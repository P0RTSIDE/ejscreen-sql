-- Traffic proximity.
-- Distance unit is kilometers. The equation on printed p. 48 is 1 divided by
-- distance in kilometers. The traffic steps on pp. 50 to 51 use that same
-- approach, set a maximum score of 10 for distances under 0.1 km, then multiply
-- by AADT. Page 21 says AADT divided by distance in meters. That line is not used.
-- The search radius is 10 km. A block score is the sum over dissolved roads of
-- AADT times the capped inverse distance. The block group value is the
-- population-weighted average of those block scores. A positive-population
-- block group with no selected road inside 10 km scores 0. A block group with
-- no residential population scores null.
-- Roads are HPMS functional classes 1, 2, and 3, plus class 4 where the urban
-- code is not 99999 (minor arterials in urban areas, including small urban 99998).
-- The technical documentation dissolves each state on Route_ID concatenated with
-- AADT so coincident segments are counted once. The distance to that dissolved
-- line is the minimum distance to any distinct segment in the group. Exact
-- duplicate geometries are removed before the minimum. Segments are not summed.
-- The cap and the unit are not revised to match the reference.

SET statement_timeout = 0;
SET work_mem = '1GB';
SET jit = off;
SET max_parallel_workers_per_gather = 0;

DROP TABLE IF EXISTS staging.hpms_route_probe;
DROP TABLE IF EXISTS staging.traffic_bg_sum_probe;
DROP TABLE IF EXISTS staging.traffic_bg_probe;
DROP TABLE IF EXISTS staging.hpms_piece_probe;
DROP TABLE IF EXISTS staging.hpms_piece;
DROP TABLE IF EXISTS staging.hpms_route;
CREATE TABLE staging.hpms_route (
  state_code smallint NOT NULL,
  route_id character varying(120),
  aadt integer NOT NULL
);

DROP TABLE IF EXISTS staging.traffic_bg_contrib;
CREATE TABLE staging.traffic_bg_contrib (
  road_state smallint NOT NULL,
  bg_geoid text NOT NULL,
  score_pop double precision NOT NULL
);

DROP TABLE IF EXISTS staging.hpms_score_done;
CREATE TABLE staging.hpms_score_done (
  state_code smallint PRIMARY KEY,
  routes integer NOT NULL,
  pieces integer NOT NULL,
  seconds double precision NOT NULL
);

DROP TABLE IF EXISTS staging.hpms_score_queue;
CREATE TABLE staging.hpms_score_queue (
  state_code smallint PRIMARY KEY,
  status text NOT NULL
);

INSERT INTO staging.hpms_score_queue (state_code, status)
SELECT DISTINCT state_code, 'pending'
FROM raw.hpms_2020;

CREATE OR REPLACE PROCEDURE staging.score_traffic_state(s integer, batch_size integer DEFAULT 150)
LANGUAGE plpgsql AS $$
DECLARE
  r0 integer := 1;
  rmax integer;
  nroutes integer;
  npieces integer;
  started timestamp := clock_timestamp();
BEGIN
  PERFORM set_config('statement_timeout', '0', true);
  PERFORM set_config('work_mem', '1GB', true);
  PERFORM set_config('jit', 'off', true);
  PERFORM set_config('enable_hashjoin', 'off', true);
  PERFORM set_config('enable_mergejoin', 'off', true);
  PERFORM set_config('join_collapse_limit', '1', true);
  PERFORM set_config('max_parallel_workers_per_gather', '0', true);

  DELETE FROM staging.traffic_bg_contrib WHERE road_state = s;
  DELETE FROM staging.hpms_route WHERE state_code = s;
  DELETE FROM staging.hpms_score_done WHERE state_code = s;

  DROP TABLE IF EXISTS pg_temp.hpms_piece;
  CREATE TEMP TABLE hpms_piece ON COMMIT DROP AS
  SELECT dense_rank() OVER (ORDER BY route_id, aadt)::integer AS route_n,
         aadt,
         geom::geography AS geog
  FROM (
    SELECT DISTINCT ON (route_id, aadt, md5(ST_AsEWKB(geom)))
           route_id,
           aadt,
           geom
    FROM raw.hpms_2020
    WHERE state_code = s
      AND aadt > 0
      AND (
        f_system IN (1, 2, 3)
        OR (f_system = 4 AND urban_code <> 99999)
      )
    ORDER BY route_id, aadt, md5(ST_AsEWKB(geom))
  ) distinct_segments
  WHERE geom IS NOT NULL;

  CREATE INDEX hpms_piece_route_n ON pg_temp.hpms_piece (route_n);
  ANALYZE hpms_piece;

  INSERT INTO staging.hpms_route (state_code, route_id, aadt)
  SELECT DISTINCT s, route_id, aadt
  FROM raw.hpms_2020
  WHERE state_code = s
    AND aadt > 0
    AND (
      f_system IN (1, 2, 3)
      OR (f_system = 4 AND urban_code <> 99999)
    );

  SELECT max(route_n), count(DISTINCT route_n), count(*)
    INTO rmax, nroutes, npieces
  FROM hpms_piece;

  IF rmax IS NOT NULL THEN
    WHILE r0 <= rmax LOOP
      INSERT INTO staging.traffic_bg_contrib (road_state, bg_geoid, score_pop)
      SELECT s, nearest.bg_geoid,
             sum(
               nearest.pop * nearest.aadt * CASE
                 WHEN nearest.min_m < 100 THEN 10::double precision
                 ELSE 1000.0 / nearest.min_m
               END
             )
      FROM (
        SELECT b.bg_geoid,
               b.geoid,
               b.pop,
               p.aadt,
               min(ST_Distance(p.geog, b.geog)) AS min_m
        FROM hpms_piece p
        JOIN staging.block_point b
          ON ST_DWithin(p.geog, b.geog, 10000)
        WHERE p.route_n BETWEEN r0 AND r0 + batch_size - 1
        GROUP BY b.bg_geoid, b.geoid, b.pop, p.route_n, p.aadt
      ) nearest
      GROUP BY nearest.bg_geoid;
      r0 := r0 + batch_size;
    END LOOP;
  END IF;

  INSERT INTO staging.hpms_score_done (state_code, routes, pieces, seconds)
  VALUES (
    s,
    COALESCE(nroutes, 0),
    COALESCE(npieces, 0),
    EXTRACT(EPOCH FROM clock_timestamp() - started)
  );
END;
$$;

CREATE OR REPLACE PROCEDURE staging.finish_traffic()
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM set_config('statement_timeout', '0', true);
  PERFORM set_config('work_mem', '1GB', true);
  PERFORM set_config('enable_hashjoin', 'on', true);
  PERFORM set_config('enable_mergejoin', 'on', true);
  PERFORM set_config('join_collapse_limit', '8', true);

  DROP TABLE IF EXISTS staging.traffic_bg_sum;
  CREATE TABLE staging.traffic_bg_sum AS
  SELECT bg_geoid, sum(score_pop) AS score_pop
  FROM staging.traffic_bg_contrib
  GROUP BY bg_geoid;

  DROP TABLE IF EXISTS staging.tier3_traffic;
  CREATE TABLE staging.tier3_traffic AS
  SELECT g.geoid,
         CASE
           WHEN COALESCE(pop.population, 0) = 0 THEN NULL
           ELSE COALESCE(scored.score_pop, 0) / pop.population
         END AS traffic
  FROM staging.block_group_inputs g
  LEFT JOIN staging.bg_population pop ON pop.bg_geoid = g.geoid
  LEFT JOIN staging.traffic_bg_sum scored ON scored.bg_geoid = g.geoid
  WHERE g.in_national_universe;

  CREATE UNIQUE INDEX tier3_traffic_geoid ON staging.tier3_traffic (geoid);
  ANALYZE staging.tier3_traffic;
END;
$$;

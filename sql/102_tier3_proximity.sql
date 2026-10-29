-- Superfund proximity and hazardous waste proximity.
-- Distance unit is kilometers, from the inverse-distance equation on printed p. 48.
-- A distance under 0.1 km takes the printed cap: 11 for Superfund, 10 for hazardous waste.
-- The search radius is 10 km. The block group value is the population-weighted average of block scores.
-- A block score is the sum of the capped inverse distances. A positive-population block group
-- with nothing inside 10 km scores 0. A block group with no residential population scores null.
-- Page 21 says traffic distance is in meters. Traffic was not built. The cap of 10 at 0.1 km
-- equals 1/0.1 only when the denominator is kilometers, so hazardous waste uses kilometers too.

SET statement_timeout = 0;
SET work_mem = '1GB';
SET max_parallel_workers_per_gather = 0;
SET enable_hashjoin = off;
SET enable_mergejoin = off;

DROP TABLE IF EXISTS staging.superfund_site;
CREATE TABLE staging.superfund_site AS
SELECT epa_id,
       ST_UnaryUnion(ST_Collect(ST_MakeValid(geom)))::geography AS geog,
       'boundary'::text AS kind
FROM (
  SELECT epa_id, geom FROM raw.superfund_fp_boundary
  UNION ALL
  SELECT epa_id, geom FROM raw.superfund_saa_boundary
) boundaries
GROUP BY epa_id
UNION ALL
SELECT p.epa_id,
       ST_Buffer(ST_SetSRID(ST_MakePoint(p.lon, p.lat), 4326)::geography, 1) AS geog,
       'point_buffer_1m'::text AS kind
FROM raw.superfund_point_only p
WHERE p.lat IS NOT NULL
  AND p.lon IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM raw.superfund_fp_boundary b WHERE b.epa_id = p.epa_id
  )
  AND NOT EXISTS (
    SELECT 1 FROM raw.superfund_saa_boundary b WHERE b.epa_id = p.epa_id
  );

CREATE INDEX superfund_site_geog ON staging.superfund_site USING GIST (geog);
ANALYZE staging.superfund_site;

DROP TABLE IF EXISTS staging.superfund_bg_sum;
CREATE TABLE staging.superfund_bg_sum AS
SELECT b.bg_geoid,
       sum(
         b.pop * CASE
           WHEN d.meters < 100 THEN 11::double precision
           ELSE 1000.0 / d.meters
         END
       ) AS score_pop
FROM staging.superfund_site s
JOIN staging.block_point b
  ON ST_DWithin(s.geog, b.geog, 10000)
CROSS JOIN LATERAL (
  SELECT ST_Distance(s.geog, b.geog) AS meters
) d
GROUP BY b.bg_geoid;

SET enable_hashjoin = on;
SET enable_mergejoin = on;

DROP TABLE IF EXISTS staging.bg_population;
CREATE TABLE staging.bg_population AS
SELECT bg_geoid, sum(pop) AS population
FROM staging.block_point
GROUP BY bg_geoid;
CREATE UNIQUE INDEX bg_population_geoid ON staging.bg_population (bg_geoid);
ANALYZE staging.bg_population;

DROP TABLE IF EXISTS staging.tier3_superfund;
CREATE TABLE staging.tier3_superfund AS
SELECT g.geoid,
       CASE
         WHEN COALESCE(pop.population, 0) = 0 THEN NULL
         ELSE COALESCE(scored.score_pop, 0) / pop.population
       END AS superfund
FROM staging.block_group_inputs g
LEFT JOIN staging.bg_population pop ON pop.bg_geoid = g.geoid
LEFT JOIN staging.superfund_bg_sum scored ON scored.bg_geoid = g.geoid
WHERE g.in_national_universe;

CREATE UNIQUE INDEX tier3_superfund_geoid ON staging.tier3_superfund (geoid);
ANALYZE staging.tier3_superfund;

DROP TABLE IF EXISTS staging.hazwaste_site;
CREATE TABLE staging.hazwaste_site AS
SELECT handler_id,
       ST_SetSRID(ST_MakePoint(lon, lat), 4326)::geography AS geog,
       operating_tsdf,
       lqg_2021
FROM raw.rcra_facility_2021
WHERE lat IS NOT NULL
  AND lon IS NOT NULL
  AND lat BETWEEN -90 AND 90
  AND lon BETWEEN -180 AND 180
  AND state IN (
    'AL','AK','AZ','AR','CA','CO','CT','DE','DC','FL','GA','HI','ID','IL','IN','IA',
    'KS','KY','LA','ME','MD','MA','MI','MN','MS','MO','MT','NE','NV','NH','NJ','NM',
    'NY','NC','ND','OH','OK','OR','PA','RI','SC','SD','TN','TX','UT','VT','VA','WA',
    'WV','WI','WY','PR'
  );

CREATE INDEX hazwaste_site_geog ON staging.hazwaste_site USING GIST (geog);
ANALYZE staging.hazwaste_site;

SET enable_hashjoin = off;
SET enable_mergejoin = off;

DROP TABLE IF EXISTS staging.hazwaste_bg_sum;
CREATE TABLE staging.hazwaste_bg_sum AS
SELECT b.bg_geoid,
       sum(
         b.pop * CASE
           WHEN d.meters < 100 THEN 10::double precision
           ELSE 1000.0 / d.meters
         END
       ) AS score_pop
FROM staging.hazwaste_site s
JOIN staging.block_point b
  ON ST_DWithin(s.geog, b.geog, 10000)
CROSS JOIN LATERAL (
  SELECT ST_Distance(s.geog, b.geog) AS meters
) d
GROUP BY b.bg_geoid;

SET enable_hashjoin = on;
SET enable_mergejoin = on;

DROP TABLE IF EXISTS staging.tier3_hazwaste;
CREATE TABLE staging.tier3_hazwaste AS
SELECT g.geoid,
       CASE
         WHEN COALESCE(pop.population, 0) = 0 THEN NULL
         ELSE COALESCE(scored.score_pop, 0) / pop.population
       END AS hazardous_waste
FROM staging.block_group_inputs g
LEFT JOIN staging.bg_population pop ON pop.bg_geoid = g.geoid
LEFT JOIN staging.hazwaste_bg_sum scored ON scored.bg_geoid = g.geoid
WHERE g.in_national_universe;

CREATE UNIQUE INDEX tier3_hazwaste_geoid ON staging.tier3_hazwaste (geoid);
ANALYZE staging.tier3_hazwaste;

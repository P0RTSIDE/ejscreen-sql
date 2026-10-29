-- 2020 block centroids and the block-group weights used by the proximity indicators.
-- Centroids are geometric centroids of TIGER/Line 2020 tabulation blocks, not Census internal points.
-- Population is 2020 P.L. 94-171 P1_001N.
-- Outside Connecticut, the 2020 block group id is the first 12 characters of the block GEOID.
-- Connecticut 2020 counties are mapped to 2022 planning-region tracts with the loaded Geocorr table.
-- A 2020 tract that maps to more than one 2022 tract is left unassigned.

SET statement_timeout = 0;
SET work_mem = '512MB';
SET max_parallel_workers_per_gather = 0;

DROP TABLE IF EXISTS staging.ct_tract_2022;
CREATE TABLE staging.ct_tract_2022 AS
SELECT
  lpad(ctcounty, 5, '0') || replace(tract, '.', '') AS tract_2020,
  lpad(county, 5, '0') || replace(tract, '.', '') AS tract_2022
FROM raw.geocorr_ct_2020_2022;

DROP TABLE IF EXISTS staging.ct_tract_unique;
CREATE TABLE staging.ct_tract_unique AS
SELECT tract_2020, min(tract_2022) AS tract_2022
FROM staging.ct_tract_2022
GROUP BY tract_2020
HAVING count(DISTINCT tract_2022) = 1;

DROP TABLE IF EXISTS staging.ct_tract_split;
CREATE TABLE staging.ct_tract_split AS
SELECT tract_2020, count(DISTINCT tract_2022) AS n_2022
FROM staging.ct_tract_2022
GROUP BY tract_2020
HAVING count(DISTINCT tract_2022) > 1;

DROP TABLE IF EXISTS staging.block_point;
CREATE TABLE staging.block_point AS
SELECT
  c.geoid,
  staging.acs_count(p."P1_001N") AS pop,
  CASE
    WHEN left(c.geoid, 2) <> '09' THEN left(c.geoid, 12)
    ELSE u.tract_2022 || substring(c.geoid FROM 12 FOR 1)
  END AS bg_geoid,
  ST_SetSRID(ST_MakePoint(c.lon, c.lat), 4326)::geography AS geog
FROM raw.tiger2020_block_centroid c
JOIN raw.pl2020_block p
  ON c.geoid = lpad(p.state, 2, '0')
    || lpad(p.county, 3, '0')
    || lpad(p.tract, 6, '0')
    || lpad(p.block, 4, '0')
LEFT JOIN staging.ct_tract_unique u
  ON u.tract_2020 = left(c.geoid, 11)
WHERE staging.acs_count(p."P1_001N") > 0
  AND (
    left(c.geoid, 2) <> '09'
    OR u.tract_2022 IS NOT NULL
  );

CREATE INDEX block_point_geoid ON staging.block_point (geoid);
CREATE INDEX block_point_bg ON staging.block_point (bg_geoid);
CREATE INDEX block_point_geog ON staging.block_point USING GIST (geog);
ANALYZE staging.block_point;

DROP TABLE IF EXISTS staging.block_point_audit;
CREATE TABLE staging.block_point_audit AS
SELECT
  (SELECT count(*) FROM raw.tiger2020_block_centroid) AS centroid_rows,
  (SELECT count(*) FROM staging.block_point) AS populated_assigned_blocks,
  (SELECT count(*) FROM staging.block_point WHERE left(geoid, 2) = '09') AS connecticut_assigned_blocks,
  (SELECT COALESCE(sum(staging.acs_count(p."P1_001N")), 0)
   FROM raw.pl2020_block p
   JOIN staging.ct_tract_split s ON s.tract_2020 = lpad(p.state, 2, '0') || lpad(p.county, 3, '0') || lpad(p.tract, 6, '0')
  ) AS split_tract_population,
  (SELECT count(*)
   FROM raw.pl2020_block p
   JOIN staging.ct_tract_split s ON s.tract_2020 = lpad(p.state, 2, '0') || lpad(p.county, 3, '0') || lpad(p.tract, 6, '0')
  ) AS split_tract_blocks;

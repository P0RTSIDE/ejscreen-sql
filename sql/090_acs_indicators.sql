SET statement_timeout = 0;
SET work_mem = '512MB';
SET max_parallel_workers_per_gather = 0;

CREATE OR REPLACE FUNCTION staging.acs_count(raw text)
RETURNS double precision
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT CASE
    WHEN raw IS NULL OR btrim(raw) = '' THEN NULL
    WHEN left(btrim(raw), 1) = '-' THEN NULL
    ELSE btrim(raw)::double precision
  END
$$;

COMMENT ON FUNCTION staging.acs_count(text) IS
  'Casts an ACS count. Blank and negative API values become null. A negative count is a Census special value, not a population.';

CREATE OR REPLACE FUNCTION staging.acs_rate(numer double precision, denom double precision)
RETURNS double precision
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT CASE
    WHEN denom IS NULL THEN NULL
    WHEN denom = 0 THEN 0::double precision
    ELSE numer / denom
  END
$$;

COMMENT ON FUNCTION staging.acs_rate(double precision, double precision) IS
  'ACS ratio. A zero denominator is stored as 0, which is the reference value. The technical documentation is silent on a zero denominator. See assumptions.';

DROP TABLE IF EXISTS staging.acs_negative_audit;
CREATE TABLE staging.acs_negative_audit AS
SELECT count(*) AS n_negative
FROM raw.acs2022_block_group
WHERE "B03002_001E" LIKE '-%'
   OR "B03002_003E" LIKE '-%'
   OR "C17002_001E" LIKE '-%'
   OR "C17002_008E" LIKE '-%'
   OR "C16002_001E" LIKE '-%'
   OR "C16002_004E" LIKE '-%'
   OR "C16002_007E" LIKE '-%'
   OR "C16002_010E" LIKE '-%'
   OR "C16002_013E" LIKE '-%'
   OR "B15002_001E" LIKE '-%'
   OR "B15002_003E" LIKE '-%'
   OR "B23025_003E" LIKE '-%'
   OR "B23025_005E" LIKE '-%'
   OR "B01001_001E" LIKE '-%';

-- Part population for a 2020 tract and one 2010 parent.
-- A 2020 block that the relationship places in one 2010 tract contributes its
-- whole 2020 P.L. 94-171 population. A block placed in more than one 2010 tract
-- is left out. arealand_int partitions those blocks, and allocating population
-- by that column did not match the published life expectancy, so it is not used.
DROP TABLE IF EXISTS staging.diag_split_block;
DROP TABLE IF EXISTS staging.diag_split_audit;
DROP TABLE IF EXISTS staging.diag_le_multi_land;
DROP TABLE IF EXISTS staging.block_parent_span;
CREATE TABLE staging.block_parent_span AS
SELECT
  lpad(state_2020, 2, '0') || lpad(county_2020, 3, '0')
    || lpad(tract_2020, 6, '0') || lpad(blk_2020, 4, '0') AS block_2020,
  min(lpad(state_2020, 2, '0') || lpad(county_2020, 3, '0') || lpad(tract_2020, 6, '0')) AS tract_2020,
  min(lpad(state_2010, 2, '0') || lpad(county_2010, 3, '0') || lpad(tract_2010, 6, '0')) AS tract_2010,
  count(DISTINCT lpad(state_2010, 2, '0') || lpad(county_2010, 3, '0') || lpad(tract_2010, 6, '0')) AS n_tract_2010
FROM raw.block_rel_2010_2020
GROUP BY 1;

DROP TABLE IF EXISTS staging.tract_part_population;
CREATE TABLE staging.tract_part_population AS
SELECT b.tract_2020,
       b.tract_2010,
       sum(p.population) AS part_population
FROM staging.block_parent_span b
JOIN (
  SELECT
    lpad(state, 2, '0') || lpad(county, 3, '0')
      || lpad(tract, 6, '0') || lpad(block, 4, '0') AS block_2020,
    staging.acs_count("P1_001N") AS population
  FROM raw.pl2020_block
) p ON p.block_2020 = b.block_2020
WHERE b.n_tract_2010 = 1
  AND p.population IS NOT NULL
GROUP BY b.tract_2020, b.tract_2010;

CREATE INDEX tract_part_population_pair
  ON staging.tract_part_population (tract_2020, tract_2010);
ANALYZE staging.tract_part_population;

-- Weighted life expectancy only for 2020 tracts with more than one 2010 parent.
-- A parent with population and no USALEEP value leaves the tract null.
-- A tract with no assignable population stays null.
DROP TABLE IF EXISTS staging.le_multi_parent;
CREATE TABLE staging.le_multi_parent AS
WITH le_2010 AS (
  SELECT lpad(tract_id, 11, '0') AS tract_geoid,
         max(NULLIF(life_expectancy, '')::double precision) AS le
  FROM raw.usaleep_2010_tract
  GROUP BY 1
),
parents AS (
  SELECT geoid_tract_20, geoid_tract_10
  FROM raw.tract_rel_2020_2010
  GROUP BY 1, 2
),
multi AS (
  SELECT geoid_tract_20
  FROM raw.tract_rel_2020_2010
  GROUP BY 1
  HAVING count(DISTINCT geoid_tract_10) > 1
)
SELECT parents.geoid_tract_20 AS tract_geoid,
       CASE
         WHEN count(*) FILTER (
           WHERE coalesce(part.part_population, 0) > 0 AND le.le IS NULL
         ) > 0 THEN NULL
         WHEN coalesce(sum(part.part_population) FILTER (WHERE le.le IS NOT NULL), 0) = 0 THEN NULL
         ELSE sum(le.le * part.part_population) FILTER (WHERE le.le IS NOT NULL)
              / sum(part.part_population) FILTER (WHERE le.le IS NOT NULL)
       END AS le
FROM parents
JOIN multi ON multi.geoid_tract_20 = parents.geoid_tract_20
LEFT JOIN staging.tract_part_population part
  ON part.tract_2020 = parents.geoid_tract_20
 AND part.tract_2010 = parents.geoid_tract_10
LEFT JOIN le_2010 le ON le.tract_geoid = parents.geoid_tract_10
GROUP BY parents.geoid_tract_20;

CREATE INDEX le_multi_parent_tract ON staging.le_multi_parent (tract_geoid);
ANALYZE staging.le_multi_parent;

DROP TABLE IF EXISTS staging.life_weight_audit;
CREATE TABLE staging.life_weight_audit AS
WITH pop AS (
  SELECT
    lpad(state, 2, '0') || lpad(county, 3, '0')
      || lpad(tract, 6, '0') || lpad(block, 4, '0') AS block_2020,
    staging.acs_count("P1_001N") AS population
  FROM raw.pl2020_block
)
SELECT
  (SELECT count(*) FROM raw.block_rel_2010_2020) AS relationship_rows,
  (SELECT count(*) FROM raw.pl2020_block) AS population_rows,
  (SELECT coalesce(sum(population), 0) FROM pop) AS population_total,
  count(*) FILTER (WHERE b.n_tract_2010 = 1) AS blocks_one_2010_tract,
  count(*) FILTER (WHERE b.n_tract_2010 > 1) AS blocks_many_2010_tracts,
  coalesce(sum(p.population) FILTER (WHERE b.n_tract_2010 = 1), 0) AS population_one_2010_tract,
  coalesce(sum(p.population) FILTER (WHERE b.n_tract_2010 > 1), 0) AS population_many_2010_tracts,
  (SELECT count(*) FROM staging.le_multi_parent) AS multi_parent_tracts,
  (SELECT count(*) FROM staging.le_multi_parent WHERE le IS NOT NULL) AS multi_parent_tracts_weighted,
  (SELECT count(*) FROM staging.le_multi_parent WHERE le IS NULL) AS multi_parent_tracts_unweighted
FROM staging.block_parent_span b
FULL JOIN pop p ON p.block_2020 = b.block_2020;

DROP TABLE staging.block_parent_span;

-- Connecticut 2022 tract to 2020 tract. Geocorr 2022, column pop20.
-- Applied only in Connecticut, and only where the 2022 tract has no life expectancy yet.
-- A positive pop20 on a 2020 parent with no life expectancy leaves the 2022 tract null.
-- A pop20 total of 0 leaves the 2022 tract null. No county-name crosswalk is used.
DROP TABLE IF EXISTS staging.le_ct_2022;
CREATE TABLE staging.le_ct_2022 AS
WITH geocorr AS (
  SELECT
    county || replace(tract, '.', '') AS tract_2022,
    ctcounty || replace(tract, '.', '') AS tract_2020,
    CASE WHEN btrim(pop20) = '' THEN NULL ELSE btrim(pop20)::double precision END AS pop20
  FROM raw.geocorr_ct_2020_2022
),
le_2010 AS (
  SELECT lpad(tract_id, 11, '0') AS tract_geoid,
         max(NULLIF(life_expectancy, '')::double precision) AS le
  FROM raw.usaleep_2010_tract
  GROUP BY 1
),
le_single_parent AS (
  SELECT rel.geoid_tract_20 AS tract_geoid,
         min(le_2010.le) AS le
  FROM raw.tract_rel_2020_2010 rel
  LEFT JOIN le_2010 ON le_2010.tract_geoid = rel.geoid_tract_10
  GROUP BY rel.geoid_tract_20
  HAVING count(DISTINCT rel.geoid_tract_10) = 1
)
SELECT geocorr.tract_2022 AS tract_geoid,
       CASE
         WHEN count(*) FILTER (
           WHERE coalesce(geocorr.pop20, 0) > 0
             AND COALESCE(le_2010.le, le_single_parent.le, le_multi.le) IS NULL
         ) > 0 THEN NULL
         WHEN coalesce(sum(geocorr.pop20) FILTER (
           WHERE COALESCE(le_2010.le, le_single_parent.le, le_multi.le) IS NOT NULL
         ), 0) = 0 THEN NULL
         ELSE sum(
           COALESCE(le_2010.le, le_single_parent.le, le_multi.le) * geocorr.pop20
         ) FILTER (
           WHERE COALESCE(le_2010.le, le_single_parent.le, le_multi.le) IS NOT NULL
         ) / sum(geocorr.pop20) FILTER (
           WHERE COALESCE(le_2010.le, le_single_parent.le, le_multi.le) IS NOT NULL
         )
       END AS le
FROM geocorr
LEFT JOIN le_2010 ON le_2010.tract_geoid = geocorr.tract_2020
LEFT JOIN le_single_parent
  ON le_single_parent.tract_geoid = geocorr.tract_2020
 AND le_2010.le IS NULL
LEFT JOIN staging.le_multi_parent le_multi
  ON le_multi.tract_geoid = geocorr.tract_2020
 AND le_2010.le IS NULL
 AND le_single_parent.le IS NULL
GROUP BY geocorr.tract_2022;

CREATE INDEX le_ct_2022_tract ON staging.le_ct_2022 (tract_geoid);
ANALYZE staging.le_ct_2022;

DROP TABLE IF EXISTS staging.ct_crosswalk_audit;
CREATE TABLE staging.ct_crosswalk_audit AS
SELECT
  (SELECT count(*) FROM raw.geocorr_ct_2020_2022) AS geocorr_rows,
  (SELECT count(*) FROM staging.le_ct_2022) AS tract_rows,
  (SELECT count(*) FROM staging.le_ct_2022 WHERE le IS NOT NULL) AS tracts_with_le,
  (SELECT count(*) FROM staging.le_ct_2022 WHERE le IS NULL) AS tracts_without_le;

DROP TABLE IF EXISTS staging.acs_indicator;
CREATE TABLE staging.acs_indicator AS
WITH bg AS (
  SELECT
    lpad("state", 2, '0') || lpad("county", 3, '0') || lpad("tract", 6, '0') || lpad("block group", 1, '0') AS geoid,
    lpad("state", 2, '0') AS state_fips,
    staging.acs_count("B03002_001E") AS b03002_001,
    staging.acs_count("B03002_003E") AS b03002_003,
    staging.acs_count("C17002_001E") AS c17002_001,
    staging.acs_count("C17002_008E") AS c17002_008,
    staging.acs_count("C16002_001E") AS c16002_001,
    staging.acs_count("C16002_004E") AS c16002_004,
    staging.acs_count("C16002_007E") AS c16002_007,
    staging.acs_count("C16002_010E") AS c16002_010,
    staging.acs_count("C16002_013E") AS c16002_013,
    staging.acs_count("B15002_001E") AS b15002_001,
    staging.acs_count("B15002_003E") AS b15002_003,
    staging.acs_count("B15002_004E") AS b15002_004,
    staging.acs_count("B15002_005E") AS b15002_005,
    staging.acs_count("B15002_006E") AS b15002_006,
    staging.acs_count("B15002_007E") AS b15002_007,
    staging.acs_count("B15002_008E") AS b15002_008,
    staging.acs_count("B15002_009E") AS b15002_009,
    staging.acs_count("B15002_010E") AS b15002_010,
    staging.acs_count("B15002_020E") AS b15002_020,
    staging.acs_count("B15002_021E") AS b15002_021,
    staging.acs_count("B15002_022E") AS b15002_022,
    staging.acs_count("B15002_023E") AS b15002_023,
    staging.acs_count("B15002_024E") AS b15002_024,
    staging.acs_count("B15002_025E") AS b15002_025,
    staging.acs_count("B15002_026E") AS b15002_026,
    staging.acs_count("B23025_003E") AS b23025_003,
    staging.acs_count("B23025_005E") AS b23025_005,
    staging.acs_count("B01001_001E") AS b01001_001,
    staging.acs_count("B01001_003E") AS b01001_003,
    staging.acs_count("B01001_020E") AS b01001_020,
    staging.acs_count("B01001_021E") AS b01001_021,
    staging.acs_count("B01001_022E") AS b01001_022,
    staging.acs_count("B01001_023E") AS b01001_023,
    staging.acs_count("B01001_024E") AS b01001_024,
    staging.acs_count("B01001_025E") AS b01001_025,
    staging.acs_count("B01001_027E") AS b01001_027,
    staging.acs_count("B01001_044E") AS b01001_044,
    staging.acs_count("B01001_045E") AS b01001_045,
    staging.acs_count("B01001_046E") AS b01001_046,
    staging.acs_count("B01001_047E") AS b01001_047,
    staging.acs_count("B01001_048E") AS b01001_048,
    staging.acs_count("B01001_049E") AS b01001_049
  FROM raw.acs2022_block_group
),
pl AS (
  SELECT
    lpad("state", 2, '0') || lpad("county", 3, '0') || lpad("tract", 6, '0') || lpad("block group", 1, '0') AS geoid,
    staging.acs_count("P1_001N") AS population
  FROM raw.pl2020_block_group
),
edu027 AS (
  SELECT
    lpad("state", 2, '0') || lpad("county", 3, '0') || lpad("tract", 6, '0') || lpad("block group", 1, '0') AS geoid,
    staging.acs_count("B15002_027E") AS b15002_027
  FROM raw.acs2022_b15002_027
),
tract AS (
  SELECT
    lpad("state", 2, '0') || lpad("county", 3, '0') || lpad("tract", 6, '0') AS tract_geoid,
    staging.acs_count("B18101_001E") AS denom,
    staging.acs_count("B18101_004E")
      + staging.acs_count("B18101_007E")
      + staging.acs_count("B18101_010E")
      + staging.acs_count("B18101_013E")
      + staging.acs_count("B18101_016E")
      + staging.acs_count("B18101_019E")
      + staging.acs_count("B18101_023E")
      + staging.acs_count("B18101_026E")
      + staging.acs_count("B18101_029E")
      + staging.acs_count("B18101_032E")
      + staging.acs_count("B18101_035E")
      + staging.acs_count("B18101_038E") AS numer
  FROM raw.acs2022_tract_b18101
),
le_2010 AS (
  SELECT lpad(tract_id, 11, '0') AS tract_geoid,
         max(NULLIF(life_expectancy, '')::double precision) AS le
  FROM raw.usaleep_2010_tract
  GROUP BY 1
),
-- A single parent means one 2010 tract in the relationship file.
-- Parents with no USALEEP row still count. An inner join would drop them
-- and treat a multi-parent tract as a single parent.
le_single_parent AS (
  SELECT rel.geoid_tract_20 AS tract_geoid,
         min(le_2010.le) AS le
  FROM raw.tract_rel_2020_2010 rel
  LEFT JOIN le_2010 ON le_2010.tract_geoid = rel.geoid_tract_10
  GROUP BY rel.geoid_tract_20
  HAVING count(DISTINCT rel.geoid_tract_10) = 1
)
SELECT
  bg.geoid,
  bg.state_fips,
  staging.acs_rate(bg.b03002_001 - bg.b03002_003, bg.b03002_001) AS pct_people_of_color,
  staging.acs_rate(bg.c17002_001 - bg.c17002_008, bg.c17002_001) AS pct_low_income,
  staging.acs_rate(
    bg.c16002_004 + bg.c16002_007 + bg.c16002_010 + bg.c16002_013,
    bg.c16002_001
  ) AS pct_limited_english,
  staging.acs_rate(
    bg.b15002_003 + bg.b15002_004 + bg.b15002_005 + bg.b15002_006
      + bg.b15002_007 + bg.b15002_008 + bg.b15002_009 + bg.b15002_010
      + bg.b15002_020 + bg.b15002_021 + bg.b15002_022 + bg.b15002_023
      + bg.b15002_024 + bg.b15002_025 + bg.b15002_026
      + edu027.b15002_027,
    bg.b15002_001
  ) AS pct_less_than_hs,
  CASE
    WHEN bg.b23025_003 IS NULL THEN NULL
    WHEN bg.b23025_003 = 0 AND bg.b01001_001 > 0 THEN NULL
    WHEN bg.b23025_003 = 0 THEN 0::double precision
    ELSE bg.b23025_005 / bg.b23025_003
  END AS pct_unemployed,
  staging.acs_rate(bg.b01001_003 + bg.b01001_027, bg.b01001_001) AS pct_under_5,
  staging.acs_rate(
    bg.b01001_020 + bg.b01001_021 + bg.b01001_022 + bg.b01001_023
      + bg.b01001_024 + bg.b01001_025 + bg.b01001_044 + bg.b01001_045
      + bg.b01001_046 + bg.b01001_047 + bg.b01001_048 + bg.b01001_049,
    bg.b01001_001
  ) AS pct_over_64,
  staging.acs_rate(tract.numer, tract.denom) AS pct_disability,
  CASE
    WHEN COALESCE(le_2010.le, le_single_parent.le, le_multi.le, le_ct.le) IS NULL THEN NULL
    ELSE 1.0 - (COALESCE(le_2010.le, le_single_parent.le, le_multi.le, le_ct.le) / 97.5)
  END AS pct_low_life_expectancy,
  bg.b01001_001 AS acs_population,
  pl.population AS pl_population
FROM bg
LEFT JOIN edu027 ON edu027.geoid = bg.geoid
LEFT JOIN pl ON pl.geoid = bg.geoid
LEFT JOIN tract ON tract.tract_geoid = left(bg.geoid, 11)
LEFT JOIN le_2010 ON le_2010.tract_geoid = left(bg.geoid, 11)
LEFT JOIN le_single_parent
  ON le_single_parent.tract_geoid = left(bg.geoid, 11)
 AND le_2010.le IS NULL
LEFT JOIN staging.le_multi_parent le_multi
  ON le_multi.tract_geoid = left(bg.geoid, 11)
 AND le_2010.le IS NULL
 AND le_single_parent.le IS NULL
LEFT JOIN staging.le_ct_2022 le_ct
  ON le_ct.tract_geoid = left(bg.geoid, 11)
 AND bg.state_fips = '09'
 AND le_2010.le IS NULL
 AND le_single_parent.le IS NULL
 AND le_multi.le IS NULL;

ALTER TABLE staging.acs_indicator ADD PRIMARY KEY (geoid);
ANALYZE staging.acs_indicator;

COMMENT ON TABLE staging.acs_indicator IS
  'Block group rates from ACS 2018-2022. A zero denominator is stored as 0. Unemployment is null when the civilian labor force is 0 and the block group population is greater than 0. Less than high school includes B15002.027. Disability is the tract rate assigned to each block group. Low life expectancy uses 1 minus life expectancy over 97.5. Multi-parent 2020 tracts use the 2020 block population weight. Connecticut 2022 tracts use the Geocorr 2022 pop20 crosswalk. Island territories are not included.';

-- Tier 2 thresholds, fixed before the comparison.
-- Continuous absolute tolerance is 1e-8, the same bar as Tier 1.
-- A column passes the exact check when at least 99 percent of rows with both values present are equal as doubles.
-- A column passes the tolerance check at the same 99 percent bar.
-- Null agreement passes when at least 99.9 percent of compared rows agree on whether the value is null.
-- A low match rate is stored here and reported. It does not raise an exception.
-- These numbers are not revised after the scores are known.

SET statement_timeout = 0;
SET work_mem = '256MB';
SET max_parallel_workers_per_gather = 0;

DROP TABLE IF EXISTS validation.tier2_pair;
DROP TABLE IF EXISTS validation.tier2_column_result;
DROP TABLE IF EXISTS validation.tier2_worst;
DROP TABLE IF EXISTS validation.tier2_geoid_gap;
DROP TABLE IF EXISTS validation.tier2_range;
DROP TABLE IF EXISTS validation.tier2_zero_denominator;
DROP TABLE IF EXISTS validation.tier2_direction;
DROP TABLE IF EXISTS validation.usaleep_fit;
DROP TABLE IF EXISTS validation.life_coverage;
DROP TABLE IF EXISTS validation.life_match_gap;
DROP TABLE IF EXISTS validation.life_multi_fit;
DROP TABLE IF EXISTS validation.life_null_reason;

CREATE TABLE validation.tier2_pair AS
SELECT v.column_name,
       a.geoid,
       a.state_fips,
       a.state_abbrev,
       v.rebuilt,
       v.reference
FROM marts.acs_block_group a
JOIN staging.block_group_inputs s ON s.geoid = a.geoid
JOIN raw.ejscreen_reference r ON r."ID" = s.source_id
CROSS JOIN LATERAL (VALUES
  ('LOWINCPCT', a.pct_low_income, NULLIF(r."LOWINCPCT", '')::double precision),
  ('PEOPCOLORPCT', a.pct_people_of_color, NULLIF(r."PEOPCOLORPCT", '')::double precision),
  ('LINGISOPCT', a.pct_limited_english, NULLIF(r."LINGISOPCT", '')::double precision),
  ('LESSHSPCT', a.pct_less_than_hs, NULLIF(r."LESSHSPCT", '')::double precision),
  ('UNEMPPCT', a.pct_unemployed, NULLIF(r."UNEMPPCT", '')::double precision),
  ('UNDER5PCT', a.pct_under_5, NULLIF(r."UNDER5PCT", '')::double precision),
  ('OVER64PCT', a.pct_over_64, NULLIF(r."OVER64PCT", '')::double precision),
  ('DISABILITYPCT', a.pct_disability, NULLIF(r."DISABILITYPCT", '')::double precision),
  ('LIFEEXPPCT', a.pct_low_life_expectancy, NULLIF(r."LIFEEXPPCT", '')::double precision),
  ('DEMOGIDX_2', a.demogidx_2, NULLIF(r."DEMOGIDX_2", '')::double precision),
  ('DEMOGIDX_2ST', a.demogidx_2st, NULLIF(r."DEMOGIDX_2ST", '')::double precision),
  ('DEMOGIDX_5', a.demogidx_5, NULLIF(r."DEMOGIDX_5", '')::double precision),
  ('DEMOGIDX_5ST', a.demogidx_5st, NULLIF(r."DEMOGIDX_5ST", '')::double precision)
) AS v(column_name, rebuilt, reference);

CREATE TABLE validation.tier2_column_result AS
WITH base AS (
  SELECT column_name, state_fips, rebuilt, reference,
         1e-8::double precision AS tol
  FROM validation.tier2_pair
),
slices AS (
  SELECT 'all'::text AS slice, column_name, rebuilt, reference, tol FROM base
  UNION ALL
  SELECT 'state_fips_' || COALESCE(current_setting('ejscreen.state_fips', true), '06'),
         column_name, rebuilt, reference, tol
  FROM base
  WHERE state_fips = COALESCE(current_setting('ejscreen.state_fips', true), '06')
),
agg AS (
  SELECT slice, column_name,
         count(*) AS n_rows,
         count(*) FILTER (WHERE rebuilt IS NOT NULL AND reference IS NOT NULL) AS both_present,
         count(*) FILTER (WHERE rebuilt IS NULL AND reference IS NULL) AS both_null,
         count(*) FILTER (WHERE rebuilt IS NULL AND reference IS NOT NULL) AS rebuilt_null,
         count(*) FILTER (WHERE rebuilt IS NOT NULL AND reference IS NULL) AS reference_null,
         count(*) FILTER (WHERE rebuilt = reference) AS exact_n,
         count(*) FILTER (
           WHERE rebuilt IS NOT NULL AND reference IS NOT NULL AND abs(rebuilt - reference) <= tol
         ) AS within_tol_n,
         corr(rebuilt, reference) AS pearson
  FROM slices
  GROUP BY slice, column_name
),
diffs AS (
  SELECT slice, column_name,
         min(abs_diff) AS abs_min,
         percentile_cont(0.5) WITHIN GROUP (ORDER BY abs_diff) AS abs_median,
         percentile_cont(0.95) WITHIN GROUP (ORDER BY abs_diff) AS abs_p95,
         max(abs_diff) AS abs_max
  FROM (
    SELECT 'all'::text AS slice, column_name, abs(rebuilt - reference) AS abs_diff
    FROM validation.tier2_pair
    WHERE rebuilt IS NOT NULL AND reference IS NOT NULL
    UNION ALL
    SELECT 'state_fips_' || COALESCE(current_setting('ejscreen.state_fips', true), '06'),
           column_name, abs(rebuilt - reference)
    FROM validation.tier2_pair
    WHERE rebuilt IS NOT NULL AND reference IS NOT NULL
      AND state_fips = COALESCE(current_setting('ejscreen.state_fips', true), '06')
  ) d
  GROUP BY slice, column_name
),
ranked AS (
  SELECT slice, column_name, corr(rank_rebuilt, rank_reference) AS spearman
  FROM (
    SELECT 'all'::text AS slice, column_name,
           rank() OVER (PARTITION BY column_name ORDER BY rebuilt) AS rank_rebuilt,
           rank() OVER (PARTITION BY column_name ORDER BY reference) AS rank_reference
    FROM validation.tier2_pair
    WHERE rebuilt IS NOT NULL AND reference IS NOT NULL
  ) r
  GROUP BY slice, column_name
  UNION ALL
  SELECT slice, column_name, corr(rank_rebuilt, rank_reference)
  FROM (
    SELECT 'state_fips_' || COALESCE(current_setting('ejscreen.state_fips', true), '06') AS slice,
           column_name,
           rank() OVER (PARTITION BY column_name ORDER BY rebuilt) AS rank_rebuilt,
           rank() OVER (PARTITION BY column_name ORDER BY reference) AS rank_reference
    FROM validation.tier2_pair
    WHERE rebuilt IS NOT NULL AND reference IS NOT NULL
      AND state_fips = COALESCE(current_setting('ejscreen.state_fips', true), '06')
  ) r
  GROUP BY slice, column_name
)
SELECT a.slice, a.column_name, a.n_rows, a.both_present, a.both_null,
       a.rebuilt_null, a.reference_null, a.exact_n, a.within_tol_n, a.pearson, k.spearman,
       d.abs_min, d.abs_median, d.abs_p95, d.abs_max,
       CASE WHEN a.both_present = 0 THEN (a.rebuilt_null + a.reference_null) = 0
            ELSE a.exact_n::numeric / a.both_present >= 0.99 END AS exact_pass,
       CASE WHEN a.both_present = 0 THEN (a.rebuilt_null + a.reference_null) = 0
            ELSE a.within_tol_n::numeric / a.both_present >= 0.99 END AS tolerance_pass,
       ((a.n_rows - a.rebuilt_null - a.reference_null)::numeric / NULLIF(a.n_rows, 0)) >= 0.999 AS null_pass
FROM agg a
LEFT JOIN diffs d USING (slice, column_name)
LEFT JOIN ranked k USING (slice, column_name);

CREATE TABLE validation.tier2_worst AS
SELECT column_name, geoid, state_abbrev, state_fips, rebuilt, reference,
       abs(rebuilt - reference) AS abs_diff
FROM validation.tier2_pair
WHERE rebuilt IS NOT NULL AND reference IS NOT NULL
ORDER BY abs(rebuilt - reference) DESC, column_name, geoid
LIMIT 20;

CREATE TABLE validation.tier2_geoid_gap AS
SELECT 'acs_missing_from_reference' AS gap_side, a.geoid
FROM marts.acs_block_group a
WHERE NOT EXISTS (
  SELECT 1 FROM staging.block_group_inputs s WHERE s.geoid = a.geoid
)
UNION ALL
SELECT 'reference_national_missing_from_acs', s.geoid
FROM staging.block_group_inputs s
WHERE s.in_national_universe
  AND NOT EXISTS (
    SELECT 1 FROM marts.acs_block_group a WHERE a.geoid = s.geoid
  );

CREATE TABLE validation.tier2_range AS
SELECT 'pct_low_income' AS column_name,
       count(*) FILTER (WHERE pct_low_income < 0 OR pct_low_income > 1) AS outside_0_1
FROM marts.acs_block_group
UNION ALL
SELECT 'pct_people_of_color', count(*) FILTER (WHERE pct_people_of_color < 0 OR pct_people_of_color > 1)
FROM marts.acs_block_group
UNION ALL
SELECT 'pct_limited_english', count(*) FILTER (WHERE pct_limited_english < 0 OR pct_limited_english > 1)
FROM marts.acs_block_group
UNION ALL
SELECT 'pct_less_than_hs', count(*) FILTER (WHERE pct_less_than_hs < 0 OR pct_less_than_hs > 1)
FROM marts.acs_block_group
UNION ALL
SELECT 'pct_unemployed', count(*) FILTER (WHERE pct_unemployed < 0 OR pct_unemployed > 1)
FROM marts.acs_block_group
UNION ALL
SELECT 'pct_under_5', count(*) FILTER (WHERE pct_under_5 < 0 OR pct_under_5 > 1)
FROM marts.acs_block_group
UNION ALL
SELECT 'pct_over_64', count(*) FILTER (WHERE pct_over_64 < 0 OR pct_over_64 > 1)
FROM marts.acs_block_group
UNION ALL
SELECT 'pct_disability', count(*) FILTER (WHERE pct_disability < 0 OR pct_disability > 1)
FROM marts.acs_block_group
UNION ALL
SELECT 'pct_low_life_expectancy', count(*) FILTER (WHERE pct_low_life_expectancy < 0 OR pct_low_life_expectancy > 1)
FROM marts.acs_block_group;

-- Same 1e-8 tolerance as the column check. This split is a description of rows already outside that bar.
CREATE TABLE validation.tier2_direction AS
SELECT column_name,
       count(*) FILTER (
         WHERE rebuilt IS NOT NULL AND reference IS NOT NULL AND abs(rebuilt - reference) > 1e-8 AND rebuilt < reference
       ) AS rebuilt_lower,
       count(*) FILTER (
         WHERE rebuilt IS NOT NULL AND reference IS NOT NULL AND abs(rebuilt - reference) > 1e-8 AND rebuilt > reference
       ) AS rebuilt_higher,
       percentile_cont(0.5) WITHIN GROUP (
         ORDER BY (reference - rebuilt)
       ) FILTER (
         WHERE rebuilt IS NOT NULL AND reference IS NOT NULL AND abs(rebuilt - reference) > 1e-8
       ) AS median_reference_minus_rebuilt
FROM validation.tier2_pair
GROUP BY column_name;

CREATE TABLE validation.tier2_zero_denominator AS
WITH denom AS (
  SELECT
    lpad("state", 2, '0') || lpad("county", 3, '0') || lpad("tract", 6, '0') || lpad("block group", 1, '0') AS geoid,
    staging.acs_count("C17002_001E") AS lowinc_denom,
    staging.acs_count("B03002_001E") AS color_denom,
    staging.acs_count("C16002_001E") AS ling_denom,
    staging.acs_count("B15002_001E") AS edu_denom,
    staging.acs_count("B23025_003E") AS unemp_denom,
    staging.acs_count("B01001_001E") AS age_denom
  FROM raw.acs2022_block_group
),
paired AS (
  SELECT v.column_name, v.rebuilt, v.reference, v.denominator
  FROM marts.acs_block_group a
  JOIN staging.block_group_inputs s ON s.geoid = a.geoid
  JOIN raw.ejscreen_reference r ON r."ID" = s.source_id
  JOIN denom d ON d.geoid = a.geoid
  CROSS JOIN LATERAL (VALUES
    ('LOWINCPCT', a.pct_low_income, NULLIF(r."LOWINCPCT", '')::double precision, d.lowinc_denom),
    ('PEOPCOLORPCT', a.pct_people_of_color, NULLIF(r."PEOPCOLORPCT", '')::double precision, d.color_denom),
    ('LINGISOPCT', a.pct_limited_english, NULLIF(r."LINGISOPCT", '')::double precision, d.ling_denom),
    ('LESSHSPCT', a.pct_less_than_hs, NULLIF(r."LESSHSPCT", '')::double precision, d.edu_denom),
    ('UNEMPPCT', a.pct_unemployed, NULLIF(r."UNEMPPCT", '')::double precision, d.unemp_denom),
    ('UNDER5PCT', a.pct_under_5, NULLIF(r."UNDER5PCT", '')::double precision, d.age_denom),
    ('OVER64PCT', a.pct_over_64, NULLIF(r."OVER64PCT", '')::double precision, d.age_denom)
  ) AS v(column_name, rebuilt, reference, denominator)
)
SELECT column_name,
       count(*) FILTER (
         WHERE rebuilt IS NULL AND reference = 0 AND denominator = 0
       ) AS null_reference_zero,
       count(*) FILTER (
         WHERE rebuilt IS NULL
           AND reference IS NOT NULL
           AND NOT (reference = 0 AND denominator = 0)
       ) AS other_rebuilt_null
FROM paired
GROUP BY column_name;

CREATE TABLE validation.usaleep_fit AS
WITH file_stats AS (
  SELECT count(*) AS file_rows,
         min(NULLIF(life_expectancy, '')::double precision) AS min_le,
         max(NULLIF(life_expectancy, '')::double precision) AS max_le
  FROM raw.usaleep_2010_tract
),
joined AS (
  SELECT lpad(u.tract_id, 11, '0') AS tract_geoid,
         NULLIF(u.life_expectancy, '')::double precision AS life_expectancy,
         NULLIF(r."LIFEEXPPCT", '')::double precision AS published
  FROM raw.usaleep_2010_tract u
  JOIN staging.block_group_inputs s
    ON left(s.geoid, 11) = lpad(u.tract_id, 11, '0')
   AND s.in_national_universe
  JOIN raw.ejscreen_reference r ON r."ID" = s.source_id
),
usable AS (
  SELECT life_expectancy / (1.0 - published) AS implied_max,
         (SELECT max_le FROM file_stats) AS file_max
  FROM joined
  WHERE life_expectancy IS NOT NULL
    AND published IS NOT NULL
    AND published > 0
    AND published < 1
)
SELECT
  (SELECT file_rows FROM file_stats) AS file_rows,
  (SELECT min_le FROM file_stats) AS min_life_expectancy,
  (SELECT max_le FROM file_stats) AS max_life_expectancy,
  (SELECT count(*) FROM joined) AS joined_block_groups,
  (SELECT count(DISTINCT tract_geoid) FROM joined) AS joined_tracts,
  (SELECT count(*) FROM usable) AS usable_rows,
  (SELECT min(implied_max) FROM usable) AS implied_max_min,
  (SELECT percentile_cont(0.05) WITHIN GROUP (ORDER BY implied_max) FROM usable) AS implied_max_p05,
  (SELECT percentile_cont(0.5) WITHIN GROUP (ORDER BY implied_max) FROM usable) AS implied_max_median,
  (SELECT percentile_cont(0.95) WITHIN GROUP (ORDER BY implied_max) FROM usable) AS implied_max_p95,
  (SELECT max(implied_max) FROM usable) AS implied_max_max,
  (SELECT stddev_samp(implied_max) FROM usable) AS implied_max_sd,
  -- Fit against the maximum life expectancy in the file. These counts are not a pass threshold.
  (SELECT count(*) FROM usable WHERE abs(implied_max - file_max) <= 1e-6) AS implied_near_file_max,
  (SELECT count(*) FROM usable WHERE abs(implied_max - file_max) > 1) AS implied_beyond_one_year,
  (
    SELECT count(*)
    FROM staging.block_group_inputs s
    JOIN raw.ejscreen_reference r ON r."ID" = s.source_id
    WHERE s.in_national_universe
      AND NULLIF(r."LIFEEXPPCT", '') IS NOT NULL
      AND NOT EXISTS (
        SELECT 1 FROM raw.usaleep_2010_tract u
        WHERE lpad(u.tract_id, 11, '0') = left(s.geoid, 11)
      )
  ) AS published_rows_without_same_tract_id;

-- Coverage of the adopted life expectancy assignment. Not a pass threshold.
CREATE TABLE validation.life_coverage AS
WITH direct AS (
  SELECT DISTINCT lpad(tract_id, 11, '0') AS tract_geoid
  FROM raw.usaleep_2010_tract
  WHERE NULLIF(life_expectancy, '') IS NOT NULL
),
parents AS (
  SELECT geoid_tract_20, count(DISTINCT geoid_tract_10) AS n_parents
  FROM raw.tract_rel_2020_2010
  GROUP BY geoid_tract_20
),
rows AS (
  SELECT a.geoid,
         left(a.geoid, 11) AS tract_2022,
         left(a.geoid, 2) AS state_fips,
         a.pct_low_life_expectancy IS NOT NULL AS assigned,
         d.tract_geoid IS NOT NULL AS direct_id,
         p.n_parents
  FROM marts.acs_block_group a
  LEFT JOIN direct d ON d.tract_geoid = left(a.geoid, 11)
  LEFT JOIN parents p ON p.geoid_tract_20 = left(a.geoid, 11)
)
SELECT
  count(*) FILTER (WHERE direct_id) AS direct_block_groups,
  count(*) FILTER (WHERE NOT direct_id AND n_parents = 1 AND assigned) AS single_parent_block_groups,
  count(*) FILTER (WHERE NOT direct_id AND n_parents > 1) AS multi_parent_block_groups,
  count(*) FILTER (WHERE NOT direct_id AND n_parents > 1 AND assigned) AS multi_parent_assigned,
  count(*) FILTER (WHERE NOT direct_id AND n_parents > 1 AND NOT assigned) AS multi_parent_unassigned,
  count(*) FILTER (WHERE NOT direct_id AND n_parents IS NULL) AS no_2020_tract_block_groups,
  count(*) FILTER (WHERE state_fips = '09' AND assigned) AS connecticut_assigned,
  count(*) FILTER (WHERE state_fips = '09' AND NOT assigned) AS connecticut_unassigned
FROM rows;

-- Why a published life expectancy is still null in the rebuild. Not a pass threshold.
CREATE TABLE validation.life_null_reason AS
WITH direct AS (
  SELECT DISTINCT lpad(tract_id, 11, '0') AS tract_geoid
  FROM raw.usaleep_2010_tract
  WHERE NULLIF(life_expectancy, '') IS NOT NULL
),
parents AS (
  SELECT geoid_tract_20, count(DISTINCT geoid_tract_10) AS n_parents
  FROM raw.tract_rel_2020_2010
  GROUP BY geoid_tract_20
)
SELECT
  count(*) FILTER (
    WHERE a.pct_low_life_expectancy IS NULL
      AND NULLIF(r."LIFEEXPPCT", '') IS NOT NULL
      AND a.state_fips = '09'
  ) AS connecticut_reference,
  count(*) FILTER (
    WHERE a.pct_low_life_expectancy IS NULL
      AND NULLIF(r."LIFEEXPPCT", '') IS NOT NULL
      AND a.state_fips <> '09'
      AND p.n_parents > 1
  ) AS multi_parent_reference,
  count(*) FILTER (
    WHERE a.pct_low_life_expectancy IS NULL
      AND NULLIF(r."LIFEEXPPCT", '') IS NOT NULL
      AND a.state_fips <> '09'
      AND d.tract_geoid IS NULL
      AND p.n_parents = 1
  ) AS single_parent_reference,
  count(*) FILTER (
    WHERE a.pct_low_life_expectancy IS NULL
      AND NULLIF(r."LIFEEXPPCT", '') IS NOT NULL
      AND a.state_fips <> '09'
      AND d.tract_geoid IS NULL
      AND p.n_parents IS NULL
  ) AS other_reference,
  count(*) FILTER (
    WHERE a.pct_low_life_expectancy IS NOT NULL
      AND NULLIF(r."LIFEEXPPCT", '') IS NULL
      AND a.state_fips = '09'
  ) AS connecticut_reference_blank
FROM marts.acs_block_group a
JOIN staging.block_group_inputs s ON s.geoid = a.geoid AND s.in_national_universe
JOIN raw.ejscreen_reference r ON r."ID" = s.source_id
LEFT JOIN direct d ON d.tract_geoid = left(a.geoid, 11)
LEFT JOIN parents p ON p.geoid_tract_20 = left(a.geoid, 11);

-- Supplemental gap on rows whose low life expectancy already matches.
-- Not a pass threshold. Used to see whether the life expectancy moments moved.
CREATE TABLE validation.life_match_gap AS
SELECT
  count(*) FILTER (
    WHERE le.rebuilt IS NOT NULL AND le.reference IS NOT NULL
      AND abs(le.rebuilt - le.reference) <= 1e-8
  ) AS le_match_rows,
  count(*) FILTER (
    WHERE le.rebuilt IS NOT NULL AND le.reference IS NOT NULL
      AND abs(le.rebuilt - le.reference) <= 1e-8
      AND abs(d5.rebuilt - d5.reference) <= 1e-8
  ) AS demogidx_5_within_on_le_match,
  percentile_cont(0.5) WITHIN GROUP (ORDER BY abs(d5.rebuilt - d5.reference)) FILTER (
    WHERE le.rebuilt IS NOT NULL AND le.reference IS NOT NULL
      AND abs(le.rebuilt - le.reference) <= 1e-8
      AND d5.rebuilt IS NOT NULL AND d5.reference IS NOT NULL
  ) AS demogidx_5_median_abs_on_le_match,
  count(*) FILTER (
    WHERE le.rebuilt IS NOT NULL AND le.reference IS NOT NULL
      AND abs(le.rebuilt - le.reference) <= 1e-8
      AND abs(d5st.rebuilt - d5st.reference) <= 1e-8
  ) AS demogidx_5st_within_on_le_match,
  percentile_cont(0.5) WITHIN GROUP (ORDER BY abs(d5st.rebuilt - d5st.reference)) FILTER (
    WHERE le.rebuilt IS NOT NULL AND le.reference IS NOT NULL
      AND abs(le.rebuilt - le.reference) <= 1e-8
      AND d5st.rebuilt IS NOT NULL AND d5st.reference IS NOT NULL
  ) AS demogidx_5st_median_abs_on_le_match,
  count(*) FILTER (WHERE le.rebuilt IS NULL AND le.reference IS NOT NULL) AS life_rebuilt_null
FROM validation.tier2_pair le
JOIN validation.tier2_pair d5
  ON d5.geoid = le.geoid AND d5.column_name = 'DEMOGIDX_5'
JOIN validation.tier2_pair d5st
  ON d5st.geoid = le.geoid AND d5st.column_name = 'DEMOGIDX_5ST'
WHERE le.column_name = 'LIFEEXPPCT';

-- Multi-parent rows filled by the block population weight. Not a pass threshold.
CREATE TABLE validation.life_multi_fit AS
WITH le_2010 AS (
  SELECT lpad(tract_id, 11, '0') AS tract_geoid,
         max(NULLIF(life_expectancy, '')::double precision) AS le
  FROM raw.usaleep_2010_tract
  GROUP BY 1
),
direct AS (
  SELECT tract_geoid FROM le_2010 WHERE le IS NOT NULL
),
single_parent AS (
  SELECT rel.geoid_tract_20 AS tract_geoid
  FROM raw.tract_rel_2020_2010 rel
  LEFT JOIN le_2010 ON le_2010.tract_geoid = rel.geoid_tract_10
  GROUP BY rel.geoid_tract_20
  HAVING count(DISTINCT rel.geoid_tract_10) = 1
),
filled AS (
  SELECT m.le,
         a.pct_low_life_expectancy AS rebuilt,
         NULLIF(r."LIFEEXPPCT", '')::double precision AS reference
  FROM marts.acs_block_group a
  JOIN staging.le_multi_parent m
    ON m.tract_geoid = left(a.geoid, 11)
   AND m.le IS NOT NULL
  JOIN staging.block_group_inputs s ON s.geoid = a.geoid
  JOIN raw.ejscreen_reference r ON r."ID" = s.source_id
  LEFT JOIN direct d ON d.tract_geoid = left(a.geoid, 11)
  LEFT JOIN single_parent sp ON sp.tract_geoid = left(a.geoid, 11)
  WHERE d.tract_geoid IS NULL
    AND sp.tract_geoid IS NULL
    AND a.pct_low_life_expectancy IS NOT NULL
)
SELECT
  count(*) FILTER (WHERE reference IS NOT NULL) AS compared,
  count(*) FILTER (
    WHERE reference IS NOT NULL AND abs(rebuilt - reference) <= 1e-8
  ) AS within_1e8,
  count(*) FILTER (
    WHERE reference > 0 AND reference < 1
      AND abs(le / (1.0 - reference) - 97.5) <= 1e-6
  ) AS near_975,
  count(*) FILTER (
    WHERE reference > 0 AND reference < 1
      AND abs(le / (1.0 - reference) - 97.5) <= 1e-6
      AND abs(rebuilt - reference) <= 1e-8
  ) AS near_975_within,
  count(*) FILTER (
    WHERE reference > 0 AND reference < 1
      AND abs(le / (1.0 - reference) - 97.5) <= 1e-6
      AND abs(rebuilt - reference) > 1e-8
  ) AS near_975_miss
FROM filled;

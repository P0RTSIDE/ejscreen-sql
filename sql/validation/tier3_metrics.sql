-- Tier 3 thresholds, the same bars as Tier 1 and Tier 2.
-- Continuous absolute tolerance is 1e-8.
-- Exact and tolerance pass at 99 percent of rows where both values are present.
-- Null agreement passes at 99.9 percent.
-- A low match rate is stored and reported. It does not raise an exception.
-- These numbers are not revised after the scores are known.

SET statement_timeout = 0;
SET work_mem = '256MB';
SET max_parallel_workers_per_gather = 0;

DO $$
BEGIN
  IF to_regclass('staging.tier3_lead_paint') IS NULL
     OR to_regclass('staging.tier3_superfund') IS NULL
     OR to_regclass('staging.tier3_hazwaste') IS NULL
     OR to_regclass('staging.tier3_traffic') IS NULL THEN
    RAISE EXCEPTION 'Tier 3 indicator tables are missing. Run sql/100_tier3_lead.sql, sql/102_tier3_proximity.sql, and sql/103_tier3_traffic.sql before validate.';
  END IF;
END $$;

DROP TABLE IF EXISTS validation.tier3_pair;
DROP TABLE IF EXISTS validation.tier3_column_result;
DROP TABLE IF EXISTS validation.tier3_worst;
DROP TABLE IF EXISTS validation.tier3_geoid_gap;
DROP TABLE IF EXISTS validation.tier3_cluster;

CREATE TABLE validation.tier3_pair AS
SELECT v.column_name,
       g.geoid,
       g.state_fips,
       g.state_abbrev,
       v.rebuilt,
       v.reference
FROM staging.block_group_inputs g
JOIN raw.ejscreen_reference r ON r."ID" = g.source_id
LEFT JOIN staging.tier3_lead_paint lead ON lead.geoid = g.geoid
LEFT JOIN staging.tier3_superfund npl ON npl.geoid = g.geoid
LEFT JOIN staging.tier3_hazwaste haz ON haz.geoid = g.geoid
LEFT JOIN staging.tier3_traffic traf ON traf.geoid = g.geoid
CROSS JOIN LATERAL (VALUES
  ('PRE1960PCT', lead.lead_paint, NULLIF(r."PRE1960PCT", '')::double precision),
  ('PNPL', npl.superfund, NULLIF(r."PNPL", '')::double precision),
  ('PTSDF', haz.hazardous_waste, NULLIF(r."PTSDF", '')::double precision),
  ('PTRAF', traf.traffic, NULLIF(r."PTRAF", '')::double precision)
) AS v(column_name, rebuilt, reference)
WHERE g.in_national_universe;

CREATE TABLE validation.tier3_column_result AS
WITH base AS (
  SELECT column_name, state_fips, rebuilt, reference,
         1e-8::double precision AS tol
  FROM validation.tier3_pair
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
         percentile_cont(0.25) WITHIN GROUP (ORDER BY abs_diff) AS abs_p25,
         percentile_cont(0.5) WITHIN GROUP (ORDER BY abs_diff) AS abs_median,
         percentile_cont(0.75) WITHIN GROUP (ORDER BY abs_diff) AS abs_p75,
         percentile_cont(0.95) WITHIN GROUP (ORDER BY abs_diff) AS abs_p95,
         max(abs_diff) AS abs_max,
         avg(abs_diff) AS abs_mean
  FROM (
    SELECT 'all'::text AS slice, column_name, abs(rebuilt - reference) AS abs_diff
    FROM validation.tier3_pair
    WHERE rebuilt IS NOT NULL AND reference IS NOT NULL
    UNION ALL
    SELECT 'state_fips_' || COALESCE(current_setting('ejscreen.state_fips', true), '06'),
           column_name, abs(rebuilt - reference)
    FROM validation.tier3_pair
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
    FROM validation.tier3_pair
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
    FROM validation.tier3_pair
    WHERE rebuilt IS NOT NULL AND reference IS NOT NULL
      AND state_fips = COALESCE(current_setting('ejscreen.state_fips', true), '06')
  ) r
  GROUP BY slice, column_name
)
SELECT a.slice, a.column_name, a.n_rows, a.both_present, a.both_null,
       a.rebuilt_null, a.reference_null, a.exact_n, a.within_tol_n, a.pearson, k.spearman,
       d.abs_min, d.abs_p25, d.abs_median, d.abs_p75, d.abs_p95, d.abs_max, d.abs_mean,
       CASE WHEN a.both_present = 0 THEN (a.rebuilt_null + a.reference_null) = 0
            ELSE a.exact_n::numeric / a.both_present >= 0.99 END AS exact_pass,
       CASE WHEN a.both_present = 0 THEN (a.rebuilt_null + a.reference_null) = 0
            ELSE a.within_tol_n::numeric / a.both_present >= 0.99 END AS tolerance_pass,
       ((a.n_rows - a.rebuilt_null - a.reference_null)::numeric / NULLIF(a.n_rows, 0)) >= 0.999 AS null_pass
FROM agg a
LEFT JOIN diffs d USING (slice, column_name)
LEFT JOIN ranked k USING (slice, column_name);

CREATE TABLE validation.tier3_worst AS
SELECT column_name, geoid, state_abbrev, state_fips, rebuilt, reference, abs_diff
FROM (
  SELECT column_name, geoid, state_abbrev, state_fips, rebuilt, reference,
         abs(rebuilt - reference) AS abs_diff,
         row_number() OVER (
           PARTITION BY column_name
           ORDER BY abs(rebuilt - reference) DESC, geoid
         ) AS rn
  FROM validation.tier3_pair
  WHERE rebuilt IS NOT NULL AND reference IS NOT NULL
) ranked
WHERE rn <= 20;

CREATE TABLE validation.tier3_geoid_gap AS
SELECT 'reference_missing_lead' AS gap_side, g.geoid
FROM staging.block_group_inputs g
WHERE g.in_national_universe
  AND NOT EXISTS (SELECT 1 FROM staging.tier3_lead_paint t WHERE t.geoid = g.geoid)
UNION ALL
SELECT 'reference_missing_superfund', g.geoid
FROM staging.block_group_inputs g
WHERE g.in_national_universe
  AND NOT EXISTS (SELECT 1 FROM staging.tier3_superfund t WHERE t.geoid = g.geoid)
UNION ALL
SELECT 'reference_missing_hazwaste', g.geoid
FROM staging.block_group_inputs g
WHERE g.in_national_universe
  AND NOT EXISTS (SELECT 1 FROM staging.tier3_hazwaste t WHERE t.geoid = g.geoid)
UNION ALL
SELECT 'reference_missing_traffic', g.geoid
FROM staging.block_group_inputs g
WHERE g.in_national_universe
  AND NOT EXISTS (SELECT 1 FROM staging.tier3_traffic t WHERE t.geoid = g.geoid)
UNION ALL
SELECT 'lead_missing_reference', t.geoid
FROM staging.tier3_lead_paint t
WHERE NOT EXISTS (
  SELECT 1 FROM staging.block_group_inputs g
  WHERE g.geoid = t.geoid AND g.in_national_universe
)
UNION ALL
SELECT 'superfund_missing_reference', t.geoid
FROM staging.tier3_superfund t
WHERE NOT EXISTS (
  SELECT 1 FROM staging.block_group_inputs g
  WHERE g.geoid = t.geoid AND g.in_national_universe
)
UNION ALL
SELECT 'hazwaste_missing_reference', t.geoid
FROM staging.tier3_hazwaste t
WHERE NOT EXISTS (
  SELECT 1 FROM staging.block_group_inputs g
  WHERE g.geoid = t.geoid AND g.in_national_universe
)
UNION ALL
SELECT 'traffic_missing_reference', t.geoid
FROM staging.tier3_traffic t
WHERE NOT EXISTS (
  SELECT 1 FROM staging.block_group_inputs g
  WHERE g.geoid = t.geoid AND g.in_national_universe
);

CREATE TABLE validation.tier3_cluster AS
SELECT column_name,
       state_abbrev,
       CASE
         WHEN reference = 0 AND rebuilt = 0 THEN 'both_zero'
         WHEN reference = 0 AND rebuilt > 0 THEN 'reference_zero_rebuilt_positive'
         WHEN rebuilt = 0 AND reference > 0 THEN 'rebuilt_zero_reference_positive'
         WHEN rebuilt > reference THEN 'rebuilt_higher'
         WHEN rebuilt < reference THEN 'rebuilt_lower'
         ELSE 'other'
       END AS cluster,
       count(*) AS n,
       percentile_cont(0.5) WITHIN GROUP (ORDER BY abs(rebuilt - reference)) AS median_abs
FROM validation.tier3_pair
WHERE rebuilt IS NOT NULL AND reference IS NOT NULL
GROUP BY 1, 2, 3;

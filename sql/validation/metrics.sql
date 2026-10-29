SET statement_timeout = 0;
SET work_mem = '256MB';
SET max_parallel_workers_per_gather = 0;
SET maintenance_work_mem = '512MB';

DROP TABLE IF EXISTS validation.reference_value;
DROP TABLE IF EXISTS validation.pair;
DROP TABLE IF EXISTS validation.column_result;
DROP TABLE IF EXISTS validation.worst_mismatch;
DROP TABLE IF EXISTS validation.geoid_gap;
DROP TABLE IF EXISTS validation.percent_rank_summary;
DROP TABLE IF EXISTS validation.raw_agreement;
DROP TABLE IF EXISTS validation.universe;
DROP TABLE IF EXISTS validation.worked_example;
DROP TABLE IF EXISTS validation.ca_top;

CREATE TABLE validation.universe AS
SELECT count(*) AS total_rows,
       count(*) FILTER (WHERE in_national_universe) AS states_dc_pr,
       count(*) FILTER (WHERE NOT in_national_universe) AS territories,
       (count(*) FILTER (WHERE in_national_universe) = 242336) AS states_dc_pr_matches_tech_doc
FROM staging.block_group_inputs;

CREATE TABLE validation.reference_value (
  scope text NOT NULL,
  column_name text NOT NULL,
  kind text NOT NULL,
  geoid text NOT NULL,
  value double precision
);


INSERT INTO validation.reference_value (scope, column_name, kind, geoid, value)
SELECT 'national_file', v.column_name, v.kind, s.geoid, NULLIF(v.raw, '')::double precision
FROM raw.ejscreen_reference r
JOIN staging.block_group_inputs s ON s.source_id = r."ID"
CROSS JOIN LATERAL (VALUES
    ('DEMOGIDX_2', 'continuous', r."DEMOGIDX_2"),
    ('DEMOGIDX_5', 'continuous', r."DEMOGIDX_5"),
    ('DEMOGIDX_2ST', 'continuous', r."DEMOGIDX_2ST"),
    ('DEMOGIDX_5ST', 'continuous', r."DEMOGIDX_5ST"),
    ('P_DEMOGIDX_2', 'percentile', r."P_DEMOGIDX_2"),
    ('P_DEMOGIDX_5', 'percentile', r."P_DEMOGIDX_5"),
    ('P_PEOPCOLORPCT', 'percentile', r."P_PEOPCOLORPCT"),
    ('P_LOWINCPCT', 'percentile', r."P_LOWINCPCT"),
    ('P_UNEMPPCT', 'percentile', r."P_UNEMPPCT"),
    ('P_DISABILITYPCT', 'percentile', r."P_DISABILITYPCT"),
    ('P_LINGISOPCT', 'percentile', r."P_LINGISOPCT"),
    ('P_LESSHSPCT', 'percentile', r."P_LESSHSPCT"),
    ('P_UNDER5PCT', 'percentile', r."P_UNDER5PCT"),
    ('P_OVER64PCT', 'percentile', r."P_OVER64PCT"),
    ('P_LIFEEXPPCT', 'percentile', r."P_LIFEEXPPCT"),
    ('P_PM25', 'percentile', r."P_PM25"),
    ('P_OZONE', 'percentile', r."P_OZONE"),
    ('P_DSLPM', 'percentile', r."P_DSLPM"),
    ('P_RSEI_AIR', 'percentile', r."P_RSEI_AIR"),
    ('P_PTRAF', 'percentile', r."P_PTRAF"),
    ('P_LDPNT', 'percentile', r."P_LDPNT"),
    ('P_PNPL', 'percentile', r."P_PNPL"),
    ('P_PRMP', 'percentile', r."P_PRMP"),
    ('P_PTSDF', 'percentile', r."P_PTSDF"),
    ('P_UST', 'percentile', r."P_UST"),
    ('P_PWDIS', 'percentile', r."P_PWDIS"),
    ('P_NO2', 'percentile', r."P_NO2"),
    ('P_DWATER', 'percentile', r."P_DWATER"),
    ('D2_PM25', 'continuous', r."D2_PM25"),
    ('P_D2_PM25', 'percentile', r."P_D2_PM25"),
    ('D5_PM25', 'continuous', r."D5_PM25"),
    ('P_D5_PM25', 'percentile', r."P_D5_PM25"),
    ('D2_OZONE', 'continuous', r."D2_OZONE"),
    ('P_D2_OZONE', 'percentile', r."P_D2_OZONE"),
    ('D5_OZONE', 'continuous', r."D5_OZONE"),
    ('P_D5_OZONE', 'percentile', r."P_D5_OZONE"),
    ('D2_DSLPM', 'continuous', r."D2_DSLPM"),
    ('P_D2_DSLPM', 'percentile', r."P_D2_DSLPM"),
    ('D5_DSLPM', 'continuous', r."D5_DSLPM"),
    ('P_D5_DSLPM', 'percentile', r."P_D5_DSLPM"),
    ('D2_RSEI_AIR', 'continuous', r."D2_RSEI_AIR"),
    ('P_D2_RSEI_AIR', 'percentile', r."P_D2_RSEI_AIR"),
    ('D5_RSEI_AIR', 'continuous', r."D5_RSEI_AIR"),
    ('P_D5_RSEI_AIR', 'percentile', r."P_D5_RSEI_AIR"),
    ('D2_PTRAF', 'continuous', r."D2_PTRAF"),
    ('P_D2_PTRAF', 'percentile', r."P_D2_PTRAF"),
    ('D5_PTRAF', 'continuous', r."D5_PTRAF"),
    ('P_D5_PTRAF', 'percentile', r."P_D5_PTRAF"),
    ('D2_LDPNT', 'continuous', r."D2_LDPNT"),
    ('P_D2_LDPNT', 'percentile', r."P_D2_LDPNT"),
    ('D5_LDPNT', 'continuous', r."D5_LDPNT"),
    ('P_D5_LDPNT', 'percentile', r."P_D5_LDPNT"),
    ('D2_PNPL', 'continuous', r."D2_PNPL"),
    ('P_D2_PNPL', 'percentile', r."P_D2_PNPL"),
    ('D5_PNPL', 'continuous', r."D5_PNPL"),
    ('P_D5_PNPL', 'percentile', r."P_D5_PNPL"),
    ('D2_PRMP', 'continuous', r."D2_PRMP"),
    ('P_D2_PRMP', 'percentile', r."P_D2_PRMP"),
    ('D5_PRMP', 'continuous', r."D5_PRMP"),
    ('P_D5_PRMP', 'percentile', r."P_D5_PRMP"),
    ('D2_PTSDF', 'continuous', r."D2_PTSDF"),
    ('P_D2_PTSDF', 'percentile', r."P_D2_PTSDF"),
    ('D5_PTSDF', 'continuous', r."D5_PTSDF"),
    ('P_D5_PTSDF', 'percentile', r."P_D5_PTSDF"),
    ('D2_UST', 'continuous', r."D2_UST"),
    ('P_D2_UST', 'percentile', r."P_D2_UST"),
    ('D5_UST', 'continuous', r."D5_UST"),
    ('P_D5_UST', 'percentile', r."P_D5_UST"),
    ('D2_PWDIS', 'continuous', r."D2_PWDIS"),
    ('P_D2_PWDIS', 'percentile', r."P_D2_PWDIS"),
    ('D5_PWDIS', 'continuous', r."D5_PWDIS"),
    ('P_D5_PWDIS', 'percentile', r."P_D5_PWDIS"),
    ('D2_NO2', 'continuous', r."D2_NO2"),
    ('P_D2_NO2', 'percentile', r."P_D2_NO2"),
    ('D5_NO2', 'continuous', r."D5_NO2"),
    ('P_D5_NO2', 'percentile', r."P_D5_NO2"),
    ('D2_DWATER', 'continuous', r."D2_DWATER"),
    ('P_D2_DWATER', 'percentile', r."P_D2_DWATER"),
    ('D5_DWATER', 'continuous', r."D5_DWATER"),
    ('P_D5_DWATER', 'percentile', r."P_D5_DWATER")
) AS v(column_name, kind, raw);


INSERT INTO validation.reference_value (scope, column_name, kind, geoid, value)
SELECT 'state_file', v.column_name, v.kind, s.geoid, NULLIF(v.raw, '')::double precision
FROM raw.ejscreen_reference_state_pct r
JOIN staging.block_group_inputs s ON s.source_id = r."ID"
CROSS JOIN LATERAL (VALUES
    ('DEMOGIDX_2', 'continuous', r."DEMOGIDX_2"),
    ('DEMOGIDX_5', 'continuous', r."DEMOGIDX_5"),
    ('P_DEMOGIDX_2', 'percentile', r."P_DEMOGIDX_2"),
    ('P_DEMOGIDX_5', 'percentile', r."P_DEMOGIDX_5"),
    ('P_PEOPCOLORPCT', 'percentile', r."P_PEOPCOLORPCT"),
    ('P_LOWINCPCT', 'percentile', r."P_LOWINCPCT"),
    ('P_UNEMPPCT', 'percentile', r."P_UNEMPPCT"),
    ('P_DISABILITYPCT', 'percentile', r."P_DISABILITYPCT"),
    ('P_LINGISOPCT', 'percentile', r."P_LINGISOPCT"),
    ('P_LESSHSPCT', 'percentile', r."P_LESSHSPCT"),
    ('P_UNDER5PCT', 'percentile', r."P_UNDER5PCT"),
    ('P_OVER64PCT', 'percentile', r."P_OVER64PCT"),
    ('P_LIFEEXPPCT', 'percentile', r."P_LIFEEXPPCT"),
    ('P_PM25', 'percentile', r."P_PM25"),
    ('P_OZONE', 'percentile', r."P_OZONE"),
    ('P_DSLPM', 'percentile', r."P_DSLPM"),
    ('P_RSEI_AIR', 'percentile', r."P_RSEI_AIR"),
    ('P_PTRAF', 'percentile', r."P_PTRAF"),
    ('P_LDPNT', 'percentile', r."P_LDPNT"),
    ('P_PNPL', 'percentile', r."P_PNPL"),
    ('P_PRMP', 'percentile', r."P_PRMP"),
    ('P_PTSDF', 'percentile', r."P_PTSDF"),
    ('P_UST', 'percentile', r."P_UST"),
    ('P_PWDIS', 'percentile', r."P_PWDIS"),
    ('P_NO2', 'percentile', r."P_NO2"),
    ('P_DWATER', 'percentile', r."P_DWATER"),
    ('D2_PM25', 'continuous', r."D2_PM25"),
    ('P_D2_PM25', 'percentile', r."P_D2_PM25"),
    ('D5_PM25', 'continuous', r."D5_PM25"),
    ('P_D5_PM25', 'percentile', r."P_D5_PM25"),
    ('D2_OZONE', 'continuous', r."D2_OZONE"),
    ('P_D2_OZONE', 'percentile', r."P_D2_OZONE"),
    ('D5_OZONE', 'continuous', r."D5_OZONE"),
    ('P_D5_OZONE', 'percentile', r."P_D5_OZONE"),
    ('D2_DSLPM', 'continuous', r."D2_DSLPM"),
    ('P_D2_DSLPM', 'percentile', r."P_D2_DSLPM"),
    ('D5_DSLPM', 'continuous', r."D5_DSLPM"),
    ('P_D5_DSLPM', 'percentile', r."P_D5_DSLPM"),
    ('D2_RSEI_AIR', 'continuous', r."D2_RSEI_AIR"),
    ('P_D2_RSEI_AIR', 'percentile', r."P_D2_RSEI_AIR"),
    ('D5_RSEI_AIR', 'continuous', r."D5_RSEI_AIR"),
    ('P_D5_RSEI_AIR', 'percentile', r."P_D5_RSEI_AIR"),
    ('D2_PTRAF', 'continuous', r."D2_PTRAF"),
    ('P_D2_PTRAF', 'percentile', r."P_D2_PTRAF"),
    ('D5_PTRAF', 'continuous', r."D5_PTRAF"),
    ('P_D5_PTRAF', 'percentile', r."P_D5_PTRAF"),
    ('D2_LDPNT', 'continuous', r."D2_LDPNT"),
    ('P_D2_LDPNT', 'percentile', r."P_D2_LDPNT"),
    ('D5_LDPNT', 'continuous', r."D5_LDPNT"),
    ('P_D5_LDPNT', 'percentile', r."P_D5_LDPNT"),
    ('D2_PNPL', 'continuous', r."D2_PNPL"),
    ('P_D2_PNPL', 'percentile', r."P_D2_PNPL"),
    ('D5_PNPL', 'continuous', r."D5_PNPL"),
    ('P_D5_PNPL', 'percentile', r."P_D5_PNPL"),
    ('D2_PRMP', 'continuous', r."D2_PRMP"),
    ('P_D2_PRMP', 'percentile', r."P_D2_PRMP"),
    ('D5_PRMP', 'continuous', r."D5_PRMP"),
    ('P_D5_PRMP', 'percentile', r."P_D5_PRMP"),
    ('D2_PTSDF', 'continuous', r."D2_PTSDF"),
    ('P_D2_PTSDF', 'percentile', r."P_D2_PTSDF"),
    ('D5_PTSDF', 'continuous', r."D5_PTSDF"),
    ('P_D5_PTSDF', 'percentile', r."P_D5_PTSDF"),
    ('D2_UST', 'continuous', r."D2_UST"),
    ('P_D2_UST', 'percentile', r."P_D2_UST"),
    ('D5_UST', 'continuous', r."D5_UST"),
    ('P_D5_UST', 'percentile', r."P_D5_UST"),
    ('D2_PWDIS', 'continuous', r."D2_PWDIS"),
    ('P_D2_PWDIS', 'percentile', r."P_D2_PWDIS"),
    ('D5_PWDIS', 'continuous', r."D5_PWDIS"),
    ('P_D5_PWDIS', 'percentile', r."P_D5_PWDIS"),
    ('D2_NO2', 'continuous', r."D2_NO2"),
    ('P_D2_NO2', 'percentile', r."P_D2_NO2"),
    ('D5_NO2', 'continuous', r."D5_NO2"),
    ('P_D5_NO2', 'percentile', r."P_D5_NO2"),
    ('D2_DWATER', 'continuous', r."D2_DWATER"),
    ('P_D2_DWATER', 'percentile', r."P_D2_DWATER"),
    ('D5_DWATER', 'continuous', r."D5_DWATER"),
    ('P_D5_DWATER', 'percentile', r."P_D5_DWATER")
) AS v(column_name, kind, raw);

CREATE INDEX reference_value_lookup ON validation.reference_value (scope, column_name, geoid);
ANALYZE validation.reference_value;

CREATE TABLE validation.pair AS
SELECT b.scope, b.column_name, b.kind, b.geoid, s.state_fips, s.state_abbrev,
       b.value AS rebuilt, f.value AS reference,
       s.pct_low_life_expectancy IS NULL AS life_expectancy_missing
FROM marts.rebuilt b
JOIN validation.reference_value f
  ON f.scope = b.scope AND f.column_name = b.column_name AND f.geoid = b.geoid
JOIN staging.block_group_inputs s ON s.geoid = b.geoid;

DO $pair$
BEGIN
  IF (SELECT count(*) FROM marts.rebuilt) <> (SELECT count(*) FROM validation.pair) THEN
    RAISE EXCEPTION 'Rebuilt rows did not all match a reference cell';
  END IF;
END;
$pair$;

CREATE INDEX pair_lookup ON validation.pair (scope, column_name, state_fips);
ANALYZE validation.pair;

CREATE TABLE validation.column_result AS
WITH base AS (
  SELECT scope, column_name, kind, state_fips, rebuilt, reference,
         CASE WHEN kind = 'percentile' THEN 0::double precision ELSE 1e-8 END AS tol
  FROM validation.pair
),
slices AS (
  SELECT scope, 'all'::text AS slice, column_name, kind, rebuilt, reference, tol FROM base
  UNION ALL
  SELECT scope, 'state_fips_' || COALESCE(current_setting('ejscreen.state_fips', true), '06'),
         column_name, kind, rebuilt, reference, tol
  FROM base
  WHERE state_fips = COALESCE(current_setting('ejscreen.state_fips', true), '06')
),
agg AS (
  SELECT scope, slice, column_name, kind,
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
  GROUP BY scope, slice, column_name, kind
),
diffs AS (
  SELECT scope, slice, column_name,
         min(abs_diff) AS abs_min,
         percentile_cont(0.5) WITHIN GROUP (ORDER BY abs_diff) AS abs_median,
         percentile_cont(0.95) WITHIN GROUP (ORDER BY abs_diff) AS abs_p95,
         max(abs_diff) AS abs_max
  FROM (
    SELECT scope, 'all'::text AS slice, column_name, abs(rebuilt - reference) AS abs_diff
    FROM validation.pair
    WHERE rebuilt IS NOT NULL AND reference IS NOT NULL
    UNION ALL
    SELECT scope, 'state_fips_' || COALESCE(current_setting('ejscreen.state_fips', true), '06'),
           column_name, abs(rebuilt - reference)
    FROM validation.pair
    WHERE rebuilt IS NOT NULL AND reference IS NOT NULL
      AND state_fips = COALESCE(current_setting('ejscreen.state_fips', true), '06')
  ) d
  GROUP BY scope, slice, column_name
),
ranked AS (
  SELECT scope, slice, column_name, corr(rank_rebuilt, rank_reference) AS spearman
  FROM (
    SELECT scope, 'all'::text AS slice, column_name,
           rank() OVER (PARTITION BY scope, column_name ORDER BY rebuilt) AS rank_rebuilt,
           rank() OVER (PARTITION BY scope, column_name ORDER BY reference) AS rank_reference
    FROM validation.pair
    WHERE rebuilt IS NOT NULL AND reference IS NOT NULL
  ) r
  GROUP BY scope, slice, column_name
  UNION ALL
  SELECT scope, slice, column_name, corr(rank_rebuilt, rank_reference)
  FROM (
    SELECT scope, 'state_fips_' || COALESCE(current_setting('ejscreen.state_fips', true), '06') AS slice,
           column_name,
           rank() OVER (PARTITION BY scope, column_name ORDER BY rebuilt) AS rank_rebuilt,
           rank() OVER (PARTITION BY scope, column_name ORDER BY reference) AS rank_reference
    FROM validation.pair
    WHERE rebuilt IS NOT NULL AND reference IS NOT NULL
      AND state_fips = COALESCE(current_setting('ejscreen.state_fips', true), '06')
  ) r
  GROUP BY scope, slice, column_name
),
rankdiff AS (
  SELECT scope, slice, column_name,
         min(gap) AS rankdiff_min,
         percentile_cont(0.5) WITHIN GROUP (ORDER BY gap) AS rankdiff_median,
         percentile_cont(0.95) WITHIN GROUP (ORDER BY gap) AS rankdiff_p95,
         max(gap) AS rankdiff_max
  FROM (
    SELECT scope, slice, column_name,
           abs(percent_rank() OVER (PARTITION BY scope, slice, column_name ORDER BY rebuilt)
               - percent_rank() OVER (PARTITION BY scope, slice, column_name ORDER BY reference)) * 100 AS gap
    FROM (
      SELECT scope, 'all'::text AS slice, column_name, rebuilt, reference
      FROM validation.pair
      WHERE rebuilt IS NOT NULL AND reference IS NOT NULL
      UNION ALL
      SELECT scope, 'state_fips_' || COALESCE(current_setting('ejscreen.state_fips', true), '06'),
             column_name, rebuilt, reference
      FROM validation.pair
      WHERE rebuilt IS NOT NULL AND reference IS NOT NULL
        AND state_fips = COALESCE(current_setting('ejscreen.state_fips', true), '06')
    ) p
  ) g
  GROUP BY scope, slice, column_name
)
SELECT a.scope, a.slice, a.column_name, a.kind, a.n_rows, a.both_present, a.both_null,
       a.rebuilt_null, a.reference_null, a.exact_n, a.within_tol_n, a.pearson, k.spearman,
       d.abs_min, d.abs_median, d.abs_p95, d.abs_max,
       g.rankdiff_min, g.rankdiff_median, g.rankdiff_p95, g.rankdiff_max,
       CASE WHEN a.both_present = 0 THEN (a.rebuilt_null + a.reference_null) = 0
            ELSE a.exact_n::numeric / a.both_present >= 0.99 END AS exact_pass,
       CASE WHEN a.both_present = 0 THEN (a.rebuilt_null + a.reference_null) = 0
            ELSE a.within_tol_n::numeric / a.both_present >= 0.99 END AS tolerance_pass,
       ((a.n_rows - a.rebuilt_null - a.reference_null)::numeric / a.n_rows) >= 0.999 AS null_pass
FROM agg a
LEFT JOIN diffs d USING (scope, slice, column_name)
LEFT JOIN ranked k USING (scope, slice, column_name)
LEFT JOIN rankdiff g USING (scope, slice, column_name);

CREATE TABLE validation.worst_mismatch AS
SELECT scope, column_name, kind, geoid, state_abbrev, rebuilt, reference,
       abs(rebuilt - reference) AS abs_diff, life_expectancy_missing
FROM validation.pair
WHERE rebuilt IS NOT NULL AND reference IS NOT NULL
ORDER BY abs(rebuilt - reference) DESC, scope, column_name, geoid
LIMIT 20;

CREATE TABLE validation.geoid_gap AS
SELECT 'national_raw_missing_from_staging' AS gap_side, n."ID" AS source_id
FROM raw.ejscreen_reference n
WHERE NOT EXISTS (SELECT 1 FROM staging.block_group_inputs s WHERE s.source_id = n."ID")
UNION ALL
SELECT 'staging_missing_from_national_raw', s.source_id
FROM staging.block_group_inputs s
WHERE NOT EXISTS (SELECT 1 FROM raw.ejscreen_reference n WHERE n."ID" = s.source_id)
UNION ALL
SELECT 'state_raw_missing_from_staging', n."ID"
FROM raw.ejscreen_reference_state_pct n
WHERE NOT EXISTS (SELECT 1 FROM staging.block_group_inputs s WHERE s.source_id = n."ID")
UNION ALL
SELECT 'staging_missing_from_state_raw', s.source_id
FROM staging.block_group_inputs s
WHERE NOT EXISTS (SELECT 1 FROM raw.ejscreen_reference_state_pct n WHERE n."ID" = s.source_id);

CREATE TABLE validation.percent_rank_summary AS
SELECT r.scope, r.percentile_column,
       count(*) AS n,
       min(abs(r.percent_rank_0_100 - p.value)) AS abs_min,
       percentile_cont(0.5) WITHIN GROUP (ORDER BY abs(r.percent_rank_0_100 - p.value)) AS abs_median,
       percentile_cont(0.95) WITHIN GROUP (ORDER BY abs(r.percent_rank_0_100 - p.value)) AS abs_p95,
       max(abs(r.percent_rank_0_100 - p.value)) AS abs_max,
       avg(abs(r.percent_rank_0_100 - p.value)) AS abs_mean
FROM marts.indicator_percent_rank r
JOIN marts.rebuilt p
  ON p.scope = r.scope
 AND p.column_name = r.percentile_column
 AND p.geoid = r.geoid
WHERE p.value IS NOT NULL
GROUP BY r.scope, r.percentile_column;

CREATE TABLE validation.raw_agreement AS
SELECT 'PEOPCOLORPCT' AS column_name,
       count(*) FILTER (
         WHERE NULLIF(n."PEOPCOLORPCT", '')::double precision IS DISTINCT FROM NULLIF(s."PEOPCOLORPCT", '')::double precision
       ) AS n_differ,
       max(abs(NULLIF(n."PEOPCOLORPCT", '')::double precision - NULLIF(s."PEOPCOLORPCT", '')::double precision)) AS max_abs
FROM raw.ejscreen_reference n
JOIN raw.ejscreen_reference_state_pct s ON s."ID" = n."ID"
UNION ALL
SELECT 'LOWINCPCT' AS column_name,
       count(*) FILTER (
         WHERE NULLIF(n."LOWINCPCT", '')::double precision IS DISTINCT FROM NULLIF(s."LOWINCPCT", '')::double precision
       ) AS n_differ,
       max(abs(NULLIF(n."LOWINCPCT", '')::double precision - NULLIF(s."LOWINCPCT", '')::double precision)) AS max_abs
FROM raw.ejscreen_reference n
JOIN raw.ejscreen_reference_state_pct s ON s."ID" = n."ID"
UNION ALL
SELECT 'UNEMPPCT' AS column_name,
       count(*) FILTER (
         WHERE NULLIF(n."UNEMPPCT", '')::double precision IS DISTINCT FROM NULLIF(s."UNEMPPCT", '')::double precision
       ) AS n_differ,
       max(abs(NULLIF(n."UNEMPPCT", '')::double precision - NULLIF(s."UNEMPPCT", '')::double precision)) AS max_abs
FROM raw.ejscreen_reference n
JOIN raw.ejscreen_reference_state_pct s ON s."ID" = n."ID"
UNION ALL
SELECT 'DISABILITYPCT' AS column_name,
       count(*) FILTER (
         WHERE NULLIF(n."DISABILITYPCT", '')::double precision IS DISTINCT FROM NULLIF(s."DISABILITYPCT", '')::double precision
       ) AS n_differ,
       max(abs(NULLIF(n."DISABILITYPCT", '')::double precision - NULLIF(s."DISABILITYPCT", '')::double precision)) AS max_abs
FROM raw.ejscreen_reference n
JOIN raw.ejscreen_reference_state_pct s ON s."ID" = n."ID"
UNION ALL
SELECT 'LINGISOPCT' AS column_name,
       count(*) FILTER (
         WHERE NULLIF(n."LINGISOPCT", '')::double precision IS DISTINCT FROM NULLIF(s."LINGISOPCT", '')::double precision
       ) AS n_differ,
       max(abs(NULLIF(n."LINGISOPCT", '')::double precision - NULLIF(s."LINGISOPCT", '')::double precision)) AS max_abs
FROM raw.ejscreen_reference n
JOIN raw.ejscreen_reference_state_pct s ON s."ID" = n."ID"
UNION ALL
SELECT 'LESSHSPCT' AS column_name,
       count(*) FILTER (
         WHERE NULLIF(n."LESSHSPCT", '')::double precision IS DISTINCT FROM NULLIF(s."LESSHSPCT", '')::double precision
       ) AS n_differ,
       max(abs(NULLIF(n."LESSHSPCT", '')::double precision - NULLIF(s."LESSHSPCT", '')::double precision)) AS max_abs
FROM raw.ejscreen_reference n
JOIN raw.ejscreen_reference_state_pct s ON s."ID" = n."ID"
UNION ALL
SELECT 'UNDER5PCT' AS column_name,
       count(*) FILTER (
         WHERE NULLIF(n."UNDER5PCT", '')::double precision IS DISTINCT FROM NULLIF(s."UNDER5PCT", '')::double precision
       ) AS n_differ,
       max(abs(NULLIF(n."UNDER5PCT", '')::double precision - NULLIF(s."UNDER5PCT", '')::double precision)) AS max_abs
FROM raw.ejscreen_reference n
JOIN raw.ejscreen_reference_state_pct s ON s."ID" = n."ID"
UNION ALL
SELECT 'OVER64PCT' AS column_name,
       count(*) FILTER (
         WHERE NULLIF(n."OVER64PCT", '')::double precision IS DISTINCT FROM NULLIF(s."OVER64PCT", '')::double precision
       ) AS n_differ,
       max(abs(NULLIF(n."OVER64PCT", '')::double precision - NULLIF(s."OVER64PCT", '')::double precision)) AS max_abs
FROM raw.ejscreen_reference n
JOIN raw.ejscreen_reference_state_pct s ON s."ID" = n."ID"
UNION ALL
SELECT 'LIFEEXPPCT' AS column_name,
       count(*) FILTER (
         WHERE NULLIF(n."LIFEEXPPCT", '')::double precision IS DISTINCT FROM NULLIF(s."LIFEEXPPCT", '')::double precision
       ) AS n_differ,
       max(abs(NULLIF(n."LIFEEXPPCT", '')::double precision - NULLIF(s."LIFEEXPPCT", '')::double precision)) AS max_abs
FROM raw.ejscreen_reference n
JOIN raw.ejscreen_reference_state_pct s ON s."ID" = n."ID"
UNION ALL
SELECT 'PM25' AS column_name,
       count(*) FILTER (
         WHERE NULLIF(n."PM25", '')::double precision IS DISTINCT FROM NULLIF(s."PM25", '')::double precision
       ) AS n_differ,
       max(abs(NULLIF(n."PM25", '')::double precision - NULLIF(s."PM25", '')::double precision)) AS max_abs
FROM raw.ejscreen_reference n
JOIN raw.ejscreen_reference_state_pct s ON s."ID" = n."ID"
UNION ALL
SELECT 'OZONE' AS column_name,
       count(*) FILTER (
         WHERE NULLIF(n."OZONE", '')::double precision IS DISTINCT FROM NULLIF(s."OZONE", '')::double precision
       ) AS n_differ,
       max(abs(NULLIF(n."OZONE", '')::double precision - NULLIF(s."OZONE", '')::double precision)) AS max_abs
FROM raw.ejscreen_reference n
JOIN raw.ejscreen_reference_state_pct s ON s."ID" = n."ID"
UNION ALL
SELECT 'DSLPM' AS column_name,
       count(*) FILTER (
         WHERE NULLIF(n."DSLPM", '')::double precision IS DISTINCT FROM NULLIF(s."DSLPM", '')::double precision
       ) AS n_differ,
       max(abs(NULLIF(n."DSLPM", '')::double precision - NULLIF(s."DSLPM", '')::double precision)) AS max_abs
FROM raw.ejscreen_reference n
JOIN raw.ejscreen_reference_state_pct s ON s."ID" = n."ID"
UNION ALL
SELECT 'RSEI_AIR' AS column_name,
       count(*) FILTER (
         WHERE NULLIF(n."RSEI_AIR", '')::double precision IS DISTINCT FROM NULLIF(s."RSEI_AIR", '')::double precision
       ) AS n_differ,
       max(abs(NULLIF(n."RSEI_AIR", '')::double precision - NULLIF(s."RSEI_AIR", '')::double precision)) AS max_abs
FROM raw.ejscreen_reference n
JOIN raw.ejscreen_reference_state_pct s ON s."ID" = n."ID"
UNION ALL
SELECT 'PTRAF' AS column_name,
       count(*) FILTER (
         WHERE NULLIF(n."PTRAF", '')::double precision IS DISTINCT FROM NULLIF(s."PTRAF", '')::double precision
       ) AS n_differ,
       max(abs(NULLIF(n."PTRAF", '')::double precision - NULLIF(s."PTRAF", '')::double precision)) AS max_abs
FROM raw.ejscreen_reference n
JOIN raw.ejscreen_reference_state_pct s ON s."ID" = n."ID"
UNION ALL
SELECT 'PRE1960PCT' AS column_name,
       count(*) FILTER (
         WHERE NULLIF(n."PRE1960PCT", '')::double precision IS DISTINCT FROM NULLIF(s."PRE1960PCT", '')::double precision
       ) AS n_differ,
       max(abs(NULLIF(n."PRE1960PCT", '')::double precision - NULLIF(s."PRE1960PCT", '')::double precision)) AS max_abs
FROM raw.ejscreen_reference n
JOIN raw.ejscreen_reference_state_pct s ON s."ID" = n."ID"
UNION ALL
SELECT 'PNPL' AS column_name,
       count(*) FILTER (
         WHERE NULLIF(n."PNPL", '')::double precision IS DISTINCT FROM NULLIF(s."PNPL", '')::double precision
       ) AS n_differ,
       max(abs(NULLIF(n."PNPL", '')::double precision - NULLIF(s."PNPL", '')::double precision)) AS max_abs
FROM raw.ejscreen_reference n
JOIN raw.ejscreen_reference_state_pct s ON s."ID" = n."ID"
UNION ALL
SELECT 'PRMP' AS column_name,
       count(*) FILTER (
         WHERE NULLIF(n."PRMP", '')::double precision IS DISTINCT FROM NULLIF(s."PRMP", '')::double precision
       ) AS n_differ,
       max(abs(NULLIF(n."PRMP", '')::double precision - NULLIF(s."PRMP", '')::double precision)) AS max_abs
FROM raw.ejscreen_reference n
JOIN raw.ejscreen_reference_state_pct s ON s."ID" = n."ID"
UNION ALL
SELECT 'PTSDF' AS column_name,
       count(*) FILTER (
         WHERE NULLIF(n."PTSDF", '')::double precision IS DISTINCT FROM NULLIF(s."PTSDF", '')::double precision
       ) AS n_differ,
       max(abs(NULLIF(n."PTSDF", '')::double precision - NULLIF(s."PTSDF", '')::double precision)) AS max_abs
FROM raw.ejscreen_reference n
JOIN raw.ejscreen_reference_state_pct s ON s."ID" = n."ID"
UNION ALL
SELECT 'UST' AS column_name,
       count(*) FILTER (
         WHERE NULLIF(n."UST", '')::double precision IS DISTINCT FROM NULLIF(s."UST", '')::double precision
       ) AS n_differ,
       max(abs(NULLIF(n."UST", '')::double precision - NULLIF(s."UST", '')::double precision)) AS max_abs
FROM raw.ejscreen_reference n
JOIN raw.ejscreen_reference_state_pct s ON s."ID" = n."ID"
UNION ALL
SELECT 'PWDIS' AS column_name,
       count(*) FILTER (
         WHERE NULLIF(n."PWDIS", '')::double precision IS DISTINCT FROM NULLIF(s."PWDIS", '')::double precision
       ) AS n_differ,
       max(abs(NULLIF(n."PWDIS", '')::double precision - NULLIF(s."PWDIS", '')::double precision)) AS max_abs
FROM raw.ejscreen_reference n
JOIN raw.ejscreen_reference_state_pct s ON s."ID" = n."ID"
UNION ALL
SELECT 'NO2' AS column_name,
       count(*) FILTER (
         WHERE NULLIF(n."NO2", '')::double precision IS DISTINCT FROM NULLIF(s."NO2", '')::double precision
       ) AS n_differ,
       max(abs(NULLIF(n."NO2", '')::double precision - NULLIF(s."NO2", '')::double precision)) AS max_abs
FROM raw.ejscreen_reference n
JOIN raw.ejscreen_reference_state_pct s ON s."ID" = n."ID"
UNION ALL
SELECT 'DWATER' AS column_name,
       count(*) FILTER (
         WHERE NULLIF(n."DWATER", '')::double precision IS DISTINCT FROM NULLIF(s."DWATER", '')::double precision
       ) AS n_differ,
       max(abs(NULLIF(n."DWATER", '')::double precision - NULLIF(s."DWATER", '')::double precision)) AS max_abs
FROM raw.ejscreen_reference n
JOIN raw.ejscreen_reference_state_pct s ON s."ID" = n."ID";

CREATE TABLE validation.worked_example AS
SELECT b.scope, b.column_name, b.value AS rebuilt, f.value AS reference
FROM marts.rebuilt b
JOIN validation.reference_value f
  ON f.scope = b.scope AND f.column_name = b.column_name AND f.geoid = b.geoid
WHERE b.geoid = '410510068022'
  AND b.column_name IN ('DEMOGIDX_2', 'DEMOGIDX_5', 'P_PNPL', 'D2_PNPL', 'D5_PNPL', 'DEMOGIDX_2ST', 'DEMOGIDX_5ST');

CREATE TABLE validation.ca_top AS
SELECT s.geoid, s.d2_pm25 AS rebuilt_d2_pm25, f.value AS reference_d2_pm25,
       s.p_pm25 AS rebuilt_p_pm25, s.st_p_pm25 AS rebuilt_state_p_pm25
FROM marts.block_group_score s
LEFT JOIN validation.reference_value f
  ON f.geoid = s.geoid AND f.scope = 'national_file' AND f.column_name = 'D2_PM25'
WHERE s.state_fips = COALESCE(current_setting('ejscreen.state_fips', true), '06')
ORDER BY s.d2_pm25 DESC NULLS LAST
LIMIT 20;

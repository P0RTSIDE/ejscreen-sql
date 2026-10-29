DROP TABLE IF EXISTS marts.ranked_value;
DROP TABLE IF EXISTS marts.rebuilt;
DROP TABLE IF EXISTS marts.raw_percentile;

CREATE TABLE marts.rebuilt (
  scope text NOT NULL,
  column_name text NOT NULL,
  kind text NOT NULL,
  geoid text NOT NULL,
  value double precision
);

CREATE TABLE marts.ranked_value (
  scope text NOT NULL,
  percentile_column text NOT NULL,
  geoid text NOT NULL,
  value double precision NOT NULL
);


DROP TABLE IF EXISTS staging.rank_input;
CREATE TABLE staging.rank_input (
  group_key text NOT NULL,
  geoid text NOT NULL,
  state_abbrev text NOT NULL,
  in_national_universe boolean NOT NULL,
  value double precision,
  rank_mode text NOT NULL
);

CREATE OR REPLACE PROCEDURE marts.fill_rank_output()
LANGUAGE plpgsql
AS $rank$
BEGIN
  PERFORM set_config('work_mem', '512MB', true);
  DROP TABLE IF EXISTS marts.cutoff_us;
  DROP TABLE IF EXISTS marts.cutoff_state;
  DROP TABLE IF EXISTS marts.rank_output;
  CREATE TABLE marts.cutoff_us AS
  SELECT i.group_key,
         percentile_cont(f.fractions) WITHIN GROUP (ORDER BY i.value) AS cutoffs
  FROM staging.rank_input i
  CROSS JOIN marts.percentile_fractions f
  WHERE i.rank_mode IN ('both', 'us')
    AND i.in_national_universe
    AND i.value IS NOT NULL
  GROUP BY i.group_key, f.fractions;
  CREATE TABLE marts.cutoff_state AS
  SELECT i.group_key,
         i.state_abbrev,
         percentile_cont(f.fractions) WITHIN GROUP (ORDER BY i.value) AS cutoffs
  FROM staging.rank_input i
  CROSS JOIN marts.percentile_fractions f
  WHERE i.rank_mode IN ('both', 'state')
    AND i.value IS NOT NULL
  GROUP BY i.group_key, i.state_abbrev, f.fractions;
  CREATE TABLE marts.rank_output AS
  SELECT i.group_key,
         i.geoid,
         CASE
           WHEN i.rank_mode = 'state' THEN NULL
           WHEN NOT i.in_national_universe THEN NULL
           WHEN i.value IS NULL THEN NULL
           ELSE marts.assign_percentile(i.value, u.cutoffs)
         END AS us_percentile,
         CASE
           WHEN i.rank_mode = 'us' THEN NULL
           WHEN i.value IS NULL THEN NULL
           ELSE marts.assign_percentile(i.value, s.cutoffs)
         END AS state_percentile
  FROM staging.rank_input i
  LEFT JOIN marts.cutoff_us u ON u.group_key = i.group_key
  LEFT JOIN marts.cutoff_state s
    ON s.group_key = i.group_key
   AND s.state_abbrev = i.state_abbrev;
  CREATE INDEX rank_output_key ON marts.rank_output (group_key, geoid);
END;
$rank$;


TRUNCATE staging.rank_input;
INSERT INTO staging.rank_input (group_key, geoid, state_abbrev, in_national_universe, value, rank_mode)
SELECT 'P_PEOPCOLORPCT', geoid, state_abbrev, in_national_universe, pct_people_of_color, 'both' FROM staging.block_group_inputs
UNION ALL
SELECT 'P_LOWINCPCT', geoid, state_abbrev, in_national_universe, pct_low_income, 'both' FROM staging.block_group_inputs
UNION ALL
SELECT 'P_UNEMPPCT', geoid, state_abbrev, in_national_universe, pct_unemployed, 'both' FROM staging.block_group_inputs
UNION ALL
SELECT 'P_DISABILITYPCT', geoid, state_abbrev, in_national_universe, pct_disability, 'both' FROM staging.block_group_inputs
UNION ALL
SELECT 'P_LINGISOPCT', geoid, state_abbrev, in_national_universe, pct_limited_english, 'both' FROM staging.block_group_inputs
UNION ALL
SELECT 'P_LESSHSPCT', geoid, state_abbrev, in_national_universe, pct_less_than_hs, 'both' FROM staging.block_group_inputs
UNION ALL
SELECT 'P_UNDER5PCT', geoid, state_abbrev, in_national_universe, pct_under_5, 'both' FROM staging.block_group_inputs
UNION ALL
SELECT 'P_OVER64PCT', geoid, state_abbrev, in_national_universe, pct_over_64, 'both' FROM staging.block_group_inputs
UNION ALL
SELECT 'P_LIFEEXPPCT', geoid, state_abbrev, in_national_universe, pct_low_life_expectancy, 'both' FROM staging.block_group_inputs
UNION ALL
SELECT 'P_PM25', geoid, state_abbrev, in_national_universe, pm25, 'both' FROM staging.block_group_inputs
UNION ALL
SELECT 'P_OZONE', geoid, state_abbrev, in_national_universe, ozone, 'both' FROM staging.block_group_inputs
UNION ALL
SELECT 'P_DSLPM', geoid, state_abbrev, in_national_universe, diesel_pm, 'both' FROM staging.block_group_inputs
UNION ALL
SELECT 'P_RSEI_AIR', geoid, state_abbrev, in_national_universe, toxic_air, 'both' FROM staging.block_group_inputs
UNION ALL
SELECT 'P_PTRAF', geoid, state_abbrev, in_national_universe, traffic, 'both' FROM staging.block_group_inputs
UNION ALL
SELECT 'P_LDPNT', geoid, state_abbrev, in_national_universe, lead_paint, 'both' FROM staging.block_group_inputs
UNION ALL
SELECT 'P_PNPL', geoid, state_abbrev, in_national_universe, superfund, 'both' FROM staging.block_group_inputs
UNION ALL
SELECT 'P_PRMP', geoid, state_abbrev, in_national_universe, rmp, 'both' FROM staging.block_group_inputs
UNION ALL
SELECT 'P_PTSDF', geoid, state_abbrev, in_national_universe, hazardous_waste, 'both' FROM staging.block_group_inputs
UNION ALL
SELECT 'P_UST', geoid, state_abbrev, in_national_universe, ust, 'both' FROM staging.block_group_inputs
UNION ALL
SELECT 'P_PWDIS', geoid, state_abbrev, in_national_universe, wastewater, 'both' FROM staging.block_group_inputs
UNION ALL
SELECT 'P_NO2', geoid, state_abbrev, in_national_universe, no2, 'both' FROM staging.block_group_inputs
UNION ALL
SELECT 'P_DWATER', geoid, state_abbrev, in_national_universe, drinking_water, 'both' FROM staging.block_group_inputs;

CALL marts.fill_rank_output();

CREATE TABLE marts.raw_percentile AS
SELECT o.group_key, o.geoid, i.state_abbrev, i.in_national_universe, i.value,
       o.us_percentile, o.state_percentile
FROM marts.rank_output o
JOIN staging.rank_input i
  ON i.group_key = o.group_key
 AND i.geoid = o.geoid;
CREATE INDEX raw_percentile_key ON marts.raw_percentile (group_key, geoid);

INSERT INTO marts.rebuilt (scope, column_name, kind, geoid, value)
SELECT 'national_file', group_key, 'percentile', geoid, us_percentile::double precision
FROM marts.rank_output
UNION ALL
SELECT 'state_file', group_key, 'percentile', geoid, state_percentile::double precision
FROM marts.rank_output;


INSERT INTO marts.ranked_value (scope, percentile_column, geoid, value)
SELECT 'national_file', group_key, geoid, value
FROM staging.rank_input
WHERE rank_mode IN ('both', 'us')
  AND in_national_universe
  AND value IS NOT NULL
UNION ALL
SELECT 'state_file', group_key, geoid, value
FROM staging.rank_input
WHERE rank_mode IN ('both', 'state')
  AND value IS NOT NULL;


INSERT INTO marts.rebuilt (scope, column_name, kind, geoid, value)
SELECT 'national_file', 'DEMOGIDX_2', 'continuous', geoid, demogidx_2 FROM marts.demographic_index
UNION ALL
SELECT 'national_file', 'DEMOGIDX_5', 'continuous', geoid, demogidx_5 FROM marts.demographic_index
UNION ALL
SELECT 'national_file', 'DEMOGIDX_2ST', 'continuous', geoid, demogidx_2st FROM marts.demographic_index
UNION ALL
SELECT 'national_file', 'DEMOGIDX_5ST', 'continuous', geoid, demogidx_5st FROM marts.demographic_index
UNION ALL
SELECT 'state_file', 'DEMOGIDX_2', 'continuous', geoid, demogidx_2st FROM marts.demographic_index
UNION ALL
SELECT 'state_file', 'DEMOGIDX_5', 'continuous', geoid, demogidx_5st FROM marts.demographic_index
UNION ALL
SELECT 'national_file', 'D2_PM25', 'continuous', b.geoid,
       d.demogidx_2 * p.us_percentile::double precision
FROM staging.block_group_inputs b
JOIN marts.demographic_index d ON d.geoid = b.geoid
JOIN marts.raw_percentile p ON p.group_key = 'P_PM25' AND p.geoid = b.geoid
UNION ALL
SELECT 'national_file', 'D5_PM25', 'continuous', b.geoid,
       d.demogidx_5 * p.us_percentile::double precision
FROM staging.block_group_inputs b
JOIN marts.demographic_index d ON d.geoid = b.geoid
JOIN marts.raw_percentile p ON p.group_key = 'P_PM25' AND p.geoid = b.geoid
UNION ALL
SELECT 'state_file', 'D2_PM25', 'continuous', b.geoid,
       d.demogidx_2st * p.state_percentile::double precision
FROM staging.block_group_inputs b
JOIN marts.demographic_index d ON d.geoid = b.geoid
JOIN marts.raw_percentile p ON p.group_key = 'P_PM25' AND p.geoid = b.geoid
UNION ALL
SELECT 'state_file', 'D5_PM25', 'continuous', b.geoid,
       d.demogidx_5st * p.state_percentile::double precision
FROM staging.block_group_inputs b
JOIN marts.demographic_index d ON d.geoid = b.geoid
JOIN marts.raw_percentile p ON p.group_key = 'P_PM25' AND p.geoid = b.geoid
UNION ALL
SELECT 'national_file', 'D2_OZONE', 'continuous', b.geoid,
       d.demogidx_2 * p.us_percentile::double precision
FROM staging.block_group_inputs b
JOIN marts.demographic_index d ON d.geoid = b.geoid
JOIN marts.raw_percentile p ON p.group_key = 'P_OZONE' AND p.geoid = b.geoid
UNION ALL
SELECT 'national_file', 'D5_OZONE', 'continuous', b.geoid,
       d.demogidx_5 * p.us_percentile::double precision
FROM staging.block_group_inputs b
JOIN marts.demographic_index d ON d.geoid = b.geoid
JOIN marts.raw_percentile p ON p.group_key = 'P_OZONE' AND p.geoid = b.geoid
UNION ALL
SELECT 'state_file', 'D2_OZONE', 'continuous', b.geoid,
       d.demogidx_2st * p.state_percentile::double precision
FROM staging.block_group_inputs b
JOIN marts.demographic_index d ON d.geoid = b.geoid
JOIN marts.raw_percentile p ON p.group_key = 'P_OZONE' AND p.geoid = b.geoid
UNION ALL
SELECT 'state_file', 'D5_OZONE', 'continuous', b.geoid,
       d.demogidx_5st * p.state_percentile::double precision
FROM staging.block_group_inputs b
JOIN marts.demographic_index d ON d.geoid = b.geoid
JOIN marts.raw_percentile p ON p.group_key = 'P_OZONE' AND p.geoid = b.geoid
UNION ALL
SELECT 'national_file', 'D2_DSLPM', 'continuous', b.geoid,
       d.demogidx_2 * p.us_percentile::double precision
FROM staging.block_group_inputs b
JOIN marts.demographic_index d ON d.geoid = b.geoid
JOIN marts.raw_percentile p ON p.group_key = 'P_DSLPM' AND p.geoid = b.geoid
UNION ALL
SELECT 'national_file', 'D5_DSLPM', 'continuous', b.geoid,
       d.demogidx_5 * p.us_percentile::double precision
FROM staging.block_group_inputs b
JOIN marts.demographic_index d ON d.geoid = b.geoid
JOIN marts.raw_percentile p ON p.group_key = 'P_DSLPM' AND p.geoid = b.geoid
UNION ALL
SELECT 'state_file', 'D2_DSLPM', 'continuous', b.geoid,
       d.demogidx_2st * p.state_percentile::double precision
FROM staging.block_group_inputs b
JOIN marts.demographic_index d ON d.geoid = b.geoid
JOIN marts.raw_percentile p ON p.group_key = 'P_DSLPM' AND p.geoid = b.geoid
UNION ALL
SELECT 'state_file', 'D5_DSLPM', 'continuous', b.geoid,
       d.demogidx_5st * p.state_percentile::double precision
FROM staging.block_group_inputs b
JOIN marts.demographic_index d ON d.geoid = b.geoid
JOIN marts.raw_percentile p ON p.group_key = 'P_DSLPM' AND p.geoid = b.geoid
UNION ALL
SELECT 'national_file', 'D2_RSEI_AIR', 'continuous', b.geoid,
       d.demogidx_2 * p.us_percentile::double precision
FROM staging.block_group_inputs b
JOIN marts.demographic_index d ON d.geoid = b.geoid
JOIN marts.raw_percentile p ON p.group_key = 'P_RSEI_AIR' AND p.geoid = b.geoid
UNION ALL
SELECT 'national_file', 'D5_RSEI_AIR', 'continuous', b.geoid,
       d.demogidx_5 * p.us_percentile::double precision
FROM staging.block_group_inputs b
JOIN marts.demographic_index d ON d.geoid = b.geoid
JOIN marts.raw_percentile p ON p.group_key = 'P_RSEI_AIR' AND p.geoid = b.geoid
UNION ALL
SELECT 'state_file', 'D2_RSEI_AIR', 'continuous', b.geoid,
       d.demogidx_2st * p.state_percentile::double precision
FROM staging.block_group_inputs b
JOIN marts.demographic_index d ON d.geoid = b.geoid
JOIN marts.raw_percentile p ON p.group_key = 'P_RSEI_AIR' AND p.geoid = b.geoid
UNION ALL
SELECT 'state_file', 'D5_RSEI_AIR', 'continuous', b.geoid,
       d.demogidx_5st * p.state_percentile::double precision
FROM staging.block_group_inputs b
JOIN marts.demographic_index d ON d.geoid = b.geoid
JOIN marts.raw_percentile p ON p.group_key = 'P_RSEI_AIR' AND p.geoid = b.geoid
UNION ALL
SELECT 'national_file', 'D2_PTRAF', 'continuous', b.geoid,
       d.demogidx_2 * p.us_percentile::double precision
FROM staging.block_group_inputs b
JOIN marts.demographic_index d ON d.geoid = b.geoid
JOIN marts.raw_percentile p ON p.group_key = 'P_PTRAF' AND p.geoid = b.geoid
UNION ALL
SELECT 'national_file', 'D5_PTRAF', 'continuous', b.geoid,
       d.demogidx_5 * p.us_percentile::double precision
FROM staging.block_group_inputs b
JOIN marts.demographic_index d ON d.geoid = b.geoid
JOIN marts.raw_percentile p ON p.group_key = 'P_PTRAF' AND p.geoid = b.geoid
UNION ALL
SELECT 'state_file', 'D2_PTRAF', 'continuous', b.geoid,
       d.demogidx_2st * p.state_percentile::double precision
FROM staging.block_group_inputs b
JOIN marts.demographic_index d ON d.geoid = b.geoid
JOIN marts.raw_percentile p ON p.group_key = 'P_PTRAF' AND p.geoid = b.geoid
UNION ALL
SELECT 'state_file', 'D5_PTRAF', 'continuous', b.geoid,
       d.demogidx_5st * p.state_percentile::double precision
FROM staging.block_group_inputs b
JOIN marts.demographic_index d ON d.geoid = b.geoid
JOIN marts.raw_percentile p ON p.group_key = 'P_PTRAF' AND p.geoid = b.geoid
UNION ALL
SELECT 'national_file', 'D2_LDPNT', 'continuous', b.geoid,
       d.demogidx_2 * p.us_percentile::double precision
FROM staging.block_group_inputs b
JOIN marts.demographic_index d ON d.geoid = b.geoid
JOIN marts.raw_percentile p ON p.group_key = 'P_LDPNT' AND p.geoid = b.geoid
UNION ALL
SELECT 'national_file', 'D5_LDPNT', 'continuous', b.geoid,
       d.demogidx_5 * p.us_percentile::double precision
FROM staging.block_group_inputs b
JOIN marts.demographic_index d ON d.geoid = b.geoid
JOIN marts.raw_percentile p ON p.group_key = 'P_LDPNT' AND p.geoid = b.geoid
UNION ALL
SELECT 'state_file', 'D2_LDPNT', 'continuous', b.geoid,
       d.demogidx_2st * p.state_percentile::double precision
FROM staging.block_group_inputs b
JOIN marts.demographic_index d ON d.geoid = b.geoid
JOIN marts.raw_percentile p ON p.group_key = 'P_LDPNT' AND p.geoid = b.geoid
UNION ALL
SELECT 'state_file', 'D5_LDPNT', 'continuous', b.geoid,
       d.demogidx_5st * p.state_percentile::double precision
FROM staging.block_group_inputs b
JOIN marts.demographic_index d ON d.geoid = b.geoid
JOIN marts.raw_percentile p ON p.group_key = 'P_LDPNT' AND p.geoid = b.geoid
UNION ALL
SELECT 'national_file', 'D2_PNPL', 'continuous', b.geoid,
       d.demogidx_2 * p.us_percentile::double precision
FROM staging.block_group_inputs b
JOIN marts.demographic_index d ON d.geoid = b.geoid
JOIN marts.raw_percentile p ON p.group_key = 'P_PNPL' AND p.geoid = b.geoid
UNION ALL
SELECT 'national_file', 'D5_PNPL', 'continuous', b.geoid,
       d.demogidx_5 * p.us_percentile::double precision
FROM staging.block_group_inputs b
JOIN marts.demographic_index d ON d.geoid = b.geoid
JOIN marts.raw_percentile p ON p.group_key = 'P_PNPL' AND p.geoid = b.geoid
UNION ALL
SELECT 'state_file', 'D2_PNPL', 'continuous', b.geoid,
       d.demogidx_2st * p.state_percentile::double precision
FROM staging.block_group_inputs b
JOIN marts.demographic_index d ON d.geoid = b.geoid
JOIN marts.raw_percentile p ON p.group_key = 'P_PNPL' AND p.geoid = b.geoid
UNION ALL
SELECT 'state_file', 'D5_PNPL', 'continuous', b.geoid,
       d.demogidx_5st * p.state_percentile::double precision
FROM staging.block_group_inputs b
JOIN marts.demographic_index d ON d.geoid = b.geoid
JOIN marts.raw_percentile p ON p.group_key = 'P_PNPL' AND p.geoid = b.geoid
UNION ALL
SELECT 'national_file', 'D2_PRMP', 'continuous', b.geoid,
       d.demogidx_2 * p.us_percentile::double precision
FROM staging.block_group_inputs b
JOIN marts.demographic_index d ON d.geoid = b.geoid
JOIN marts.raw_percentile p ON p.group_key = 'P_PRMP' AND p.geoid = b.geoid
UNION ALL
SELECT 'national_file', 'D5_PRMP', 'continuous', b.geoid,
       d.demogidx_5 * p.us_percentile::double precision
FROM staging.block_group_inputs b
JOIN marts.demographic_index d ON d.geoid = b.geoid
JOIN marts.raw_percentile p ON p.group_key = 'P_PRMP' AND p.geoid = b.geoid
UNION ALL
SELECT 'state_file', 'D2_PRMP', 'continuous', b.geoid,
       d.demogidx_2st * p.state_percentile::double precision
FROM staging.block_group_inputs b
JOIN marts.demographic_index d ON d.geoid = b.geoid
JOIN marts.raw_percentile p ON p.group_key = 'P_PRMP' AND p.geoid = b.geoid
UNION ALL
SELECT 'state_file', 'D5_PRMP', 'continuous', b.geoid,
       d.demogidx_5st * p.state_percentile::double precision
FROM staging.block_group_inputs b
JOIN marts.demographic_index d ON d.geoid = b.geoid
JOIN marts.raw_percentile p ON p.group_key = 'P_PRMP' AND p.geoid = b.geoid
UNION ALL
SELECT 'national_file', 'D2_PTSDF', 'continuous', b.geoid,
       d.demogidx_2 * p.us_percentile::double precision
FROM staging.block_group_inputs b
JOIN marts.demographic_index d ON d.geoid = b.geoid
JOIN marts.raw_percentile p ON p.group_key = 'P_PTSDF' AND p.geoid = b.geoid
UNION ALL
SELECT 'national_file', 'D5_PTSDF', 'continuous', b.geoid,
       d.demogidx_5 * p.us_percentile::double precision
FROM staging.block_group_inputs b
JOIN marts.demographic_index d ON d.geoid = b.geoid
JOIN marts.raw_percentile p ON p.group_key = 'P_PTSDF' AND p.geoid = b.geoid
UNION ALL
SELECT 'state_file', 'D2_PTSDF', 'continuous', b.geoid,
       d.demogidx_2st * p.state_percentile::double precision
FROM staging.block_group_inputs b
JOIN marts.demographic_index d ON d.geoid = b.geoid
JOIN marts.raw_percentile p ON p.group_key = 'P_PTSDF' AND p.geoid = b.geoid
UNION ALL
SELECT 'state_file', 'D5_PTSDF', 'continuous', b.geoid,
       d.demogidx_5st * p.state_percentile::double precision
FROM staging.block_group_inputs b
JOIN marts.demographic_index d ON d.geoid = b.geoid
JOIN marts.raw_percentile p ON p.group_key = 'P_PTSDF' AND p.geoid = b.geoid
UNION ALL
SELECT 'national_file', 'D2_UST', 'continuous', b.geoid,
       d.demogidx_2 * p.us_percentile::double precision
FROM staging.block_group_inputs b
JOIN marts.demographic_index d ON d.geoid = b.geoid
JOIN marts.raw_percentile p ON p.group_key = 'P_UST' AND p.geoid = b.geoid
UNION ALL
SELECT 'national_file', 'D5_UST', 'continuous', b.geoid,
       d.demogidx_5 * p.us_percentile::double precision
FROM staging.block_group_inputs b
JOIN marts.demographic_index d ON d.geoid = b.geoid
JOIN marts.raw_percentile p ON p.group_key = 'P_UST' AND p.geoid = b.geoid
UNION ALL
SELECT 'state_file', 'D2_UST', 'continuous', b.geoid,
       d.demogidx_2st * p.state_percentile::double precision
FROM staging.block_group_inputs b
JOIN marts.demographic_index d ON d.geoid = b.geoid
JOIN marts.raw_percentile p ON p.group_key = 'P_UST' AND p.geoid = b.geoid
UNION ALL
SELECT 'state_file', 'D5_UST', 'continuous', b.geoid,
       d.demogidx_5st * p.state_percentile::double precision
FROM staging.block_group_inputs b
JOIN marts.demographic_index d ON d.geoid = b.geoid
JOIN marts.raw_percentile p ON p.group_key = 'P_UST' AND p.geoid = b.geoid
UNION ALL
SELECT 'national_file', 'D2_PWDIS', 'continuous', b.geoid,
       d.demogidx_2 * p.us_percentile::double precision
FROM staging.block_group_inputs b
JOIN marts.demographic_index d ON d.geoid = b.geoid
JOIN marts.raw_percentile p ON p.group_key = 'P_PWDIS' AND p.geoid = b.geoid
UNION ALL
SELECT 'national_file', 'D5_PWDIS', 'continuous', b.geoid,
       d.demogidx_5 * p.us_percentile::double precision
FROM staging.block_group_inputs b
JOIN marts.demographic_index d ON d.geoid = b.geoid
JOIN marts.raw_percentile p ON p.group_key = 'P_PWDIS' AND p.geoid = b.geoid
UNION ALL
SELECT 'state_file', 'D2_PWDIS', 'continuous', b.geoid,
       d.demogidx_2st * p.state_percentile::double precision
FROM staging.block_group_inputs b
JOIN marts.demographic_index d ON d.geoid = b.geoid
JOIN marts.raw_percentile p ON p.group_key = 'P_PWDIS' AND p.geoid = b.geoid
UNION ALL
SELECT 'state_file', 'D5_PWDIS', 'continuous', b.geoid,
       d.demogidx_5st * p.state_percentile::double precision
FROM staging.block_group_inputs b
JOIN marts.demographic_index d ON d.geoid = b.geoid
JOIN marts.raw_percentile p ON p.group_key = 'P_PWDIS' AND p.geoid = b.geoid
UNION ALL
SELECT 'national_file', 'D2_NO2', 'continuous', b.geoid,
       d.demogidx_2 * p.us_percentile::double precision
FROM staging.block_group_inputs b
JOIN marts.demographic_index d ON d.geoid = b.geoid
JOIN marts.raw_percentile p ON p.group_key = 'P_NO2' AND p.geoid = b.geoid
UNION ALL
SELECT 'national_file', 'D5_NO2', 'continuous', b.geoid,
       d.demogidx_5 * p.us_percentile::double precision
FROM staging.block_group_inputs b
JOIN marts.demographic_index d ON d.geoid = b.geoid
JOIN marts.raw_percentile p ON p.group_key = 'P_NO2' AND p.geoid = b.geoid
UNION ALL
SELECT 'state_file', 'D2_NO2', 'continuous', b.geoid,
       d.demogidx_2st * p.state_percentile::double precision
FROM staging.block_group_inputs b
JOIN marts.demographic_index d ON d.geoid = b.geoid
JOIN marts.raw_percentile p ON p.group_key = 'P_NO2' AND p.geoid = b.geoid
UNION ALL
SELECT 'state_file', 'D5_NO2', 'continuous', b.geoid,
       d.demogidx_5st * p.state_percentile::double precision
FROM staging.block_group_inputs b
JOIN marts.demographic_index d ON d.geoid = b.geoid
JOIN marts.raw_percentile p ON p.group_key = 'P_NO2' AND p.geoid = b.geoid
UNION ALL
SELECT 'national_file', 'D2_DWATER', 'continuous', b.geoid,
       d.demogidx_2 * p.us_percentile::double precision
FROM staging.block_group_inputs b
JOIN marts.demographic_index d ON d.geoid = b.geoid
JOIN marts.raw_percentile p ON p.group_key = 'P_DWATER' AND p.geoid = b.geoid
UNION ALL
SELECT 'national_file', 'D5_DWATER', 'continuous', b.geoid,
       d.demogidx_5 * p.us_percentile::double precision
FROM staging.block_group_inputs b
JOIN marts.demographic_index d ON d.geoid = b.geoid
JOIN marts.raw_percentile p ON p.group_key = 'P_DWATER' AND p.geoid = b.geoid
UNION ALL
SELECT 'state_file', 'D2_DWATER', 'continuous', b.geoid,
       d.demogidx_2st * p.state_percentile::double precision
FROM staging.block_group_inputs b
JOIN marts.demographic_index d ON d.geoid = b.geoid
JOIN marts.raw_percentile p ON p.group_key = 'P_DWATER' AND p.geoid = b.geoid
UNION ALL
SELECT 'state_file', 'D5_DWATER', 'continuous', b.geoid,
       d.demogidx_5st * p.state_percentile::double precision
FROM staging.block_group_inputs b
JOIN marts.demographic_index d ON d.geoid = b.geoid
JOIN marts.raw_percentile p ON p.group_key = 'P_DWATER' AND p.geoid = b.geoid;

TRUNCATE staging.rank_input;
INSERT INTO staging.rank_input (group_key, geoid, state_abbrev, in_national_universe, value, rank_mode)
SELECT 'P_DEMOGIDX_2', s.geoid, s.state_abbrev, s.in_national_universe, d.demogidx_2, 'us' FROM marts.demographic_index d JOIN staging.block_group_inputs s ON s.geoid = d.geoid UNION ALL SELECT 'P_DEMOGIDX_5', s.geoid, s.state_abbrev, s.in_national_universe, d.demogidx_5, 'us' FROM marts.demographic_index d JOIN staging.block_group_inputs s ON s.geoid = d.geoid UNION ALL SELECT 'P_D2_PM25', s.geoid, s.state_abbrev, s.in_national_universe, r.value, 'us' FROM marts.rebuilt r JOIN staging.block_group_inputs s ON s.geoid = r.geoid WHERE r.scope = 'national_file' AND r.column_name = 'D2_PM25' UNION ALL SELECT 'P_D5_PM25', s.geoid, s.state_abbrev, s.in_national_universe, r.value, 'us' FROM marts.rebuilt r JOIN staging.block_group_inputs s ON s.geoid = r.geoid WHERE r.scope = 'national_file' AND r.column_name = 'D5_PM25' UNION ALL SELECT 'P_D2_OZONE', s.geoid, s.state_abbrev, s.in_national_universe, r.value, 'us' FROM marts.rebuilt r JOIN staging.block_group_inputs s ON s.geoid = r.geoid WHERE r.scope = 'national_file' AND r.column_name = 'D2_OZONE' UNION ALL SELECT 'P_D5_OZONE', s.geoid, s.state_abbrev, s.in_national_universe, r.value, 'us' FROM marts.rebuilt r JOIN staging.block_group_inputs s ON s.geoid = r.geoid WHERE r.scope = 'national_file' AND r.column_name = 'D5_OZONE' UNION ALL SELECT 'P_D2_DSLPM', s.geoid, s.state_abbrev, s.in_national_universe, r.value, 'us' FROM marts.rebuilt r JOIN staging.block_group_inputs s ON s.geoid = r.geoid WHERE r.scope = 'national_file' AND r.column_name = 'D2_DSLPM' UNION ALL SELECT 'P_D5_DSLPM', s.geoid, s.state_abbrev, s.in_national_universe, r.value, 'us' FROM marts.rebuilt r JOIN staging.block_group_inputs s ON s.geoid = r.geoid WHERE r.scope = 'national_file' AND r.column_name = 'D5_DSLPM' UNION ALL SELECT 'P_D2_RSEI_AIR', s.geoid, s.state_abbrev, s.in_national_universe, r.value, 'us' FROM marts.rebuilt r JOIN staging.block_group_inputs s ON s.geoid = r.geoid WHERE r.scope = 'national_file' AND r.column_name = 'D2_RSEI_AIR' UNION ALL SELECT 'P_D5_RSEI_AIR', s.geoid, s.state_abbrev, s.in_national_universe, r.value, 'us' FROM marts.rebuilt r JOIN staging.block_group_inputs s ON s.geoid = r.geoid WHERE r.scope = 'national_file' AND r.column_name = 'D5_RSEI_AIR' UNION ALL SELECT 'P_D2_PTRAF', s.geoid, s.state_abbrev, s.in_national_universe, r.value, 'us' FROM marts.rebuilt r JOIN staging.block_group_inputs s ON s.geoid = r.geoid WHERE r.scope = 'national_file' AND r.column_name = 'D2_PTRAF' UNION ALL SELECT 'P_D5_PTRAF', s.geoid, s.state_abbrev, s.in_national_universe, r.value, 'us' FROM marts.rebuilt r JOIN staging.block_group_inputs s ON s.geoid = r.geoid WHERE r.scope = 'national_file' AND r.column_name = 'D5_PTRAF' UNION ALL SELECT 'P_D2_LDPNT', s.geoid, s.state_abbrev, s.in_national_universe, r.value, 'us' FROM marts.rebuilt r JOIN staging.block_group_inputs s ON s.geoid = r.geoid WHERE r.scope = 'national_file' AND r.column_name = 'D2_LDPNT' UNION ALL SELECT 'P_D5_LDPNT', s.geoid, s.state_abbrev, s.in_national_universe, r.value, 'us' FROM marts.rebuilt r JOIN staging.block_group_inputs s ON s.geoid = r.geoid WHERE r.scope = 'national_file' AND r.column_name = 'D5_LDPNT' UNION ALL SELECT 'P_D2_PNPL', s.geoid, s.state_abbrev, s.in_national_universe, r.value, 'us' FROM marts.rebuilt r JOIN staging.block_group_inputs s ON s.geoid = r.geoid WHERE r.scope = 'national_file' AND r.column_name = 'D2_PNPL' UNION ALL SELECT 'P_D5_PNPL', s.geoid, s.state_abbrev, s.in_national_universe, r.value, 'us' FROM marts.rebuilt r JOIN staging.block_group_inputs s ON s.geoid = r.geoid WHERE r.scope = 'national_file' AND r.column_name = 'D5_PNPL' UNION ALL SELECT 'P_D2_PRMP', s.geoid, s.state_abbrev, s.in_national_universe, r.value, 'us' FROM marts.rebuilt r JOIN staging.block_group_inputs s ON s.geoid = r.geoid WHERE r.scope = 'national_file' AND r.column_name = 'D2_PRMP' UNION ALL SELECT 'P_D5_PRMP', s.geoid, s.state_abbrev, s.in_national_universe, r.value, 'us' FROM marts.rebuilt r JOIN staging.block_group_inputs s ON s.geoid = r.geoid WHERE r.scope = 'national_file' AND r.column_name = 'D5_PRMP' UNION ALL SELECT 'P_D2_PTSDF', s.geoid, s.state_abbrev, s.in_national_universe, r.value, 'us' FROM marts.rebuilt r JOIN staging.block_group_inputs s ON s.geoid = r.geoid WHERE r.scope = 'national_file' AND r.column_name = 'D2_PTSDF' UNION ALL SELECT 'P_D5_PTSDF', s.geoid, s.state_abbrev, s.in_national_universe, r.value, 'us' FROM marts.rebuilt r JOIN staging.block_group_inputs s ON s.geoid = r.geoid WHERE r.scope = 'national_file' AND r.column_name = 'D5_PTSDF' UNION ALL SELECT 'P_D2_UST', s.geoid, s.state_abbrev, s.in_national_universe, r.value, 'us' FROM marts.rebuilt r JOIN staging.block_group_inputs s ON s.geoid = r.geoid WHERE r.scope = 'national_file' AND r.column_name = 'D2_UST' UNION ALL SELECT 'P_D5_UST', s.geoid, s.state_abbrev, s.in_national_universe, r.value, 'us' FROM marts.rebuilt r JOIN staging.block_group_inputs s ON s.geoid = r.geoid WHERE r.scope = 'national_file' AND r.column_name = 'D5_UST' UNION ALL SELECT 'P_D2_PWDIS', s.geoid, s.state_abbrev, s.in_national_universe, r.value, 'us' FROM marts.rebuilt r JOIN staging.block_group_inputs s ON s.geoid = r.geoid WHERE r.scope = 'national_file' AND r.column_name = 'D2_PWDIS' UNION ALL SELECT 'P_D5_PWDIS', s.geoid, s.state_abbrev, s.in_national_universe, r.value, 'us' FROM marts.rebuilt r JOIN staging.block_group_inputs s ON s.geoid = r.geoid WHERE r.scope = 'national_file' AND r.column_name = 'D5_PWDIS' UNION ALL SELECT 'P_D2_NO2', s.geoid, s.state_abbrev, s.in_national_universe, r.value, 'us' FROM marts.rebuilt r JOIN staging.block_group_inputs s ON s.geoid = r.geoid WHERE r.scope = 'national_file' AND r.column_name = 'D2_NO2' UNION ALL SELECT 'P_D5_NO2', s.geoid, s.state_abbrev, s.in_national_universe, r.value, 'us' FROM marts.rebuilt r JOIN staging.block_group_inputs s ON s.geoid = r.geoid WHERE r.scope = 'national_file' AND r.column_name = 'D5_NO2' UNION ALL SELECT 'P_D2_DWATER', s.geoid, s.state_abbrev, s.in_national_universe, r.value, 'us' FROM marts.rebuilt r JOIN staging.block_group_inputs s ON s.geoid = r.geoid WHERE r.scope = 'national_file' AND r.column_name = 'D2_DWATER' UNION ALL SELECT 'P_D5_DWATER', s.geoid, s.state_abbrev, s.in_national_universe, r.value, 'us' FROM marts.rebuilt r JOIN staging.block_group_inputs s ON s.geoid = r.geoid WHERE r.scope = 'national_file' AND r.column_name = 'D5_DWATER';
CALL marts.fill_rank_output();
INSERT INTO marts.rebuilt (scope, column_name, kind, geoid, value)
SELECT 'national_file', group_key, 'percentile', geoid, us_percentile::double precision
FROM marts.rank_output;

INSERT INTO marts.ranked_value (scope, percentile_column, geoid, value)
SELECT 'national_file', group_key, geoid, value
FROM staging.rank_input
WHERE rank_mode IN ('both', 'us')
  AND in_national_universe
  AND value IS NOT NULL
UNION ALL
SELECT 'state_file', group_key, geoid, value
FROM staging.rank_input
WHERE rank_mode IN ('both', 'state')
  AND value IS NOT NULL;


TRUNCATE staging.rank_input;
INSERT INTO staging.rank_input (group_key, geoid, state_abbrev, in_national_universe, value, rank_mode)
SELECT 'P_DEMOGIDX_2', s.geoid, s.state_abbrev, s.in_national_universe, d.demogidx_2st, 'state' FROM marts.demographic_index d JOIN staging.block_group_inputs s ON s.geoid = d.geoid UNION ALL SELECT 'P_DEMOGIDX_5', s.geoid, s.state_abbrev, s.in_national_universe, d.demogidx_5st, 'state' FROM marts.demographic_index d JOIN staging.block_group_inputs s ON s.geoid = d.geoid UNION ALL SELECT 'P_D2_PM25', s.geoid, s.state_abbrev, s.in_national_universe, r.value, 'state' FROM marts.rebuilt r JOIN staging.block_group_inputs s ON s.geoid = r.geoid WHERE r.scope = 'state_file' AND r.column_name = 'D2_PM25' UNION ALL SELECT 'P_D5_PM25', s.geoid, s.state_abbrev, s.in_national_universe, r.value, 'state' FROM marts.rebuilt r JOIN staging.block_group_inputs s ON s.geoid = r.geoid WHERE r.scope = 'state_file' AND r.column_name = 'D5_PM25' UNION ALL SELECT 'P_D2_OZONE', s.geoid, s.state_abbrev, s.in_national_universe, r.value, 'state' FROM marts.rebuilt r JOIN staging.block_group_inputs s ON s.geoid = r.geoid WHERE r.scope = 'state_file' AND r.column_name = 'D2_OZONE' UNION ALL SELECT 'P_D5_OZONE', s.geoid, s.state_abbrev, s.in_national_universe, r.value, 'state' FROM marts.rebuilt r JOIN staging.block_group_inputs s ON s.geoid = r.geoid WHERE r.scope = 'state_file' AND r.column_name = 'D5_OZONE' UNION ALL SELECT 'P_D2_DSLPM', s.geoid, s.state_abbrev, s.in_national_universe, r.value, 'state' FROM marts.rebuilt r JOIN staging.block_group_inputs s ON s.geoid = r.geoid WHERE r.scope = 'state_file' AND r.column_name = 'D2_DSLPM' UNION ALL SELECT 'P_D5_DSLPM', s.geoid, s.state_abbrev, s.in_national_universe, r.value, 'state' FROM marts.rebuilt r JOIN staging.block_group_inputs s ON s.geoid = r.geoid WHERE r.scope = 'state_file' AND r.column_name = 'D5_DSLPM' UNION ALL SELECT 'P_D2_RSEI_AIR', s.geoid, s.state_abbrev, s.in_national_universe, r.value, 'state' FROM marts.rebuilt r JOIN staging.block_group_inputs s ON s.geoid = r.geoid WHERE r.scope = 'state_file' AND r.column_name = 'D2_RSEI_AIR' UNION ALL SELECT 'P_D5_RSEI_AIR', s.geoid, s.state_abbrev, s.in_national_universe, r.value, 'state' FROM marts.rebuilt r JOIN staging.block_group_inputs s ON s.geoid = r.geoid WHERE r.scope = 'state_file' AND r.column_name = 'D5_RSEI_AIR' UNION ALL SELECT 'P_D2_PTRAF', s.geoid, s.state_abbrev, s.in_national_universe, r.value, 'state' FROM marts.rebuilt r JOIN staging.block_group_inputs s ON s.geoid = r.geoid WHERE r.scope = 'state_file' AND r.column_name = 'D2_PTRAF' UNION ALL SELECT 'P_D5_PTRAF', s.geoid, s.state_abbrev, s.in_national_universe, r.value, 'state' FROM marts.rebuilt r JOIN staging.block_group_inputs s ON s.geoid = r.geoid WHERE r.scope = 'state_file' AND r.column_name = 'D5_PTRAF' UNION ALL SELECT 'P_D2_LDPNT', s.geoid, s.state_abbrev, s.in_national_universe, r.value, 'state' FROM marts.rebuilt r JOIN staging.block_group_inputs s ON s.geoid = r.geoid WHERE r.scope = 'state_file' AND r.column_name = 'D2_LDPNT' UNION ALL SELECT 'P_D5_LDPNT', s.geoid, s.state_abbrev, s.in_national_universe, r.value, 'state' FROM marts.rebuilt r JOIN staging.block_group_inputs s ON s.geoid = r.geoid WHERE r.scope = 'state_file' AND r.column_name = 'D5_LDPNT' UNION ALL SELECT 'P_D2_PNPL', s.geoid, s.state_abbrev, s.in_national_universe, r.value, 'state' FROM marts.rebuilt r JOIN staging.block_group_inputs s ON s.geoid = r.geoid WHERE r.scope = 'state_file' AND r.column_name = 'D2_PNPL' UNION ALL SELECT 'P_D5_PNPL', s.geoid, s.state_abbrev, s.in_national_universe, r.value, 'state' FROM marts.rebuilt r JOIN staging.block_group_inputs s ON s.geoid = r.geoid WHERE r.scope = 'state_file' AND r.column_name = 'D5_PNPL' UNION ALL SELECT 'P_D2_PRMP', s.geoid, s.state_abbrev, s.in_national_universe, r.value, 'state' FROM marts.rebuilt r JOIN staging.block_group_inputs s ON s.geoid = r.geoid WHERE r.scope = 'state_file' AND r.column_name = 'D2_PRMP' UNION ALL SELECT 'P_D5_PRMP', s.geoid, s.state_abbrev, s.in_national_universe, r.value, 'state' FROM marts.rebuilt r JOIN staging.block_group_inputs s ON s.geoid = r.geoid WHERE r.scope = 'state_file' AND r.column_name = 'D5_PRMP' UNION ALL SELECT 'P_D2_PTSDF', s.geoid, s.state_abbrev, s.in_national_universe, r.value, 'state' FROM marts.rebuilt r JOIN staging.block_group_inputs s ON s.geoid = r.geoid WHERE r.scope = 'state_file' AND r.column_name = 'D2_PTSDF' UNION ALL SELECT 'P_D5_PTSDF', s.geoid, s.state_abbrev, s.in_national_universe, r.value, 'state' FROM marts.rebuilt r JOIN staging.block_group_inputs s ON s.geoid = r.geoid WHERE r.scope = 'state_file' AND r.column_name = 'D5_PTSDF' UNION ALL SELECT 'P_D2_UST', s.geoid, s.state_abbrev, s.in_national_universe, r.value, 'state' FROM marts.rebuilt r JOIN staging.block_group_inputs s ON s.geoid = r.geoid WHERE r.scope = 'state_file' AND r.column_name = 'D2_UST' UNION ALL SELECT 'P_D5_UST', s.geoid, s.state_abbrev, s.in_national_universe, r.value, 'state' FROM marts.rebuilt r JOIN staging.block_group_inputs s ON s.geoid = r.geoid WHERE r.scope = 'state_file' AND r.column_name = 'D5_UST' UNION ALL SELECT 'P_D2_PWDIS', s.geoid, s.state_abbrev, s.in_national_universe, r.value, 'state' FROM marts.rebuilt r JOIN staging.block_group_inputs s ON s.geoid = r.geoid WHERE r.scope = 'state_file' AND r.column_name = 'D2_PWDIS' UNION ALL SELECT 'P_D5_PWDIS', s.geoid, s.state_abbrev, s.in_national_universe, r.value, 'state' FROM marts.rebuilt r JOIN staging.block_group_inputs s ON s.geoid = r.geoid WHERE r.scope = 'state_file' AND r.column_name = 'D5_PWDIS' UNION ALL SELECT 'P_D2_NO2', s.geoid, s.state_abbrev, s.in_national_universe, r.value, 'state' FROM marts.rebuilt r JOIN staging.block_group_inputs s ON s.geoid = r.geoid WHERE r.scope = 'state_file' AND r.column_name = 'D2_NO2' UNION ALL SELECT 'P_D5_NO2', s.geoid, s.state_abbrev, s.in_national_universe, r.value, 'state' FROM marts.rebuilt r JOIN staging.block_group_inputs s ON s.geoid = r.geoid WHERE r.scope = 'state_file' AND r.column_name = 'D5_NO2' UNION ALL SELECT 'P_D2_DWATER', s.geoid, s.state_abbrev, s.in_national_universe, r.value, 'state' FROM marts.rebuilt r JOIN staging.block_group_inputs s ON s.geoid = r.geoid WHERE r.scope = 'state_file' AND r.column_name = 'D2_DWATER' UNION ALL SELECT 'P_D5_DWATER', s.geoid, s.state_abbrev, s.in_national_universe, r.value, 'state' FROM marts.rebuilt r JOIN staging.block_group_inputs s ON s.geoid = r.geoid WHERE r.scope = 'state_file' AND r.column_name = 'D5_DWATER';
CALL marts.fill_rank_output();
INSERT INTO marts.rebuilt (scope, column_name, kind, geoid, value)
SELECT 'state_file', group_key, 'percentile', geoid, state_percentile::double precision
FROM marts.rank_output;

INSERT INTO marts.ranked_value (scope, percentile_column, geoid, value)
SELECT 'national_file', group_key, geoid, value
FROM staging.rank_input
WHERE rank_mode IN ('both', 'us')
  AND in_national_universe
  AND value IS NOT NULL
UNION ALL
SELECT 'state_file', group_key, geoid, value
FROM staging.rank_input
WHERE rank_mode IN ('both', 'state')
  AND value IS NOT NULL;


CREATE INDEX rebuilt_lookup ON marts.rebuilt (scope, column_name, geoid);
ANALYZE marts.rebuilt;
ANALYZE marts.ranked_value;

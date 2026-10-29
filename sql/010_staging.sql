DROP TABLE IF EXISTS staging.measure_value;
DROP TABLE IF EXISTS staging.block_group_inputs;

CREATE TABLE staging.block_group_inputs AS
SELECT
  "ID" AS source_id,
  CASE WHEN length("ID") >= 12 THEN "ID" ELSE lpad("ID", 12, '0') END AS geoid,
  left("ID", 2) AS state_fips,
  "ST_ABBREV" AS state_abbrev,
  "STATE_NAME" AS state_name,
  "CNTY_NAME" AS county_name,
  NULLIF("REGION", '') AS region,
  "ST_ABBREV" NOT IN ('AS', 'GU', 'MP', 'VI') AS in_national_universe,
  NULLIF("ACSTOTPOP", '')::double precision AS population,
  NULLIF("PEOPCOLORPCT", '')::double precision AS pct_people_of_color,
  NULLIF("LOWINCPCT", '')::double precision AS pct_low_income,
  NULLIF("UNEMPPCT", '')::double precision AS pct_unemployed,
  NULLIF("DISABILITYPCT", '')::double precision AS pct_disability,
  NULLIF("LINGISOPCT", '')::double precision AS pct_limited_english,
  NULLIF("LESSHSPCT", '')::double precision AS pct_less_than_hs,
  NULLIF("UNDER5PCT", '')::double precision AS pct_under_5,
  NULLIF("OVER64PCT", '')::double precision AS pct_over_64,
  NULLIF("LIFEEXPPCT", '')::double precision AS pct_low_life_expectancy,
  NULLIF("PM25", '')::double precision AS pm25,
  NULLIF("OZONE", '')::double precision AS ozone,
  NULLIF("DSLPM", '')::double precision AS diesel_pm,
  NULLIF("RSEI_AIR", '')::double precision AS toxic_air,
  NULLIF("PTRAF", '')::double precision AS traffic,
  NULLIF("PRE1960PCT", '')::double precision AS lead_paint,
  NULLIF("PNPL", '')::double precision AS superfund,
  NULLIF("PRMP", '')::double precision AS rmp,
  NULLIF("PTSDF", '')::double precision AS hazardous_waste,
  NULLIF("UST", '')::double precision AS ust,
  NULLIF("PWDIS", '')::double precision AS wastewater,
  NULLIF("NO2", '')::double precision AS no2,
  NULLIF("DWATER", '')::double precision AS drinking_water
FROM raw.ejscreen_reference;

ALTER TABLE staging.block_group_inputs
  ALTER COLUMN geoid SET NOT NULL,
  ALTER COLUMN source_id SET NOT NULL;
ALTER TABLE staging.block_group_inputs ADD PRIMARY KEY (geoid);
CREATE UNIQUE INDEX block_group_inputs_source_id ON staging.block_group_inputs (source_id);

COMMENT ON TABLE staging.block_group_inputs IS
  'One row per block group or territory place or estate. Indicator values are the published raw fields from raw.ejscreen_reference. Tech doc pp. 15 to 29 and pp. 31 to 35.';

CREATE TABLE staging.measure_value AS
SELECT geoid, state_abbrev, in_national_universe, 'PEOPCOLORPCT' AS measure_code, pct_people_of_color AS value
FROM staging.block_group_inputs
UNION ALL
SELECT geoid, state_abbrev, in_national_universe, 'LOWINCPCT' AS measure_code, pct_low_income AS value
FROM staging.block_group_inputs
UNION ALL
SELECT geoid, state_abbrev, in_national_universe, 'UNEMPPCT' AS measure_code, pct_unemployed AS value
FROM staging.block_group_inputs
UNION ALL
SELECT geoid, state_abbrev, in_national_universe, 'DISABILITYPCT' AS measure_code, pct_disability AS value
FROM staging.block_group_inputs
UNION ALL
SELECT geoid, state_abbrev, in_national_universe, 'LINGISOPCT' AS measure_code, pct_limited_english AS value
FROM staging.block_group_inputs
UNION ALL
SELECT geoid, state_abbrev, in_national_universe, 'LESSHSPCT' AS measure_code, pct_less_than_hs AS value
FROM staging.block_group_inputs
UNION ALL
SELECT geoid, state_abbrev, in_national_universe, 'UNDER5PCT' AS measure_code, pct_under_5 AS value
FROM staging.block_group_inputs
UNION ALL
SELECT geoid, state_abbrev, in_national_universe, 'OVER64PCT' AS measure_code, pct_over_64 AS value
FROM staging.block_group_inputs
UNION ALL
SELECT geoid, state_abbrev, in_national_universe, 'LIFEEXPPCT' AS measure_code, pct_low_life_expectancy AS value
FROM staging.block_group_inputs
UNION ALL
SELECT geoid, state_abbrev, in_national_universe, 'PM25' AS measure_code, pm25 AS value
FROM staging.block_group_inputs
UNION ALL
SELECT geoid, state_abbrev, in_national_universe, 'OZONE' AS measure_code, ozone AS value
FROM staging.block_group_inputs
UNION ALL
SELECT geoid, state_abbrev, in_national_universe, 'DSLPM' AS measure_code, diesel_pm AS value
FROM staging.block_group_inputs
UNION ALL
SELECT geoid, state_abbrev, in_national_universe, 'RSEI_AIR' AS measure_code, toxic_air AS value
FROM staging.block_group_inputs
UNION ALL
SELECT geoid, state_abbrev, in_national_universe, 'PTRAF' AS measure_code, traffic AS value
FROM staging.block_group_inputs
UNION ALL
SELECT geoid, state_abbrev, in_national_universe, 'PRE1960PCT' AS measure_code, lead_paint AS value
FROM staging.block_group_inputs
UNION ALL
SELECT geoid, state_abbrev, in_national_universe, 'PNPL' AS measure_code, superfund AS value
FROM staging.block_group_inputs
UNION ALL
SELECT geoid, state_abbrev, in_national_universe, 'PRMP' AS measure_code, rmp AS value
FROM staging.block_group_inputs
UNION ALL
SELECT geoid, state_abbrev, in_national_universe, 'PTSDF' AS measure_code, hazardous_waste AS value
FROM staging.block_group_inputs
UNION ALL
SELECT geoid, state_abbrev, in_national_universe, 'UST' AS measure_code, ust AS value
FROM staging.block_group_inputs
UNION ALL
SELECT geoid, state_abbrev, in_national_universe, 'PWDIS' AS measure_code, wastewater AS value
FROM staging.block_group_inputs
UNION ALL
SELECT geoid, state_abbrev, in_national_universe, 'NO2' AS measure_code, no2 AS value
FROM staging.block_group_inputs
UNION ALL
SELECT geoid, state_abbrev, in_national_universe, 'DWATER' AS measure_code, drinking_water AS value
FROM staging.block_group_inputs;

CREATE INDEX measure_value_code ON staging.measure_value (measure_code);
ANALYZE staging.block_group_inputs;
ANALYZE staging.measure_value;

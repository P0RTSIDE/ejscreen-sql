-- Lead paint. ACS 2022 5-year B25034 at block group.
-- Printed formula: (B25034.009 + B25034.010 + B25034.011) / B25034.001.
-- The reference column PRE1960PCT stores the ratio, not a 0 to 100 percent.
-- Zero denominator follows staging.acs_rate: a zero denominator is 0, a null denominator stays null.
-- A numerator part that Census left blank or marked negative becomes null, and the sum is then null.

SET statement_timeout = 0;
SET work_mem = '256MB';
SET max_parallel_workers_per_gather = 0;

DROP TABLE IF EXISTS staging.tier3_lead_paint;
CREATE TABLE staging.tier3_lead_paint AS
SELECT
  lpad("state", 2, '0')
    || lpad("county", 3, '0')
    || lpad("tract", 6, '0')
    || lpad("block group", 1, '0') AS geoid,
  staging.acs_count("B25034_001E") AS housing_units,
  staging.acs_count("B25034_009E") AS built_1950_1959,
  staging.acs_count("B25034_010E") AS built_1940_1949,
  staging.acs_count("B25034_011E") AS built_1939_or_earlier,
  staging.acs_rate(
    staging.acs_count("B25034_009E")
      + staging.acs_count("B25034_010E")
      + staging.acs_count("B25034_011E"),
    staging.acs_count("B25034_001E")
  ) AS lead_paint
FROM raw.acs2022_bg_b25034;

CREATE UNIQUE INDEX tier3_lead_paint_geoid ON staging.tier3_lead_paint (geoid);
ANALYZE staging.tier3_lead_paint;

DROP TABLE IF EXISTS staging.tier3_lead_zero_denom;
CREATE TABLE staging.tier3_lead_zero_denom AS
SELECT
  count(*) FILTER (WHERE housing_units = 0) AS zero_denom_n,
  count(*) FILTER (WHERE housing_units = 0 AND lead_paint = 0) AS zero_denom_stored_0,
  count(*) FILTER (WHERE housing_units IS NULL) AS null_denom_n,
  count(*) FILTER (WHERE housing_units IS NULL AND lead_paint IS NULL) AS null_denom_stored_null,
  count(*) FILTER (
    WHERE housing_units = 0
      AND (built_1950_1959 IS NULL OR built_1940_1949 IS NULL OR built_1939_or_earlier IS NULL)
  ) AS zero_denom_with_null_part
FROM staging.tier3_lead_paint;

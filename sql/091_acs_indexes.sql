DROP TABLE IF EXISTS marts.acs_block_group;
DROP TABLE IF EXISTS marts.acs_moment_state;
DROP TABLE IF EXISTS marts.acs_moment_us;

CREATE TABLE marts.acs_moment_us AS
SELECT measure_code,
       count(value)::integer AS n,
       avg(value) AS mu,
       CASE
         WHEN count(value) > 1 THEN sqrt(greatest(
           0::double precision,
           (sum(value * value) - sum(value) * sum(value) / count(value)) / (count(value) - 1)
         ))
       END AS sigma
FROM (
  SELECT 'LOWINCPCT' AS measure_code, pct_low_income AS value FROM staging.acs_indicator
  UNION ALL
  SELECT 'PEOPCOLORPCT', pct_people_of_color FROM staging.acs_indicator
  UNION ALL
  SELECT 'LINGISOPCT', pct_limited_english FROM staging.acs_indicator
  UNION ALL
  SELECT 'LESSHSPCT', pct_less_than_hs FROM staging.acs_indicator
  UNION ALL
  SELECT 'DISABILITYPCT', pct_disability FROM staging.acs_indicator
  UNION ALL
  SELECT 'LIFEEXPPCT', pct_low_life_expectancy FROM staging.acs_indicator
) m
WHERE value IS NOT NULL
GROUP BY measure_code;

CREATE TABLE marts.acs_moment_state AS
SELECT state_fips,
       measure_code,
       count(value)::integer AS n,
       avg(value) AS mu,
       CASE
         WHEN count(value) > 1 THEN sqrt(greatest(
           0::double precision,
           (sum(value * value) - sum(value) * sum(value) / count(value)) / (count(value) - 1)
         ))
       END AS sigma
FROM (
  SELECT state_fips, 'LOWINCPCT' AS measure_code, pct_low_income AS value FROM staging.acs_indicator
  UNION ALL
  SELECT state_fips, 'PEOPCOLORPCT', pct_people_of_color FROM staging.acs_indicator
  UNION ALL
  SELECT state_fips, 'LINGISOPCT', pct_limited_english FROM staging.acs_indicator
  UNION ALL
  SELECT state_fips, 'LESSHSPCT', pct_less_than_hs FROM staging.acs_indicator
  UNION ALL
  SELECT state_fips, 'DISABILITYPCT', pct_disability FROM staging.acs_indicator
  UNION ALL
  SELECT state_fips, 'LIFEEXPPCT', pct_low_life_expectancy FROM staging.acs_indicator
) m
WHERE value IS NOT NULL
GROUP BY state_fips, measure_code;

CREATE TABLE marts.acs_block_group AS
WITH z AS (
  SELECT i.geoid,
         i.state_fips,
         i.pct_low_income,
         i.pct_people_of_color,
         i.pct_limited_english,
         i.pct_less_than_hs,
         i.pct_unemployed,
         i.pct_under_5,
         i.pct_over_64,
         i.pct_disability,
         i.pct_low_life_expectancy,
         (i.pct_low_income - u_li.mu) / NULLIF(u_li.sigma, 0) AS z_li,
         (i.pct_people_of_color - u_poc.mu) / NULLIF(u_poc.sigma, 0) AS z_poc,
         (i.pct_limited_english - u_ling.mu) / NULLIF(u_ling.sigma, 0) AS z_ling,
         (i.pct_less_than_hs - u_hs.mu) / NULLIF(u_hs.sigma, 0) AS z_hs,
         (i.pct_disability - u_dis.mu) / NULLIF(u_dis.sigma, 0) AS z_dis,
         (i.pct_low_life_expectancy - u_life.mu) / NULLIF(u_life.sigma, 0) AS z_life,
         (i.pct_low_income - s_li.mu) / NULLIF(s_li.sigma, 0) AS z_li_st,
         (i.pct_people_of_color - s_poc.mu) / NULLIF(s_poc.sigma, 0) AS z_poc_st,
         (i.pct_limited_english - s_ling.mu) / NULLIF(s_ling.sigma, 0) AS z_ling_st,
         (i.pct_less_than_hs - s_hs.mu) / NULLIF(s_hs.sigma, 0) AS z_hs_st,
         (i.pct_disability - s_dis.mu) / NULLIF(s_dis.sigma, 0) AS z_dis_st,
         (i.pct_low_life_expectancy - s_life.mu) / NULLIF(s_life.sigma, 0) AS z_life_st
  FROM staging.acs_indicator i
  LEFT JOIN marts.acs_moment_us u_li ON u_li.measure_code = 'LOWINCPCT'
  LEFT JOIN marts.acs_moment_us u_poc ON u_poc.measure_code = 'PEOPCOLORPCT'
  LEFT JOIN marts.acs_moment_us u_ling ON u_ling.measure_code = 'LINGISOPCT'
  LEFT JOIN marts.acs_moment_us u_hs ON u_hs.measure_code = 'LESSHSPCT'
  LEFT JOIN marts.acs_moment_us u_dis ON u_dis.measure_code = 'DISABILITYPCT'
  LEFT JOIN marts.acs_moment_us u_life ON u_life.measure_code = 'LIFEEXPPCT'
  LEFT JOIN marts.acs_moment_state s_li
    ON s_li.measure_code = 'LOWINCPCT' AND s_li.state_fips = i.state_fips
  LEFT JOIN marts.acs_moment_state s_poc
    ON s_poc.measure_code = 'PEOPCOLORPCT' AND s_poc.state_fips = i.state_fips
  LEFT JOIN marts.acs_moment_state s_ling
    ON s_ling.measure_code = 'LINGISOPCT' AND s_ling.state_fips = i.state_fips
  LEFT JOIN marts.acs_moment_state s_hs
    ON s_hs.measure_code = 'LESSHSPCT' AND s_hs.state_fips = i.state_fips
  LEFT JOIN marts.acs_moment_state s_dis
    ON s_dis.measure_code = 'DISABILITYPCT' AND s_dis.state_fips = i.state_fips
  LEFT JOIN marts.acs_moment_state s_life
    ON s_life.measure_code = 'LIFEEXPPCT' AND s_life.state_fips = i.state_fips
),
unshifted AS (
  SELECT z.*,
         CASE
           WHEN z_li IS NULL OR z_poc IS NULL THEN NULL
           ELSE (z_li + z_poc) / 2.0
         END AS demog_u,
         CASE
           WHEN z_li_st IS NULL OR z_poc_st IS NULL THEN NULL
           ELSE (z_li_st + z_poc_st) / 2.0
         END AS demog_u_st,
         CASE
           WHEN z_li IS NOT NULL AND z_ling IS NOT NULL AND z_hs IS NOT NULL AND z_dis IS NOT NULL AND z_life IS NOT NULL
             THEN (z_li + z_ling + z_hs + z_dis + z_life) / 5.0
           WHEN z_li IS NOT NULL AND z_ling IS NOT NULL AND z_hs IS NOT NULL AND z_dis IS NOT NULL AND z_life IS NULL
             THEN (z_li + z_ling + z_hs + z_dis) / 4.0
           ELSE NULL
         END AS supp_u,
         CASE
           WHEN z_li_st IS NOT NULL AND z_ling_st IS NOT NULL AND z_hs_st IS NOT NULL AND z_dis_st IS NOT NULL AND z_life_st IS NOT NULL
             THEN (z_li_st + z_ling_st + z_hs_st + z_dis_st + z_life_st) / 5.0
           WHEN z_li_st IS NOT NULL AND z_ling_st IS NOT NULL AND z_hs_st IS NOT NULL AND z_dis_st IS NOT NULL AND z_life_st IS NULL
             THEN (z_li_st + z_ling_st + z_hs_st + z_dis_st) / 4.0
           ELSE NULL
         END AS supp_u_st
  FROM z
),
us_shift AS (
  SELECT min(demog_u) AS min_demog, min(supp_u) AS min_supp FROM unshifted
),
st_shift AS (
  SELECT state_fips, min(demog_u_st) AS min_demog, min(supp_u_st) AS min_supp
  FROM unshifted
  GROUP BY state_fips
)
SELECT u.geoid,
       u.state_fips,
       s.state_abbrev,
       u.pct_low_income,
       u.pct_people_of_color,
       u.pct_limited_english,
       u.pct_less_than_hs,
       u.pct_unemployed,
       u.pct_under_5,
       u.pct_over_64,
       u.pct_disability,
       u.pct_low_life_expectancy,
       u.demog_u AS demogidx_2_unshifted,
       u.demog_u + abs(us.min_demog) AS demogidx_2,
       u.demog_u_st AS demogidx_2st_unshifted,
       u.demog_u_st + abs(st.min_demog) AS demogidx_2st,
       u.supp_u AS demogidx_5_unshifted,
       u.supp_u + abs(us.min_supp) AS demogidx_5,
       u.supp_u_st AS demogidx_5st_unshifted,
       u.supp_u_st + abs(st.min_supp) AS demogidx_5st
FROM unshifted u
CROSS JOIN us_shift us
JOIN st_shift st ON st.state_fips = u.state_fips
LEFT JOIN staging.block_group_inputs s ON s.geoid = u.geoid;

ALTER TABLE marts.acs_block_group ADD PRIMARY KEY (geoid);
ANALYZE marts.acs_block_group;

COMMENT ON TABLE marts.acs_block_group IS
  'Demographic Index and Supplemental Demographic Index rebuilt from ACS 2018-2022 and USALEEP. Tech doc pp. 31 to 39.';
COMMENT ON COLUMN marts.acs_block_group.geoid IS
  '12 character block group id from the ACS state, county, tract, and block group codes.';
COMMENT ON COLUMN marts.acs_block_group.state_fips IS
  'State, District of Columbia, or Puerto Rico FIPS code. Island territories are not in the ACS extract.';
COMMENT ON COLUMN marts.acs_block_group.state_abbrev IS
  'State abbreviation from the Tier 1 reference row when the id matches. Null when the ACS id is not in the reference.';
COMMENT ON COLUMN marts.acs_block_group.pct_low_income IS
  'Percent low income, (C17002.001 - C17002.008) / C17002.001. A zero denominator is 0. Tech doc pp. 8 to 9 and p. 32.';
COMMENT ON COLUMN marts.acs_block_group.pct_people_of_color IS
  'Percent people of color, (B03002.001 - B03002.003) / B03002.001. A zero denominator is 0. Tech doc p. 7 and p. 32.';
COMMENT ON COLUMN marts.acs_block_group.pct_limited_english IS
  'Percent limited English speaking households from C16002. A zero denominator is 0. Tech doc p. 10 and p. 34.';
COMMENT ON COLUMN marts.acs_block_group.pct_less_than_hs IS
  'Percent less than high school from B15002, including B15002.027. A zero denominator is 0. Tech doc pp. 11 to 12 and Table 5.';
COMMENT ON COLUMN marts.acs_block_group.pct_unemployed IS
  'Unemployment in the civilian labor force, B23025.005 / B23025.003. A zero denominator is 0. Tech doc pp. 9 to 10. Not an index input.';
COMMENT ON COLUMN marts.acs_block_group.pct_under_5 IS
  'Percent under age 5, (B01001.003 + B01001.027) / B01001.001. A zero denominator is 0. Tech doc p. 12. Not an index input.';
COMMENT ON COLUMN marts.acs_block_group.pct_over_64 IS
  'Percent over age 64 from the printed B01001 sum. A zero denominator is 0. Tech doc p. 13. Not an index input.';
COMMENT ON COLUMN marts.acs_block_group.pct_disability IS
  'Tract B18101 disability rate assigned to each block group in the tract. A zero tract total is 0. Tech doc p. 34 and p. 55.';
COMMENT ON COLUMN marts.acs_block_group.pct_low_life_expectancy IS
  '1 minus life expectancy at birth divided by 97.5. 97.5 is derived from the reference, not printed in the tech doc. Tech doc p. 33.';
COMMENT ON COLUMN marts.acs_block_group.demogidx_2_unshifted IS
  'Average of the national low income and people of color z-scores, before the shift. Tech doc p. 32.';
COMMENT ON COLUMN marts.acs_block_group.demogidx_2 IS
  'National Demographic Index after adding the absolute value of the smallest national unshifted index. Tech doc p. 33 and pp. 36 to 37.';
COMMENT ON COLUMN marts.acs_block_group.demogidx_2st_unshifted IS
  'Average of the state low income and people of color z-scores, before the state shift. Tech doc p. 33.';
COMMENT ON COLUMN marts.acs_block_group.demogidx_2st IS
  'State Demographic Index after the state shift. Tech doc p. 33.';
COMMENT ON COLUMN marts.acs_block_group.demogidx_5_unshifted IS
  'Average of five national supplemental z-scores, or four where low life expectancy is missing, before the shift. Tech doc p. 35.';
COMMENT ON COLUMN marts.acs_block_group.demogidx_5 IS
  'National Supplemental Demographic Index after the non-negative shift. Tech doc p. 35 and pp. 38 to 39.';
COMMENT ON COLUMN marts.acs_block_group.demogidx_5st_unshifted IS
  'Average of five state supplemental z-scores, or four where low life expectancy is missing, before the state shift. Tech doc p. 35.';
COMMENT ON COLUMN marts.acs_block_group.demogidx_5st IS
  'State Supplemental Demographic Index after the state shift. Tech doc p. 35.';

COMMENT ON TABLE marts.acs_moment_us IS
  'Unweighted national mean and sample standard deviation of the ACS supplemental and demographic rates. Zero denominators are included as 0. Sample divisor n - 1. Tech doc pp. 31 to 35.';
COMMENT ON TABLE marts.acs_moment_state IS
  'Unweighted state mean and sample standard deviation of the same rates. Includes the District of Columbia and Puerto Rico. Zero denominators are included as 0. Tech doc p. 33 and p. 35.';

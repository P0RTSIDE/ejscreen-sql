DROP TABLE IF EXISTS marts.demographic_index;
DROP TABLE IF EXISTS marts.moment_state;
DROP TABLE IF EXISTS marts.moment_us;

CREATE TABLE marts.moment_us AS
SELECT measure_code,
       count(value)::integer AS n,
       avg(value) AS mu,
       CASE
         WHEN count(value) > 1 THEN sqrt(greatest(
           0::double precision,
           (sum(value * value) - sum(value) * sum(value) / count(value)) / (count(value) - 1)
         ))
       END AS sigma
FROM staging.measure_value
WHERE in_national_universe
  AND value IS NOT NULL
  AND measure_code IN ('LOWINCPCT', 'PEOPCOLORPCT', 'LINGISOPCT', 'LESSHSPCT', 'DISABILITYPCT', 'LIFEEXPPCT')
GROUP BY measure_code;

CREATE TABLE marts.moment_state AS
SELECT state_abbrev,
       measure_code,
       count(value)::integer AS n,
       avg(value) AS mu,
       CASE
         WHEN count(value) > 1 THEN sqrt(greatest(
           0::double precision,
           (sum(value * value) - sum(value) * sum(value) / count(value)) / (count(value) - 1)
         ))
       END AS sigma
FROM staging.measure_value
WHERE value IS NOT NULL
  AND measure_code IN ('LOWINCPCT', 'PEOPCOLORPCT', 'LINGISOPCT', 'LESSHSPCT', 'DISABILITYPCT', 'LIFEEXPPCT')
GROUP BY state_abbrev, measure_code;

CREATE TABLE marts.demographic_index AS
WITH z AS (
  SELECT m.geoid,
         m.state_abbrev,
         m.in_national_universe,
         m.measure_code,
         (m.value - u.mu) / NULLIF(u.sigma, 0) AS z_us,
         (m.value - s.mu) / NULLIF(s.sigma, 0) AS z_st
  FROM staging.measure_value m
  LEFT JOIN marts.moment_us u ON u.measure_code = m.measure_code
  LEFT JOIN marts.moment_state s
    ON s.measure_code = m.measure_code
   AND s.state_abbrev = m.state_abbrev
  WHERE m.measure_code IN ('LOWINCPCT', 'PEOPCOLORPCT', 'LINGISOPCT', 'LESSHSPCT', 'DISABILITYPCT', 'LIFEEXPPCT')
),
wide AS (
  SELECT geoid,
         state_abbrev,
         in_national_universe,
         max(z_us) FILTER (WHERE measure_code = 'LOWINCPCT') AS z_li,
    max(z_us) FILTER (WHERE measure_code = 'PEOPCOLORPCT') AS z_poc,
    max(z_us) FILTER (WHERE measure_code = 'LINGISOPCT') AS z_ling,
    max(z_us) FILTER (WHERE measure_code = 'LESSHSPCT') AS z_hs,
    max(z_us) FILTER (WHERE measure_code = 'DISABILITYPCT') AS z_dis,
    max(z_us) FILTER (WHERE measure_code = 'LIFEEXPPCT') AS z_life,
    max(z_st) FILTER (WHERE measure_code = 'LOWINCPCT') AS z_li_st,
    max(z_st) FILTER (WHERE measure_code = 'PEOPCOLORPCT') AS z_poc_st,
    max(z_st) FILTER (WHERE measure_code = 'LINGISOPCT') AS z_ling_st,
    max(z_st) FILTER (WHERE measure_code = 'LESSHSPCT') AS z_hs_st,
    max(z_st) FILTER (WHERE measure_code = 'DISABILITYPCT') AS z_dis_st,
    max(z_st) FILTER (WHERE measure_code = 'LIFEEXPPCT') AS z_life_st
  FROM z
  GROUP BY geoid, state_abbrev, in_national_universe
),
unshifted AS (
  SELECT wide.*,
         CASE
           WHEN z_li IS NULL OR z_poc IS NULL THEN NULL
           ELSE (z_li + z_poc) / 2.0
         END AS demog_u,
         CASE
           WHEN z_li IS NOT NULL AND z_ling IS NOT NULL AND z_hs IS NOT NULL AND z_dis IS NOT NULL AND z_life IS NOT NULL
             THEN (z_li + z_ling + z_hs + z_dis + z_life) / 5.0
           WHEN z_li IS NOT NULL AND z_ling IS NOT NULL AND z_hs IS NOT NULL AND z_dis IS NOT NULL AND z_life IS NULL
             THEN (z_li + z_ling + z_hs + z_dis) / 4.0
           ELSE NULL
         END AS supp_u,
         CASE
           WHEN z_li_st IS NULL OR z_poc_st IS NULL THEN NULL
           ELSE (z_li_st + z_poc_st) / 2.0
         END AS demog_u_st,
         CASE
           WHEN z_li_st IS NOT NULL AND z_ling_st IS NOT NULL AND z_hs_st IS NOT NULL AND z_dis_st IS NOT NULL AND z_life_st IS NOT NULL
             THEN (z_li_st + z_ling_st + z_hs_st + z_dis_st + z_life_st) / 5.0
           WHEN z_li_st IS NOT NULL AND z_ling_st IS NOT NULL AND z_hs_st IS NOT NULL AND z_dis_st IS NOT NULL AND z_life_st IS NULL
             THEN (z_li_st + z_ling_st + z_hs_st + z_dis_st) / 4.0
           ELSE NULL
         END AS supp_u_st
  FROM wide
),
us_shift AS (
  SELECT min(demog_u) AS min_demog, min(supp_u) AS min_supp
  FROM unshifted
  WHERE in_national_universe
),
st_shift AS (
  SELECT state_abbrev, min(demog_u_st) AS min_demog, min(supp_u_st) AS min_supp
  FROM unshifted
  GROUP BY state_abbrev
)
SELECT u.geoid,
       u.demog_u AS demogidx_2_unshifted,
       u.demog_u + abs(us.min_demog) AS demogidx_2,
       u.supp_u AS demogidx_5_unshifted,
       u.supp_u + abs(us.min_supp) AS demogidx_5,
       u.demog_u_st AS demogidx_2st_unshifted,
       u.demog_u_st + abs(st.min_demog) AS demogidx_2st,
       u.supp_u_st AS demogidx_5st_unshifted,
       u.supp_u_st + abs(st.min_supp) AS demogidx_5st
FROM unshifted u
CROSS JOIN us_shift us
JOIN st_shift st ON st.state_abbrev = u.state_abbrev;

ALTER TABLE marts.demographic_index ADD PRIMARY KEY (geoid);
ANALYZE marts.demographic_index;

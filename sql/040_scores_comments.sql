DROP VIEW IF EXISTS marts.indicator_percent_rank;
DROP TABLE IF EXISTS marts.block_group_score;

CREATE TABLE marts.block_group_score AS
SELECT
  s.geoid,
  s.state_fips,
  s.state_abbrev,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'DEMOGIDX_2') AS demogidx_2,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'DEMOGIDX_5') AS demogidx_5,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'DEMOGIDX_2ST') AS demogidx_2st,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'DEMOGIDX_5ST') AS demogidx_5st,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'P_DEMOGIDX_2') AS p_demogidx_2,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'P_DEMOGIDX_5') AS p_demogidx_5,
  max(r.value) FILTER (WHERE r.scope = 'state_file' AND r.column_name = 'P_DEMOGIDX_2') AS st_p_demogidx_2,
  max(r.value) FILTER (WHERE r.scope = 'state_file' AND r.column_name = 'P_DEMOGIDX_5') AS st_p_demogidx_5,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'P_PEOPCOLORPCT') AS p_peopcolorpct,
  max(r.value) FILTER (WHERE r.scope = 'state_file' AND r.column_name = 'P_PEOPCOLORPCT') AS st_p_peopcolorpct,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'P_LOWINCPCT') AS p_lowincpct,
  max(r.value) FILTER (WHERE r.scope = 'state_file' AND r.column_name = 'P_LOWINCPCT') AS st_p_lowincpct,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'P_UNEMPPCT') AS p_unemppct,
  max(r.value) FILTER (WHERE r.scope = 'state_file' AND r.column_name = 'P_UNEMPPCT') AS st_p_unemppct,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'P_DISABILITYPCT') AS p_disabilitypct,
  max(r.value) FILTER (WHERE r.scope = 'state_file' AND r.column_name = 'P_DISABILITYPCT') AS st_p_disabilitypct,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'P_LINGISOPCT') AS p_lingisopct,
  max(r.value) FILTER (WHERE r.scope = 'state_file' AND r.column_name = 'P_LINGISOPCT') AS st_p_lingisopct,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'P_LESSHSPCT') AS p_lesshspct,
  max(r.value) FILTER (WHERE r.scope = 'state_file' AND r.column_name = 'P_LESSHSPCT') AS st_p_lesshspct,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'P_UNDER5PCT') AS p_under5pct,
  max(r.value) FILTER (WHERE r.scope = 'state_file' AND r.column_name = 'P_UNDER5PCT') AS st_p_under5pct,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'P_OVER64PCT') AS p_over64pct,
  max(r.value) FILTER (WHERE r.scope = 'state_file' AND r.column_name = 'P_OVER64PCT') AS st_p_over64pct,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'P_LIFEEXPPCT') AS p_lifeexppct,
  max(r.value) FILTER (WHERE r.scope = 'state_file' AND r.column_name = 'P_LIFEEXPPCT') AS st_p_lifeexppct,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'P_PM25') AS p_pm25,
  max(r.value) FILTER (WHERE r.scope = 'state_file' AND r.column_name = 'P_PM25') AS st_p_pm25,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'D2_PM25') AS d2_pm25,
  max(r.value) FILTER (WHERE r.scope = 'state_file' AND r.column_name = 'D2_PM25') AS st_d2_pm25,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'P_D2_PM25') AS p_d2_pm25,
  max(r.value) FILTER (WHERE r.scope = 'state_file' AND r.column_name = 'P_D2_PM25') AS st_p_d2_pm25,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'D5_PM25') AS d5_pm25,
  max(r.value) FILTER (WHERE r.scope = 'state_file' AND r.column_name = 'D5_PM25') AS st_d5_pm25,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'P_D5_PM25') AS p_d5_pm25,
  max(r.value) FILTER (WHERE r.scope = 'state_file' AND r.column_name = 'P_D5_PM25') AS st_p_d5_pm25,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'P_OZONE') AS p_ozone,
  max(r.value) FILTER (WHERE r.scope = 'state_file' AND r.column_name = 'P_OZONE') AS st_p_ozone,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'D2_OZONE') AS d2_ozone,
  max(r.value) FILTER (WHERE r.scope = 'state_file' AND r.column_name = 'D2_OZONE') AS st_d2_ozone,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'P_D2_OZONE') AS p_d2_ozone,
  max(r.value) FILTER (WHERE r.scope = 'state_file' AND r.column_name = 'P_D2_OZONE') AS st_p_d2_ozone,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'D5_OZONE') AS d5_ozone,
  max(r.value) FILTER (WHERE r.scope = 'state_file' AND r.column_name = 'D5_OZONE') AS st_d5_ozone,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'P_D5_OZONE') AS p_d5_ozone,
  max(r.value) FILTER (WHERE r.scope = 'state_file' AND r.column_name = 'P_D5_OZONE') AS st_p_d5_ozone,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'P_DSLPM') AS p_dslpm,
  max(r.value) FILTER (WHERE r.scope = 'state_file' AND r.column_name = 'P_DSLPM') AS st_p_dslpm,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'D2_DSLPM') AS d2_dslpm,
  max(r.value) FILTER (WHERE r.scope = 'state_file' AND r.column_name = 'D2_DSLPM') AS st_d2_dslpm,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'P_D2_DSLPM') AS p_d2_dslpm,
  max(r.value) FILTER (WHERE r.scope = 'state_file' AND r.column_name = 'P_D2_DSLPM') AS st_p_d2_dslpm,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'D5_DSLPM') AS d5_dslpm,
  max(r.value) FILTER (WHERE r.scope = 'state_file' AND r.column_name = 'D5_DSLPM') AS st_d5_dslpm,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'P_D5_DSLPM') AS p_d5_dslpm,
  max(r.value) FILTER (WHERE r.scope = 'state_file' AND r.column_name = 'P_D5_DSLPM') AS st_p_d5_dslpm,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'P_RSEI_AIR') AS p_rsei_air,
  max(r.value) FILTER (WHERE r.scope = 'state_file' AND r.column_name = 'P_RSEI_AIR') AS st_p_rsei_air,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'D2_RSEI_AIR') AS d2_rsei_air,
  max(r.value) FILTER (WHERE r.scope = 'state_file' AND r.column_name = 'D2_RSEI_AIR') AS st_d2_rsei_air,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'P_D2_RSEI_AIR') AS p_d2_rsei_air,
  max(r.value) FILTER (WHERE r.scope = 'state_file' AND r.column_name = 'P_D2_RSEI_AIR') AS st_p_d2_rsei_air,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'D5_RSEI_AIR') AS d5_rsei_air,
  max(r.value) FILTER (WHERE r.scope = 'state_file' AND r.column_name = 'D5_RSEI_AIR') AS st_d5_rsei_air,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'P_D5_RSEI_AIR') AS p_d5_rsei_air,
  max(r.value) FILTER (WHERE r.scope = 'state_file' AND r.column_name = 'P_D5_RSEI_AIR') AS st_p_d5_rsei_air,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'P_PTRAF') AS p_ptraf,
  max(r.value) FILTER (WHERE r.scope = 'state_file' AND r.column_name = 'P_PTRAF') AS st_p_ptraf,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'D2_PTRAF') AS d2_ptraf,
  max(r.value) FILTER (WHERE r.scope = 'state_file' AND r.column_name = 'D2_PTRAF') AS st_d2_ptraf,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'P_D2_PTRAF') AS p_d2_ptraf,
  max(r.value) FILTER (WHERE r.scope = 'state_file' AND r.column_name = 'P_D2_PTRAF') AS st_p_d2_ptraf,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'D5_PTRAF') AS d5_ptraf,
  max(r.value) FILTER (WHERE r.scope = 'state_file' AND r.column_name = 'D5_PTRAF') AS st_d5_ptraf,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'P_D5_PTRAF') AS p_d5_ptraf,
  max(r.value) FILTER (WHERE r.scope = 'state_file' AND r.column_name = 'P_D5_PTRAF') AS st_p_d5_ptraf,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'P_LDPNT') AS p_ldpnt,
  max(r.value) FILTER (WHERE r.scope = 'state_file' AND r.column_name = 'P_LDPNT') AS st_p_ldpnt,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'D2_LDPNT') AS d2_ldpnt,
  max(r.value) FILTER (WHERE r.scope = 'state_file' AND r.column_name = 'D2_LDPNT') AS st_d2_ldpnt,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'P_D2_LDPNT') AS p_d2_ldpnt,
  max(r.value) FILTER (WHERE r.scope = 'state_file' AND r.column_name = 'P_D2_LDPNT') AS st_p_d2_ldpnt,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'D5_LDPNT') AS d5_ldpnt,
  max(r.value) FILTER (WHERE r.scope = 'state_file' AND r.column_name = 'D5_LDPNT') AS st_d5_ldpnt,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'P_D5_LDPNT') AS p_d5_ldpnt,
  max(r.value) FILTER (WHERE r.scope = 'state_file' AND r.column_name = 'P_D5_LDPNT') AS st_p_d5_ldpnt,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'P_PNPL') AS p_pnpl,
  max(r.value) FILTER (WHERE r.scope = 'state_file' AND r.column_name = 'P_PNPL') AS st_p_pnpl,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'D2_PNPL') AS d2_pnpl,
  max(r.value) FILTER (WHERE r.scope = 'state_file' AND r.column_name = 'D2_PNPL') AS st_d2_pnpl,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'P_D2_PNPL') AS p_d2_pnpl,
  max(r.value) FILTER (WHERE r.scope = 'state_file' AND r.column_name = 'P_D2_PNPL') AS st_p_d2_pnpl,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'D5_PNPL') AS d5_pnpl,
  max(r.value) FILTER (WHERE r.scope = 'state_file' AND r.column_name = 'D5_PNPL') AS st_d5_pnpl,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'P_D5_PNPL') AS p_d5_pnpl,
  max(r.value) FILTER (WHERE r.scope = 'state_file' AND r.column_name = 'P_D5_PNPL') AS st_p_d5_pnpl,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'P_PRMP') AS p_prmp,
  max(r.value) FILTER (WHERE r.scope = 'state_file' AND r.column_name = 'P_PRMP') AS st_p_prmp,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'D2_PRMP') AS d2_prmp,
  max(r.value) FILTER (WHERE r.scope = 'state_file' AND r.column_name = 'D2_PRMP') AS st_d2_prmp,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'P_D2_PRMP') AS p_d2_prmp,
  max(r.value) FILTER (WHERE r.scope = 'state_file' AND r.column_name = 'P_D2_PRMP') AS st_p_d2_prmp,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'D5_PRMP') AS d5_prmp,
  max(r.value) FILTER (WHERE r.scope = 'state_file' AND r.column_name = 'D5_PRMP') AS st_d5_prmp,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'P_D5_PRMP') AS p_d5_prmp,
  max(r.value) FILTER (WHERE r.scope = 'state_file' AND r.column_name = 'P_D5_PRMP') AS st_p_d5_prmp,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'P_PTSDF') AS p_ptsdf,
  max(r.value) FILTER (WHERE r.scope = 'state_file' AND r.column_name = 'P_PTSDF') AS st_p_ptsdf,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'D2_PTSDF') AS d2_ptsdf,
  max(r.value) FILTER (WHERE r.scope = 'state_file' AND r.column_name = 'D2_PTSDF') AS st_d2_ptsdf,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'P_D2_PTSDF') AS p_d2_ptsdf,
  max(r.value) FILTER (WHERE r.scope = 'state_file' AND r.column_name = 'P_D2_PTSDF') AS st_p_d2_ptsdf,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'D5_PTSDF') AS d5_ptsdf,
  max(r.value) FILTER (WHERE r.scope = 'state_file' AND r.column_name = 'D5_PTSDF') AS st_d5_ptsdf,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'P_D5_PTSDF') AS p_d5_ptsdf,
  max(r.value) FILTER (WHERE r.scope = 'state_file' AND r.column_name = 'P_D5_PTSDF') AS st_p_d5_ptsdf,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'P_UST') AS p_ust,
  max(r.value) FILTER (WHERE r.scope = 'state_file' AND r.column_name = 'P_UST') AS st_p_ust,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'D2_UST') AS d2_ust,
  max(r.value) FILTER (WHERE r.scope = 'state_file' AND r.column_name = 'D2_UST') AS st_d2_ust,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'P_D2_UST') AS p_d2_ust,
  max(r.value) FILTER (WHERE r.scope = 'state_file' AND r.column_name = 'P_D2_UST') AS st_p_d2_ust,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'D5_UST') AS d5_ust,
  max(r.value) FILTER (WHERE r.scope = 'state_file' AND r.column_name = 'D5_UST') AS st_d5_ust,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'P_D5_UST') AS p_d5_ust,
  max(r.value) FILTER (WHERE r.scope = 'state_file' AND r.column_name = 'P_D5_UST') AS st_p_d5_ust,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'P_PWDIS') AS p_pwdis,
  max(r.value) FILTER (WHERE r.scope = 'state_file' AND r.column_name = 'P_PWDIS') AS st_p_pwdis,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'D2_PWDIS') AS d2_pwdis,
  max(r.value) FILTER (WHERE r.scope = 'state_file' AND r.column_name = 'D2_PWDIS') AS st_d2_pwdis,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'P_D2_PWDIS') AS p_d2_pwdis,
  max(r.value) FILTER (WHERE r.scope = 'state_file' AND r.column_name = 'P_D2_PWDIS') AS st_p_d2_pwdis,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'D5_PWDIS') AS d5_pwdis,
  max(r.value) FILTER (WHERE r.scope = 'state_file' AND r.column_name = 'D5_PWDIS') AS st_d5_pwdis,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'P_D5_PWDIS') AS p_d5_pwdis,
  max(r.value) FILTER (WHERE r.scope = 'state_file' AND r.column_name = 'P_D5_PWDIS') AS st_p_d5_pwdis,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'P_NO2') AS p_no2,
  max(r.value) FILTER (WHERE r.scope = 'state_file' AND r.column_name = 'P_NO2') AS st_p_no2,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'D2_NO2') AS d2_no2,
  max(r.value) FILTER (WHERE r.scope = 'state_file' AND r.column_name = 'D2_NO2') AS st_d2_no2,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'P_D2_NO2') AS p_d2_no2,
  max(r.value) FILTER (WHERE r.scope = 'state_file' AND r.column_name = 'P_D2_NO2') AS st_p_d2_no2,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'D5_NO2') AS d5_no2,
  max(r.value) FILTER (WHERE r.scope = 'state_file' AND r.column_name = 'D5_NO2') AS st_d5_no2,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'P_D5_NO2') AS p_d5_no2,
  max(r.value) FILTER (WHERE r.scope = 'state_file' AND r.column_name = 'P_D5_NO2') AS st_p_d5_no2,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'P_DWATER') AS p_dwater,
  max(r.value) FILTER (WHERE r.scope = 'state_file' AND r.column_name = 'P_DWATER') AS st_p_dwater,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'D2_DWATER') AS d2_dwater,
  max(r.value) FILTER (WHERE r.scope = 'state_file' AND r.column_name = 'D2_DWATER') AS st_d2_dwater,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'P_D2_DWATER') AS p_d2_dwater,
  max(r.value) FILTER (WHERE r.scope = 'state_file' AND r.column_name = 'P_D2_DWATER') AS st_p_d2_dwater,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'D5_DWATER') AS d5_dwater,
  max(r.value) FILTER (WHERE r.scope = 'state_file' AND r.column_name = 'D5_DWATER') AS st_d5_dwater,
  max(r.value) FILTER (WHERE r.scope = 'national_file' AND r.column_name = 'P_D5_DWATER') AS p_d5_dwater,
  max(r.value) FILTER (WHERE r.scope = 'state_file' AND r.column_name = 'P_D5_DWATER') AS st_p_d5_dwater
FROM staging.block_group_inputs s
LEFT JOIN marts.rebuilt r ON r.geoid = s.geoid
GROUP BY s.geoid, s.state_fips, s.state_abbrev;

ALTER TABLE marts.block_group_score ADD PRIMARY KEY (geoid);

CREATE VIEW marts.indicator_percent_rank AS
SELECT scope,
       percentile_column,
       geoid,
       value,
       percent_rank() OVER (PARTITION BY scope, percentile_column ORDER BY value) * 100
         AS percent_rank_0_100
FROM marts.ranked_value;

COMMENT ON TABLE marts.block_group_score IS 'Rebuilt EJScreen version 2.3 demographic indexes, indicator percentiles, EJ indexes, and supplemental indexes. National columns follow pp. 31 to 42. State columns use the same formulas inside each state. The tech doc states no cap on the index product.';
COMMENT ON COLUMN marts.block_group_score.geoid IS '12 character id. Census block group id, or a zero padded place or estate code. See assumptions for the padding rule.';
COMMENT ON COLUMN marts.block_group_score.state_fips IS 'First two digits of the source id. Includes 11 for the District of Columbia and 72 for Puerto Rico.';
COMMENT ON COLUMN marts.block_group_score.state_abbrev IS 'State, District of Columbia, Puerto Rico, or island territory abbreviation from the reference file.';
COMMENT ON COLUMN marts.block_group_score.demogidx_2 IS 'Demographic Index, shifted national average of the low income and people of color z scores. Tech doc pp. 32 to 33 and pp. 36 to 37.';
COMMENT ON COLUMN marts.block_group_score.demogidx_5 IS 'Supplemental Demographic Index, shifted national average of five z scores, or four when low life expectancy is missing. Tech doc pp. 33 to 35 and pp. 38 to 39.';
COMMENT ON COLUMN marts.block_group_score.demogidx_2st IS 'State Demographic Index. Same formula as the national Demographic Index, using the state mean, sample standard deviation, and shift. Tech doc p. 33.';
COMMENT ON COLUMN marts.block_group_score.demogidx_5st IS 'State Supplemental Demographic Index. Tech doc p. 35.';
COMMENT ON COLUMN marts.block_group_score.p_demogidx_2 IS 'National percentile of the Demographic Index. Tech doc pp. 40 to 42.';
COMMENT ON COLUMN marts.block_group_score.p_demogidx_5 IS 'National percentile of the Supplemental Demographic Index. Tech doc pp. 40 to 42.';
COMMENT ON COLUMN marts.block_group_score.st_p_demogidx_2 IS 'State percentile of the state Demographic Index. Tech doc pp. 41 to 42.';
COMMENT ON COLUMN marts.block_group_score.st_p_demogidx_5 IS 'State percentile of the state Supplemental Demographic Index. Tech doc pp. 41 to 42.';
COMMENT ON COLUMN marts.block_group_score.p_peopcolorpct IS 'National percentile of Percent people of color. Tech doc p. 7 and p. 32 and pp. 40 to 42.';
COMMENT ON COLUMN marts.block_group_score.st_p_peopcolorpct IS 'State percentile of Percent people of color. Tech doc p. 7 and p. 32 and pp. 41 to 42.';
COMMENT ON COLUMN marts.block_group_score.p_lowincpct IS 'National percentile of Percent low income. Tech doc pp. 8 to 9 and p. 32 and pp. 40 to 42.';
COMMENT ON COLUMN marts.block_group_score.st_p_lowincpct IS 'State percentile of Percent low income. Tech doc pp. 8 to 9 and p. 32 and pp. 41 to 42.';
COMMENT ON COLUMN marts.block_group_score.p_unemppct IS 'National percentile of Percent unemployed. Tech doc pp. 9 to 10 and pp. 40 to 42.';
COMMENT ON COLUMN marts.block_group_score.st_p_unemppct IS 'State percentile of Percent unemployed. Tech doc pp. 9 to 10 and pp. 41 to 42.';
COMMENT ON COLUMN marts.block_group_score.p_disabilitypct IS 'National percentile of Percent persons with disabilities. Tech doc p. 34 and pp. 40 to 42.';
COMMENT ON COLUMN marts.block_group_score.st_p_disabilitypct IS 'State percentile of Percent persons with disabilities. Tech doc p. 34 and pp. 41 to 42.';
COMMENT ON COLUMN marts.block_group_score.p_lingisopct IS 'National percentile of Percent limited English speaking households. Tech doc p. 10 and p. 34 and pp. 40 to 42.';
COMMENT ON COLUMN marts.block_group_score.st_p_lingisopct IS 'State percentile of Percent limited English speaking households. Tech doc p. 10 and p. 34 and pp. 41 to 42.';
COMMENT ON COLUMN marts.block_group_score.p_lesshspct IS 'National percentile of Percent less than high school education. Tech doc pp. 11 to 12 and pp. 34 to 35 and pp. 40 to 42.';
COMMENT ON COLUMN marts.block_group_score.st_p_lesshspct IS 'State percentile of Percent less than high school education. Tech doc pp. 11 to 12 and pp. 34 to 35 and pp. 41 to 42.';
COMMENT ON COLUMN marts.block_group_score.p_under5pct IS 'National percentile of Percent under age 5. Tech doc pp. 12 to 13 and pp. 40 to 42.';
COMMENT ON COLUMN marts.block_group_score.st_p_under5pct IS 'State percentile of Percent under age 5. Tech doc pp. 12 to 13 and pp. 41 to 42.';
COMMENT ON COLUMN marts.block_group_score.p_over64pct IS 'National percentile of Percent over age 64. Tech doc pp. 12 to 13 and pp. 40 to 42.';
COMMENT ON COLUMN marts.block_group_score.st_p_over64pct IS 'State percentile of Percent over age 64. Tech doc pp. 12 to 13 and pp. 41 to 42.';
COMMENT ON COLUMN marts.block_group_score.p_lifeexppct IS 'National percentile of Low life expectancy. Tech doc p. 33 and p. 55 and pp. 40 to 42.';
COMMENT ON COLUMN marts.block_group_score.st_p_lifeexppct IS 'State percentile of Low life expectancy. Tech doc p. 33 and p. 55 and pp. 41 to 42.';
COMMENT ON COLUMN marts.block_group_score.p_pm25 IS 'National percentile of Particulate Matter 2.5. Tech doc p. 16 and pp. 40 to 42.';
COMMENT ON COLUMN marts.block_group_score.st_p_pm25 IS 'State percentile of Particulate Matter 2.5. Tech doc p. 16 and pp. 41 to 42.';
COMMENT ON COLUMN marts.block_group_score.d2_pm25 IS 'National EJ index for Particulate Matter 2.5: shifted demographic index times the national environmental percentile on a 0 to 100 scale. Tech doc p. 36 and p. 16.';
COMMENT ON COLUMN marts.block_group_score.st_d2_pm25 IS 'State EJ index for Particulate Matter 2.5: shifted state demographic index times the state environmental percentile on a 0 to 100 scale. Tech doc p. 36, p. 33, and pp. 41 to 43.';
COMMENT ON COLUMN marts.block_group_score.p_d2_pm25 IS 'National percentile of the EJ index for Particulate Matter 2.5. Tech doc pp. 36 to 42.';
COMMENT ON COLUMN marts.block_group_score.st_p_d2_pm25 IS 'State percentile of the state EJ index for Particulate Matter 2.5. Tech doc pp. 41 to 43.';
COMMENT ON COLUMN marts.block_group_score.d5_pm25 IS 'National supplemental index for Particulate Matter 2.5: shifted demographic index times the national environmental percentile on a 0 to 100 scale. Tech doc p. 38 and p. 16.';
COMMENT ON COLUMN marts.block_group_score.st_d5_pm25 IS 'State supplemental index for Particulate Matter 2.5: shifted state demographic index times the state environmental percentile on a 0 to 100 scale. Tech doc p. 38, p. 33, and pp. 41 to 43.';
COMMENT ON COLUMN marts.block_group_score.p_d5_pm25 IS 'National percentile of the supplemental index for Particulate Matter 2.5. Tech doc pp. 36 to 42.';
COMMENT ON COLUMN marts.block_group_score.st_p_d5_pm25 IS 'State percentile of the state supplemental index for Particulate Matter 2.5. Tech doc pp. 41 to 43.';
COMMENT ON COLUMN marts.block_group_score.p_ozone IS 'National percentile of Ozone. Tech doc pp. 16 to 17 and pp. 40 to 42.';
COMMENT ON COLUMN marts.block_group_score.st_p_ozone IS 'State percentile of Ozone. Tech doc pp. 16 to 17 and pp. 41 to 42.';
COMMENT ON COLUMN marts.block_group_score.d2_ozone IS 'National EJ index for Ozone: shifted demographic index times the national environmental percentile on a 0 to 100 scale. Tech doc p. 36 and pp. 16 to 17.';
COMMENT ON COLUMN marts.block_group_score.st_d2_ozone IS 'State EJ index for Ozone: shifted state demographic index times the state environmental percentile on a 0 to 100 scale. Tech doc p. 36, p. 33, and pp. 41 to 43.';
COMMENT ON COLUMN marts.block_group_score.p_d2_ozone IS 'National percentile of the EJ index for Ozone. Tech doc pp. 36 to 42.';
COMMENT ON COLUMN marts.block_group_score.st_p_d2_ozone IS 'State percentile of the state EJ index for Ozone. Tech doc pp. 41 to 43.';
COMMENT ON COLUMN marts.block_group_score.d5_ozone IS 'National supplemental index for Ozone: shifted demographic index times the national environmental percentile on a 0 to 100 scale. Tech doc p. 38 and pp. 16 to 17.';
COMMENT ON COLUMN marts.block_group_score.st_d5_ozone IS 'State supplemental index for Ozone: shifted state demographic index times the state environmental percentile on a 0 to 100 scale. Tech doc p. 38, p. 33, and pp. 41 to 43.';
COMMENT ON COLUMN marts.block_group_score.p_d5_ozone IS 'National percentile of the supplemental index for Ozone. Tech doc pp. 36 to 42.';
COMMENT ON COLUMN marts.block_group_score.st_p_d5_ozone IS 'State percentile of the state supplemental index for Ozone. Tech doc pp. 41 to 43.';
COMMENT ON COLUMN marts.block_group_score.p_dslpm IS 'National percentile of Diesel particulate matter. Tech doc p. 19 and pp. 40 to 42.';
COMMENT ON COLUMN marts.block_group_score.st_p_dslpm IS 'State percentile of Diesel particulate matter. Tech doc p. 19 and pp. 41 to 42.';
COMMENT ON COLUMN marts.block_group_score.d2_dslpm IS 'National EJ index for Diesel particulate matter: shifted demographic index times the national environmental percentile on a 0 to 100 scale. Tech doc p. 36 and p. 19.';
COMMENT ON COLUMN marts.block_group_score.st_d2_dslpm IS 'State EJ index for Diesel particulate matter: shifted state demographic index times the state environmental percentile on a 0 to 100 scale. Tech doc p. 36, p. 33, and pp. 41 to 43.';
COMMENT ON COLUMN marts.block_group_score.p_d2_dslpm IS 'National percentile of the EJ index for Diesel particulate matter. Tech doc pp. 36 to 42.';
COMMENT ON COLUMN marts.block_group_score.st_p_d2_dslpm IS 'State percentile of the state EJ index for Diesel particulate matter. Tech doc pp. 41 to 43.';
COMMENT ON COLUMN marts.block_group_score.d5_dslpm IS 'National supplemental index for Diesel particulate matter: shifted demographic index times the national environmental percentile on a 0 to 100 scale. Tech doc p. 38 and p. 19.';
COMMENT ON COLUMN marts.block_group_score.st_d5_dslpm IS 'State supplemental index for Diesel particulate matter: shifted state demographic index times the state environmental percentile on a 0 to 100 scale. Tech doc p. 38, p. 33, and pp. 41 to 43.';
COMMENT ON COLUMN marts.block_group_score.p_d5_dslpm IS 'National percentile of the supplemental index for Diesel particulate matter. Tech doc pp. 36 to 42.';
COMMENT ON COLUMN marts.block_group_score.st_p_d5_dslpm IS 'State percentile of the state supplemental index for Diesel particulate matter. Tech doc pp. 41 to 43.';
COMMENT ON COLUMN marts.block_group_score.p_rsei_air IS 'National percentile of Toxic releases to air. Tech doc pp. 19 to 20 and pp. 40 to 42.';
COMMENT ON COLUMN marts.block_group_score.st_p_rsei_air IS 'State percentile of Toxic releases to air. Tech doc pp. 19 to 20 and pp. 41 to 42.';
COMMENT ON COLUMN marts.block_group_score.d2_rsei_air IS 'National EJ index for Toxic releases to air: shifted demographic index times the national environmental percentile on a 0 to 100 scale. Tech doc p. 36 and pp. 19 to 20.';
COMMENT ON COLUMN marts.block_group_score.st_d2_rsei_air IS 'State EJ index for Toxic releases to air: shifted state demographic index times the state environmental percentile on a 0 to 100 scale. Tech doc p. 36, p. 33, and pp. 41 to 43.';
COMMENT ON COLUMN marts.block_group_score.p_d2_rsei_air IS 'National percentile of the EJ index for Toxic releases to air. Tech doc pp. 36 to 42.';
COMMENT ON COLUMN marts.block_group_score.st_p_d2_rsei_air IS 'State percentile of the state EJ index for Toxic releases to air. Tech doc pp. 41 to 43.';
COMMENT ON COLUMN marts.block_group_score.d5_rsei_air IS 'National supplemental index for Toxic releases to air: shifted demographic index times the national environmental percentile on a 0 to 100 scale. Tech doc p. 38 and pp. 19 to 20.';
COMMENT ON COLUMN marts.block_group_score.st_d5_rsei_air IS 'State supplemental index for Toxic releases to air: shifted state demographic index times the state environmental percentile on a 0 to 100 scale. Tech doc p. 38, p. 33, and pp. 41 to 43.';
COMMENT ON COLUMN marts.block_group_score.p_d5_rsei_air IS 'National percentile of the supplemental index for Toxic releases to air. Tech doc pp. 36 to 42.';
COMMENT ON COLUMN marts.block_group_score.st_p_d5_rsei_air IS 'State percentile of the state supplemental index for Toxic releases to air. Tech doc pp. 41 to 43.';
COMMENT ON COLUMN marts.block_group_score.p_ptraf IS 'National percentile of Traffic proximity and volume. Tech doc pp. 21 to 22 and pp. 40 to 42.';
COMMENT ON COLUMN marts.block_group_score.st_p_ptraf IS 'State percentile of Traffic proximity and volume. Tech doc pp. 21 to 22 and pp. 41 to 42.';
COMMENT ON COLUMN marts.block_group_score.d2_ptraf IS 'National EJ index for Traffic proximity and volume: shifted demographic index times the national environmental percentile on a 0 to 100 scale. Tech doc p. 36 and pp. 21 to 22.';
COMMENT ON COLUMN marts.block_group_score.st_d2_ptraf IS 'State EJ index for Traffic proximity and volume: shifted state demographic index times the state environmental percentile on a 0 to 100 scale. Tech doc p. 36, p. 33, and pp. 41 to 43.';
COMMENT ON COLUMN marts.block_group_score.p_d2_ptraf IS 'National percentile of the EJ index for Traffic proximity and volume. Tech doc pp. 36 to 42.';
COMMENT ON COLUMN marts.block_group_score.st_p_d2_ptraf IS 'State percentile of the state EJ index for Traffic proximity and volume. Tech doc pp. 41 to 43.';
COMMENT ON COLUMN marts.block_group_score.d5_ptraf IS 'National supplemental index for Traffic proximity and volume: shifted demographic index times the national environmental percentile on a 0 to 100 scale. Tech doc p. 38 and pp. 21 to 22.';
COMMENT ON COLUMN marts.block_group_score.st_d5_ptraf IS 'State supplemental index for Traffic proximity and volume: shifted state demographic index times the state environmental percentile on a 0 to 100 scale. Tech doc p. 38, p. 33, and pp. 41 to 43.';
COMMENT ON COLUMN marts.block_group_score.p_d5_ptraf IS 'National percentile of the supplemental index for Traffic proximity and volume. Tech doc pp. 36 to 42.';
COMMENT ON COLUMN marts.block_group_score.st_p_d5_ptraf IS 'State percentile of the state supplemental index for Traffic proximity and volume. Tech doc pp. 41 to 43.';
COMMENT ON COLUMN marts.block_group_score.p_ldpnt IS 'National percentile of Lead paint. Tech doc pp. 22 to 23 and pp. 40 to 42.';
COMMENT ON COLUMN marts.block_group_score.st_p_ldpnt IS 'State percentile of Lead paint. Tech doc pp. 22 to 23 and pp. 41 to 42.';
COMMENT ON COLUMN marts.block_group_score.d2_ldpnt IS 'National EJ index for Lead paint: shifted demographic index times the national environmental percentile on a 0 to 100 scale. Tech doc p. 36 and pp. 22 to 23.';
COMMENT ON COLUMN marts.block_group_score.st_d2_ldpnt IS 'State EJ index for Lead paint: shifted state demographic index times the state environmental percentile on a 0 to 100 scale. Tech doc p. 36, p. 33, and pp. 41 to 43.';
COMMENT ON COLUMN marts.block_group_score.p_d2_ldpnt IS 'National percentile of the EJ index for Lead paint. Tech doc pp. 36 to 42.';
COMMENT ON COLUMN marts.block_group_score.st_p_d2_ldpnt IS 'State percentile of the state EJ index for Lead paint. Tech doc pp. 41 to 43.';
COMMENT ON COLUMN marts.block_group_score.d5_ldpnt IS 'National supplemental index for Lead paint: shifted demographic index times the national environmental percentile on a 0 to 100 scale. Tech doc p. 38 and pp. 22 to 23.';
COMMENT ON COLUMN marts.block_group_score.st_d5_ldpnt IS 'State supplemental index for Lead paint: shifted state demographic index times the state environmental percentile on a 0 to 100 scale. Tech doc p. 38, p. 33, and pp. 41 to 43.';
COMMENT ON COLUMN marts.block_group_score.p_d5_ldpnt IS 'National percentile of the supplemental index for Lead paint. Tech doc pp. 36 to 42.';
COMMENT ON COLUMN marts.block_group_score.st_p_d5_ldpnt IS 'State percentile of the state supplemental index for Lead paint. Tech doc pp. 41 to 43.';
COMMENT ON COLUMN marts.block_group_score.p_pnpl IS 'National percentile of Superfund proximity. Tech doc p. 23 and pp. 40 to 42.';
COMMENT ON COLUMN marts.block_group_score.st_p_pnpl IS 'State percentile of Superfund proximity. Tech doc p. 23 and pp. 41 to 42.';
COMMENT ON COLUMN marts.block_group_score.d2_pnpl IS 'National EJ index for Superfund proximity: shifted demographic index times the national environmental percentile on a 0 to 100 scale. Tech doc p. 36 and p. 23.';
COMMENT ON COLUMN marts.block_group_score.st_d2_pnpl IS 'State EJ index for Superfund proximity: shifted state demographic index times the state environmental percentile on a 0 to 100 scale. Tech doc p. 36, p. 33, and pp. 41 to 43.';
COMMENT ON COLUMN marts.block_group_score.p_d2_pnpl IS 'National percentile of the EJ index for Superfund proximity. Tech doc pp. 36 to 42.';
COMMENT ON COLUMN marts.block_group_score.st_p_d2_pnpl IS 'State percentile of the state EJ index for Superfund proximity. Tech doc pp. 41 to 43.';
COMMENT ON COLUMN marts.block_group_score.d5_pnpl IS 'National supplemental index for Superfund proximity: shifted demographic index times the national environmental percentile on a 0 to 100 scale. Tech doc p. 38 and p. 23.';
COMMENT ON COLUMN marts.block_group_score.st_d5_pnpl IS 'State supplemental index for Superfund proximity: shifted state demographic index times the state environmental percentile on a 0 to 100 scale. Tech doc p. 38, p. 33, and pp. 41 to 43.';
COMMENT ON COLUMN marts.block_group_score.p_d5_pnpl IS 'National percentile of the supplemental index for Superfund proximity. Tech doc pp. 36 to 42.';
COMMENT ON COLUMN marts.block_group_score.st_p_d5_pnpl IS 'State percentile of the state supplemental index for Superfund proximity. Tech doc pp. 41 to 43.';
COMMENT ON COLUMN marts.block_group_score.p_prmp IS 'National percentile of RMP facility proximity. Tech doc p. 24 and pp. 40 to 42.';
COMMENT ON COLUMN marts.block_group_score.st_p_prmp IS 'State percentile of RMP facility proximity. Tech doc p. 24 and pp. 41 to 42.';
COMMENT ON COLUMN marts.block_group_score.d2_prmp IS 'National EJ index for RMP facility proximity: shifted demographic index times the national environmental percentile on a 0 to 100 scale. Tech doc p. 36 and p. 24.';
COMMENT ON COLUMN marts.block_group_score.st_d2_prmp IS 'State EJ index for RMP facility proximity: shifted state demographic index times the state environmental percentile on a 0 to 100 scale. Tech doc p. 36, p. 33, and pp. 41 to 43.';
COMMENT ON COLUMN marts.block_group_score.p_d2_prmp IS 'National percentile of the EJ index for RMP facility proximity. Tech doc pp. 36 to 42.';
COMMENT ON COLUMN marts.block_group_score.st_p_d2_prmp IS 'State percentile of the state EJ index for RMP facility proximity. Tech doc pp. 41 to 43.';
COMMENT ON COLUMN marts.block_group_score.d5_prmp IS 'National supplemental index for RMP facility proximity: shifted demographic index times the national environmental percentile on a 0 to 100 scale. Tech doc p. 38 and p. 24.';
COMMENT ON COLUMN marts.block_group_score.st_d5_prmp IS 'State supplemental index for RMP facility proximity: shifted state demographic index times the state environmental percentile on a 0 to 100 scale. Tech doc p. 38, p. 33, and pp. 41 to 43.';
COMMENT ON COLUMN marts.block_group_score.p_d5_prmp IS 'National percentile of the supplemental index for RMP facility proximity. Tech doc pp. 36 to 42.';
COMMENT ON COLUMN marts.block_group_score.st_p_d5_prmp IS 'State percentile of the state supplemental index for RMP facility proximity. Tech doc pp. 41 to 43.';
COMMENT ON COLUMN marts.block_group_score.p_ptsdf IS 'National percentile of Hazardous waste proximity. Tech doc pp. 24 to 25 and pp. 40 to 42.';
COMMENT ON COLUMN marts.block_group_score.st_p_ptsdf IS 'State percentile of Hazardous waste proximity. Tech doc pp. 24 to 25 and pp. 41 to 42.';
COMMENT ON COLUMN marts.block_group_score.d2_ptsdf IS 'National EJ index for Hazardous waste proximity: shifted demographic index times the national environmental percentile on a 0 to 100 scale. Tech doc p. 36 and pp. 24 to 25.';
COMMENT ON COLUMN marts.block_group_score.st_d2_ptsdf IS 'State EJ index for Hazardous waste proximity: shifted state demographic index times the state environmental percentile on a 0 to 100 scale. Tech doc p. 36, p. 33, and pp. 41 to 43.';
COMMENT ON COLUMN marts.block_group_score.p_d2_ptsdf IS 'National percentile of the EJ index for Hazardous waste proximity. Tech doc pp. 36 to 42.';
COMMENT ON COLUMN marts.block_group_score.st_p_d2_ptsdf IS 'State percentile of the state EJ index for Hazardous waste proximity. Tech doc pp. 41 to 43.';
COMMENT ON COLUMN marts.block_group_score.d5_ptsdf IS 'National supplemental index for Hazardous waste proximity: shifted demographic index times the national environmental percentile on a 0 to 100 scale. Tech doc p. 38 and pp. 24 to 25.';
COMMENT ON COLUMN marts.block_group_score.st_d5_ptsdf IS 'State supplemental index for Hazardous waste proximity: shifted state demographic index times the state environmental percentile on a 0 to 100 scale. Tech doc p. 38, p. 33, and pp. 41 to 43.';
COMMENT ON COLUMN marts.block_group_score.p_d5_ptsdf IS 'National percentile of the supplemental index for Hazardous waste proximity. Tech doc pp. 36 to 42.';
COMMENT ON COLUMN marts.block_group_score.st_p_d5_ptsdf IS 'State percentile of the state supplemental index for Hazardous waste proximity. Tech doc pp. 41 to 43.';
COMMENT ON COLUMN marts.block_group_score.p_ust IS 'National percentile of Underground storage tanks. Tech doc pp. 25 to 26 and pp. 40 to 42.';
COMMENT ON COLUMN marts.block_group_score.st_p_ust IS 'State percentile of Underground storage tanks. Tech doc pp. 25 to 26 and pp. 41 to 42.';
COMMENT ON COLUMN marts.block_group_score.d2_ust IS 'National EJ index for Underground storage tanks: shifted demographic index times the national environmental percentile on a 0 to 100 scale. Tech doc p. 36 and pp. 25 to 26.';
COMMENT ON COLUMN marts.block_group_score.st_d2_ust IS 'State EJ index for Underground storage tanks: shifted state demographic index times the state environmental percentile on a 0 to 100 scale. Tech doc p. 36, p. 33, and pp. 41 to 43.';
COMMENT ON COLUMN marts.block_group_score.p_d2_ust IS 'National percentile of the EJ index for Underground storage tanks. Tech doc pp. 36 to 42.';
COMMENT ON COLUMN marts.block_group_score.st_p_d2_ust IS 'State percentile of the state EJ index for Underground storage tanks. Tech doc pp. 41 to 43.';
COMMENT ON COLUMN marts.block_group_score.d5_ust IS 'National supplemental index for Underground storage tanks: shifted demographic index times the national environmental percentile on a 0 to 100 scale. Tech doc p. 38 and pp. 25 to 26.';
COMMENT ON COLUMN marts.block_group_score.st_d5_ust IS 'State supplemental index for Underground storage tanks: shifted state demographic index times the state environmental percentile on a 0 to 100 scale. Tech doc p. 38, p. 33, and pp. 41 to 43.';
COMMENT ON COLUMN marts.block_group_score.p_d5_ust IS 'National percentile of the supplemental index for Underground storage tanks. Tech doc pp. 36 to 42.';
COMMENT ON COLUMN marts.block_group_score.st_p_d5_ust IS 'State percentile of the state supplemental index for Underground storage tanks. Tech doc pp. 41 to 43.';
COMMENT ON COLUMN marts.block_group_score.p_pwdis IS 'National percentile of Wastewater discharge. Tech doc pp. 26 to 27 and pp. 40 to 42.';
COMMENT ON COLUMN marts.block_group_score.st_p_pwdis IS 'State percentile of Wastewater discharge. Tech doc pp. 26 to 27 and pp. 41 to 42.';
COMMENT ON COLUMN marts.block_group_score.d2_pwdis IS 'National EJ index for Wastewater discharge: shifted demographic index times the national environmental percentile on a 0 to 100 scale. Tech doc p. 36 and pp. 26 to 27.';
COMMENT ON COLUMN marts.block_group_score.st_d2_pwdis IS 'State EJ index for Wastewater discharge: shifted state demographic index times the state environmental percentile on a 0 to 100 scale. Tech doc p. 36, p. 33, and pp. 41 to 43.';
COMMENT ON COLUMN marts.block_group_score.p_d2_pwdis IS 'National percentile of the EJ index for Wastewater discharge. Tech doc pp. 36 to 42.';
COMMENT ON COLUMN marts.block_group_score.st_p_d2_pwdis IS 'State percentile of the state EJ index for Wastewater discharge. Tech doc pp. 41 to 43.';
COMMENT ON COLUMN marts.block_group_score.d5_pwdis IS 'National supplemental index for Wastewater discharge: shifted demographic index times the national environmental percentile on a 0 to 100 scale. Tech doc p. 38 and pp. 26 to 27.';
COMMENT ON COLUMN marts.block_group_score.st_d5_pwdis IS 'State supplemental index for Wastewater discharge: shifted state demographic index times the state environmental percentile on a 0 to 100 scale. Tech doc p. 38, p. 33, and pp. 41 to 43.';
COMMENT ON COLUMN marts.block_group_score.p_d5_pwdis IS 'National percentile of the supplemental index for Wastewater discharge. Tech doc pp. 36 to 42.';
COMMENT ON COLUMN marts.block_group_score.st_p_d5_pwdis IS 'State percentile of the state supplemental index for Wastewater discharge. Tech doc pp. 41 to 43.';
COMMENT ON COLUMN marts.block_group_score.p_no2 IS 'National percentile of Nitrogen dioxide. Tech doc pp. 18 to 19 and pp. 40 to 42.';
COMMENT ON COLUMN marts.block_group_score.st_p_no2 IS 'State percentile of Nitrogen dioxide. Tech doc pp. 18 to 19 and pp. 41 to 42.';
COMMENT ON COLUMN marts.block_group_score.d2_no2 IS 'National EJ index for Nitrogen dioxide: shifted demographic index times the national environmental percentile on a 0 to 100 scale. Tech doc p. 36 and pp. 18 to 19.';
COMMENT ON COLUMN marts.block_group_score.st_d2_no2 IS 'State EJ index for Nitrogen dioxide: shifted state demographic index times the state environmental percentile on a 0 to 100 scale. Tech doc p. 36, p. 33, and pp. 41 to 43.';
COMMENT ON COLUMN marts.block_group_score.p_d2_no2 IS 'National percentile of the EJ index for Nitrogen dioxide. Tech doc pp. 36 to 42.';
COMMENT ON COLUMN marts.block_group_score.st_p_d2_no2 IS 'State percentile of the state EJ index for Nitrogen dioxide. Tech doc pp. 41 to 43.';
COMMENT ON COLUMN marts.block_group_score.d5_no2 IS 'National supplemental index for Nitrogen dioxide: shifted demographic index times the national environmental percentile on a 0 to 100 scale. Tech doc p. 38 and pp. 18 to 19.';
COMMENT ON COLUMN marts.block_group_score.st_d5_no2 IS 'State supplemental index for Nitrogen dioxide: shifted state demographic index times the state environmental percentile on a 0 to 100 scale. Tech doc p. 38, p. 33, and pp. 41 to 43.';
COMMENT ON COLUMN marts.block_group_score.p_d5_no2 IS 'National percentile of the supplemental index for Nitrogen dioxide. Tech doc pp. 36 to 42.';
COMMENT ON COLUMN marts.block_group_score.st_p_d5_no2 IS 'State percentile of the state supplemental index for Nitrogen dioxide. Tech doc pp. 41 to 43.';
COMMENT ON COLUMN marts.block_group_score.p_dwater IS 'National percentile of Drinking water non-compliance. Tech doc pp. 27 to 29 and pp. 40 to 42.';
COMMENT ON COLUMN marts.block_group_score.st_p_dwater IS 'State percentile of Drinking water non-compliance. Tech doc pp. 27 to 29 and pp. 41 to 42.';
COMMENT ON COLUMN marts.block_group_score.d2_dwater IS 'National EJ index for Drinking water non-compliance: shifted demographic index times the national environmental percentile on a 0 to 100 scale. Tech doc p. 36 and pp. 27 to 29.';
COMMENT ON COLUMN marts.block_group_score.st_d2_dwater IS 'State EJ index for Drinking water non-compliance: shifted state demographic index times the state environmental percentile on a 0 to 100 scale. Tech doc p. 36, p. 33, and pp. 41 to 43.';
COMMENT ON COLUMN marts.block_group_score.p_d2_dwater IS 'National percentile of the EJ index for Drinking water non-compliance. Tech doc pp. 36 to 42.';
COMMENT ON COLUMN marts.block_group_score.st_p_d2_dwater IS 'State percentile of the state EJ index for Drinking water non-compliance. Tech doc pp. 41 to 43.';
COMMENT ON COLUMN marts.block_group_score.d5_dwater IS 'National supplemental index for Drinking water non-compliance: shifted demographic index times the national environmental percentile on a 0 to 100 scale. Tech doc p. 38 and pp. 27 to 29.';
COMMENT ON COLUMN marts.block_group_score.st_d5_dwater IS 'State supplemental index for Drinking water non-compliance: shifted state demographic index times the state environmental percentile on a 0 to 100 scale. Tech doc p. 38, p. 33, and pp. 41 to 43.';
COMMENT ON COLUMN marts.block_group_score.p_d5_dwater IS 'National percentile of the supplemental index for Drinking water non-compliance. Tech doc pp. 36 to 42.';
COMMENT ON COLUMN marts.block_group_score.st_p_d5_dwater IS 'State percentile of the state supplemental index for Drinking water non-compliance. Tech doc pp. 41 to 43.';
COMMENT ON TABLE marts.demographic_index IS 'Shifted and unshifted demographic indexes. National formulas are tech doc pp. 32 to 39. State formulas use the same steps inside each state, p. 33 and p. 35.';
COMMENT ON COLUMN marts.demographic_index.geoid IS '12 character id joining to staging.block_group_inputs.';
COMMENT ON COLUMN marts.demographic_index.demogidx_2_unshifted IS 'Average of the national low income and people of color z scores, before the shift. Tech doc p. 32 and p. 36.';
COMMENT ON COLUMN marts.demographic_index.demogidx_2 IS 'Demographic Index after adding the absolute value of the smallest national unshifted index. Tech doc p. 33 and pp. 36 to 37.';
COMMENT ON COLUMN marts.demographic_index.demogidx_5_unshifted IS 'Average of five national z scores, or four when low life expectancy is missing, before the shift. Tech doc p. 35.';
COMMENT ON COLUMN marts.demographic_index.demogidx_5 IS 'Supplemental Demographic Index after the national shift. Tech doc p. 35 and pp. 38 to 39.';
COMMENT ON COLUMN marts.demographic_index.demogidx_2st_unshifted IS 'Unshifted state Demographic Index. Tech doc p. 33.';
COMMENT ON COLUMN marts.demographic_index.demogidx_2st IS 'State Demographic Index after the state shift. Tech doc p. 33.';
COMMENT ON COLUMN marts.demographic_index.demogidx_5st_unshifted IS 'Unshifted state Supplemental Demographic Index. Tech doc p. 35.';
COMMENT ON COLUMN marts.demographic_index.demogidx_5st IS 'State Supplemental Demographic Index after the state shift. Tech doc p. 35.';
COMMENT ON TABLE marts.moment_us IS 'Unweighted national mean and sample standard deviation of the demographic inputs. Tech doc pp. 31 to 33 and p. 41. The four island territories are excluded.';
COMMENT ON TABLE marts.moment_state IS 'Unweighted state mean and sample standard deviation of the demographic inputs. Tech doc p. 33, p. 35, and p. 41.';
COMMENT ON TABLE marts.rebuilt IS 'Long rebuilt values aligned to published column names. scope national_file is compared with raw.ejscreen_reference. scope state_file is compared with raw.ejscreen_reference_state_pct.';
COMMENT ON TABLE marts.raw_percentile IS 'Cutoff percentiles for published indicator inputs. National percentiles exclude the four island territories. Tech doc pp. 40 to 42 and p. 53.';
COMMENT ON TABLE marts.ranked_value IS 'Values that enter each percentile denominator. The percent rank view reads this table.';
COMMENT ON VIEW marts.indicator_percent_rank IS 'PostgreSQL percent_rank() times 100 for the same values used by the cutoff percentiles. Comparison only. The primary percentile is marts.assign_percentile, tech doc pp. 40 to 42.';
COMMENT ON COLUMN marts.moment_us.measure_code IS 'Published indicator column used in a demographic z score.';
COMMENT ON COLUMN marts.moment_us.n IS 'Count of non null block groups in the moment.';
COMMENT ON COLUMN marts.moment_us.mu IS 'Unweighted mean. Tech doc p. 41.';
COMMENT ON COLUMN marts.moment_us.sigma IS 'Sample standard deviation, divisor n - 1. See assumptions.';
COMMENT ON COLUMN marts.moment_state.state_abbrev IS 'State, District of Columbia, Puerto Rico, or island territory.';
COMMENT ON COLUMN marts.moment_state.measure_code IS 'Published indicator column used in a demographic z score.';
COMMENT ON COLUMN marts.moment_state.n IS 'Count of non null block groups in the moment.';
COMMENT ON COLUMN marts.moment_state.mu IS 'Unweighted mean. Tech doc p. 41.';
COMMENT ON COLUMN marts.moment_state.sigma IS 'Sample standard deviation, divisor n - 1. See assumptions.';
COMMENT ON COLUMN marts.rebuilt.scope IS 'national_file or state_file, matching the two Harvard extracts.';
COMMENT ON COLUMN marts.rebuilt.column_name IS 'Published column name in the Harvard extract.';
COMMENT ON COLUMN marts.rebuilt.kind IS 'continuous for an index value, percentile for an integer percentile.';
COMMENT ON COLUMN marts.rebuilt.geoid IS '12 character id.';
COMMENT ON COLUMN marts.rebuilt.value IS 'Rebuilt number. Null where an input is null or the tech doc excludes the row.';
COMMENT ON COLUMN marts.raw_percentile.group_key IS 'Published percentile column this cutoff belongs to.';
COMMENT ON COLUMN marts.raw_percentile.geoid IS '12 character id.';
COMMENT ON COLUMN marts.raw_percentile.state_abbrev IS 'State, District of Columbia, Puerto Rico, or island territory.';
COMMENT ON COLUMN marts.raw_percentile.in_national_universe IS 'True for the 50 states, the District of Columbia, and Puerto Rico.';
COMMENT ON COLUMN marts.raw_percentile.value IS 'Rebuilt number. Null where an input is null or the tech doc excludes the row.';
COMMENT ON COLUMN marts.raw_percentile.us_percentile IS 'National cutoff percentile, null for the four island territories. Tech doc p. 53.';
COMMENT ON COLUMN marts.raw_percentile.state_percentile IS 'State cutoff percentile. Tech doc pp. 41 to 42.';
COMMENT ON COLUMN marts.ranked_value.scope IS 'national_file or state_file, matching the two Harvard extracts.';
COMMENT ON COLUMN marts.ranked_value.percentile_column IS 'Published percentile column whose denominator this value belongs to.';
COMMENT ON COLUMN marts.ranked_value.geoid IS '12 character id.';
COMMENT ON COLUMN marts.ranked_value.value IS 'Rebuilt number. Null where an input is null or the tech doc excludes the row.';
COMMENT ON COLUMN marts.indicator_percent_rank.scope IS 'national_file or state_file.';
COMMENT ON COLUMN marts.indicator_percent_rank.percentile_column IS 'Published percentile column being compared.';
COMMENT ON COLUMN marts.indicator_percent_rank.geoid IS '12 character id.';
COMMENT ON COLUMN marts.indicator_percent_rank.value IS 'Indicator or index value that was ranked.';
COMMENT ON COLUMN marts.indicator_percent_rank.percent_rank_0_100 IS 'percent_rank() times 100. Ties share the minimum rank. Not the tech doc cutoff percentile.';

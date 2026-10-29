DO $assert$
DECLARE
  bad bigint;
BEGIN
  IF (SELECT count(*) FROM raw.ejscreen_reference) <> (SELECT count(*) FROM staging.block_group_inputs) THEN
    RAISE EXCEPTION 'Staging row count does not match raw.ejscreen_reference';
  END IF;
  IF (SELECT count(*) FROM raw.ejscreen_reference_state_pct) <> (SELECT count(*) FROM staging.block_group_inputs) THEN
    RAISE EXCEPTION 'State extract row count does not match staging';
  END IF;
  IF (SELECT count(*) FROM (SELECT source_id FROM staging.block_group_inputs GROUP BY 1 HAVING count(*) > 1) d) > 0 THEN
    RAISE EXCEPTION 'Duplicate source id in staging';
  END IF;
  SELECT count(*) INTO bad FROM staging.block_group_inputs WHERE geoid !~ '^[0-9]{12}$';
  IF bad > 0 THEN
    RAISE EXCEPTION 'geoid is not 12 digits on % rows', bad;
  END IF;
  SELECT count(*) INTO bad FROM staging.block_group_inputs WHERE population < 0;
  IF bad > 0 THEN
    RAISE EXCEPTION 'Negative population on % rows', bad;
  END IF;
  SELECT count(*) INTO bad
  FROM staging.block_group_inputs
  WHERE in_national_universe
    AND (population IS NULL OR pct_low_income IS NULL OR pct_people_of_color IS NULL
         OR pct_disability IS NULL OR pct_limited_english IS NULL OR pct_less_than_hs IS NULL);
  IF bad > 0 THEN
    RAISE EXCEPTION 'Unexpected null demographic input or population in the national universe on % rows', bad;
  END IF;
  SELECT count(*) INTO bad FROM marts.rebuilt
  WHERE kind = 'percentile' AND value IS NOT NULL
    AND (value < 0 OR value > 100 OR value <> trunc(value));
  IF bad > 0 THEN
    RAISE EXCEPTION 'Percentile outside 0 to 100 or not a whole number on % rows', bad;
  END IF;
  SELECT count(*) INTO bad FROM marts.raw_percentile
  WHERE ((in_national_universe AND (value IS NULL) IS DISTINCT FROM (us_percentile IS NULL))
      OR ((NOT in_national_universe) AND us_percentile IS NOT NULL)
      OR ((value IS NULL) IS DISTINCT FROM (state_percentile IS NULL)));
  IF bad > 0 THEN
    RAISE EXCEPTION 'Raw percentile null pattern does not follow the indicator value on % rows', bad;
  END IF;
  SELECT count(*) INTO bad FROM marts.rebuilt r
  JOIN staging.block_group_inputs s ON s.geoid = r.geoid
  WHERE r.scope = 'national_file' AND r.kind = 'percentile'
    AND NOT s.in_national_universe AND r.value IS NOT NULL;
  IF bad > 0 THEN
    RAISE EXCEPTION 'National percentile is present for a territory row on % cells', bad;
  END IF;
  IF (SELECT min(demogidx_2) FROM marts.demographic_index) <> 0
     OR (SELECT min(demogidx_5) FROM marts.demographic_index) <> 0
     OR (SELECT bool_or(demogidx_2 < 0) OR bool_or(demogidx_5 < 0) FROM marts.demographic_index) THEN
    RAISE EXCEPTION 'National shifted demographic index is not non-negative with minimum 0';
  END IF;
  IF EXISTS (
    SELECT 1
    FROM marts.demographic_index d
    JOIN staging.block_group_inputs s ON s.geoid = d.geoid
    WHERE d.demogidx_2st IS NOT NULL
    GROUP BY s.state_abbrev
    HAVING min(d.demogidx_2st) <> 0 OR bool_or(d.demogidx_2st < 0)
        OR min(d.demogidx_5st) <> 0 OR bool_or(d.demogidx_5st < 0)
  ) THEN
    RAISE EXCEPTION 'A state shifted demographic index is negative or its minimum is not 0';
  END IF;
  SELECT count(*) INTO bad FROM (
  SELECT 1 FROM marts.rebuilt e
  JOIN marts.demographic_index d ON d.geoid = e.geoid
  JOIN marts.raw_percentile p ON p.geoid = e.geoid AND p.group_key = 'P_PM25'
  WHERE e.scope = 'national_file' AND e.column_name = 'D2_PM25'
    AND e.value IS DISTINCT FROM (d.demogidx_2 * p.us_percentile::double precision)
  UNION ALL
  SELECT 1 FROM marts.rebuilt e
  JOIN marts.demographic_index d ON d.geoid = e.geoid
  JOIN marts.raw_percentile p ON p.geoid = e.geoid AND p.group_key = 'P_PM25'
  WHERE e.scope = 'national_file' AND e.column_name = 'D5_PM25'
    AND e.value IS DISTINCT FROM (d.demogidx_5 * p.us_percentile::double precision)
  UNION ALL
  SELECT 1 FROM marts.rebuilt e
  JOIN marts.demographic_index d ON d.geoid = e.geoid
  JOIN marts.raw_percentile p ON p.geoid = e.geoid AND p.group_key = 'P_PM25'
  WHERE e.scope = 'state_file' AND e.column_name = 'D2_PM25'
    AND e.value IS DISTINCT FROM (d.demogidx_2st * p.state_percentile::double precision)
  UNION ALL
  SELECT 1 FROM marts.rebuilt e
  JOIN marts.demographic_index d ON d.geoid = e.geoid
  JOIN marts.raw_percentile p ON p.geoid = e.geoid AND p.group_key = 'P_PM25'
  WHERE e.scope = 'state_file' AND e.column_name = 'D5_PM25'
    AND e.value IS DISTINCT FROM (d.demogidx_5st * p.state_percentile::double precision)
  UNION ALL
  SELECT 1 FROM marts.rebuilt e
  JOIN marts.demographic_index d ON d.geoid = e.geoid
  JOIN marts.raw_percentile p ON p.geoid = e.geoid AND p.group_key = 'P_OZONE'
  WHERE e.scope = 'national_file' AND e.column_name = 'D2_OZONE'
    AND e.value IS DISTINCT FROM (d.demogidx_2 * p.us_percentile::double precision)
  UNION ALL
  SELECT 1 FROM marts.rebuilt e
  JOIN marts.demographic_index d ON d.geoid = e.geoid
  JOIN marts.raw_percentile p ON p.geoid = e.geoid AND p.group_key = 'P_OZONE'
  WHERE e.scope = 'national_file' AND e.column_name = 'D5_OZONE'
    AND e.value IS DISTINCT FROM (d.demogidx_5 * p.us_percentile::double precision)
  UNION ALL
  SELECT 1 FROM marts.rebuilt e
  JOIN marts.demographic_index d ON d.geoid = e.geoid
  JOIN marts.raw_percentile p ON p.geoid = e.geoid AND p.group_key = 'P_OZONE'
  WHERE e.scope = 'state_file' AND e.column_name = 'D2_OZONE'
    AND e.value IS DISTINCT FROM (d.demogidx_2st * p.state_percentile::double precision)
  UNION ALL
  SELECT 1 FROM marts.rebuilt e
  JOIN marts.demographic_index d ON d.geoid = e.geoid
  JOIN marts.raw_percentile p ON p.geoid = e.geoid AND p.group_key = 'P_OZONE'
  WHERE e.scope = 'state_file' AND e.column_name = 'D5_OZONE'
    AND e.value IS DISTINCT FROM (d.demogidx_5st * p.state_percentile::double precision)
  UNION ALL
  SELECT 1 FROM marts.rebuilt e
  JOIN marts.demographic_index d ON d.geoid = e.geoid
  JOIN marts.raw_percentile p ON p.geoid = e.geoid AND p.group_key = 'P_DSLPM'
  WHERE e.scope = 'national_file' AND e.column_name = 'D2_DSLPM'
    AND e.value IS DISTINCT FROM (d.demogidx_2 * p.us_percentile::double precision)
  UNION ALL
  SELECT 1 FROM marts.rebuilt e
  JOIN marts.demographic_index d ON d.geoid = e.geoid
  JOIN marts.raw_percentile p ON p.geoid = e.geoid AND p.group_key = 'P_DSLPM'
  WHERE e.scope = 'national_file' AND e.column_name = 'D5_DSLPM'
    AND e.value IS DISTINCT FROM (d.demogidx_5 * p.us_percentile::double precision)
  UNION ALL
  SELECT 1 FROM marts.rebuilt e
  JOIN marts.demographic_index d ON d.geoid = e.geoid
  JOIN marts.raw_percentile p ON p.geoid = e.geoid AND p.group_key = 'P_DSLPM'
  WHERE e.scope = 'state_file' AND e.column_name = 'D2_DSLPM'
    AND e.value IS DISTINCT FROM (d.demogidx_2st * p.state_percentile::double precision)
  UNION ALL
  SELECT 1 FROM marts.rebuilt e
  JOIN marts.demographic_index d ON d.geoid = e.geoid
  JOIN marts.raw_percentile p ON p.geoid = e.geoid AND p.group_key = 'P_DSLPM'
  WHERE e.scope = 'state_file' AND e.column_name = 'D5_DSLPM'
    AND e.value IS DISTINCT FROM (d.demogidx_5st * p.state_percentile::double precision)
  UNION ALL
  SELECT 1 FROM marts.rebuilt e
  JOIN marts.demographic_index d ON d.geoid = e.geoid
  JOIN marts.raw_percentile p ON p.geoid = e.geoid AND p.group_key = 'P_RSEI_AIR'
  WHERE e.scope = 'national_file' AND e.column_name = 'D2_RSEI_AIR'
    AND e.value IS DISTINCT FROM (d.demogidx_2 * p.us_percentile::double precision)
  UNION ALL
  SELECT 1 FROM marts.rebuilt e
  JOIN marts.demographic_index d ON d.geoid = e.geoid
  JOIN marts.raw_percentile p ON p.geoid = e.geoid AND p.group_key = 'P_RSEI_AIR'
  WHERE e.scope = 'national_file' AND e.column_name = 'D5_RSEI_AIR'
    AND e.value IS DISTINCT FROM (d.demogidx_5 * p.us_percentile::double precision)
  UNION ALL
  SELECT 1 FROM marts.rebuilt e
  JOIN marts.demographic_index d ON d.geoid = e.geoid
  JOIN marts.raw_percentile p ON p.geoid = e.geoid AND p.group_key = 'P_RSEI_AIR'
  WHERE e.scope = 'state_file' AND e.column_name = 'D2_RSEI_AIR'
    AND e.value IS DISTINCT FROM (d.demogidx_2st * p.state_percentile::double precision)
  UNION ALL
  SELECT 1 FROM marts.rebuilt e
  JOIN marts.demographic_index d ON d.geoid = e.geoid
  JOIN marts.raw_percentile p ON p.geoid = e.geoid AND p.group_key = 'P_RSEI_AIR'
  WHERE e.scope = 'state_file' AND e.column_name = 'D5_RSEI_AIR'
    AND e.value IS DISTINCT FROM (d.demogidx_5st * p.state_percentile::double precision)
  UNION ALL
  SELECT 1 FROM marts.rebuilt e
  JOIN marts.demographic_index d ON d.geoid = e.geoid
  JOIN marts.raw_percentile p ON p.geoid = e.geoid AND p.group_key = 'P_PTRAF'
  WHERE e.scope = 'national_file' AND e.column_name = 'D2_PTRAF'
    AND e.value IS DISTINCT FROM (d.demogidx_2 * p.us_percentile::double precision)
  UNION ALL
  SELECT 1 FROM marts.rebuilt e
  JOIN marts.demographic_index d ON d.geoid = e.geoid
  JOIN marts.raw_percentile p ON p.geoid = e.geoid AND p.group_key = 'P_PTRAF'
  WHERE e.scope = 'national_file' AND e.column_name = 'D5_PTRAF'
    AND e.value IS DISTINCT FROM (d.demogidx_5 * p.us_percentile::double precision)
  UNION ALL
  SELECT 1 FROM marts.rebuilt e
  JOIN marts.demographic_index d ON d.geoid = e.geoid
  JOIN marts.raw_percentile p ON p.geoid = e.geoid AND p.group_key = 'P_PTRAF'
  WHERE e.scope = 'state_file' AND e.column_name = 'D2_PTRAF'
    AND e.value IS DISTINCT FROM (d.demogidx_2st * p.state_percentile::double precision)
  UNION ALL
  SELECT 1 FROM marts.rebuilt e
  JOIN marts.demographic_index d ON d.geoid = e.geoid
  JOIN marts.raw_percentile p ON p.geoid = e.geoid AND p.group_key = 'P_PTRAF'
  WHERE e.scope = 'state_file' AND e.column_name = 'D5_PTRAF'
    AND e.value IS DISTINCT FROM (d.demogidx_5st * p.state_percentile::double precision)
  UNION ALL
  SELECT 1 FROM marts.rebuilt e
  JOIN marts.demographic_index d ON d.geoid = e.geoid
  JOIN marts.raw_percentile p ON p.geoid = e.geoid AND p.group_key = 'P_LDPNT'
  WHERE e.scope = 'national_file' AND e.column_name = 'D2_LDPNT'
    AND e.value IS DISTINCT FROM (d.demogidx_2 * p.us_percentile::double precision)
  UNION ALL
  SELECT 1 FROM marts.rebuilt e
  JOIN marts.demographic_index d ON d.geoid = e.geoid
  JOIN marts.raw_percentile p ON p.geoid = e.geoid AND p.group_key = 'P_LDPNT'
  WHERE e.scope = 'national_file' AND e.column_name = 'D5_LDPNT'
    AND e.value IS DISTINCT FROM (d.demogidx_5 * p.us_percentile::double precision)
  UNION ALL
  SELECT 1 FROM marts.rebuilt e
  JOIN marts.demographic_index d ON d.geoid = e.geoid
  JOIN marts.raw_percentile p ON p.geoid = e.geoid AND p.group_key = 'P_LDPNT'
  WHERE e.scope = 'state_file' AND e.column_name = 'D2_LDPNT'
    AND e.value IS DISTINCT FROM (d.demogidx_2st * p.state_percentile::double precision)
  UNION ALL
  SELECT 1 FROM marts.rebuilt e
  JOIN marts.demographic_index d ON d.geoid = e.geoid
  JOIN marts.raw_percentile p ON p.geoid = e.geoid AND p.group_key = 'P_LDPNT'
  WHERE e.scope = 'state_file' AND e.column_name = 'D5_LDPNT'
    AND e.value IS DISTINCT FROM (d.demogidx_5st * p.state_percentile::double precision)
  UNION ALL
  SELECT 1 FROM marts.rebuilt e
  JOIN marts.demographic_index d ON d.geoid = e.geoid
  JOIN marts.raw_percentile p ON p.geoid = e.geoid AND p.group_key = 'P_PNPL'
  WHERE e.scope = 'national_file' AND e.column_name = 'D2_PNPL'
    AND e.value IS DISTINCT FROM (d.demogidx_2 * p.us_percentile::double precision)
  UNION ALL
  SELECT 1 FROM marts.rebuilt e
  JOIN marts.demographic_index d ON d.geoid = e.geoid
  JOIN marts.raw_percentile p ON p.geoid = e.geoid AND p.group_key = 'P_PNPL'
  WHERE e.scope = 'national_file' AND e.column_name = 'D5_PNPL'
    AND e.value IS DISTINCT FROM (d.demogidx_5 * p.us_percentile::double precision)
  UNION ALL
  SELECT 1 FROM marts.rebuilt e
  JOIN marts.demographic_index d ON d.geoid = e.geoid
  JOIN marts.raw_percentile p ON p.geoid = e.geoid AND p.group_key = 'P_PNPL'
  WHERE e.scope = 'state_file' AND e.column_name = 'D2_PNPL'
    AND e.value IS DISTINCT FROM (d.demogidx_2st * p.state_percentile::double precision)
  UNION ALL
  SELECT 1 FROM marts.rebuilt e
  JOIN marts.demographic_index d ON d.geoid = e.geoid
  JOIN marts.raw_percentile p ON p.geoid = e.geoid AND p.group_key = 'P_PNPL'
  WHERE e.scope = 'state_file' AND e.column_name = 'D5_PNPL'
    AND e.value IS DISTINCT FROM (d.demogidx_5st * p.state_percentile::double precision)
  UNION ALL
  SELECT 1 FROM marts.rebuilt e
  JOIN marts.demographic_index d ON d.geoid = e.geoid
  JOIN marts.raw_percentile p ON p.geoid = e.geoid AND p.group_key = 'P_PRMP'
  WHERE e.scope = 'national_file' AND e.column_name = 'D2_PRMP'
    AND e.value IS DISTINCT FROM (d.demogidx_2 * p.us_percentile::double precision)
  UNION ALL
  SELECT 1 FROM marts.rebuilt e
  JOIN marts.demographic_index d ON d.geoid = e.geoid
  JOIN marts.raw_percentile p ON p.geoid = e.geoid AND p.group_key = 'P_PRMP'
  WHERE e.scope = 'national_file' AND e.column_name = 'D5_PRMP'
    AND e.value IS DISTINCT FROM (d.demogidx_5 * p.us_percentile::double precision)
  UNION ALL
  SELECT 1 FROM marts.rebuilt e
  JOIN marts.demographic_index d ON d.geoid = e.geoid
  JOIN marts.raw_percentile p ON p.geoid = e.geoid AND p.group_key = 'P_PRMP'
  WHERE e.scope = 'state_file' AND e.column_name = 'D2_PRMP'
    AND e.value IS DISTINCT FROM (d.demogidx_2st * p.state_percentile::double precision)
  UNION ALL
  SELECT 1 FROM marts.rebuilt e
  JOIN marts.demographic_index d ON d.geoid = e.geoid
  JOIN marts.raw_percentile p ON p.geoid = e.geoid AND p.group_key = 'P_PRMP'
  WHERE e.scope = 'state_file' AND e.column_name = 'D5_PRMP'
    AND e.value IS DISTINCT FROM (d.demogidx_5st * p.state_percentile::double precision)
  UNION ALL
  SELECT 1 FROM marts.rebuilt e
  JOIN marts.demographic_index d ON d.geoid = e.geoid
  JOIN marts.raw_percentile p ON p.geoid = e.geoid AND p.group_key = 'P_PTSDF'
  WHERE e.scope = 'national_file' AND e.column_name = 'D2_PTSDF'
    AND e.value IS DISTINCT FROM (d.demogidx_2 * p.us_percentile::double precision)
  UNION ALL
  SELECT 1 FROM marts.rebuilt e
  JOIN marts.demographic_index d ON d.geoid = e.geoid
  JOIN marts.raw_percentile p ON p.geoid = e.geoid AND p.group_key = 'P_PTSDF'
  WHERE e.scope = 'national_file' AND e.column_name = 'D5_PTSDF'
    AND e.value IS DISTINCT FROM (d.demogidx_5 * p.us_percentile::double precision)
  UNION ALL
  SELECT 1 FROM marts.rebuilt e
  JOIN marts.demographic_index d ON d.geoid = e.geoid
  JOIN marts.raw_percentile p ON p.geoid = e.geoid AND p.group_key = 'P_PTSDF'
  WHERE e.scope = 'state_file' AND e.column_name = 'D2_PTSDF'
    AND e.value IS DISTINCT FROM (d.demogidx_2st * p.state_percentile::double precision)
  UNION ALL
  SELECT 1 FROM marts.rebuilt e
  JOIN marts.demographic_index d ON d.geoid = e.geoid
  JOIN marts.raw_percentile p ON p.geoid = e.geoid AND p.group_key = 'P_PTSDF'
  WHERE e.scope = 'state_file' AND e.column_name = 'D5_PTSDF'
    AND e.value IS DISTINCT FROM (d.demogidx_5st * p.state_percentile::double precision)
  UNION ALL
  SELECT 1 FROM marts.rebuilt e
  JOIN marts.demographic_index d ON d.geoid = e.geoid
  JOIN marts.raw_percentile p ON p.geoid = e.geoid AND p.group_key = 'P_UST'
  WHERE e.scope = 'national_file' AND e.column_name = 'D2_UST'
    AND e.value IS DISTINCT FROM (d.demogidx_2 * p.us_percentile::double precision)
  UNION ALL
  SELECT 1 FROM marts.rebuilt e
  JOIN marts.demographic_index d ON d.geoid = e.geoid
  JOIN marts.raw_percentile p ON p.geoid = e.geoid AND p.group_key = 'P_UST'
  WHERE e.scope = 'national_file' AND e.column_name = 'D5_UST'
    AND e.value IS DISTINCT FROM (d.demogidx_5 * p.us_percentile::double precision)
  UNION ALL
  SELECT 1 FROM marts.rebuilt e
  JOIN marts.demographic_index d ON d.geoid = e.geoid
  JOIN marts.raw_percentile p ON p.geoid = e.geoid AND p.group_key = 'P_UST'
  WHERE e.scope = 'state_file' AND e.column_name = 'D2_UST'
    AND e.value IS DISTINCT FROM (d.demogidx_2st * p.state_percentile::double precision)
  UNION ALL
  SELECT 1 FROM marts.rebuilt e
  JOIN marts.demographic_index d ON d.geoid = e.geoid
  JOIN marts.raw_percentile p ON p.geoid = e.geoid AND p.group_key = 'P_UST'
  WHERE e.scope = 'state_file' AND e.column_name = 'D5_UST'
    AND e.value IS DISTINCT FROM (d.demogidx_5st * p.state_percentile::double precision)
  UNION ALL
  SELECT 1 FROM marts.rebuilt e
  JOIN marts.demographic_index d ON d.geoid = e.geoid
  JOIN marts.raw_percentile p ON p.geoid = e.geoid AND p.group_key = 'P_PWDIS'
  WHERE e.scope = 'national_file' AND e.column_name = 'D2_PWDIS'
    AND e.value IS DISTINCT FROM (d.demogidx_2 * p.us_percentile::double precision)
  UNION ALL
  SELECT 1 FROM marts.rebuilt e
  JOIN marts.demographic_index d ON d.geoid = e.geoid
  JOIN marts.raw_percentile p ON p.geoid = e.geoid AND p.group_key = 'P_PWDIS'
  WHERE e.scope = 'national_file' AND e.column_name = 'D5_PWDIS'
    AND e.value IS DISTINCT FROM (d.demogidx_5 * p.us_percentile::double precision)
  UNION ALL
  SELECT 1 FROM marts.rebuilt e
  JOIN marts.demographic_index d ON d.geoid = e.geoid
  JOIN marts.raw_percentile p ON p.geoid = e.geoid AND p.group_key = 'P_PWDIS'
  WHERE e.scope = 'state_file' AND e.column_name = 'D2_PWDIS'
    AND e.value IS DISTINCT FROM (d.demogidx_2st * p.state_percentile::double precision)
  UNION ALL
  SELECT 1 FROM marts.rebuilt e
  JOIN marts.demographic_index d ON d.geoid = e.geoid
  JOIN marts.raw_percentile p ON p.geoid = e.geoid AND p.group_key = 'P_PWDIS'
  WHERE e.scope = 'state_file' AND e.column_name = 'D5_PWDIS'
    AND e.value IS DISTINCT FROM (d.demogidx_5st * p.state_percentile::double precision)
  UNION ALL
  SELECT 1 FROM marts.rebuilt e
  JOIN marts.demographic_index d ON d.geoid = e.geoid
  JOIN marts.raw_percentile p ON p.geoid = e.geoid AND p.group_key = 'P_NO2'
  WHERE e.scope = 'national_file' AND e.column_name = 'D2_NO2'
    AND e.value IS DISTINCT FROM (d.demogidx_2 * p.us_percentile::double precision)
  UNION ALL
  SELECT 1 FROM marts.rebuilt e
  JOIN marts.demographic_index d ON d.geoid = e.geoid
  JOIN marts.raw_percentile p ON p.geoid = e.geoid AND p.group_key = 'P_NO2'
  WHERE e.scope = 'national_file' AND e.column_name = 'D5_NO2'
    AND e.value IS DISTINCT FROM (d.demogidx_5 * p.us_percentile::double precision)
  UNION ALL
  SELECT 1 FROM marts.rebuilt e
  JOIN marts.demographic_index d ON d.geoid = e.geoid
  JOIN marts.raw_percentile p ON p.geoid = e.geoid AND p.group_key = 'P_NO2'
  WHERE e.scope = 'state_file' AND e.column_name = 'D2_NO2'
    AND e.value IS DISTINCT FROM (d.demogidx_2st * p.state_percentile::double precision)
  UNION ALL
  SELECT 1 FROM marts.rebuilt e
  JOIN marts.demographic_index d ON d.geoid = e.geoid
  JOIN marts.raw_percentile p ON p.geoid = e.geoid AND p.group_key = 'P_NO2'
  WHERE e.scope = 'state_file' AND e.column_name = 'D5_NO2'
    AND e.value IS DISTINCT FROM (d.demogidx_5st * p.state_percentile::double precision)
  UNION ALL
  SELECT 1 FROM marts.rebuilt e
  JOIN marts.demographic_index d ON d.geoid = e.geoid
  JOIN marts.raw_percentile p ON p.geoid = e.geoid AND p.group_key = 'P_DWATER'
  WHERE e.scope = 'national_file' AND e.column_name = 'D2_DWATER'
    AND e.value IS DISTINCT FROM (d.demogidx_2 * p.us_percentile::double precision)
  UNION ALL
  SELECT 1 FROM marts.rebuilt e
  JOIN marts.demographic_index d ON d.geoid = e.geoid
  JOIN marts.raw_percentile p ON p.geoid = e.geoid AND p.group_key = 'P_DWATER'
  WHERE e.scope = 'national_file' AND e.column_name = 'D5_DWATER'
    AND e.value IS DISTINCT FROM (d.demogidx_5 * p.us_percentile::double precision)
  UNION ALL
  SELECT 1 FROM marts.rebuilt e
  JOIN marts.demographic_index d ON d.geoid = e.geoid
  JOIN marts.raw_percentile p ON p.geoid = e.geoid AND p.group_key = 'P_DWATER'
  WHERE e.scope = 'state_file' AND e.column_name = 'D2_DWATER'
    AND e.value IS DISTINCT FROM (d.demogidx_2st * p.state_percentile::double precision)
  UNION ALL
  SELECT 1 FROM marts.rebuilt e
  JOIN marts.demographic_index d ON d.geoid = e.geoid
  JOIN marts.raw_percentile p ON p.geoid = e.geoid AND p.group_key = 'P_DWATER'
  WHERE e.scope = 'state_file' AND e.column_name = 'D5_DWATER'
    AND e.value IS DISTINCT FROM (d.demogidx_5st * p.state_percentile::double precision)
  ) identity_mismatch;
  IF bad > 0 THEN
    RAISE EXCEPTION 'EJ or supplemental index is not the demographic index times the environmental percentile on % cells', bad;
  END IF;
END;
$assert$;

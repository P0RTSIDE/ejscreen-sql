COMMENT ON COLUMN marts.acs_moment_us.measure_code IS
  'LOWINCPCT, PEOPCOLORPCT, LINGISOPCT, LESSHSPCT, DISABILITYPCT, or LIFEEXPPCT. Tech doc pp. 32 to 35.';
COMMENT ON COLUMN marts.acs_moment_us.n IS
  'Block groups with a non-null rate. Tech doc p. 41 describes the mean as the average of block groups with data.';
COMMENT ON COLUMN marts.acs_moment_us.mu IS
  'Unweighted mean of the ACS rate. Tech doc p. 31.';
COMMENT ON COLUMN marts.acs_moment_us.sigma IS
  'Sample standard deviation, divisor n - 1. The technical documentation prints standard deviations that match this divisor. See assumptions.';
COMMENT ON COLUMN marts.acs_moment_state.measure_code IS
  'LOWINCPCT, PEOPCOLORPCT, LINGISOPCT, LESSHSPCT, DISABILITYPCT, or LIFEEXPPCT.';
COMMENT ON COLUMN marts.acs_moment_state.state_fips IS
  'State used for the state mean and standard deviation. Includes the District of Columbia and Puerto Rico.';
COMMENT ON COLUMN marts.acs_moment_state.n IS
  'Block groups in the state with a non-null rate.';
COMMENT ON COLUMN marts.acs_moment_state.mu IS
  'Unweighted state mean of the ACS rate. Tech doc p. 33.';
COMMENT ON COLUMN marts.acs_moment_state.sigma IS
  'Sample standard deviation inside the state, divisor n - 1.';

DO $acs_assert$
DECLARE
  bad bigint;
BEGIN
  SELECT count(*) INTO bad FROM staging.acs_indicator WHERE geoid !~ '^[0-9]{12}$';
  IF bad > 0 THEN
    RAISE EXCEPTION 'ACS geoid is not 12 digits on % rows', bad;
  END IF;
  SELECT count(*) INTO bad
  FROM staging.acs_indicator
  WHERE state_fips IN ('60', '66', '69', '78');
  IF bad > 0 THEN
    RAISE EXCEPTION 'Island territory rows are in the ACS rebuild: %', bad;
  END IF;
  SELECT count(*) INTO bad
  FROM staging.acs_indicator
  WHERE acs_population < 0 OR pl_population < 0;
  IF bad > 0 THEN
    RAISE EXCEPTION 'Negative population on % ACS rows', bad;
  END IF;
  IF (SELECT count(DISTINCT state_fips) FROM staging.acs_indicator) <> 52 THEN
    RAISE EXCEPTION 'ACS rebuild does not have 52 state codes (50 states, DC, and Puerto Rico)';
  END IF;
  IF (SELECT min(demogidx_2) FROM marts.acs_block_group) <> 0
     OR (SELECT bool_or(demogidx_2 < 0) FROM marts.acs_block_group) THEN
    RAISE EXCEPTION 'National ACS Demographic Index is not non-negative with minimum 0';
  END IF;
  IF EXISTS (
    SELECT 1
    FROM marts.acs_block_group
    WHERE demogidx_2st IS NOT NULL
    GROUP BY state_fips
    HAVING min(demogidx_2st) <> 0 OR bool_or(demogidx_2st < 0)
  ) THEN
    RAISE EXCEPTION 'A state ACS Demographic Index is negative or its minimum is not 0';
  END IF;
  IF (SELECT min(demogidx_5) FROM marts.acs_block_group) <> 0
     OR (SELECT bool_or(demogidx_5 < 0) FROM marts.acs_block_group) THEN
    RAISE EXCEPTION 'National ACS Supplemental Demographic Index is not non-negative with minimum 0';
  END IF;
  IF EXISTS (
    SELECT 1
    FROM marts.acs_block_group
    WHERE demogidx_5st IS NOT NULL
    GROUP BY state_fips
    HAVING min(demogidx_5st) <> 0 OR bool_or(demogidx_5st < 0)
  ) THEN
    RAISE EXCEPTION 'A state ACS Supplemental Demographic Index is negative or its minimum is not 0';
  END IF;
END
$acs_assert$;

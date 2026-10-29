CREATE EXTENSION IF NOT EXISTS postgis;

CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS marts;
CREATE SCHEMA IF NOT EXISTS validation;

-- Cutoff fractions p/100 for integer percentiles 0 through 100.
-- percentile_cont uses linear interpolation at position 1 + (n - 1) * fraction.
CREATE TABLE IF NOT EXISTS marts.percentile_fractions AS
SELECT array_agg(gs::double precision / 100.0 ORDER BY gs) AS fractions
FROM generate_series(0, 100) AS gs;

-- Tech doc pp. 40 to 42. Highest percentile whose cutoff is <= the value.
-- If the value equals that cutoff and a run of percentiles share it, use the lowest percentile in the run.
CREATE OR REPLACE FUNCTION marts.assign_percentile(v double precision, cuts double precision[])
RETURNS integer
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
  lo integer := 1;
  hi integer := cardinality(cuts);
  mid integer;
  best integer := 0;
BEGIN
  IF v IS NULL OR cuts IS NULL OR cardinality(cuts) = 0 THEN
    RETURN NULL;
  END IF;
  WHILE lo <= hi LOOP
    mid := (lo + hi) / 2;
    IF cuts[mid] <= v THEN
      best := mid;
      lo := mid + 1;
    ELSE
      hi := mid - 1;
    END IF;
  END LOOP;
  IF best = 0 THEN
    RETURN NULL;
  END IF;
  IF cuts[best] = v THEN
    WHILE best > 1 AND cuts[best - 1] = v LOOP
      best := best - 1;
    END LOOP;
  END IF;
  RETURN best - 1;
END;
$$;

COMMENT ON FUNCTION marts.assign_percentile(double precision, double precision[]) IS
  'Assigns an integer percentile from 101 raw cutoffs. Implements EJScreen Technical Documentation for Version 2.3, pp. 40 to 42: lower end of the range, with the floor rule for tied cutoffs.';

DO $$
DECLARE
  tied double precision[] := array_fill(0::double precision, ARRAY[11]) || ARRAY[1::double precision];
  steps double precision[] := ARRAY[0, 0.25, 0.5, 1]::double precision[];
  got integer;
BEGIN
  IF (SELECT cardinality(fractions) FROM marts.percentile_fractions) <> 101 THEN
    RAISE EXCEPTION 'Percentile fraction grid must contain 101 cutoffs';
  END IF;
  got := marts.assign_percentile(0, tied);
  IF got <> 0 THEN
    RAISE EXCEPTION 'Tied zero cutoff should assign percentile 0, got %', got;
  END IF;
  got := marts.assign_percentile(0.5, tied);
  IF got <> 10 THEN
    RAISE EXCEPTION 'Value above a tied zero run should keep the top of that run, got %', got;
  END IF;
  got := marts.assign_percentile(1, tied);
  IF got <> 11 THEN
    RAISE EXCEPTION 'Value equal to the top cutoff should assign that percentile, got %', got;
  END IF;
  got := marts.assign_percentile(0.25, steps);
  IF got <> 1 THEN
    RAISE EXCEPTION 'Exact cutoff hit should assign that percentile, got %', got;
  END IF;
  got := marts.assign_percentile(0.3, steps);
  IF got <> 1 THEN
    RAISE EXCEPTION 'Value inside a range should assign the lower cutoff, got %', got;
  END IF;
END;
$$;

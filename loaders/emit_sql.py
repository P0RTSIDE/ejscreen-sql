"""Write the Tier 1 SQL files from the CSV headers and the indicator catalog."""

import csv
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SQL = ROOT / "sql"

# suffix, staging column, raw column, percentile column, tech doc name, page
ENV = [
    ("PM25", "pm25", "PM25", "P_PM25", "Particulate Matter 2.5", "p. 16"),
    ("OZONE", "ozone", "OZONE", "P_OZONE", "Ozone", "pp. 16 to 17"),
    ("DSLPM", "diesel_pm", "DSLPM", "P_DSLPM", "Diesel particulate matter", "p. 19"),
    ("RSEI_AIR", "toxic_air", "RSEI_AIR", "P_RSEI_AIR", "Toxic releases to air", "pp. 19 to 20"),
    ("PTRAF", "traffic", "PTRAF", "P_PTRAF", "Traffic proximity and volume", "pp. 21 to 22"),
    ("LDPNT", "lead_paint", "PRE1960PCT", "P_LDPNT", "Lead paint", "pp. 22 to 23"),
    ("PNPL", "superfund", "PNPL", "P_PNPL", "Superfund proximity", "p. 23"),
    ("PRMP", "rmp", "PRMP", "P_PRMP", "RMP facility proximity", "p. 24"),
    ("PTSDF", "hazardous_waste", "PTSDF", "P_PTSDF", "Hazardous waste proximity", "pp. 24 to 25"),
    ("UST", "ust", "UST", "P_UST", "Underground storage tanks", "pp. 25 to 26"),
    ("PWDIS", "wastewater", "PWDIS", "P_PWDIS", "Wastewater discharge", "pp. 26 to 27"),
    ("NO2", "no2", "NO2", "P_NO2", "Nitrogen dioxide", "pp. 18 to 19"),
    ("DWATER", "drinking_water", "DWATER", "P_DWATER", "Drinking water non-compliance", "pp. 27 to 29"),
]
SOC = [
    ("PEOPCOLORPCT", "pct_people_of_color", "PEOPCOLORPCT", "P_PEOPCOLORPCT", "Percent people of color", "p. 7 and p. 32"),
    ("LOWINCPCT", "pct_low_income", "LOWINCPCT", "P_LOWINCPCT", "Percent low income", "pp. 8 to 9 and p. 32"),
    ("UNEMPPCT", "pct_unemployed", "UNEMPPCT", "P_UNEMPPCT", "Percent unemployed", "pp. 9 to 10"),
    ("DISABILITYPCT", "pct_disability", "DISABILITYPCT", "P_DISABILITYPCT", "Percent persons with disabilities", "p. 34"),
    ("LINGISOPCT", "pct_limited_english", "LINGISOPCT", "P_LINGISOPCT", "Percent limited English speaking households", "p. 10 and p. 34"),
    ("LESSHSPCT", "pct_less_than_hs", "LESSHSPCT", "P_LESSHSPCT", "Percent less than high school education", "pp. 11 to 12 and pp. 34 to 35"),
    ("UNDER5PCT", "pct_under_5", "UNDER5PCT", "P_UNDER5PCT", "Percent under age 5", "pp. 12 to 13"),
    ("OVER64PCT", "pct_over_64", "OVER64PCT", "P_OVER64PCT", "Percent over age 64", "pp. 12 to 13"),
    ("LIFEEXPPCT", "pct_low_life_expectancy", "LIFEEXPPCT", "P_LIFEEXPPCT", "Low life expectancy", "p. 33 and p. 55"),
]
Z_CODES = ("LOWINCPCT", "PEOPCOLORPCT", "LINGISOPCT", "LESSHSPCT", "DISABILITYPCT", "LIFEEXPPCT")


def q(name: str) -> str:
    return '"' + name.replace('"', '""') + '"'


def header(path: Path) -> list[str]:
    with path.open(newline="", encoding="utf-8-sig") as handle:
        return next(csv.reader(handle))


def write(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text.strip() + "\n")
    print(path.relative_to(ROOT))


def raw_ddl(table: str, columns: list[str]) -> str:
    body = ",\n  ".join(f"{q(col)} text" for col in columns)
    return f"DROP TABLE IF EXISTS {table};\nCREATE TABLE {table} (\n  {body}\n);"


def staging_sql() -> str:
    casts = [
        ('"ID"', "source_id", "text"),
        ('CASE WHEN length("ID") >= 12 THEN "ID" ELSE lpad("ID", 12, \'0\') END', "geoid", "text"),
        ('left("ID", 2)', "state_fips", "text"),
        ('"ST_ABBREV"', "state_abbrev", "text"),
        ('"STATE_NAME"', "state_name", "text"),
        ('"CNTY_NAME"', "county_name", "text"),
        ('NULLIF("REGION", \'\')', "region", "text"),
        ('"ST_ABBREV" NOT IN (\'AS\', \'GU\', \'MP\', \'VI\')', "in_national_universe", "bool"),
        ('NULLIF("ACSTOTPOP", \'\')::double precision', "population", "float"),
    ]
    for _suffix, stage, raw, _pct, _name, _page in SOC + ENV:
        casts.append((f'NULLIF({q(raw)}, \'\')::double precision', stage, "float"))
    select_list = ",\n  ".join(f"{expr} AS {alias}" for expr, alias, _kind in casts)
    measure_unions = []
    for _suffix, stage, raw, _pct, _name, _page in SOC + ENV:
        measure_unions.append(
            f"SELECT geoid, state_abbrev, in_national_universe, '{raw}' AS measure_code, {stage} AS value\n"
            f"FROM staging.block_group_inputs"
        )
    measures = "\nUNION ALL\n".join(measure_unions)
    return f"""
DROP TABLE IF EXISTS staging.measure_value;
DROP TABLE IF EXISTS staging.block_group_inputs;

CREATE TABLE staging.block_group_inputs AS
SELECT
  {select_list}
FROM raw.ejscreen_reference;

ALTER TABLE staging.block_group_inputs
  ALTER COLUMN geoid SET NOT NULL,
  ALTER COLUMN source_id SET NOT NULL;
ALTER TABLE staging.block_group_inputs ADD PRIMARY KEY (geoid);
CREATE UNIQUE INDEX block_group_inputs_source_id ON staging.block_group_inputs (source_id);

COMMENT ON TABLE staging.block_group_inputs IS
  'One row per block group or territory place or estate. Indicator values are the published raw fields from raw.ejscreen_reference. Tech doc pp. 15 to 29 and pp. 31 to 35.';

CREATE TABLE staging.measure_value AS
{measures};

CREATE INDEX measure_value_code ON staging.measure_value (measure_code);
ANALYZE staging.block_group_inputs;
ANALYZE staging.measure_value;
"""


def demographics_sql() -> str:
    codes = ", ".join(f"'{code}'" for code in Z_CODES)
    z_us = []
    z_st = []
    for code, alias in (
        ("LOWINCPCT", "li"),
        ("PEOPCOLORPCT", "poc"),
        ("LINGISOPCT", "ling"),
        ("LESSHSPCT", "hs"),
        ("DISABILITYPCT", "dis"),
        ("LIFEEXPPCT", "life"),
    ):
        z_us.append(f"max(z_us) FILTER (WHERE measure_code = '{code}') AS z_{alias}")
        z_st.append(f"max(z_st) FILTER (WHERE measure_code = '{code}') AS z_{alias}_st")
    wide_cols = ",\n    ".join(z_us + z_st)
    return f"""
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
  AND measure_code IN ({codes})
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
  AND measure_code IN ({codes})
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
  WHERE m.measure_code IN ({codes})
),
wide AS (
  SELECT geoid,
         state_abbrev,
         in_national_universe,
         {wide_cols}
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
"""


def rank_engine() -> str:
    return """
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
"""


def save_ranked_sql() -> str:
    return """
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
"""


def percentiles_sql() -> str:
    raw_inserts = []
    for _suffix, stage, raw, pct, _name, _page in SOC + ENV:
        raw_inserts.append(
            f"SELECT '{pct}', geoid, state_abbrev, in_national_universe, {stage}, 'both' "
            f"FROM staging.block_group_inputs"
        )
    raw_sql = "\nUNION ALL\n".join(raw_inserts)
    ej_inserts = []
    for suffix, _stage, _raw, pct, _name, _page in ENV:
        for kind, demo in (("D2", "demogidx_2"), ("D5", "demogidx_5")):
            ej_inserts.append(
                f"""SELECT b.geoid, 'national_file', '{kind}_{suffix}', 'continuous',
       d.{demo} * p.us_percentile::double precision
FROM staging.block_group_inputs b
JOIN marts.demographic_index d ON d.geoid = b.geoid
JOIN marts.raw_percentile p ON p.group_key = '{pct}' AND p.geoid = b.geoid"""
            )
        for kind, demo in (("D2", "demogidx_2st"), ("D5", "demogidx_5st")):
            ej_inserts.append(
                f"""SELECT b.geoid, 'state_file', '{kind}_{suffix}', 'continuous',
       d.{demo} * p.state_percentile::double precision
FROM staging.block_group_inputs b
JOIN marts.demographic_index d ON d.geoid = b.geoid
JOIN marts.raw_percentile p ON p.group_key = '{pct}' AND p.geoid = b.geoid"""
            )
    ej_sql = "\nUNION ALL\n".join(ej_inserts)
    us_rank_parts = [
        "SELECT 'P_DEMOGIDX_2', s.geoid, s.state_abbrev, s.in_national_universe, d.demogidx_2, 'us' "
        "FROM marts.demographic_index d JOIN staging.block_group_inputs s ON s.geoid = d.geoid",
        "SELECT 'P_DEMOGIDX_5', s.geoid, s.state_abbrev, s.in_national_universe, d.demogidx_5, 'us' "
        "FROM marts.demographic_index d JOIN staging.block_group_inputs s ON s.geoid = d.geoid",
    ]
    st_rank_parts = [
        "SELECT 'P_DEMOGIDX_2', s.geoid, s.state_abbrev, s.in_national_universe, d.demogidx_2st, 'state' "
        "FROM marts.demographic_index d JOIN staging.block_group_inputs s ON s.geoid = d.geoid",
        "SELECT 'P_DEMOGIDX_5', s.geoid, s.state_abbrev, s.in_national_universe, d.demogidx_5st, 'state' "
        "FROM marts.demographic_index d JOIN staging.block_group_inputs s ON s.geoid = d.geoid",
    ]
    for suffix, _stage, _raw, _pct, _name, _page in ENV:
        for kind in ("D2", "D5"):
            us_rank_parts.append(
                f"SELECT 'P_{kind}_{suffix}', s.geoid, s.state_abbrev, s.in_national_universe, r.value, 'us' "
                f"FROM marts.rebuilt r JOIN staging.block_group_inputs s ON s.geoid = r.geoid "
                f"WHERE r.scope = 'national_file' AND r.column_name = '{kind}_{suffix}'"
            )
            st_rank_parts.append(
                f"SELECT 'P_{kind}_{suffix}', s.geoid, s.state_abbrev, s.in_national_universe, r.value, 'state' "
                f"FROM marts.rebuilt r JOIN staging.block_group_inputs s ON s.geoid = r.geoid "
                f"WHERE r.scope = 'state_file' AND r.column_name = '{kind}_{suffix}'"
            )
    return f"""
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

{rank_engine()}

TRUNCATE staging.rank_input;
INSERT INTO staging.rank_input (group_key, geoid, state_abbrev, in_national_universe, value, rank_mode)
{raw_sql};

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

{save_ranked_sql()}

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
{ej_sql};

TRUNCATE staging.rank_input;
INSERT INTO staging.rank_input (group_key, geoid, state_abbrev, in_national_universe, value, rank_mode)
{" UNION ALL ".join(us_rank_parts)};
CALL marts.fill_rank_output();
INSERT INTO marts.rebuilt (scope, column_name, kind, geoid, value)
SELECT 'national_file', group_key, 'percentile', geoid, us_percentile::double precision
FROM marts.rank_output;
{save_ranked_sql()}

TRUNCATE staging.rank_input;
INSERT INTO staging.rank_input (group_key, geoid, state_abbrev, in_national_universe, value, rank_mode)
{" UNION ALL ".join(st_rank_parts)};
CALL marts.fill_rank_output();
INSERT INTO marts.rebuilt (scope, column_name, kind, geoid, value)
SELECT 'state_file', group_key, 'percentile', geoid, state_percentile::double precision
FROM marts.rank_output;
{save_ranked_sql()}

CREATE INDEX rebuilt_lookup ON marts.rebuilt (scope, column_name, geoid);
ANALYZE marts.rebuilt;
ANALYZE marts.ranked_value;
"""


def scores_sql() -> str:
    cols = [
        ("demogidx_2", "national_file", "DEMOGIDX_2", "Demographic Index, shifted national average of the low income and people of color z scores. Tech doc pp. 32 to 33 and pp. 36 to 37."),
        ("demogidx_5", "national_file", "DEMOGIDX_5", "Supplemental Demographic Index, shifted national average of five z scores, or four when low life expectancy is missing. Tech doc pp. 33 to 35 and pp. 38 to 39."),
        ("demogidx_2st", "national_file", "DEMOGIDX_2ST", "State Demographic Index. Same formula as the national Demographic Index, using the state mean, sample standard deviation, and shift. Tech doc p. 33."),
        ("demogidx_5st", "national_file", "DEMOGIDX_5ST", "State Supplemental Demographic Index. Tech doc p. 35."),
        ("p_demogidx_2", "national_file", "P_DEMOGIDX_2", "National percentile of the Demographic Index. Tech doc pp. 40 to 42."),
        ("p_demogidx_5", "national_file", "P_DEMOGIDX_5", "National percentile of the Supplemental Demographic Index. Tech doc pp. 40 to 42."),
        ("st_p_demogidx_2", "state_file", "P_DEMOGIDX_2", "State percentile of the state Demographic Index. Tech doc pp. 41 to 42."),
        ("st_p_demogidx_5", "state_file", "P_DEMOGIDX_5", "State percentile of the state Supplemental Demographic Index. Tech doc pp. 41 to 42."),
    ]
    for _suffix, _stage, raw, pct, name, page in SOC:
        key = pct.lower()
        cols.append((key, "national_file", pct, f"National percentile of {name}. Tech doc {page} and pp. 40 to 42."))
        cols.append((f"st_{key}", "state_file", pct, f"State percentile of {name}. Tech doc {page} and pp. 41 to 42."))
    for suffix, _stage, _raw, pct, name, page in ENV:
        low = suffix.lower()
        cols.append((f"p_{low}", "national_file", pct, f"National percentile of {name}. Tech doc {page} and pp. 40 to 42."))
        cols.append((f"st_p_{low}", "state_file", pct, f"State percentile of {name}. Tech doc {page} and pp. 41 to 42."))
        for kind, label, demo_page in (
            ("D2", "EJ index", "p. 36"),
            ("D5", "supplemental index", "p. 38"),
        ):
            cols.append((
                f"{kind.lower()}_{low}",
                "national_file",
                f"{kind}_{suffix}",
                f"National {label} for {name}: shifted demographic index times the national environmental percentile on a 0 to 100 scale. Tech doc {demo_page} and {page}.",
            ))
            cols.append((
                f"st_{kind.lower()}_{low}",
                "state_file",
                f"{kind}_{suffix}",
                f"State {label} for {name}: shifted state demographic index times the state environmental percentile on a 0 to 100 scale. Tech doc {demo_page}, p. 33, and pp. 41 to 43.",
            ))
            cols.append((
                f"p_{kind.lower()}_{low}",
                "national_file",
                f"P_{kind}_{suffix}",
                f"National percentile of the {label} for {name}. Tech doc pp. 36 to 42.",
            ))
            cols.append((
                f"st_p_{kind.lower()}_{low}",
                "state_file",
                f"P_{kind}_{suffix}",
                f"State percentile of the state {label} for {name}. Tech doc pp. 41 to 43.",
            ))
    select_cols = ["s.geoid", "s.state_fips", "s.state_abbrev"]
    for alias, scope, column, _comment in cols:
        select_cols.append(
            f"max(r.value) FILTER (WHERE r.scope = '{scope}' AND r.column_name = '{column}') AS {alias}"
        )
    comments = [
        "COMMENT ON TABLE marts.block_group_score IS 'Rebuilt EJScreen version 2.3 demographic indexes, indicator percentiles, EJ indexes, and supplemental indexes. National columns follow pp. 31 to 42. State columns use the same formulas inside each state. The tech doc states no cap on the index product.';",
        "COMMENT ON COLUMN marts.block_group_score.geoid IS '12 character id. Census block group id, or a zero padded place or estate code. See assumptions for the padding rule.';",
        "COMMENT ON COLUMN marts.block_group_score.state_fips IS 'First two digits of the source id. Includes 11 for the District of Columbia and 72 for Puerto Rico.';",
        "COMMENT ON COLUMN marts.block_group_score.state_abbrev IS 'State, District of Columbia, Puerto Rico, or island territory abbreviation from the reference file.';",
    ]
    for alias, _scope, _column, comment in cols:
        safe = comment.replace("'", "''")
        comments.append(f"COMMENT ON COLUMN marts.block_group_score.{alias} IS '{safe}';")
    comments.extend([
        "COMMENT ON TABLE marts.demographic_index IS 'Shifted and unshifted demographic indexes. National formulas are tech doc pp. 32 to 39. State formulas use the same steps inside each state, p. 33 and p. 35.';",
        "COMMENT ON COLUMN marts.demographic_index.geoid IS '12 character id joining to staging.block_group_inputs.';",
        "COMMENT ON COLUMN marts.demographic_index.demogidx_2_unshifted IS 'Average of the national low income and people of color z scores, before the shift. Tech doc p. 32 and p. 36.';",
        "COMMENT ON COLUMN marts.demographic_index.demogidx_2 IS 'Demographic Index after adding the absolute value of the smallest national unshifted index. Tech doc p. 33 and pp. 36 to 37.';",
        "COMMENT ON COLUMN marts.demographic_index.demogidx_5_unshifted IS 'Average of five national z scores, or four when low life expectancy is missing, before the shift. Tech doc p. 35.';",
        "COMMENT ON COLUMN marts.demographic_index.demogidx_5 IS 'Supplemental Demographic Index after the national shift. Tech doc p. 35 and pp. 38 to 39.';",
        "COMMENT ON COLUMN marts.demographic_index.demogidx_2st_unshifted IS 'Unshifted state Demographic Index. Tech doc p. 33.';",
        "COMMENT ON COLUMN marts.demographic_index.demogidx_2st IS 'State Demographic Index after the state shift. Tech doc p. 33.';",
        "COMMENT ON COLUMN marts.demographic_index.demogidx_5st_unshifted IS 'Unshifted state Supplemental Demographic Index. Tech doc p. 35.';",
        "COMMENT ON COLUMN marts.demographic_index.demogidx_5st IS 'State Supplemental Demographic Index after the state shift. Tech doc p. 35.';",
        "COMMENT ON TABLE marts.moment_us IS 'Unweighted national mean and sample standard deviation of the demographic inputs. Tech doc pp. 31 to 33 and p. 41. The four island territories are excluded.';",
        "COMMENT ON TABLE marts.moment_state IS 'Unweighted state mean and sample standard deviation of the demographic inputs. Tech doc p. 33, p. 35, and p. 41.';",
        "COMMENT ON TABLE marts.rebuilt IS 'Long rebuilt values aligned to published column names. scope national_file is compared with raw.ejscreen_reference. scope state_file is compared with raw.ejscreen_reference_state_pct.';",
        "COMMENT ON TABLE marts.raw_percentile IS 'Cutoff percentiles for published indicator inputs. National percentiles exclude the four island territories. Tech doc pp. 40 to 42 and p. 53.';",
        "COMMENT ON TABLE marts.ranked_value IS 'Values that enter each percentile denominator. The percent rank view reads this table.';",
        "COMMENT ON VIEW marts.indicator_percent_rank IS 'PostgreSQL percent_rank() times 100 for the same values used by the cutoff percentiles. Comparison only. The primary percentile is marts.assign_percentile, tech doc pp. 40 to 42.';",
    ])
    for table, names in (
        ("moment_us", ("measure_code", "n", "mu", "sigma")),
        ("moment_state", ("state_abbrev", "measure_code", "n", "mu", "sigma")),
        ("rebuilt", ("scope", "column_name", "kind", "geoid", "value")),
        ("raw_percentile", ("group_key", "geoid", "state_abbrev", "in_national_universe", "value", "us_percentile", "state_percentile")),
        ("ranked_value", ("scope", "percentile_column", "geoid", "value")),
    ):
        notes = {
            "measure_code": "Published indicator column used in a demographic z score.",
            "n": "Count of non null block groups in the moment.",
            "mu": "Unweighted mean. Tech doc p. 41.",
            "sigma": "Sample standard deviation, divisor n - 1. See assumptions.",
            "state_abbrev": "State, District of Columbia, Puerto Rico, or island territory.",
            "scope": "national_file or state_file, matching the two Harvard extracts.",
            "column_name": "Published column name in the Harvard extract.",
            "kind": "continuous for an index value, percentile for an integer percentile.",
            "geoid": "12 character id.",
            "value": "Rebuilt number. Null where an input is null or the tech doc excludes the row.",
            "group_key": "Published percentile column this cutoff belongs to.",
            "in_national_universe": "True for the 50 states, the District of Columbia, and Puerto Rico.",
            "us_percentile": "National cutoff percentile, null for the four island territories. Tech doc p. 53.",
            "state_percentile": "State cutoff percentile. Tech doc pp. 41 to 42.",
            "percentile_column": "Published percentile column whose denominator this value belongs to.",
        }
        for name in names:
            comments.append(
                f"COMMENT ON COLUMN marts.{table}.{name} IS '{notes[name]}';"
            )
    view_comments = [
        ("scope", "national_file or state_file."),
        ("percentile_column", "Published percentile column being compared."),
        ("geoid", "12 character id."),
        ("value", "Indicator or index value that was ranked."),
        ("percent_rank_0_100", "percent_rank() times 100. Ties share the minimum rank. Not the tech doc cutoff percentile."),
    ]
    for name, note in view_comments:
        comments.append(f"COMMENT ON COLUMN marts.indicator_percent_rank.{name} IS '{note}';")
    comment_sql = "\n".join(comments)
    select_sql = ",\n  ".join(select_cols)
    return f"""
DROP VIEW IF EXISTS marts.indicator_percent_rank;
DROP TABLE IF EXISTS marts.block_group_score;

CREATE TABLE marts.block_group_score AS
SELECT
  {select_sql}
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

{comment_sql}
"""


def assertions_sql() -> str:
    checks = []
    for suffix, _stage, _raw, pct, _name, _page in ENV:
        checks.append(
            f"""SELECT 1 FROM marts.rebuilt e
  JOIN marts.demographic_index d ON d.geoid = e.geoid
  JOIN marts.raw_percentile p ON p.geoid = e.geoid AND p.group_key = '{pct}'
  WHERE e.scope = 'national_file' AND e.column_name = 'D2_{suffix}'
    AND e.value IS DISTINCT FROM (d.demogidx_2 * p.us_percentile::double precision)"""
        )
        checks.append(
            f"""SELECT 1 FROM marts.rebuilt e
  JOIN marts.demographic_index d ON d.geoid = e.geoid
  JOIN marts.raw_percentile p ON p.geoid = e.geoid AND p.group_key = '{pct}'
  WHERE e.scope = 'national_file' AND e.column_name = 'D5_{suffix}'
    AND e.value IS DISTINCT FROM (d.demogidx_5 * p.us_percentile::double precision)"""
        )
        checks.append(
            f"""SELECT 1 FROM marts.rebuilt e
  JOIN marts.demographic_index d ON d.geoid = e.geoid
  JOIN marts.raw_percentile p ON p.geoid = e.geoid AND p.group_key = '{pct}'
  WHERE e.scope = 'state_file' AND e.column_name = 'D2_{suffix}'
    AND e.value IS DISTINCT FROM (d.demogidx_2st * p.state_percentile::double precision)"""
        )
        checks.append(
            f"""SELECT 1 FROM marts.rebuilt e
  JOIN marts.demographic_index d ON d.geoid = e.geoid
  JOIN marts.raw_percentile p ON p.geoid = e.geoid AND p.group_key = '{pct}'
  WHERE e.scope = 'state_file' AND e.column_name = 'D5_{suffix}'
    AND e.value IS DISTINCT FROM (d.demogidx_5st * p.state_percentile::double precision)"""
        )
    identity = "\n  UNION ALL\n  ".join(checks)
    return """
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
  __IDENTITY__
  ) identity_mismatch;
  IF bad > 0 THEN
    RAISE EXCEPTION 'EJ or supplemental index is not the demographic index times the environmental percentile on % cells', bad;
  END IF;
END;
$assert$;
""".replace("__IDENTITY__", identity)


def reference_values(scope: str, table: str, columns: list[tuple[str, str]]) -> str:
    values = ",\n    ".join(
        f"('{column}', '{kind}', r.{q(column)})" for column, kind in columns
    )
    return f"""
INSERT INTO validation.reference_value (scope, column_name, kind, geoid, value)
SELECT '{scope}', v.column_name, v.kind, s.geoid, NULLIF(v.raw, '')::double precision
FROM {table} r
JOIN staging.block_group_inputs s ON s.source_id = r."ID"
CROSS JOIN LATERAL (VALUES
    {values}
) AS v(column_name, kind, raw);
"""


def metrics_sql() -> str:
    # Thresholds below are fixed in this file before the comparison is run.
    # Continuous tolerance is 1e-8. Percentile tolerance is 0.
    # Exact and tolerance checks pass at 99 percent of rows with both values present.
    # Null agreement passes at 99.9 percent of rows.
    national = [("DEMOGIDX_2", "continuous"), ("DEMOGIDX_5", "continuous"),
                ("DEMOGIDX_2ST", "continuous"), ("DEMOGIDX_5ST", "continuous"),
                ("P_DEMOGIDX_2", "percentile"), ("P_DEMOGIDX_5", "percentile")]
    state = [("DEMOGIDX_2", "continuous"), ("DEMOGIDX_5", "continuous"),
             ("P_DEMOGIDX_2", "percentile"), ("P_DEMOGIDX_5", "percentile")]
    for _suffix, _stage, raw, pct, _name, _page in SOC + ENV:
        national.append((pct, "percentile"))
        state.append((pct, "percentile"))
    for suffix, _stage, _raw, _pct, _name, _page in ENV:
        for kind in ("D2", "D5"):
            national.append((f"{kind}_{suffix}", "continuous"))
            national.append((f"P_{kind}_{suffix}", "percentile"))
            state.append((f"{kind}_{suffix}", "continuous"))
            state.append((f"P_{kind}_{suffix}", "percentile"))
    raw_compare = []
    for _suffix, _stage, raw, _pct, _name, _page in SOC + ENV:
        raw_compare.append(raw)
    raw_union = "\nUNION ALL\n".join(
        f"""SELECT '{col}' AS column_name,
       count(*) FILTER (
         WHERE NULLIF(n.{q(col)}, '')::double precision IS DISTINCT FROM NULLIF(s.{q(col)}, '')::double precision
       ) AS n_differ,
       max(abs(NULLIF(n.{q(col)}, '')::double precision - NULLIF(s.{q(col)}, '')::double precision)) AS max_abs
FROM raw.ejscreen_reference n
JOIN raw.ejscreen_reference_state_pct s ON s."ID" = n."ID\""""
        for col in raw_compare
    )
    return f"""
SET statement_timeout = 0;
SET work_mem = '512MB';
SET max_parallel_workers_per_gather = 2;

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

{reference_values('national_file', 'raw.ejscreen_reference', national)}
{reference_values('state_file', 'raw.ejscreen_reference_state_pct', state)}

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
{raw_union};

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
"""


def main() -> None:
    national = header(Path("/tmp/EJSCREEN_2024_BG_with_AS_CNMI_GU_VI.csv"))
    state = header(Path("/tmp/EJSCREEN_2024_BG_StatePct_with_AS_CNMI_GU_VI.csv"))
    if len(national) != 231 or len(state) != 229:
        raise SystemExit(f"Unexpected header widths {len(national)} {len(state)}")
    write(SQL / "002_raw_tables.sql", "\n".join([
        raw_ddl("raw.ejscreen_reference", national),
        raw_ddl("raw.ejscreen_reference_state_pct", state),
    ]))
    write(SQL / "010_staging.sql", staging_sql())
    write(SQL / "020_demographics.sql", demographics_sql())
    write(SQL / "030_percentiles_indexes.sql", percentiles_sql())
    write(SQL / "040_scores_comments.sql", scores_sql())
    write(SQL / "080_assertions.sql", assertions_sql())
    write(SQL / "validation" / "metrics.sql", metrics_sql())


if __name__ == "__main__":
    main()

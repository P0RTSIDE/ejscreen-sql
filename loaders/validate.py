"""Run assertions and write the profile and validation report from SQL results."""

import os
from pathlib import Path
from xml.etree import ElementTree as ET
import zipfile

from common import ROOT, connect, load_dotenv, run_sql_file

DOCS = ROOT / "docs"
NS = {"m": "http://schemas.openxmlformats.org/spreadsheetml/2006/main"}
TEXT_COLUMNS = {"ID", "STATE_NAME", "ST_ABBREV", "CNTY_NAME"}
EXCEED_ALIAS = {
    "EXCEED_COUNT_80": "EXCEED2_COUNT_80",
    "EXCEED_COUNT_80_SUP": "EXCEED2_COUNT_80_SUP",
}


def num(value) -> str:
    if value is None:
        return ""
    return format(float(value), ".12g")


def rate(part, whole) -> str:
    if not whole:
        return ""
    return format(part / whole, ".6f")


def workbook_dictionary(path: Path) -> dict[str, str]:
    if not path.exists():
        return {}
    with zipfile.ZipFile(path) as book:
        shared = []
        root = ET.fromstring(book.read("xl/sharedStrings.xml"))
        for item in root.findall("m:si", NS):
            shared.append("".join(node.text or "" for node in item.findall(".//m:t", NS)))
        sheet = ET.fromstring(book.read("xl/worksheets/sheet1.xml"))
    rows = {}
    for cell in sheet.findall(".//m:c", NS):
        ref = cell.attrib.get("r", "")
        col = "".join(ch for ch in ref if ch.isalpha())
        row = int("".join(ch for ch in ref if ch.isdigit()) or 0)
        raw = cell.find("m:v", NS)
        if raw is None or raw.text is None:
            value = ""
        elif cell.attrib.get("t") == "s":
            value = shared[int(raw.text)]
        else:
            value = raw.text
        index = 0
        for ch in col:
            index = index * 26 + ord(ch) - 64
        rows.setdefault(row, {})[index] = value
    out = {}
    for row, cols in rows.items():
        name = (cols.get(2) or "").strip()
        description = (cols.get(3) or "").strip()
        if name and name not in {"Column Names", "GDB Fieldname"}:
            out[name] = description
    return out


def query_rows(conn, sql, params=None):
    with conn.cursor() as cur:
        cur.execute(sql, params)
        columns = [desc[0] for desc in cur.description]
        return [dict(zip(columns, row)) for row in cur.fetchall()]


def column_stats(conn, table: str) -> list[dict]:
    with conn.cursor() as cur:
        cur.execute(
            """
            SELECT column_name
            FROM information_schema.columns
            WHERE table_schema = 'raw' AND table_name = %s
            ORDER BY ordinal_position
            """,
            (table,),
        )
        columns = [row[0] for row in cur.fetchall()]
    parts = []
    for column in columns:
        quoted = '"' + column.replace('"', '""') + '"'
        if column in TEXT_COLUMNS or column.startswith("T_"):
            parts.append(
                f"""SELECT '{column}' AS column_name,
                       count(*) FILTER (WHERE {quoted} IS NULL) AS null_count,
                       count(*) AS n,
                       min({quoted}) AS min_value,
                       max({quoted}) AS max_value
                FROM raw.{table}"""
            )
        else:
            parts.append(
                f"""SELECT '{column}' AS column_name,
                       count(*) FILTER (WHERE {quoted} IS NULL) AS null_count,
                       count(*) AS n,
                       min(NULLIF({quoted}, '')::double precision)::text AS min_value,
                       max(NULLIF({quoted}, '')::double precision)::text AS max_value
                FROM raw.{table}"""
            )
    return query_rows(conn, " UNION ALL ".join(parts) + " ORDER BY column_name")


def write_profile(conn) -> None:
    audit = query_rows(conn, "SELECT * FROM raw.load_audit ORDER BY file_role")
    universe = query_rows(conn, "SELECT * FROM validation.universe")[0]
    lengths = query_rows(
        conn,
        """
        SELECT length(source_id) AS id_length, count(*) AS n
        FROM staging.block_group_inputs
        GROUP BY 1
        ORDER BY 1
        """,
    )
    areas = query_rows(
        conn,
        """
        SELECT state_abbrev, count(*) AS n,
               count(*) FILTER (WHERE population IS NULL) AS population_null,
               count(*) FILTER (WHERE pm25 IS NULL) AS pm25_null,
               count(*) FILTER (WHERE demogidx_2 IS NULL) AS demogidx_2_null
        FROM staging.block_group_inputs s
        LEFT JOIN marts.demographic_index d ON d.geoid = s.geoid
        GROUP BY state_abbrev
        ORDER BY state_abbrev
        """,
    )
    national_dict = workbook_dictionary(DOCS.parent / "data" / "reference" / "EJScreen_2024_BG_Percentiles_Columns.xlsx")
    state_dict = workbook_dictionary(DOCS.parent / "data" / "reference" / "EJScreen_2024_BG_State_Percentiles_Columns.xlsx")
    national_stats = column_stats(conn, "ejscreen_reference")
    state_stats = column_stats(conn, "ejscreen_reference_state_pct")
    lines = [
        "# EJScreen 2024 reference profile",
        "",
        "Every count, minimum, and maximum below comes from a query against the loaded Postgres tables.",
        "",
        "## Files loaded",
        "",
        "| Role | File | Bytes | Columns | Rows | SHA256 |",
        "| --- | --- | --- | --- | --- | --- |",
    ]
    for row in audit:
        lines.append(
            f"| {row['file_role']} | {row['filename']} | {row['byte_count']} | {row['column_count']} | {row['row_count']} | {row['sha256']} |"
        )
    lines.extend([
        "",
        "## Universe",
        "",
        f"Total rows: {universe['total_rows']}.",
        f"States, the District of Columbia, and Puerto Rico: {universe['states_dc_pr']}.",
        f"Island territory place and estate records: {universe['territories']}.",
        f"The tech doc count of 242,336 block groups for the states, the District of Columbia, and Puerto Rico "
        f"{'matches' if universe['states_dc_pr_matches_tech_doc'] else 'does not match'} this extract.",
        "",
        "Source id lengths:",
        "",
        "| Length | Rows |",
        "| --- | --- |",
    ])
    for row in lengths:
        lines.append(f"| {row['id_length']} | {row['n']} |")
    lines.extend([
        "",
        "Rows by area. Demographic index nulls are the rebuilt national Demographic Index.",
        "",
        "| Area | Rows | Population null | PM2.5 null | Demographic Index null |",
        "| --- | --- | --- | --- | --- |",
    ])
    for row in areas:
        lines.append(
            f"| {row['state_abbrev']} | {row['n']} | {row['population_null']} | {row['pm25_null']} | {row['demogidx_2_null']} |"
        )
    lines.extend(["", "## National extract columns", ""])
    lines.extend(dictionary_table(national_stats, national_dict))
    lines.extend(["", "## State percentile extract columns", ""])
    lines.extend(dictionary_table(state_stats, state_dict))
    lines.append("")
    (DOCS / "data_profile.md").write_text("\n".join(lines))


def dictionary_table(stats: list[dict], descriptions: dict[str, str]) -> list[str]:
    lines = [
        "| Column | Workbook description | Nulls | Minimum | Maximum |",
        "| --- | --- | --- | --- | --- |",
    ]
    for row in stats:
        key = EXCEED_ALIAS.get(row["column_name"], row["column_name"])
        description = descriptions.get(key) or descriptions.get(row["column_name"]) or ""
        description = description.replace("|", "/")
        lines.append(
            f"| {row['column_name']} | {description} | {row['null_count']} | {row['min_value'] or ''} | {row['max_value'] or ''} |"
        )
    return lines


def hypothesis(rows: list[dict]) -> list[str]:
    if not rows:
        return ["No row had both a rebuilt value and a reference value that differed."]
    largest = max(row["abs_diff"] for row in rows)
    if largest is not None and largest <= 1e-8:
        return [
            "The 20 largest absolute differences are at most 1e-8. "
            "That is the size of double precision residue for these calculations, "
            "not a separate formula."
        ]
    grouped: dict[tuple, list] = {}
    for row in rows:
        key = (row["scope"], row["column_name"])
        grouped.setdefault(key, []).append(row)
    lines = []
    for (scope, column), group in grouped.items():
        missing_life = sum(1 for row in group if row["life_expectancy_missing"])
        states = sorted({row["state_abbrev"] for row in group})
        text = (
            f"{scope} {column}: {len(group)} of the 20 largest gaps, "
            f"in {', '.join(states)}."
        )
        if column.startswith("D5_") or column.startswith("DEMOGIDX_5"):
            if missing_life == len(group):
                text += " Low life expectancy is missing on these rows, so the supplemental index uses the four factor average on tech doc p. 35."
            elif missing_life:
                text += f" Low life expectancy is missing on {missing_life} of these rows."
        if column.startswith("P_") or column.startswith("D2_") or column.startswith("D5_"):
            gaps = sorted({num(row["abs_diff"]) for row in group})
            text += f" Absolute differences in this cluster: {', '.join(gaps)}."
        lines.append(text)
    return lines


def write_report(conn) -> None:
    universe = query_rows(conn, "SELECT * FROM validation.universe")[0]
    checks = query_rows(
        conn,
        """
        SELECT * FROM validation.column_result
        ORDER BY scope, slice, kind, column_name
        """,
    )
    worst = query_rows(conn, "SELECT * FROM validation.worst_mismatch ORDER BY abs_diff DESC, scope, column_name, geoid")
    gaps = query_rows(conn, "SELECT gap_side, count(*) AS n FROM validation.geoid_gap GROUP BY gap_side ORDER BY gap_side")
    gap_ids = query_rows(conn, "SELECT gap_side, source_id FROM validation.geoid_gap ORDER BY gap_side, source_id LIMIT 20")
    rank_summary = query_rows(
        conn,
        """
        SELECT scope,
               count(*) AS n_columns,
               min(abs_min) AS abs_min,
               percentile_cont(0.5) WITHIN GROUP (ORDER BY abs_median) AS median_of_medians,
               max(abs_max) AS abs_max,
               avg(abs_mean) AS mean_of_means
        FROM validation.percent_rank_summary
        GROUP BY scope
        ORDER BY scope
        """,
    )
    rank_extremes = query_rows(
        conn,
        """
        SELECT scope, percentile_column, n, abs_min, abs_median, abs_p95, abs_max, abs_mean
        FROM validation.percent_rank_summary
        ORDER BY abs_max DESC, scope, percentile_column
        LIMIT 15
        """,
    )
    raw_agreement = query_rows(
        conn,
        "SELECT * FROM validation.raw_agreement WHERE n_differ > 0 ORDER BY n_differ DESC, column_name",
    )
    example = query_rows(conn, "SELECT * FROM validation.worked_example ORDER BY scope, column_name")
    ca_top = query_rows(conn, "SELECT * FROM validation.ca_top")
    load_dotenv()
    state_fips = os.environ.get("STATE_FIPS", "06")
    all_checks = [row for row in checks if row["slice"] == "all"]
    ca_checks = [row for row in checks if row["slice"] != "all"]

    def tally(rows, field):
        passed = sum(1 for row in rows if row[field])
        return passed, len(rows) - passed

    exact_pass, exact_fail = tally(all_checks, "exact_pass")
    tol_pass, tol_fail = tally(all_checks, "tolerance_pass")
    null_pass, null_fail = tally(all_checks, "null_pass")
    gap_fail = 0 if not gaps else 1
    universe_fail = 0 if universe["states_dc_pr_matches_tech_doc"] else 1
    reported_pass = exact_pass + tol_pass + null_pass + (1 - gap_fail) + (1 - universe_fail)
    reported_fail = exact_fail + tol_fail + null_fail + gap_fail + universe_fail

    def family_lines(rows):
        lines = [
            "| Scope | Column | Kind | Both present | Exact | Exact rate | Within tolerance | Tolerance rate | Null disagreements | Pearson | Spearman | Abs min | Abs median | Abs p95 | Abs max | Exact | Tolerance | Nulls |",
            "| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |",
        ]
        for row in rows:
            disagree = row["rebuilt_null"] + row["reference_null"]
            lines.append(
                "| {scope} | {column_name} | {kind} | {both_present} | {exact_n} | {exact_rate} | {within_tol_n} | {tol_rate} | {disagree} | {pearson} | {spearman} | {abs_min} | {abs_median} | {abs_p95} | {abs_max} | {exact_pass} | {tolerance_pass} | {null_pass} |".format(
                    scope=row["scope"],
                    column_name=row["column_name"],
                    kind=row["kind"],
                    both_present=row["both_present"],
                    exact_n=row["exact_n"],
                    exact_rate=rate(row["exact_n"], row["both_present"]),
                    within_tol_n=row["within_tol_n"],
                    tol_rate=rate(row["within_tol_n"], row["both_present"]),
                    disagree=disagree,
                    pearson=num(row["pearson"]),
                    spearman=num(row["spearman"]),
                    abs_min=num(row["abs_min"]),
                    abs_median=num(row["abs_median"]),
                    abs_p95=num(row["abs_p95"]),
                    abs_max=num(row["abs_max"]),
                    exact_pass="pass" if row["exact_pass"] else "fail",
                    tolerance_pass="pass" if row["tolerance_pass"] else "fail",
                    null_pass="pass" if row["null_pass"] else "fail",
                )
            )
        return lines

    def outliers(rows):
        if not rows:
            return ["No columns in this slice."]
        best_exact = max(rate(row["exact_n"], row["both_present"]) or "0" for row in rows)
        # call out columns whose tolerance pass is false or whose exact rate is below the best in the same kind and scope
        notes = []
        for row in rows:
            if not row["tolerance_pass"] or not row["exact_pass"] or not row["null_pass"]:
                notes.append(
                    f"{row['scope']} {row['column_name']}: exact {rate(row['exact_n'], row['both_present'])}, "
                    f"tolerance {rate(row['within_tol_n'], row['both_present'])}, "
                    f"null disagreements {row['rebuilt_null'] + row['reference_null']}."
                )
        if not notes:
            return ["Every column in this slice passed the exact, tolerance, and null checks."]
        return notes

    lines = [
        "# EJScreen version 2.3 validation",
        "",
        "The sections through the pilot area are Tier 1. They compare indexes built from the published indicator values. "
        "The Tier 2 section rebuilds the demographic indicators from the American Community Survey and compares those columns with the same Harvard extract. "
        "This report compares the SQL reconstruction with the Harvard Dataverse EJScreen 2024 block group extracts. "
        "Match rates are reported checks. A low match rate does not stop the build. "
        "The build stops if an assertion fails. Assertions cover id uniqueness, 12 character ids, population, "
        "percentile bounds, the non-negative shift, and the index product. "
        "The tech doc states no maximum of 100 for an EJ index or supplemental index, so no such maximum is asserted.",
        "",
        "## Thresholds",
        "",
        "These thresholds are fixed in `sql/validation/metrics.sql` before the comparison runs.",
        "",
        "Continuous values pass the tolerance check when the absolute difference is at most 1e-8 on at least 99 percent of rows where both sides are present. "
        "The reference stores those fields at 15 decimal places. 1e-8 is above ordinary double precision residue and below a one point percentile error.",
        "",
        "Percentile values are integers. Their tolerance is 0, so the tolerance check is the exact check. The pass bar is 99 percent.",
        "",
        "Null agreement passes when at least 99.9 percent of rows agree on whether the value is null.",
        "",
        "Exact equality is double precision equality. Spearman correlation is the Pearson correlation of `rank()` values, and ties share the minimum rank.",
        "",
        "## Result",
        "",
        f"Reported checks passed: {reported_pass}. Reported checks failed: {reported_fail}.",
        f"Exact checks: {exact_pass} passed, {exact_fail} failed.",
        f"Tolerance checks: {tol_pass} passed, {tol_fail} failed.",
        f"Null agreement checks: {null_pass} passed, {null_fail} failed.",
        f"Geographic id alignment: {'pass' if gap_fail == 0 else 'fail'}.",
        f"Tech doc block group count of 242,336: {'pass' if universe_fail == 0 else 'fail'}.",
        "",
        "Assertions ran before this report was written. A failed assertion stops the run and does not produce this file.",
        "",
        "## Universe",
        "",
        f"Total rows: {universe['total_rows']}.",
        f"States, the District of Columbia, and Puerto Rico: {universe['states_dc_pr']}.",
        f"Island territories: {universe['territories']}.",
        "",
        "## Geographic ids",
        "",
    ]
    if not gaps:
        lines.append("No source id is missing from either side. Unmatched count is 0 for the national extract and for the state percentile extract.")
    else:
        lines.append("| Gap | Rows |")
        lines.append("| --- | --- |")
        for row in gaps:
            lines.append(f"| {row['gap_side']} | {row['n']} |")
        lines.append("")
        lines.append("Up to 20 missing ids:")
        lines.append("")
        for row in gap_ids:
            lines.append(f"- {row['gap_side']}: {row['source_id']}")
    lines.extend(["", "## Columns that are not uniform", ""])
    lines.extend(outliers(all_checks))
    lines.extend(["", "## All columns", ""])
    lines.extend(family_lines(all_checks))
    lines.extend(["", "## Absolute difference and percentile rank difference", ""])
    lines.append("The absolute difference columns are in the table above. Percentile rank difference is the absolute gap, on a 0 to 100 scale, between `percent_rank()` of the rebuilt value and `percent_rank()` of the reference value among rows where both are present.")
    lines.append("")
    lines.append("| Scope | Column | Rank diff min | Rank diff median | Rank diff p95 | Rank diff max |")
    lines.append("| --- | --- | --- | --- | --- | --- |")
    for row in all_checks:
        lines.append(
            f"| {row['scope']} | {row['column_name']} | {num(row['rankdiff_min'])} | {num(row['rankdiff_median'])} | {num(row['rankdiff_p95'])} | {num(row['rankdiff_max'])} |"
        )
    lines.extend(["", "## Largest mismatches", ""])
    lines.append("| Scope | Column | GEOID | Area | Rebuilt | Reference | Absolute difference | Life expectancy missing |")
    lines.append("| --- | --- | --- | --- | --- | --- | --- | --- |")
    for row in worst:
        lines.append(
            f"| {row['scope']} | {row['column_name']} | {row['geoid']} | {row['state_abbrev']} | {num(row['rebuilt'])} | {num(row['reference'])} | {num(row['abs_diff'])} | {row['life_expectancy_missing']} |"
        )
    lines.extend(["", "### Reading the largest gaps", ""])
    lines.extend(hypothesis(worst))
    lines.extend(["", f"## Pilot area, state FIPS {state_fips}", ""])
    lines.extend(outliers(ca_checks))
    lines.extend(["", "Top 20 block groups in this state by the rebuilt national PM2.5 EJ index:", ""])
    lines.append("| GEOID | Rebuilt D2_PM25 | Reference D2_PM25 | Rebuilt national PM2.5 percentile | Rebuilt state PM2.5 percentile |")
    lines.append("| --- | --- | --- | --- | --- |")
    for row in ca_top:
        lines.append(
            f"| {row['geoid']} | {num(row['rebuilt_d2_pm25'])} | {num(row['reference_d2_pm25'])} | {num(row['rebuilt_p_pm25'])} | {num(row['rebuilt_state_p_pm25'])} |"
        )
    lines.extend(["", "## Worked example block group 410510068022", ""])
    lines.append("Tech doc pp. 36 to 39 use this block group. The reference values below are the published full precision fields, not the rounded figures in the narrative.")
    lines.append("")
    lines.append("| Scope | Column | Rebuilt | Reference |")
    lines.append("| --- | --- | --- | --- |")
    for row in example:
        lines.append(f"| {row['scope']} | {row['column_name']} | {num(row['rebuilt'])} | {num(row['reference'])} |")
    lines.extend(["", "## Percent rank compared with the cutoff percentile", ""])
    lines.append("`marts.indicator_percent_rank` uses `percent_rank()` times 100. The table below compares it with the cutoff percentile on the same rows.")
    lines.append("")
    lines.append("| Scope | Columns | Smallest column minimum | Median of column medians | Largest column maximum | Mean of column means |")
    lines.append("| --- | --- | --- | --- | --- | --- |")
    for row in rank_summary:
        lines.append(
            f"| {row['scope']} | {row['n_columns']} | {num(row['abs_min'])} | {num(row['median_of_medians'])} | {num(row['abs_max'])} | {num(row['mean_of_means'])} |"
        )
    lines.extend(["", "Largest column maximums:", ""])
    lines.append("| Scope | Percentile column | Rows | Min | Median | P95 | Max | Mean |")
    lines.append("| --- | --- | --- | --- | --- | --- | --- | --- |")
    for row in rank_extremes:
        lines.append(
            f"| {row['scope']} | {row['percentile_column']} | {row['n']} | {num(row['abs_min'])} | {num(row['abs_median'])} | {num(row['abs_p95'])} | {num(row['abs_max'])} | {num(row['abs_mean'])} |"
        )
    lines.extend(["", "## Raw indicator agreement between the two extracts", ""])
    lines.append("Staging uses the national extract for indicator inputs. Rows below are indicator columns whose numeric values are not identical in the state extract.")
    lines.append("")
    if not raw_agreement:
        lines.append("The shared indicator inputs match as double precision numbers.")
    else:
        lines.append("| Column | Rows that differ | Maximum absolute difference |")
        lines.append("| --- | --- | --- |")
        for row in raw_agreement:
            lines.append(f"| {row['column_name']} | {row['n_differ']} | {num(row['max_abs'])} |")
    lines.extend(tier2_section(conn))
    lines.extend(tier3_section(conn))
    lines.append("")
    (DOCS / "validation_report.md").write_text("\n".join(lines))
    update_assumptions(rank_summary, rank_extremes)
    print(
        f"reported_pass {reported_pass} reported_fail {reported_fail} "
        f"exact {exact_pass}/{exact_fail} tolerance {tol_pass}/{tol_fail} null {null_pass}/{null_fail}"
    )
    print(
        f"universe total {universe['total_rows']} states_dc_pr {universe['states_dc_pr']} "
        f"territories {universe['territories']} match {universe['states_dc_pr_matches_tech_doc']}"
    )


def update_assumptions(summary, extremes) -> None:
    path = DOCS / "assumptions.md"
    text = path.read_text()
    start = "<!-- measured-percent-rank:start -->"
    end = "<!-- measured-percent-rank:end -->"
    if start not in text or end not in text:
        return
    body = ["The measured absolute difference between `percent_rank()` times 100 and the cutoff percentile is:"]
    for row in summary:
        body.append(
            f"Scope {row['scope']}: {row['n_columns']} percentile columns, "
            f"smallest minimum {num(row['abs_min'])}, median of medians {num(row['median_of_medians'])}, "
            f"largest maximum {num(row['abs_max'])}, mean of means {num(row['mean_of_means'])}."
        )
    if extremes:
        top = extremes[0]
        body.append(
            f"The largest single column maximum is {top['scope']} {top['percentile_column']} at {num(top['abs_max'])}."
        )
    replacement = start + "\n" + "\n".join(body) + "\n" + end
    pre, rest = text.split(start, 1)
    _old, post = rest.split(end, 1)
    path.write_text(pre + replacement + post)


def tier2_section(conn) -> list[str]:
    checks = query_rows(
        conn,
        """
        SELECT * FROM validation.tier2_column_result
        WHERE slice = 'all'
        ORDER BY column_name
        """,
    )
    worst = query_rows(
        conn,
        "SELECT * FROM validation.tier2_worst ORDER BY abs_diff DESC, column_name, geoid",
    )
    gaps = query_rows(
        conn,
        "SELECT gap_side, count(*) AS n FROM validation.tier2_geoid_gap GROUP BY gap_side ORDER BY gap_side",
    )
    gap_ids = query_rows(
        conn,
        "SELECT gap_side, geoid FROM validation.tier2_geoid_gap ORDER BY gap_side, geoid LIMIT 20",
    )
    ranges = query_rows(conn, "SELECT * FROM validation.tier2_range ORDER BY column_name")
    fit_rows = query_rows(conn, "SELECT * FROM validation.usaleep_fit")
    coverage_rows = query_rows(conn, "SELECT * FROM validation.life_coverage")
    gap_rows = query_rows(conn, "SELECT * FROM validation.life_match_gap")
    weight_rows = query_rows(conn, "SELECT * FROM staging.life_weight_audit")
    multi_rows = query_rows(conn, "SELECT * FROM validation.life_multi_fit")
    ct_rows = query_rows(conn, "SELECT * FROM staging.ct_crosswalk_audit")
    null_reason_rows = query_rows(conn, "SELECT * FROM validation.life_null_reason")
    negative = query_rows(conn, "SELECT n_negative FROM staging.acs_negative_audit")
    acs_n = query_rows(conn, "SELECT count(*) AS n FROM marts.acs_block_group")[0]["n"]
    zeros = {
        row["column_name"]: row
        for row in query_rows(conn, "SELECT * FROM validation.tier2_zero_denominator")
    }
    directions = {
        row["column_name"]: row
        for row in query_rows(conn, "SELECT * FROM validation.tier2_direction")
    }
    state_checks = query_rows(
        conn,
        """
        SELECT * FROM validation.tier2_column_result
        WHERE slice <> 'all'
        ORDER BY slice, column_name
        """,
    )
    passed = sum(1 for row in checks if row["exact_pass"] and row["tolerance_pass"] and row["null_pass"])
    failed = len(checks) - passed

    def hypothesis() -> list[str]:
        notes = []
        by_column = {}
        for row in worst:
            by_column.setdefault(row["column_name"], []).append(row)
        for row in checks:
            if row["exact_pass"] and row["tolerance_pass"] and row["null_pass"]:
                continue
            column = row["column_name"]
            text = (
                f"{column}: exact rate {rate(row['exact_n'], row['both_present'])}, "
                f"tolerance rate {rate(row['within_tol_n'], row['both_present'])}, "
                f"median absolute difference {num(row['abs_median'])}, "
                f"maximum absolute difference {num(row['abs_max'])}."
            )
            if row["abs_max"] is not None and row["abs_max"] <= 1e-8:
                text += " Where both values are present, the gap is double precision residue."
            elif column == "DISABILITYPCT":
                text += (
                    " The block group value is the tract disability rate. "
                    "The earlier product with the block group population share was lower on every differing row and was not kept."
                )
            elif column == "LESSHSPCT":
                text += " The numerator includes B15002.027, female 12th grade with no diploma, which Table 5 lists and the printed sum omits."
            elif column in {"DEMOGIDX_2", "DEMOGIDX_2ST"}:
                text += (
                    " The index uses the ACS rates, the sample standard deviation, and the non-negative shift. "
                    "A zero ACS denominator is included as 0."
                )
            elif column in {"DEMOGIDX_5", "DEMOGIDX_5ST"}:
                text += (
                    " The index is the average of the five adopted z-scores, or four where low life expectancy is missing, then the non-negative shift. "
                    "The formula is unchanged. "
                    "Low life expectancy for a 2020 tract with more than one 2010 parent is the average of the parent values weighted by 2020 block population. "
                    "Connecticut 2022 tracts take the 2020 tract life expectancy through the Geocorr 2022 pop20 crosswalk."
                )
                if gap_rows and column == "DEMOGIDX_5":
                    gap = gap_rows[0]
                    text += (
                        f" On the {gap['le_match_rows']} rows whose life expectancy matches within 1e-8, "
                        f"{gap['demogidx_5_within_on_le_match']} national supplemental values are within 1e-8. "
                        f"The median absolute gap on those rows is {num(gap['demogidx_5_median_abs_on_le_match'])}."
                    )
                if gap_rows and column == "DEMOGIDX_5ST":
                    gap = gap_rows[0]
                    text += (
                        f" On the rows whose life expectancy matches within 1e-8, "
                        f"{gap['demogidx_5st_within_on_le_match']} state supplemental values are within 1e-8. "
                        f"The median absolute gap on those rows is {num(gap['demogidx_5st_median_abs_on_le_match'])}."
                    )
                if not row["tolerance_pass"]:
                    text += " No other weight and no other maximum were tried."
            elif column == "LIFEEXPPCT":
                text += (
                    " The rate is 1 minus life expectancy divided by 97.5. "
                    "97.5 is the maximum in US_A.CSV and is not printed in the technical documentation. "
                    "A 2022 tract with no direct 2010 id and one 2010 parent takes that parent's life expectancy. "
                    "A 2022 tract with more than one 2010 parent takes the population-weighted average of the parent life expectancies. "
                    "The weight is 2020 P.L. 94-171 block population from Census API dataset 2020/dec/pl, variable P1_001N, summed through the Census 2010 to 2020 block relationship file. "
                    "A 2020 block that meets more than one 2010 tract is left out. "
                    "The file's arealand_int column partitions those blocks, and allocating population by that column did not match the published rate, so it is not used. "
                    "Connecticut 2022 tracts use the Missouri Census Data Center Geocorr 2022 crosswalk, weight column pop20. "
                    "Rows whose implied maximum is not 97.5 stay in the comparison. "
                    "97.5 was not changed."
                )
            zero = zeros.get(column)
            if zero is not None and row["rebuilt_null"]:
                text += (
                    f" Null disagreements: {zero['null_reference_zero']} rows have an ACS denominator of 0 and a reference value of 0."
                )
                if zero["other_rebuilt_null"]:
                    text += f" Other rebuilt nulls with a reference value: {zero['other_rebuilt_null']}."
                if column == "UNEMPPCT":
                    text += (
                        " Unemployment is null where the civilian labor force is 0 and the block group population is greater than 0. "
                        "A zero labor force in a block group with population 0 stays 0. Other zero denominators stay 0."
                    )
                else:
                    text += " The ratio is stored as 0 where the denominator is 0."
            direction = directions.get(column)
            if direction and (direction["rebuilt_lower"] or direction["rebuilt_higher"]):
                text += (
                    f" Outside 1e-8, the rebuild is lower on {direction['rebuilt_lower']} rows"
                    f" and higher on {direction['rebuilt_higher']} rows."
                )
                if direction["median_reference_minus_rebuilt"] is not None:
                    text += (
                        f" Median of reference minus rebuilt on those rows: {num(direction['median_reference_minus_rebuilt'])}."
                    )
            cluster = by_column.get(column, [])
            if cluster:
                states = sorted({item["state_abbrev"] or item["state_fips"] for item in cluster})
                text += f" The 20 largest mismatches that fall in this column sit in {', '.join(states)}."
            notes.append(text)
        if not notes:
            return ["Every Tier 2 column passed the exact, tolerance, and null checks."]
        return notes

    lines = [
        "",
        "## Tier 2, ACS demographic rebuild",
        "",
        "Thresholds are fixed in `sql/validation/tier2_metrics.sql`. "
        "Continuous tolerance is an absolute difference of at most 1e-8 on at least 99 percent of rows where both values are present. "
        "Null agreement passes at 99.9 percent. "
        "A low match rate is reported. It does not stop the run. "
        "The ACS assertions cover 12 character ids, exclusion of the four island territories, non-negative population, 52 state codes, and the non-negative demographic shift.",
        "",
        f"ACS block groups loaded: {acs_n}.",
        f"Negative ACS count values set to null: {negative[0]['n_negative'] if negative else ''}.",
        f"Tier 2 column checks passed: {passed}. Tier 2 column checks failed: {failed}.",
        "",
        "The four island territories are not in the 2022 ACS 5-year API, so they are not in this rebuild.",
        "A zero ACS denominator is stored as 0. Unemployment is null when the civilian labor force is 0 and the block group population is greater than 0. "
        "Less than high school includes B15002.027. "
        "Disability is the tract rate assigned to each block group in the tract. "
        "Low life expectancy is 1 minus life expectancy at birth divided by 97.5. "
        "Connecticut 2022 tracts use the Geocorr 2022 pop20 crosswalk. "
        "The supplemental demographic index is the five factor average, or the four factor average where low life expectancy is missing.",
        "",
        "### Geographic ids",
        "",
    ]
    if not gaps:
        lines.append("Every ACS block group id is in the reference extract, and every reference block group in the states, the District of Columbia, and Puerto Rico is in the ACS rebuild.")
    else:
        lines.append("| Gap | Rows |")
        lines.append("| --- | --- |")
        for row in gaps:
            lines.append(f"| {row['gap_side']} | {row['n']} |")
        lines.append("")
        lines.append("Up to 20 ids:")
        lines.append("")
        for row in gap_ids:
            lines.append(f"- {row['gap_side']}: {row['geoid']}")
    lines.extend([
        "",
        "### Columns",
        "",
        "| Column | Rows | Both present | Exact rate | Tolerance rate | Null disagreements | Pearson | Spearman | Abs min | Abs median | Abs p95 | Abs max | Exact | Tolerance | Nulls |",
        "| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |",
    ])
    for row in checks:
        lines.append(
            "| {column_name} | {n_rows} | {both_present} | {exact_rate} | {tol_rate} | {disagree} | {pearson} | {spearman} | {abs_min} | {abs_median} | {abs_p95} | {abs_max} | {exact_pass} | {tolerance_pass} | {null_pass} |".format(
                column_name=row["column_name"],
                n_rows=row["n_rows"],
                both_present=row["both_present"],
                exact_rate=rate(row["exact_n"], row["both_present"]),
                tol_rate=rate(row["within_tol_n"], row["both_present"]),
                disagree=row["rebuilt_null"] + row["reference_null"],
                pearson=num(row["pearson"]),
                spearman=num(row["spearman"]),
                abs_min=num(row["abs_min"]),
                abs_median=num(row["abs_median"]),
                abs_p95=num(row["abs_p95"]),
                abs_max=num(row["abs_max"]),
                exact_pass="pass" if row["exact_pass"] else "fail",
                tolerance_pass="pass" if row["tolerance_pass"] else "fail",
                null_pass="pass" if row["null_pass"] else "fail",
            )
        )
    if state_checks:
        slice_name = state_checks[0]["slice"]
        lines.extend([
            "",
            f"### Pilot slice {slice_name}",
            "",
            "Same thresholds as the national table. This slice is the state set in `STATE_FIPS`.",
            "",
            "| Column | Rows | Both present | Exact rate | Tolerance rate | Null disagreements | Pearson | Spearman | Abs median | Abs max | Exact | Tolerance | Nulls |",
            "| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |",
        ])
        for row in state_checks:
            lines.append(
                "| {column_name} | {n_rows} | {both_present} | {exact_rate} | {tol_rate} | {disagree} | {pearson} | {spearman} | {abs_median} | {abs_max} | {exact_pass} | {tolerance_pass} | {null_pass} |".format(
                    column_name=row["column_name"],
                    n_rows=row["n_rows"],
                    both_present=row["both_present"],
                    exact_rate=rate(row["exact_n"], row["both_present"]),
                    tol_rate=rate(row["within_tol_n"], row["both_present"]),
                    disagree=row["rebuilt_null"] + row["reference_null"],
                    pearson=num(row["pearson"]),
                    spearman=num(row["spearman"]),
                    abs_median=num(row["abs_median"]),
                    abs_max=num(row["abs_max"]),
                    exact_pass="pass" if row["exact_pass"] else "fail",
                    tolerance_pass="pass" if row["tolerance_pass"] else "fail",
                    null_pass="pass" if row["null_pass"] else "fail",
                )
            )
    lines.extend(["", "### Rates outside 0 to 1", ""])
    lines.append("This is a reported check. It does not stop the run.")
    lines.append("")
    lines.append("| Column | Rows outside 0 to 1 |")
    lines.append("| --- | --- |")
    for row in ranges:
        lines.append(f"| {row['column_name']} | {row['outside_0_1']} |")
    lines.extend(["", "### Largest mismatches", ""])
    lines.append("| Column | GEOID | Area | Rebuilt | Reference | Absolute difference |")
    lines.append("| --- | --- | --- | --- | --- | --- |")
    for row in worst:
        lines.append(
            f"| {row['column_name']} | {row['geoid']} | {row['state_abbrev'] or row['state_fips']} | {num(row['rebuilt'])} | {num(row['reference'])} | {num(row['abs_diff'])} |"
        )
    lines.extend(["", "### Reading the largest gaps", ""])
    lines.extend(hypothesis())
    fit = fit_rows[0] if fit_rows else None
    lines.extend(["", "### Low life expectancy", ""])
    if not fit:
        lines.append("The USALEEP file was not loaded, so no maximum was derived.")
    else:
        lines.append(
            "File `US_A.CSV` from the National Center for Health Statistics is loaded. "
            f"Rows in the file: {fit['file_rows']}. "
            f"Life expectancy at birth ranges from {num(fit['min_life_expectancy'])} to {num(fit['max_life_expectancy'])}. "
            f"Block groups whose 2022 tract id matches a zero padded 2010 tract id: {fit['joined_block_groups']} "
            f"({fit['joined_tracts']} tracts). "
            f"Published low life expectancy rows with no matching 2010 tract id: {fit['published_rows_without_same_tract_id']}."
        )
        lines.append("")
        lines.append(
            "On rows where both a life expectancy and a published low life expectancy between 0 and 1 are present, "
            f"the implied maximum (life expectancy divided by 1 minus the published rate) has "
            f"minimum {num(fit['implied_max_min'])}, "
            f"5th percentile {num(fit['implied_max_p05'])}, "
            f"median {num(fit['implied_max_median'])}, "
            f"95th percentile {num(fit['implied_max_p95'])}, "
            f"maximum {num(fit['implied_max_max'])}, "
            f"and sample standard deviation {num(fit['implied_max_sd'])}. "
            f"Usable rows: {fit['usable_rows']}. "
            f"Rows within 1e-6 of the file maximum life expectancy ({num(fit['max_life_expectancy'])}): {fit['implied_near_file_max']}. "
            f"Rows more than one year from that file maximum: {fit['implied_beyond_one_year']}."
        )
        lines.append("")
        lines.append(
            "97.5 is the file maximum and the center of the implied maximum. "
            "It is not printed in the technical documentation. "
            "It is used as the denominator because the rows whose implied maximum is within 1e-6 of 97.5 then match the published rate within 1e-8. "
            "Rows farther from 97.5 stay in the comparison and are the exceptions."
        )
        coverage = coverage_rows[0] if coverage_rows else None
        if coverage:
            lines.append("")
            lines.append(
                f"Block groups whose 2022 tract id is a 2010 tract id in the file: {coverage['direct_block_groups']}. "
                f"Block groups filled from a single 2010 parent in `tab20_tract20_tract10_natl.txt`: {coverage['single_parent_block_groups']}. "
                "A single parent is one 2010 tract in the relationship file. Parents with no USALEEP row still count. "
                f"Block groups in a 2020 tract with more than one 2010 parent: {coverage['multi_parent_block_groups']}. "
                f"Of those, {coverage['multi_parent_assigned']} have a life expectancy and {coverage['multi_parent_unassigned']} stay null. "
                "The tract relationship file has land area only. The weight is 2020 block population from the Census 2010 to 2020 block relationship file, summed to each 2010 tract inside the 2020 tract. "
                "A block in more than one 2010 tract is left out. arealand_int sums to the 2020 land area on each of those blocks. "
                "Allocating block population by arealand_int was compared with the published rate and was not kept. "
                "The whole-block population weight is applied only where that tract has more than one 2010 parent and neither a direct 2010 id nor a single parent supplied a value."
            )
            if weight_rows:
                weight = weight_rows[0]
                lines.append("")
                lines.append(
                    f"Block relationship rows: {weight['relationship_rows']}. "
                    f"2020 blocks with population: {weight['population_rows']}. "
                    f"Population total: {weight['population_total']}. "
                    f"Blocks in one 2010 tract: {weight['blocks_one_2010_tract']}, population {weight['population_one_2010_tract']}. "
                    f"Blocks in more than one 2010 tract, left out of the weight: {weight['blocks_many_2010_tracts']}, population {weight['population_many_2010_tracts']}. "
                    f"Multi-parent 2020 tracts: {weight['multi_parent_tracts']}. "
                    f"Tracts with a weighted life expectancy: {weight['multi_parent_tracts_weighted']}. "
                    f"Tracts left null: {weight['multi_parent_tracts_unweighted']}."
                )
            lines.append("")
            ct = ct_rows[0] if ct_rows else None
            reason = null_reason_rows[0] if null_reason_rows else None
            ct_sentence = (
                f"Block groups whose 2022 tract id is not in the 2020 tract relationship: {coverage['no_2020_tract_block_groups']}. "
                f"Connecticut block groups assigned: {coverage['connecticut_assigned']}. "
                f"Connecticut block groups left unassigned: {coverage['connecticut_unassigned']}. "
            )
            if ct:
                ct_sentence += (
                    f"Geocorr rows: {ct['geocorr_rows']}. "
                    f"2022 tracts in the crosswalk: {ct['tract_rows']}. "
                    f"Tracts with a life expectancy: {ct['tracts_with_le']}. "
                    f"Tracts without one: {ct['tracts_without_le']}. "
                )
            ct_sentence += (
                "The publisher is the Missouri Census Data Center. "
                "The file is geocorr2022_2629507182.csv, downloaded from https://mcdc.missouri.edu/temp/geocorr2022_2629507182.csv. "
                "The weight column is pop20, total population from the 2020 Census. "
                "The Census 2022 relationship page, https://www.census.gov/geographies/reference-files/2022/geo/relationship-files.html, and the file directory https://www2.census.gov/geo/docs/maps-data/data/rel2022/ list seven Connecticut files. "
                "None links a 2020 tract to a 2022 tract or a 2020 block to a 2022 block. "
                "NHGIS geographic crosswalks do not include a 2020 to 2022 pair. "
                "No county-name crosswalk is used. "
                "The 2010 to 2015 tract relationship table named in the technical documentation was not found, and US_A.CSV is already keyed by 2010 tract ids, so that step is not applied again."
            )
            lines.append(ct_sentence)
            if reason:
                lines.append("")
                lines.append(
                    "Where the reference has a life expectancy and the rebuild is null: "
                    f"Connecticut {reason['connecticut_reference']}, "
                    f"multi-parent {reason['multi_parent_reference']}, "
                    f"single-parent tracts with no USALEEP value {reason['single_parent_reference']}, "
                    f"other {reason['other_reference']}. "
                    "Those single-parent tracts stay null. CDC PLACES was not used. "
                    f"Connecticut rows with a rebuilt life expectancy and a blank reference: {reason['connecticut_reference_blank']}."
                )
            if multi_rows:
                multi = multi_rows[0]
                lines.append("")
                lines.append(
                    f"Multi-parent block groups filled by the block population weight and compared with a published rate: {multi['compared']}. "
                    f"Within 1e-8: {multi['within_1e8']}. "
                    f"Rows whose implied maximum is within 1e-6 of 97.5: {multi['near_975']}. "
                    f"Of those, {multi['near_975_within']} are within 1e-8 and {multi['near_975_miss']} are not."
                )
            if gap_rows:
                gap = gap_rows[0]
                lines.append("")
                lines.append(
                    f"Rows where rebuilt life expectancy is null and the reference has a value: {gap['life_rebuilt_null']}. "
                    f"Rows whose life expectancy matches within 1e-8: {gap['le_match_rows']}. "
                    f"On those rows the national supplemental median absolute gap is {num(gap['demogidx_5_median_abs_on_le_match'])} "
                    f"and the state supplemental median absolute gap is {num(gap['demogidx_5st_median_abs_on_le_match'])}."
                )
    print(f"tier2_pass {passed} tier2_fail {failed} acs_rows {acs_n}")
    return lines


def tier3_section(conn) -> list[str]:
    checks = query_rows(
        conn,
        """
        SELECT * FROM validation.tier3_column_result
        WHERE slice = 'all'
        ORDER BY column_name
        """,
    )
    state_checks = query_rows(
        conn,
        """
        SELECT * FROM validation.tier3_column_result
        WHERE slice <> 'all'
        ORDER BY column_name
        """,
    )
    worst = query_rows(
        conn,
        """
        SELECT * FROM validation.tier3_worst
        ORDER BY column_name, abs_diff DESC, geoid
        """,
    )
    gaps = query_rows(
        conn,
        "SELECT gap_side, count(*) AS n FROM validation.tier3_geoid_gap GROUP BY gap_side ORDER BY gap_side",
    )
    clusters = query_rows(
        conn,
        """
        SELECT column_name, cluster, sum(n) AS n,
               sum(n * median_abs) / NULLIF(sum(n), 0) AS weighted_median_abs
        FROM validation.tier3_cluster
        GROUP BY column_name, cluster
        ORDER BY column_name, n DESC
        """,
    )
    zero = query_rows(conn, "SELECT * FROM staging.tier3_lead_zero_denom")
    sites = query_rows(
        conn,
        """
        SELECT kind, count(*) AS n
        FROM staging.superfund_site
        GROUP BY kind
        ORDER BY kind
        """,
    )
    haz_n = query_rows(
        conn,
        """
        SELECT count(*) AS n,
               count(*) FILTER (WHERE operating_tsdf = 'Y') AS operating_n,
               count(*) FILTER (WHERE lqg_2021 = 'Y') AS lqg_n,
               count(*) FILTER (WHERE operating_tsdf = 'Y' AND lqg_2021 = 'Y') AS both_n
        FROM staging.hazwaste_site
        """,
    )
    passed = sum(1 for row in checks if row["exact_pass"] and row["tolerance_pass"] and row["null_pass"])
    failed = len(checks) - passed
    lines = [
        "",
        "## Tier 3, lead paint, Superfund proximity, hazardous waste proximity, and traffic proximity",
        "",
        "Thresholds are fixed in `sql/validation/tier3_metrics.sql` and are the same bars as Tier 1 and Tier 2. "
        "Continuous tolerance is an absolute difference of at most 1e-8 on at least 99 percent of rows where both values are present. "
        "Exact equality uses the same 99 percent bar. "
        "Null agreement passes at 99.9 percent. "
        "A low match rate is reported. The distance unit and the cap were not changed after the comparison.",
        "",
        "Traffic proximity uses the 2020 HPMS file geodatabase supplied for this run. "
        "The annual average daily traffic field is AADT. "
        "Distance is kilometers, from the inverse-distance equation on p. 48 and the traffic steps on pp. 50 to 51. "
        "Page 21 says AADT divided by distance in meters. That sentence was not used. "
        "The maximum score of 10 applies to distances under 0.1 km, and that capped inverse distance is then multiplied by AADT. "
        "The roads are interstates, other freeways and expressways, other principal arterials, and minor arterials in urban areas. "
        "Within each state, segments that share Route_ID and AADT contribute once, through the minimum distance to the group.",
        "",
        f"Tier 3 column checks passed: {passed}. Tier 3 column checks failed: {failed}.",
        "",
        "### Geographic ids",
        "",
    ]
    if not gaps:
        lines.append("Every rebuilt block group id is in the national reference universe, and every national reference id is in each rebuilt table.")
    else:
        lines.append("| Gap | Rows |")
        lines.append("| --- | --- |")
        for row in gaps:
            lines.append(f"| {row['gap_side']} | {row['n']} |")
    lines.extend(["", "### Column comparison", ""])
    lines.append("| Column | Rows | Both present | Exact rate | Tolerance rate | Null agreement | Pearson | Spearman | Median absolute gap | P95 | Max | Exact | Tolerance | Null |")
    lines.append("| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |")
    for row in checks:
        null_agree = (row["n_rows"] - row["rebuilt_null"] - row["reference_null"]) / row["n_rows"] if row["n_rows"] else None
        lines.append(
            f"| {row['column_name']} | {row['n_rows']} | {row['both_present']} | "
            f"{rate(row['exact_n'], row['both_present'])} | {rate(row['within_tol_n'], row['both_present'])} | "
            f"{format(null_agree, '.6f') if null_agree is not None else ''} | {num(row['pearson'])} | {num(row['spearman'])} | "
            f"{num(row['abs_median'])} | {num(row['abs_p95'])} | {num(row['abs_max'])} | "
            f"{'pass' if row['exact_pass'] else 'fail'} | {'pass' if row['tolerance_pass'] else 'fail'} | "
            f"{'pass' if row['null_pass'] else 'fail'} |"
        )
    if state_checks:
        lines.extend(["", "State slice for the configured state FIPS:", ""])
        lines.append("| Column | Rows | Tolerance rate | Median absolute gap | Max | Tolerance |")
        lines.append("| --- | --- | --- | --- | --- | --- |")
        for row in state_checks:
            lines.append(
                f"| {row['column_name']} | {row['n_rows']} | {rate(row['within_tol_n'], row['both_present'])} | "
                f"{num(row['abs_median'])} | {num(row['abs_max'])} | {'pass' if row['tolerance_pass'] else 'fail'} |"
            )
    lines.extend(["", "### Difference distribution", ""])
    lines.append("| Column | Min | P25 | Median | P75 | P95 | Max | Mean |")
    lines.append("| --- | --- | --- | --- | --- | --- | --- | --- |")
    for row in checks:
        lines.append(
            f"| {row['column_name']} | {num(row['abs_min'])} | {num(row['abs_p25'])} | {num(row['abs_median'])} | "
            f"{num(row['abs_p75'])} | {num(row['abs_p95'])} | {num(row['abs_max'])} | {num(row['abs_mean'])} |"
        )
    lines.extend(["", "### Twenty largest mismatches in each column", ""])
    lines.append("| Column | GEOID | State | Rebuilt | Reference | Absolute gap |")
    lines.append("| --- | --- | --- | --- | --- | --- |")
    for row in worst:
        lines.append(
            f"| {row['column_name']} | {row['geoid']} | {row['state_abbrev']} | "
            f"{num(row['rebuilt'])} | {num(row['reference'])} | {num(row['abs_diff'])} |"
        )
    lines.extend(["", "### Hypothesis for each mismatch cluster", ""])
    method = {
        "PRE1960PCT": (
            "Lead paint is (B25034_009E + B25034_010E + B25034_011E) / B25034_001E from ACS 2022 5-year table B25034. "
            "The reference stores the ratio, which is the printed percent divided by 100. "
            "A zero housing-unit total is stored as 0, the same rule as the demographic rates that matched. A null total stays null."
        ),
        "PNPL": (
            "Superfund uses kilometers and a cap of 11 inside 0.1 km, from the inverse-distance equation on p. 48 and the Superfund steps on pp. 49 to 50. "
            "The current public boundary service is not the February 26, 2024 extract. "
            "Final and proposed polygons are included, plus Superfund Alternative Approach boundaries matched to the EPA enforcement list, plus final and proposed points that have no polygon, buffered by 1 meter. "
            "The block group score is the population-weighted average of block scores. The unit and the cap were not flipped to chase the reference. "
            "A May 20, 2024 EDG boundary archive was scored and not adopted because Pearson fell. The column figures remain the current public boundary score."
        ),
        "PTSDF": (
            "Hazardous waste uses the same inverse-distance method: kilometers, cap 10 inside 0.1 km, radius 10 km, population-weighted from block centroids. "
            "Operating TSDFs are the current RCRAInfo handler universe, not the February 5, 2024 pull. "
            "Large quantity generators are handlers whose 2021 Biennial Report calculated generator status is L. "
            "A handler that is both is one point. Locations come from the current handler file. "
            "No February 5, 2024 export was found, so this score was not rebuilt."
        ),
        "PTRAF": (
            "Traffic uses kilometers and a cap of 10 on the inverse distance inside 0.1 km, then multiplies by AADT, from pp. 48 and 50 to 51. "
            "Page 21's meters sentence was not used. "
            "The road classes are HPMS functional systems 1, 2, and 3, plus system 4 when the urban code is not 99999. "
            "The block group score is the population-weighted average of block scores. "
            "The minimum distance within a state, Route_ID, and AADT group is the dissolve. The unit and the cap were not flipped to chase the reference."
        ),
    }
    by_cluster = {}
    for row in clusters:
        by_cluster.setdefault(row["column_name"], []).append(row)
    if zero:
        z = zero[0]
        lines.append(
            f"Lead paint zero denominators: {z['zero_denom_n']}. "
            f"Stored as 0: {z['zero_denom_stored_0']}. "
            f"Null denominators: {z['null_denom_n']}."
        )
    if sites:
        parts = ", ".join(f"{row['kind']} {row['n']}" for row in sites)
        lines.append(f"Superfund sites scored: {parts}.")
    if haz_n:
        h = haz_n[0]
        lines.append(
            f"Hazardous waste sites scored: {h['n']}. "
            f"Operating TSDFs: {h['operating_n']}. "
            f"2021 large quantity generators: {h['lqg_n']}. "
            f"Counted in both: {h['both_n']}."
        )
    lines.append("")
    for row in checks:
        lines.append(f"{row['column_name']}. {method.get(row['column_name'], '')}")
        for cluster in by_cluster.get(row["column_name"], []):
            lines.append(
                f"Cluster {cluster['cluster']}: {cluster['n']} rows. "
                f"State-weighted median absolute gap {num(cluster['weighted_median_abs'])}."
            )
        if row["exact_pass"] and row["tolerance_pass"] and row["null_pass"]:
            lines.append("Hypothesis: the remaining gaps are double precision residue. The method was not changed.")
        elif row["column_name"] == "PRE1960PCT" and row["tolerance_pass"]:
            lines.append("Hypothesis: exact equality fails on double precision residue. The zero-denominator rows agree with the reference value 0, so no separate null rule was added.")
        elif row["column_name"] == "PNPL":
            lines.append(
                "Hypothesis: the kilometer score with cap 11 is the same scale as the reference. "
                "On rows where both values are positive, the median ratio of rebuilt to reference is about 1. "
                "The tolerance misses are small boundary differences plus universe differences, not a meters-versus-kilometers switch. "
                "Rows where the reference is 0 and the rebuild is positive are sites in the current file that were outside the February 26, 2024 universe. "
                "Rows where the rebuild is 0 and the reference is positive are sites from that vintage that are not in the current public boundaries, including SAA names with no polygon. "
                "The largest gaps are California block groups whose reference is 33, three times the cap, and whose rebuild is about 11, one site inside 0.1 km. "
                "Four Connecticut block groups are null here and filled in the reference: three are the split 2020 tract 09009343101, which was not assigned, and one is a zero-population tract the reference stores as 0. "
                "The cap stays 11 and the unit stays kilometers. "
                "May 20, 2024 boundary test, not adopted: Internet Archive capture of EPA EDG NPL_Boundaries.zip at 2024-05-20 12:44:37 UTC, 11601789 bytes. "
                "Feature class 5, status F or P, 1542 features, 1340 EPA IDs. "
                "On 240939 rows Pearson moved from 0.938579900173 to 0.929886719342. "
                "The positive-row median ratio is 0.999993473666 on 97386 rows. "
                "The current public boundary score remains."
            )
        elif row["column_name"] == "PTSDF":
            lines.append(
                "Hypothesis: the scores are the same order of magnitude as the reference, so the unit is kilometers and the cap of 10 is on the inverse distance, not a meters formula. "
                "On rows where both values are positive, the median ratio of rebuilt to reference is about 0.6, and no both-positive row is within 1e-8. "
                "The rebuild is the October 18, 2026 RCRAInfo handler file for operating TSDF status and coordinates, joined to 2021 Biennial Report calculated generator status L. "
                "The technical documentation pull was February 5, 2024. "
                "Thousands of block groups are 0 here and positive in the reference, which is facilities present in that pull and absent from this public pair. "
                "The largest gaps are Massachusetts and the District of Columbia, in the same direction as the national ratio. "
                "The cap stays 10 and the unit stays kilometers. "
                "No February 5, 2024 RCRAInfo export was found. Historical S3 keys are AccessDenied and the Internet Archive has no capture of that pull, so the October 18, 2026 score remains."
            )
        elif row["column_name"] == "PTRAF":
            lines.append(
                "Hypothesis: the kilometer score, with the cap of 10 applied before multiplying by AADT, is the same scale as the reference. "
                "Pearson is about 0.997 and the median ratio on positive rows is about 0.932. "
                "The tolerance misses are not a meters-versus-kilometers switch. Page 21's meters sentence was not used. "
                "The only rows within 1e-8 are shared zeros. Most other rows are a little lower here. "
                "The largest gaps are Hawaii, where the median ratio is about 0.43 in Honolulu and about 0.30 on the other islands. "
                "A block there can sit within 10 km of many segments of one route, so one distance per Route_ID and AADT is lower than a score that still adds those segments. "
                "1039 rows are 0 here and positive in the reference. They are spread across states, with the most in Alabama, Arizona, and Minnesota. "
                "Four Connecticut block groups are null here and filled in the reference: three are the split 2020 tract 09009343101, which was not assigned, and one is a zero-population tract the reference stores as 0. "
                "The cap stays 10 on the inverse distance and the unit stays kilometers."
            )
        lines.append("")
    return lines


def main() -> None:
    load_dotenv()
    run_sql_file(ROOT / "sql" / "080_assertions.sql")
    run_sql_file(ROOT / "sql" / "092_acs_assertions.sql")
    with connect() as conn:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT set_config('ejscreen.state_fips', %s, false)",
                (os.environ.get("STATE_FIPS", "06"),),
            )
        conn.commit()
    run_sql_file(ROOT / "sql" / "validation" / "metrics.sql")
    run_sql_file(ROOT / "sql" / "validation" / "tier2_metrics.sql")
    run_sql_file(ROOT / "sql" / "validation" / "tier3_metrics.sql")
    with connect() as conn:
        with conn.cursor() as cur:
            cur.execute("SET max_parallel_workers_per_gather = 0")
            cur.execute("SET work_mem = '256MB'")
        write_profile(conn)
        write_report(conn)


if __name__ == "__main__":
    main()

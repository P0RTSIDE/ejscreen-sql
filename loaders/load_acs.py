"""Load downloaded ACS, PL 94-171, and USALEEP files into raw tables."""

import csv
from pathlib import Path

from common import ROOT, connect

CENSUS_DIR = ROOT / "data" / "census"


def header_of(path: Path) -> list[str]:
    with path.open(newline="") as handle:
        return next(csv.reader(handle))


def load_directory(conn, directory: Path, table: str) -> int:
    files = sorted(directory.glob("*.csv"))
    if not files:
        raise SystemExit(f"No CSV files in {directory}")
    header = header_of(files[0])
    for path in files[1:]:
        if header_of(path) != header:
            raise SystemExit(f"Header mismatch in {path.name}")
    quoted = ", ".join('"' + name.replace('"', '""') + '"' for name in header)
    column_defs = ", ".join(
        '"' + name.replace('"', '""') + '" text' for name in header
    )
    with conn.cursor() as cur:
        cur.execute(f"DROP TABLE IF EXISTS {table}")
        cur.execute(f"CREATE TABLE {table} ({column_defs})")
        for path in files:
            with path.open("rb") as handle:
                with cur.copy(
                    f"COPY {table} ({quoted}) FROM STDIN WITH (FORMAT csv, HEADER true, NULL '')"
                ) as copy:
                    copy.write(handle.read())
        cur.execute(f"SELECT count(*) FROM {table}")
        loaded = cur.fetchone()[0]
    conn.commit()
    print(f"{table} rows {loaded} columns {len(header)}", flush=True)
    return loaded


def load_usaleep(conn) -> int:
    path = CENSUS_DIR / "US_A.CSV"
    if not path.exists():
        raise SystemExit("US_A.CSV is not in data/census")
    with conn.cursor() as cur:
        cur.execute("DROP TABLE IF EXISTS raw.usaleep_2010_tract")
        cur.execute(
            """
            CREATE TABLE raw.usaleep_2010_tract (
              tract_id text,
              state2kx text,
              cnty2kx text,
              tract2kx text,
              life_expectancy text,
              life_expectancy_se text,
              abridged_flag text
            )
            """
        )
        with path.open("rb") as handle:
            with cur.copy(
                """
                COPY raw.usaleep_2010_tract
                  (tract_id, state2kx, cnty2kx, tract2kx, life_expectancy, life_expectancy_se, abridged_flag)
                FROM STDIN WITH (FORMAT csv, HEADER true, NULL '')
                """
            ) as copy:
                copy.write(handle.read())
        cur.execute("SELECT count(*) FROM raw.usaleep_2010_tract")
        loaded = cur.fetchone()[0]
    conn.commit()
    print(f"raw.usaleep_2010_tract rows {loaded}", flush=True)
    return loaded


def load_tract_relationship(conn) -> int:
    path = CENSUS_DIR / "relationship" / "tab20_tract20_tract10_natl.txt"
    if not path.exists():
        raise SystemExit("tab20_tract20_tract10_natl.txt is not in data/census/relationship")
    columns = [
        "oid_tract_20",
        "geoid_tract_20",
        "namelsad_tract_20",
        "arealand_tract_20",
        "areawater_tract_20",
        "mtfcc_tract_20",
        "funcstat_tract_20",
        "oid_tract_10",
        "geoid_tract_10",
        "namelsad_tract_10",
        "arealand_tract_10",
        "areawater_tract_10",
        "mtfcc_tract_10",
        "funcstat_tract_10",
        "arealand_part",
        "areawater_part",
    ]
    quoted = ", ".join(columns)
    defs = ", ".join(f"{name} text" for name in columns)
    with conn.cursor() as cur:
        cur.execute("DROP TABLE IF EXISTS raw.tract_rel_2020_2010")
        cur.execute(f"CREATE TABLE raw.tract_rel_2020_2010 ({defs})")
        with path.open("rb") as handle:
            payload = handle.read()
            if payload.startswith(b"\xef\xbb\xbf"):
                payload = payload[3:]
            with cur.copy(
                f"COPY raw.tract_rel_2020_2010 ({quoted}) FROM STDIN WITH (FORMAT csv, DELIMITER '|', HEADER true, NULL '')"
            ) as copy:
                copy.write(payload)
        cur.execute("SELECT count(*) FROM raw.tract_rel_2020_2010")
        loaded = cur.fetchone()[0]
    conn.commit()
    print(f"raw.tract_rel_2020_2010 rows {loaded}", flush=True)
    return loaded


def main() -> None:
    with connect() as conn:
        load_directory(conn, CENSUS_DIR / "acs2022_bg", "raw.acs2022_block_group")
        load_directory(conn, CENSUS_DIR / "acs2022_bg_b15002_027", "raw.acs2022_b15002_027")
        load_directory(conn, CENSUS_DIR / "acs2022_tract_b18101", "raw.acs2022_tract_b18101")
        load_directory(conn, CENSUS_DIR / "pl2020_bg", "raw.pl2020_block_group")
        load_usaleep(conn)
        load_tract_relationship(conn)
        from load_block_weight import load_block_population, load_block_relationship
        load_block_relationship(conn)
        load_block_population(conn)


if __name__ == "__main__":
    main()

"""Load the 2010-2020 block relationship and 2020 block population. No indicator math."""

import csv
import io
import zipfile
from pathlib import Path

from common import ROOT, connect

CENSUS_DIR = ROOT / "data" / "census"
REL_DIR = CENSUS_DIR / "relationship" / "t10t20"
BLOCK_DIR = CENSUS_DIR / "pl2020_block"


def header_of(path: Path, delimiter: str) -> list[str]:
    with path.open(newline="") as handle:
        return next(csv.reader(handle, delimiter=delimiter))


def relationship_zips() -> list[Path]:
    files = sorted(REL_DIR.glob("TAB2010_TAB2020_ST*.zip"))
    if len(files) != 52:
        raise SystemExit(f"Expected 52 block relationship zips, found {len(files)}")
    return files


def zip_header(path: Path) -> tuple[str, list[str]]:
    with zipfile.ZipFile(path) as archive:
        names = [info.filename for info in archive.infolist() if info.filename.lower().endswith(".txt")]
        if len(names) != 1:
            raise SystemExit(f"{path.name} has {len(names)} text files")
        with archive.open(names[0]) as handle:
            line = handle.readline()
    if line.startswith(b"\xef\xbb\xbf"):
        line = line[3:]
    header = next(csv.reader([line.decode("utf-8").strip()], delimiter="|"))
    return names[0], header


def load_block_relationship(conn) -> int:
    files = relationship_zips()
    text_name, header = zip_header(files[0])
    for path in files[1:]:
        _, other = zip_header(path)
        if other != header:
            raise SystemExit(f"Header mismatch in {path.name}")
    columns = [name.strip().lower() for name in header]
    quoted = ", ".join(columns)
    defs = ", ".join(f"{name} text" for name in columns)
    with conn.cursor() as cur:
        cur.execute("DROP TABLE IF EXISTS raw.block_rel_2010_2020")
        cur.execute(f"CREATE TABLE raw.block_rel_2010_2020 ({defs})")
        for path in files:
            member, _ = zip_header(path)
            with zipfile.ZipFile(path) as archive:
                with archive.open(member) as handle:
                    payload = handle.read()
            if payload.startswith(b"\xef\xbb\xbf"):
                payload = payload[3:]
            with cur.copy(
                f"COPY raw.block_rel_2010_2020 ({quoted}) FROM STDIN WITH (FORMAT csv, DELIMITER '|', HEADER true, NULL '')"
            ) as copy:
                copy.write(payload)
            print(f"loaded {path.name}", flush=True)
        cur.execute("SELECT count(*) FROM raw.block_rel_2010_2020")
        loaded = cur.fetchone()[0]
        cur.execute(
            """
            CREATE INDEX block_rel_2010_2020_block
              ON raw.block_rel_2010_2020 (state_2020, county_2020, tract_2020, blk_2020)
            """
        )
    conn.commit()
    print(f"raw.block_rel_2010_2020 rows {loaded} columns {len(columns)}", flush=True)
    del text_name
    return loaded


def load_block_population(conn) -> int:
    files = sorted(BLOCK_DIR.glob("*.csv"))
    if not files:
        raise SystemExit(f"No block population files in {BLOCK_DIR}")
    header = header_of(files[0], ",")
    for path in files[1:]:
        if header_of(path, ",") != header:
            raise SystemExit(f"Header mismatch in {path.name}")
    quoted = ", ".join('"' + name.replace('"', '""') + '"' for name in header)
    defs = ", ".join('"' + name.replace('"', '""') + '" text' for name in header)
    with conn.cursor() as cur:
        cur.execute("DROP TABLE IF EXISTS raw.pl2020_block")
        cur.execute(f"CREATE TABLE raw.pl2020_block ({defs})")
        for path in files:
            with path.open("rb") as handle:
                with cur.copy(
                    f'COPY raw.pl2020_block ({quoted}) FROM STDIN WITH (FORMAT csv, HEADER true, NULL \'\')'
                ) as copy:
                    copy.write(handle.read())
        cur.execute("SELECT count(*) FROM raw.pl2020_block")
        loaded = cur.fetchone()[0]
        cur.execute(
            """
            CREATE INDEX pl2020_block_geoid
              ON raw.pl2020_block (state, county, tract, block)
            """
        )
    conn.commit()
    print(f"raw.pl2020_block rows {loaded} columns {len(header)}", flush=True)
    return loaded


def load_geocorr_ct(conn) -> int:
    """Load the Missouri Census Data Center Geocorr 2022 Connecticut tract file.

    The download has a machine header and a second label row. The label row is not loaded.
    """
    path = CENSUS_DIR / "relationship" / "geocorr2022_2629507182.csv"
    if not path.exists():
        raise SystemExit(f"Missing {path}")
    with path.open(newline="") as handle:
        rows = list(csv.reader(handle))
    if len(rows) < 3 or rows[0] != [
        "county",
        "tract",
        "CTcounty",
        "CountyName",
        "CTCountyName",
        "pop20",
        "afact",
    ]:
        raise SystemExit(f"Unexpected Geocorr header in {path.name}")
    data = rows[2:]
    if not data or data[0][0] == "Connecticut planning region":
        raise SystemExit(f"Geocorr label row was not skipped in {path.name}")
    columns = ["county", "tract", "ctcounty", "county_name", "ct_county_name", "pop20", "afact"]
    quoted = ", ".join(columns)
    defs = ", ".join(f"{name} text" for name in columns)
    buffer = io.StringIO()
    csv.writer(buffer, lineterminator="\n").writerows(data)
    payload = buffer.getvalue().encode()
    with conn.cursor() as cur:
        cur.execute("DROP TABLE IF EXISTS raw.geocorr_ct_2020_2022")
        cur.execute(f"CREATE TABLE raw.geocorr_ct_2020_2022 ({defs})")
        with cur.copy(
            f"COPY raw.geocorr_ct_2020_2022 ({quoted}) FROM STDIN WITH (FORMAT csv, NULL '')"
        ) as copy:
            copy.write(payload)
        cur.execute("SELECT count(*) FROM raw.geocorr_ct_2020_2022")
        loaded = cur.fetchone()[0]
        if loaded != 886:
            raise SystemExit(f"Expected 886 Geocorr rows, loaded {loaded}")
    conn.commit()
    print(f"raw.geocorr_ct_2020_2022 rows {loaded}", flush=True)
    return loaded


def main() -> None:
    with connect() as conn:
        load_block_relationship(conn)
        if any(BLOCK_DIR.glob("*.csv")):
            load_block_population(conn)
        geocorr = CENSUS_DIR / "relationship" / "geocorr2022_2629507182.csv"
        if geocorr.exists():
            load_geocorr_ct(conn)


if __name__ == "__main__":
    main()

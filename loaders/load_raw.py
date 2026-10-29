"""Load the Harvard CSV extracts into raw tables."""

import hashlib
import json
from pathlib import Path

import psycopg

from common import REFERENCE_DIR, ROOT, connect, run_sql_file

FILES = {
    "national_csv": {
        "filename": "EJSCREEN_2024_BG_with_AS_CNMI_GU_VI.csv",
        "table": "raw.ejscreen_reference",
        "bytes": 436936720,
        "columns": 231,
    },
    "state_csv": {
        "filename": "EJSCREEN_2024_BG_StatePct_with_AS_CNMI_GU_VI.csv",
        "table": "raw.ejscreen_reference_state_pct",
        "bytes": 428393381,
        "columns": 229,
    },
}


def materialize(filename: str, expected_bytes: int) -> Path:
    single = REFERENCE_DIR / filename
    if single.exists() and single.stat().st_size == expected_bytes:
        return single
    manifest = json.loads((REFERENCE_DIR / "manifest.json").read_text())
    item = next(row for row in manifest["files"] if row["filename"] == filename)
    dest = Path("/tmp") / filename
    digest = hashlib.sha256()
    with dest.open("wb") as handle:
        for part in item["parts"]:
            blob = (REFERENCE_DIR / part["name"]).read_bytes()
            if len(blob) != part["bytes"]:
                raise SystemExit(f"Part size mismatch for {part['name']}")
            handle.write(blob)
            digest.update(blob)
    if dest.stat().st_size != expected_bytes:
        raise SystemExit(f"Reassembled size mismatch for {filename}")
    if digest.hexdigest() != item["sha256"]:
        raise SystemExit(f"Checksum mismatch for {filename}")
    return dest


def data_row_count(path: Path) -> int:
    count = 0
    ends_nl = False
    with path.open("rb") as handle:
        while True:
            chunk = handle.read(8 * 1024 * 1024)
            if not chunk:
                break
            count += chunk.count(b"\n")
            ends_nl = chunk.endswith(b"\n")
    if not ends_nl:
        count += 1
    return count - 1


def copy_csv(conn: psycopg.Connection, table: str, path: Path) -> None:
    with path.open("rb") as handle:
        start = handle.read(3)
        if start != b"\xef\xbb\xbf":
            handle.seek(0)
        sql = f"COPY {table} FROM STDIN WITH (FORMAT csv, HEADER MATCH, NULL '')"
        with conn.cursor() as cur:
            with cur.copy(sql) as copy:
                while True:
                    chunk = handle.read(8 * 1024 * 1024)
                    if not chunk:
                        break
                    copy.write(chunk)


def main() -> None:
    paths = {}
    for role, spec in FILES.items():
        path = materialize(spec["filename"], spec["bytes"])
        paths[role] = path
        print(f"source {spec['filename']} {path.stat().st_size} bytes", flush=True)
    run_sql_file(ROOT / "sql" / "001_schemas.sql")
    run_sql_file(ROOT / "sql" / "002_raw_tables.sql")
    with connect() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                CREATE TABLE IF NOT EXISTS raw.load_audit (
                  file_role text PRIMARY KEY,
                  filename text NOT NULL,
                  byte_count bigint NOT NULL,
                  column_count integer NOT NULL,
                  sha256 text NOT NULL,
                  row_count bigint NOT NULL,
                  loaded_at timestamptz NOT NULL DEFAULT now()
                )
                """
            )
            cur.execute("TRUNCATE raw.load_audit")
        conn.commit()
        for role, spec in FILES.items():
            path = paths[role]
            print(f"loading {spec['table']}", flush=True)
            copy_csv(conn, spec["table"], path)
            conn.commit()
            expected_rows = data_row_count(path)
            with conn.cursor() as cur:
                cur.execute(f"SELECT count(*) FROM {spec['table']}")
                loaded = cur.fetchone()[0]
                cur.execute(
                    """
                    SELECT count(*) FROM information_schema.columns
                    WHERE table_schema = %s AND table_name = %s
                    """,
                    (spec["table"].split(".")[0], spec["table"].split(".")[1]),
                )
                columns = cur.fetchone()[0]
            if loaded != expected_rows:
                raise SystemExit(
                    f"{spec['table']} loaded {loaded} rows, file has {expected_rows} data rows"
                )
            if columns != spec["columns"]:
                raise SystemExit(
                    f"{spec['table']} has {columns} columns, expected {spec['columns']}"
                )
            digest = hashlib.sha256(path.read_bytes()).hexdigest()
            with conn.cursor() as cur:
                cur.execute(f"ANALYZE {spec['table']}")
                cur.execute(
                    """
                    INSERT INTO raw.load_audit (file_role, filename, byte_count, column_count, sha256, row_count)
                    VALUES (%s, %s, %s, %s, %s, %s)
                    """,
                    (role, spec["filename"], spec["bytes"], columns, digest, loaded),
                )
            conn.commit()
            print(f"{spec['table']} rows {loaded} columns {columns}", flush=True)


if __name__ == "__main__":
    main()

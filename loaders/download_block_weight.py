"""Download the 2010-2020 block relationship files and 2020 block population.

No indicator math. The relationship files are Census Bureau pipe-delimited
zips. Block population is P1_001N from 2020/dec/pl, the same variable already
loaded at block group geography, requested here at block geography so it can
join the relationship file.
"""

import csv
import json
import os
import time
import urllib.parse
import urllib.request
import zipfile
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
from urllib.error import HTTPError, URLError

from download_acs import (
    CENSUS_DIR,
    api_key,
    complete,
    fetch_json,
    state_fips_list,
    write_rows,
)

def replace_retry(partial: Path, path: Path) -> None:
    for attempt in range(8):
        try:
            os.replace(partial, path)
            return
        except OSError as exc:
            if exc.errno in {11, 16} and attempt < 7:
                time.sleep(0.5 * (attempt + 1))
                continue
            raise


REL_DIR = CENSUS_DIR / "relationship" / "t10t20"
REL_URL = "https://www2.census.gov/geo/docs/maps-data/data/rel2020/t10t20"
REL_FIPS = [
    "01", "02", "04", "05", "06", "08", "09", "10", "11", "12", "13", "15",
    "16", "17", "18", "19", "20", "21", "22", "23", "24", "25", "26", "27",
    "28", "29", "30", "31", "32", "33", "34", "35", "36", "37", "38", "39",
    "40", "41", "42", "44", "45", "46", "47", "48", "49", "50", "51", "53",
    "54", "55", "56", "72",
]
def fetch_blocks_once(params: dict, label: str):
    """One Census API call. The key stays off the printed label."""
    query = dict(params)
    query["key"] = api_key()
    url = "https://api.census.gov/data/2020/dec/pl?" + urllib.parse.urlencode(query)
    request = urllib.request.Request(url, headers={"User-Agent": "ejscreen-tier2"})
    try:
        with urllib.request.urlopen(request, timeout=300) as response:
            status = getattr(response, "status", None) or response.getcode()
            if status != 200:
                raise SystemExit(f"Download failed for 2020/dec/pl {label} status {status}")
            return json.load(response)
    except HTTPError as exc:
        raise SystemExit(f"Download failed for 2020/dec/pl {label} status {exc.code}") from exc
    except URLError as exc:
        raise SystemExit(f"Download failed for 2020/dec/pl {label} status {exc.reason}") from exc


def download_relationship_zip(code: str) -> str:
    REL_DIR.mkdir(parents=True, exist_ok=True)
    name = f"TAB2010_TAB2020_ST{code}.zip"
    path = REL_DIR / name
    if path.exists() and path.stat().st_size > 1000:
        return code
    url = f"{REL_URL}/{name}"
    partial = path.with_suffix(".zip.partial")
    last_error = None
    for attempt in range(4):
        try:
            request = urllib.request.Request(url, headers={"User-Agent": "ejscreen-tier2"})
            with urllib.request.urlopen(request, timeout=180) as response:
                payload = response.read()
            if len(payload) < 1000:
                raise OSError(f"short download for {name}")
            partial.write_bytes(payload)
            replace_retry(partial, path)
            print(f"relationship {name} {path.stat().st_size}", flush=True)
            return code
        except (HTTPError, URLError, OSError) as exc:
            last_error = exc
            time.sleep(2 ** attempt)
    raise SystemExit(f"Relationship download failed for {name}: {last_error}")


def unzip_relationships() -> int:
    """The loader reads the zips directly. Expanding them on the store fills the disk."""
    found = 0
    for code in REL_FIPS:
        archive = REL_DIR / f"TAB2010_TAB2020_ST{code}.zip"
        if not archive.exists() or archive.stat().st_size < 1000:
            raise SystemExit(f"Missing {archive.name}")
        with zipfile.ZipFile(archive) as handle:
            names = [info.filename for info in handle.infolist() if info.filename.lower().endswith(".txt")]
        if len(names) != 1:
            raise SystemExit(f"{archive.name} has {len(names)} text files")
        found += 1
    print(f"relationship zips {found}", flush=True)
    return found


def counties_for(code: str) -> list[str]:
    path = CENSUS_DIR / "pl2020_bg" / f"{code}.csv"
    found = set()
    with path.open(newline="") as handle:
        for row in csv.DictReader(handle):
            found.add(row["county"].zfill(3))
    if not found:
        raise SystemExit(f"No counties in {path.name}")
    return sorted(found)


def download_state_blocks(code: str) -> str:
    path = CENSUS_DIR / "pl2020_block" / f"{code}.csv"
    if complete(path):
        print(f"block population {code} already stored", flush=True)
        return code
    try:
        rows = fetch_blocks_once(
            {"get": "P1_001N", "for": "block:*", "in": f"state:{code} county:*"},
            f"block state {code}",
        )
        write_rows(path, rows)
        print(f"block population {code} rows {len(rows) - 1}", flush=True)
        return code
    except SystemExit as exc:
        print(f"block population {code} state query failed, using counties: {exc}", flush=True)
    header = None
    body = []
    for county in counties_for(code):
        rows = fetch_json(
            "2020/dec/pl",
            {
                "get": "P1_001N",
                "for": "block:*",
                "in": f"state:{code} county:{county}",
            },
            f"2020 PL block state {code} county {county}",
        )
        if header is None:
            header = rows[0]
        elif rows[0] != header:
            raise SystemExit(f"Header mismatch for state {code} county {county}")
        body.extend(rows[1:])
    write_rows(path, [header, *body])
    print(f"block population {code} rows {len(body)}", flush=True)
    return code


def download_relationships() -> None:
    with ThreadPoolExecutor(max_workers=6) as pool:
        futures = {pool.submit(download_relationship_zip, code): code for code in REL_FIPS}
        for future in as_completed(futures):
            future.result()
    n = unzip_relationships()
    print(f"relationship text files {n}", flush=True)


def download_block_population() -> None:
    codes = state_fips_list()
    failed = []
    with ThreadPoolExecutor(max_workers=3) as pool:
        futures = {pool.submit(download_state_blocks, code): code for code in codes}
        for future in as_completed(futures):
            code = futures[future]
            try:
                future.result()
            except (SystemExit, OSError) as exc:
                failed.append(code)
                print(f"block population {code} will retry: {exc}", flush=True)
    for code in failed:
        download_state_blocks(code)
    print(f"block population states {len(codes)}", flush=True)


def main() -> None:
    api_key()
    download_relationships()
    download_block_population()


if __name__ == "__main__":
    main()

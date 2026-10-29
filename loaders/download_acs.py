"""Download ACS 2022 5-year and 2020 PL 94-171 tables. No indicator math."""

import csv
import json
import os
import time
import urllib.parse
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
from urllib.error import HTTPError, URLError

from common import ROOT, load_dotenv

CENSUS_DIR = ROOT / "data" / "census"
EXCLUDED_FIPS = {"60", "66", "69", "78"}
BG_VARS = [
    "B03002_001E",
    "B03002_003E",
    "C17002_001E",
    "C17002_008E",
    "C16002_001E",
    "C16002_004E",
    "C16002_007E",
    "C16002_010E",
    "C16002_013E",
    "B15002_001E",
    "B15002_003E",
    "B15002_004E",
    "B15002_005E",
    "B15002_006E",
    "B15002_007E",
    "B15002_008E",
    "B15002_009E",
    "B15002_010E",
    "B15002_020E",
    "B15002_021E",
    "B15002_022E",
    "B15002_023E",
    "B15002_024E",
    "B15002_025E",
    "B15002_026E",
    "B23025_003E",
    "B23025_005E",
    "B01001_001E",
    "B01001_003E",
    "B01001_020E",
    "B01001_021E",
    "B01001_022E",
    "B01001_023E",
    "B01001_024E",
    "B01001_025E",
    "B01001_027E",
    "B01001_044E",
    "B01001_045E",
    "B01001_046E",
    "B01001_047E",
    "B01001_048E",
    "B01001_049E",
]
# B18101 lines whose 2022 ACS group label is "With a disability", plus the table total.
TRACT_VARS = [
    "B18101_001E",
    "B18101_004E",
    "B18101_007E",
    "B18101_010E",
    "B18101_013E",
    "B18101_016E",
    "B18101_019E",
    "B18101_023E",
    "B18101_026E",
    "B18101_029E",
    "B18101_032E",
    "B18101_035E",
    "B18101_038E",
]


def api_key() -> str:
    load_dotenv()
    key = os.environ.get("CENSUS_API_KEY", "").strip()
    if not key:
        raise SystemExit("CENSUS_API_KEY is empty")
    return key


def fetch_json(dataset: str, params: dict, label: str):
    query = dict(params)
    query["key"] = api_key()
    url = "https://api.census.gov/data/" + dataset + "?" + urllib.parse.urlencode(query)
    public = "https://api.census.gov/data/" + dataset + " " + label
    last_error = None
    for attempt in range(4):
        try:
            request = urllib.request.Request(url, headers={"User-Agent": "ejscreen-tier2"})
            with urllib.request.urlopen(request, timeout=180) as response:
                status = getattr(response, "status", None) or response.getcode()
                if status != 200:
                    raise SystemExit(f"Download failed for {public} status {status}")
                return json.load(response)
        except HTTPError as exc:
            last_error = exc
            if exc.code in {429, 500, 502, 503, 504} and attempt < 3:
                time.sleep(2 ** attempt)
                continue
            raise SystemExit(f"Download failed for {public} status {exc.code}") from exc
        except URLError as exc:
            last_error = exc
            if attempt < 3:
                time.sleep(2 ** attempt)
                continue
            raise SystemExit(f"Download failed for {public} status {exc.reason}") from exc
    raise SystemExit(f"Download failed for {public} status {last_error}")


def write_rows(path: Path, rows: list) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    partial = path.with_suffix(path.suffix + ".partial")
    with partial.open("w", newline="") as handle:
        writer = csv.writer(handle)
        for row in rows:
            writer.writerow(["" if value is None else value for value in row])
    for attempt in range(8):
        try:
            partial.replace(path)
            return
        except OSError as exc:
            if exc.errno in {11, 16} and attempt < 7:
                time.sleep(0.5 * (attempt + 1))
                continue
            raise


def complete(path: Path) -> bool:
    if not path.exists() or path.stat().st_size < 40:
        return False
    with path.open() as handle:
        header = handle.readline()
        second = handle.readline()
    return bool(header) and bool(second)


def state_fips_list() -> list[str]:
    rows = fetch_json("2022/acs/acs5", {"get": "NAME", "for": "state:*"}, "state list")
    codes = []
    for row in rows[1:]:
        code = row[-1].zfill(2)
        if code in EXCLUDED_FIPS:
            continue
        codes.append(code)
    return sorted(codes)


def download_b15002_027(code: str) -> str:
    path = CENSUS_DIR / "acs2022_bg_b15002_027" / f"{code}.csv"
    if complete(path):
        return code
    rows = fetch_json(
        "2022/acs/acs5",
        {
            "get": "B15002_027E",
            "for": "block group:*",
            "in": f"state:{code} county:*",
        },
        f"B15002_027E state {code}",
    )
    write_rows(path, rows)
    return code


def download_state(code: str) -> str:
    bg_path = CENSUS_DIR / "acs2022_bg" / f"{code}.csv"
    tract_path = CENSUS_DIR / "acs2022_tract_b18101" / f"{code}.csv"
    pl_path = CENSUS_DIR / "pl2020_bg" / f"{code}.csv"
    if not complete(bg_path):
        rows = fetch_json(
            "2022/acs/acs5",
            {
                "get": ",".join(BG_VARS),
                "for": "block group:*",
                "in": f"state:{code} county:*",
            },
            f"block group state {code}",
        )
        write_rows(bg_path, rows)
    if not complete(tract_path):
        rows = fetch_json(
            "2022/acs/acs5",
            {
                "get": ",".join(TRACT_VARS),
                "for": "tract:*",
                "in": f"state:{code} county:*",
            },
            f"tract B18101 state {code}",
        )
        write_rows(tract_path, rows)
    if not complete(pl_path):
        rows = fetch_json(
            "2020/dec/pl",
            {
                "get": "P1_001N",
                "for": "block group:*",
                "in": f"state:{code} county:*",
            },
            f"2020 PL block group state {code}",
        )
        write_rows(pl_path, rows)
    download_b15002_027(code)
    return code


def main() -> None:
    CENSUS_DIR.mkdir(parents=True, exist_ok=True)
    codes = state_fips_list()
    print(f"states {len(codes)}", flush=True)
    failed_codes = []
    with ThreadPoolExecutor(max_workers=2) as pool:
        futures = {pool.submit(download_state, code): code for code in codes}
        for future in as_completed(futures):
            code = futures[future]
            try:
                future.result()
                print(f"state {code} stored", flush=True)
            except (SystemExit, OSError) as exc:
                failed_codes.append(code)
                print(f"state {code} will retry: {exc}", flush=True)
    for code in failed_codes:
        download_state(code)
        print(f"state {code} stored", flush=True)
    print(f"downloaded {len(codes)} states", flush=True)
    from download_block_weight import download_block_population, download_relationships
    download_relationships()
    download_block_population()


if __name__ == "__main__":
    main()

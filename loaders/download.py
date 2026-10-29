"""Download the Harvard Dataverse EJScreen 2024 extracts."""

import hashlib
import json
import sys
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

from common import REFERENCE_DIR

PART_SIZE = 90_000_000

FILES = [
    {
        "file_id": "10775972",
        "filename": "EJSCREEN_2024_BG_with_AS_CNMI_GU_VI.csv",
        "role": "national_csv",
        "bytes": 436936720,
        "columns": 231,
    },
    {
        "file_id": "10775971",
        "filename": "EJSCREEN_2024_BG_StatePct_with_AS_CNMI_GU_VI.csv",
        "role": "state_csv",
        "bytes": 428393381,
        "columns": 229,
    },
    {
        "file_id": "10775980",
        "filename": "EJScreen_2024_BG_Percentiles_Columns.xlsx",
        "role": "national_workbook",
        "bytes": 21936,
        "columns": None,
    },
    {
        "file_id": "10775978",
        "filename": "EJScreen_2024_BG_State_Percentiles_Columns.xlsx",
        "role": "state_workbook",
        "bytes": 21808,
        "columns": None,
    },
]


def url_for(file_id: str) -> str:
    return f"https://dataverse.harvard.edu/api/access/datafile/{file_id}"


def download(file_id: str, dest: Path) -> None:
    url = url_for(file_id)
    request = Request(url, headers={"User-Agent": "ejscreen-tier1-reconstruction"})
    try:
        response = urlopen(request, timeout=120)
    except HTTPError as exc:
        raise SystemExit(f"Download failed for {url} status {exc.code}") from exc
    except URLError as exc:
        raise SystemExit(f"Download failed for {url} status {exc.reason}") from exc
    status = getattr(response, "status", None) or response.getcode()
    if status != 200:
        raise SystemExit(f"Download failed for {url} status {status}")
    digest = hashlib.sha256()
    total = 0
    with dest.open("wb") as handle:
        while True:
            chunk = response.read(8 * 1024 * 1024)
            if not chunk:
                break
            handle.write(chunk)
            digest.update(chunk)
            total += len(chunk)
    return total, digest.hexdigest()


def header_count(path: Path) -> int:
    with path.open("rb") as handle:
        line = handle.readline()
    if line.startswith(b"\xef\xbb\xbf"):
        line = line[3:]
    return len(line.decode("utf-8").rstrip("\r\n").split(","))


def store_csv(spec: dict, src: Path, digest: str) -> None:
    REFERENCE_DIR.mkdir(parents=True, exist_ok=True)
    single = REFERENCE_DIR / spec["filename"]
    try:
        if single.exists() and single.stat().st_size == spec["bytes"]:
            stored = "single"
        else:
            data = src.read_bytes()
            single.write_bytes(data)
            stored = "single"
    except OSError:
        stored = "parts"
        if single.exists():
            single.unlink()
        parts = []
        with src.open("rb") as handle:
            index = 0
            while True:
                blob = handle.read(PART_SIZE)
                if not blob:
                    break
                part_name = f"{spec['filename']}.part{index:03d}"
                (REFERENCE_DIR / part_name).write_bytes(blob)
                parts.append({"name": part_name, "bytes": len(blob)})
                index += 1
        manifest_path = REFERENCE_DIR / "manifest.json"
        manifest = {"part_size_bytes": PART_SIZE, "files": []}
        if manifest_path.exists():
            manifest = json.loads(manifest_path.read_text())
        manifest["files"] = [
            item for item in manifest.get("files", []) if item.get("filename") != spec["filename"]
        ]
        manifest["files"].append(
            {
                "filename": spec["filename"],
                "bytes": spec["bytes"],
                "sha256": digest,
                "parts": parts,
            }
        )
        manifest_path.write_text(json.dumps(manifest, indent=2) + "\n")
    print(f"{spec['filename']} stored as {stored}")


def parts_match(spec: dict) -> bool:
    manifest_path = REFERENCE_DIR / "manifest.json"
    if not manifest_path.exists():
        return False
    manifest = json.loads(manifest_path.read_text())
    item = next((row for row in manifest.get("files", []) if row["filename"] == spec["filename"]), None)
    if not item or item.get("bytes") != spec["bytes"]:
        return False
    total = 0
    for part in item["parts"]:
        path = REFERENCE_DIR / part["name"]
        if not path.exists() or path.stat().st_size != part["bytes"]:
            return False
        total += part["bytes"]
    return total == spec["bytes"]


def main() -> None:
    REFERENCE_DIR.mkdir(parents=True, exist_ok=True)
    for spec in FILES:
        dest_name = spec["filename"]
        existing = REFERENCE_DIR / dest_name
        if spec["columns"] is None and existing.exists() and existing.stat().st_size == spec["bytes"]:
            print(f"{dest_name} already present ({spec['bytes']} bytes)")
            continue
        if spec["columns"] is not None and parts_match(spec):
            print(f"{dest_name} parts already present ({spec['bytes']} bytes)")
            continue
        if spec["columns"] is not None and existing.exists() and existing.stat().st_size == spec["bytes"]:
            print(f"{dest_name} already present ({spec['bytes']} bytes)")
            continue
        tmp = Path("/tmp") / dest_name
        print(f"downloading {url_for(spec['file_id'])}")
        total, digest = download(spec["file_id"], tmp)
        if total != spec["bytes"]:
            raise SystemExit(
                f"Size mismatch for {url_for(spec['file_id'])}: got {total} bytes, expected {spec['bytes']}"
            )
        if spec["columns"] is not None:
            counted = header_count(tmp)
            if counted != spec["columns"]:
                raise SystemExit(
                    f"Column mismatch for {url_for(spec['file_id'])}: got {counted} fields, expected {spec['columns']}"
                )
            store_csv(spec, tmp, digest)
        else:
            existing.write_bytes(tmp.read_bytes())
            print(f"{dest_name} stored ({total} bytes)")


if __name__ == "__main__":
    try:
        main()
    except SystemExit:
        raise
    except Exception as exc:
        print(f"Download failed: {exc}", file=sys.stderr)
        raise

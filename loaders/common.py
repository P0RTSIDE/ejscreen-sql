"""Paths, environment, and Postgres helpers."""

import os
import subprocess
from pathlib import Path

import psycopg

ROOT = Path(__file__).resolve().parents[1]
REFERENCE_DIR = ROOT / "data" / "reference"


def load_dotenv() -> None:
    env_path = ROOT / ".env"
    if not env_path.exists():
        return
    for line in env_path.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        os.environ.setdefault(key.strip(), value.strip())


def connect() -> psycopg.Connection:
    load_dotenv()
    return psycopg.connect(
        host=os.environ["POSTGRES_HOST"],
        port=int(os.environ["POSTGRES_PORT"]),
        user=os.environ["POSTGRES_USER"],
        password=os.environ["POSTGRES_PASSWORD"],
        dbname=os.environ["POSTGRES_DB"],
    )


def run_sql_file(path: Path) -> None:
    load_dotenv()
    user = os.environ["POSTGRES_USER"]
    db = os.environ["POSTGRES_DB"]
    script = path.read_text()
    result = subprocess.run(
        [
            "docker",
            "compose",
            "--env-file",
            str(ROOT / ".env"),
            "exec",
            "-T",
            "db",
            "psql",
            "-U",
            user,
            "-d",
            db,
            "-v",
            "ON_ERROR_STOP=1",
            "-f",
            "-",
        ],
        input=script,
        text=True,
        cwd=ROOT,
        capture_output=True,
    )
    if result.returncode != 0:
        raise SystemExit(
            f"SQL failed in {path.name}\n{result.stdout}\n{result.stderr}"
        )
    if result.stderr.strip():
        print(result.stderr.strip())

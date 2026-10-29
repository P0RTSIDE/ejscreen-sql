"""Run SQL files in order."""

import sys
from pathlib import Path

from common import ROOT, run_sql_file

def main() -> None:
    if len(sys.argv) < 2:
        raise SystemExit("Usage: run_sql.py file.sql [file.sql ...]")
    for arg in sys.argv[1:]:
        path = Path(arg)
        if not path.is_absolute():
            path = ROOT / path
        print(f"running {path.relative_to(ROOT)}", flush=True)
        run_sql_file(path)


if __name__ == "__main__":
    main()

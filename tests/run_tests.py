"""Run every test module, each in its own process, several at a time.

    python -B tests/run_tests.py [--jobs N] [pattern ...]

A pattern selects modules whose name contains it. The exit status is 1 when
any module fails.
"""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import os
from pathlib import Path
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parents[1]


def modules(patterns: list[str]) -> list[str]:
    names = sorted(path.stem for path in (ROOT / "tests").glob("test_*.py"))
    if patterns:
        names = [name for name in names if any(pattern in name for pattern in patterns)]
    return names


def run(name: str) -> tuple[str, int, float, str]:
    started = time.monotonic()
    # Some modules import their neighbours (fixtures) by bare name.
    environment = dict(
        os.environ, PYTHONPATH=os.pathsep.join(filter(None, (str(ROOT / "tests"), os.environ.get("PYTHONPATH"))))
    )
    result = subprocess.run(
        [sys.executable, "-B", "-m", "unittest", "-q", "tests." + name],
        cwd=ROOT,
        env=environment,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
    )
    return name, result.returncode, time.monotonic() - started, result.stdout + result.stderr


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--jobs", type=int, default=min(8, os.cpu_count() or 1))
    parser.add_argument("patterns", nargs="*")
    args = parser.parse_args()
    names = modules(args.patterns)
    if not names:
        print("no test modules selected", file=sys.stderr)
        return 1
    started = time.monotonic()
    failed = []
    with ThreadPoolExecutor(max_workers=max(1, args.jobs)) as pool:
        for future in as_completed([pool.submit(run, name) for name in names]):
            name, code, seconds, output = future.result()
            print("%-4s %6.1fs  %s" % ("ok" if code == 0 else "FAIL", seconds, name), flush=True)
            if code:
                failed.append((name, output))
    for name, output in failed:
        print("\n==== %s ====\n%s" % (name, output.rstrip()))
    print("\n%d modules, %d failed, %.1fs" % (len(names), len(failed), time.monotonic() - started))
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())

"""Test-only terminal command logger; never assembles or writes a ROM/listing."""

import json
import os
from pathlib import Path
import runpy
import sys

arguments = sys.argv[1:]
kind = "assembler" if arguments and arguments[0] == "--assembler" else "python-script"
if kind == "assembler":
    arguments = arguments[1:]
events = Path(os.environ["PROFILE_FLAGS_EVENTS"])
recorded = json.loads(events.read_text(encoding="utf-8"))
recorded.append({"kind": kind, "arguments": arguments})
# Newly created private test record only; no user/project output is touched.
events.write_text(json.dumps(recorded), encoding="utf-8")
if kind == "python-script" and arguments and arguments[0].endswith("check_profile_as_args.py"):
    sys.argv = arguments
    runpy.run_path(arguments[0], run_name="__main__")

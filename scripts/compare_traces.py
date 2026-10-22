#!/usr/bin/env python3
"""
Compare two CPU trace logs and show differences.

Usage:
    python compare_traces.py trace1.csv trace2.csv [--show-context N]

Output:
    Shows where the traces diverge (first N different lines)
"""

import argparse
import sys
from pathlib import Path


def parse_trace_line(line):
    """Parse a trace line into components."""
    line = line.strip()
    if not line or line.startswith("#"):
        return None

    parts = line.split(",")
    if len(parts) < 3:
        return None

    return {
        "type": parts[0],
        "frame": parts[1] if len(parts) > 1 else "",
        "pc": parts[2] if len(parts) > 2 else "",
        "addr": parts[3] if len(parts) > 3 else "",
        "value": parts[4] if len(parts) > 4 else "",
        "size": parts[5] if len(parts) > 5 else "",
        "disasm": parts[6] if len(parts) > 6 else "",
        "regs": parts[7] if len(parts) > 7 else "",
        "raw": line,
    }


def load_trace(path):
    """Load trace file and parse into list of events."""
    events = []
    with open(path, "r") as f:
        for line_num, line in enumerate(f, 1):
            parsed = parse_trace_line(line)
            if parsed:
                parsed["line_num"] = line_num
                events.append(parsed)
    return events


def compare_traces(trace1, trace2, max_diffs=10, context=3):
    """Compare two traces and return differences."""
    diffs = []

    # Find first divergence point
    min_len = min(len(trace1), len(trace2))

    for i in range(min_len):
        e1, e2 = trace1[i], trace2[i]

        # Compare key fields
        different = False
        diff_fields = []

        if e1["type"] != e2["type"]:
            different = True
            diff_fields.append(f"type: {e1['type']} vs {e2['type']}")

        if e1["pc"] != e2["pc"]:
            different = True
            diff_fields.append(f"PC: {e1['pc']} vs {e2['pc']}")

        if e1["type"] == "EXEC":
            if e1["disasm"] != e2["disasm"]:
                different = True
                diff_fields.append(f"disasm: {e1['disasm']} vs {e2['disasm']}")
        else:
            if e1["addr"] != e2["addr"]:
                different = True
                diff_fields.append(f"addr: {e1['addr']} vs {e2['addr']}")
            if e1["value"] != e2["value"]:
                different = True
                diff_fields.append(f"value: {e1['value']} vs {e2['value']}")

        if different:
            diffs.append(
                {
                    "index": i,
                    "trace1_line": e1["line_num"],
                    "trace2_line": e2["line_num"],
                    "trace1": e1,
                    "trace2": e2,
                    "diff_fields": diff_fields,
                }
            )

            if len(diffs) >= max_diffs:
                break

    # Check if one trace is longer
    if len(trace1) != len(trace2) and len(diffs) < max_diffs:
        diffs.append(
            {
                "index": min_len,
                "trace1_line": trace1[min_len]["line_num"] if min_len < len(trace1) else None,
                "trace2_line": trace2[min_len]["line_num"] if min_len < len(trace2) else None,
                "trace1": trace1[min_len] if min_len < len(trace1) else None,
                "trace2": trace2[min_len] if min_len < len(trace2) else None,
                "diff_fields": [f"trace1 has {len(trace1)} events, trace2 has {len(trace2)} events"],
            }
        )

    return diffs


def print_context(trace, index, context, label, show_exec=True):
    """Print context around an index in trace."""
    start = max(0, index - context)
    end = min(len(trace), index + context + 1)

    for i in range(start, end):
        e = trace[i]
        marker = ">>>" if i == index else "   "

        if e["type"] == "EXEC":
            print(f"{marker} {label}[{e['line_num']:5d}] EXEC PC={e['pc']} {e['disasm']}")
        else:
            print(f"{marker} {label}[{e['line_num']:5d}] {e['type']} PC={e['pc']} addr={e['addr']} value={e['value']}")


def main():
    parser = argparse.ArgumentParser(description="Compare two CPU trace logs")
    parser.add_argument("trace1", help="First trace file (original)")
    parser.add_argument("trace2", help="Second trace file (modified)")
    parser.add_argument("--max-diffs", type=int, default=5, help="Max differences to show")
    parser.add_argument("--context", type=int, default=3, help="Context lines around diff")
    parser.add_argument("--exec-only", action="store_true", help="Compare only EXEC events")

    args = parser.parse_args()

    # Check files exist
    if not Path(args.trace1).exists():
        print(f"Error: {args.trace1} not found", file=sys.stderr)
        return 1
    if not Path(args.trace2).exists():
        print(f"Error: {args.trace2} not found", file=sys.stderr)
        return 1

    # Load traces
    print(f"Loading {args.trace1}...")
    trace1 = load_trace(args.trace1)
    print(f"  {len(trace1)} events")

    print(f"Loading {args.trace2}...")
    trace2 = load_trace(args.trace2)
    print(f"  {len(trace2)} events")

    # Filter to EXEC only if requested
    if args.exec_only:
        trace1 = [e for e in trace1 if e["type"] == "EXEC"]
        trace2 = [e for e in trace2 if e["type"] == "EXEC"]
        print(f"Filtered to EXEC: {len(trace1)} / {len(trace2)} events")

    # Compare
    print("\nComparing traces...")
    diffs = compare_traces(trace1, trace2, args.max_diffs, args.context)

    if not diffs:
        print("\n[OK] Traces are identical!")
        return 0

    print(f"\n[DIFF] Found {len(diffs)} difference(s):\n")

    for i, diff in enumerate(diffs, 1):
        print(f"{'=' * 60}")
        print(f"Difference #{i} at event index {diff['index']}")
        print(f"  Fields: {', '.join(diff['diff_fields'])}")
        print()

        if diff["trace1"]:
            print(f"  Trace 1 ({args.trace1}):")
            print_context(trace1, diff["index"], args.context, "T1")
            print()

        if diff["trace2"]:
            print(f"  Trace 2 ({args.trace2}):")
            print_context(trace2, diff["index"], args.context, "T2")
        print()

    return 1


if __name__ == "__main__":
    sys.exit(main())

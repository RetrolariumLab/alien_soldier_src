#!/usr/bin/env python3
"""
Batch Preparation Script for Documentation Workflow

Prepares a batch of procedures for documentation:
1. Reads analysis_report_{movie}.csv
2. Selects N unprocessed procedures
3. Extracts their code and context
4. Outputs batch_procedures.txt for Claude to analyze
"""

import csv
import re
import argparse
from pathlib import Path

from research_movie import report_for_movie


INCLUDE_RE = re.compile(r'^\s*include\s+"([^"]+\.s)"', re.IGNORECASE)


def source_modules(source_file):
    """Return the assembly modules named by the address-ordered include index."""
    source_file = Path(source_file)
    if source_file.name != "main.s":
        return [source_file]

    project_dir = source_file.parent.parent
    modules = []
    for line in source_file.read_text(encoding="utf-8").splitlines():
        match = INCLUDE_RE.match(line)
        if match:
            module = project_dir / match.group(1)
            if not module.is_file():
                raise FileNotFoundError(f"{source_file}: missing module {module}")
            modules.append(module)
    if not modules:
        raise ValueError(f"{source_file}: no assembly modules found")
    return modules


def load_procedures_from_report(csv_file, count=40):
    """Load unprocessed procedures from analysis report CSV."""
    procedures = []
    processed_count = 0

    with open(csv_file, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            # Skip already processed procedures
            if row.get("processed") == "true":
                processed_count += 1
                continue

            procedures.append(
                {
                    "procedure": row["procedure"],
                    "address": row.get("address", ""),
                    "scene": row.get("scene", ""),
                    "frame": row.get("frame", ""),
                    "change_type": row.get("change_type", ""),
                    "sections": row.get("sections", ""),
                    "RAM": row.get("RAM", ""),
                    "VDP": row.get("VDP", ""),
                    "Z80": row.get("Z80", ""),
                    "YM2612": row.get("YM2612", ""),
                    "PSG": row.get("PSG", ""),
                }
            )

            if len(procedures) >= count:
                break

    print(f"Already processed: {processed_count} procedures")
    return procedures


def find_procedure_in_file(asm_file, proc_name):
    """Find and extract procedure code from one assembly module."""
    with open(asm_file, "r", encoding="utf-8", errors="ignore") as f:
        lines = f.readlines()

    # Find procedure start
    proc_pattern = re.compile(rf"^{re.escape(proc_name)}:\s*")
    start_line = None

    for i, line in enumerate(lines):
        if proc_pattern.match(line):
            start_line = i
            break

    if start_line is None:
        return None

    # Find the imported function boundary. A module is at most 1000 lines, so
    # scanning it in full is cheap and avoids silently clipping long routines.
    end_line = None
    end_pattern = re.compile(r"^; End of function\s+" + re.escape(proc_name) + r"(?:\s|$)")

    for i in range(start_line + 1, len(lines)):
        if end_pattern.match(lines[i]):
            end_line = i
            break

    has_end_marker = end_line is not None
    if end_line is None:
        # Without a boundary we must not claim that an arbitrary local label
        # or 100-line slice is the entire procedure. Show the module remainder
        # and mark the boundary as uncertain in the batch output.
        end_line = len(lines) - 1

    # Extract procedure with context
    context_before = 3
    context_after = 2

    extract_start = max(0, start_line - context_before)
    extract_end = min(len(lines), end_line + context_after + 1)

    return lines[extract_start:extract_end], has_end_marker


def find_procedure(asm_file, proc_name):
    """Find a procedure in the include index or a single source module."""
    for module in source_modules(asm_file):
        found = find_procedure_in_file(module, proc_name)
        if found is not None:
            lines, has_end_marker = found
            return module, lines, has_end_marker
    return None


def extract_procedure_code(proc_name, source_file):
    """Extract procedure code and identify its owning module."""
    found = find_procedure(source_file, proc_name)
    if found is None:
        return f"Error: Procedure {proc_name} not found"
    module, lines, has_end_marker = found
    boundary_note = "" if has_end_marker else "Boundary: no matching End of function marker; showing module remainder\n"
    return f"Source module: {module}\n{boundary_note}" + "\n".join(line.rstrip() for line in lines)


def format_sections(proc):
    """Format section changes as readable string."""
    parts = []
    if proc.get("RAM") == "Y":
        parts.append("RAM")
    if proc.get("VDP") == "Y":
        parts.append("VDP")
    if proc.get("Z80") == "Y":
        parts.append("Z80")
    if proc.get("YM2612") == "Y":
        parts.append("YM2612")
    if proc.get("PSG") == "Y":
        parts.append("PSG")
    return ", ".join(parts) if parts else "none"


def main(argv=None):
    parser = argparse.ArgumentParser(description="Prepare batch of procedures for documentation")
    report_input = parser.add_mutually_exclusive_group(required=True)
    report_input.add_argument("--report", help="Analysis report CSV file")
    report_input.add_argument("--movie-file", help="Selected movie marker")
    parser.add_argument("--count", type=int, default=40, help="Number of procedures")
    parser.add_argument("--output", required=True, help="Output file")
    parser.add_argument("--source", default="src/main.s", help="ROM-ordered source include index")

    args = parser.parse_args(argv)

    try:
        report_file = report_for_movie(Path(args.movie_file)) if args.movie_file else Path(args.report)
    except ValueError as error:
        print(f"Error: {error}")
        return 1
    output_file = Path(args.output)
    source_file = Path(args.source)

    if not report_file.exists():
        print(f"Error: Report not found: {report_file}")
        print(f"Run 'make report MOVIE=<type>' first")
        return 1

    print(f"Loading procedures from {report_file}...")
    procedures = load_procedures_from_report(report_file, args.count)

    if not procedures:
        print("No unprocessed procedures found!")
        return 0

    print(f"Found {len(procedures)} procedures for this batch")
    print(f"Extracting code...")

    with open(output_file, "w", encoding="utf-8") as out:
        out.write("=" * 80 + "\n")
        out.write(f"DOCUMENTATION BATCH - {len(procedures)} procedures\n")
        out.write("=" * 80 + "\n\n")

        out.write("Instructions for Claude:\n")
        out.write("-" * 40 + "\n")
        out.write("1. Analyze each procedure below\n")
        out.write("2. Create workflow/rename_batch.csv with columns:\n")
        out.write("   old_name,new_name,description\n")
        out.write("3. Run: make rename\n")
        out.write("\n")
        out.write("CSV format example:\n")
        out.write("old_name,new_name,description\n")
        out.write('sub_1234,Player_UpdateHealth,"Updates player health bar"\n')
        out.write('sub_5678,Enemy_CheckCollision,"Checks enemy collision with player"\n')
        out.write("\n" + "=" * 80 + "\n\n")

        for i, proc in enumerate(procedures, 1):
            proc_name = proc["procedure"]
            print(f"[{i}/{len(procedures)}] {proc_name}...")

            out.write("\n" + "=" * 80 + "\n")
            out.write(f"[{i}/{len(procedures)}] {proc_name}\n")
            out.write("=" * 80 + "\n\n")

            out.write(f"Address:     {proc['address']}\n")
            out.write(f"Scene:       {proc['scene']}\n")
            out.write(f"Frame:       {proc['frame']}\n")
            out.write(f"Change type: {proc['change_type']}\n")
            out.write(f"Sections:    {format_sections(proc)}\n")

            # Visual diff path hint
            frame = proc.get("frame", "0")
            try:
                frame_num = int(frame)
                out.write(f"\nVisual diff: diffs/*/[{proc_name}]/{frame_num:06d}_diff.png\n")
            except (ValueError, TypeError):
                out.write(f"\nVisual diff: diffs/*/[{proc_name}]/\n")

            out.write("\n--- CODE ---\n\n")
            code = extract_procedure_code(proc_name, source_file)
            out.write(code)
            out.write("\n")

    print(f"\nBatch prepared: {output_file}")
    print(f"\nNext: Claude analyzes and creates workflow/rename_batch.csv")

    return 0


if __name__ == "__main__":
    exit(main())

#!/usr/bin/env python3
"""
ROM Procedure Analyzer (Parallel)

Analyzes which reviewed code procedures affect visual output by:
1. Disabling each named procedure in its owning ROM-ordered module
2. Building modified ROM
3. Comparing screenshots with reference during TAS playback
4. Recording first frame where difference occurs

Supports parallel execution with multiple workers.
"""

import os
import sys
import re
import subprocess
import shutil
import argparse
import csv
import tempfile
from pathlib import Path
from concurrent.futures import ProcessPoolExecutor, as_completed
import time

from prepare_batch import source_modules


def load_procedures_from_file(procedures_file, source_file):
    """Resolve named code procedures to one owning module each."""
    names = [
        line.strip()
        for line in Path(procedures_file).read_text(encoding="utf-8").splitlines()
        if line.strip() and not line.lstrip().startswith("#")
    ]
    if len(names) != len(set(names)):
        raise ValueError(f"{procedures_file}: duplicate procedure name")
    if any(not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", name) for name in names):
        raise ValueError(f"{procedures_file}: invalid procedure name")

    source = Path(source_file)
    project_dir = source.resolve().parent.parent
    wanted = set(names)
    found = {}
    for module_index, module in enumerate(source_modules(source)):
        lines = module.read_text(encoding="utf-8").splitlines()
        function_ends = {
            match.group(1)
            for line in lines
            if (match := re.match(r"^; End of function\s+([A-Za-z_][A-Za-z0-9_]*)(?:\s|$)", line))
        }
        for line_num, line in enumerate(lines, 1):
            match = re.match(r"^([A-Za-z_][A-Za-z0-9_]*):", line)
            if not match or match.group(1) not in wanted:
                continue
            name = match.group(1)
            if name in found:
                raise ValueError(f"{name}: defined in more than one source module")
            if name not in function_ends:
                raise ValueError(f"{module}:{line_num}: {name} has no function end marker")
            found[name] = {
                "name": name,
                "module": module.resolve().relative_to(project_dir).as_posix(),
                "line": line_num,
                "position": (module_index, line_num),
            }
    missing = [name for name in names if name not in found]
    if missing:
        raise ValueError(f"procedures not found in source modules: {', '.join(missing)}")
    ordered = sorted(found.values(), key=lambda item: item["position"])
    return [
        {key: value for key, value in item.items() if key != "position"} | {"order": index}
        for index, item in enumerate(ordered)
    ]


def disable_procedure(source_file, proc_name):
    """Add 'rts' after procedure label to disable it."""
    pattern = re.compile(rf"^({re.escape(proc_name)}:.*?)$", re.MULTILINE)

    with open(source_file, "r", encoding="utf-8") as f:
        content = f.read()

    def replacer(match):
        return match.group(1) + "\n\trts\t; DISABLED BY ANALYZER"

    new_content, count = pattern.subn(replacer, content)
    if count != 1:
        raise ValueError(f"{source_file}: expected one definition of {proc_name}, found {count}")

    with open(source_file, "w", encoding="utf-8") as f:
        f.write(new_content)


def setup_worker_dir(project_dir, proc_name, temp_base):
    """Create isolated worker directory with project copy."""
    worker_dir = Path(temp_base) / proc_name
    worker_dir.mkdir()
    project = Path(project_dir)
    shutil.copy2(project / "Makefile", worker_dir / "Makefile")
    for dirname in ("bin", "data", "src", "scripts", "assets", "config"):
        shutil.copytree(project / dirname, worker_dir / dirname)
    if (project / "mk").is_dir():
        shutil.copytree(project / "mk", worker_dir / "mk")
    # A perturbation build is intentionally not byte-identical. Its private
    # worker needs extracted assets, not another copy of the user's ROM dump.
    return str(worker_dir)


def build_rom(worker_dir):
    """Build ROM using make."""
    result = subprocess.run(["make", "build"], cwd=worker_dir, capture_output=True, text=True)
    return result.returncode == 0, result.stderr


def run_comparison(
    gens_exe,
    rom_file,
    movie_file,
    reference_dir,
    diffs_dir,
    proc_name,
    interval=20,
    max_frames=90000,
    max_diffs=10,
    max_memory_diffs=10,
    frameskip=0,
    window_x=None,
    window_y=None,
    diff_color=None,
):
    """Run emulator in comparison mode.

    Returns: (first_visual_diff_frame, visual_diff_count, first_memory_diff_frame, memory_diff_count)
    """
    os.makedirs(diffs_dir, exist_ok=True)
    proc_diffs_dir = tempfile.mkdtemp(prefix=f"{proc_name}_", dir=diffs_dir)

    # Emulator must run from its own directory to find DLLs
    gens_dir = os.path.dirname(gens_exe)

    cmd = [
        gens_exe,
        "-rom",
        rom_file,
        "-play",
        movie_file,
        "-screenshot-interval",
        str(interval),
        "-reference-dir",
        reference_dir,
        "-screenshot-dir",
        proc_diffs_dir,
        "-max-frames",
        str(max_frames),
        "-max-diffs",
        str(max_diffs),
        "-max-memory-diffs",
        str(max_memory_diffs),
        "-turbo",
        "-frameskip",
        str(frameskip),
        "-nosound",
    ]

    # Add window position if specified
    if window_x is not None:
        cmd.extend(["-window-x", str(window_x)])
    if window_y is not None:
        cmd.extend(["-window-y", str(window_y)])

    # Add diff color if specified
    if diff_color:
        cmd.extend(["-diff-color", diff_color])

    replay = subprocess.run(cmd, capture_output=True, cwd=gens_dir)
    if replay.returncode != 0:
        raise RuntimeError(
            f"emulator exited with code {replay.returncode}: {replay.stderr.decode(errors='replace')[-500:]}"
        )

    # Find visual diffs (PNG files, excluding _diff.png files which are visualizations)
    visual_diffs = sorted([f for f in os.listdir(proc_diffs_dir) if f.endswith(".png") and not f.endswith("_diff.png")])

    # Find memory diffs (_memdiff.csv files contain actual byte differences)
    memory_diffs = sorted([f for f in os.listdir(proc_diffs_dir) if f.endswith("_memdiff.csv")])

    first_visual_diff = None
    first_memory_diff = None

    if visual_diffs:
        first_visual_diff = int(visual_diffs[0].replace(".png", ""))

    if memory_diffs:
        # Memory diff files are named XXXXXX_memdiff.csv
        first_memory_diff = int(memory_diffs[0].replace("_memdiff.csv", ""))

    # Remove directory only if empty
    if not visual_diffs and not memory_diffs:
        os.rmdir(proc_diffs_dir)

    return first_visual_diff, len(visual_diffs), first_memory_diff, len(memory_diffs)


def analyze_single_procedure(args_tuple):
    """Analyze a single procedure (worker function)."""
    (
        proc,
        project_dir,
        temp_base,
        gens_exe,
        movie_file,
        reference_dir,
        diffs_dir,
        interval,
        max_frames,
        max_diffs,
        max_memory_diffs,
        frameskip,
        worker_index,
        grid_cols,
        window_width,
        window_height,
        diff_color,
    ) = args_tuple

    proc_name = proc["name"]

    # Calculate window position based on worker index (grid layout)
    col = worker_index % grid_cols
    row = worker_index // grid_cols
    window_x = col * window_width
    window_y = row * window_height

    try:
        # Setup worker directory (unique per procedure)
        worker_dir = setup_worker_dir(project_dir, proc_name, temp_base)
        source_file = os.path.join(worker_dir, proc["module"])
        rom_file = os.path.join(worker_dir, "asbuilt.bin")

        # Disable procedure
        disable_procedure(source_file, proc_name)

        # Build ROM
        success, error = build_rom(worker_dir)
        if not success:
            return {
                "procedure": proc_name,
                "module": proc["module"],
                "order": proc["order"],
                "line": proc["line"],
                "first_visual_frame": "BUILD_ERROR",
                "visual_diff_count": 0,
                "first_memory_frame": "",
                "memory_diff_count": 0,
                "status": "error",
            }

        # Run comparison (now returns both visual and memory diffs)
        first_visual, visual_count, first_memory, memory_count = run_comparison(
            gens_exe,
            rom_file,
            movie_file,
            reference_dir,
            diffs_dir,
            proc_name,
            interval,
            max_frames,
            max_diffs,
            max_memory_diffs,
            frameskip,
            window_x,
            window_y,
            diff_color,
        )

        # Determine status based on what kind of diffs were found
        if first_visual is not None and first_memory is not None:
            status = "both"  # Both visual and memory differences
        elif first_visual is not None:
            status = "visual"  # Only visual differences
        elif first_memory is not None:
            status = "memory"  # Only memory differences (no visual change)
        else:
            status = "no_change"

        return {
            "procedure": proc_name,
            "module": proc["module"],
            "order": proc["order"],
            "line": proc["line"],
            "first_visual_frame": first_visual if first_visual else "",
            "visual_diff_count": visual_count,
            "first_memory_frame": first_memory if first_memory else "",
            "memory_diff_count": memory_count,
            "status": status,
        }

    except Exception as e:
        return {
            "procedure": proc_name,
            "module": proc["module"],
            "order": proc["order"],
            "line": proc["line"],
            "first_visual_frame": f"ERROR: {str(e)}",
            "visual_diff_count": 0,
            "first_memory_frame": "",
            "memory_diff_count": 0,
            "status": "error",
        }


def analyze_procedures(args):
    """Main analysis loop with parallel execution."""
    project_dir = str(Path(args.project_dir).resolve())
    if args.workers < 1 or args.grid_cols < 1:
        print("Error: workers and grid columns must be positive")
        return 1

    # Check procedures file first (required)
    if not args.procedures_file:
        print("Error: --procedures-file is required")
        print("")
        print("To generate a list of unanalyzed procedures, run:")
        print("  make find-unanalyzed")
        print("")
        print("This will create unanalyzed_procedures.txt with procedures that need analysis.")
        return 1

    procedures_file = os.path.join(project_dir, args.procedures_file)
    if not os.path.exists(procedures_file):
        print(f"Error: Procedures file not found: {procedures_file}")
        print("")
        print("To generate a list of unanalyzed procedures, run:")
        print("  make find-unanalyzed")
        return 1

    # Build other paths
    source_file = os.path.join(project_dir, args.source)
    movie_file = os.path.join(project_dir, args.movie)
    reference_dir = os.path.join(project_dir, args.reference)
    diffs_dir = os.path.join(project_dir, args.diffs)
    gens_exe = os.path.join(project_dir, args.gens)
    results_file = os.path.join(project_dir, args.output)

    # Verify paths
    if not os.path.exists(source_file):
        print(f"Error: Source file not found: {source_file}")
        return 1
    if not os.path.exists(reference_dir):
        print(f"Error: Reference directory not found: {reference_dir}")
        return 1
    if not os.path.exists(gens_exe):
        print(f"Error: Emulator not found: {gens_exe}")
        return 1
    if not os.path.exists(movie_file):
        print(f"Error: Movie file not found: {movie_file}")
        return 1

    # Load procedures from file
    print(f"Loading procedures from {args.procedures_file}...")
    try:
        procedures = load_procedures_from_file(procedures_file, source_file)
    except (OSError, ValueError) as error:
        print(f"Error: {error}")
        return 1
    print(f"Loaded {len(procedures)} procedures from file")

    if not procedures:
        print("No hypothesis-level code procedures to analyze")
        return 0

    if args.limit:
        procedures = procedures[: args.limit]
        print(f"Limited to first {args.limit} procedures")

    if args.start_from:
        start_idx = 0
        for i, proc in enumerate(procedures):
            if proc["name"] == args.start_from:
                start_idx = i
                break
        procedures = procedures[start_idx:]
        print(f"Starting from {args.start_from} ({len(procedures)} remaining)")

    # Create directories
    os.makedirs(diffs_dir, exist_ok=True)

    # Create a unique, self-owned workspace; never delete a pre-existing tree.
    temp_workspace = tempfile.TemporaryDirectory(prefix="alien_analysis_")
    temp_base = temp_workspace.name

    # Grid layout for window positioning
    grid_cols = args.grid_cols
    window_width = 320
    window_height = 240

    print(f"\nAnalyzing {len(procedures)} procedures with {args.workers} workers...")
    print(f"Window grid: {grid_cols} columns, {window_width}x{window_height} per window")
    print("=" * 60)

    # Prepare tasks with worker index for window positioning
    tasks = []
    for i, proc in enumerate(procedures):
        worker_index = i % args.workers  # Cycle through worker slots
        tasks.append(
            (
                proc,
                project_dir,
                temp_base,
                gens_exe,
                movie_file,
                reference_dir,
                diffs_dir,
                args.interval,
                args.max_frames,
                args.max_diffs,
                args.max_memory_diffs,
                args.frameskip,
                worker_index,
                grid_cols,
                window_width,
                window_height,
                args.diff_color,
            )
        )

    # Run in parallel
    results = []
    completed = 0
    start_time = time.time()

    with ProcessPoolExecutor(max_workers=args.workers) as executor:
        futures = {executor.submit(analyze_single_procedure, task): task[0] for task in tasks}

        for future in as_completed(futures):
            proc = futures[future]
            result = future.result()
            results.append(result)
            completed += 1

            # Progress output
            # V=visual, M=memory only, B=both, E=error, .=no change
            status_map = {"visual": "V", "memory": "M", "both": "B", "error": "E", "no_change": "."}
            status_char = status_map.get(result["status"], "?")
            elapsed = time.time() - start_time
            rate = completed / elapsed if elapsed > 0 else 0
            eta = (len(procedures) - completed) / rate if rate > 0 else 0

            print(
                f"\r[{completed}/{len(procedures)}] {status_char} {result['procedure']:<20} "
                f"({rate:.1f}/s, ETA: {eta / 60:.0f}m)      ",
                end="",
                flush=True,
            )

    print("\n" + "=" * 60)

    print("Cleaning up temporary files...")
    temp_workspace.cleanup()

    # Keep the queue's ROM order, not unrelated line numbers across modules.
    results.sort(key=lambda x: x["order"])

    # Save results
    print(f"Saving results to {results_file}...")
    with open(results_file, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(
            f,
            fieldnames=[
                "procedure",
                "module",
                "order",
                "line",
                "first_visual_frame",
                "visual_diff_count",
                "first_memory_frame",
                "memory_diff_count",
                "status",
            ],
        )
        writer.writeheader()
        writer.writerows(results)

    # Summary
    visual_count = sum(1 for r in results if r["status"] == "visual")
    memory_count = sum(1 for r in results if r["status"] == "memory")
    both_count = sum(1 for r in results if r["status"] == "both")
    no_change_count = sum(1 for r in results if r["status"] == "no_change")
    error_count = sum(1 for r in results if r["status"] == "error")
    elapsed = time.time() - start_time

    print(f"\nSummary:")
    print(f"  Visual only:   {visual_count}")
    print(f"  Memory only:   {memory_count}")
    print(f"  Both:          {both_count}")
    print(f"  No change:     {no_change_count}")
    print(f"  Errors:        {error_count}")
    print(f"  Total:         {len(results)}")
    print(f"  Time:          {elapsed / 60:.1f} minutes")

    return 0


def main():
    parser = argparse.ArgumentParser(description="Analyze ROM procedures for visual impact")
    parser.add_argument("--project-dir", default=".", help="Project directory")
    parser.add_argument("--source", default="src/main.s", help="ROM-ordered source include index")
    parser.add_argument("--rom", default="asbuilt.bin", help="Built ROM file")
    parser.add_argument("--movie", default="dammit,truncated-aliensoldier.gmv", help="TAS movie file")
    parser.add_argument("--reference", default="reference", help="Reference screenshots directory")
    parser.add_argument("--diffs", default="diffs", help="Diffs output directory")
    parser.add_argument("--gens", default="gens_automation/Output/Gens.exe", help="Gens emulator path")
    parser.add_argument("--output", default="analysis_results.csv", help="Output CSV file")
    parser.add_argument("--interval", type=int, default=20, help="Screenshot interval")
    parser.add_argument(
        "--max-frames", type=int, default=0, help="Max frames to analyze (0 = no limit, play until movie ends)"
    )
    parser.add_argument("--max-diffs", type=int, default=10, help="Stop after N visual diffs per procedure")
    parser.add_argument("--max-memory-diffs", type=int, default=10, help="Stop after N memory diffs per procedure")
    parser.add_argument("--frameskip", type=int, default=0, help="Frame skip for faster analysis")
    parser.add_argument("--grid-cols", type=int, default=8, help="Number of columns in window grid")
    parser.add_argument(
        "--diff-color",
        default="pink",
        help="Color for diff highlighting (pink, red, green, blue, yellow, cyan, white, orange)",
    )
    parser.add_argument("--procedures-file", help="File with list of procedures to analyze (one per line)")
    parser.add_argument("--limit", type=int, help="Limit number of procedures to analyze")
    parser.add_argument("--start-from", help="Start from specific procedure name")
    parser.add_argument("--workers", "-j", type=int, default=1, help="Number of parallel workers")

    args = parser.parse_args()
    return analyze_procedures(args)


if __name__ == "__main__":
    sys.exit(main())

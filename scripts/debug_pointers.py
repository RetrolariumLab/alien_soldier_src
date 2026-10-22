#!/usr/bin/env python3
"""Retired monolithic pointer experiment; kept only as historical source.

The CLI refuses to run. The module-aware release replacement is
``make verify-relocation``.
"""

import os
import sys
import re
import subprocess
import shutil
import argparse
import time
from pathlib import Path
from concurrent.futures import ProcessPoolExecutor, as_completed


def find_data_blocks(source_file):
    """Find all data blocks by extracting addresses from label names.

    Matches labels like:
    - byte_F5000:  → address 0xF5000
    - word_E8812:  → address 0xE8812
    - off_16FAC:   → address 0x16FAC
    - dword_1234:  → address 0x1234
    - unk_ABCD:    → address 0xABCD

    This catches ALL data types including dc.b, dc.w, dc.l, binclude, etc.
    """
    blocks = []

    with open(source_file, "r", encoding="utf-8", errors="ignore") as f:
        lines = f.readlines()

    # Pattern to match data labels with hex addresses in names
    # Matches: byte_XXXXX, word_XXXXX, dword_XXXXX, off_XXXXX, unk_XXXXX, etc.
    # Note: loc_XXXXX are code locations, not data, so we skip them
    data_label_pattern = re.compile(r"^(byte|word|dword|off|unk)_([0-9A-Fa-f]+):", re.IGNORECASE)

    for i, line in enumerate(lines):
        # Look for data labels with addresses in their names
        match = data_label_pattern.match(line)
        if match:
            label_type = match.group(1)
            address_hex = match.group(2)
            label = f"{label_type}_{address_hex}"

            try:
                address = int(address_hex, 16)

                # Collect ALL data blocks (no sampling)
                blocks.append(
                    {
                        "label": label,
                        "line_num": i + 1,  # 1-based line number
                        "address": address,
                        "line": line.rstrip(),
                    }
                )
            except ValueError:
                # Invalid hex address, skip
                continue

    return blocks


def setup_worker_dir(project_dir, label, temp_base):
    """Create isolated worker directory with project copy."""
    worker_dir = os.path.join(temp_base, label)

    # Clean and recreate
    if os.path.exists(worker_dir):
        shutil.rmtree(worker_dir)
    os.makedirs(worker_dir)

    # Copy essential files
    src_file = os.path.join(project_dir, "alien_soldier_j.s")
    shutil.copy(src_file, worker_dir)

    # Copy Makefile
    shutil.copy(os.path.join(project_dir, "Makefile"), worker_dir)

    # Copy directories
    for dirname in ["bin", "data", "src", "scripts"]:
        src_path = os.path.join(project_dir, dirname)
        dst_path = os.path.join(worker_dir, dirname)
        if os.path.exists(src_path) and not os.path.exists(dst_path):
            shutil.copytree(src_path, dst_path)

    return worker_dir


def insert_padding(source_file, label, line_num):
    """Insert padding (dc.w 0,0,0,0,0,0,0,0) before the specified label."""
    with open(source_file, "r", encoding="utf-8", errors="ignore") as f:
        lines = f.readlines()

    # Insert padding at line_num - 1 (before the label)
    padding = "\t\tdc.w 0, 0, 0, 0, 0, 0, 0, 0 ; DEBUG PADDING\n"
    lines.insert(line_num - 1, padding)

    # Write modified file
    with open(source_file, "w", encoding="utf-8", errors="ignore") as f:
        f.writelines(lines)


def build_rom(worker_dir):
    """Build ROM using make."""
    result = subprocess.run(["make", "build"], cwd=worker_dir, capture_output=True, text=True)
    return result.returncode == 0


def run_comparison(
    gens_exe,
    rom_file,
    movie_file,
    reference_dir,
    diffs_dir,
    label,
    interval=20,
    max_frames=0,
    frameskip=8,
    window_x=None,
    window_y=None,
    diff_color="pink",
):
    """Run emulator in comparison mode.

    IMPORTANT: Stops after collecting 10 VISUAL differences (screenshots with pink highlighting).
    Visual differences are detected by presence of *_diff.png files (with pink highlighting).

    Returns: (first_visual_diff_frame, visual_diff_count, first_memory_diff_frame, memory_diff_count)
    """
    label_diffs_dir = os.path.join(diffs_dir, label)
    if os.path.exists(label_diffs_dir):
        for f in os.listdir(label_diffs_dir):
            os.remove(os.path.join(label_diffs_dir, f))
    else:
        os.makedirs(label_diffs_dir)

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
        label_diffs_dir,
        "-max-diffs",
        "10",  # Stop after 10 VISUAL diffs
        "-max-memory-diffs",
        "0",  # Don't stop on memory diffs (0 = ignore)
        "-memory-after-visual",
        "1",  # Save memory diffs ONLY after first visual diff
        "-turbo",
        "-frameskip",
        str(frameskip),
        "-nosound",
    ]

    if max_frames > 0:
        cmd.extend(["-max-frames", str(max_frames)])

    # Add window position if specified
    if window_x is not None:
        cmd.extend(["-window-x", str(window_x)])
    if window_y is not None:
        cmd.extend(["-window-y", str(window_y)])

    # Add diff color for highlighting
    cmd.extend(["-diff-color", diff_color])

    subprocess.run(cmd, capture_output=True, cwd=gens_dir)

    # IMPORTANT: Visual differences are marked by *_diff.png files!
    # These files show differences with pink highlighting.
    # Format: NNNNNN_diff.png where NNNNNN is the frame number
    diff_screenshots = sorted([f for f in os.listdir(label_diffs_dir) if f.endswith("_diff.png")])

    # Regular screenshots (without _diff suffix)
    regular_screenshots = sorted(
        [f for f in os.listdir(label_diffs_dir) if f.endswith(".png") and not f.endswith("_diff.png")]
    )

    # Find genstate dumps (.gs0 - .gs9)
    genstate_dumps = sorted([f for f in os.listdir(label_diffs_dir) if re.match(r".*\.gs\d$", f)])

    # Find memory diffs (_memdiff.csv files)
    memory_diffs = sorted([f for f in os.listdir(label_diffs_dir) if f.endswith("_memdiff.csv")])

    first_visual_diff = None
    first_memory_diff = None

    # Visual diffs are detected by *_diff.png files (with pink highlighting)!
    if diff_screenshots:
        # Extract frame number from filename like "014220_diff.png"
        first_diff_file = diff_screenshots[0]
        frame_str = first_diff_file.replace("_diff.png", "")
        try:
            first_visual_diff = int(frame_str)
        except ValueError:
            # Fallback: try to extract digits
            import re

            digits = re.search(r"(\d+)_diff\.png", first_diff_file)
            if digits:
                first_visual_diff = int(digits.group(1))

    if memory_diffs:
        first_memory_diff = int(memory_diffs[0].replace("_memdiff.csv", ""))

    # Keep directory only if we have visual diffs (*_diff.png files)
    has_visual_diffs = len(diff_screenshots) > 0

    if not has_visual_diffs:
        try:
            # Clean up if no visual differences found
            shutil.rmtree(label_diffs_dir)
        except:
            pass

    return first_visual_diff, len(diff_screenshots), first_memory_diff, len(memory_diffs)


def test_single_block(args_tuple):
    """Test a single data block (worker function)."""
    (
        block,
        project_dir,
        temp_base,
        gens_exe,
        movie_file,
        reference_dir,
        diffs_dir,
        interval,
        max_frames,
        frameskip,
        worker_index,
        grid_cols,
        window_width,
        window_height,
        diff_color,
    ) = args_tuple

    label = block["label"]

    # Calculate window position based on worker index (grid layout)
    col = worker_index % grid_cols
    row = worker_index // grid_cols
    window_x = col * window_width
    window_y = row * window_height

    try:
        # Setup worker directory
        worker_dir = setup_worker_dir(project_dir, label, temp_base)
        source_file = os.path.join(worker_dir, "alien_soldier_j.s")
        rom_file = os.path.join(worker_dir, "asbuilt.bin")

        # Insert padding before this label
        insert_padding(source_file, label, block["line_num"])

        # Build ROM
        if not build_rom(worker_dir):
            return {
                "label": label,
                "address": block["address"],
                "line": block["line_num"],
                "status": "build_error",
                "first_visual_frame": None,
                "visual_count": 0,
                "first_memory_frame": None,
                "memory_count": 0,
            }

        # Run comparison
        first_visual, visual_count, first_memory, memory_count = run_comparison(
            gens_exe,
            rom_file,
            movie_file,
            reference_dir,
            diffs_dir,
            label,
            interval,
            max_frames,
            frameskip,
            window_x,
            window_y,
            diff_color,
        )

        # Determine status - ONLY visual differences matter!
        # Memory-only differences are not considered problems
        if first_visual is not None:
            status = "DIFFERENCE_FOUND"  # Visual difference = PROBLEM!
        else:
            status = "ok"  # No visual difference = OK (memory diffs don't count)

        return {
            "label": label,
            "address": block["address"],
            "line": block["line_num"],
            "status": status,
            "first_visual_frame": first_visual,
            "visual_count": visual_count,
            "first_memory_frame": first_memory,
            "memory_count": memory_count,
        }

    except Exception as e:
        return {
            "label": label,
            "address": block["address"],
            "line": block["line_num"],
            "status": f"error: {str(e)}",
            "first_visual_frame": None,
            "visual_count": 0,
            "first_memory_frame": None,
            "memory_count": 0,
        }


def main():
    print(
        "ERROR: the monolithic pointer debugger is retired. It selects extinct "
        "address-derived labels and can delete prior diff output. Use "
        "make verify-relocation for the module-aware pointer check."
    )
    return 1

    parser = argparse.ArgumentParser(description="Debug pointer issues by testing data blocks")
    parser.add_argument("--project-dir", default=".", help="Project directory")
    parser.add_argument("--source", default="alien_soldier_j.s", help="Source file")
    parser.add_argument("--rom", default="asbuilt.bin", help="ROM file")
    parser.add_argument("--movie", required=True, help="Movie file to test")
    parser.add_argument("--gens-exe", default="gens_automation/Output/Gens.exe", help="Gens executable")
    parser.add_argument("--reference", required=True, help="Reference directory")
    parser.add_argument("--diffs", required=True, help="Diffs output directory (will create /pointers/ subdirectory)")
    parser.add_argument("--max-frames", type=int, default=0, help="Maximum frames to test (0 = entire movie)")
    parser.add_argument(
        "--start-address", type=lambda x: int(x, 16), default=0x1BD000, help="Starting address (hex, default: 1BD000)"
    )
    parser.add_argument(
        "--end-address", type=lambda x: int(x, 16), default=0x100000, help="Ending address (hex, default: 100000)"
    )
    parser.add_argument("--workers", "-j", type=int, default=24, help="Number of parallel workers")
    parser.add_argument("--grid-cols", type=int, default=6, help="Number of columns in window grid")
    parser.add_argument("--interval", type=int, default=20, help="Screenshot interval")
    parser.add_argument("--frameskip", type=int, default=8, help="Frame skip for faster analysis")
    parser.add_argument("--diff-color", default="pink", help="Color for diff highlighting")

    args = parser.parse_args()

    project_dir = str(Path(args.project_dir).resolve())
    source_file = Path(project_dir) / args.source
    movie_file = Path(project_dir) / args.movie
    gens_exe = Path(project_dir) / args.gens_exe
    reference_dir = Path(project_dir) / args.reference
    diffs_dir = Path(project_dir) / args.diffs

    print("=" * 80)
    print("POINTER DEBUG - Finding Problematic Data Blocks")
    print("=" * 80)
    print(f"Source:     {source_file.name}")
    print(f"Movie:      {movie_file.name}")
    print(f"Range:      ${args.end_address:06X} -> ${args.start_address:06X}")
    print(f"Workers:    {args.workers} parallel emulators")
    print(f"Grid:       {args.grid_cols} columns")
    print(f"Output:     {diffs_dir}")
    print()
    print("Strategy:")
    print("  1. Test ALL data labels (byte_*, word_*, dword_*, off_*) in range")
    print("  2. Insert padding (16 bytes) before each label")
    print("  3. Build ROM and run movie")
    print("  4. Compare screenshots with reference")
    print("  5. Stop after 10 VISUAL differences found per block")
    print("  6. Test from END to START to minimize displacement")
    print("=" * 80)
    print()

    # Verify paths
    if not source_file.exists():
        print(f"ERROR: Source file not found: {source_file}")
        return 1
    if not movie_file.exists():
        print(f"ERROR: Movie file not found: {movie_file}")
        return 1
    if not gens_exe.exists():
        print(f"ERROR: Gens executable not found: {gens_exe}")
        return 1
    if not reference_dir.exists():
        print()
        print("=" * 80)
        print("ERROR: Reference directory not found!")
        print("=" * 80)
        print(f"Directory: {reference_dir}")
        print()
        print("You must generate reference data first by running:")
        movie_type = reference_dir.name  # Extract movie type from path
        print(f"  make reference MOVIE={movie_type}")
        print()
        print("This will capture screenshots and memory dumps from the original ROM")
        print("for comparison during pointer debugging.")
        print("=" * 80)
        return 1

    # Create diffs directory with /pointers/ subdirectory
    pointers_dir = diffs_dir / "pointers"
    pointers_dir.mkdir(parents=True, exist_ok=True)
    diffs_dir = pointers_dir  # Use pointers subdirectory

    # Find ALL data blocks (no sampling!)
    print("Scanning source for ALL data blocks (by label names)...")
    all_blocks = find_data_blocks(str(source_file))
    print(f"Found {len(all_blocks)} data labels total")
    print(f"  Types: byte_*, word_*, dword_*, off_*")

    # Filter blocks in address range and sort from END to START
    blocks = [b for b in all_blocks if args.end_address <= b["address"] <= args.start_address]
    blocks.sort(key=lambda x: x["address"], reverse=True)

    print(f"Testing {len(blocks)} blocks in range ${args.end_address:06X}-${args.start_address:06X}")
    print(
        f"Estimated time: {len(blocks) * 40 / args.workers / 60:.0f}-{len(blocks) * 60 / args.workers / 60:.0f} minutes"
    )
    print()
    print("⏪ Testing from END of ROM backwards to minimize displacement...")
    print("🎯 Looking for VISUAL differences (screenshots with pink highlighting)")
    print()

    # Create temp directory for workers
    temp_base = os.path.join(project_dir, "tmp", "debug_workers")
    if os.path.exists(temp_base):
        shutil.rmtree(temp_base)
    os.makedirs(temp_base)

    # Grid layout for window positioning
    grid_cols = args.grid_cols
    window_width = 320
    window_height = 240

    # Prepare tasks
    tasks = []
    for i, block in enumerate(blocks):
        worker_index = i % args.workers
        tasks.append(
            (
                block,
                project_dir,
                temp_base,
                str(gens_exe),
                str(movie_file),
                str(reference_dir),
                str(diffs_dir),
                args.interval,
                args.max_frames,
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
    first_problem_found = False
    problematic_blocks = []

    print(f"Starting analysis with {args.workers} parallel workers...")
    print("Status: ✓=OK (no visual diff)  ✗=VISUAL_DIFF_FOUND  E=BUILD_ERROR")
    print("=" * 80)

    with ProcessPoolExecutor(max_workers=args.workers) as executor:
        # Submit all tasks
        futures = {executor.submit(test_single_block, task): task[0] for task in tasks}

        for future in as_completed(futures):
            block = futures[future]
            result = future.result()
            results.append(result)
            completed += 1

            # Check if this is a problematic block
            if result["status"] == "DIFFERENCE_FOUND":
                first_problem_found = True
                problematic_blocks.append(result)

            # Progress output
            status_map = {"ok": "✓", "DIFFERENCE_FOUND": "✗", "build_error": "E"}
            status_char = status_map.get(result["status"], "?")
            elapsed = time.time() - start_time
            rate = completed / elapsed if elapsed > 0 else 0
            eta = (len(blocks) - completed) / rate if rate > 0 else 0

            print(
                f"\r[{completed}/{len(blocks)}] {status_char} ${result['address']:06X} {result['label']:<30} "
                f"({rate:.1f}/s, ETA: {eta / 60:.0f}m)      ",
                end="",
                flush=True,
            )

            # If first problem found, don't cancel running tasks but note it
            if first_problem_found and completed == len([f for f in futures if f.done()]):
                # All currently running tasks are done, we can stop
                break

    print("\n" + "=" * 80)

    # Cleanup
    print("Cleaning up temporary files...")
    shutil.rmtree(temp_base, ignore_errors=True)

    # Final report
    elapsed = time.time() - start_time
    print()
    print("=" * 80)
    print("RESULTS")
    print("=" * 80)
    print(f"Tested blocks:      {completed}")
    print(f"Problematic blocks: {len(problematic_blocks)}")
    print(f"Time elapsed:       {elapsed / 60:.1f} minutes")
    print()
    print("Run 'make report-pointers' to analyze results.")
    print("=" * 80)
    return 0


if __name__ == "__main__":
    sys.exit(main())

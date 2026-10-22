#!/usr/bin/env python3
"""
Universal Analysis Report Generator

Generates a comprehensive report for all available analysis types (TAS, longplay, menus):
1. Scans diffs/{type}/ directories to find analyzed procedures
2. Analyzes diff screenshots to detect change types (black screen, frozen, etc.)
3. Compares memory state dumps if available in reference and diffs directories
4. Maps procedures to their functionality in each analysis context
"""

import os
import sys
import csv
import argparse
from pathlib import Path
from collections import defaultdict

# Optional: PIL for image analysis
try:
    from PIL import Image

    HAS_PIL = True
except ImportError:
    HAS_PIL = False


def parse_description_file(filepath):
    """Parse description file into list of (start, end, description) tuples."""
    scenes = []
    with open(filepath, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("Frames"):
                continue

            # Format: "start-end, description"
            parts = line.split(",", 1)
            if len(parts) != 2:
                continue

            frame_range = parts[0].strip()
            description = parts[1].strip()

            # Parse frame range
            if "-" in frame_range:
                start, end = frame_range.split("-")
                try:
                    scenes.append((int(start), int(end), description))
                except ValueError:
                    continue

    return scenes


def get_scene_for_frame(frame, scenes):
    """Find scene description for a given frame number."""
    for start, end, description in scenes:
        if start <= frame <= end:
            return description
    return None


def analyze_image(filepath):
    """Analyze image to detect type: black, red, or normal."""
    if not HAS_PIL:
        return "unknown"

    try:
        img = Image.open(filepath).convert("RGB")
        pixels = list(img.getdata())
        total = len(pixels)

        if total == 0:
            return "unknown"

        # Count pixel types
        black_count = 0
        red_count = 0

        for r, g, b in pixels:
            # Black: very dark pixels
            if r < 20 and g < 20 and b < 20:
                black_count += 1
            # Red: high red, low green/blue
            elif r > 150 and g < 50 and b < 50:
                red_count += 1

        black_ratio = black_count / total
        red_ratio = red_count / total

        if black_ratio > 0.95:
            return "black_screen"
        elif red_ratio > 0.5:
            return "red_screen"
        else:
            return "normal"

    except Exception:
        return "unknown"


def compare_images(path1, path2):
    """Check if two images are identical."""
    if not HAS_PIL:
        return False

    try:
        img1 = Image.open(path1)
        img2 = Image.open(path2)

        if img1.size != img2.size:
            return False

        # Compare pixel by pixel (sample for speed)
        pixels1 = list(img1.getdata())
        pixels2 = list(img2.getdata())

        return pixels1 == pixels2

    except Exception:
        return False


def parse_memdiff_csv(csv_path):
    """Parse _memdiff.csv file and return section statistics.

    Returns dict with:
        - sections: dict of section_name -> diff_count
        - total_diffs: total number of byte differences
        - section_details: dict of section_name -> list of (address, expected, actual)
    """
    if not os.path.exists(csv_path):
        return None

    try:
        sections = defaultdict(int)
        section_details = defaultdict(list)
        total_diffs = 0

        with open(csv_path, "r", encoding="utf-8") as f:
            reader = csv.DictReader(f)
            for row in reader:
                section = row.get("section", "")
                if not section:
                    continue

                sections[section] += 1
                total_diffs += 1

                # Store first few details per section
                if len(section_details[section]) < 5:
                    section_details[section].append(
                        {
                            "address": row.get("address", ""),
                            "expected": row.get("expected", ""),
                            "actual": row.get("actual", ""),
                        }
                    )

        if total_diffs == 0:
            return None

        return {"sections": dict(sections), "total_diffs": total_diffs, "section_details": dict(section_details)}

    except Exception as e:
        return {"error": str(e)}


def find_memdiff_files(proc_dir):
    """Find all _memdiff.csv files in a procedure directory.

    Returns list of (frame_number, filepath) tuples sorted by frame.
    """
    memdiff_files = []

    if not os.path.isdir(proc_dir):
        return memdiff_files

    for filename in os.listdir(proc_dir):
        if filename.endswith("_memdiff.csv"):
            try:
                frame = int(filename.replace("_memdiff.csv", ""))
                memdiff_files.append((frame, os.path.join(proc_dir, filename)))
            except ValueError:
                continue

    return sorted(memdiff_files, key=lambda x: x[0])


def aggregate_memdiff_sections(proc_dir):
    """Aggregate memory diff sections across all frames for a procedure.

    Returns dict with:
        - sections: dict of section_name -> total diff count across all frames
        - frames_with_diffs: number of frames that have memory diffs
        - first_frame: first frame with memory diff
    """
    memdiff_files = find_memdiff_files(proc_dir)

    if not memdiff_files:
        return None

    aggregated_sections = defaultdict(int)
    frames_with_diffs = 0
    first_frame = None

    for frame, filepath in memdiff_files:
        result = parse_memdiff_csv(filepath)
        if result and "sections" in result:
            frames_with_diffs += 1
            if first_frame is None:
                first_frame = frame

            for section, count in result["sections"].items():
                aggregated_sections[section] += count

    if frames_with_diffs == 0:
        return None

    return {"sections": dict(aggregated_sections), "frames_with_diffs": frames_with_diffs, "first_frame": first_frame}


def compare_state_dumps(ref_path, diff_path):
    """Compare two state dump files and return comparison summary."""
    if not ref_path.exists() or not diff_path.exists():
        return None

    try:
        # Read both files
        with open(ref_path, "rb") as f:
            ref_data = f.read()
        with open(diff_path, "rb") as f:
            diff_data = f.read()

        if len(ref_data) != len(diff_data):
            return {"status": "size_mismatch", "ref_size": len(ref_data), "diff_size": len(diff_data)}

        # Compare RAM section (at offset 176, 65536 bytes)
        ram_offset = 176
        ram_size = 65536

        if len(ref_data) >= ram_offset + ram_size:
            ref_ram = ref_data[ram_offset : ram_offset + ram_size]
            diff_ram = diff_data[ram_offset : ram_offset + ram_size]

            # Count different bytes
            diff_count = sum(1 for a, b in zip(ref_ram, diff_ram) if a != b)
            diff_percentage = (diff_count / ram_size) * 100

            # Find ranges of differences
            diff_ranges = []
            in_diff = False
            start_addr = None

            for i, (a, b) in enumerate(zip(ref_ram, diff_ram)):
                if a != b:
                    if not in_diff:
                        start_addr = i
                        in_diff = True
                else:
                    if in_diff:
                        diff_ranges.append((start_addr, i - 1))
                        in_diff = False

            if in_diff:
                diff_ranges.append((start_addr, ram_size - 1))

            return {
                "status": "compared",
                "diff_bytes": diff_count,
                "diff_percentage": diff_percentage,
                "diff_ranges": diff_ranges[:10],  # First 10 ranges
            }

    except Exception as e:
        return {"status": "error", "message": str(e)}

    return None


def scan_diffs_directory(diffs_dir):
    """Scan diffs directory to find analyzed procedures."""
    procedures = []

    if not diffs_dir.exists():
        return procedures

    # Each subdirectory is a procedure
    for proc_dir in diffs_dir.iterdir():
        if not proc_dir.is_dir():
            continue

        proc_name = proc_dir.name

        # Find screenshots (non-diff files)
        screenshots = sorted([f for f in proc_dir.iterdir() if f.suffix == ".png" and "_diff" not in f.name])

        if not screenshots:
            continue

        # Get first frame number from first screenshot
        first_screenshot = screenshots[0]
        try:
            first_frame = int(first_screenshot.stem)
        except ValueError:
            continue

        procedures.append({"name": proc_name, "first_frame": first_frame, "screenshot_count": len(screenshots)})

    return procedures


def analyze_procedure_diffs(proc_dir, ref_dir, analysis_type):
    """Analyze diff screenshots, state dumps, and memory diffs for a procedure.

    Returns:
        change_type: 'black_screen', 'red_screen', 'frozen', 'visual_change', 'memory_only', 'no_diffs'
        frames: list of frame numbers with diffs
        state_comparison: legacy state dump comparison (may be None)
        memdiff_info: aggregated memory diff sections (may be None)
    """
    if not os.path.isdir(proc_dir):
        return "no_diffs", [], None, None

    # Get all non-diff screenshots
    screenshots = sorted([f for f in os.listdir(proc_dir) if f.endswith(".png") and "_diff" not in f])

    # Get frame numbers from screenshots
    frames = []
    for s in screenshots:
        try:
            frame = int(s.replace(".png", ""))
            frames.append(frame)
        except ValueError:
            continue

    # Aggregate memory diff sections
    memdiff_info = aggregate_memdiff_sections(proc_dir)

    # If no screenshots but have memory diffs, it's memory-only change
    if not frames and memdiff_info:
        # Get frames from memdiff files
        memdiff_files = find_memdiff_files(proc_dir)
        frames = [f[0] for f in memdiff_files]
        return "memory_only", frames, None, memdiff_info

    if not frames:
        return "no_diffs", [], None, None

    # Analyze first screenshot
    first_screenshot = os.path.join(proc_dir, screenshots[0])
    first_type = analyze_image(first_screenshot)

    # Check for frozen game
    is_frozen = False
    if len(screenshots) >= 3:
        identical_count = 0
        for i in range(len(screenshots) - 1):
            path1 = os.path.join(proc_dir, screenshots[i])
            path2 = os.path.join(proc_dir, screenshots[i + 1])
            if compare_images(path1, path2):
                identical_count += 1

        if identical_count >= len(screenshots) - 2:
            is_frozen = True

    # Determine change type
    if first_type == "black_screen":
        change_type = "black_screen"
    elif first_type == "red_screen":
        change_type = "red_screen"
    elif is_frozen:
        change_type = "frozen"
    else:
        change_type = "visual_change"

    # Compare state dumps if available (legacy)
    state_comparison = None
    if ref_dir and frames:
        first_frame = frames[0]
        ref_state = Path(ref_dir) / f"{first_frame:06d}.genstate"
        diff_state = Path(proc_dir) / f"{first_frame:06d}.genstate"

        if ref_state.exists() and diff_state.exists():
            state_comparison = compare_state_dumps(ref_state, diff_state)

    return change_type, frames, state_comparison, memdiff_info


def detect_available_analyses(project_dir):
    """Auto-detect available analysis types based on description files and diffs."""
    available = []
    project_path = Path(project_dir)

    for analysis_type in ["tas", "longplay", "menus"]:
        desc_file = project_path / "movies" / f"{analysis_type}_description.txt"
        diffs_dir = project_path / "diffs" / analysis_type

        if desc_file.exists() and diffs_dir.exists():
            available.append(analysis_type)

    return available


def generate_report(args):
    """Generate the universal analysis report."""
    project_dir = Path(args.project_dir).resolve()
    output_dir = Path(args.output_dir).resolve() if args.output_dir != "." else project_dir
    output_file = output_dir / args.output

    # Auto-detect available analyses
    print("Detecting available analysis types...")
    available_types = detect_available_analyses(project_dir)

    if not available_types:
        print("Error: No analysis types found!")
        print("  Expected: movies/{type}_description.txt and diffs/{type}/ directories")
        return 1

    # Filter to specific movie type if requested
    if args.movie:
        if args.movie not in available_types:
            print(f"Error: Movie type '{args.movie}' not found!")
            print(f"  Available: {', '.join(available_types)}")
            return 1
        available_types = [args.movie]
        print(f"  Processing only: {args.movie}")
    else:
        print(f"  Found: {', '.join(available_types)}")

    # Process each analysis type
    all_reports = {}
    total_procedures = 0

    for analysis_type in available_types:
        print(f"\nProcessing {analysis_type} analysis...")

        # Load description file
        desc_file = project_dir / "movies" / f"{analysis_type}_description.txt"
        scenes = parse_description_file(desc_file)
        print(f"  Found {len(scenes)} scenes")

        # Paths
        diffs_dir = project_dir / "diffs" / analysis_type
        ref_dir = project_dir / "reference" / analysis_type

        # Scan diffs directory for procedures
        print(f"  Scanning diffs directory...")
        procedures = scan_diffs_directory(diffs_dir)
        print(f"  Found {len(procedures)} procedures with diffs")
        total_procedures += len(procedures)

        # Analyze procedures
        print(f"  Analyzing screenshots and state dumps...")
        scene_procedures = defaultdict(list)
        unknown_procedures = []

        for i, proc in enumerate(procedures):
            proc_name = proc["name"]
            first_frame = proc["first_frame"]

            # Analyze diffs
            proc_diff_dir = diffs_dir / proc_name
            change_type, frames, state_cmp, memdiff_info = analyze_procedure_diffs(
                proc_diff_dir, ref_dir if ref_dir.exists() else None, analysis_type
            )

            # Get scene
            scene = get_scene_for_frame(first_frame, scenes)

            # Format change type
            if change_type == "black_screen":
                change_desc = "causes black screen"
            elif change_type == "red_screen":
                change_desc = "causes red screen (crash)"
            elif change_type == "frozen":
                change_desc = "causes game freeze"
            elif change_type == "visual_change":
                change_desc = "visual effect"
            elif change_type == "memory_only":
                change_desc = "memory change only"
            else:
                change_desc = "unknown effect"

            entry = {
                "procedure": proc_name,
                "first_frame": first_frame,
                "scene": scene,
                "change_type": change_type,
                "change_desc": change_desc,
                "frame_count": len(frames),
                "state_comparison": state_cmp,
                "memdiff_info": memdiff_info,
            }

            if scene:
                scene_procedures[scene].append(entry)
            else:
                unknown_procedures.append(entry)

            if (i + 1) % 100 == 0:
                print(f"    Processed {i + 1}/{len(procedures)}...")

        all_reports[analysis_type] = {
            "scenes": scene_procedures,
            "unknown": unknown_procedures,
            "scene_order": {scene[2]: scene[0] for scene in scenes},
        }

    # Generate separate text reports for each analysis type
    print(f"\nWriting separate reports to {output_dir}...")

    for analysis_type in available_types:
        txt_output = output_dir / f"analysis_report_{analysis_type}.txt"
        print(f"  Writing {txt_output.name}...")

        with open(txt_output, "w", encoding="utf-8") as f:
            report_data = all_reports[analysis_type]
            scene_procedures = report_data["scenes"]
            unknown_procedures = report_data["unknown"]
            scene_order = report_data["scene_order"]

            # Count procedures for this analysis type
            type_proc_count = sum(len(procs) for procs in scene_procedures.values()) + len(unknown_procedures)

            f.write("=" * 80 + "\n")
            f.write(f"ALIEN SOLDIER {analysis_type.upper()} ANALYSIS REPORT\n")
            f.write("=" * 80 + "\n\n")

            f.write(f"Total procedures with diffs: {type_proc_count}\n\n")

            # Statistics by change type
            change_stats = defaultdict(int)
            memory_diff_count = 0

            # Section statistics
            section_stats = defaultdict(int)

            for scene_procs in scene_procedures.values():
                for p in scene_procs:
                    change_stats[p["change_type"]] += 1
                    if p.get("state_comparison"):
                        memory_diff_count += 1
                    if p.get("memdiff_info") and "sections" in p["memdiff_info"]:
                        for section in p["memdiff_info"]["sections"]:
                            section_stats[section] += 1

            for p in unknown_procedures:
                change_stats[p["change_type"]] += 1
                if p.get("state_comparison"):
                    memory_diff_count += 1
                if p.get("memdiff_info") and "sections" in p["memdiff_info"]:
                    for section in p["memdiff_info"]["sections"]:
                        section_stats[section] += 1

            f.write(f"Change type statistics:\n")
            for ctype, count in sorted(change_stats.items(), key=lambda x: -x[1]):
                f.write(f"  {ctype}: {count}\n")

            if memory_diff_count > 0:
                f.write(f"  memory_analyzed: {memory_diff_count}\n")

            if section_stats:
                f.write(f"\nSection change statistics (procedures affecting each section):\n")
                # Order sections logically
                section_order = [
                    "M68K_RAM",
                    "M68K_REGS",
                    "VDP_VRAM",
                    "VDP_CRAM",
                    "VDP_VSRAM",
                    "VDP_REGS",
                    "Z80_RAM",
                    "Z80_REGS",
                    "YM2612",
                    "PSG",
                    "SRAM",
                ]
                for section in section_order:
                    if section in section_stats:
                        f.write(f"  {section}: {section_stats[section]} procedures\n")
                # Any other sections not in the predefined order
                for section, count in sorted(section_stats.items()):
                    if section not in section_order:
                        f.write(f"  {section}: {count} procedures\n")

            f.write("\n")
            f.write("-" * 80 + "\n")
            f.write("PROCEDURES BY SCENE\n")
            f.write("-" * 80 + "\n")

            # Sort scenes by frame order
            sorted_scenes = sorted(scene_procedures.keys(), key=lambda s: scene_order.get(s, 999999))

            for scene in sorted_scenes:
                procs = scene_procedures[scene]
                f.write(f"\n--- {scene} ---\n\n")

                # Sort by first frame
                procs.sort(key=lambda p: p["first_frame"])

                for p in procs:
                    f.write(f"{p['procedure']}: {p['change_desc']} (frame {p['first_frame']})")

                    # Add section info from memdiff if available
                    if p.get("memdiff_info") and "sections" in p["memdiff_info"]:
                        sections = list(p["memdiff_info"]["sections"].keys())
                        f.write(f" [{', '.join(sections)}]")
                    # Fall back to legacy state comparison
                    elif p.get("state_comparison"):
                        state_cmp = p["state_comparison"]
                        if state_cmp.get("status") == "compared":
                            diff_pct = state_cmp["diff_percentage"]
                            f.write(f" [RAM: {diff_pct:.2f}% changed]")

                    f.write("\n")

            if unknown_procedures:
                f.write(f"\n--- Unknown scene ---\n\n")
                unknown_procedures.sort(key=lambda p: p["first_frame"])
                for p in unknown_procedures:
                    f.write(f"{p['procedure']}: {p['change_desc']} (frame {p['first_frame']})")

                    # Add section info from memdiff if available
                    if p.get("memdiff_info") and "sections" in p["memdiff_info"]:
                        sections = list(p["memdiff_info"]["sections"].keys())
                        f.write(f" [{', '.join(sections)}]")
                    # Fall back to legacy state comparison
                    elif p.get("state_comparison"):
                        state_cmp = p["state_comparison"]
                        if state_cmp.get("status") == "compared":
                            diff_pct = state_cmp["diff_percentage"]
                            f.write(f" [RAM: {diff_pct:.2f}% changed]")

                    f.write("\n")

    print("Report generated successfully!")

    # Generate separate CSV reports for each analysis type
    def extract_sections(p):
        """Extract section info from procedure entry."""
        sections = {}
        if p.get("memdiff_info") and "sections" in p["memdiff_info"]:
            for section, count in p["memdiff_info"]["sections"].items():
                sections[section] = count
        return sections

    def get_address(proc_name):
        """Extract hex address from procedure name (sub_XXXX, loc_XXXX, etc)."""
        parts = proc_name.split("_")
        if len(parts) >= 2:
            try:
                return int(parts[1], 16)
            except ValueError:
                pass
        return 0xFFFFFFFF  # Put unparseable names at end

    def load_processed_procs(csv_path):
        """Load processed status from existing CSV."""
        processed = set()
        if os.path.exists(csv_path):
            try:
                with open(csv_path, "r", encoding="utf-8") as f:
                    reader = csv.DictReader(f)
                    for row in reader:
                        if row.get("processed") == "true":
                            processed.add(row["procedure"])
            except Exception:
                pass
        return processed

    def write_csv_report(csv_path, procs, processed_procs):
        """Write CSV report for a single analysis type."""
        # Sort by address
        procs.sort(key=lambda p: get_address(p["procedure"]))

        with open(csv_path, "w", newline="", encoding="utf-8") as f:
            fieldnames = [
                "procedure",
                "address",
                "scene",
                "frame",
                "change_type",
                "memory_diff_pct",
                "sections",
                "RAM",
                "VDP",
                "Z80",
                "YM2612",
                "PSG",
                "processed",
            ]
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            writer.writeheader()

            for p in procs:
                addr = get_address(p["procedure"])
                sections = p.get("sections", {})

                section_list = sorted(sections.keys())
                section_str = ",".join(section_list) if section_list else ""

                ram_changed = "Y" if "M68K_RAM" in sections or "M68K_REGS" in sections else ""
                vdp_changed = "Y" if any(s.startswith("VDP_") for s in sections) else ""
                z80_changed = "Y" if "Z80_RAM" in sections or "Z80_REGS" in sections else ""
                ym2612_changed = "Y" if "YM2612" in sections else ""
                psg_changed = "Y" if "PSG" in sections else ""

                writer.writerow(
                    {
                        "procedure": p["procedure"],
                        "address": f"0x{addr:X}" if addr != 0xFFFFFFFF else "",
                        "scene": p["scene"],
                        "frame": p["frame"],
                        "change_type": p["change_type"],
                        "memory_diff_pct": f"{p['memory_diff_pct']:.2f}" if p["memory_diff_pct"] is not None else "",
                        "sections": section_str,
                        "RAM": ram_changed,
                        "VDP": vdp_changed,
                        "Z80": z80_changed,
                        "YM2612": ym2612_changed,
                        "PSG": psg_changed,
                        "processed": "true" if p["procedure"] in processed_procs else "false",
                    }
                )

        return len(procs)

    # Generate separate report for each analysis type
    print(f"\nGenerating separate CSV reports...")

    for analysis_type in available_types:
        csv_output = output_dir / f"analysis_report_{analysis_type}.csv"
        report_data = all_reports[analysis_type]

        # Collect procedures for this analysis type
        procs = []

        for scene, scene_procs in report_data["scenes"].items():
            for p in scene_procs:
                sections = extract_sections(p)
                procs.append(
                    {
                        "procedure": p["procedure"],
                        "scene": scene,
                        "frame": p["first_frame"],
                        "change_type": p["change_type"],
                        "memory_diff_pct": p["state_comparison"]["diff_percentage"]
                        if p.get("state_comparison") and p["state_comparison"].get("status") == "compared"
                        else None,
                        "sections": sections,
                    }
                )

        for p in report_data["unknown"]:
            sections = extract_sections(p)
            procs.append(
                {
                    "procedure": p["procedure"],
                    "scene": "",
                    "frame": p["first_frame"],
                    "change_type": p["change_type"],
                    "memory_diff_pct": p["state_comparison"]["diff_percentage"]
                    if p.get("state_comparison") and p["state_comparison"].get("status") == "compared"
                    else None,
                    "sections": sections,
                }
            )

        # Load existing processed status
        processed_procs = load_processed_procs(csv_output)

        # Write CSV
        count = write_csv_report(csv_output, procs, processed_procs)
        print(f"  {analysis_type}: {csv_output.name} ({count} procedures)")

    # Print summary
    print(f"\nSummary:")
    for analysis_type in available_types:
        report_data = all_reports[analysis_type]
        scene_count = len(report_data["scenes"])
        unknown_count = len(report_data["unknown"])
        print(f"  {analysis_type}: {scene_count} scenes, {unknown_count} unknown")

    return 0


def main():
    parser = argparse.ArgumentParser(description="Generate universal analysis report")
    parser.add_argument("--project-dir", default=".", help="Project directory")
    parser.add_argument("--output", default="analysis_report.txt", help="Output report file")
    parser.add_argument("--output-dir", default=".", help="Output directory for reports (default: project root)")
    parser.add_argument(
        "--movie", choices=["tas", "longplay", "menus"], help="Generate report for specific movie type only"
    )

    args = parser.parse_args()
    return generate_report(args)


if __name__ == "__main__":
    sys.exit(main())

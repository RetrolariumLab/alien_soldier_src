#!/usr/bin/env python3
"""
Mass Procedure Renaming Script

Applies procedure renames from database to assembly file:
- Renames function definitions
- Updates all function calls
- Updates cross-references in comments
- Adds description comments above procedures
"""

import csv
import re
import shutil
import argparse
from pathlib import Path
from datetime import datetime


def load_database(csv_file):
    """Load procedures from CSV database that are ready to rename."""
    procedures = []

    with open(csv_file, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            # Only process procedures with new names
            if row["new_name"] and row["new_name"].strip():
                procedures.append(
                    {
                        "old_name": row["old_name"],
                        "new_name": row["new_name"].strip(),
                        "description": row.get("description", "").strip(),
                        "category": row.get("category", "").strip(),
                    }
                )

    return procedures


def get_existing_labels(asm_file):
    """Extract all existing labels from assembly file."""
    labels = set()
    label_pattern = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*):", re.MULTILINE)

    with open(asm_file, "r", encoding="utf-8", errors="ignore") as f:
        content = f.read()

    for match in label_pattern.finditer(content):
        labels.add(match.group(1))

    return labels


def check_name_collisions(procedures, existing_labels):
    """
    Check for name collisions before renaming.

    Returns tuple: (is_valid, errors)
    - is_valid: True if no collisions found
    - errors: List of error messages describing collisions
    """
    errors = []

    # Get set of old names being renamed
    old_names = {p["old_name"] for p in procedures}

    # Check 1: Duplicate new names within the batch
    new_names_count = {}
    for proc in procedures:
        new_name = proc["new_name"]
        if new_name not in new_names_count:
            new_names_count[new_name] = []
        new_names_count[new_name].append(proc["old_name"])

    for new_name, old_names_list in new_names_count.items():
        if len(old_names_list) > 1:
            errors.append(f"DUPLICATE: '{new_name}' is assigned to multiple procedures: {', '.join(old_names_list)}")

    # Check 2: New name collides with existing label (that we're not renaming)
    for proc in procedures:
        new_name = proc["new_name"]
        old_name = proc["old_name"]

        # Skip if new name equals old name (no rename)
        if new_name == old_name:
            continue

        # Check if new name already exists as a label
        if new_name in existing_labels:
            # It's only a collision if that label is not being renamed itself
            if new_name not in old_names:
                errors.append(f"COLLISION: '{old_name}' -> '{new_name}' conflicts with existing label '{new_name}'")

    return len(errors) == 0, errors


def create_backup(source_file):
    """Create timestamped backup of assembly file."""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_file = source_file.parent / f"{source_file.stem}_backup_{timestamp}{source_file.suffix}"
    shutil.copy2(source_file, backup_file)
    return backup_file


def apply_renames(asm_file, procedures, dry_run=False):
    """Apply all renames to assembly file."""
    with open(asm_file, "r", encoding="utf-8", errors="ignore") as f:
        content = f.read()

    original_content = content
    changes_log = []

    for proc in procedures:
        old_name = proc["old_name"]
        new_name = proc["new_name"]
        description = proc["description"]

        # Count occurrences before
        old_pattern = re.compile(r"\b" + re.escape(old_name) + r"\b")
        occurrences_before = len(old_pattern.findall(content))

        # Skip if procedure not found (already renamed)
        if occurrences_before == 0:
            print(f"  {old_name} -> SKIPPED (not found, likely already renamed)")
            changes_log.append(
                {
                    "old_name": old_name,
                    "new_name": new_name,
                    "occurrences_replaced": 0,
                    "remaining_old": 0,
                    "total_new": 0,
                    "skipped": True,
                }
            )
            continue

        print(f"  {old_name} -> {new_name}")

        # 1. Replace function definition with comment
        # Pattern: sub_XXXXX: (with optional whitespace and comments)
        def_pattern = re.compile(r"^(" + re.escape(old_name) + r":)(\s*.*?)$", re.MULTILINE)

        def definition_replacer(match):
            label = match.group(1)
            rest = match.group(2)  # Comments, whitespace, etc.

            # Build new definition with comment
            new_def_parts = []

            # Add description comment if available
            if description:
                new_def_parts.append(f"; {description}")

            # Add new label with "was:" marker
            new_label = f"{new_name}:"
            if rest.strip():
                # Preserve inline comments, add "was:" note
                new_def_parts.append(f"{new_label}{rest}  ; was: {old_name}")
            else:
                new_def_parts.append(f"{new_label}\t\t\t\t; was: {old_name}")

            return "\n".join(new_def_parts)

        content = def_pattern.sub(definition_replacer, content)

        # 2. Replace direct short calls: bsr.w sub_XXXXX
        bsr_pattern = re.compile(r"\bbsr\.w\s+" + re.escape(old_name) + r"\b")
        content = bsr_pattern.sub(f"bsr.w {new_name}", content)

        # 3. Replace direct byte calls: bsr.s sub_XXXXX
        bsrs_pattern = re.compile(r"\bbsr\.s\s+" + re.escape(old_name) + r"\b")
        content = bsrs_pattern.sub(f"bsr.s {new_name}", content)

        # 4. Replace long calls: jsr (sub_XXXXX).l
        jsr_pattern = re.compile(r"\bjsr\s+\(" + re.escape(old_name) + r"\)\.l")
        content = jsr_pattern.sub(f"jsr ({new_name}).l", content)

        # 5. Replace jump instructions: jmp (sub_XXXXX) and jmp sub_XXXXX
        jmp_pattern = re.compile(r"\bjmp\s+\(" + re.escape(old_name) + r"\)")
        content = jmp_pattern.sub(f"jmp ({new_name})", content)
        jmp_pattern2 = re.compile(r"\bjmp\s+" + re.escape(old_name) + r"\b")
        content = jmp_pattern2.sub(f"jmp {new_name}", content)

        # 6. Replace branch instructions: bra.w/bra.s/bne.w/beq.w/etc sub_XXXXX
        # Matches: bXX.w sub_XXXX or bXX.s sub_XXXX (where XX is any branch condition)
        branch_pattern = re.compile(r"\b(b[a-z]{2}\.[ws])\s+" + re.escape(old_name) + r"\b")
        content = branch_pattern.sub(rf"\1 {new_name}", content)

        # 7. Replace data references: dc.l sub_XXXXX
        dcl_pattern = re.compile(r"\bdc\.l\s+" + re.escape(old_name) + r"\b")
        content = dcl_pattern.sub(f"dc.l {new_name}", content)

        # 8. Replace dbf/dbra instructions: dbf dN,sub_XXXXX (with optional space after comma)
        # db instructions can be: dbf, dbra, dbeq, dbne, etc (1-3 letter suffix)
        dbf_pattern = re.compile(r"\b(db[a-z]{1,3})\s+(d\d+),\s*" + re.escape(old_name) + r"\b")
        content = dbf_pattern.sub(rf"\1 \2,{new_name}", content)

        # 9. Replace immediate address values: #sub_XXXXX
        immediate_pattern = re.compile(r"#" + re.escape(old_name) + r"\b")
        content = immediate_pattern.sub(f"#{new_name}", content)

        # 10. Replace PC-relative addressing: jsr/jmp/lea sub_XXXXX(pc)
        pcrel_pattern = re.compile(r"\b(jsr|jmp|lea)\s+" + re.escape(old_name) + r"\(pc\)")
        content = pcrel_pattern.sub(rf"\1 {new_name}(pc)", content)

        # 10a. Replace in arithmetic expressions: sub_XXXXX-label or sub_XXXXX+label
        # Used in offset tables: dc.w label-base or label+base or base-label
        # Right side: -sub_XXXXX or +sub_XXXXX
        expr_right_pattern = re.compile(r"([-+])\s*" + re.escape(old_name) + r"\b")
        content = expr_right_pattern.sub(rf"\1{new_name}", content)
        # Left side: sub_XXXXX- or sub_XXXXX+
        expr_left_pattern = re.compile(r"\b" + re.escape(old_name) + r"\s*([-+])")
        content = expr_left_pattern.sub(rf"{new_name}\1", content)

        # 11. Replace in cross-reference comments
        # ; CODE XREF: sub_XXXXX+XX
        xref_pattern = re.compile(r"(;\s*(?:CODE|DATA)\s+XREF:\s+)" + re.escape(old_name) + r"\b")
        content = xref_pattern.sub(r"\1" + new_name, content)

        # 12. Replace "End of function" markers
        end_pattern = re.compile(r"^(;\s*End of function\s+)" + re.escape(old_name) + r"\s*$", re.MULTILINE)
        content = end_pattern.sub(r"\1" + new_name, content)

        # Count occurrences after
        new_pattern = re.compile(r"\b" + re.escape(new_name) + r"\b")
        occurrences_after = len(new_pattern.findall(content))

        # Check for remaining old references
        remaining_old = len(old_pattern.findall(content))

        changes_log.append(
            {
                "old_name": old_name,
                "new_name": new_name,
                "occurrences_replaced": occurrences_before - remaining_old,
                "remaining_old": remaining_old,
                "total_new": occurrences_after,
                "skipped": False,
            }
        )

    # Write changes if not dry-run
    if not dry_run:
        with open(asm_file, "w", encoding="utf-8", newline="\n") as f:
            f.write(content)

    return changes_log, len(content) != len(original_content)


def update_analysis_report(report_file, renamed_procedures):
    """Mark renamed procedures as processed in analysis_report.csv."""
    if not report_file.exists():
        print(f"Note: Analysis report not found: {report_file}")
        print("      Skipping processed tracking")
        return

    # Read existing report
    rows = []
    with open(report_file, "r", encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f)
        fieldnames = reader.fieldnames

        # Add 'processed' column if not present
        if "processed" not in fieldnames:
            fieldnames = list(fieldnames) + ["processed"]

        # Process rows
        for row in reader:
            # Add processed column with default value if needed
            if "processed" not in row:
                row["processed"] = ""

            # Mark procedure as processed if it was renamed
            if row["procedure"] in renamed_procedures:
                row["processed"] = "true"

            rows.append(row)

    # Write back
    with open(report_file, "w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)

    processed_count = sum(1 for r in rows if r["processed"] == "true")
    print(f"\nUpdated {report_file.name}:")
    print(f"  Marked {len(renamed_procedures)} procedures as processed")
    print(f"  Total processed: {processed_count}/{len(rows)}")


def main():
    print(
        "ERROR: rename_procedures.py is retired because it edits one source file. "
        "Use make rename or scripts/rename_batch.py for module-aware renames."
    )
    return 1

    parser = argparse.ArgumentParser(description="Apply procedure renames from database")
    parser.add_argument("--database", default="procedure_database.csv", help="Procedure database CSV")
    parser.add_argument("--source", default="alien_soldier_j.s", help="Assembly source file")
    parser.add_argument(
        "--report", default="analysis_report.csv", help="Analysis report CSV to mark procedures as processed"
    )
    parser.add_argument("--project-dir", default=".", help="Project directory")
    parser.add_argument("--dry-run", action="store_true", help="Preview changes without applying")
    parser.add_argument("--no-backup", action="store_true", help="Skip creating backup (not recommended)")
    parser.add_argument("--log", default="rename_log.txt", help="Log file for changes")

    args = parser.parse_args()

    project_dir = Path(args.project_dir).resolve()
    db_file = project_dir / args.database
    asm_file = project_dir / args.source
    log_file = project_dir / args.log
    report_file = project_dir / args.report

    if not db_file.exists():
        print(f"Error: Database file not found: {db_file}")
        return 1

    if not asm_file.exists():
        print(f"Error: Assembly file not found: {asm_file}")
        return 1

    print(f"Loading procedure database from {db_file}...")
    procedures = load_database(db_file)

    if not procedures:
        print("No procedures with new names found in database")
        print("Fill in 'new_name' column in CSV before running this script")
        return 0

    print(f"Found {len(procedures)} procedures to rename")

    # Check for name collisions BEFORE making any changes
    print(f"\nChecking for name collisions...")
    existing_labels = get_existing_labels(asm_file)
    print(f"  Found {len(existing_labels)} existing labels in source file")

    is_valid, collision_errors = check_name_collisions(procedures, existing_labels)

    if not is_valid:
        print("\n" + "=" * 80)
        print("ERROR: Name collisions detected! Cannot proceed with renaming.")
        print("=" * 80)
        for error in collision_errors:
            print(f"  {error}")
        print("\nPlease fix these collisions in the database and try again.")
        print("Each new name must be unique and not conflict with existing labels.")
        return 1

    print("  No collisions found - all new names are unique")

    if args.dry_run:
        print("\n*** DRY RUN MODE - No changes will be applied ***\n")
    else:
        if not args.no_backup:
            print("\nCreating backup...")
            backup_file = create_backup(asm_file)
            print(f"Backup created: {backup_file}")

    print(f"\nApplying renames to {asm_file}...")
    changes_log, has_changes = apply_renames(asm_file, procedures, args.dry_run)

    # Write log
    print(f"\nWriting change log to {log_file}...")
    with open(log_file, "w", encoding="utf-8") as f:
        f.write(f"Procedure Rename Log - {datetime.now()}\n")
        f.write(f"Mode: {'DRY RUN' if args.dry_run else 'APPLIED'}\n")
        f.write("=" * 80 + "\n\n")

        for change in changes_log:
            f.write(f"{change['old_name']} -> {change['new_name']}\n")

            if change.get("skipped", False):
                f.write(f"  SKIPPED: Procedure not found (likely already renamed)\n")
            else:
                f.write(f"  Replaced: {change['occurrences_replaced']} occurrences\n")
                f.write(f"  New references: {change['total_new']}\n")

                if change["remaining_old"] > 0:
                    f.write(f"  WARNING: {change['remaining_old']} old references remain!\n")

            f.write("\n")

        f.write("=" * 80 + "\n")
        f.write(f"Total procedures processed: {len(changes_log)}\n")

    # Summary
    print("\n" + "=" * 80)
    print("SUMMARY")
    print("=" * 80)

    renamed = [c for c in changes_log if not c.get("skipped", False)]
    skipped = [c for c in changes_log if c.get("skipped", False)]

    print(f"Procedures renamed: {len(renamed)}")
    if skipped:
        print(f"Procedures skipped (already renamed): {len(skipped)}")
        for c in skipped[:5]:
            print(f"  {c['old_name']}")
        if len(skipped) > 5:
            print(f"  ... and {len(skipped) - 5} more")

    warnings = [c for c in changes_log if c["remaining_old"] > 0 and not c.get("skipped", False)]
    if warnings:
        print(f"\nWARNINGS: {len(warnings)} procedures have remaining old references:")
        for c in warnings[:5]:
            print(f"  {c['old_name']}: {c['remaining_old']} old refs remaining")
        if len(warnings) > 5:
            print(f"  ... and {len(warnings) - 5} more")

    if args.dry_run:
        print("\n*** DRY RUN COMPLETE - No changes applied ***")
        print(f"Review the log at {log_file}")
        print("Run without --dry-run to apply changes")
    else:
        # Always mark procedures as processed if we have any in the log
        if changes_log:
            renamed_procs = [c["old_name"] for c in changes_log]
            update_analysis_report(report_file, renamed_procs)

        if has_changes:
            print(f"\n*** CHANGES APPLIED to {asm_file} ***")
            print(f"Backup: {backup_file if not args.no_backup else 'NONE'}")
            print(f"Log: {log_file}")

            print("\nNext steps:")
            print("  1. Review changes with: git diff alien_soldier_j.s")
            print("  2. Build ROM: make build")
            print("  3. Test that ROM works correctly")
            print("  4. Commit if everything looks good")
        elif skipped:
            print(f"\n*** All procedures already renamed, marked as processed ***")
        else:
            print("\nNo changes made (procedures may already be renamed)")

    return 0


if __name__ == "__main__":
    import sys

    sys.exit(main())

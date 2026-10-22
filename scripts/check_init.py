import argparse
from pathlib import Path


REQUIRED_DATA_DIRS = ("artcomp", "artunc")


def main():
    parser = argparse.ArgumentParser(description="Check that the ROM data required by the assembler exists.")
    parser.add_argument("--data-dir", required=True)
    parser.add_argument("--orig-rom", required=True)
    args = parser.parse_args()

    data_dir = Path(args.data_dir)
    missing = [name for name in REQUIRED_DATA_DIRS if not (data_dir / name).is_dir()]
    if not missing:
        return 0

    print()
    print("============================================================")
    print(" ERROR: Project is not initialized!")
    print("============================================================")
    print()
    print(" The data/ directory (or its required subfolders) is missing.")
    print(" Missing: " + ", ".join(str(data_dir / name) for name in missing))
    print(" Assembly will fail because the source uses binclude/incbin")
    print(" directives that reference data extracted from the ROM.")
    print()
    print(" Please run first:")
    print("   make init")
    print()
    print(" This requires the original ROM file in the project root:")
    print(f"   {args.orig_rom}")
    print("============================================================")
    print()
    return 1


if __name__ == "__main__":
    raise SystemExit(main())

import os
import sys
import platform
import argparse
import subprocess
import hashlib
import json
import shlex


def canonical_rom_error(data, reference):
    """Return a diagnostic when bytes are not the declared preservation input."""
    digest = hashlib.sha1(data).hexdigest()
    if len(data) != reference['size'] or digest != reference['sha1']:
        return (
            f"expected {reference['size']} bytes, SHA1 {reference['sha1']}; "
            f"actual {len(data)} bytes, SHA1 {digest}"
        )
    return None


def first_difference(left, right):
    """Return the first differing byte offset, including a length-only mismatch."""
    return next(
        (index for index, pair in enumerate(zip(left, right)) if pair[0] != pair[1]),
        min(len(left), len(right)),
    )


def detect_platform():
    """Auto-detect host OS/arch and return matching bin/ subfolder.
    Mirrors the logic from Makefile.
    """
    system = platform.system()
    machine = platform.machine()

    if system == "Windows":
        return "windows_i386"
    elif system == "Darwin":
        return f"macos_{machine}"
    else:
        # Linux and other POSIX
        return f"linux_{machine}"


def get_default_tools():
    """Return default (as_bin, p2bin) paths based on detected platform."""
    plat = detect_platform()
    system = platform.system()

    if system == "Windows":
        as_exe = "asw.exe"
        p2bin_exe = "p2bin.exe"
    else:
        # Linux / macOS: no .exe, and AS is called 'asl'
        as_exe = "asl"
        p2bin_exe = "p2bin"

    as_bin = os.path.join("bin", plat, as_exe)
    p2bin = os.path.join("bin", plat, p2bin_exe)
    return as_bin, p2bin


def run_process(cmd):
    """Execute shell command and wait for completion"""
    p = subprocess.Popen(cmd, bufsize=2048)
    return p.wait()


def assemble_main_src(base_dir, src_file, object_file, output_file, as_bin,
                      p2bin, as_args, padding):
    """Assemble source file and convert to binary ROM"""
    # Get absolute paths before changing directory
    src_abs = os.path.abspath(src_file)
    object_abs = os.path.abspath(object_file)
    output_abs = os.path.abspath(output_file)
    p2bin_abs = os.path.abspath(p2bin)
    as_bin_abs = os.path.abspath(as_bin)

    os.makedirs(os.path.dirname(object_abs), exist_ok=True)

    # Get bin directory
    bin_dir = os.path.dirname(as_bin_abs)

    # Calculate relative path from bin to source
    src_rel = os.path.relpath(src_abs, bin_dir)

    # Use full path to assembler
    asm_cmd = [
        as_bin_abs,
        '-i', os.path.abspath(base_dir),
        '-o', object_abs,
        *shlex.split(as_args),
        src_rel,
    ]
    print(f'Assembling: {subprocess.list2cmdline(asm_cmd)}')
    ret = subprocess.call(asm_cmd, cwd=bin_dir)

    if ret != 0:
        print(f'Assembly failed with code {ret}')
        return ret

    # Convert .p file to binary
    if not os.path.exists(object_abs):
        print(f'Error: Object file {object_abs} not found')
        return 1

    p2bin_cmd = [p2bin_abs, object_abs, output_abs, f'-p={padding}']
    print(f'Converting to binary: {subprocess.list2cmdline(p2bin_cmd)}')
    ret = run_process(p2bin_cmd)
    if ret != 0:
        print(f'Conversion failed with code {ret}')
        return ret

    print(f'Build complete: {output_file}')
    return 0


if __name__ == '__main__':
    default_as_bin, default_p2bin = get_default_tools()

    parser = argparse.ArgumentParser(
        description='Build Alien Soldier ROM from assembly source'
    )
    parser.add_argument('-s', '--source', default='src/main.s',
                        help='Source assembly index (default: src/main.s)')
    parser.add_argument('--obj', default='build/main.p',
                        help='AS object file (default: build/main.p)')
    parser.add_argument('-o', '--output', default='asbuilt.bin',
                        help='Output ROM file (default: asbuilt.bin)')
    parser.add_argument('--as-bin', default=default_as_bin,
                        help=f'Path to AS assembler (default: {default_as_bin})')
    parser.add_argument('--p2bin', default=default_p2bin,
                        help=f'Path to p2bin converter (default: {default_p2bin})')
    parser.add_argument('--as-args', default='-maxerrors 2',
                        help='Arguments for AS assembler (default: -maxerrors 2)')
    parser.add_argument('--manifest', default='assets/manifest.json',
                        help='Canonical ROM and padding manifest')
    parser.add_argument('--original-rom', default='Alien Soldier (J) [!].bin',
                        help='Reference cartridge dump declared by the asset manifest')
    parser.add_argument('--verify', action='store_true',
                        help='Fail unless output is byte-identical to the canonical ROM')
    args = parser.parse_args()

    basedir = os.getcwd()

    with open(args.manifest, 'r', encoding='utf-8') as manifest_file:
        manifest = json.load(manifest_file)
    if manifest.get('schema_version') != 1:
        print(f"Unsupported asset manifest schema: {manifest.get('schema_version')}")
        sys.exit(1)
    reference = manifest['reference_rom']
    padding = reference.get('padding_byte', '0xFF')
    if padding.lower().startswith('0x'):
        padding = padding[2:]

    ret = assemble_main_src(
        basedir,
        args.source,
        args.obj,
        args.output,
        args.as_bin,
        args.p2bin,
        args.as_args,
        padding
    )

    if ret == 0:
        if not os.path.isfile(args.original_rom):
            message = f'Reference ROM not found: {args.original_rom}'
            if args.verify:
                print(f'ERROR: {message}')
                ret = 1
            else:
                print(f'WARNING: {message}; byte identity was not checked')
        else:
            with open(args.original_rom, 'rb') as original_file:
                original = original_file.read()
            with open(args.output, 'rb') as built_file:
                built = built_file.read()
            original_sha1 = hashlib.sha1(original).hexdigest()
            identity_error = canonical_rom_error(original, reference)
            if identity_error:
                reference_name = reference.get('name', 'declared preservation')
                print(f'ERROR: {args.original_rom} is not the {reference_name} ROM')
                print(f'  {identity_error}')
                ret = 1
            elif built == original:
                reference_name = reference.get('name', 'declared preservation')
                print(f'[OK] Byte-identical {reference_name} ROM reproduced (SHA1 {original_sha1})')
            else:
                offset = first_difference(built, original)
                message = f'Built ROM differs from canonical ROM at 0x{offset:06X}'
                if args.verify:
                    print(f'ERROR: {message}')
                    ret = 1
                else:
                    print(f'WARNING: {message}')

    sys.exit(ret)

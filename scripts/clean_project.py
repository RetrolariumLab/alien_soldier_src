#!/usr/bin/env python3
"""Remove only exact reproducible outputs, retaining historical evidence.

Preserve Source2 historical, failed, source and native owners under build/content.
Only fixed standard build files/trees and the old scenario/cache outputs belong
to clean. No content-manifest paths or wildcard listings grant deletion rights.
"""

from pathlib import Path
import json
import os
import re
import shutil


PROJECT_ROOT = Path(__file__).resolve().parents[1]
STANDARD_MODES = ('jp', 'eu', 'zero-edit/jp', 'zero-edit/eu')
ROOT_TARGETS = [
    'build/main.p', 'build/main.lst', 'build/source_inventory.json',
    'alien_soldier_j.p', 'alien_soldier_j.lst', 'asbuilt.bin',
    'build/eu/main.p', 'build/eu/main.lst', 'asbuilt_eu.bin',
    *(f'build/content/{mode}/alien_soldier.{suffix}'
      for mode in STANDARD_MODES for suffix in ('bin', 'p')),
    # Exact Makefile SCREEN_REFERENCE_LISTING default; arbitrary .lst survive.
    'build/content/zero-edit/jp/screen_runtime.lst',
    'build/content/zero-edit/eu/screen_runtime.lst',
]
DIRECTORY_TARGETS = [f'build/content/{mode}/tree' for mode in STANDARD_MODES]
RECURSIVE_PATTERNS = ['__pycache__']
CACHE_ROOTS = ('scripts', 'tests')


def checked_root(root: Path) -> Path:
    raw = root.absolute()
    if any(part.is_symlink() or getattr(part, 'is_junction', lambda: False)()
           for part in (raw, *raw.parents)):
        raise ValueError('cleanup root crosses a link')
    resolved = raw.resolve()
    if not resolved.is_dir():
        raise ValueError('cleanup root is missing')
    return resolved


def checked_target(root: Path, relative: str | Path) -> Path:
    """Retain the public escape/link checks, adding root and hard-link guards."""
    root = checked_root(root)
    relative = Path(relative)
    if relative.is_absolute() or not relative.parts or any(
        part in ('.', '..') for part in relative.parts
    ):
        raise ValueError(f'unsafe cleanup target: {relative}')
    path = root
    for part in relative.parts:
        path /= part
        if path.is_symlink() or getattr(path, 'is_junction', lambda: False)():
            raise ValueError(f'cleanup target crosses a link: {path}')
    if path == root or not path.resolve().is_relative_to(root):
        raise ValueError(f'cleanup target escapes checkout: {path}')
    if path.is_file() and path.stat().st_nlink != 1:
        raise ValueError(f'cleanup target is hard-linked: {path}')
    return path


def directory_owned(relative: str | Path) -> bool:
    relative = Path(relative)
    return (relative.as_posix() in DIRECTORY_TARGETS
            or relative == Path('__pycache__')
            or relative.name == '__pycache__' and relative.parts[0] in CACHE_ROOTS)


def validate_removal(root: Path, relative: str | Path, *, allow_directory=False) -> Path:
    """Preflight all descendants without following/recovering foreign links."""
    if type(allow_directory) is not bool:
        raise ValueError('cleanup directory authority must be boolean')
    if allow_directory and not directory_owned(relative):
        raise ValueError(f'not an exact generated cleanup directory: {relative}')
    path = checked_target(root, relative)
    if path.is_file():
        if allow_directory:
            raise ValueError(f'expected cleanup directory, found file: {path}')
        return path
    if not path.is_dir():
        if path.exists():
            raise ValueError(f'unsupported cleanup target type: {path}')
        return path
    if not allow_directory:
        raise ValueError(f'expected cleanup file, found directory: {path}')
    def failed(error):
        raise error
    for parent, children, files in os.walk(path, followlinks=False, onerror=failed):
        checked_target(root, Path(parent).relative_to(root))
        for name in children + files:
            checked_target(root, (Path(parent) / name).relative_to(root))
    return path


def remove_path(root: Path, relative: str | Path, *, allow_directory=False) -> bool:
    path = validate_removal(root, relative, allow_directory=allow_directory)
    if path.is_file():
        path.unlink()
        print(f'  Removed file: {relative}')
        return True
    if path.is_dir():
        # The resolved absolute target has just been checked against the exact
        # checkout and the fixed tree/cache ownership allowlist.
        shutil.rmtree(path)
        print(f'  Removed dir:  {relative}')
        return True
    return False


def runtime_capture_targets(root: Path) -> tuple[list[Path], list[Path]]:
    """Unchanged public scenario contract: only declared frame PNG/genstate."""
    config = json.loads((root / 'config/runtime_scenarios.json').read_text(encoding='utf-8'))
    files, directories = [], []
    for scenario in config['scenarios']:
        scenario_id, frame = scenario['id'], scenario['frame']
        if not isinstance(scenario_id, str) or not re.fullmatch(r'[a-z][a-z0-9_]*', scenario_id):
            raise ValueError(f'unsafe runtime scenario id: {scenario_id!r}')
        if isinstance(frame, bool) or not isinstance(frame, int) or frame < 0:
            raise ValueError(f'unsafe runtime frame: {frame!r}')
        directory = Path('runtime/captures') / scenario_id
        directories.append(directory)
        files.extend(directory / f'{frame:06d}.{suffix}' for suffix in ('genstate', 'png'))
    return files, directories


def cache_targets(root: Path) -> list[Path]:
    result = []
    def failed(error):
        raise error
    for base in CACHE_ROOTS:
        directory = checked_target(root, base)
        if not directory.is_dir():
            continue
        for current, children, _ in os.walk(directory, topdown=True, followlinks=False, onerror=failed):
            current, safe_children = Path(current), []
            for child in children:
                relative = (current / child).relative_to(root)
                candidate = checked_target(root, relative)
                if child in RECURSIVE_PATTERNS:
                    result.append(relative)
                elif candidate.is_dir():
                    safe_children.append(child)
            children[:] = safe_children
    return [*result, *(Path(pattern) for pattern in RECURSIVE_PATTERNS)]


def clean(root: Path = PROJECT_ROOT) -> int:
    """Preflight every exact generated target before removing any output."""
    root = checked_root(root)
    print('Cleaning project...')
    capture_files, capture_directories = runtime_capture_targets(root)
    plan = [(Path(target), False) for target in ROOT_TARGETS]
    plan += [(Path(target), True) for target in DIRECTORY_TARGETS]
    plan += [(target, False) for target in capture_files]
    plan += [(target, True) for target in cache_targets(root)]
    # Fail before the first deletion if any selected tree/file/cache is unsafe.
    for target, allow_directory in plan:
        validate_removal(root, target, allow_directory=allow_directory)
    for target in [*capture_directories, Path('runtime/captures')]:
        checked_target(root, target)
    removed = sum(remove_path(root, target, allow_directory=allow_directory)
                  for target, allow_directory in plan)
    for target in [*capture_directories, Path('runtime/captures')]:
        directory = checked_target(root, target)
        if directory.is_dir():
            try:
                directory.rmdir()
            except OSError:
                pass  # Other captures belong to their owner, not make clean.
    print('  Extracted data, content workspace and retained evidence were preserved.')
    return removed


def main() -> None:
    clean()


if __name__ == '__main__':
    main()

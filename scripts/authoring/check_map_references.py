#!/usr/bin/env python3
"""Inventory the complete static map period and test source-relative guards."""

from __future__ import annotations

import argparse
import hashlib
import json
import struct
import sys
from collections import Counter
from dataclasses import asdict, replace
from pathlib import Path
from types import SimpleNamespace


SCRIPT_ROOT = Path(__file__).resolve().parents[1]
if str(SCRIPT_ROOT) not in sys.path:
    sys.path.insert(0, str(SCRIPT_ROOT))

from authoring.atomic_output import atomic_write_json  # noqa: E402
from authoring.compressed_graphics_model import source_owners, source_paths  # noqa: E402
from authoring.content_workspace import ContentError, checked_path, load_manifest, profile_record  # noqa: E402
from authoring.map_reference_guard import periodic_reference_error, writer_ids  # noqa: E402
from authoring.screen_studio_model import build_scene, load_config  # noqa: E402
from authoring.stage_renderer import forget, read_once, scene, signed_word  # noqa: E402
from authoring.stage_tilemap_model import (  # noqa: E402
    CHUNK_BYTES, COARSE_COLUMNS, DIRECTIVE, PATTERN_BYTES, PLANE_A_TABLE, PLANE_B_TABLE,
    RAM_BASE, RAM_SIZE, plane_descriptor, read_asset_list,
)


PROFILES = ("jp", "eu")
COUNTS = ("valid", "unowned_coarse", "unloaded_chunk", "unowned_chunk",
          "unloaded_pattern", "unowned_pattern")
WORDS_PER_PATTERN = PATTERN_BYTES // 2
LINKS_PER_PLANE = COARSE_COLUMNS ** 2 * CHUNK_BYTES
TILES_PER_PLANE = LINKS_PER_PLANE * WORDS_PER_PATTERN


def empty_counts():
    return dict.fromkeys(COUNTS, 0)


def owned(owners, address, width):
    return (0 <= address and address + width <= RAM_SIZE and owners[address] != 0
            and owners[address] == owners[address + width - 1])


def plane_facts(plane):
    """Fold 1,048,576 tile reads into 256 pattern/chunk facts and 1,024 cells."""
    if len(plane.ram) != RAM_SIZE:
        raise ValueError("map RAM image is not 64 KiB")
    for name in ("coarse", "chunks", "patterns"):
        if not RAM_BASE <= getattr(plane.descriptor, name) < RAM_BASE + RAM_SIZE:
            raise ValueError("map descriptor %s is outside RAM" % name)
    for _list, _source, start, length in plane.written:
        if not 0 <= start <= start + length <= RAM_SIZE:
            raise ValueError("map transfer range is outside RAM")
    owners = writer_ids(plane.written)
    chunks = plane.region(plane.descriptor.chunks)
    patterns = plane.region(plane.descriptor.patterns)
    chunk_base = plane.descriptor.chunks - RAM_BASE
    pattern_base = plane.descriptor.patterns - RAM_BASE
    coarse_base = plane.descriptor.coarse - RAM_BASE
    pattern_facts = []
    for value in range(256):
        counts, mask = empty_counts(), 0
        digest = hashlib.sha256()
        for word in range(WORDS_PER_PATTERN):
            address = pattern_base + value * PATTERN_BYTES + word * 2
            if value * PATTERN_BYTES >= patterns:
                status = "unloaded_pattern"
            elif not owned(owners, address, 2):
                status = "unowned_pattern"
            else:
                status = "valid"
                mask |= 1 << word
            counts[status] += 1
            in_ram = 0 <= address and address + 2 <= RAM_SIZE
            digest.update(struct.pack(">BHHH", COUNTS.index(status), owners[address] if in_ram else 0,
                                      owners[address + 1] if in_ram else 0,
                                      int.from_bytes(plane.ram[address:address + 2], "big") if in_ram else 0))
        pattern_facts.append((counts, mask, digest.digest()))
    chunk_facts = []
    for coarse in range(256):
        counts, witness = empty_counts(), None
        digest = hashlib.sha256()
        for position in range(CHUNK_BYTES):
            address = chunk_base + coarse * CHUNK_BYTES + position
            if coarse * CHUNK_BYTES >= chunks:
                status = "unloaded_chunk"
            elif not owned(owners, address, 1):
                status = "unowned_chunk"
            else:
                status = None
            if status is not None:
                counts[status] += WORDS_PER_PATTERN
                digest.update(bytes((COUNTS.index(status),)))
                continue
            value = plane.ram[address]
            pattern_counts, mask, pattern_digest = pattern_facts[value]
            for key in COUNTS:
                counts[key] += pattern_counts[key]
            digest.update(struct.pack(">HB", owners[address], value) + pattern_digest)
            if mask and witness is None:
                witness = (position, (mask & -mask).bit_length() - 1)
        chunk_facts.append((counts, witness, digest.digest()))
    counts, witness = empty_counts(), None
    digest = hashlib.sha256(json.dumps({"descriptor": asdict(plane.descriptor), "y_offset": plane.y_offset},
                                       sort_keys=True).encode("utf-8"))
    for cell in range(COARSE_COLUMNS ** 2):
        address = coarse_base + cell
        if not 0 <= address < RAM_SIZE:
            raise ValueError("coarse map period escapes RAM")
        value = plane.ram[address]
        digest.update(struct.pack(">HHB", cell, owners[address], value))
        if not owned(owners, address, 1):
            counts["unowned_coarse"] += CHUNK_BYTES * WORDS_PER_PATTERN
            digest.update(b"unowned")
            continue
        chunk_counts, chunk_witness, chunk_digest = chunk_facts[value]
        for key in COUNTS:
            counts[key] += chunk_counts[key]
        digest.update(chunk_digest)
        if chunk_witness is not None:
            witness = (cell, value, *chunk_witness)  # Last valid coarse cell stresses the full period.
    if sum(counts.values()) != TILES_PER_PLANE:
        raise ValueError("map inventory did not account for the complete period")
    ownership = Counter(owners)
    writer_ranges = [
        {"id": index, "asset_list": item[0], "source": item[1],
         "start": "0x%08X" % (RAM_BASE + item[2]), "length": item[3],
         "final_owned_bytes": ownership[index]}
        for index, item in enumerate(plane.written, 1)
    ]
    report = {
        "descriptor": asdict(plane.descriptor), "y_offset": plane.y_offset,
        "loaded_chunk_bytes": chunks, "loaded_pattern_bytes": patterns,
        "counts": counts, "unloaded": counts["unloaded_chunk"] + counts["unloaded_pattern"],
        "unowned": counts["unowned_coarse"] + counts["unowned_chunk"] + counts["unowned_pattern"],
        "ram_sha256": hashlib.sha256(plane.ram).hexdigest(),
        "writer_ranges": writer_ranges,
        "writer_ranges_sha256": hashlib.sha256(json.dumps(writer_ranges, sort_keys=True).encode()).hexdigest(),
        "graph_sha256": digest.hexdigest(),
    }
    return report, witness, pattern_facts


def mutation_probes(plane, plane_name, context, witness, pattern_facts):
    """Change one RAM byte at a time; canonical source and ownership stay intact."""
    if witness is None:
        return [{"role": role, "status": "not_applicable", "why": "no source-valid read"}
                for role in ("coarse", "chunk")]
    cell, coarse, position, word = witness
    original = SimpleNamespace(tilemap=plane if plane_name == "plane_a" else None,
                               plane_b=plane if plane_name == "plane_b" else None)
    chunks = plane.region(plane.descriptor.chunks)
    bad_coarse = next((value for value in reversed(range(256)) if value * CHUNK_BYTES >= chunks), None)
    bad_chunk = next((value for value in reversed(range(256))
                      if not pattern_facts[value][1] & (1 << word)), None)
    probes = []
    for role, address, bad in (
        ("coarse", plane.descriptor.coarse - RAM_BASE + cell, bad_coarse),
        ("chunk", plane.descriptor.chunks - RAM_BASE + coarse * CHUNK_BYTES + position, bad_chunk),
    ):
        if bad is None:
            probes.append({"role": role, "status": "not_applicable", "why": "all 8-bit targets retain this source-valid read"})
            continue
        mutated = bytearray(plane.ram)
        mutated[address] = bad
        changed_plane = replace(plane, ram=mutated)
        changed = SimpleNamespace(tilemap=changed_plane if plane_name == "plane_a" else None,
                                  plane_b=changed_plane if plane_name == "plane_b" else None)
        error = periodic_reference_error(original, changed, context)
        if error is None:
            raise ValueError("periodic guard accepted a new invalid %s reference: %s %s" % (role, context, plane_name))
        probes.append({"role": role, "status": "rejected", "address": "0x%08X" % (RAM_BASE + address),
                       "old": plane.ram[address], "new": bad, "guard_error": error})
        del changed, changed_plane, mutated
    return probes


def stage_planes(root, read, graphics):
    if len(read["loaders"]) != graphics["stage_rendering"]["stage_table_entries"]:
        raise ValueError("stage loader inventory differs from its declared count")
    if len(read["configurations"]) != len(read["loaders"]):
        raise ValueError("stage configuration/loader counts differ")
    for index, configuration in enumerate(read["configurations"]):
        if configuration is None:
            raise ValueError("static stage %d has no configuration" % index)
        if index in read["not_reproduced"]:
            for plane_name in ("plane_a", "plane_b"):
                yield {"kind": "stage", "id": str(index), "plane": plane_name,
                       "status": "excluded", "why": read["not_reproduced"][index]}, None
            continue
        built = scene(root, index)
        if built.missing_codecs:
            raise ValueError("static stage %d has unavailable graphics codecs" % index)
        for plane_name, mode, table in (
            ("plane_a", configuration.plane_a_mode, PLANE_A_TABLE),
            ("plane_b", configuration.plane_b_mode, PLANE_B_TABLE),
        ):
            record = {"kind": "stage", "id": str(index), "plane": plane_name,
                      "configuration": configuration.name, "entry_mode": mode}
            name, offset = plane_descriptor(mode, read["plane_tables"][table], offset_variant=table == PLANE_A_TABLE)
            if name is None:
                yield {**record, "status": "constant_fill", "why": "source entry mode is zero; no map reads"}, None
                continue
            if name not in read["descriptors"]:
                raise ValueError("static stage %d descriptor is missing: %s" % (index, name))
            if plane_name == "plane_b":
                offset += signed_word(configuration.camera_y) - signed_word(configuration.secondary_camera_y)
            plane = replace(read["tilemaps"][index], descriptor=read["descriptors"][name], y_offset=offset)
            drawable = built.tilemap if plane_name == "plane_a" else built.plane_b
            loaded = bool(plane.region(plane.descriptor.chunks) and plane.region(plane.descriptor.patterns))
            yield {**record, "status": "audited", "loaded": loaded, "renderer_drawable": drawable is not None,
                   "renderer_route": built.planes[0 if plane_name == "plane_a" else 1],
                   "asset_lists": list(plane.lists)}, plane


def check_inputs(root, profile, sources, data, paths, owners, manifest):
    record = profile_record(manifest, profile)
    assets = json.loads(checked_path(root, record["asset_manifest"]).read_text(encoding="utf-8"))
    expected = {entry["path"]: entry for entry in assets["assets"]}
    result = []
    for source in sorted(sources):
        raw = data.get(source)
        if not isinstance(raw, bytes) or source not in owners:
            raise ValueError("map source is unavailable: %s" % source)
        item = {"source": source, "source_file": owners[source],
                "compressed_size": len(raw), "compressed_sha256": hashlib.sha256(raw).hexdigest()}
        path = paths.get(source)
        if path is not None:
            try:
                relative = Path(path).relative_to("data").as_posix()
            except ValueError:
                raise ValueError("map payload is outside canonical data: %s" % path) from None
            asset = expected.get(relative)
            if asset is None or len(raw) != asset["size"] or hashlib.sha1(raw).hexdigest() != asset["sha1"]:
                raise ValueError("map payload differs from the %s preservation manifest: %s" % (profile, path))
            item["payload_path"] = path
            item["profile_asset_sha1"] = asset["sha1"]
        result.append(item)
    return result


def require_scene_sources(read, screens):
    """Do not mistake the permissive reader's missing payload for a source gap."""
    list_names = {name for index, plane in enumerate(read["tilemaps"])
                  if index not in read["not_reproduced"] for name in plane.lists}
    commands = {name: read["lists"][name] for name in list_names}
    for record in screens["supported"]:
        name = record["asset_list"]
        if name in read["lists"]:
            commands[name] = read["lists"][name]
            continue
        stop = record.get("asset_stop_label")
        if name not in read["bodies"] or stop not in read["bodies"]:
            raise ValueError("static screen asset list is unavailable: %s" % name)
        lines = [line for line in read["bodies"][stop] if line.strip() and not line.strip().startswith(";")]
        directive = DIRECTIVE.match(lines[0]) if lines else None
        if directive is None or directive.group("kind") != "dc.w":
            raise ValueError("static screen asset stop word is unavailable: %s" % stop)
        parsed = read_asset_list(name, (*read["bodies"][name], " dc.w " + directive.group("body").split(",", 1)[0]))
        if not parsed:
            raise ValueError("static screen asset list cannot be decoded: %s" % name)
        commands[name] = parsed
    for name, records in commands.items():
        for command in records:
            if command.to_ram and not isinstance(read["data"].get(command.source), bytes):
                raise ValueError("static map RAM payload is unavailable: %s in %s" % (command.source, name))


def audit(root: Path, profiles=PROFILES):
    manifest = load_manifest(root / "config/authoring/content_studios.json", root)
    graphics = json.loads((root / "config/authoring/graphics.json").read_text(encoding="utf-8"))
    screens = load_config(root)
    if tuple(item["id"] for item in screens["supported"]) != (
            "title_background", "options_background", "story_background"):
        raise ValueError("static screen audit requires all three declared supported screens")
    forget(root)
    read = read_once(root)
    require_scene_sources(read, screens)
    paths, owners = source_paths(root), source_owners(root)
    report = {"schema_version": 1, "status": "passed_static_inventory", "scope": "canonical source; no workspace/staged edits",
              "runtime_reachability": "not established", "period_pixels": [8192, 8192],
              "chunk_links_per_plane": LINKS_PER_PLANE, "tile_reads_per_plane": TILES_PER_PLANE, "profiles": {}}
    for profile in profiles:
        if profile not in PROFILES:
            raise ValueError("unknown map audit profile: %s" % profile)
        records, sources, totals = [], set(), empty_counts()
        entries = list(stage_planes(root, read, graphics))
        for screen in screens["supported"]:
            built = build_scene(root, profile, screen)
            for plane_name, plane in (("plane_a", built.tilemap), ("plane_b", built.plane_b)):
                record = {"kind": "screen", "id": screen["id"], "plane": plane_name, "scope": screen["scope"]}
                if plane is None:
                    entries.append(({**record, "status": "constant_fill", "why": "declared static screen has no map on this plane"}, None))
                else:
                    entries.append(({**record, "status": "audited", "loaded": True, "renderer_drawable": True,
                                     "asset_lists": list(plane.lists)}, plane))
        for record, plane in entries:
            if plane is not None:
                facts, witness, patterns = plane_facts(plane)
                record.update(facts)
                record["mutation_probes"] = mutation_probes(plane, record["plane"], record["kind"] + " " + record["id"], witness, patterns)
                for key in COUNTS:
                    totals[key] += facts["counts"][key]
                sources.update(item[1] for item in plane.written)
            records.append(record)
        excluded_screens = [{"kind": "screen", "id": item["id"], "status": "excluded", "why": item["reason"]}
                            for item in screens["unsupported"]]
        report["profiles"][profile] = {
            "assembler_defines": manifest["assembler_defines"][profile], "planes": records,
            "unsupported_screen_routes": excluded_screens, "counts": totals,
            "audited_planes": sum(item["status"] == "audited" for item in records),
            "map_inputs": check_inputs(root, profile, sources, read["data"], paths, owners, manifest),
        }
    report["inventory_sha256"] = hashlib.sha256(json.dumps(report, sort_keys=True).encode("utf-8")).hexdigest()
    return report


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path("."))
    parser.add_argument("--profile", choices=(*PROFILES, "all"), default="all")
    parser.add_argument("--output", type=Path, default=Path("build/content/map-reference-audit.json"))
    args = parser.parse_args(argv)
    root = args.root.resolve()
    try:
        output = checked_path(root, args.output, Path("build/content"))
        if output.suffix != ".json":
            raise ValueError("map audit output must be JSON inside build/content")
        report = audit(root, PROFILES if args.profile == "all" else (args.profile,))
        atomic_write_json(output, report)
        for profile, result in report["profiles"].items():
            counts = result["counts"]
            print("[OK] %s %d static descriptor planes: %d valid, %d unloaded, %d unowned tile reads" % (
                profile, result["audited_planes"], counts["valid"],
                counts["unloaded_chunk"] + counts["unloaded_pattern"],
                counts["unowned_coarse"] + counts["unowned_chunk"] + counts["unowned_pattern"]))
        print("[OK] static inventory %s: %s; runtime reachability not established" % (report["inventory_sha256"], output))
        return 0
    except (OSError, ValueError, KeyError, ContentError) as error:
        print("[ERROR] %s" % error, file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())

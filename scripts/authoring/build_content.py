#!/usr/bin/env python3
"""Build a profile-aware ROM from the isolated content workspace."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import shlex
import struct
import sys
import tempfile
from pathlib import Path


SCRIPT_ROOT = Path(__file__).resolve().parents[1]
if str(SCRIPT_ROOT) not in sys.path:
    sys.path.insert(0, str(SCRIPT_ROOT))

from build_rom import assemble_main_src, first_difference  # noqa: E402
from authoring.content_workspace import (  # noqa: E402
    ContentError,
    EXPECTED_PROFILES,
    checked_path,
    load_manifest,
    profile_record,
    stage_tree,
    validate_workspace,
)


CHECKSUM_HEADER = 0x18E
CHECKSUM_FROM = 0x200
# JP's comparison runs through the word at $60000. EU's unrolled loop
# reads 0x1FFE groups of 128 words, ending at $1FFFFE.
CHECKSUM_END = {"jp": 0x60002, "eu": 0x200000}


def update_boot_checksum(image: bytearray, profile: str) -> int:
    """Store the checksum that this profile's Reset routine actually tests."""
    try:
        end = CHECKSUM_END[profile]
    except KeyError as error:
        raise ContentError(f"unknown content checksum profile: {profile}") from error
    if len(image) < end:
        raise ContentError(f"{profile} content ROM is too short for its boot checksum span")
    total = sum(word for (word,) in struct.iter_unpack(">H", memoryview(image)[CHECKSUM_FROM:end])) & 0xFFFF
    struct.pack_into(">H", image, CHECKSUM_HEADER, total)
    return total


def file_digest(path: Path, algorithm: str = "sha1") -> str:
    digest = hashlib.new(algorithm)
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def validate_reference(path: Path, reference: dict) -> bytes:
    try:
        data = path.read_bytes()
    except OSError as error:
        raise ContentError(f"cannot read reference ROM {path}: {error}") from error
    digest = hashlib.sha1(data).hexdigest()
    if len(data) != reference["size"] or digest != reference["sha1"]:
        raise ContentError(
            f"reference ROM differs for {reference['name']}: expected "
            f"{reference['size']} bytes, SHA1 {reference['sha1']}; actual "
            f"{len(data)} bytes, SHA1 {digest}"
        )
    return data


def assembler_args(base: str, manifest: dict, profile: str) -> str:
    additions = [part for define in manifest["assembler_defines"][profile] for part in ("-D", define)]
    return shlex.join([*shlex.split(base), *additions])


def checked_listing(root: Path, output: Path, listing: Path | None) -> Path | None:
    if listing is None:
        return None
    path = listing if listing.is_absolute() else root / listing
    try:
        relative = path.relative_to(root)
    except ValueError as error:
        raise ContentError("content listing must be inside the selected profile output") from error
    path = checked_path(root, relative, Path("build/content"))
    if not path.is_relative_to(output.parent) or path.suffix != ".lst":
        raise ContentError("content listing must be a .lst inside the selected profile output")
    return path


def build(
    root: Path,
    manifest: dict,
    profile: str,
    as_bin: Path,
    p2bin: Path,
    as_args: str,
    zero_edit: bool,
    listing: Path | None = None,
) -> Path:
    record = profile_record(manifest, profile)
    reference = record["reference_rom"]
    original_path = checked_path(root, reference["filename"])
    original = validate_reference(original_path, reference)
    if not zero_edit:
        validate_workspace(root, manifest, profile)
    output_key = "zero_edit_outputs" if zero_edit else "profile_outputs"
    output = checked_path(root, manifest[output_key][profile], Path("build/content"))
    listing = checked_listing(root, output, listing)
    mode_root = output.parent
    tree = mode_root / "tree"
    staged_main = stage_tree(root, tree)
    if not zero_edit:
        from authoring.content_workspace import artifact_path
        from authoring.level_studio_model import apply_document, load_document

        for artifact in manifest["artifacts"]:
            if profile not in artifact["profiles"]:
                continue
            if artifact["kind"] == "level_document":
                document = load_document(artifact_path(root, manifest, profile, artifact))
                apply_document(document, tree, profile)
            elif artifact["kind"] == "graphics_tile_document":
                from authoring.graphics_studio_model import (
                    apply_document as apply_graphics_document,
                    load_document as load_graphics_document,
                )

                document = load_graphics_document(artifact_path(root, manifest, profile, artifact))
                apply_graphics_document(document, tree, profile)
            elif artifact["kind"] == "compressed_tile_document":
                from authoring.compressed_graphics_model import (
                    apply_document as apply_compressed_graphics_document,
                    load_document as load_compressed_graphics_document,
                )

                document = load_compressed_graphics_document(
                    artifact_path(root, manifest, profile, artifact), root, profile
                )
                apply_compressed_graphics_document(document, tree, profile)
            elif artifact["kind"] == "palette_document":
                from authoring.palette_studio_model import (
                    apply_document as apply_palette_document,
                    load_document as load_palette_document,
                )

                document = load_palette_document(artifact_path(root, manifest, profile, artifact))
                apply_palette_document(document, tree, profile)
            elif artifact["kind"] == "mapping_document":
                from authoring.mapping_studio_model import (
                    apply_document as apply_mapping_document,
                    load_document as load_mapping_document,
                )

                document = load_mapping_document(artifact_path(root, manifest, profile, artifact))
                apply_mapping_document(document, tree, profile)
            elif artifact["kind"] == "animation_document":
                from authoring.animation_studio_model import (
                    apply_document as apply_animation_document,
                    load_document as load_animation_document,
                )

                document = load_animation_document(artifact_path(root, manifest, profile, artifact))
                apply_animation_document(document, tree, profile, validation_root=root)
            elif artifact["kind"] == "screen_map_document":
                from authoring.screen_map_model import (
                    apply_document as apply_screen_map_document,
                    load_document as load_screen_map_document,
                )

                document = load_screen_map_document(artifact_path(root, manifest, profile, artifact))
                apply_screen_map_document(document, tree, profile, validation_root=root)
            elif artifact["kind"] == "stage_map_document":
                from authoring.stage_map_model import (
                    apply_document as apply_stage_map_document,
                    load_document as load_stage_map_document,
                )

                document = load_stage_map_document(artifact_path(root, manifest, profile, artifact))
                apply_stage_map_document(document, tree, profile, validation_root=root)
            elif artifact["kind"] == "stage_map_document":
                from authoring.stage_map_model import (
                    apply_document as apply_stage_map_document,
                    load_document as load_stage_map_document,
                )

                document = load_stage_map_document(artifact_path(root, manifest, profile, artifact))
                apply_stage_map_document(document, tree, profile, validation_root=root)
            elif artifact["kind"] == "story_text_document":
                from authoring.story_text_model import (
                    apply_document as apply_story_text_document,
                    load_document as load_story_text_document,
                )

                document = load_story_text_document(artifact_path(root, manifest, profile, artifact))
                apply_story_text_document(document, tree, profile, validation_root=root)
            elif artifact["kind"] == "frontend_text_document":
                from authoring.frontend_text_model import (
                    apply_document as apply_frontend_text_document,
                    load_document as load_frontend_text_document,
                )

                document = load_frontend_text_document(artifact_path(root, manifest, profile, artifact))
                apply_frontend_text_document(document, tree, profile, validation_root=root)
            elif artifact["kind"] == "results_text_document":
                from authoring.results_text_model import (
                    apply_document as apply_results_text_document,
                    load_document as load_results_text_document,
                )

                document = load_results_text_document(artifact_path(root, manifest, profile, artifact))
                apply_results_text_document(document, tree, profile, validation_root=root)
            elif artifact["kind"] == "stage_message_document":
                from authoring.stage_message_model import (
                    apply_document as apply_stage_message_document,
                    load_document as load_stage_message_document,
                )

                document = load_stage_message_document(artifact_path(root, manifest, profile, artifact))
                apply_stage_message_document(document, tree, profile, validation_root=root)
            elif artifact["kind"] == "scripted_message_document":
                from authoring.scripted_message_model import (
                    apply_document as apply_scripted_message_document,
                    load_document as load_scripted_message_document,
                )

                document = load_scripted_message_document(artifact_path(root, manifest, profile, artifact))
                apply_scripted_message_document(document, tree, profile, validation_root=root)
            elif artifact["kind"] == "credits_text_document":
                from authoring.credits_text_model import (
                    apply_document as apply_credits_text_document,
                    load_document as load_credits_text_document,
                )

                document = load_credits_text_document(artifact_path(root, manifest, profile, artifact))
                apply_credits_text_document(document, tree, profile, validation_root=root)
            elif artifact["kind"] == "glyph_source_list_document":
                from authoring.glyph_source_list_model import (
                    apply_document as apply_glyph_source_list_document,
                    load_document as load_glyph_source_list_document,
                )

                document = load_glyph_source_list_document(artifact_path(root, manifest, profile, artifact))
                apply_glyph_source_list_document(document, tree, profile, validation_root=root)
            elif artifact["kind"] == "japanese_glyph_document":
                from authoring.japanese_glyph_model import (
                    apply_document as apply_japanese_glyph_document,
                    load_document as load_japanese_glyph_document,
                )

                document = load_japanese_glyph_document(artifact_path(root, manifest, profile, artifact))
                apply_japanese_glyph_document(document, tree, profile, validation_root=root)
            elif artifact["kind"] == "sound_sequence_document":
                from authoring.sound_sequence_model import (
                    apply_document as apply_sound_sequence_document,
                    load_document as load_sound_sequence_document,
                )

                document = load_sound_sequence_document(artifact_path(root, manifest, profile, artifact))
                apply_sound_sequence_document(document, tree, profile, validation_root=root)
            elif artifact["kind"] == "sound_instrument_document":
                from authoring.sound_instrument_model import (
                    apply_document as apply_sound_instrument_document,
                    load_document as load_sound_instrument_document,
                )

                document = load_sound_instrument_document(artifact_path(root, manifest, profile, artifact))
                apply_sound_instrument_document(document, tree, profile, validation_root=root)
            elif artifact["kind"] == "sound_envelope_document":
                from authoring.sound_envelope_model import (
                    apply_document as apply_sound_envelope_document,
                    load_document as load_sound_envelope_document,
                )

                document = load_sound_envelope_document(artifact_path(root, manifest, profile, artifact))
                apply_sound_envelope_document(document, tree, profile, validation_root=root)
            elif artifact["kind"] == "sound_pcm_document":
                from authoring.sound_pcm_model import (
                    apply_document as apply_sound_pcm_document,
                    load_document as load_sound_pcm_document,
                )

                document = load_sound_pcm_document(artifact_path(root, manifest, profile, artifact))
                apply_sound_pcm_document(document, tree, profile, validation_root=root)
    output.parent.mkdir(parents=True, exist_ok=True)
    object_file = output.with_suffix(".p")
    padding = reference["padding_byte"].removeprefix("0x")
    if listing is not None:
        listing.parent.mkdir(parents=True, exist_ok=True)
        as_args = shlex.join([*shlex.split(as_args), "-L", "-olist", str(listing)])
    with tempfile.TemporaryDirectory(prefix=".content-rom-", dir=output.parent) as temporary:
        candidate = Path(temporary) / output.name
        result = assemble_main_src(
            tree,
            staged_main,
            object_file,
            candidate,
            as_bin,
            p2bin,
            assembler_args(as_args, manifest, profile),
            padding,
        )
        if result:
            raise ContentError(f"content assembly failed with code {result}")
        built = bytearray(candidate.read_bytes())
        if zero_edit and built != original:
            offset = first_difference(built, original)
            raise ContentError(f"{profile} zero-edit ROM differs at 0x{offset:06X}")
        if not zero_edit:
            if len(built) != reference["size"]:
                raise ContentError(f"{profile} edited content ROM has {len(built)} bytes; expected {reference['size']}")
            update_boot_checksum(built, profile)
            candidate.write_bytes(built)
        os.replace(candidate, output)
    if built == original:
        print(f"[OK] {profile} content ROM is byte-identical (SHA1 {reference['sha1']})")
    else:
        print(
            f"[OK] Edited {profile} content ROM built: {output.relative_to(root)} "
            f"(SHA1 {hashlib.sha1(built).hexdigest()})"
        )
    return output


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", default=".")
    parser.add_argument("--manifest", default="config/authoring/content_studios.json")
    parser.add_argument("--profile", default="jp", choices=EXPECTED_PROFILES)
    parser.add_argument("--as-bin", required=True)
    parser.add_argument("--p2bin", required=True)
    parser.add_argument("--as-args", default="-maxerrors 2")
    parser.add_argument("--listing", type=Path)
    parser.add_argument("--zero-edit", action="store_true")
    args = parser.parse_args()
    root = Path(args.root).resolve()
    try:
        manifest = load_manifest(checked_path(root, args.manifest), root)
        build(
            root,
            manifest,
            args.profile,
            Path(args.as_bin).resolve(),
            Path(args.p2bin).resolve(),
            args.as_args,
            args.zero_edit,
            args.listing,
        )
        return 0
    except (ContentError, OSError, json.JSONDecodeError) as error:
        print(f"[ERROR] {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())

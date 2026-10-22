#!/usr/bin/env python3
"""Initialize and validate Alien Soldier's isolated content workspace."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import shutil
import sys
from pathlib import Path
from typing import Any


SCRIPT_ROOT = Path(__file__).resolve().parents[1]
if str(SCRIPT_ROOT) not in sys.path:
    sys.path.insert(0, str(SCRIPT_ROOT))

from rom_profiles import ProfileError, load_profiles  # noqa: E402
from authoring.stage_tilemap_model import with_parsed_operation  # noqa: E402


EXPECTED_PROFILES = ("jp", "eu")
EXPECTED_STUDIOS = ("level", "graphics", "screen", "text", "sound")
STUDIO_STATUSES = {"planned", "foundation", "supported"}
ARTIFACT_KINDS = {
    "animation_document",
    "compressed_tile_document",
    "credits_text_document",
    "frontend_text_document",
    "glyph_source_list_document",
    "japanese_glyph_document",
    "level_document",
    "graphics_tile_document",
    "mapping_document",
    "palette_document",
    "results_text_document",
    "screen_map_document",
    "stage_map_document",
    "scripted_message_document",
    "sound_envelope_document",
    "sound_instrument_document",
    "sound_pcm_document",
    "sound_sequence_document",
    "stage_message_document",
    "story_text_document",
}
GENERATED_ROOT = Path("build/content")


class ContentError(ValueError):
    """Raised when an authoring declaration or workspace is unsafe."""


def _is_safe_relative(value: Any) -> bool:
    if not isinstance(value, str) or not value:
        return False
    path = Path(value)
    return not path.is_absolute() and ".." not in path.parts and "." not in path.parts


def _inside(path: Path, parent: Path) -> bool:
    try:
        path.relative_to(parent)
    except ValueError:
        return False
    return True


def checked_path(root: Path, relative: str | Path, owner: Path | None = None) -> Path:
    """Resolve a relative path without allowing escapes or existing links."""
    root = root.resolve()
    relative = Path(relative)
    if relative.is_absolute() or not relative.parts or any(part in {"", ".", ".."} for part in relative.parts):
        raise ContentError(f"unsafe content path: {relative}")
    path = root
    for part in relative.parts:
        path /= part
        if path.is_symlink() or getattr(path, "is_junction", lambda: False)():
            raise ContentError(f"content path crosses a link: {path}")
    resolved = path.resolve()
    boundary = (root / owner).resolve() if owner is not None else root
    if not _inside(resolved, boundary):
        raise ContentError(f"content path escapes {boundary}: {path}")
    return path


def validate_manifest(document: dict[str, Any]) -> list[str]:
    """Return all structural errors in the authoring manifest."""
    errors: list[str] = []
    if document.get("schema_version") != 1:
        return ["content manifest is not schema 1"]
    if not _is_safe_relative(document.get("profile_manifest")):
        errors.append("invalid profile_manifest path")
    if tuple(document.get("profiles", ())) != EXPECTED_PROFILES:
        errors.append("content profiles must be jp followed by eu")
    if not _is_safe_relative(document.get("workspace")):
        errors.append("invalid workspace path")
    if not _is_safe_relative(document.get("workspace_document")):
        errors.append("invalid workspace document path")

    for field in ("profile_outputs", "zero_edit_outputs", "assembler_defines"):
        values = document.get(field)
        if not isinstance(values, dict) or tuple(values) != EXPECTED_PROFILES:
            errors.append(f"{field} must declare jp followed by eu")
            continue
        if field != "assembler_defines":
            for profile, value in values.items():
                if not _is_safe_relative(value) or not Path(value).is_relative_to(GENERATED_ROOT):
                    errors.append(f"invalid {field} path for {profile}")
        else:
            for profile, defines in values.items():
                if not isinstance(defines, list) or not all(
                    isinstance(item, str) and item and not any(char.isspace() for char in item) for item in defines
                ):
                    errors.append(f"invalid assembler defines for {profile}")

    studios = document.get("studios")
    if not isinstance(studios, list):
        return errors + ["studios is not a list"]
    studio_ids = tuple(studio.get("id") for studio in studios if isinstance(studio, dict))
    if studio_ids != EXPECTED_STUDIOS:
        errors.append("studio identity or order differs")
    artifact_records = document.get("artifacts")
    if not isinstance(artifact_records, list):
        return errors + ["artifacts is not a list"]
    artifact_ids = [item.get("id") for item in artifact_records if isinstance(item, dict)]
    if len(artifact_ids) != len(artifact_records) or len(set(artifact_ids)) != len(artifact_ids):
        errors.append("artifact identifiers are missing or not unique")
    known_artifacts = set(artifact_ids)
    for artifact in artifact_records:
        if not isinstance(artifact, dict):
            continue
        identifier = artifact.get("id", "<missing>")
        if artifact.get("studio") not in EXPECTED_STUDIOS:
            errors.append(f"invalid artifact studio: {identifier}")
        if artifact.get("kind") not in ARTIFACT_KINDS:
            errors.append(f"unsupported artifact kind: {identifier}")
        if not _is_safe_relative(artifact.get("workspace")):
            errors.append(f"invalid artifact workspace: {identifier}")
        if tuple(artifact.get("profiles", ())) != EXPECTED_PROFILES:
            errors.append(f"invalid artifact profiles: {identifier}")
        if artifact.get("kind") == "level_document":
            for field in (
                "spawn_list_count",
                "placement_count",
                "configuration_count",
                "stage_slot_count",
                "entry_bytes",
            ):
                value = artifact.get(field)
                if isinstance(value, bool) or not isinstance(value, int) or value <= 0:
                    errors.append(f"invalid artifact {field}: {identifier}")
        elif artifact.get("kind") == "graphics_tile_document":
            for field in ("payload_count", "tile_count"):
                value = artifact.get(field)
                if isinstance(value, bool) or not isinstance(value, int) or value <= 0:
                    errors.append(f"invalid artifact {field}: {identifier}")
        elif artifact.get("kind") == "compressed_tile_document":
            for field in (
                "payload_count",
                "tile_count",
                "decoded_byte_count",
                "compressed_capacity",
            ):
                value = artifact.get(field)
                if isinstance(value, bool) or not isinstance(value, int) or value <= 0:
                    errors.append(f"invalid artifact {field}: {identifier}")
        elif artifact.get("kind") == "palette_document":
            for field in ("block_count", "command_count", "offset_list_count"):
                value = artifact.get(field)
                if isinstance(value, bool) or not isinstance(value, int) or value <= 0:
                    errors.append(f"invalid artifact {field}: {identifier}")
        elif artifact.get("kind") == "mapping_document":
            for field in (
                "block_count",
                "mapping_count",
                "piece_count",
                "static_mapping_count",
                "dynamic_mapping_count",
                "payload_block_count",
            ):
                value = artifact.get(field)
                if isinstance(value, bool) or not isinstance(value, int) or value <= 0:
                    errors.append(f"invalid artifact {field}: {identifier}")
        elif artifact.get("kind") == "animation_document":
            for field in ("script_count", "frame_count", "jump_count", "target_count"):
                value = artifact.get(field)
                if isinstance(value, bool) or not isinstance(value, int) or value <= 0:
                    errors.append(f"invalid artifact {field}: {identifier}")
        elif artifact.get("kind") in ("screen_map_document", "stage_map_document"):
            for field in (
                "payload_count",
                "value_count",
                "decoded_byte_count",
                "compressed_capacity",
            ):
                value = artifact.get(field)
                if isinstance(value, bool) or not isinstance(value, int) or value <= 0:
                    errors.append(f"invalid artifact {field}: {identifier}")
        elif artifact.get("kind") == "story_text_document":
            if artifact.get("row_bytes") != 34:
                errors.append(f"invalid artifact row_bytes: {identifier}")
            counts = artifact.get("row_counts")
            if (
                not isinstance(counts, dict)
                or tuple(counts) != EXPECTED_PROFILES
                or any(isinstance(value, bool) or not isinstance(value, int) or value <= 0 for value in counts.values())
            ):
                errors.append(f"invalid artifact row_counts: {identifier}")
        elif artifact.get("kind") == "frontend_text_document":
            for field in ("string_count", "glyph_count", "encoded_byte_count"):
                value = artifact.get(field)
                if isinstance(value, bool) or not isinstance(value, int) or value <= 0:
                    errors.append(f"invalid artifact {field}: {identifier}")
        elif artifact.get("kind") == "results_text_document":
            for field in (
                "row_count",
                "row_bytes",
                "glyph_count",
                "encoded_byte_count",
                "max_glyph_id",
                "summary_label_count",
                "summary_glyph_count",
                "summary_encoded_byte_count",
            ):
                value = artifact.get(field)
                if isinstance(value, bool) or not isinstance(value, int) or value <= 0:
                    errors.append(f"invalid artifact {field}: {identifier}")
        elif artifact.get("kind") == "stage_message_document":
            for field in (
                "stream_count",
                "sequence_count",
                "entry_count",
                "encoded_byte_count",
            ):
                value = artifact.get(field)
                if isinstance(value, bool) or not isinstance(value, int) or value <= 0:
                    errors.append(f"invalid artifact {field}: {identifier}")
        elif artifact.get("kind") == "scripted_message_document":
            for field in (
                "script_count",
                "command_count",
                "record_count",
                "glyph_count",
                "encoded_byte_count",
                "unexposed_byte_count",
            ):
                value = artifact.get(field)
                if isinstance(value, bool) or not isinstance(value, int) or value <= 0:
                    errors.append(f"invalid artifact {field}: {identifier}")
        elif artifact.get("kind") == "credits_text_document":
            for field in (
                "record_count",
                "glyph_slot_count",
                "encoded_byte_count",
                "max_glyph_id",
            ):
                value = artifact.get(field)
                if isinstance(value, bool) or not isinstance(value, int) or value <= 0:
                    errors.append(f"invalid artifact {field}: {identifier}")
        elif artifact.get("kind") == "glyph_source_list_document":
            for field in ("list_count", "glyph_count", "encoded_byte_count"):
                value = artifact.get(field)
                if isinstance(value, bool) or not isinstance(value, int) or value <= 0:
                    errors.append(f"invalid artifact {field}: {identifier}")
        elif artifact.get("kind") == "japanese_glyph_document":
            for field in ("entry_count", "art_glyph_count", "encoded_byte_count", "glyph_bytes"):
                value = artifact.get(field)
                if isinstance(value, bool) or not isinstance(value, int) or value <= 0:
                    errors.append(f"invalid artifact {field}: {identifier}")
        elif artifact.get("kind") == "sound_sequence_document":
            for field in ("payload_count", "instruction_count", "reachable_byte_count"):
                value = artifact.get(field)
                if isinstance(value, bool) or not isinstance(value, int) or value <= 0:
                    errors.append(f"invalid artifact {field}: {identifier}")
        elif artifact.get("kind") == "sound_instrument_document":
            for field in (
                "payload_count",
                "instrument_count",
                "parameter_byte_count",
                "padding_byte_count",
            ):
                value = artifact.get(field)
                if isinstance(value, bool) or not isinstance(value, int) or value <= 0:
                    errors.append(f"invalid artifact {field}: {identifier}")
        elif artifact.get("kind") == "sound_envelope_document":
            for field in (
                "family_count",
                "envelope_count",
                "capacity",
                "value_count",
                "command_count",
                "protected_byte_count",
            ):
                value = artifact.get(field)
                if isinstance(value, bool) or not isinstance(value, int) or value <= 0:
                    errors.append(f"invalid artifact {field}: {identifier}")
        elif artifact.get("kind") == "sound_pcm_document":
            for field in (
                "bank_count",
                "sample_count",
                "sample_byte_count",
                "decoded_value_count",
                "header_byte_count",
                "padding_byte_count",
                "descriptor_record_count",
                "dispatchable_descriptor_count",
                "referenced_sample_count",
                "unreferenced_sample_count",
            ):
                value = artifact.get(field)
                if isinstance(value, bool) or not isinstance(value, int) or value <= 0:
                    errors.append(f"invalid artifact {field}: {identifier}")
        owners = artifact.get("source_owners")
        if not isinstance(owners, list) or not owners or not all(_is_safe_relative(owner) for owner in owners):
            errors.append(f"invalid artifact source owners: {identifier}")
    for studio in studios:
        if not isinstance(studio, dict):
            errors.append("studio entry is not an object")
            continue
        if studio.get("status") not in STUDIO_STATUSES:
            errors.append(f"invalid studio status: {studio.get('id')}")
        claims = studio.get("artifacts")
        if not isinstance(claims, list):
            errors.append(f"studio artifacts are not a list: {studio.get('id')}")
            continue
        for artifact in claims:
            if artifact not in known_artifacts:
                errors.append(f"studio {studio.get('id')} names unknown artifact {artifact}")
        if studio.get("status") == "supported" and not claims:
            errors.append(f"supported studio has no artifacts: {studio.get('id')}")
    return errors


def load_manifest(path: Path, root: Path) -> dict[str, Any]:
    """Load the content contract and cross-check its preservation profiles."""
    try:
        document = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise ContentError(f"cannot load content manifest {path}: {error}") from error
    errors = validate_manifest(document)
    if errors:
        raise ContentError("; ".join(errors))
    profile_path = checked_path(root, document["profile_manifest"])
    try:
        profiles = load_profiles(profile_path)
    except ProfileError as error:
        raise ContentError(str(error)) from error
    if tuple(profiles["profiles_by_id"]) != EXPECTED_PROFILES:
        raise ContentError("content and preservation profile order differs")
    document["profile_records"] = profiles["profiles_by_id"]
    return document


def profile_record(manifest: dict[str, Any], profile: str) -> dict[str, Any]:
    try:
        record = manifest["profile_records"][profile]
    except KeyError as error:
        raise ContentError(f"unknown content profile: {profile}") from error
    if record["status"] != "supported":
        raise ContentError(f"content base profile is not supported: {profile}")
    return record


def workspace_document(manifest: dict[str, Any], profile: str) -> dict[str, Any]:
    reference = profile_record(manifest, profile)["reference_rom"]
    return {
        "schema_version": 1,
        "profile": profile,
        "base_rom": {
            "size": reference["size"],
            "sha1": reference["sha1"],
            "sha256": reference["sha256"],
        },
        "artifacts": {},
    }


def workspace_path(root: Path, manifest: dict[str, Any], profile: str) -> Path:
    relative = Path(manifest["workspace"]) / profile / manifest["workspace_document"]
    return checked_path(root, relative, Path(manifest["workspace"]))


def artifact_path(root: Path, manifest: dict[str, Any], profile: str, artifact: dict[str, Any]) -> Path:
    relative = Path(manifest["workspace"]) / profile / artifact["workspace"]
    return checked_path(root, relative, Path(manifest["workspace"]))


def atomic_write_json(path: Path, document: dict[str, Any]) -> None:
    from authoring.atomic_output import atomic_write_json as _write_json

    _write_json(path, document, ensure_ascii=False)


def initialize(root: Path, manifest: dict[str, Any], profile: str, force: bool = False) -> bool:
    """Create one profile workspace without overwriting edits by default."""
    destination = workspace_path(root, manifest, profile)
    created = 0
    if not destination.exists() or force:
        atomic_write_json(destination, workspace_document(manifest, profile))
        created += 1
    for artifact in manifest["artifacts"]:
        if profile not in artifact["profiles"]:
            continue
        path = artifact_path(root, manifest, profile, artifact)
        if path.exists() and not force:
            if artifact["kind"] == "compressed_tile_document":
                from authoring.compressed_graphics_model import load_document, upgrade_legacy_document

                document = load_document(path)
                if document.get("schema_version") == 1:
                    atomic_write_json(path, upgrade_legacy_document(document, root, profile))
                    created += 1
            continue
        if artifact["kind"] == "level_document":
            from authoring.level_studio_model import export_document

            atomic_write_json(path, export_document(root, profile))
        elif artifact["kind"] == "graphics_tile_document":
            from authoring.graphics_studio_model import export_document

            atomic_write_json(path, export_document(root, profile))
        elif artifact["kind"] == "compressed_tile_document":
            from authoring.compressed_graphics_model import export_document

            atomic_write_json(path, export_document(root, profile))
        elif artifact["kind"] == "palette_document":
            from authoring.palette_studio_model import export_document

            atomic_write_json(path, export_document(root, profile))
        elif artifact["kind"] == "mapping_document":
            from authoring.mapping_studio_model import export_document

            atomic_write_json(path, export_document(root, profile))
        elif artifact["kind"] == "animation_document":
            from authoring.animation_studio_model import export_document

            atomic_write_json(path, export_document(root, profile))
        elif artifact["kind"] == "screen_map_document":
            from authoring.screen_map_model import export_document

            atomic_write_json(path, export_document(root, profile))
        elif artifact["kind"] == "stage_map_document":
            from authoring.stage_map_model import export_document

            atomic_write_json(path, export_document(root, profile))
        elif artifact["kind"] == "story_text_document":
            from authoring.story_text_model import export_document

            atomic_write_json(path, export_document(root, profile))
        elif artifact["kind"] == "frontend_text_document":
            from authoring.frontend_text_model import export_document

            atomic_write_json(path, export_document(root, profile))
        elif artifact["kind"] == "results_text_document":
            from authoring.results_text_model import export_document

            atomic_write_json(path, export_document(root, profile))
        elif artifact["kind"] == "stage_message_document":
            from authoring.stage_message_model import export_document

            atomic_write_json(path, export_document(root, profile))
        elif artifact["kind"] == "scripted_message_document":
            from authoring.scripted_message_model import export_document

            atomic_write_json(path, export_document(root, profile))
        elif artifact["kind"] == "credits_text_document":
            from authoring.credits_text_model import export_document

            atomic_write_json(path, export_document(root, profile))
        elif artifact["kind"] == "glyph_source_list_document":
            from authoring.glyph_source_list_model import export_document

            atomic_write_json(path, export_document(root, profile))
        elif artifact["kind"] == "japanese_glyph_document":
            from authoring.japanese_glyph_model import export_document

            atomic_write_json(path, export_document(root, profile))
        elif artifact["kind"] == "sound_sequence_document":
            from authoring.sound_sequence_model import export_document

            atomic_write_json(path, export_document(root, profile))
        elif artifact["kind"] == "sound_instrument_document":
            from authoring.sound_instrument_model import export_document

            atomic_write_json(path, export_document(root, profile))
        elif artifact["kind"] == "sound_envelope_document":
            from authoring.sound_envelope_model import export_document

            atomic_write_json(path, export_document(root, profile))
        elif artifact["kind"] == "sound_pcm_document":
            from authoring.sound_pcm_model import export_document

            atomic_write_json(path, export_document(root, profile))
        created += 1
    state = "initialized" if created else "already exists"
    print(f"[OK] Content workspace {state}: {destination.parent.relative_to(root)} ({created} file(s) written)")
    return bool(created)


def load_workspace(root: Path, manifest: dict[str, Any], profile: str) -> dict[str, Any]:
    path = workspace_path(root, manifest, profile)
    try:
        document = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as error:
        raise ContentError(f"workspace is missing: {path}; run make init-content") from error
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise ContentError(f"cannot load workspace {path}: {error}") from error
    expected = workspace_document(manifest, profile)
    if document.get("schema_version") != expected["schema_version"]:
        raise ContentError(f"workspace schema differs: {path}")
    if document.get("profile") != profile or document.get("base_rom") != expected["base_rom"]:
        raise ContentError(f"workspace base profile differs: {path}")
    artifacts = document.get("artifacts")
    if not isinstance(artifacts, dict):
        raise ContentError(f"workspace artifacts are not an object: {path}")
    known = {item["id"] for item in manifest["artifacts"]}
    unknown = sorted(set(artifacts) - known)
    if unknown:
        raise ContentError(f"workspace names unknown artifacts: {', '.join(unknown)}")
    return document


@with_parsed_operation
def validate_workspace(root: Path, manifest: dict[str, Any], profile: str) -> None:
    load_workspace(root, manifest, profile)
    for artifact in manifest["artifacts"]:
        if profile not in artifact["profiles"]:
            continue
        path = artifact_path(root, manifest, profile, artifact)
        if not path.is_file():
            raise ContentError(f"workspace artifact is missing: {path}; run make init-content")
        try:
            if artifact["kind"] == "level_document":
                from authoring.level_studio_model import load_document, validate_document

                document = load_document(path)
                validate_document(document, root, profile)
                observed = {
                    "spawn_list_count": len(document["spawn_lists"]),
                    "placement_count": sum(len(item["entries"]) for item in document["spawn_lists"]),
                    "configuration_count": len(document["configurations"]),
                    "stage_slot_count": len(document["stage_slots"]),
                    "entry_bytes": document["entry_bytes"],
                }
                for field, value in observed.items():
                    if artifact[field] != value:
                        raise ValueError(f"manifest {field} {artifact[field]} differs from {value}")
            elif artifact["kind"] == "graphics_tile_document":
                from authoring.graphics_studio_model import load_document, validate_document

                document = load_document(path)
                validate_document(document, root, profile)
                observed = {
                    "payload_count": len(document["payloads"]),
                    "tile_count": sum(len(block["tiles"]) for item in document["payloads"] for block in item["blocks"]),
                }
                for field, value in observed.items():
                    if artifact[field] != value:
                        raise ValueError(f"manifest {field} {artifact[field]} differs from {value}")
            elif artifact["kind"] == "compressed_tile_document":
                from authoring.compressed_graphics_model import (
                    load_document,
                    validate_document,
                )

                document = load_document(path, root, profile)
                validate_document(document, root, profile)
                observed = {
                    "payload_count": document["payload_count"],
                    "tile_count": document["tile_count"],
                    "decoded_byte_count": document["decoded_byte_count"],
                    "compressed_capacity": document["compressed_capacity"],
                }
                for field, value in observed.items():
                    if artifact[field] != value:
                        raise ValueError(f"manifest {field} {artifact[field]} differs from {value}")
            elif artifact["kind"] == "palette_document":
                from authoring.palette_studio_model import load_document, validate_document

                document = load_document(path)
                validate_document(document, root, profile)
                observed = {
                    "block_count": document["block_count"],
                    "command_count": len(document["commands"]),
                    "offset_list_count": len(document["offset_lists"]),
                }
                for field, value in observed.items():
                    if artifact[field] != value:
                        raise ValueError(f"manifest {field} {artifact[field]} differs from {value}")
            elif artifact["kind"] == "mapping_document":
                from authoring.mapping_studio_model import load_document, validate_document

                document = load_document(path)
                validate_document(document, root, profile)
                observed = {
                    "block_count": document["block_count"],
                    "mapping_count": document["mapping_count"],
                    "piece_count": document["piece_count"],
                    "static_mapping_count": document["static_mapping_count"],
                    "dynamic_mapping_count": document["dynamic_mapping_count"],
                    "payload_block_count": document["payload_block_count"],
                }
                for field, value in observed.items():
                    if artifact[field] != value:
                        raise ValueError(f"manifest {field} {artifact[field]} differs from {value}")
            elif artifact["kind"] == "animation_document":
                from authoring.animation_studio_model import load_document, validate_document

                document = load_document(path)
                validate_document(document, root, profile)
                observed = {
                    "script_count": document["script_count"],
                    "frame_count": document["frame_count"],
                    "jump_count": document["jump_count"],
                    "target_count": len(document["frame_targets"]),
                }
                for field, value in observed.items():
                    if artifact[field] != value:
                        raise ValueError(f"manifest {field} {artifact[field]} differs from {value}")
            elif artifact["kind"] in ("screen_map_document", "stage_map_document"):
                if artifact["kind"] == "screen_map_document":
                    from authoring.screen_map_model import load_document, validate_document
                else:
                    from authoring.stage_map_model import load_document, validate_document

                document = load_document(path)
                validate_document(document, root, profile)
                observed = {
                    "payload_count": document["payload_count"],
                    "value_count": document["value_count"],
                    "decoded_byte_count": document["decoded_byte_count"],
                    "compressed_capacity": document["compressed_capacity"],
                }
                for field, value in observed.items():
                    if artifact[field] != value:
                        raise ValueError(f"manifest {field} {artifact[field]} differs from {value}")
            elif artifact["kind"] == "story_text_document":
                from authoring.story_text_model import load_document, validate_document

                document = load_document(path)
                validate_document(document, root, profile)
                if artifact["row_bytes"] != document["row_bytes"]:
                    raise ValueError("manifest row_bytes differs from document")
                if artifact["row_counts"][profile] != document["row_count"]:
                    raise ValueError("manifest row count differs from document")
            elif artifact["kind"] == "frontend_text_document":
                from authoring.frontend_text_model import load_document, validate_document

                document = load_document(path)
                validate_document(document, root, profile)
                for field in ("string_count", "glyph_count", "encoded_byte_count"):
                    if artifact[field] != document[field]:
                        raise ValueError(f"manifest {field} differs from document")
            elif artifact["kind"] == "results_text_document":
                from authoring.results_text_model import load_document, validate_document

                document = load_document(path)
                validate_document(document, root, profile)
                for field in (
                    "row_count",
                    "row_bytes",
                    "glyph_count",
                    "encoded_byte_count",
                    "max_glyph_id",
                    "summary_label_count",
                    "summary_glyph_count",
                    "summary_encoded_byte_count",
                ):
                    if artifact[field] != document[field]:
                        raise ValueError(f"manifest {field} differs from document")
            elif artifact["kind"] == "stage_message_document":
                from authoring.stage_message_model import load_document, validate_document

                document = load_document(path)
                validate_document(document, root, profile)
                observed = {
                    "stream_count": document["stream_count"],
                    "sequence_count": sum(item["sequence_count"] for item in document["streams"]),
                    "entry_count": document["entry_count"],
                    "encoded_byte_count": document["encoded_byte_count"],
                }
                for field, value in observed.items():
                    if artifact[field] != value:
                        raise ValueError(f"manifest {field} differs from document")
            elif artifact["kind"] == "scripted_message_document":
                from authoring.scripted_message_model import load_document, validate_document

                document = load_document(path)
                validate_document(document, root, profile)
                for field in (
                    "script_count",
                    "command_count",
                    "record_count",
                    "glyph_count",
                    "encoded_byte_count",
                    "unexposed_byte_count",
                ):
                    if artifact[field] != document[field]:
                        raise ValueError(f"manifest {field} differs from document")
            elif artifact["kind"] == "credits_text_document":
                from authoring.credits_text_model import load_document, validate_document

                document = load_document(path)
                validate_document(document, root, profile)
                for field in (
                    "record_count",
                    "glyph_slot_count",
                    "encoded_byte_count",
                    "max_glyph_id",
                ):
                    if artifact[field] != document[field]:
                        raise ValueError(f"manifest {field} differs from document")
            elif artifact["kind"] == "glyph_source_list_document":
                from authoring.glyph_source_list_model import load_document, validate_document

                document = load_document(path)
                validate_document(document, root, profile)
                for field in ("list_count", "glyph_count", "encoded_byte_count"):
                    if artifact[field] != document[field]:
                        raise ValueError(f"manifest {field} differs from document")
            elif artifact["kind"] == "japanese_glyph_document":
                from authoring.japanese_glyph_model import load_document, validate_document

                document = load_document(path)
                validate_document(document, root, profile)
                for field in ("entry_count", "art_glyph_count", "encoded_byte_count", "glyph_bytes"):
                    if artifact[field] != document[field]:
                        raise ValueError(f"manifest {field} differs from document")
            elif artifact["kind"] == "sound_sequence_document":
                from authoring.sound_sequence_model import load_document, validate_document

                document = load_document(path)
                validate_document(document, root, profile)
                for field in ("payload_count", "instruction_count", "reachable_byte_count"):
                    if artifact[field] != document[field]:
                        raise ValueError(f"manifest {field} differs from document")
            elif artifact["kind"] == "sound_instrument_document":
                from authoring.sound_instrument_model import load_document, validate_document

                document = load_document(path)
                validate_document(document, root, profile)
                for field in (
                    "payload_count",
                    "instrument_count",
                    "parameter_byte_count",
                    "padding_byte_count",
                ):
                    if artifact[field] != document[field]:
                        raise ValueError(f"manifest {field} differs from document")
            elif artifact["kind"] == "sound_envelope_document":
                from authoring.sound_envelope_model import load_document, validate_document

                document = load_document(path)
                validate_document(document, root, profile)
                for field in (
                    "family_count",
                    "envelope_count",
                    "capacity",
                    "value_count",
                    "command_count",
                    "protected_byte_count",
                ):
                    if artifact[field] != document[field]:
                        raise ValueError(f"manifest {field} differs from document")
            elif artifact["kind"] == "sound_pcm_document":
                from authoring.sound_pcm_model import load_document, validate_document

                document = load_document(path)
                validate_document(document, root, profile)
                for field in (
                    "bank_count",
                    "sample_count",
                    "sample_byte_count",
                    "decoded_value_count",
                    "header_byte_count",
                    "padding_byte_count",
                    "descriptor_record_count",
                    "dispatchable_descriptor_count",
                    "referenced_sample_count",
                    "unreferenced_sample_count",
                ):
                    if artifact[field] != document[field]:
                        raise ValueError(f"manifest {field} differs from document")
        except ValueError as error:
            raise ContentError(f"invalid {artifact['id']}: {error}") from error
    map_artifacts = {
        item["id"]: item
        for item in manifest["artifacts"]
        if item["id"] in {"screen_maps", "stage_maps"} and profile in item["profiles"]
    }
    if set(map_artifacts) == {"screen_maps", "stage_maps"}:
        from authoring.screen_map_model import (
            export_document as export_screen_maps,
            load_document as load_screen_maps,
        )
        from authoring.screen_studio_state import validate_screen_map_references
        from authoring.stage_map_model import (
            export_document as export_stage_maps,
            load_document as load_stage_maps,
        )

        screen = load_screen_maps(artifact_path(root, manifest, profile, map_artifacts["screen_maps"]))
        stage = load_stage_maps(artifact_path(root, manifest, profile, map_artifacts["stage_maps"]))
        screen_baseline = export_screen_maps(root, profile)
        stage_baseline = export_stage_maps(root, profile)
        try:
            validate_screen_map_references(root, profile, screen, screen_baseline, stage, stage_baseline)
        except ValueError as error:
            raise ContentError(f"invalid screen maps: {error}") from error
        level_artifact = next(
            (item for item in manifest["artifacts"] if item["id"] == "level_layouts" and profile in item["profiles"]),
            None,
        )
        if level_artifact is not None:
            from authoring.level_studio_model import load_document as load_levels
            from authoring.level_studio_state import validate_stage_map_references

            levels = load_levels(artifact_path(root, manifest, profile, level_artifact))
            try:
                validate_stage_map_references(root, profile, levels, stage, stage_baseline, screen, screen_baseline)
            except ValueError as error:
                raise ContentError(f"invalid visible stage maps: {error}") from error
    print(f"[OK] {profile} content workspace is structurally valid")


def inspect(root: Path, manifest: dict[str, Any], profile: str) -> None:
    path = workspace_path(root, manifest, profile)
    if not path.is_file():
        print(f"Profile: {profile}\nWorkspace: missing")
        return
    current = path.read_bytes()
    baseline = (json.dumps(workspace_document(manifest, profile), indent=2, ensure_ascii=False) + "\n").encode("utf-8")
    state = "unchanged" if current == baseline else "edited"
    print(f"Profile: {profile}")
    print(f"Workspace: {state}, SHA256 {hashlib.sha256(current).hexdigest()}")
    for artifact in manifest["artifacts"]:
        if profile not in artifact["profiles"]:
            continue
        path = artifact_path(root, manifest, profile, artifact)
        if not path.is_file():
            print(f"{artifact['id']}: missing")
            continue
        if artifact["kind"] == "level_document":
            from authoring.level_studio_model import export_document, load_document

            unchanged = load_document(path) == export_document(root, profile)
        elif artifact["kind"] == "graphics_tile_document":
            from authoring.graphics_studio_model import export_document, load_document

            unchanged = load_document(path) == export_document(root, profile)
        elif artifact["kind"] == "compressed_tile_document":
            from authoring.compressed_graphics_model import export_document, load_document

            unchanged = load_document(path, root, profile) == export_document(root, profile)
        elif artifact["kind"] == "palette_document":
            from authoring.palette_studio_model import export_document, load_document

            unchanged = load_document(path) == export_document(root, profile)
        elif artifact["kind"] == "mapping_document":
            from authoring.mapping_studio_model import export_document, load_document

            unchanged = load_document(path) == export_document(root, profile)
        elif artifact["kind"] == "animation_document":
            from authoring.animation_studio_model import export_document, load_document

            unchanged = load_document(path) == export_document(root, profile)
        elif artifact["kind"] == "screen_map_document":
            from authoring.screen_map_model import export_document, load_document

            unchanged = load_document(path) == export_document(root, profile)
        elif artifact["kind"] == "stage_map_document":
            from authoring.stage_map_model import export_document, load_document

            unchanged = load_document(path) == export_document(root, profile)
        elif artifact["kind"] == "story_text_document":
            from authoring.story_text_model import export_document, load_document

            unchanged = load_document(path) == export_document(root, profile)
        elif artifact["kind"] == "frontend_text_document":
            from authoring.frontend_text_model import export_document, load_document

            unchanged = load_document(path) == export_document(root, profile)
        elif artifact["kind"] == "results_text_document":
            from authoring.results_text_model import export_document, load_document

            unchanged = load_document(path) == export_document(root, profile)
        elif artifact["kind"] == "stage_message_document":
            from authoring.stage_message_model import export_document, load_document

            unchanged = load_document(path) == export_document(root, profile)
        elif artifact["kind"] == "scripted_message_document":
            from authoring.scripted_message_model import export_document, load_document

            unchanged = load_document(path) == export_document(root, profile)
        elif artifact["kind"] == "credits_text_document":
            from authoring.credits_text_model import export_document, load_document

            unchanged = load_document(path) == export_document(root, profile)
        elif artifact["kind"] == "glyph_source_list_document":
            from authoring.glyph_source_list_model import export_document, load_document

            unchanged = load_document(path) == export_document(root, profile)
        elif artifact["kind"] == "japanese_glyph_document":
            from authoring.japanese_glyph_model import export_document, load_document

            unchanged = load_document(path) == export_document(root, profile)
        elif artifact["kind"] == "sound_sequence_document":
            from authoring.sound_sequence_model import export_document, load_document

            unchanged = load_document(path) == export_document(root, profile)
        elif artifact["kind"] == "sound_instrument_document":
            from authoring.sound_instrument_model import export_document, load_document

            unchanged = load_document(path) == export_document(root, profile)
        elif artifact["kind"] == "sound_envelope_document":
            from authoring.sound_envelope_model import export_document, load_document

            unchanged = load_document(path) == export_document(root, profile)
        elif artifact["kind"] == "sound_pcm_document":
            from authoring.sound_pcm_model import export_document, load_document

            unchanged = load_document(path) == export_document(root, profile)
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        print(f"{artifact['id']}: {'unchanged' if unchanged else 'edited'}, SHA256 {digest}")


def _remove_generated_tree(root: Path, destination: Path) -> None:
    relative = destination.relative_to(root.resolve())
    checked = checked_path(root, relative, GENERATED_ROOT)
    if checked.is_dir():
        shutil.rmtree(checked)
    elif checked.exists():
        raise ContentError(f"generated tree path is not a directory: {checked}")


def _check_staging_input(source: Path) -> None:
    if not source.is_dir():
        raise ContentError(f"content staging input is missing: {source}")

    def failed(error: OSError) -> None:
        raise ContentError(f"cannot inspect staging input: {error}") from error

    for directory, children, files in os.walk(source, followlinks=False, onerror=failed):
        for name in children + files:
            path = Path(directory) / name
            if path.is_symlink() or getattr(path, "is_junction", lambda: False)():
                raise ContentError(f"content staging input crosses a link: {path}")


def stage_tree(root: Path, destination: Path) -> Path:
    """Copy canonical source and extracted data into a disposable build tree."""
    root = root.resolve()
    raw_destination = destination if destination.is_absolute() else root / destination
    try:
        relative = raw_destination.relative_to(root)
    except ValueError as error:
        raise ContentError(f"staging destination is outside {GENERATED_ROOT}: {destination}") from error
    if not _inside(raw_destination, root / GENERATED_ROOT):
        raise ContentError(f"staging destination is outside {GENERATED_ROOT}: {destination}")
    if relative.name != "tree" or len(relative.parts) < 4:
        raise ContentError(f"staging destination must be a profile tree: {destination}")
    destination = checked_path(root, relative, GENERATED_ROOT)
    if not _inside(destination, root / GENERATED_ROOT):
        raise ContentError(f"staging destination is outside {GENERATED_ROOT}: {destination}")
    for name in ("src", "data"):
        _check_staging_input(checked_path(root, name))
    if not (root / "src/main.s").is_file():
        raise ContentError("content staging input is missing: src/main.s")
    _remove_generated_tree(root, destination)
    destination.mkdir(parents=True)
    for name in ("src", "data"):
        source = checked_path(root, name)
        shutil.copytree(source, destination / name, copy_function=shutil.copyfile)
    return destination / "src/main.s"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("init", "inspect", "validate"))
    parser.add_argument("--root", default=".")
    parser.add_argument("--manifest", default="config/authoring/content_studios.json")
    parser.add_argument("--profile", default="jp", choices=EXPECTED_PROFILES)
    parser.add_argument("--force", action="store_true")
    args = parser.parse_args()
    root = Path(args.root).resolve()
    try:
        manifest_path = checked_path(root, args.manifest)
        manifest = load_manifest(manifest_path, root)
        if args.command == "init":
            initialize(root, manifest, args.profile, args.force)
        elif args.command == "inspect":
            inspect(root, manifest, args.profile)
        else:
            validate_workspace(root, manifest, args.profile)
        return 0
    except ContentError as error:
        print(f"[ERROR] {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())

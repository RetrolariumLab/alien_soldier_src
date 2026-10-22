"""Prove initial stage-state index domains from the cartridge's selected readers.

This checks the first indexed read, not semantic suitability or all later
transitions. No process family is inferred from a configuration's name.
"""

from __future__ import annotations

import re
from pathlib import Path


SOURCE_OWNERS = (
    "src/stages/stage_process_dispatch.s",
    "src/stages/early_stage_process_states.s",
    "src/stages/stage10_to_stage13.s",
    "src/stages/late_game_state_dispatch.s",
    "src/stages/stage_and_boss_transition_states.s",
    "src/stages/object_loading.s",
    "src/stages/phase_loading.s",
    "src/stages/configuration.s",
    "src/stages/configuration_records.s",
)
FAMILIES = {
    "Stage_DispatchEarlyStageState": ("EarlyStage_StateHandlerOffsets", "Stage1_InitializeScrollState"),
    "Stage_DispatchMidgameState": ("Stage_MidgameStateHandlerOffsets", "Stage10_Initialize"),
    "Stage_DispatchLateGameState": ("Stage_LateGameStateHandlerOffsets", "Stage_LateGameStateReturn"),
    "Stage_DispatchTransitionState": ("Stage_TransitionStateOffsets", "StageTransition_InitializeAsteroidField"),
}


def blocks(root: Path) -> dict[str, list[str]]:
    result = {}
    for relative in SOURCE_OWNERS:
        current = None
        for line in (root / relative).read_text(encoding="utf-8").splitlines():
            code = line.split(";", 1)[0].strip()
            match = re.match(r"^(\w+):(.*)$", code)
            if match:
                current, code = match.groups()
                if current in result:
                    raise ValueError("duplicate stage-state source label: " + current)
                result[current] = []
                code = code.strip()
            if current is not None and code:
                result[current].append(re.sub(r"\s+", " ", code))
    return result


def table(source: dict, name: str, size: str, anchor: str | None = None) -> tuple[str, ...]:
    entries = []
    for line in source.get(name, ()):
        expression = r"dc\.%s (\w+)" % size
        if anchor is not None:
            expression += "-" + re.escape(anchor)
        match = re.fullmatch(expression, line)
        if match is None:
            raise ValueError("unsupported stage-state table entry: " + name)
        entries.append(match[1])
    if not entries:
        raise ValueError("missing stage-state source table: " + name)
    return tuple(entries)


def assignment(body: list[str], name: str) -> int:
    """Require an unconditional assignment at the loader's entry, before calls."""
    if not body:
        raise ValueError("missing stage process initializer: " + name)
    first = body[0]
    if first == "clr.w (StageProcessTableOffset).w":
        return 0
    match = re.fullmatch(r"move\.w #(?P<value>\$[0-9A-Fa-f]+|\d+),\(StageProcessTableOffset\)\.w", first)
    if match:
        value = match["value"]
        return int(value[1:], 16) if value.startswith("$") else int(value)
    raise ValueError("stage loader has no proved initial process assignment: " + name)


def initial_domains(root: Path, slots: list[dict]) -> list[dict]:
    source = blocks(root)
    expected_loader = [
        "bsr.w Stage_LoadSharedMappings",
        "move.w (StageTableIndex).w,d0",
        "movea.w Stage_AssetLoaderOffsets(pc,d0.w),a0",
        "adda.l #Stage_LoadSharedMappings,a0",
        "jmp (a0)",
    ]
    expected_initializer = [
        "move.w (StageTableIndex).w,d0",
        "movea.w Stage_InitializerOffsets(pc,d0.w),a0",
        "adda.l #Weapon_ClearAmmoRegenTimers,a0",
        "jmp (a0)",
    ]
    if source.get("Stage_LoadAssetsForCurrentTableIndex") != expected_loader:
        raise ValueError("stage asset-loader indexed reader differs")
    if source.get("Stage_DispatchInitializer") != expected_initializer:
        raise ValueError("stage configuration indexed reader differs")
    if source.get("Stage_ApplyConfigurationRecord", [])[:1] != ["move.w (a0)+,(StageStateOffset).w"]:
        raise ValueError("stage record no longer seeds the state word at offset zero")
    dispatch = source.get("Stage_RunSelectedProcess", ())
    required = [
        "move.w (StageStateOffset).w,d0",
        "move.w (StageProcessTableOffset).w,d1",
        "movea.l Stage_ProcessHandlerTable(pc,d1.w),a0",
        "jmp (a0)",
    ]
    if list(dispatch[-4:]) != required:
        raise ValueError("stage process indexed reader differs from the proved instructions")
    processes = table(source, "Stage_ProcessHandlerTable", "l")
    if any(name not in FAMILIES for name in processes):
        raise ValueError("stage process has no proved state reader")
    capacities = {}
    for name, (owner, anchor) in FAMILIES.items():
        reader_name = "Stage_DispatchMidgameState_Handler" if name == "Stage_DispatchMidgameState" else name
        reader = source.get(reader_name, ())
        expected = ["movea.w %s(pc,d0.w),a0" % owner, "adda.l #%s,a0" % anchor, "jmp (a0)"]
        if list(reader[-3:]) != expected:
            raise ValueError("stage state indexed reader differs: " + reader_name)
        if name == "Stage_DispatchMidgameState" and list(reader[:1]) != ["move.w (StageStateOffset).w,d0"]:
            raise ValueError("midgame state reader no longer reads the configuration-seeded word")
        capacities[name] = len(table(source, owner, "w", anchor))
    loaders = table(source, "Stage_AssetLoaderOffsets", "w", "Stage_LoadSharedMappings")
    if len(loaders) != len(slots):
        raise ValueError("stage asset-loader and configuration slot inventories differ")
    results = []
    for index, (loader, slot) in enumerate(zip(loaders, slots, strict=True)):
        offset = assignment(source.get(loader, []), loader)
        initializer = source.get(slot["initializer"], [])
        if not initializer:
            raise ValueError("stage configuration initializer is missing")
        for position, line in enumerate(initializer):
            if "StageProcessTableOffset" not in line:
                continue
            # Only the stage-17 initializer currently overrides the loader.
            # Prove the actual instruction, not a hard-coded stage number.
            if position != 0:
                raise ValueError("stage initializer process override is not proved unconditional at entry")
            offset = assignment([line], slot["initializer"])
        if offset % 4 or not 0 <= offset // 4 < len(processes):
            raise ValueError("stage loader process offset escapes its pointer table")
        family = processes[offset // 4]
        results.append(
            {
                "index": index,
                "loader": loader,
                "process_offset": offset,
                "process": family,
                "table": FAMILIES[family][0],
                "entry_count": capacities[family],
                "allowed": frozenset(range(0, capacities[family] * 2, 2)),
            }
        )
    return results


def state_errors(root: Path, document: dict, baseline: dict) -> list[str]:
    originals = {record["name"]: record for record in baseline["configurations"]}
    slots = document.get("stage_slots")
    records = document.get("configurations")
    if not isinstance(slots, list) or not isinstance(records, list):
        return []  # The owning complete document validator reports structure.
    if len(slots) != len(baseline["stage_slots"]):
        return []
    domains = initial_domains(root, baseline["stage_slots"])
    candidates = {
        record.get("name"): record
        for record in records
        if isinstance(record, dict) and isinstance(record.get("name"), str)
    }
    constraints = {name: [] for name in originals}
    for slot, domain in zip(slots, domains, strict=True):
        if isinstance(slot, dict) and isinstance(slot.get("configuration"), str):
            if slot["configuration"] in constraints:
                constraints[slot["configuration"]].append(domain)
    errors = []
    for name, record in candidates.items():
        if name not in originals or not isinstance(record.get("fields"), dict):
            continue
        value = record["fields"].get("state_offset")
        if type(value) is not int:
            continue
        if not constraints[name]:
            if value != originals[name]["fields"]["state_offset"]:
                errors.append("%s: state_offset has no selected initial reader; preserve its source value" % name)
        for domain in constraints[name]:
            if value not in domain["allowed"]:
                errors.append(
                    "%s: state_offset is outside the aligned %s domain for stage slot %d"
                    % (name, domain["table"], domain["index"])
                )
    return errors

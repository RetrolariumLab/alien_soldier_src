# Gens Emulator State Dump Specification

## Overview

This reference explains the state-dump container consumed by the project tools.
It preserves the original implementation design and examples; not every optional
section or proposed flag is an accepted runtime capability. The current pinned
runner, declared sections and exact-frame validation are described in
[runtime verification](runtime.md). A container checksum identifies an input; it
does not replace complete ROM identity or scenario acceptance predicates.

## Use Case

When modifying ROMs (e.g., removing unused data), visual differences may appear
but the root cause is unclear. By comparing full memory state between original
and modified ROM runs, we can identify exactly what changed in RAM, VRAM,
registers, etc.

An illustrative relocation failure can be investigated by comparing the first
differing RAM/VRAM state. This is a debugging example, not a reproduced
current-game defect, proof of a particular boss identity or an accepted patch.

## Command Line Interface

### New Flags

```
-dump-state-dir <directory>
    Enable state dumping and specify output directory.
    Creates .genstate files for each captured frame.

-dump-state-interval <frames>
    Frame interval for state dumps (default: 20)
    Same as screenshot-interval but for state dumps.

-dump-state-frames <frame1,frame2,...>
    Dump state only at specific frames (comma-separated list)
    Example: -dump-state-frames 1000,2000,3000

-dump-state-start <frame>
    Start dumping state from this frame (default: 0)

-dump-state-end <frame>
    Stop dumping state after this frame (default: no limit)
```

### Example Usage

```bash
# Dump state every 20 frames for first 10000 frames
Gens.exe -rom original.bin -play movie.gmv \
    -dump-state-dir states/original \
    -dump-state-interval 20 \
    -dump-state-end 10000

# Dump state only at specific frames where bug appears
Gens.exe -rom modified.bin -play movie.gmv \
    -dump-state-dir states/modified \
    -dump-state-frames 5000,5020,5040,5060
```

## File Format

See `scripts/genstate_format.py` for detailed format specification.

### File Naming

```
<frame_number>.genstate
```

Examples:

- `20.genstate` - State at frame 20
- `5000.genstate` - State at frame 5000

### Container Structure

```
[64 bytes] Header
    - Magic: "GENSTATE" (8 bytes)
    - Version: 1 (4 bytes, little-endian)
    - Frame: frame number (4 bytes, LE)
    - Timestamp: Unix timestamp (8 bytes, LE)
    - ROM checksum: CRC32 of ROM (4 bytes, LE)
    - Reserved: 36 bytes

[N * 16 bytes] Section Table
    Each entry:
        - Section ID (4 bytes, LE)
        - Offset from file start (4 bytes, LE)
        - Size in bytes (4 bytes, LE)
        - Flags (4 bytes, LE) [reserved]
    End marker: all zeros (16 bytes)

[Variable] Section Data
    Raw binary data for each section
```

## Required Sections

### Section 0x01: 68000 RAM

- **Size:** 65536 bytes (64KB)
- **Source:** Main 68000 work RAM (0xFF0000-0xFFFFFF)
- **Implementation:** `memcpy(dest, M68K_RAM, 0x10000)`

### Section 0x02: 68000 Registers

- **Size:** 72 bytes
- **Layout:**
  ```
  [32 bytes] D0-D7 (8 × 4 bytes, LE)
  [32 bytes] A0-A7 (8 × 4 bytes, LE)
  [4 bytes]  PC (4 bytes, LE)
  [4 bytes]  SR (4 bytes, LE)
  ```
- **Implementation:** Access from M68K emulation core

### Section 0x10: VDP VRAM

- **Size:** 65536 bytes (64KB)
- **Source:** VDP video RAM
- **Implementation:** Copy from VDP VRAM buffer

### Section 0x11: VDP CRAM (Color RAM)

- **Size:** 128 bytes
- **Source:** VDP color palette (64 colors × 2 bytes)
- **Implementation:** Copy from VDP CRAM buffer

### Section 0x12: VDP VSRAM (Vertical Scroll RAM)

- **Size:** 80 bytes
- **Source:** VDP vertical scroll values (40 entries × 2 bytes)
- **Implementation:** Copy from VDP VSRAM buffer

### Section 0x13: VDP Registers

- **Size:** 24 bytes
- **Source:** VDP register set (registers 0-23)
- **Implementation:** Copy from VDP register array

## Optional Sections (Future Enhancement)

### Section 0x20: Z80 RAM

- **Size:** 8192 bytes (8KB)
- **Source:** Z80 RAM

### Section 0x21: Z80 Registers

- **Size:** ~20 bytes
- **Layout:** A, F, BC, DE, HL, IX, IY, SP, PC, etc.

### Section 0x30: YM2612 State

- **Size:** Variable
- **Contents:** YM2612 FM synthesizer register state

### Section 0x31: PSG State

- **Size:** ~16 bytes
- **Contents:** PSG tone/noise generator state

## Implementation Notes

### Performance Considerations

State dumps are relatively small (~130KB per frame with basic sections) but can
add up:

- 20 frame interval over 90000 frames = 4500 dumps
- 4500 × 130KB ≈ 585 MB

Recommendations:

1. Use reasonable frame intervals (20-60)
2. Limit dump range to regions where bugs appear
3. Consider compression (gzip) if needed

### Integration Points

**In `automation.cpp`:**

```cpp
// Add state dump check in frame update loop
if (ShouldDumpState(frameCount)) {
    DumpEmulatorState(frameCount);
}
```

**New file `state_dump.cpp`:**

```cpp
void DumpEmulatorState(int frame) {
    // Open file
    char filename[256];
    sprintf(filename, "%s/%d.genstate", StateDumpDir, frame);
    FILE* f = fopen(filename, "wb");

    // Write header
    WriteStateHeader(f, frame);

    // Write sections
    WriteSection(f, SECTION_M68K_RAM, M68K_RAM, 0x10000);
    WriteSection(f, SECTION_M68K_REGS, GetM68KRegisters(), 72);
    WriteSection(f, SECTION_VDP_VRAM, VDP_VRAM, 0x10000);
    WriteSection(f, SECTION_VDP_CRAM, VDP_CRAM, 128);
    WriteSection(f, SECTION_VDP_VSRAM, VDP_VSRAM, 80);
    WriteSection(f, SECTION_VDP_REGS, VDP_Regs, 24);

    // Write end marker
    WriteEndMarker(f);

    fclose(f);
}
```

### ROM Checksum Calculation

Use CRC32 of entire ROM for header:

```cpp
uint32_t CalculateROMChecksum() {
    // Use existing ROM buffer
    return crc32(0, ROM_Data, ROM_Size);
}
```

## Testing

### Basic Test

1. Run original ROM with
   `-dump-state-dir states/original -dump-state-frames 1000`
2. Verify `states/original/1000.genstate` is created
3. Use Python tool to read and display contents

### Comparison Test

1. Run original ROM, dump state at frame 5000
2. Run modified ROM, dump state at frame 5000
3. Use `compare_states.py` to show differences

### Range Test

1. Run with `-dump-state-interval 20 -dump-state-end 10000`
2. Verify 500 state files created (10000 / 20)
3. Check file sizes are consistent (~130KB each)

## Workflow Example

**Debugging Antlord hitbox bug:**

```bash
# Step 1: Dump original ROM state
make build  # Build original ROM
Gens.exe -rom asbuilt.bin -play movie.gmv \
    -dump-state-dir states/antlord_original \
    -dump-state-start 45000 -dump-state-end 50000 \
    -dump-state-interval 20 \
    -turbo -nosound

# Step 2: Remove UnidentifiedSegaTilemap data and rebuild
# (edit src/data/sega_screen_assets.s to comment out UnidentifiedSegaTilemap)
make build

# Step 3: Dump modified ROM state
Gens.exe -rom asbuilt.bin -play movie.gmv \
    -dump-state-dir states/antlord_modified \
    -dump-state-start 45000 -dump-state-end 50000 \
    -dump-state-interval 20 \
    -turbo -nosound

# Step 4: Compare states to find first difference
python scripts/compare_states.py \
    states/antlord_original \
    states/antlord_modified \
    --frame-start 45000 --frame-end 50000 --interval 20

# Output will show:
#   First difference at frame: 47340
#   RAM difference at 0xFF1234: 0x20 -> 0x00
#   VRAM difference at 0x8000: ...
```

This pinpoints exactly when and where the bug manifests in memory.

## Future Enhancements

1. **Compression:** Add gzip compression flag to reduce disk usage
2. **Selective sections:** Allow choosing which sections to dump
3. **Diff mode:** Built-in comparison between two state files
4. **JSON export:** Convert .genstate to JSON for easier inspection
5. **Memory watch:** Track specific addresses across frames

## References

- Gens-automation source: `gens_automation/src/`
- Existing automation: `automation.cpp`, `screenshot.cpp`
- Format implementation: `scripts/genstate_format.py`
- Comparison tool: `scripts/compare_states.py`

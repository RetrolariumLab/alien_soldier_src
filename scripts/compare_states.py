#!/usr/bin/env python3
"""
Genesis State Dump Comparison Tool

Reads and compares .genstate files containing complete emulator state.
Generates detailed reports for LLM analysis showing memory, sprite, and register differences.
"""

import sys
import os
import struct
from enum import IntEnum
from dataclasses import dataclass
from typing import Dict, List, Optional, Tuple
from pathlib import Path
from datetime import datetime


class SectionID(IntEnum):
    """Section identifiers for state dump."""

    M68K_RAM = 0x01  # 68000 RAM (64KB)
    M68K_REGS = 0x02  # 68000 Registers (72 bytes)
    VDP_VRAM = 0x10  # VDP Video RAM (64KB)
    VDP_CRAM = 0x11  # VDP Color RAM (128 bytes)
    VDP_VSRAM = 0x12  # VDP Vertical Scroll RAM (80 bytes)
    VDP_REGS = 0x13  # VDP Registers (24 bytes)
    Z80_RAM = 0x20  # Z80 RAM (8KB)
    Z80_REGS = 0x21  # Z80 Registers (~20 bytes)
    YM2612 = 0x30  # YM2612 FM chip state (5328 bytes)
    PSG = 0x31  # PSG state (~64 bytes)
    SRAM = 0x40  # Battery-backed SRAM (64KB)


@dataclass
class SectionEntry:
    """Section table entry."""

    section_id: int
    offset: int
    size: int
    flags: int


@dataclass
class StateHeader:
    """State dump header."""

    magic: bytes
    version: int
    frame: int
    timestamp: int
    rom_checksum: int

    @classmethod
    def from_bytes(cls, data: bytes) -> "StateHeader":
        """Parse header from bytes."""
        if len(data) < 64:
            raise ValueError("Header too short")

        magic = data[0:8]
        if magic != b"GENSTATE":
            raise ValueError(f"Invalid magic: {magic}")

        version, frame, timestamp, rom_checksum = struct.unpack("<IIQI", data[8:28])

        return cls(magic, version, frame, timestamp, rom_checksum)


class GenstateReader:
    """Reader for .genstate files."""

    def __init__(self, filepath: str):
        self.filepath = filepath
        self.header: Optional[StateHeader] = None
        self.sections: Dict[int, bytes] = {}
        self._load()

    def _load(self):
        """Load state dump from file."""
        with open(self.filepath, "rb") as f:
            # Read header
            header_data = f.read(64)
            self.header = StateHeader.from_bytes(header_data)

            # Read section table
            section_entries = []
            while True:
                entry_data = f.read(16)
                if len(entry_data) < 16:
                    break

                section_id, offset, size, flags = struct.unpack("<IIII", entry_data)

                # End of section table marker
                if section_id == 0 and offset == 0:
                    break

                section_entries.append(SectionEntry(section_id, offset, size, flags))

            # Read section data
            for entry in section_entries:
                f.seek(entry.offset)
                data = f.read(entry.size)
                self.sections[entry.section_id] = data

    def get_section(self, section_id: SectionID) -> Optional[bytes]:
        """Get section data by ID."""
        return self.sections.get(section_id)

    def get_m68k_ram(self) -> Optional[bytes]:
        """Get 68000 RAM (64KB)."""
        return self.get_section(SectionID.M68K_RAM)

    def get_m68k_regs(self) -> Optional[bytes]:
        """Get 68000 Registers (72 bytes)."""
        return self.get_section(SectionID.M68K_REGS)

    def get_vdp_vram(self) -> Optional[bytes]:
        """Get VDP VRAM (64KB)."""
        return self.get_section(SectionID.VDP_VRAM)

    def get_vdp_cram(self) -> Optional[bytes]:
        """Get VDP Color RAM (128 bytes)."""
        return self.get_section(SectionID.VDP_CRAM)

    def get_vdp_vsram(self) -> Optional[bytes]:
        """Get VDP VSRAM (80 bytes)."""
        return self.get_section(SectionID.VDP_VSRAM)

    def get_vdp_regs(self) -> Optional[bytes]:
        """Get VDP Registers (24 bytes)."""
        return self.get_section(SectionID.VDP_REGS)

    def get_z80_ram(self) -> Optional[bytes]:
        """Get Z80 RAM (8KB)."""
        return self.get_section(SectionID.Z80_RAM)

    def get_z80_regs(self) -> Optional[bytes]:
        """Get Z80 Registers (~20 bytes)."""
        return self.get_section(SectionID.Z80_REGS)

    def get_ym2612(self) -> Optional[bytes]:
        """Get YM2612 FM chip state (5328 bytes)."""
        return self.get_section(SectionID.YM2612)

    def get_psg(self) -> Optional[bytes]:
        """Get PSG sound state (~64 bytes)."""
        return self.get_section(SectionID.PSG)

    def get_sram(self) -> Optional[bytes]:
        """Get battery-backed SRAM (up to 64KB)."""
        return self.get_section(SectionID.SRAM)


def format_hex_dump(data: bytes, offset: int, length: int = 16) -> str:
    """Format hex dump line."""
    hex_part = " ".join(f"{b:02X}" for b in data[offset : offset + length])
    ascii_part = "".join(chr(b) if 32 <= b < 127 else "." for b in data[offset : offset + length])
    return f"{offset:08X}  {hex_part:<48}  {ascii_part}"


def find_memory_differences(
    original: bytes, modified: bytes, section_name: str, base_addr: int = 0, max_diffs: int = 1000
) -> List[Tuple[int, int, int]]:
    """Find differences between two memory regions."""
    if len(original) != len(modified):
        print(f"WARNING: {section_name} size mismatch: {len(original)} vs {len(modified)}")
        return []

    diffs = []
    i = 0
    while i < len(original) and len(diffs) < max_diffs:
        if original[i] != modified[i]:
            # Find extent of difference
            start = i
            while i < len(original) and original[i] != modified[i]:
                i += 1
            end = i

            diffs.append((base_addr + start, base_addr + end, end - start))
        else:
            i += 1

    return diffs


def parse_m68k_registers(reg_data: bytes) -> Dict[str, int]:
    """Parse 68000 register data."""
    regs = {}

    # D0-D7 (8 × 4 bytes, LE)
    for i in range(8):
        offset = i * 4
        value = struct.unpack("<I", reg_data[offset : offset + 4])[0]
        regs[f"D{i}"] = value

    # A0-A7 (8 × 4 bytes, LE)
    for i in range(8):
        offset = 32 + i * 4
        value = struct.unpack("<I", reg_data[offset : offset + 4])[0]
        regs[f"A{i}"] = value

    # PC
    regs["PC"] = struct.unpack("<I", reg_data[64:68])[0]

    # SR
    regs["SR"] = struct.unpack("<I", reg_data[68:72])[0]

    return regs


def parse_vdp_registers(reg_data: bytes) -> Dict[int, int]:
    """Parse VDP register data."""
    return {i: reg_data[i] for i in range(min(24, len(reg_data)))}


def generate_llm_report(ref_file: str, cur_file: str, output_dir: str):
    """Generate detailed LLM-friendly comparison report."""

    print(f"Loading reference state: {ref_file}")
    ref = GenstateReader(ref_file)

    print(f"Loading current state: {cur_file}")
    cur = GenstateReader(cur_file)

    # Create reports directory
    os.makedirs(output_dir, exist_ok=True)

    # Extract frame number from filename
    frame_num = Path(cur_file).stem.replace("_current", "")
    report_file = os.path.join(output_dir, f"diff_frame_{frame_num}.md")

    print(f"Generating report: {report_file}")

    with open(report_file, "w", encoding="utf-8") as f:
        # Header
        f.write(f"# Memory State Difference Report\n\n")
        f.write(f"**Frame:** {frame_num}\n")
        f.write(f"**Generated:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
        f.write(f"**Reference ROM Checksum:** 0x{ref.header.rom_checksum:08X}\n")
        f.write(f"**Current ROM Checksum:** 0x{cur.header.rom_checksum:08X}\n\n")

        f.write("---\n\n")

        # Summary
        f.write("## Summary\n\n")
        f.write("This report shows the first frame where the modified ROM's memory state differs from the reference.\n")
        f.write("Differences indicate where the ROM modification affected game behavior.\n\n")

        # 68000 Registers
        f.write("## 68000 CPU Registers\n\n")
        ref_regs_data = ref.get_m68k_regs()
        cur_regs_data = cur.get_m68k_regs()

        if ref_regs_data and cur_regs_data:
            ref_regs = parse_m68k_registers(ref_regs_data)
            cur_regs = parse_m68k_registers(cur_regs_data)

            reg_diffs = []
            for reg_name in ref_regs:
                if ref_regs[reg_name] != cur_regs[reg_name]:
                    reg_diffs.append((reg_name, ref_regs[reg_name], cur_regs[reg_name]))

            if reg_diffs:
                f.write("**Register differences found:**\n\n")
                f.write("| Register | Reference | Current | Difference |\n")
                f.write("|----------|-----------|---------|------------|\n")
                for reg_name, ref_val, cur_val in reg_diffs:
                    diff = cur_val - ref_val
                    f.write(f"| {reg_name} | 0x{ref_val:08X} | 0x{cur_val:08X} | {diff:+d} (0x{abs(diff):X}) |\n")
                f.write("\n")
            else:
                f.write("**No register differences**\n\n")

        # 68000 RAM
        f.write("## 68000 RAM (0xFF0000-0xFFFFFF)\n\n")
        ref_ram = ref.get_m68k_ram()
        cur_ram = cur.get_m68k_ram()

        if ref_ram and cur_ram:
            ram_diffs = find_memory_differences(ref_ram, cur_ram, "RAM", 0xFF0000)

            if ram_diffs:
                f.write(f"**Found {len(ram_diffs)} difference region(s)**\n\n")

                for addr_start, addr_end, size in ram_diffs[:20]:  # Limit to first 20
                    offset_start = addr_start - 0xFF0000
                    offset_end = addr_end - 0xFF0000

                    f.write(f"### RAM Difference: 0x{addr_start:08X} - 0x{addr_end:08X} ({size} bytes)\n\n")

                    # Show context
                    context_start = max(0, offset_start - 16)
                    context_end = min(len(ref_ram), offset_end + 16)

                    f.write("**Reference (original ROM):**\n```\n")
                    for off in range(context_start, context_end, 16):
                        if offset_start <= off < offset_end:
                            f.write(f"→ {format_hex_dump(ref_ram, off)}\n")
                        else:
                            f.write(f"  {format_hex_dump(ref_ram, off)}\n")
                    f.write("```\n\n")

                    f.write("**Current (modified ROM):**\n```\n")
                    for off in range(context_start, context_end, 16):
                        if offset_start <= off < offset_end:
                            f.write(f"→ {format_hex_dump(cur_ram, off)}\n")
                        else:
                            f.write(f"  {format_hex_dump(cur_ram, off)}\n")
                    f.write("```\n\n")

                if len(ram_diffs) > 20:
                    f.write(f"*... and {len(ram_diffs) - 20} more difference regions (truncated for brevity)*\n\n")
            else:
                f.write("**No RAM differences**\n\n")

        # VDP VRAM
        f.write("## VDP VRAM (Video RAM)\n\n")
        ref_vram = ref.get_vdp_vram()
        cur_vram = cur.get_vdp_vram()

        if ref_vram and cur_vram:
            vram_diffs = find_memory_differences(ref_vram, cur_vram, "VRAM", 0x0000)

            if vram_diffs:
                f.write(f"**Found {len(vram_diffs)} difference region(s) in VRAM**\n\n")
                f.write("*VRAM differences indicate sprite/tile data or pattern changes.*\n\n")

                for addr_start, addr_end, size in vram_diffs[:10]:  # Limit to first 10
                    f.write(f"### VRAM Difference: 0x{addr_start:04X} - 0x{addr_end:04X} ({size} bytes)\n\n")

                    # Show first few bytes
                    f.write("**Reference:** ")
                    f.write(" ".join(f"{b:02X}" for b in ref_vram[addr_start : min(addr_end, addr_start + 32)]))
                    if addr_end - addr_start > 32:
                        f.write(f" ... (+{addr_end - addr_start - 32} more bytes)")
                    f.write("\n\n")

                    f.write("**Current:** ")
                    f.write(" ".join(f"{b:02X}" for b in cur_vram[addr_start : min(addr_end, addr_start + 32)]))
                    if addr_end - addr_start > 32:
                        f.write(f" ... (+{addr_end - addr_start - 32} more bytes)")
                    f.write("\n\n")

                if len(vram_diffs) > 10:
                    f.write(f"*... and {len(vram_diffs) - 10} more VRAM regions (truncated)*\n\n")
            else:
                f.write("**No VRAM differences**\n\n")

        # VDP Color RAM
        f.write("## VDP CRAM (Color Palette)\n\n")
        ref_cram = ref.get_vdp_cram()
        cur_cram = cur.get_vdp_cram()

        if ref_cram and cur_cram and ref_cram != cur_cram:
            f.write("**Color palette differences found:**\n\n")

            # Parse as 16-bit LE colors
            for i in range(0, min(len(ref_cram), len(cur_cram)), 2):
                ref_color = struct.unpack("<H", ref_cram[i : i + 2])[0]
                cur_color = struct.unpack("<H", cur_cram[i : i + 2])[0]

                if ref_color != cur_color:
                    # Extract RGB components (Genesis format: 0000 BBB0 GGG0 RRR0)
                    ref_r = (ref_color & 0x000E) >> 1
                    ref_g = (ref_color & 0x00E0) >> 5
                    ref_b = (ref_color & 0x0E00) >> 9
                    cur_r = (cur_color & 0x000E) >> 1
                    cur_g = (cur_color & 0x00E0) >> 5
                    cur_b = (cur_color & 0x0E00) >> 9

                    f.write(f"- **Color {i // 2}**: ")
                    f.write(f"0x{ref_color:04X} (R:{ref_r} G:{ref_g} B:{ref_b}) → ")
                    f.write(f"0x{cur_color:04X} (R:{cur_r} G:{cur_g} B:{cur_b})\n")
            f.write("\n")
        else:
            f.write("**No color palette differences**\n\n")

        # VDP Registers
        f.write("## VDP Registers\n\n")
        ref_vdp_regs_data = ref.get_vdp_regs()
        cur_vdp_regs_data = cur.get_vdp_regs()

        if ref_vdp_regs_data and cur_vdp_regs_data:
            ref_vdp_regs = parse_vdp_registers(ref_vdp_regs_data)
            cur_vdp_regs = parse_vdp_registers(cur_vdp_regs_data)

            vdp_reg_diffs = []
            for reg_num in ref_vdp_regs:
                if ref_vdp_regs[reg_num] != cur_vdp_regs[reg_num]:
                    vdp_reg_diffs.append((reg_num, ref_vdp_regs[reg_num], cur_vdp_regs[reg_num]))

            if vdp_reg_diffs:
                f.write("**VDP register differences:**\n\n")
                f.write("| Register | Reference | Current | Description |\n")
                f.write("|----------|-----------|---------|-------------|\n")

                vdp_reg_names = {
                    0: "Mode Set 1",
                    1: "Mode Set 2",
                    2: "Plane A Pattern Table",
                    3: "Window Pattern Table",
                    4: "Plane B Pattern Table",
                    5: "Sprite Attribute Table",
                    7: "Background Color",
                    10: "H-Interrupt Counter",
                    11: "Mode Set 3",
                    12: "Mode Set 4",
                    13: "H-Scroll Table",
                    15: "Auto Increment",
                    16: "Plane Size",
                }

                for reg_num, ref_val, cur_val in vdp_reg_diffs:
                    desc = vdp_reg_names.get(reg_num, "Unknown")
                    f.write(f"| VDP Reg {reg_num} | 0x{ref_val:02X} | 0x{cur_val:02X} | {desc} |\n")
                f.write("\n")
            else:
                f.write("**No VDP register differences**\n\n")

        # VDP VSRAM
        f.write("## VDP VSRAM (Vertical Scroll)\n\n")
        ref_vsram = ref.get_vdp_vsram()
        cur_vsram = cur.get_vdp_vsram()

        if ref_vsram and cur_vsram:
            vsram_diffs = find_memory_differences(ref_vsram, cur_vsram, "VSRAM", 0x0000)

            if vsram_diffs:
                f.write(f"**Found {len(vsram_diffs)} difference region(s) in VSRAM**\n\n")
                f.write("*VSRAM differences indicate vertical scroll position changes.*\n\n")

                for addr_start, addr_end, size in vsram_diffs[:10]:
                    f.write(f"- **Offset 0x{addr_start:04X} - 0x{addr_end:04X}** ({size} bytes): ")
                    f.write(f"Ref: {' '.join(f'{b:02X}' for b in ref_vsram[addr_start:addr_end])} → ")
                    f.write(f"Cur: {' '.join(f'{b:02X}' for b in cur_vsram[addr_start:addr_end])}\n")
                f.write("\n")
            else:
                f.write("**No VSRAM differences**\n\n")

        # Z80 RAM
        f.write("## Z80 RAM (Sound CPU Memory)\n\n")
        ref_z80_ram = ref.get_z80_ram()
        cur_z80_ram = cur.get_z80_ram()

        if ref_z80_ram and cur_z80_ram:
            z80_diffs = find_memory_differences(ref_z80_ram, cur_z80_ram, "Z80_RAM", 0x0000)

            if z80_diffs:
                f.write(f"**Found {len(z80_diffs)} difference region(s) in Z80 RAM**\n\n")
                f.write("*Z80 RAM differences indicate sound driver state changes.*\n\n")

                for addr_start, addr_end, size in z80_diffs[:10]:
                    f.write(f"### Z80 RAM Difference: 0x{addr_start:04X} - 0x{addr_end:04X} ({size} bytes)\n\n")

                    f.write("**Reference:** ")
                    f.write(" ".join(f"{b:02X}" for b in ref_z80_ram[addr_start : min(addr_end, addr_start + 32)]))
                    if addr_end - addr_start > 32:
                        f.write(f" ... (+{addr_end - addr_start - 32} more bytes)")
                    f.write("\n\n")

                    f.write("**Current:** ")
                    f.write(" ".join(f"{b:02X}" for b in cur_z80_ram[addr_start : min(addr_end, addr_start + 32)]))
                    if addr_end - addr_start > 32:
                        f.write(f" ... (+{addr_end - addr_start - 32} more bytes)")
                    f.write("\n\n")

                if len(z80_diffs) > 10:
                    f.write(f"*... and {len(z80_diffs) - 10} more Z80 RAM regions (truncated)*\n\n")
            else:
                f.write("**No Z80 RAM differences**\n\n")

        # YM2612 FM Sound Chip
        f.write("## YM2612 FM Sound Chip\n\n")
        ref_ym2612 = ref.get_ym2612()
        cur_ym2612 = cur.get_ym2612()

        if ref_ym2612 and cur_ym2612:
            ym_diffs = find_memory_differences(ref_ym2612, cur_ym2612, "YM2612", 0x0000)

            if ym_diffs:
                f.write(f"**Found {len(ym_diffs)} difference region(s) in YM2612 state**\n\n")
                f.write("*YM2612 differences indicate FM synthesis sound state changes.*\n")
                f.write("*This affects music and FM sound effects playback.*\n\n")

                for addr_start, addr_end, size in ym_diffs[:10]:
                    f.write(f"- **Offset 0x{addr_start:04X} - 0x{addr_end:04X}** ({size} bytes)\n")

                if len(ym_diffs) > 10:
                    f.write(f"\n*... and {len(ym_diffs) - 10} more YM2612 regions (truncated)*\n")
                f.write("\n")
            else:
                f.write("**No YM2612 differences**\n\n")
        else:
            f.write("*YM2612 section not present in state dumps*\n\n")

        # PSG Sound Generator
        f.write("## PSG Sound Generator\n\n")
        ref_psg = ref.get_psg()
        cur_psg = cur.get_psg()

        if ref_psg and cur_psg:
            psg_diffs = find_memory_differences(ref_psg, cur_psg, "PSG", 0x0000)

            if psg_diffs:
                f.write(f"**Found {len(psg_diffs)} difference region(s) in PSG state**\n\n")
                f.write("*PSG differences indicate square wave / noise sound state changes.*\n\n")

                # Show full PSG state (it's small, ~64 bytes)
                f.write("**Reference PSG state:**\n```\n")
                for off in range(0, len(ref_psg), 16):
                    f.write(format_hex_dump(ref_psg, off) + "\n")
                f.write("```\n\n")

                f.write("**Current PSG state:**\n```\n")
                for off in range(0, len(cur_psg), 16):
                    f.write(format_hex_dump(cur_psg, off) + "\n")
                f.write("```\n\n")
            else:
                f.write("**No PSG differences**\n\n")
        else:
            f.write("*PSG section not present in state dumps*\n\n")

        # SRAM (if present)
        f.write("## SRAM (Battery-Backed Save RAM)\n\n")
        ref_sram = ref.get_sram()
        cur_sram = cur.get_sram()

        if ref_sram and cur_sram:
            sram_diffs = find_memory_differences(ref_sram, cur_sram, "SRAM", 0x0000)

            if sram_diffs:
                f.write(f"**Found {len(sram_diffs)} difference region(s) in SRAM**\n\n")
                f.write("*SRAM differences indicate save data changes.*\n\n")

                for addr_start, addr_end, size in sram_diffs[:10]:
                    f.write(f"### SRAM Difference: 0x{addr_start:04X} - 0x{addr_end:04X} ({size} bytes)\n\n")

                    f.write("**Reference:** ")
                    f.write(" ".join(f"{b:02X}" for b in ref_sram[addr_start : min(addr_end, addr_start + 32)]))
                    if addr_end - addr_start > 32:
                        f.write(f" ... (+{addr_end - addr_start - 32} more bytes)")
                    f.write("\n\n")

                    f.write("**Current:** ")
                    f.write(" ".join(f"{b:02X}" for b in cur_sram[addr_start : min(addr_end, addr_start + 32)]))
                    if addr_end - addr_start > 32:
                        f.write(f" ... (+{addr_end - addr_start - 32} more bytes)")
                    f.write("\n\n")

                if len(sram_diffs) > 10:
                    f.write(f"*... and {len(sram_diffs) - 10} more SRAM regions (truncated)*\n\n")
            else:
                f.write("**No SRAM differences**\n\n")
        else:
            f.write("*SRAM section not present in state dumps (game may not use battery save)*\n\n")

        # Analysis Notes
        f.write("## Analysis Notes\n\n")
        f.write("### For LLM Analysis:\n\n")
        f.write("1. **RAM differences** show where game state (variables, counters, pointers) diverged\n")
        f.write("2. **VRAM differences** indicate sprite/tile graphics or pattern table changes\n")
        f.write("3. **Color palette changes** suggest visual rendering differences\n")
        f.write("4. **Register differences** show CPU or VDP state divergence\n")
        f.write("5. **Z80 RAM differences** indicate sound driver state changes\n")
        f.write("6. **YM2612 differences** show FM synthesis sound state divergence (music/SFX)\n")
        f.write("7. **PSG differences** show square wave / noise sound state changes\n")
        f.write("8. **SRAM differences** indicate save game data changes\n\n")
        f.write("### Debugging Strategy:\n\n")
        f.write("- Focus on RAM addresses around 0xFF0000-0xFFFFFF for game variables\n")
        f.write("- Check if changed addresses correspond to known data structures\n")
        f.write("- VRAM changes near sprite tables may indicate missing graphics\n")
        f.write("- PC (Program Counter) difference indicates execution path divergence\n")
        f.write("- Sound differences (YM2612/PSG/Z80) may indicate music or SFX bugs\n")
        f.write("- Sound changes without visual changes suggest audio-only issues\n\n")
        f.write("---\n\n")
        f.write("*Report generated by compare_states.py*\n")

    print(f"Report saved: {report_file}")
    return report_file


def find_and_compare_states(diffs_dir: str, reference_dir: str, output_dir: str) -> int:
    """
    Find all .genstate files in diffs_dir and compare with corresponding reference files.

    Returns number of reports generated.
    """
    import glob

    # Find all .genstate files in diffs directory (not ending with _diff)
    pattern = os.path.join(diffs_dir, "*.genstate")
    diff_files = sorted(glob.glob(pattern))

    if not diff_files:
        print(f"No .genstate files found in {diffs_dir}")
        return 0

    print(f"Found {len(diff_files)} state file(s) in {diffs_dir}")

    os.makedirs(output_dir, exist_ok=True)
    reports_generated = 0

    for cur_file in diff_files:
        # Get filename and construct reference path
        filename = os.path.basename(cur_file)
        ref_file = os.path.join(reference_dir, filename)

        if not os.path.exists(ref_file):
            print(f"  Skipping {filename}: no reference file found")
            continue

        try:
            print(f"\nComparing: {filename}")
            generate_llm_report(ref_file, cur_file, output_dir)
            reports_generated += 1
        except Exception as e:
            print(f"  Error comparing {filename}: {e}")

    return reports_generated


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Compare Genesis state dumps and generate LLM-friendly reports")

    # Mode 1: Compare two specific files
    parser.add_argument("reference", nargs="?", help="Reference state file")
    parser.add_argument("current", nargs="?", help="Current state file")

    # Mode 2: Compare all files in directories
    parser.add_argument("--diffs-dir", help="Directory with current state files")
    parser.add_argument("--reference-dir", help="Directory with reference state files")

    # Common options
    parser.add_argument("--output-dir", "-o", default="reports", help="Output directory for reports (default: reports)")

    args = parser.parse_args()

    # Mode 2: Directory comparison
    if args.diffs_dir and args.reference_dir:
        if not os.path.isdir(args.diffs_dir):
            print(f"Error: Diffs directory not found: {args.diffs_dir}")
            return 1
        if not os.path.isdir(args.reference_dir):
            print(f"Error: Reference directory not found: {args.reference_dir}")
            return 1

        print("=" * 70)
        print("STATE COMPARISON (Directory Mode)")
        print("=" * 70)
        print(f"Diffs dir:     {args.diffs_dir}")
        print(f"Reference dir: {args.reference_dir}")
        print(f"Output dir:    {args.output_dir}")
        print("=" * 70)

        count = find_and_compare_states(args.diffs_dir, args.reference_dir, args.output_dir)

        print()
        print("=" * 70)
        if count > 0:
            print(f"SUCCESS: Generated {count} report(s)")
        else:
            print("No reports generated")
        print("=" * 70)
        return 0 if count > 0 else 1

    # Mode 1: Single file comparison
    if args.reference and args.current:
        if not os.path.exists(args.reference):
            print(f"Error: Reference file not found: {args.reference}")
            return 1
        if not os.path.exists(args.current):
            print(f"Error: Current file not found: {args.current}")
            return 1

        try:
            report_file = generate_llm_report(args.reference, args.current, args.output_dir)
            print()
            print("=" * 70)
            print("SUCCESS: Comparison report generated")
            print("=" * 70)
            print(f"Report: {report_file}")
            return 0
        except Exception as e:
            print(f"Error: {e}")
            import traceback

            traceback.print_exc()
            return 1

    # No valid arguments
    parser.print_help()
    print()
    print("Examples:")
    print("  # Compare two files:")
    print("  python compare_states.py reference/000020.genstate diffs/000020.genstate")
    print()
    print("  # Compare all files in directories:")
    print("  python compare_states.py --diffs-dir diffs/tas --reference-dir reference/tas")
    return 1


if __name__ == "__main__":
    sys.exit(main())

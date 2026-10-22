#!/usr/bin/env python3
"""Small reader for Gens automation .genstate files."""

from __future__ import annotations

import struct
from dataclasses import dataclass
from pathlib import Path


M68K_RAM = 0x01


@dataclass(frozen=True)
class Genstate:
    frame: int
    rom_checksum: int
    sections: dict[int, bytes]

    @classmethod
    def read(cls, path: Path) -> "Genstate":
        data = path.read_bytes()
        if len(data) < 80 or data[:8] != b"GENSTATE":
            raise ValueError(f"invalid genstate file: {path}")
        _, frame, _, checksum = struct.unpack_from("<IIQI", data, 8)
        sections: dict[int, bytes] = {}
        table = 64
        while table + 16 <= len(data):
            section_id, offset, size, _ = struct.unpack_from("<IIII", data, table)
            table += 16
            if section_id == 0 and offset == 0:
                break
            if offset + size > len(data):
                raise ValueError(f"section {section_id:#x} exceeds {path}")
            sections[section_id] = data[offset : offset + size]
        return cls(frame=frame, rom_checksum=checksum, sections=sections)

    def m68k_u8(self, address: int) -> int:
        ram = self.sections[M68K_RAM]
        offset = address & 0xFFFF
        return ram[offset ^ 1]

    def m68k_u16(self, address: int) -> int:
        return (self.m68k_u8(address) << 8) | self.m68k_u8(address + 1)

    def m68k_u32(self, address: int) -> int:
        return (self.m68k_u16(address) << 16) | self.m68k_u16(address + 2)

#!/usr/bin/env python3
"""
Binary Trace Parser for Gens-automation Emulator

Parses compact binary trace files (.btrc) and generates:
- Human-readable story logs
- Graphviz DOT files for visualization (pointer graphs, DMA maps)

Usage:
    python bintrace_parser.py <trace.btrc> --story story.txt
    python bintrace_parser.py <trace.btrc> --graphviz output.dot --mode pointers
    python bintrace_parser.py <trace.btrc> --graphviz output.dot --mode dma
    python bintrace_parser.py <trace.btrc> --symbols symbols.lst
"""

import struct
import argparse
import os
from dataclasses import dataclass
from typing import List, Dict, Optional, BinaryIO, Tuple

# Event types (must match bintrace.h)
EVT_FRAME = 0x00
EVT_EXEC = 0x01
EVT_READ = 0x02
EVT_WRITE = 0x03
EVT_READ_BLOCK = 0x04
EVT_WRITE_BLOCK = 0x05
EVT_VRAM_WRITE = 0x10
EVT_VRAM_READ = 0x11
EVT_CRAM_WRITE = 0x12
EVT_CRAM_READ = 0x13
EVT_VSRAM_WRITE = 0x14
EVT_VSRAM_READ = 0x15
EVT_DMA = 0x20
EVT_POINTER_LOAD = 0x30

# Flags
FLAG_ROM_ACCESS = 0x01
FLAG_RAM_ACCESS = 0x02
FLAG_POINTER = 0x04

EVENT_NAMES = {
    EVT_FRAME: "FRAME",
    EVT_EXEC: "EXEC",
    EVT_READ: "READ",
    EVT_WRITE: "WRITE",
    EVT_READ_BLOCK: "READ_BLOCK",
    EVT_WRITE_BLOCK: "WRITE_BLOCK",
    EVT_VRAM_WRITE: "VRAM_W",
    EVT_VRAM_READ: "VRAM_R",
    EVT_CRAM_WRITE: "CRAM_W",
    EVT_CRAM_READ: "CRAM_R",
    EVT_VSRAM_WRITE: "VSRAM_W",
    EVT_VSRAM_READ: "VSRAM_R",
    EVT_DMA: "DMA",
    EVT_POINTER_LOAD: "PTR_LOAD",
}


@dataclass
class TraceHeader:
    magic: str
    version: int
    flags: int
    start_frame: int
    end_frame: int
    event_count: int


@dataclass
class Event:
    type: int
    flags: int
    frame_delta: int


@dataclass
class FrameEvent(Event):
    frame: int


@dataclass
class MemEvent(Event):
    pc: int
    addr: int
    size: int
    value: int


@dataclass
class BlockEvent(Event):
    pc: int
    addr: int
    data: bytes


@dataclass
class VDPEvent(Event):
    pc: int
    addr: int
    size: int
    value: int


@dataclass
class DMAEvent(Event):
    pc: int
    src: int
    dst: int
    length: int
    dst_type: int


@dataclass
class PointerEvent(Event):
    pc: int
    table_addr: int
    target_addr: int


class SymbolMap:
    """Load and lookup symbols from .lst or .sym files"""

    def __init__(self):
        self.symbols: Dict[int, str] = {}
        self.reverse: Dict[str, int] = {}
        # Sorted list of ROM addresses for nearest-symbol lookup
        self._rom_addrs: List[int] = []
        self._rom_addrs_dirty = True

    def _rebuild_rom_addrs(self):
        """Rebuild sorted ROM address list for binary search"""
        if self._rom_addrs_dirty:
            # Only include ROM addresses (0x000000 - 0x3FFFFF)
            self._rom_addrs = sorted(addr for addr in self.symbols.keys() if 0 <= addr < 0x400000)
            self._rom_addrs_dirty = False

    def load_lst(self, path: str):
        """Load symbols from IDA/Ghidra .lst file"""
        with open(path, "r", errors="ignore") as f:
            for line in f:
                # Try various listing formats
                # Format: "00:1234 label:"
                if ":" in line:
                    parts = line.split()
                    if len(parts) >= 2:
                        addr_part = parts[0]
                        if ":" in addr_part:
                            try:
                                seg, off = addr_part.split(":")
                                addr = (int(seg, 16) << 16) | int(off, 16)
                                label = parts[1].rstrip(":")
                                if label and not label.startswith(";"):
                                    self.symbols[addr] = label
                                    self.reverse[label] = addr
                            except ValueError:
                                pass
        self._rom_addrs_dirty = True

    def load_sym(self, path: str):
        """Load symbols from simple sym file (addr label format)"""
        with open(path, "r", errors="ignore") as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith(";") or line.startswith("#"):
                    continue
                parts = line.split()
                if len(parts) >= 2:
                    try:
                        addr = int(parts[0], 16)
                        label = parts[1]
                        self.symbols[addr] = label
                        self.reverse[label] = addr
                    except ValueError:
                        pass
        self._rom_addrs_dirty = True

    def lookup(self, addr: int) -> Optional[str]:
        """Exact lookup"""
        return self.symbols.get(addr)

    def find_nearest(self, addr: int, max_offset: int = 0x1000) -> Optional[Tuple[int, str]]:
        """Find nearest symbol at or before addr (for ROM addresses only)"""
        if addr < 0 or addr >= 0x400000:
            return None

        self._rebuild_rom_addrs()

        if not self._rom_addrs:
            return None

        # Binary search for the largest address <= addr
        import bisect

        idx = bisect.bisect_right(self._rom_addrs, addr) - 1
        if idx < 0:
            return None

        sym_addr = self._rom_addrs[idx]
        if addr - sym_addr <= max_offset:
            return (sym_addr, self.symbols[sym_addr])
        return None

    def format_addr(self, addr: int) -> str:
        """Format address with symbol if available"""
        sym = self.symbols.get(addr)
        if sym:
            return f"{sym}"
        return f"${addr:06X}"

    def format_pc(self, addr: int) -> str:
        """Format PC address with function+offset if available"""
        # Exact match
        sym = self.symbols.get(addr)
        if sym:
            return sym

        # Find nearest for ROM addresses
        nearest = self.find_nearest(addr)
        if nearest:
            sym_addr, sym_name = nearest
            offset = addr - sym_addr
            if offset == 0:
                return sym_name
            return f"{sym_name}+${offset:X}"

        return f"${addr:06X}"

    def format_data_addr(self, addr: int) -> str:
        """Format data address - exact match only, skip small constants"""
        # Skip addresses that are likely flag constants (0-0x100)
        if addr < 0x100:
            return f"${addr:06X}"

        sym = self.symbols.get(addr)
        if sym:
            return sym
        return f"${addr:06X}"


class BinTraceParser:
    """Parser for binary trace files"""

    def __init__(self, symbols: Optional[SymbolMap] = None):
        self.symbols = symbols or SymbolMap()
        self.header: Optional[TraceHeader] = None
        self.events: List[Event] = []
        self.current_frame = 0

    def parse(self, path: str):
        """Parse a binary trace file"""
        with open(path, "rb") as f:
            self._parse_header(f)
            self._parse_events(f)

    def _parse_header(self, f: BinaryIO):
        """Parse the 32-byte file header"""
        data = f.read(32)
        if len(data) < 32:
            raise ValueError("File too small for header")

        magic = data[0:4].decode("ascii")
        if magic != "BTRC":
            raise ValueError(f"Invalid magic: {magic}")

        version, flags, start_frame, end_frame, event_count = struct.unpack_from("<HHIII", data, 4)

        self.header = TraceHeader(
            magic=magic,
            version=version,
            flags=flags,
            start_frame=start_frame,
            end_frame=end_frame,
            event_count=event_count,
        )

    def _parse_events(self, f: BinaryIO):
        """Parse all events from file"""
        while True:
            # Read event header (4 bytes)
            header_data = f.read(4)
            if len(header_data) < 4:
                break

            evt_type, flags, frame_delta = struct.unpack("<BBH", header_data)

            event = self._parse_event(f, evt_type, flags, frame_delta)
            if event:
                self.events.append(event)

    def _parse_event(self, f: BinaryIO, evt_type: int, flags: int, frame_delta: int) -> Optional[Event]:
        """Parse a single event based on its type"""

        if evt_type == EVT_FRAME:
            data = f.read(4)
            (frame,) = struct.unpack("<I", data)
            self.current_frame = frame
            return FrameEvent(evt_type, flags, frame_delta, frame)

        elif evt_type in (EVT_READ, EVT_WRITE):
            # 12 bytes: pc(4) + addr:size(4) + value(4)
            data = f.read(12)
            pc, addr_size, value = struct.unpack("<III", data)
            addr = addr_size & 0xFFFFFF
            size = (addr_size >> 24) & 0xFF
            return MemEvent(evt_type, flags, frame_delta, pc, addr, size, value)

        elif evt_type in (EVT_READ_BLOCK, EVT_WRITE_BLOCK):
            # 12 bytes header + variable data
            data = f.read(12)
            pc, addr, data_len_reserved = struct.unpack("<III", data)
            data_len = data_len_reserved & 0xFFFF
            # Read data + padding
            block_data = f.read(data_len)
            pad = (4 - (data_len & 3)) & 3
            if pad > 0:
                f.read(pad)
            return BlockEvent(evt_type, flags, frame_delta, pc, addr, block_data)

        elif evt_type in (
            EVT_VRAM_WRITE,
            EVT_VRAM_READ,
            EVT_CRAM_WRITE,
            EVT_CRAM_READ,
            EVT_VSRAM_WRITE,
            EVT_VSRAM_READ,
        ):
            # 12 bytes: pc(4) + addr(2) + size(1) + reserved(1) + value(4)
            data = f.read(12)
            pc, addr, size, _, value = struct.unpack("<IHBBI", data)
            return VDPEvent(evt_type, flags, frame_delta, pc, addr, size, value)

        elif evt_type == EVT_DMA:
            # 12 bytes: pc(4) + src(4) + dst(2) + len(2)
            # Plus 4 more bytes: type(1) + pad(3)
            data = f.read(16)
            pc, src, dst, length = struct.unpack("<IIHH", data[:12])
            dst_type = data[12]
            return DMAEvent(evt_type, flags, frame_delta, pc, src, dst, length, dst_type)

        elif evt_type == EVT_POINTER_LOAD:
            # 12 bytes: pc(4) + table_addr(4) + target_addr(4)
            data = f.read(12)
            pc, table_addr, target_addr = struct.unpack("<III", data)
            return PointerEvent(evt_type, flags, frame_delta, pc, table_addr, target_addr)

        else:
            # Unknown event, skip
            return None

    def generate_story(self, output_path: str):
        """Generate human-readable story log"""
        with open(output_path, "w") as f:
            f.write(f"# Binary Trace Story Log\n")
            f.write(f"# Frames: {self.header.start_frame} - {self.header.end_frame}\n")
            f.write(f"# Events: {self.header.event_count}\n\n")

            current_frame = 0

            for event in self.events:
                if isinstance(event, FrameEvent):
                    current_frame = event.frame
                    f.write(f"\n=== FRAME {current_frame} ===\n")

                elif isinstance(event, MemEvent):
                    evt_name = "Read" if event.type == EVT_READ else "Write"
                    addr_str = self.symbols.format_data_addr(event.addr)
                    pc_str = self.symbols.format_pc(event.pc)
                    ptr_flag = " [POINTER?]" if event.flags & FLAG_POINTER else ""
                    f.write(
                        f"  [{pc_str}] {evt_name} {event.size}B: {addr_str} = ${event.value:0{event.size * 2}X}{ptr_flag}\n"
                    )

                elif isinstance(event, BlockEvent):
                    evt_name = "Read block" if event.type == EVT_READ_BLOCK else "Write block"
                    addr_str = self.symbols.format_data_addr(event.addr)
                    pc_str = self.symbols.format_pc(event.pc)
                    f.write(f"  [{pc_str}] {evt_name}: {len(event.data)} bytes from {addr_str}\n")
                    # Show first few bytes
                    preview = event.data[:16].hex(" ").upper()
                    if len(event.data) > 16:
                        preview += " ..."
                    f.write(f"    Data: {preview}\n")

                elif isinstance(event, VDPEvent):
                    vdp_type = EVENT_NAMES.get(event.type, "VDP")
                    pc_str = self.symbols.format_pc(event.pc)
                    f.write(f"  [{pc_str}] {vdp_type}: ${event.addr:04X} = ${event.value:0{event.size * 2}X}\n")

                elif isinstance(event, DMAEvent):
                    src_str = self.symbols.format_data_addr(event.src)
                    dst_type_name = ["VRAM", "CRAM", "VSRAM"][event.dst_type] if event.dst_type < 3 else "?"
                    pc_str = self.symbols.format_pc(event.pc)
                    f.write(f"  [{pc_str}] DMA: {src_str} -> {dst_type_name} ${event.dst:04X}, {event.length} bytes\n")

                elif isinstance(event, PointerEvent):
                    table_str = self.symbols.format_data_addr(event.table_addr)
                    target_str = self.symbols.format_data_addr(event.target_addr)
                    pc_str = self.symbols.format_pc(event.pc)
                    f.write(f"  [{pc_str}] POINTER LOAD: table={table_str}, target={target_str}\n")

        print(f"Story log written to: {output_path}")

    def generate_graphviz_pointers(self, output_path: str):
        """Generate Graphviz DOT file showing pointer relationships"""
        # Collect pointer relationships
        pointers: Dict[int, set] = {}  # table_addr -> set of targets

        for event in self.events:
            # Detect potential pointers from 32-bit reads with FLAG_POINTER
            if isinstance(event, MemEvent) and event.type == EVT_READ:
                if event.flags & FLAG_POINTER and event.size == 4:
                    table = event.addr
                    target = event.value
                    # Filter out NULL and small values (not real pointers)
                    if target < 0x200:
                        continue
                    # Filter out values that don't look like M68K addresses
                    if not (0x200 <= target < 0x400000 or 0xFF0000 <= target <= 0xFFFFFF):
                        continue
                    if table not in pointers:
                        pointers[table] = set()
                    pointers[table].add(target)

            elif isinstance(event, PointerEvent):
                target = event.target_addr
                if target < 0x200:
                    continue
                if event.table_addr not in pointers:
                    pointers[event.table_addr] = set()
                pointers[event.table_addr].add(target)

        with open(output_path, "w") as f:
            f.write("digraph pointers {\n")
            f.write("  rankdir=LR;\n")
            f.write("  node [shape=box];\n\n")

            # Emit nodes and edges
            node_ids = {}
            for table, targets in pointers.items():
                # Try exact match first, then nearest
                table_label = self.symbols.lookup(table)
                if not table_label:
                    nearest = self.symbols.find_nearest(table, max_offset=0x100)
                    if nearest:
                        sym_addr, sym_name = nearest
                        offset = table - sym_addr
                        table_label = f"{sym_name}+${offset:X}" if offset else sym_name
                    else:
                        table_label = f"${table:06X}"

                table_id = f"tbl_{table:06X}"
                node_ids[table] = table_id

                # ROM tables are filled
                style = "style=filled fillcolor=lightblue" if table < 0x400000 else ""
                f.write(f'  {table_id} [label="{table_label}\\n${table:06X}" {style}];\n')

                for target in targets:
                    target_label = self.symbols.lookup(target)
                    if not target_label:
                        nearest = self.symbols.find_nearest(target, max_offset=0x100)
                        if nearest:
                            sym_addr, sym_name = nearest
                            offset = target - sym_addr
                            target_label = f"{sym_name}+${offset:X}" if offset else sym_name
                        else:
                            target_label = f"${target:06X}"

                    target_id = f"dat_{target:06X}"

                    if target not in node_ids:
                        node_ids[target] = target_id
                        f.write(f'  {target_id} [label="{target_label}\\n${target:06X}"];\n')

                    f.write(f"  {table_id} -> {node_ids[target]};\n")

            f.write("}\n")

        print(f"Graphviz DOT (pointers) written to: {output_path}")

    def generate_graphviz_dma(self, output_path: str):
        """Generate Graphviz DOT file showing DMA data flow"""
        dma_flows: Dict[Tuple[int, int, int], int] = {}  # (src, dst, type) -> total bytes

        for event in self.events:
            if isinstance(event, DMAEvent):
                key = (event.src, event.dst, event.dst_type)
                dma_flows[key] = dma_flows.get(key, 0) + event.length

        with open(output_path, "w") as f:
            f.write("digraph dma {\n")
            f.write("  rankdir=LR;\n")
            f.write("  node [shape=box];\n\n")

            # Create subgraphs for different memory regions
            f.write("  subgraph cluster_rom {\n")
            f.write('    label="ROM";\n')
            f.write("    style=filled;\n")
            f.write("    fillcolor=lightyellow;\n")

            rom_nodes = set()
            vdp_nodes = set()

            for (src, dst, dst_type), total in dma_flows.items():
                if src < 0x400000:
                    rom_nodes.add(src)

                vdp_nodes.add((dst, dst_type))

            for src in rom_nodes:
                label = self.symbols.lookup(src)
                if not label:
                    nearest = self.symbols.find_nearest(src, max_offset=0x100)
                    if nearest:
                        sym_addr, sym_name = nearest
                        offset = src - sym_addr
                        label = f"{sym_name}+${offset:X}" if offset else sym_name
                    else:
                        label = f"${src:06X}"
                f.write(f'    rom_{src:06X} [label="{label}\\n${src:06X}"];\n')

            f.write("  }\n\n")

            # VDP destinations
            f.write("  subgraph cluster_vdp {\n")
            f.write('    label="VDP";\n')
            f.write("    style=filled;\n")
            f.write("    fillcolor=lightgreen;\n")

            for dst, dst_type in vdp_nodes:
                dst_name = ["VRAM", "CRAM", "VSRAM"][dst_type] if dst_type < 3 else "?"
                f.write(f'    vdp_{dst:04X}_{dst_type} [label="{dst_name}\\n${dst:04X}"];\n')

            f.write("  }\n\n")

            # Edges with byte counts
            for (src, dst, dst_type), total in dma_flows.items():
                src_id = f"rom_{src:06X}" if src < 0x400000 else f"ram_{src:06X}"
                dst_id = f"vdp_{dst:04X}_{dst_type}"
                f.write(f'  {src_id} -> {dst_id} [label="{total} bytes"];\n')

            f.write("}\n")

        print(f"Graphviz DOT (DMA) written to: {output_path}")

    def generate_graphviz_callers(self, output_path: str, max_edges: int = 30):
        """Generate Graphviz DOT file showing which functions trigger DMA transfers"""
        # Collect: (function, region) -> total_bytes (only DMA events)
        edges: Dict[Tuple[str, str], int] = {}

        for event in self.events:
            if isinstance(event, DMAEvent):
                func_name = self.symbols.format_pc(event.pc)
                if "+" in func_name:
                    func_name = func_name.split("+")[0]

                # Get source label
                src_label = self.symbols.lookup(event.src)
                if not src_label:
                    nearest = self.symbols.find_nearest(event.src, max_offset=0x2000)
                    if nearest:
                        src_label = nearest[1]
                    else:
                        src_label = f"ROM_${event.src & 0xFFF000:06X}"

                key = (func_name, src_label)
                edges[key] = edges.get(key, 0) + event.length

        # Sort by byte count and take top N
        sorted_edges = sorted(edges.items(), key=lambda x: -x[1])[:max_edges]

        # Collect unique funcs and regions
        funcs = set()
        regions = set()
        for (func, region), _ in sorted_edges:
            funcs.add(func)
            regions.add(region)

        with open(output_path, "w") as f:
            f.write("digraph callers {\n")
            f.write("  rankdir=LR;\n")
            f.write("  node [shape=box];\n\n")

            # Functions cluster
            f.write("  subgraph cluster_funcs {\n")
            f.write('    label="Functions (DMA callers)";\n')
            f.write("    style=filled;\n")
            f.write("    fillcolor=lightyellow;\n")

            func_ids = {}
            for func in sorted(funcs):
                func_id = f"func_{hash(func) & 0xFFFFFF:06X}"
                func_ids[func] = func_id
                f.write(f'    {func_id} [label="{func}"];\n')

            f.write("  }\n\n")

            # Data regions cluster
            f.write("  subgraph cluster_data {\n")
            f.write('    label="Data Sources";\n')
            f.write("    style=filled;\n")
            f.write("    fillcolor=lightblue;\n")

            region_ids = {}
            for region in sorted(regions):
                region_id = f"data_{hash(region) & 0xFFFFFF:06X}"
                region_ids[region] = region_id
                f.write(f'    {region_id} [label="{region}"];\n')

            f.write("  }\n\n")

            # Edges with byte counts
            for (func, region), byte_count in sorted_edges:
                if byte_count >= 1024:
                    label = f"{byte_count // 1024}KB"
                else:
                    label = f"{byte_count}B"
                f.write(f'  {func_ids[func]} -> {region_ids[region]} [label="{label}"];\n')

            f.write("}\n")

        print(f"Graphviz DOT (callers) written to: {output_path} ({len(sorted_edges)} edges)")

    def print_stats(self):
        """Print trace statistics"""
        if not self.header:
            print("No trace loaded")
            return

        print(f"Trace Statistics:")
        print(f"  Version: {self.header.version}")
        print(f"  Frames: {self.header.start_frame} - {self.header.end_frame}")
        print(f"  Event count: {self.header.event_count}")
        print(f"  Parsed events: {len(self.events)}")

        # Count by type
        type_counts: Dict[int, int] = {}
        for event in self.events:
            type_counts[event.type] = type_counts.get(event.type, 0) + 1

        print(f"\nEvents by type:")
        for evt_type, count in sorted(type_counts.items()):
            name = EVENT_NAMES.get(evt_type, f"0x{evt_type:02X}")
            print(f"  {name}: {count}")


def main():
    parser = argparse.ArgumentParser(
        description="Parse Gens-automation binary trace files",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s trace.btrc --stats
  %(prog)s trace.btrc --story story.txt
  %(prog)s trace.btrc --graphviz pointers.dot --mode pointers
  %(prog)s trace.btrc --graphviz dma.dot --mode dma
  %(prog)s trace.btrc --symbols game.lst --story story.txt
        """,
    )
    parser.add_argument("trace", help="Binary trace file (.btrc)")
    parser.add_argument("--story", metavar="FILE", help="Generate human-readable story log")
    parser.add_argument("--graphviz", metavar="FILE", help="Generate Graphviz DOT file")
    parser.add_argument(
        "--mode",
        choices=["pointers", "dma", "callers"],
        default="pointers",
        help="Graphviz output mode (default: pointers)",
    )
    parser.add_argument("--symbols", metavar="FILE", help="Load symbols from .lst or .sym file")
    parser.add_argument("--stats", action="store_true", help="Print trace statistics")

    args = parser.parse_args()

    # Load symbols if provided
    symbols = SymbolMap()
    if args.symbols:
        if args.symbols.endswith(".lst"):
            symbols.load_lst(args.symbols)
        else:
            symbols.load_sym(args.symbols)
        print(f"Loaded {len(symbols.symbols)} symbols from {args.symbols}")

    # Parse trace
    trace = BinTraceParser(symbols)
    print(f"Parsing: {args.trace}")
    trace.parse(args.trace)

    # Output
    if args.stats or (not args.story and not args.graphviz):
        trace.print_stats()

    if args.story:
        trace.generate_story(args.story)

    if args.graphviz:
        if args.mode == "pointers":
            trace.generate_graphviz_pointers(args.graphviz)
        elif args.mode == "dma":
            trace.generate_graphviz_dma(args.graphviz)
        elif args.mode == "callers":
            trace.generate_graphviz_callers(args.graphviz)


if __name__ == "__main__":
    main()

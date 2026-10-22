# Vendored toolchain

This directory contains the AS Macro Assembler and its `p2bin` companion. They
are vendored so the canonical Alien Soldier build does not depend on an
uncontrolled system installation.

These are general-purpose build tools and contain no Alien Soldier code, data or
graphics. AS Macro Assembler 1.42 Beta [Bld 212] is by Alfred Arnold and is
distributed under its own licence. The upstream project is
<http://john.ccac.rwth-aachen.de:8000/as/>. `p2bin` is the Sonic-disassembly
variant supporting the `-p=` padding option.

The exact sizes and SHA-256 hashes of all Windows and Linux files are recorded
in `config/toolchain.json` and checked by `make verify-toolchain` before an
assembler is allowed to produce release evidence. The Windows files are
byte-identical to those used by the sibling Flicky reconstruction; the Linux
binaries came from the s1disasm toolchain import recorded in Git history.

For cartridge images, `p2bin` must receive `-p=FF`: the cartridge fills its four
unused ROM ranges with `$FF`, while the tool's default is `$00`. The separately
assembled Z80 loader image uses `-p=00` for its own zero-filled gap; it does not
change the cartridge padding policy.

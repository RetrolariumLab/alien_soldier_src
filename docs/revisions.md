# Revisions

There are two revisions, built from one source. The default is Japanese, as in
Source Reconstruction 1.0; pass `REVISION=eu` to select the European cartridge.

| Revision | Reference image             | SHA-1                                      | Output                       |
| -------- | --------------------------- | ------------------------------------------ | ---------------------------- |
| `jp`     | `Alien Soldier (J) [!].bin` | `8f6eb584ed9487b8504fbc21d86783f58e6c9cd6` | `build/alien_soldier_jp.bin` |
| `eu`     | `Alien Soldier (E) [!].bin` | `fa141778bd6540775194d77318f27d2a934e1ac1` | `build/alien_soldier_eu.bin` |

`config/game_profile.json` records each revision's hashes, its assembler defines
(`BuildProfileEU=1` for the European one; the Japanese one keeps the original
no-define default), the range its boot code checksums and the MAME machine it
runs on (`megadrij`, `megadriv`); `assets/manifest.json` cuts both images' data.
`make verify-revisions` requires byte identity for both. The ROM images remain
user-supplied and are never repository assets.

## Commands

```text
make split
make build REVISION=jp
make build REVISION=eu
make verify REVISION=jp
make verify REVISION=eu
make verify-revisions
```

## What differs

The European image preserves its own header product code, checksum, territory
field, complete two-megabyte checksum loop, region-warning layout, PAL sound
cadence, story timings and renderer, title layout, credits timings, and Stage 15
Sunset Sting transition. Only two of the 589 extracted JP payloads have
different bytes: the primary and accent story rows. The other 587 payloads are
shared exactly.

The region split also exposed two address literals that were accidentally valid
in the JP layout. The ship-message table now contains longword symbols, matching
its `move.l` reader, and the Terobuster gravity-shot animation loop stores a
relocatable bank-relative word. This is why both revisions are useful source
evidence rather than merely two build variants.

The byte range `$05D2F2-$1FFFFF` is identical between the cartridge images. The
fixed sound and graphics banks retain their original `org` boundaries; the
EU-specific growth before `$082324` is absorbed by the first preservation gap.

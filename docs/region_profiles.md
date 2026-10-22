# Preservation region profiles

There are two independent preservation profiles. The default is Japanese, as in
Source Reconstruction 1.0; pass `PROFILE=eu` to select the European cartridge.

| Profile | Reference image             | SHA-1                                      | Output           |
| ------- | --------------------------- | ------------------------------------------ | ---------------- |
| `jp`    | `Alien Soldier (J) [!].bin` | `8f6eb584ed9487b8504fbc21d86783f58e6c9cd6` | `asbuilt.bin`    |
| `eu`    | `Alien Soldier (E) [!].bin` | `fa141778bd6540775194d77318f27d2a934e1ac1` | `asbuilt_eu.bin` |

`config/rom_profiles.json` is the machine-readable authority for inputs,
outputs, manifests, address lists, layouts, hashes, and support status. Both
profiles are supported and `make verify-all` requires byte identity for both.
The ROM images remain user-supplied and are never repository assets.

## Commands

```text
make split PROFILE=jp
make split PROFILE=eu
make build PROFILE=jp
make build PROFILE=eu
make verify PROFILE=jp
make verify PROFILE=eu
make verify-all
```

`make derive-eu-assets` reconstructs the EU manifest and its two private story
payloads from the two declared cartridge inputs. `make derive-eu-layout`
reconstructs `config/rom_layout_eu.json` from the EU assembler listing. These
are maintenance commands; the checked-in manifests and layouts are what normal
verification consumes.

## Caller assembler flags

`AS_ARGS` contains caller-owned base flags only. `PROFILE` owns the mandatory
preservation define: Make appends `BuildProfileEU=1` for EU through protected
internal variables, and retains the original no-define JP default. A custom
`AS_ARGS=-q` or `AS_ARGS='-q -maxerrors 2'` cannot discard regional selection.
Caller `-D` definitions of `BuildProfileJP/EU` are rejected before ordinary
preservation assembly/extraction and Make content-build dispatch; unrelated
defines are allowed. This is a bounded reserved symbol policy, not a complete
assembler-option validator or variant pipeline.

The Python CLI argument uses assignment form (`--as-args=...`) at both Make and
the inner init forwarding boundary, so a sole dash-prefixed flag is a value
instead of another parser option. The content builder receives only base flags
and adds its own `CONTENT_PROFILE` manifest define, independently of `PROFILE`.
Neither caller flags nor Make's regional internals can duplicate a define by
accident. Direct content CLI callers retain their existing validation contract.

`make check-profile-flags` checks this with Make dry runs and stubs, without
assembling or opening a cartridge. The listing preflight is order-only and does
not force an unchanged listing to be reassembled.

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
relocatable bank-relative word. This is why both profiles are useful source
evidence rather than merely two build variants.

The byte range `$05D2F2-$1FFFFF` is identical between the cartridge images. The
fixed sound and graphics banks retain their original `org` boundaries; the
EU-specific growth before `$082324` is absorbed by the first preservation gap.
Each profile has a listing-derived layout contract that checks all 398 modules,
eight landmarks, padding, and 289 DMA payload boundaries.

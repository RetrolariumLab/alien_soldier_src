# Sound formats and reference safety

Sound sequence editing is fixed-capacity and source-relative. Its headless
validator now checks effective PSG period references in addition to envelope
selectors, DAC descriptor IDs, instruction identity, and source-owned control
flow. This is an authoring-safety check, not a promise of hardware audio fidelity
or a claim that a song reaches every statically analysed event in gameplay.

The implementation is
[`sound_period_references.py`](../scripts/authoring/sound_period_references.py),
called before staged writes by
[`sound_sequence_model.py`](../scripts/authoring/sound_sequence_model.py).
Run it over either complete original corpus with:

```text
python scripts/authoring/sound_sequence_model.py check --profile jp
python scripts/authoring/sound_sequence_model.py check --profile eu
```

## Cartridge evidence

[`Sound_DecodePSGSequenceNote`](../src/sound/psg_playback_and_envelopes.s)
subtracts `$81`, returns through the rest path on carry (`$80`), adds channel
byte `8(a5)` with byte arithmetic, masks the result to `$7F`, doubles it, and
reads a word from `Sound_PSGNotePeriodTable`. The actual table contains **70
words**, including its final zero: valid indices are `0..69`, not `0..127`.
The seven-bit mask describes the reader's possible index, not the table size.
Type `$E0` does not bypass this lookup; the later PSG frequency writer treats
that type as a noise-channel mode. Muting/override output tests also occur
after the note-period lookup, so silence is not evidence of reference safety.

Header initial words are copied directly into channel word `8(a5)`: the
big-endian high byte is the initial transpose. `$FB` adds its operand to this
byte, wrapping modulo 256. `$F3` unconditionally sets current channel type to
`$E0`; `$E5` and `$F1` select operands according to type and do not change it.

Physical parser ownership matters. BGM has a dedicated first PCM record,
ordinary FM records, and ordinary PSG records. The final regular FM record may
also have type `$06`, so that byte is not a DAC identifier. Ordinary SFX chooses
a fixed FM/PSG record when loaded. Special SFX `$F9..$FC` tests the current type
sign on each driver update. Its `$F3` changes the parser only after the current
note/duration event ends; the parser already executing its commands is not
replaced mid-event. These routes come from
[`driver_core.s`](../src/sound/driver_core.s) and
[`playback_and_loading.s`](../src/sound/playback_and_loading.s).

The guard verifies the exact note, transpose, noise, relative jump, loop,
call/return, and initialization instruction bodies and their command-table
associations before using these rules. The source initializers seed `$D=$30`,
copy each header word to `8(aN)`, and clear the loop/call bytes. Ordinary and
special SFX clear twelve longs per record. BGM reset clears `$220` bytes from
`SoundCurrentPriority=$FFFFF800`, covering the BGM records through `$FFFFFA1F`;
the named record addresses and clearing instructions are checked as well.
Every canonical BGM has at least six FM/PCM header records and executes that
stack-cursor seed. A hypothetical PSG-only BGM call is explicitly unanalysed
because its loader skips this register seed.

## Bounded execution and edit policy

Each header channel is analysed separately, even when several channels share
one sequence. State includes cursor, live type, transpose, current physical
parser, return stack, the eight bytes at `$28..$2F`, and the source pitch-control
dependency set. Relative calls return to the instruction after their operand;
loop counters execute their actual byte decrement, including count zero's
256 iterations. This is a finite state walk, not an infinite-loop assumption
or a union of all syntactic branch outcomes.

The call stack shares those loop bytes. A call marks its four absolute return
pointer bytes unknown; they remain unknown after return. A loop that indexes
them is unanalysed rather than assigned invented ROM-address bytes. Depth
greater than two escapes this proved region and is also unanalysed. Analysis
has an explicit 250,000-state ceiling per channel. `$FF $03` attenuation has
global-state-dependent operand consumption and is unanalysed; no canonical
payload currently uses any extended command. Unknown paths preserve the
original payload but lock all sequence edits to that payload. An unavailable
or changed source-reader contract fails validation instead of silently
disabling the guard.

An edited payload may not add a proved reference beyond the table. Existing
canonical out-of-table references are preserved only by exact source-relative
identity: channel/site, live type, transpose, note and encoded duration,
executed `$FB`/`$F3` instruction bytes and offsets, loop/return state, actual
table-byte SHA-256, and checked reader/initializer instruction-body SHA-256.
There is no address-only whitelist and no guessed correction to the original
game. Changing a transpose instruction and compensating the note cannot reuse
an old exception merely because the numerical index remains the same.
An independent volume edit can retain an otherwise identical reference.

The existing fixed instruction inventory keeps opcodes, sizes, targets, and
header bytes immutable. `$F7` selector and count bytes are now explicitly
source-owned too, matching the workstation's already locked control-flow
operands. This prevents headless JSON from bypassing the control-flow policy.

## The original corpus

Both cartridges hold 182 payloads and 33,062 instructions. Each profile analysed all
435 header channels in 97,301 states (largest channel: 1,899 states; greatest
call depth: one). There were no unanalysed canonical channels. JP and EU have
identical sound payload bytes; each profile is still validated on its own.

The current static out-of-table inventory is eight payload-relative sites,
15 channel/site pairs and 27 exact state/control contexts. Duplicate channel
owners are counted separately; repeated loop/control states explain the
additional contexts. Header channel indices below are zero-based.

| Payload | Offsets | Channels | Transpose / note | Effective index | Exact contexts |
| --- | --- | --- | --- | --- | --- |
| `Sound_BGM_81` | `$0EB2` | 6, 7 | `$DD` / `$A3` | 127 | 4 |
| `Sound_BGM_8C` | `$06A0`, `$06A5`, `$06A9` | 6, 7 | `$DC` / `$9D` | 120 | 6 |
| `Sound_BGM_8F` | `$0185` | 7 | `$19` / `$B2` | 74 | 1 |
| `Sound_BGM_90` | `$066C`, `$075D`, `$076E` | 6, 7 | `$E8` / `$97` | 126 | 16 |

Whether these references are intentionally used, interrupted before execution,
audibly silent, or errors in the shipped game remains **unknown**. They are
statically derived reads under an uninterrupted header execution, not runtime
chip observations. No canonical game payload has been altered to remove them.

Measured source fingerprints:

- PSG table, 140 big-endian bytes: SHA-256
  `a1c0729cf3c324276e18224a6e85ec287f8bc5f50ce8fdbcb848aa2dde720ecd`.
- Checked reader/initializer instruction bodies: SHA-256
  `5b958317c9fbdb0a5fd3751eb27fb67c9ec1ac8af5aa0df93c19432a842ba888`.
- Sorted `[payload name, payload SHA-256]` manifest, compact JSON: SHA-256
  `26dde0733b58b21f581af167fa348897102a87762436d7e48313f18f09f2a870`.

## Verification and limits

[`test_sound_period_references.py`](../tests/test_sound_period_references.py)
covers table-end and next-index probes, rests, signed/wrapped transposition,
shared FM/PSG roots, noise mode, event-boundary parser changes, counted loops,
call propagation and pointer aliases, exact baseline preservation, source
contract changes, unknown-path edit locking and headless validation. The
existing envelope and DAC reference suites also pass with this guard.

Header-initialization audition alone cannot prove these effective references.
This check does not simulate elapsed time, concurrent song/SFX requests,
pause/resume or fade scheduling, audio envelopes, chip writes, or waveform
quality. Runtime trace evidence is a separate obligation; static proof here
must not be reported as hardware playback confirmation.

## Fixed-capacity format inventory

`make check-sound-model` checks both regional profiles and inventories:

- 31 BGM request IDs (`$81-$9F`) resolving to 25 unique payloads because
  `$99-$9E` alias `$81`;
- 157 sequence-SFX payloads across `$40-$7F`, `$A0-$F8`, and the four special
  override IDs `$F9-$FC`;
- nine ROM-aligned DPCM banks totalling `$41A5E` bytes.

`make check-sound-workspace` proves that the editable sequence document for
both profiles, the 901-record FM instrument document, the global envelope
document, and all 90 header-delimited DPCM samples encode back to their current
binary and inline-assembly owners without a byte change.

The model follows `Sound_LoadBGMRequest`, `Sound_LoadSFX`, and
`Sound_LoadSpecialSFX`. A BGM header is six fixed bytes followed by four-byte
FM/DAC channel records and six-byte PSG channel records. An SFX header is four
fixed bytes followed by six-byte channel records. Every sequence-relative
offset must remain inside its payload. The instrument base may equal the end
of a payload: the driver stores that address for later `$EF` commands, and
PSG-only payloads legitimately never dereference it.

The inventory exposes numeric fields exactly as read by the driver: counts,
tempo, priority, channel type, sequence offset, and the remaining initial
words/bytes. It deliberately does not assign semantics to those remaining
values merely from repetition.

The same gate now statically walks all 435 channel entry points. Event widths
follow the FM, PSG, and PCM readers; command widths follow all `$E0-$FE`
handlers and the five `$FF` extensions. Relative jumps, counted-loop branches,
calls, returns, and stops are traversed without simulating playback time. The
current corpus contains 33,062 reachable instructions (26,878 events and 6,184
commands) occupying 51,045 bytes. Targets may not enter a header or the middle
of another instruction, and every selected 25-byte FM instrument must fit in
its owning payload.

The profile workspace stores these 182 payloads in `sound/sequences.json`.
It exposes the bytes of reachable notes, durations, and command operands while
keeping the payload size and full instruction inventory fixed. After an edit,
the validator re-decodes the complete payload and requires identical offsets,
sizes, opcodes, extended opcodes, and relative targets. This rejects changed
control flow, changed instruction roles, truncation, and overlaps. Binary
includes and inline `dc.b` payloads both write only through the isolated staged
content tree.

Sequence validation also checks the envelope selectors in `$F1`, `$F4`, and
`$F5` against the actual source pointer-table lengths. Both `$F1` operands and
the `$F4` operand select pitch envelopes; `Sound_ApplyPitchEffects` masks bit 7
before its one-based lookup, so `$80-$88` remain valid alongside `$00-$08`.
The `$F5` PSG-volume selector is not masked and must be `$00-$0A`. Zero disables
either envelope. Invalid selectors previously retained a legal instruction
shape but could make the driver read beyond its pointer table. They now fail
before a Save or content apply, and the workstation restores the previous
value and dirty state when an edit fails. These checks protect table references;
they do not prove the musical result of an edit.
The source-corpus check visits all 182 payloads and 33,062 reachable instructions
for each profile one payload at a time. The current sequences contain 38 `$F5`
selectors, with a maximum of ten, and no reachable `$F1` or `$F4`; the latter
commands' flag and boundary cases are therefore covered by synthetic fixtures.

The BGM loader places its first FM/DAC header entry in `SoundPCMChannelRecord`.
For that slot, `Sound_ProcessPCMSequence` subtracts `$81` from a note and indexes
an eight-byte sample descriptor without an upper-bound check. The authoring
validator separately walks everything reachable from this entry, including
called or shared subroutines, and permits only rest `$80` or an ID within the
source descriptor table (currently `$81-$96`). The regular FM/PSG note range
remains unchanged; channel type `$06` is not sufficient to identify DAC because
FM6 uses it too. All 25 BGM payloads currently contain 5,931 DAC-reachable notes,
all inside `$80-$96`. This prevents an otherwise structurally valid edit from
sending out-of-table bank/header bytes to the Z80.

`sound/instruments.json` covers every complete 25-byte record beginning at the
instrument base stored in each payload header: 901 records and 22,525 parameter
bytes. The driver proves the structure as one algorithm/feedback byte, twenty
operator parameter bytes written through registers `$30-$8C`, and four total
levels written through `$40-$4C`. Six four-operator arrays retain that register
order. The 101 residual alignment bytes are protected, and an instrument table
may not overlap any reachable sequence instruction.

`sound/envelopes.json` follows `Sound_ApplyPitchEffects` and
`Sound_UpdatePSGVolumeEnvelope` rather than treating labels as independent
arrays. The two pointer tables select eight pitch envelopes and ten PSG volume
envelopes. Their 360 physical bytes contain 343 editable signed values, 16
unique protected commands, and one unreachable protected padding byte.

The pointer table order is authoritative: record 5 precedes record 6 there,
although their physical labels occur as 6 then 5. In both families envelope 6
falls through into the physical record for envelope 5 before reaching its end
command. The model walks this real control flow and exports every physical
value once, so a shared tail cannot receive conflicting edits. `$80-$84` pitch
commands and `$80-$83` PSG commands remain immutable; an edited value is
rejected if its reader would reinterpret it as a command.

`sound/pcm_samples.json` follows the four-byte little-endian header records at
the start of every PCM bank. The first start pointer gives the table size; each
record then gives an in-bank start pointer and byte length. All 90 records form
contiguous sample chains covering 253,502 editable DPCM bytes. The 360 header
bytes and 15,032 bytes after the final samples remain immutable.

The music and voice descriptor tables are cross-checked against these headers.
They contain 70 eight-byte records: 22 music records and 48 voice records. The
voice dispatcher accepts only 47 records and explicitly rejects ID `$3F`, so
the final record is retained but marked non-dispatchable. The 69 dispatchable
records address 57 unique samples; the remaining 33 header-delimited samples
are honestly retained as unreferenced rather than assigned invented names.
Only fixed-length encoded bytes are writable at this layer.

The DPCM codec is also derived from the copied `$C00`-byte Z80 program. Its
page `$0B00` lookup applies the high-nibble delta first and page `$0A00`
applies the low-nibble delta second, starting from level `$80`. Both pages
reduce to sixteen byte deltas. In nibble order they are
`0,1,2,4,8,16,32,64,$80,$FF,$FE,$FC,$F8,$F0,$E0,$C0`. Every encoded byte
therefore produces two unsigned PCM values.
All 90 samples decode to 507,004 values and re-encode byte-exactly. The
ordinary PCM loop takes its `DJNZ` delay from the Z80 request state, which
the music path sets to `1`, rather than directly from a descriptor byte.
Voice requests enter a separate mixer. Authentic playback rates still need
runtime measurement and hardware/emulator scheduling evidence.
The two pinned `LD B,C` / `DJNZ -2` sites at Z80 `$0139` and `$0177` have a
smaller exact timing result: at the music request count of one, each pair
uses 12 Z80 T-states (four for the load and eight for the untaken branch).
The model also accounts for `DJNZ`'s 256 iterations when the count is zero.
The bounded CPU-only path now also pins both `LD ($4001),A` DAC writes at Z80
`$0134` and `$0173` and every intervening branch byte. With request count one,
the first-to-second write distance is **191 T-states**. The four routes after
`CP E` at `$0140` each contribute exactly 94 T-states when the equality
route's `$1FFF` wait flag is clear; each nonzero equality poll adds 34. The
negative route remains balanced whether that flag is clear or set. On an
uninterrupted sample, with nonzero `BC`, `B`'s sign bit clear, and no new request
at `$1FFE`, the second-to-next-first write distance is **196 T-states**.
Thus one ordinary encoded byte's two output values take **387 CPU T-states**
on that specified path, alternating 191 and 196 between writes. These are
instruction-cycle counts, **not** an original WAV sample rate: Z80 bus stalls,
the console clock, YM2612 write timing, interruptions, and the separate voice
mixing paths have not been measured against runtime audio. The instruction
timings come from the [Zilog Z80 CPU User Manual](https://www.zilog.com/docs/z80/um0080.pdf).

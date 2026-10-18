# Sound Studio

Sound Studio edits four documents: the music and effect sequences, the FM
instruments, the global pitch and PSG-volume envelopes, and the DPCM samples.
Their formats, capacities and the driver rules behind them are in
[sound models](sound_models.md); the driver itself and the request IDs are in
[the sound driver](sound_driver.md). This page covers the window and the
audition.

```text
make sound-studio CONTENT_PROFILE=jp
```

## The window

Choose an artifact, a payload and a value. The sequence view leaves out
opcodes, extended-opcode selectors, jump, call and loop displacements and the
variable-width pan-animation selector; the envelope view shows only signed
values; the PCM view only bytes inside a sample its bank header proves. An
edit that fails validation is rolled back together with the unsaved flags it
changed.

**Event context.** For a sequence operand the panel shows its instruction,
source offset, decoded note, duration or command, and every header channel
that reaches it. Channel roots come from the payload header; jumps, repeats and
calls are followed and a shared subroutine keeps all its owners. This is graph
reachability, not a playback timeline: command `$F3` can turn a channel into
PSG noise at run time.

The leading BGM FM/DAC header record is the dedicated PCM channel. A later
ordinary FM record may also have type `$06`, and that byte alone never makes it
DAC. An event reachable from a DAC owner may only be rest `$80` or a sample ID
from the ordinary descriptor table, even when FM or PSG channels share the same
bytes; without a proved binding the note control is disabled.

No note names, octaves or frequencies are assigned. The panel shows the
source's FM ordinal (`byte - $80`), PSG period index (`byte - $81`), DAC
selector or rest; durations are the encoded `0..127` operand, which the driver
later multiplies by its tick rate and tempo. The PSG period table has 70 words
but the driver masks its index by `$7F` without a bound check, so edits also
pass the effective-reference guard of [sound models](sound_models.md), which
follows transposition, live channel type, loops and calls.

**FM instruments.** For an instrument byte the panel names the register group
and operator slot, following the cartridge's 25-byte reader and register order
(`$30, $38, $34, $3C` and the later groups). Algorithm and feedback are
`0..7`; the operator controls split detune and multiple, key scale and attack,
AM and decay, sustain rate, sustain level and release, and total level. Each
control keeps the other bits of its byte, including ignored ones. The bit
widths follow the YM2612 register layout as implemented by
[ymfm](https://github.com/aaronsgiles/ymfm/blob/81aec25ccbb98f4873a255f7551ac4dadac59b4a/src/ymfm_opn.h#L197-L218).

**DPCM.** The PCM panel shows the decoded unsigned levels around the selected
encoded byte, and the Z80 timing of its two DAC writes within an
uninterrupted music request (byte zero at +0 and +191 T-states, byte one at
+387 and +578, and so on). That is CPU timing only, not the playback rate,
which is not proved yet. **Export PCM WAV** writes the levels as 8-bit mono at
a rate you choose, without resampling. The same export works without a window:

```text
python scripts/authoring/sound_pcm_preview.py --profile jp --bank Sound_PCMBank1 --sample 0 --rate 11025 --output build/audio-exports/sample.wav
```

Inside the project, WAV exports must go under `build/audio-exports/`.

Save, Reload, Build and Close follow [the common Studio actions](workstation_actions.md).

## Audition

The audition selector lists the 182 payloads without guessing titles;
selecting a sequence or instrument selects its payload. Envelope and PCM edits
are heard through whichever request is selected. BGM aliases `$99-$9E` are the
same payload as `$81`, so the lowest request ID stands for them.

**Play** saves, builds the regional content ROM with a fresh listing, and starts
Gens with sound on, from a private copy of the ROM. The cold boot reaches the
story; the launcher presses Start once the story's palette and loader guards
allow a skip, waits for the title, enters the options screen (mode `$1C`,
then `$20`) and submits stop-all and the selected request through
`SoundRequestQueue`, so the cartridge's own dispatcher and loaders set up the
channels. An execute hook on the loader's return checks the channel records
(status, type, tick multiplier, sequence pointer, counters, instrument,
envelope and tempo fields) against the values the source predicts before the
first event runs. **Stop**, closing the window or starting another audition
asks the cartridge to stop all sound (request `$04`) and then ends that
emulator if it does not exit by itself.

Each session runs in `build/content/<profile>/audition/` with a private Gens
configuration. The pinned emulator resets and reinitializes its sound device
when it reads a configuration that enables sound, so the launcher seeds the
startup directory with sound state 0 before the ordinary configuration turns it
on; neither the emulator nor the ROM is patched. The session keeps
`contract.json` (ROM, listing and emulator hashes and the expected RAM) and
`result.json`; on a timeout or mismatch, `result.json.diagnostic.json`
records the mode, phase, queue bytes, program counter and the last state
changes.

From the command line, build with a listing and play a request:

```text
make audition-sound CONTENT_PROFILE=jp SOUND_REQUEST=0x81
python scripts/authoring/sound_audition.py --profile jp --request 0x81 --rom build/content/jp/alien_soldier.bin --listing build/content/jp/sound_audition.lst --gens <Gens.exe>
```

The listing must be the `.lst` written by the same content build, inside
`build/content/<profile>/`. `--check` exits after the loader-state check;
otherwise the audition plays for 1,800 frames, or `--frames` up to 3,600.
On the pinned emulator, `$81`, `$A0` and `$F9` reach the BGM, ordinary SFX and
special-SFX loaders in both cartridges. Whether the result sounds exactly like
the hardware is not checked.

## Checks

`make check-sound-studio` makes a bounded edit in every artifact for both
profiles and applies it to a staged tree without a window. The widget tests
open hidden Tk windows with small fixtures, and the audition tests cover the
request inventory, region binding, Save-before-Build order, result validation
and cleanup without running the emulator.

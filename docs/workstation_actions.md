# Studio actions

The five Studios share the same few actions. They differ in a couple of places,
listed below.

## Save and Reload

Save validates every document of the Studio first and writes nothing if any of
them fails. It then replaces each edited JSON file in the workspace through a
uniquely named temporary beside it, so one file is never left half written.

A Save of several documents is not a single transaction. If the third of four
writes fails, the first two already hold their new content and the rest keep
their old bytes; there is no rollback across files. Every edit stays in memory
and stays marked unsaved, no "Saved" status is shown, and saving again writes
the whole current selection.

Reload reads the saved documents again and asks before discarding unsaved edits.

## Build and Playtest

Build runs `make build-content` for the Studio's profile in the project
directory. Level and Graphics Studio save first; Screen, Text and Sound Studio
refuse to build while there are unsaved edits. A compiler failure is reported
with its exit code. Level Studio's Playtest saves, then passes the selected
stage and profile to `make playtest-level`.

If the build or the emulator cannot be started at all, the Studio shows one
error and stays open; edits already saved stay saved.

## Closing

Closing with unsaved edits asks first. Level and Graphics Studio offer to save
and then close; Screen, Text and Sound Studio ask whether to discard.

## Sound Studio playback

Play saves, builds the workspace with a listing, and plays the selected request
through the cartridge's own driver in Gens. Stop ends that session only. The PCM
panel exports the selected sample to WAV at a rate you choose; cancelling either
dialog writes nothing.

## Tests

`tests/test_workstation_actions.py` opens every Studio for both profiles as a
hidden Tk window and presses the real buttons: Save and Reload round trips,
cancelled Reload and Close, failing validators and writers, Build with the right
profile, the dirty-close prompts, Level Playtest and Sound Play/Stop. Process
launches are intercepted, so no ROM is built and no emulator starts.
`tests/test_studio_io_failures.py` makes each writer fail in turn and checks the
per-file behaviour above. Both need Tk.

# Input movies

`attract.rlmovie` is the deterministic input that `make test-full` plays in MAME
on the relocated build; its check, `attract.check.json`, names the RAM cells and
the frames compared with the original ROM (`make golden` writes the expected
values) and carries the `title` and `description` Retrolarium shows.

## `attract.rlmovie`

From power-on the story plays, then the title, the options with the music,
effect and voice tests, and the title idles through its four recorded attract
demos (stages 2, 8, 10 and 16, with the game's own input streams) before Start
opens the weapon setup. It is the first 63,000 frames of a menus recording made
in Gens against the Japanese ROM, converted to Retrolarium's run-length
`.rlmovie` (`rltool movie convert`); the frames and inputs are unchanged.
`attract.scenes.txt` maps frame ranges to scenes.

The recording goes on into stage 1, and the earlier releases also kept a
longplay and a tool-assisted run. MAME plays those Gens inputs differently once
the player moves through a stage (no frame offset brings them back in step), so
they stay in earlier tagged snapshots. Completing that migration, including the
remaining runtime scenarios, longplay and tool-assisted run, is planned for 3.1.
The existing attract fixture is the MAME coverage included in the unified 3.0
release; it does not cover a complete playthrough or the European revision. Both
revisions are checked separately by the byte-exact build and zero-edit Studio
checks, which do not establish equivalent runtime coverage. See the
[release scope](../README.md#release-scope).

## Content boundary

A movie is recorded controller input. It contains no ROM data, no code, no
graphics, no audio and no savestate. That is why it is tracked while everything
derived from the cartridge is not.

## Regenerating

The movie is a fixture, not a build output. Re-recording it invalidates every
frame number in its scene list and the check's expected values, so replace it
only deliberately and run `make golden` in the same change.

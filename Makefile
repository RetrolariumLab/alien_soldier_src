# Alien Soldier (Sega Mega Drive): build the source back into the original
# ROMs and check it. `make` alone lists the targets. The ROMs are yours: copy
# them next to this file under the names assets/manifest.json gives, then run
# `make split` once.
PYTHON ?= python
RLTOOL ?= rltool
export RLTOOL

# jp (the default) or eu: the revision built, verified and played.
REVISION ?= jp
ifeq ($(filter $(REVISION),jp eu),)
$(error unknown REVISION "$(REVISION)": jp or eu)
endif
# Each build passes through config/game_profile.json's build/alien_soldier.bin.
ROM = build/alien_soldier_$(REVISION).bin
RELOCATED_ROM := build/relocated/alien_soldier.bin
# The movies the relocated build plays in `make test-full`, by name
# (movies/<name>.check.json, written by `make golden`).
MOVIES := attract
MOVIE_CHECKS = $(foreach movie,$(MOVIES),movies/$(movie).check.json)
MAME_OPTION = $(if $(MAME),--mame "$(MAME)")

.PHONY: help split build verify verify-revisions build-relocated studio-check lint format \
	test test-full golden play hooks clean _assets
.DEFAULT_GOAL := help

split:
	$(RLTOOL) assets split

_assets:
	$(RLTOOL) assets check --image $(REVISION)

# Retrolarium Kit assembles the Z80 sound program, then the 68000 source that
# includes it, with its own AS and p2bin, as config/game_profile.json says.
build: _assets
	$(RLTOOL) profile build --revision $(REVISION) --output $(ROM)

verify: build
	$(RLTOOL) assets verify --image $(REVISION) --built "$(ROM)"

verify-revisions:
	$(MAKE) --no-print-directory verify REVISION=jp
	$(MAKE) --no-print-directory verify REVISION=eu

# The Japanese source with every procedure moved (scripts/relocate.py),
# built the same way and given the checksum its boot code compares.
build-relocated:
	$(RLTOOL) assets check --image jp
	$(PYTHON) scripts/relocate.py --output-dir build/relocated
	$(RLTOOL) profile build --revision jp --entry build/relocated/main.s --output $(RELOCATED_ROM)
	$(PYTHON) scripts/relocate.py --finish $(RELOCATED_ROM) --revision jp

# Open alien_soldier.rlj in a throwaway copy of the repository the way
# Retrolarium Studio does, and rebuild both revisions without edits.
studio-check:
	$(RLTOOL) studio check alien_soldier.rlj

lint:
	$(RLTOOL) lint

format:
	$(RLTOOL) lint --fix

# The quick suite: the unit tests, both ROMs byte for byte, the relocated
# build and the studio check.
test:
	$(PYTHON) -m unittest discover -s tests -t .
	$(MAKE) --no-print-directory verify-revisions build-relocated studio-check

# The full suite: the quick one, then the movies in MAME on the relocated
# build, compared with what the original ROM gives (`make golden`).
test-full: test
	$(RLTOOL) movie check $(MOVIE_CHECKS) --rom "$(RELOCATED_ROM)" $(MAME_OPTION)

golden:
	$(RLTOOL) movie golden $(MOVIE_CHECKS) --rom "$(shell $(RLTOOL) assets path --image jp)" $(MAME_OPTION)

# Watch a movie in a MAME window at the game's speed, on the relocated build
# or on ROM=<image>; once the window is closed, its cells are compared with
# the original's. In MAME, F10 lifts the speed limit and Insert fast-forwards.
#   make play [MOVIE=<name>] [ROM=<image>] [FRAMES=<frame>] [CLOSE=1]
MOVIE ?= $(firstword $(MOVIES))
PLAY_ROM = $(if $(filter command line,$(origin ROM)),$(ROM),$(RELOCATED_ROM))

play: $(if $(filter command line,$(origin ROM)),,build-relocated)
	$(if $(wildcard movies/$(MOVIE).check.json),,$(error unknown MOVIE "$(MOVIE)": movies/ has \
		$(basename $(basename $(notdir $(wildcard movies/*.check.json))))))
	$(RLTOOL) movie play movies/$(MOVIE).check.json --rom "$(PLAY_ROM)" $(MAME_OPTION) \
		$(if $(FRAMES),--stop-at $(FRAMES)) $(if $(CLOSE),--close)

# `make hooks`, once per clone, makes Git check every commit and push for stop
# words and run `make lint` first (Retrolarium Kit's rltool hooks; the
# stop-word list lives outside the repositories).
hooks:
	$(RLTOOL) hooks install --project .

clean:
	$(PYTHON) -c "import shutil; shutil.rmtree('build', ignore_errors=True)"

help:
	$(info Alien Soldier source reconstruction)
	$(info   make split                  cut the data out of the ROMs, once)
	$(info   make build [REVISION=eu]    build the ROM into build/alien_soldier_jp.bin (or _eu))
	$(info   make verify [REVISION=eu]   build it and compare it with the ROM byte for byte)
	$(info   make verify-revisions       verify both revisions)
	$(info   make build-relocated        the Japanese ROM with every procedure moved)
	$(info   make test                   the quick suite)
	$(info   make test-full              test, then the movies in MAME: MAME=path or the kit's)
	$(info   make golden                 record the movies' checkpoints from the original ROM)
	$(info   make play [MOVIE=name]      watch a movie in MAME; ROM=image for another build)
	$(info   make studio-check / lint / format / hooks / clean)
	@exit 0

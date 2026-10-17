# Runtime baseline capture, playback and emulator selection.

# Boot the European cartridge from cold and watch it reach the attract demo.
.PHONY: check-region-runtime-eu
check-region-runtime-eu: verify-runtime-toolchain
	@$(PYTHON) -B -m scripts.runtime.region_smoke --gens "$(GENS_EXE)"

runtime: verify
	@$(MAKE) --no-print-directory runtime-capture

runtime-capture: verify-runtime-toolchain
	@$(PYTHON) $(SCRIPTS_DIR)/run_runtime_scenarios.py \
		--scenarios $(RUNTIME_SCENARIOS) \
		--gens "$(GENS_EXE)" \
		--rom "$(ROM)" \
		--output-dir $(RUNTIME_DIR)
	@$(MAKE) --no-print-directory runtime-validate RUNTIME_REQUIRE_RECEIPT=1

runtime-validate:
	@$(PYTHON) $(SCRIPTS_DIR)/validate_runtime_scenarios.py \
		--scenarios $(RUNTIME_SCENARIOS) \
		--capture-dir $(RUNTIME_DIR) \
		--ram-map src/ram_addrs.inc \
		$(if $(filter 1 true,$(RUNTIME_REQUIRE_RECEIPT)),--require-receipt --gens "$(GENS_EXE)" --rom "$(ROM)",)

# Watch a recorded movie play, on whichever image you name. Nothing is captured
# and nothing is checked: this is for looking at the game with your own eyes,
# which is the only way to see the classes of damage the state comparison and the
# vendored emulator are both blind to.
#
# Usage: make play MOVIE=tas|longplay|menus
#        make play MOVIE=tas ROM=alien_soldier_stretched_4mb.bin
#        make play MOVIE=longplay TURBO=1 FRAMES=20000 MUTE=1
#
# ROM defaults to $(ROM); TURBO, MUTE and FRAMES are off unless set.
PLAY_MOVIE_FILE = $(MOVIE_FILE_$(MOVIE))
PLAY_FLAGS = -frameskip 0 $(if $(TURBO),-turbo,) $(if $(MUTE),-nosound,) $(if $(FRAMES),-max-frames $(FRAMES),)
PLAY_USAGE = make play MOVIE=tas|longplay|menus [ROM=<image>] [TURBO=1] [MUTE=1] [FRAMES=<n>]

# Every failure here is raised with $(error) and the emulator is launched on one
# line, so the target behaves the same whether make found sh or fell back to
# cmd.exe. Recipes that use [ -f ] or echo "" do not.
.PHONY: play
play:
ifndef MOVIE
	$(error MOVIE is required. Usage: $(PLAY_USAGE))
else
ifeq ($(PLAY_MOVIE_FILE),)
	$(error unknown MOVIE "$(MOVIE)" - expected tas, longplay or menus. Usage: $(PLAY_USAGE))
else
ifeq ($(wildcard $(ROM)),)
	$(error ROM not found: $(ROM))
else
ifeq ($(wildcard $(PLAY_MOVIE_FILE)),)
	$(error movie not found: $(PLAY_MOVIE_FILE))
else
	@echo Playing $(PLAY_MOVIE_FILE) on $(ROM)
	"$(GENS_EXE)" -rom "$(ROM)" -play "$(PLAY_MOVIE_FILE)" $(PLAY_FLAGS)
endif
endif
endif
endif

# Generate exact-frame PNG/state archives in a new private session each time.
# TAS defaults to 90000 frames (including post-input credits), menus to its
# authenticated stream length; longplay requires an explicit bounded prefix.
# Usage: make reference MOVIE=tas|menus
#        make reference MOVIE=longplay REFERENCE_MAX_FRAMES=100000
.PHONY: reference
reference: verify-runtime-toolchain verify
ifndef MOVIE
	@echo "ERROR: MOVIE parameter required!"
	@echo ""
	@echo "Usage: make reference MOVIE=<type>"
	@echo ""
	@echo "Examples:"
	@echo "  make reference MOVIE=tas      - TAS speedrun reference"
	@echo "  make reference MOVIE=longplay - Longplay reference"
	@echo "  make reference MOVIE=menus    - Menu exploration reference"
	@exit 1
else
	@$(PYTHON) $(SCRIPTS_DIR)/capture_reference.py \
		--movie "$(MOVIE)" --rom "$(ROM)" --gens "$(GENS_EXE)" \
		--interval $(REFERENCE_INTERVAL) \
		$(if $(REFERENCE_MAX_FRAMES),--max-frames $(REFERENCE_MAX_FRAMES),) \
		--output-dir "reference/$(MOVIE)"
endif

# Gens emulator paths
GENS_DIR ?= ../gens_automation
GENS_EXE = $(GENS_DIR)/Output/Gens.exe
GENS_REPO = https://github.com/oranguthang/gens_automation.git

# Debug: Build ROM and run with screenshot + memory comparison
# Stops after N visual differences (memory diffs won't end the run)
# Usage: make debug MOVIE=tas|longplay|menus
.PHONY: debug
debug: build
ifndef MOVIE
	@echo "ERROR: MOVIE parameter required!"
	@echo ""
	@echo "Usage: make debug MOVIE=<type>"
	@echo ""
	@echo "Examples:"
	@echo "  make debug MOVIE=tas"
	@exit 1
else
	@echo "Running $(MOVIE) with visual comparison (debug mode)..."
	python -c "import os; os.makedirs('diffs/$(MOVIE)', exist_ok=True); os.makedirs('reports', exist_ok=True)"
	"$(GENS_EXE)" \
		-rom $(ROM) \
		-play $(MOVIE_FILE_$(MOVIE)) \
		-screenshot-interval $(ANALYSIS_INTERVAL) \
		-screenshot-dir diffs/$(MOVIE) \
		-reference-dir reference/$(MOVIE) \
		$(if $(MAX_FRAMES_$(MOVIE)),-max-frames $(MAX_FRAMES_$(MOVIE)),) \
		-max-diffs 10 \
		-max-memory-diffs 0 \
		-compare-state-dumps \
		-turbo \
		-frameskip 0 \
		-nosound
	@echo ""
	@echo "Emulator run complete. Generating comparison report..."
	@python $(SCRIPTS_DIR)/compare_states.py \
		--diffs-dir diffs/$(MOVIE) \
		--reference-dir reference/$(MOVIE) \
		--output-dir reports
	@echo ""
	@echo "Debug complete! Check:"
	@echo "  - diffs/$(MOVIE)/*.genstate - Memory dumps for diff frames"
	@echo "  - diffs/$(MOVIE)/*.png - Screenshots for diff frames"
	@echo "  - reports/diff_frame_*.md - Detailed LLM-friendly analysis report"
endif

# Stop all running emulators and analysis
.PHONY: stop
stop:
	@echo "Stopping analysis and emulators..."
	-taskkill /F /IM Gens.exe 2>nul
	-taskkill /F /IM python.exe 2>nul
	@echo "Done"

# Build Gens emulator (clone if not present)
.PHONY: build-gens
build-gens:
	@python -c "import os, subprocess; os.path.isdir('$(GENS_DIR)') or (print('Cloning gens_automation...'), subprocess.run(['git', 'clone', '$(GENS_REPO)', '$(GENS_DIR)']))"
	@echo "Building Gens emulator..."
	$(MAKE) -C $(GENS_DIR)
	@echo "Build complete: $(GENS_EXE)"

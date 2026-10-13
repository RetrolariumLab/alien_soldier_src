# Alien Soldier multi-profile Makefile
# Build configuration for AS assembler

PYTHON ?= python

# Toolchain selection: auto-detect host OS/arch and pick the matching
# build-tools folder under bin/. Override with: make PLATFORM=<subfolder>
ifeq ($(OS),Windows_NT)
    PLATFORM ?= windows_i386
    AS_EXE = asw.exe
    P2BIN_EXE = p2bin.exe
else
    UNAME_S := $(shell uname -s)
    UNAME_M := $(shell uname -m)
    ifeq ($(UNAME_S),Darwin)
        PLATFORM ?= macos_$(UNAME_M)
    else
        PLATFORM ?= linux_$(UNAME_M)
    endif
    AS_EXE = asl
    P2BIN_EXE = p2bin
endif

TOOLS_DIR = bin/$(PLATFORM)

# Tools
AS_BIN = $(TOOLS_DIR)/$(AS_EXE)
P2BIN = $(TOOLS_DIR)/$(P2BIN_EXE)

# Set message path for AS assembler (needed for as.msg, cmdarg.msg, etc.)
export AS_MSGPATH = $(TOOLS_DIR)

# Preservation profile. The Source 1.0 command surface remains the JP default;
# PROFILE=eu selects the independent European reference contract.
PROFILE ?= jp
PROFILE_CONFIG = config/rom_profiles.json

ifeq ($(PROFILE),jp)
override PROFILE_AS_ARGS =
SRC = src/main.s
OBJ = build/main.p
ROM = asbuilt.bin
LISTING = build/main.lst
ORIG_ROM = Alien Soldier (J) [!].bin
ASSET_MANIFEST = assets/manifest.json
ROM_LAYOUT = config/rom_layout.json
DATA_ADDRS = data/data_addrs.txt
else ifeq ($(PROFILE),eu)
override PROFILE_AS_ARGS = -D BuildProfileEU=1
SRC = src/main.s
OBJ = build/eu/main.p
ROM = asbuilt_eu.bin
LISTING = build/eu/main.lst
ORIG_ROM = Alien Soldier (E) [!].bin
ASSET_MANIFEST = assets/manifest_eu.json
ROM_LAYOUT = config/rom_layout_eu.json
DATA_ADDRS = data/data_addrs_eu.txt
else
$(error Unknown PROFILE "$(PROFILE)"; expected jp or eu)
endif

# Caller flags are independent of mandatory preservation-profile selection.
AS_ARGS = -maxerrors 2
override PRESERVATION_AS_ARGS = $(strip $(AS_ARGS) $(PROFILE_AS_ARGS))

TOOLCHAIN_MANIFEST = config/toolchain.json
RUNTIME_SCENARIOS = config/runtime_scenarios.json
RUNTIME_DIR = runtime/captures
RUNTIME_REQUIRE_RECEIPT ?= 0
CONTENT_MANIFEST = config/authoring/content_studios.json
CONTENT_PROFILE ?= $(PROFILE)
CONTENT_ROM = build/content/$(CONTENT_PROFILE)/alien_soldier.bin
PLAYTEST_STAGE ?= 1
PLAYTEST_DIFFICULTY ?= easy
SOUND_REQUEST ?= 0x81
SOUND_FRAMES ?= 1800
SOUND_LISTING = $(abspath build/content/$(CONTENT_PROFILE)/sound_audition.lst)

# Directories
DATA_DIR = data
SRC_DIR = src
SCRIPTS_DIR = scripts
BIN_DIR = bin

# Default target
.PHONY: all build verify verify-all check-assets update-asset-manifest verify-toolchain verify-layout verify-relocation format lint test runtime runtime-capture runtime-validate release-check profile-info check-profile-ready derive-eu-assets derive-eu-layout init-content init-content-all inspect-content validate-content validate-content-all build-content check-content check-content-zero-edit check-level-model check-graphics-models check-graphics-workspace
all: build

# Preservation profile selection, extraction, assembly and identity.

profile-info:
	@$(PYTHON) $(SCRIPTS_DIR)/rom_profiles.py \
		--config $(PROFILE_CONFIG) --profile $(PROFILE)

# Preservation commands accept only profiles whose byte identity is supported.
check-profile-ready:
	@$(PYTHON) $(SCRIPTS_DIR)/rom_profiles.py \
		--config $(PROFILE_CONFIG) --profile $(PROFILE) --require-supported \
		--field status

derive-eu-assets:
	@$(PYTHON) $(SCRIPTS_DIR)/derive_profile_assets.py \
		--profiles $(PROFILE_CONFIG)

derive-eu-layout:
	@$(MAKE) --no-print-directory build/eu/main.lst PROFILE=eu
	@$(PYTHON) $(SCRIPTS_DIR)/derive_profile_layout.py \
		--base config/rom_layout.json \
		--listing build/eu/main.lst \
		--profile eu \
		--output config/rom_layout_eu.json

# Reject caller-owned profile symbols before preservation assembly/extraction.
.PHONY: check-profile-as-args
check-profile-as-args:
	@$(PYTHON) $(SCRIPTS_DIR)/check_profile_as_args.py --flags="$(AS_ARGS)"

.PHONY: check-profile-flags
check-profile-flags:
	@$(PYTHON) -m unittest tests.test_profile_make_args

# Initialize project from original ROM
# Usage: make init
.PHONY: init
init: check-profile-as-args check-profile-ready
	@$(PYTHON) $(SCRIPTS_DIR)/init_project.py \
		--orig-rom "$(ORIG_ROM)" \
		--manifest $(ASSET_MANIFEST) \
		--data-dir $(DATA_DIR) \
		--data-addrs $(DATA_ADDRS) \
		--source $(SRC) \
		--obj $(OBJ) \
		--output $(ROM) \
		--as-bin $(AS_BIN) \
		--p2bin $(P2BIN) \
		--as-args="$(PRESERVATION_AS_ARGS)" \
		--preserve-manifest assets/manifest.json \
		--preserve-manifest assets/manifest_eu.json

# Check if project is initialized (data/ directory with subfolders exists)
# If missing, print a friendly hint instead of cryptic "error in opening file"
.PHONY: check-init
check-init:
	@$(PYTHON) $(SCRIPTS_DIR)/check_init.py \
		--data-dir "$(DATA_DIR)" \
		--orig-rom "$(ORIG_ROM)"

# Build ROM from assembly source
.PHONY: build
build: check-profile-as-args check-profile-ready check-init check-assets verify-toolchain
	@echo "Building ROM..."
	$(PYTHON) $(SCRIPTS_DIR)/build_rom.py \
		--source $(SRC) \
		--obj $(OBJ) \
		--output $(ROM) \
		--manifest $(ASSET_MANIFEST) \
		--original-rom "$(ORIG_ROM)" \
		--as-bin $(AS_BIN) \
		--p2bin $(P2BIN) \
		--as-args="$(PRESERVATION_AS_ARGS)"
	@echo ""
	@echo "Build complete: $(ROM)"

# Permanent preservation gate: assemble from source and require the selected
# profile's declared cartridge image byte for byte.
verify: check-profile-as-args check-profile-ready check-init check-assets verify-toolchain
	@$(PYTHON) $(SCRIPTS_DIR)/build_rom.py --source $(SRC) --obj $(OBJ) --output $(ROM) --manifest $(ASSET_MANIFEST) --original-rom "$(ORIG_ROM)" --as-bin $(AS_BIN) --p2bin $(P2BIN) --as-args="$(PRESERVATION_AS_ARGS)" --verify
	@$(MAKE) --no-print-directory verify-layout

verify-all:
	@$(MAKE) --no-print-directory verify PROFILE=jp
	@$(MAKE) --no-print-directory verify PROFILE=eu

# Split original ROM into data files
.PHONY: split
split:
	@python $(SCRIPTS_DIR)/split_data_from_rom.py \
		--rom-file "$(ORIG_ROM)" \
		--output $(DATA_DIR) \
		--addrs $(DATA_ADDRS) \
		--manifest $(ASSET_MANIFEST) \
		--preserve-manifest assets/manifest.json \
		--preserve-manifest assets/manifest_eu.json

# Read-only prerequisite for every ordinary build.
check-assets:
	@$(PYTHON) $(SCRIPTS_DIR)/check_assets.py \
		--manifest $(ASSET_MANIFEST) \
		--asset-dir $(DATA_DIR) \
		--preserve-manifest assets/manifest.json \
		--preserve-manifest assets/manifest_eu.json

# Explicit maintainer operation used only when the extraction map changes.
update-asset-manifest:
	@$(PYTHON) $(SCRIPTS_DIR)/generate_asset_manifest.py \
		--manifest $(ASSET_MANIFEST) \
		--rom "$(ORIG_ROM)" \
		--ranges $(DATA_ADDRS) \
		--asset-dir $(DATA_DIR)

verify-toolchain:
	@$(PYTHON) $(SCRIPTS_DIR)/verify_toolchain.py \
		--config $(TOOLCHAIN_MANIFEST) \
		--platform $(PLATFORM) \
		$(if $(filter default file,$(origin GENS_DIR)),,--emulator-dir "$(GENS_DIR)")

.PHONY: verify-runtime-toolchain
verify-runtime-toolchain:
	@$(PYTHON) $(SCRIPTS_DIR)/verify_toolchain.py \
		--config $(TOOLCHAIN_MANIFEST) --platform $(PLATFORM) \
		--require-emulator --emulator-dir "$(GENS_DIR)"

verify-layout: $(LISTING)
	@$(PYTHON) $(SCRIPTS_DIR)/verify_layout.py \
		--layout $(ROM_LAYOUT) \
		--listing $(LISTING) \
		--rom $(ROM) \
		--manifest $(ASSET_MANIFEST)

# Rebuild with the layout perturbed and require every reference to follow it.
# A reference the assembler owns moves; a value written as a literal does not,
# and that difference is what this separates. No emulator is involved.
verify-relocation: $(LISTING)
	@$(PYTHON) $(SCRIPTS_DIR)/verify_relocation.py 		--layout $(ROM_LAYOUT) 		--listing $(LISTING) 		--rom $(ROM)

# Unpack LZSS-compressed data from ROM to data/uncompressed/
# Attempts to decompress all entries from data/data_addrs.txt
# Decompress LZSS data in all data subdirectories
# Creates uncompressed/ subfolder where decompression succeeds
.PHONY: unpack-data
unpack-data:
	@python $(SCRIPTS_DIR)/unpack_data.py --data-dir $(DATA_DIR)

# Clean build artifacts and temp files
.PHONY: clean
clean:
	@python $(SCRIPTS_DIR)/clean_project.py

# Generate listing file (prerequisite for symbols)

$(LISTING): $(wildcard src/*.s src/*/*.s src/*.inc) | check-profile-as-args
	@echo "Building listing file..."
	@python -c "import os; os.makedirs('build', exist_ok=True)"
	$(AS_BIN) -i . -L -olist $(LISTING) -o $(OBJ) $(PRESERVATION_AS_ARGS) $(SRC)
# Content: the workspace, its models, the five Studios and the content build.

.PHONY: init-content init-content-all inspect-content validate-content validate-content-all build-content check-content-zero-edit check-level-model check-level-map-model art-validate palette-validate mapping-validate tilemap-validate check-graphics-models check-screen-model check-screen-workspace check-graphics-workspace check-compressed-graphics-workspace check-palette-workspace check-mapping-workspace check-animation-workspace

# Content builds live under build/content and never write src/ or data/.
# PROFILE remains the preservation selector; CONTENT_PROFILE independently
# chooses which cartridge is used as the editable project's base.
init-content:
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/content_workspace.py init \
		--manifest $(CONTENT_MANIFEST) --profile $(CONTENT_PROFILE) \
		$(if $(filter true,$(FORCE)),--force,)

init-content-all:
	@$(MAKE) --no-print-directory init-content CONTENT_PROFILE=jp
	@$(MAKE) --no-print-directory init-content CONTENT_PROFILE=eu

inspect-content:
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/content_workspace.py inspect \
		--manifest $(CONTENT_MANIFEST) --profile $(CONTENT_PROFILE)

validate-content:
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/content_workspace.py validate \
		--manifest $(CONTENT_MANIFEST) --profile $(CONTENT_PROFILE)

validate-content-all:
	@$(MAKE) --no-print-directory validate-content CONTENT_PROFILE=jp
	@$(MAKE) --no-print-directory validate-content CONTENT_PROFILE=eu

build-content: check-profile-as-args init-content
	@$(MAKE) --no-print-directory check-init check-assets verify-toolchain \
		PROFILE=$(CONTENT_PROFILE)
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/build_content.py \
		--manifest $(CONTENT_MANIFEST) --profile $(CONTENT_PROFILE) \
		--as-bin $(AS_BIN) --p2bin $(P2BIN) --as-args="$(AS_ARGS)" \
		$(if $(CONTENT_LISTING),--listing "$(CONTENT_LISTING)",)

# This deliberately ignores local workspace documents and stages directly
# from tracked preservation inputs. Both regional baselines are mandatory.
check-content-zero-edit:
	@$(MAKE) --no-print-directory check-init check-assets verify-toolchain PROFILE=jp
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/build_content.py --zero-edit \
		--manifest $(CONTENT_MANIFEST) --profile jp \
		--as-bin $(AS_BIN) --p2bin $(P2BIN) --as-args "-maxerrors 2"
	@$(MAKE) --no-print-directory check-init check-assets verify-toolchain PROFILE=eu
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/build_content.py --zero-edit \
		--manifest $(CONTENT_MANIFEST) --profile eu \
		--as-bin $(AS_BIN) --p2bin $(P2BIN) --as-args "-maxerrors 2"

check-level-model:
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/level_studio_model.py check --profile jp
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/level_studio_model.py check --profile eu

.PHONY: check-level-map-model
check-level-map-model:
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/stage_map_model.py check --profile jp
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/stage_map_model.py check --profile eu

art-validate:
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/tile_art.py validate

palette-validate:
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/palettes.py validate

mapping-validate:
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/sprite_mappings.py validate

tilemap-validate:
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/stage_tilemaps.py validate

check-graphics-models: art-validate palette-validate mapping-validate tilemap-validate

check-screen-model:
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/screen_studio_model.py check --profile jp
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/screen_studio_model.py check --profile eu

check-screen-workspace:
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/screen_map_model.py check --profile jp
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/screen_map_model.py check --profile eu

# Play one music or sound request through the cartridge's own driver, on the
# saved workspace: make audition-sound SOUND_REQUEST=0x81
.PHONY: build-content-runtime
build-content-runtime: verify-runtime-toolchain
	@$(MAKE) --no-print-directory build-content CONTENT_PROFILE=$(CONTENT_PROFILE) \
		AS_ARGS='-q -maxerrors 2' CONTENT_LISTING="$(SOUND_LISTING)"

# Write a migrated copy of an older screen workspace; the original stays.
.PHONY: migrate-screen-workspace
migrate-screen-workspace:
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/screen_map_model.py migrate-story-plane \
		--profile $(CONTENT_PROFILE) --document content/workspace/$(CONTENT_PROFILE)/screens/maps.json \
		--output $(or $(MIGRATION_OUTPUT),build/content/$(CONTENT_PROFILE)/story-plane-migrated.json)

check-graphics-workspace: check-compressed-graphics-workspace check-palette-workspace check-mapping-workspace check-animation-workspace
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/graphics_studio_model.py check --profile jp
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/graphics_studio_model.py check --profile eu

check-compressed-graphics-workspace:
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/compressed_graphics_model.py check --profile jp
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/compressed_graphics_model.py check --profile eu

check-palette-workspace:
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/palette_studio_model.py check --profile jp
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/palette_studio_model.py check --profile eu

.PHONY: check-mapping-workspace
check-mapping-workspace:
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/mapping_studio_model.py check --profile jp
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/mapping_studio_model.py check --profile eu

check-animation-workspace:
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/animation_studio_model.py check --profile jp
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/animation_studio_model.py check --profile eu

# Every content model, workspace and Studio check against both cartridges.
.PHONY: check-content
check-content: init-content-all
	@$(MAKE) --no-print-directory check-level-model check-level-map-model check-graphics-models check-graphics-workspace check-screen-model check-screen-workspace
# Source policy, tests and the semantic audit tools.

.PHONY: lint format test source-inventory semantic-audit

lint:
	@$(PYTHON) $(SCRIPTS_DIR)/asm_style.py src
	@$(PYTHON) $(SCRIPTS_DIR)/lint_source.py \
		--policy config/source_policy.json
	@$(PYTHON) $(SCRIPTS_DIR)/lint_project.py

format:
	@$(PYTHON) $(SCRIPTS_DIR)/asm_style.py src --fix
	@$(MAKE) --no-print-directory lint

# Every test module in its own process, TEST_JOBS at a time. Name a few with
# TESTS="sound level" to run only the modules whose names contain them.
TEST_JOBS ?= 8
test:
	@$(PYTHON) -B tests/run_tests.py --jobs $(TEST_JOBS) $(TESTS)

source-inventory: $(LISTING)
	@$(PYTHON) $(SCRIPTS_DIR)/source_inventory.py \
		--layout $(ROM_LAYOUT) \
		--listing $(LISTING) \
		--output build/source_inventory.json

semantic-audit:
	@$(PYTHON) $(SCRIPTS_DIR)/semantic_audit_queue.py
# Runtime baseline capture, playback and emulator selection.

# Boot the European cartridge from cold and watch it reach the attract demo.

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
# Optional research, analysis and source naming workflow.

# Analysis configuration
# Workflow directory (for reports, procedure lists, etc.)
WORKFLOW_DIR = workflow

# Movie files for each analysis type
MOVIE_FILE_tas = movies/dammit,truncated-aliensoldier.gmv
MOVIE_FILE_longplay = movies/alien_soldier_j_longplay.gmv
MOVIE_FILE_menus = movies/alien_soldier_j_menus.gmv

# Max frames per movie type (0 = play until end)
MAX_FRAMES_tas = 90000
MAX_FRAMES_longplay = 0
MAX_FRAMES_menus = 0
ANALYSIS_WORKERS ?= 1
ANALYSIS_GRID_COLS = 6
ANALYSIS_FRAMESKIP = 8
ANALYSIS_INTERVAL = 20
# Reference captures are the full frame-by-frame baseline; analysis/debug may
# sample this superset at ANALYSIS_INTERVAL without regenerating it.
REFERENCE_INTERVAL ?= 1
REFERENCE_MAX_FRAMES ?= $(filter-out 0,$(MAX_FRAMES_$(MOVIE)))
ANALYSIS_MAX_FRAMES = 90000
ANALYSIS_MAX_DIFFS = 10
ANALYSIS_DIFF_COLOR = pink
PROCEDURES_FILE = $(WORKFLOW_DIR)/unanalyzed_procedures.txt

# Analyze procedures for visual/memory impact
# Usage: make analyze MOVIE=tas|longplay|menus
.PHONY: analyze
analyze:
ifndef MOVIE
	@echo "ERROR: MOVIE parameter required!"
	@echo ""
	@echo "Usage: make analyze MOVIE=<type>"
	@echo ""
	@echo "Examples:"
	@echo "  make analyze MOVIE=tas      - Analyze with TAS speedrun"
	@echo "  make analyze MOVIE=longplay - Analyze with longplay"
	@echo "  make analyze MOVIE=menus    - Analyze with menu exploration"
	@exit 1
else
	@echo "Analyzing procedures with $(MOVIE) ($(ANALYSIS_WORKERS) workers)..."
	@$(PYTHON) $(SCRIPTS_DIR)/analyze_procedures.py --project-dir . --source $(SRC) --rom $(ROM) --movie $(MOVIE_FILE_$(MOVIE)) --reference reference/$(MOVIE) --diffs diffs/$(MOVIE) --gens "$(GENS_EXE)" --procedures-file $(PROCEDURES_FILE) --workers $(ANALYSIS_WORKERS) --grid-cols $(ANALYSIS_GRID_COLS) --frameskip $(ANALYSIS_FRAMESKIP) --interval $(ANALYSIS_INTERVAL) $(if $(MAX_FRAMES_$(MOVIE)),--max-frames $(MAX_FRAMES_$(MOVIE)),) --max-diffs $(ANALYSIS_MAX_DIFFS) --diff-color $(ANALYSIS_DIFF_COLOR)
endif

# Find which procedures are not yet analyzed and save to file
.PHONY: find-unanalyzed
find-unanalyzed:
	@$(PYTHON) $(SCRIPTS_DIR)/find_review_procedures.py --source $(SRC) --audit config/name_audit.json --output $(PROCEDURES_FILE)
	@echo "Saved to $(PROCEDURES_FILE)"

# Generate analysis report
# Usage: make report MOVIE=tas|longplay|menus
.PHONY: report
report:
ifndef MOVIE
	@echo "ERROR: MOVIE parameter required!"
	@echo ""
	@echo "Usage: make report MOVIE=<type>"
	@echo ""
	@echo "Examples:"
	@echo "  make report MOVIE=tas      - Generate TAS report"
	@echo "  make report MOVIE=longplay - Generate longplay report"
	@echo "  make report MOVIE=menus    - Generate menus report"
	@exit 1
else
	@echo "Generating $(MOVIE) analysis report..."
	@python -c "import os; os.makedirs('$(WORKFLOW_DIR)', exist_ok=True)"
	python $(SCRIPTS_DIR)/generate_analysis_report.py --project-dir . --movie $(MOVIE) --output-dir $(WORKFLOW_DIR)
	@echo "Report saved: $(WORKFLOW_DIR)/analysis_report_$(MOVIE).txt / .csv"
endif

# Compare built ROM with reference
.PHONY: compare
compare:
	@$(PYTHON) $(SCRIPTS_DIR)/compare_roms.py \
		--built $(ROM) \
		--original "$(ORIG_ROM)" \
		--manifest $(ASSET_MANIFEST) \
		--project-dir .

# ============================================================================
# DOCUMENTATION WORKFLOW
# ============================================================================
# 1. make set-movie MOVIE=tas     - Set current movie type for workflow
# 2. make prepare-batch COUNT=40  - Prepare batch of procedures to document
# 3. [Claude creates workflow/rename_batch.csv with new names]
# 4. make rename                  - Apply renames and mark as processed
# ============================================================================

# Set movie type for documentation workflow
# Usage: make set-movie MOVIE=tas|longplay|menus
.PHONY: set-movie
set-movie:
	@$(PYTHON) $(SCRIPTS_DIR)/research_movie.py set --marker $(WORKFLOW_DIR)/.movie --movie "$(MOVIE)"

# Show current movie setting
.PHONY: show-movie
show-movie:
	@$(PYTHON) $(SCRIPTS_DIR)/research_movie.py show --marker $(WORKFLOW_DIR)/.movie

# Prepare batch of procedures for documentation
# Usage: make prepare-batch COUNT=40
BATCH_COUNT ?= 40
.PHONY: prepare-batch
prepare-batch:
	@$(PYTHON) $(SCRIPTS_DIR)/prepare_batch.py --movie-file $(WORKFLOW_DIR)/.movie --count $(BATCH_COUNT) --output $(WORKFLOW_DIR)/batch_procedures.txt --source $(SRC)

# Apply renames from rename_batch.csv and mark as processed
.PHONY: rename
rename:
	@$(PYTHON) $(SCRIPTS_DIR)/rename_batch.py --database $(WORKFLOW_DIR)/rename_batch.csv --movie-file $(WORKFLOW_DIR)/.movie

# Debug pointer issues by testing data blocks from END of ROM
# Retired: the old debugger mutates a monolithic file and can delete diff data.
# Use verify-relocation for the address-ordered source instead.
.PHONY: debug-pointers
debug-pointers:
	@$(PYTHON) $(SCRIPTS_DIR)/debug_pointers.py

# Retired with the old pointer debugger; preserved as a safe diagnostic.
.PHONY: report-pointers
report-pointers:
	@$(PYTHON) $(SCRIPTS_DIR)/report_pointers.py
# CPU trace capture and stopped trace analysis.

# Trace CPU execution after breakpoint
# Usage: make trace MOVIE=tas BP=0xNNNN [FRAMES=20] [LOG=trace.log]
# Example: make trace MOVIE=tas BP=0x11594 FRAMES=20 LOG=logs/trace_Boss.log
.PHONY: trace
trace:
ifndef MOVIE
	@echo "ERROR: MOVIE parameter required!"
	@echo ""
	@echo "Usage: make trace MOVIE=<type> BP=<hex_addr> [FRAMES=<n>] [LOG=<path>]"
	@echo ""
	@echo "Parameters:"
	@echo "  MOVIE   - Movie type: tas, longplay, or menus"
	@echo "  BP      - Breakpoint PC address in hex (e.g., 0x11594 or 11594)"
	@echo "  FRAMES  - Number of frames to trace after breakpoint (default: 20)"
	@echo "  LOG     - Path to trace log file (default: trace_<BP>.csv)"
	@echo ""
	@echo "Examples:"
	@echo "  make trace MOVIE=tas BP=0x11594"
	@echo "  make trace MOVIE=tas BP=0x11594 FRAMES=50 LOG=logs/boss_trace.csv"
	@exit 1
else ifndef BP
	@echo "ERROR: BP (breakpoint) parameter required!"
	@echo ""
	@echo "Usage: make trace MOVIE=<type> BP=<hex_addr>"
	@exit 1
else
	@echo "Tracing from breakpoint $(BP) for $(if $(FRAMES),$(FRAMES),20) frames..."
	@if not exist logs mkdir logs
	@if not exist build mkdir build
	$(GENS_EXE) -rom $(ROM) -play $(MOVIE_FILE_$(MOVIE)) -turbo -frameskip 8 -nosound \
		-screenshot-interval 2147483647 \
		-screenshot-dir build \
		$(if $(MAX_FRAMES_$(MOVIE)),-max-frames $(MAX_FRAMES_$(MOVIE)),) \
		-trace-breakpoint $(BP) \
		-trace-frames $(if $(FRAMES),$(FRAMES),20) \
		-trace-log $(if $(LOG),$(LOG),logs/trace_$(BP).csv)
endif

# Binary trace CPU execution by frame range
# Usage: make trace-frames MOVIE=<type> START=<frame> END=<frame> [LOG=<path>]
# Example: make trace-frames MOVIE=tas START=10300 END=10320 LOG=logs/bug.btrc
#
# Output: Compact binary trace file (~10-50x smaller than text)
# Post-process with:
#   make trace-story LOG=logs/bug.btrc    - Human-readable story
#   make trace-graph LOG=logs/bug.btrc    - Graphviz pointer/DMA visualization
.PHONY: trace-frames
trace-frames:
ifndef MOVIE
	@echo "ERROR: MOVIE parameter required!"
	@echo ""
	@echo "Usage: make trace-frames MOVIE=<type> START=<frame> END=<frame> [LOG=<path>]"
	@echo ""
	@echo "Parameters:"
	@echo "  MOVIE   - Movie type: tas, longplay, or menus"
	@echo "  START   - Start tracing at this frame"
	@echo "  END     - Stop tracing at this frame"
	@echo "  LOG     - Path to binary trace file (default: logs/trace_<START>_<END>.btrc)"
	@echo ""
	@echo "Examples:"
	@echo "  make trace-frames MOVIE=tas START=10300 END=10320"
	@echo "  make trace-frames MOVIE=tas START=10300 END=10320 LOG=logs/flying_neo.btrc"
	@echo ""
	@echo "Post-processing:"
	@echo "  make trace-story LOG=logs/trace_10300_10320.btrc"
	@echo "  make trace-graph LOG=logs/trace_10300_10320.btrc MODE=pointers"
	@echo "  make trace-graph LOG=logs/trace_10300_10320.btrc MODE=dma"
	@exit 1
else ifndef START
	@echo "ERROR: START parameter required!"
	@exit 1
else ifndef END
	@echo "ERROR: END parameter required!"
	@exit 1
else
	@echo "Binary tracing frames $(START) to $(END)..."
	@python -c "import os; os.makedirs('logs', exist_ok=True)"
	"$(GENS_EXE)" -rom $(ROM) -play $(MOVIE_FILE_$(MOVIE)) -turbo -nosound -frameskip 0 -bintrace $(if $(LOG),$(LOG),logs/trace_$(START)_$(END).btrc) -bintrace-start $(START) -bintrace-end $(END)
	@echo ""
	@echo "Binary trace saved to: $(if $(LOG),$(LOG),logs/trace_$(START)_$(END).btrc)"
	@echo ""
	@echo "Next steps:"
	@echo "  make trace-story LOG=$(if $(LOG),$(LOG),logs/trace_$(START)_$(END).btrc)"
	@echo "  make trace-graph LOG=$(if $(LOG),$(LOG),logs/trace_$(START)_$(END).btrc) MODE=pointers"
endif

# Generate human-readable story log from binary trace
# Usage: make trace-story LOG=<path.btrc> [OUT=<path.txt>] [SYMBOLS=<path.txt>]
.PHONY: trace-story
trace-story:
ifndef LOG
	@echo "ERROR: LOG parameter required!"
	@echo ""
	@echo "Usage: make trace-story LOG=<trace.btrc> [OUT=<story.txt>] [SYMBOLS=<file.txt>]"
	@echo ""
	@echo "Examples:"
	@echo "  make trace-story LOG=logs/trace_10300_10320.btrc"
	@echo "  make trace-story LOG=logs/trace.btrc OUT=logs/story.txt"
	@echo "  make trace-story LOG=logs/trace.btrc SYMBOLS=logs/symbols.txt"
	@echo ""
	@echo "Tip: Run 'make symbols' first to generate symbol file"
	@exit 1
else
	@echo "Generating story log from $(LOG)..."
	python $(SCRIPTS_DIR)/bintrace_parser.py $(LOG) \
		--story $(if $(OUT),$(OUT),$(LOG:.btrc=_story.txt)) \
		$(if $(SYMBOLS),--symbols $(SYMBOLS),$(if $(wildcard $(SYMBOLS_FILE)),--symbols $(SYMBOLS_FILE),))
endif

# Generate Graphviz visualizations from binary trace (all modes)
# Usage: make trace-graph LOG=<path.btrc>
.PHONY: trace-graph
trace-graph:
ifndef LOG
	@echo "ERROR: LOG parameter required!"
	@echo ""
	@echo "Usage: make trace-graph LOG=<trace.btrc>"
	@echo ""
	@echo "Generates all graph types:"
	@echo "  - pointers: pointer table relationships"
	@echo "  - dma: DMA data flow (ROM -> VRAM)"
	@echo "  - callers: which functions trigger DMA/reads"
	@echo ""
	@echo "Examples:"
	@echo "  make trace-graph LOG=logs/trace.btrc"
	@exit 1
else
	@echo === Generating all graphs from $(LOG) ===
	@echo.
	@echo [1/3] Pointers graph...
	@python $(SCRIPTS_DIR)/bintrace_parser.py $(LOG) \
		--graphviz $(LOG:.btrc=_pointers.dot) --mode pointers \
		$(if $(wildcard $(SYMBOLS_FILE)),--symbols $(SYMBOLS_FILE),)
	@python -c "import subprocess; r = subprocess.run(['dot', '-Tpng', '$(LOG:.btrc=_pointers.dot)', '-o', '$(LOG:.btrc=_pointers.png)'], capture_output=True); print('  -> $(LOG:.btrc=_pointers.png)') if r.returncode == 0 else print('  -> $(LOG:.btrc=_pointers.dot) (no graphviz)')"
	@echo.
	@echo [2/3] DMA graph...
	@python $(SCRIPTS_DIR)/bintrace_parser.py $(LOG) \
		--graphviz $(LOG:.btrc=_dma.dot) --mode dma \
		$(if $(wildcard $(SYMBOLS_FILE)),--symbols $(SYMBOLS_FILE),)
	@python -c "import subprocess; r = subprocess.run(['dot', '-Tpng', '$(LOG:.btrc=_dma.dot)', '-o', '$(LOG:.btrc=_dma.png)'], capture_output=True); print('  -> $(LOG:.btrc=_dma.png)') if r.returncode == 0 else print('  -> $(LOG:.btrc=_dma.dot) (no graphviz)')"
	@echo.
	@echo [3/3] Callers graph...
	@python $(SCRIPTS_DIR)/bintrace_parser.py $(LOG) \
		--graphviz $(LOG:.btrc=_callers.dot) --mode callers \
		$(if $(wildcard $(SYMBOLS_FILE)),--symbols $(SYMBOLS_FILE),)
	@python -c "import subprocess; r = subprocess.run(['dot', '-Tpng', '$(LOG:.btrc=_callers.dot)', '-o', '$(LOG:.btrc=_callers.png)'], capture_output=True); print('  -> $(LOG:.btrc=_callers.png)') if r.returncode == 0 else print('  -> $(LOG:.btrc=_callers.dot) (no graphviz)')"
	@echo.
	@echo Done! Generated graphs in $(dir $(LOG))
endif

# Print binary trace statistics
# Usage: make trace-stats LOG=<path.btrc>
.PHONY: trace-stats
trace-stats:
ifndef LOG
	@echo "ERROR: LOG parameter required!"
	@echo ""
	@echo "Usage: make trace-stats LOG=<trace.btrc>"
	@exit 1
else
	python $(SCRIPTS_DIR)/bintrace_parser.py $(LOG) --stats
endif

# Compare two trace logs
# Usage: make compare-traces T1=trace1.csv T2=trace2.csv
.PHONY: compare-traces
compare-traces:
ifndef T1
	@echo "ERROR: T1 (first trace) parameter required!"
	@echo ""
	@echo "Usage: make compare-traces T1=<path> T2=<path> [EXEC_ONLY=1]"
	@exit 1
else ifndef T2
	@echo "ERROR: T2 (second trace) parameter required!"
	@exit 1
else
	python $(SCRIPTS_DIR)/compare_traces.py $(T1) $(T2) $(if $(EXEC_ONLY),--exec-only,)
endif
# Profile-aware debugger symbol exports and validation.

# Keep regional exports independent; JP retains the released default path.
ifeq ($(PROFILE),eu)
SYMBOLS_FILE = logs/symbols_eu.txt
SYMBOLS_REGION_ARGS = --profile eu --profile-address-map config/name_addresses_eu.json --origin-listing build/main.lst --profiles $(PROFILE_CONFIG)
else
SYMBOLS_FILE = logs/symbols.txt
SYMBOLS_REGION_ARGS = --profile jp
endif

# Generate symbol file from assembly listing
# Export one canonical symbol for every ROM, RAM, and hardware address.
.PHONY: symbols verify-symbols
symbols: $(LISTING)
	@python -c "import os; os.makedirs('logs', exist_ok=True)"
	@echo "Extracting symbols from $(LISTING)..."
	python $(SCRIPTS_DIR)/extract_symbols.py $(LISTING) \
		--stats --all --resolved-only -o $(if $(SYMBOLS),$(SYMBOLS),$(SYMBOLS_FILE))

verify-symbols: symbols
ifeq ($(PROFILE),eu)
	@$(MAKE) --no-print-directory build/main.lst PROFILE=jp
endif
	@$(PYTHON) $(SCRIPTS_DIR)/verify_symbols.py \
		--symbols $(if $(SYMBOLS),$(SYMBOLS),$(SYMBOLS_FILE)) \
		--listing $(LISTING) \
		--name-audit config/name_audit.json \
		--layout $(ROM_LAYOUT) \
		--runtime $(RUNTIME_SCENARIOS) \
		--minimum 15000 --resolved-exports $(SYMBOLS_REGION_ARGS)
# The command summary, then every public target grouped by file.

# Help
.PHONY: help
help:
	@echo "Alien Soldier JP/EU source and authoring"
	@echo ""
	@echo "Build and verify (PROFILE=jp by default, PROFILE=eu for Europe):"
	@echo "  make init               - Extract the data from your original cartridge"
	@echo "  make build              - Assemble the ROM (default)"
	@echo "  make verify             - Build and require the original cartridge byte for byte"
	@echo "  make verify-all         - verify for both cartridges"
	@echo "  make verify-relocation  - Perturb the layout; every pointer must follow"
	@echo "  make verify-symbols     - Export and check the debugger symbols"
	@echo "  make compare            - Compare the built ROM with the original"
	@echo "  make check-assets       - Check the extracted data against its manifest"
	@echo "  make verify-toolchain   - Hash-check the assembler and pin the emulator"
	@echo "  make split              - Extract data from the original ROM again"
	@echo "  make clean              - Remove build output; keep extracted data"
	@echo ""
	@echo "Checks:"
	@echo "  make lint               - Assembly style, source policy and project hygiene"
	@echo "  make test               - Every test module, TEST_JOBS at a time"
	@echo "  make check-content      - Every content model and Studio against both cartridges"
	@echo "  make runtime-capture    - Twelve Japanese scenarios in the pinned emulator"
	@echo "  make release-check      - All of the above from a clean build"
	@echo ""
	@echo "Content studios (CONTENT_PROFILE=jp by default, CONTENT_PROFILE=eu for Europe):"
	@echo "  make init-content               - Initialize missing workspace files"
	@echo "  make inspect-content            - Report edited workspace artifacts"
	@echo "  make validate-content           - Validate the workspace"
	@echo "  make build-content              - Build an edited ROM into build/content"
	@echo "  make check-content-zero-edit    - An unedited workspace must build both cartridges"
	@echo ""
	@echo "Watching a movie (requires MOVIE=tas|longplay|menus):"
	@echo "  make play MOVIE=tas                       - Watch it, on $(ROM)"
	@echo "  make play MOVIE=tas ROM=<image>           - Watch it on another image"
	@echo "  make play MOVIE=longplay TURBO=1 MUTE=1   - Faster, silent"
	@echo ""
	@echo "Analysis workflow (requires MOVIE=tas|longplay|menus):"
	@echo "  1. make find-unanalyzed        - Queue hypothesis-level code for review"
	@echo "  2. make reference MOVIE=tas    - Generate reference screenshots"
	@echo "  3. make analyze MOVIE=tas      - Explore candidates (one worker by default)"
	@echo "  4. make report MOVIE=tas       - Generate analysis report"
	@echo ""
	@echo "Documentation workflow (Claude + human):"
	@echo "  1. make set-movie MOVIE=tas    - Set movie type for workflow"
	@echo "  2. make prepare-batch COUNT=40 - Prepare batch of procedures"
	@echo "     -> Claude reads workflow/batch_procedures.txt"
	@echo "     -> Claude creates workflow/rename_batch.csv"
	@echo "  3. make rename                 - Apply renames and mark processed"
	@echo "  4. make verify"
	@echo "  5. git commit"
	@echo ""
	@echo "Debugging (visual + memory):"
	@echo "  1. make reference MOVIE=tas    - Generate reference"
	@echo "  2. [modify ROM and rebuild]"
	@echo "  3. make debug MOVIE=tas        - Collect 10 visual differences"
	@echo ""
	@echo "Debugging (pointer issues):"
	@echo "  make reference MOVIE=tas       - Generate reference (required first!)"
	@echo "  make verify-relocation        - Check pointers after moving code and data"
	@echo "     -> Static perturbation build only; no emulator or screenshot capture"
	@echo ""
	@echo "CPU tracing (binary format, ~10-50x smaller than text):"
	@echo "  make trace-frames MOVIE=tas START=100 END=110"
	@echo "     -> Outputs compact binary trace: logs/trace_100_110.btrc"
	@echo "  make trace-story LOG=logs/trace_100_110.btrc"
	@echo "     -> Human-readable story log: logs/trace_100_110_story.txt"
	@echo "  make trace-graph LOG=logs/trace_100_110.btrc MODE=pointers"
	@echo "     -> Graphviz DOT: logs/trace_100_110_pointers.dot"
	@echo "  make trace-graph LOG=logs/trace_100_110.btrc MODE=dma"
	@echo "     -> Graphviz DOT: logs/trace_100_110_dma.dot"
	@echo "  make trace-stats LOG=logs/trace_100_110.btrc"
	@echo "     -> Print trace statistics"
	@echo ""
	@echo "Utilities:"
	@echo "  make show-movie         - Show current movie setting"
	@echo "  make stop               - Stop all running Gens emulators"
	@echo "  make build-gens         - Build Gens emulator (VS2022)"
	@echo ""
	@echo "MOVIE types: tas, longplay, menus"
	@echo "Workflow dir: $(WORKFLOW_DIR)/"
	@$(PYTHON) -B $(SCRIPTS_DIR)/make_interface.py --list

# Everything a release needs, in order: the inputs, the tests, both cartridges
# rebuilt from a clean tree, their symbols and relocation, the content
# pipeline, then the game itself in the pinned emulator (twelve Japanese
# scenarios and the European boot).
release-check:
	@$(MAKE) --no-print-directory check-assets PROFILE=jp
	@$(MAKE) --no-print-directory check-assets PROFILE=eu
	@$(MAKE) --no-print-directory lint
	@$(MAKE) --no-print-directory test
	@$(MAKE) --no-print-directory clean
	@$(MAKE) --no-print-directory verify-all
	@$(MAKE) --no-print-directory verify-symbols verify-relocation PROFILE=jp
	@$(MAKE) --no-print-directory verify-symbols verify-relocation PROFILE=eu
	@$(MAKE) --no-print-directory check-content-zero-edit
	@$(MAKE) --no-print-directory check-content
	@$(MAKE) --no-print-directory runtime-capture PROFILE=jp

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
.PHONY: all build verify verify-all check-assets update-asset-manifest verify-toolchain verify-layout verify-relocation format lint test runtime runtime-capture runtime-validate release-check profile-info check-profile-ready derive-eu-assets derive-eu-layout init-content init-content-all inspect-content validate-content validate-content-all build-content check-content check-content-zero-edit check-level-model level-studio playtest-level check-graphics-models check-graphics-workspace graphics-studio screen-studio text-studio sound-studio
all: build

include mk/preservation.mk
include mk/authoring.mk
include mk/validation.mk
include mk/runtime.mk
include mk/workflow.mk
include mk/tracing.mk
include mk/symbols.mk
include mk/help.mk

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
	@$(MAKE) --no-print-directory check-region-runtime-eu PROFILE=eu

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
verify: check-profile-as-args check-profile-ready check-init check-assets verify-toolchain verify-z80-source
	@$(PYTHON) $(SCRIPTS_DIR)/build_rom.py \
		--source $(SRC) \
		--obj $(OBJ) \
		--output $(ROM) \
		--manifest $(ASSET_MANIFEST) \
		--original-rom "$(ORIG_ROM)" \
		--as-bin $(AS_BIN) \
		--p2bin $(P2BIN) \
		--as-args="$(PRESERVATION_AS_ARGS)" \
		--verify
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
.PHONY: verify-z80-source
build/z80/driver.bin: $(wildcard src/sound/z80/*.asm) scripts/build_z80.py | check-profile-as-args
	@$(PYTHON) -B scripts/build_z80.py --as-bin "$(AS_BIN)" --p2bin "$(P2BIN)"

verify-z80-source: check-profile-as-args
	@$(PYTHON) -B scripts/build_z80.py --as-bin "$(AS_BIN)" --p2bin "$(P2BIN)" --verify

$(LISTING): build/z80/driver.bin $(wildcard src/*.s src/*/*.s src/*.inc) | check-profile-as-args
	@echo "Building listing file..."
	@python -c "import os; os.makedirs('build', exist_ok=True)"
	$(AS_BIN) -i . -L -olist $(LISTING) -o $(OBJ) $(PRESERVATION_AS_ARGS) $(SRC)

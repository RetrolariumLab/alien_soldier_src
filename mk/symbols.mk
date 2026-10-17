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

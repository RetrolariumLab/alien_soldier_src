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

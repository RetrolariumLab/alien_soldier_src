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

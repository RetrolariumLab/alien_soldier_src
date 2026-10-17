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

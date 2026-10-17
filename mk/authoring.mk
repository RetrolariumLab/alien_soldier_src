# Content: the workspace, its models, the five Studios and the content build.

.PHONY: init-content init-content-all inspect-content validate-content validate-content-all \
	build-content check-content-zero-edit check-level-model check-level-map-model \
	check-map-references check-level-studio level-studio playtest-level graphics-inventory \
	art-validate palette-validate mapping-validate tilemap-validate check-graphics-models \
	check-screen-model check-screen-workspace check-screen-studio screen-studio \
	check-text-workspace migrate-credits-text check-text-studio text-studio \
	check-sound-model check-sound-workspace check-sound-studio sound-studio \
	check-stage-message-model check-scripted-message-model check-credits-text-model \
	check-glyph-source-list-model check-graphics-workspace \
	check-compressed-graphics-workspace check-tile-codec-rom-edit check-palette-workspace \
	check-mapping-workspace check-animation-workspace check-graphics-studio graphics-studio

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

.PHONY: check-map-references
check-map-references:
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/check_map_references.py --profile all

check-level-studio: init-content-all
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/level_studio.py --check --profile jp
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/level_studio.py --check --profile eu

level-studio: init-content
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/level_studio.py \
		--profile $(CONTENT_PROFILE) --stage $(or $(STAGE_INDEX),0)

playtest-level: verify-runtime-toolchain build-content
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/level_playtest.py \
		--gens "$(GENS_EXE)" --rom "$(CONTENT_ROM)" \
		--profile $(CONTENT_PROFILE) --stage $(PLAYTEST_STAGE) \
		--difficulty $(PLAYTEST_DIFFICULTY)

graphics-inventory:
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/graphics_inventory.py

art-validate:
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/tile_art.py validate

palette-validate:
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/palettes.py validate

mapping-validate:
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/sprite_mappings.py validate

tilemap-validate:
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/stage_tilemaps.py validate

check-graphics-models: graphics-inventory art-validate palette-validate mapping-validate tilemap-validate

check-screen-model:
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/screen_studio_model.py check --profile jp
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/screen_studio_model.py check --profile eu

check-screen-workspace:
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/screen_map_model.py check --profile jp
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/screen_map_model.py check --profile eu

check-screen-studio: init-content-all
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/screen_studio.py --check --profile jp
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/screen_studio.py --check --profile eu

screen-studio: init-content
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/screen_studio.py \
		--profile $(CONTENT_PROFILE) --screen $(or $(SCREEN_ID),title_background)

check-text-workspace:
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/japanese_glyph_model.py check --profile jp
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/japanese_glyph_model.py check --profile eu
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/credits_text_model.py check --profile jp
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/credits_text_model.py check --profile eu
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/frontend_text_model.py check --profile jp
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/frontend_text_model.py check --profile eu
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/results_text_model.py check --profile jp
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/results_text_model.py check --profile eu
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/glyph_source_list_model.py check --profile jp
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/glyph_source_list_model.py check --profile eu
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/scripted_message_model.py check --profile jp
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/scripted_message_model.py check --profile eu
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/stage_message_model.py check --profile jp
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/stage_message_model.py check --profile eu
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/story_text_model.py check --profile jp
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/story_text_model.py check --profile eu

.PHONY: migrate-credits-text
migrate-credits-text:
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/credits_text_model.py migrate \
		--profile $(CONTENT_PROFILE) \
		--document content/workspace/$(CONTENT_PROFILE)/text/credits_sequence.json

check-text-studio: init-content-all
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/text_studio.py --check --profile jp
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/text_studio.py --check --profile eu

text-studio: init-content
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/text_studio.py --profile $(CONTENT_PROFILE)

check-sound-model:
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/sound_studio_model.py check --profile jp
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/sound_studio_model.py check --profile eu

check-sound-workspace:
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/sound_envelope_model.py check --profile jp
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/sound_envelope_model.py check --profile eu
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/sound_instrument_model.py check --profile jp
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/sound_instrument_model.py check --profile eu
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/sound_pcm_model.py check --profile jp
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/sound_pcm_model.py check --profile eu
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/sound_pcm_codec.py check --profile jp
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/sound_pcm_codec.py check --profile eu
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/sound_sequence_model.py check --profile jp
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/sound_sequence_model.py check --profile eu

check-sound-studio: init-content-all
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/sound_studio.py --check --profile jp
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/sound_studio.py --check --profile eu

sound-studio: init-content
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/sound_studio.py --profile $(CONTENT_PROFILE) --gens "$(GENS_EXE)"

# Play one music or sound request through the cartridge's own driver, on the
# saved workspace: make audition-sound SOUND_REQUEST=0x81
.PHONY: build-content-runtime audition-sound
build-content-runtime: verify-runtime-toolchain
	@$(MAKE) --no-print-directory build-content CONTENT_PROFILE=$(CONTENT_PROFILE) \
		AS_ARGS='-q -maxerrors 2' CONTENT_LISTING="$(SOUND_LISTING)"

audition-sound: build-content-runtime
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/sound_audition.py \
		--profile $(CONTENT_PROFILE) --request $(SOUND_REQUEST) --frames $(SOUND_FRAMES) \
		--rom "$(CONTENT_ROM)" --listing "$(SOUND_LISTING)" --gens "$(GENS_EXE)"

# Write a migrated copy of an older screen workspace; the original stays.
.PHONY: migrate-screen-workspace
migrate-screen-workspace:
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/screen_map_model.py migrate-story-plane \
		--profile $(CONTENT_PROFILE) --document content/workspace/$(CONTENT_PROFILE)/screens/maps.json \
		--output $(or $(MIGRATION_OUTPUT),build/content/$(CONTENT_PROFILE)/story-plane-migrated.json)

check-stage-message-model:
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/stage_message_model.py check --profile jp
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/stage_message_model.py check --profile eu

check-scripted-message-model:
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/scripted_message_model.py check --profile jp
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/scripted_message_model.py check --profile eu

check-credits-text-model:
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/credits_text_model.py check --profile jp
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/credits_text_model.py check --profile eu

check-glyph-source-list-model:
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/glyph_source_list_model.py check --profile jp
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/glyph_source_list_model.py check --profile eu

check-graphics-workspace: check-compressed-graphics-workspace check-palette-workspace check-mapping-workspace check-animation-workspace
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/graphics_studio_model.py check --profile jp
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/graphics_studio_model.py check --profile eu

check-compressed-graphics-workspace:
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/compressed_graphics_model.py check --profile jp
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/compressed_graphics_model.py check --profile eu

.PHONY: check-tile-codec-rom-edit
check-tile-codec-rom-edit:
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/check_tile_codec_rom.py --profile all \
		--as-bin $(AS_BIN) --p2bin $(P2BIN)

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

check-graphics-studio: init-content-all
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/graphics_studio.py --check --profile jp
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/graphics_studio.py --check --profile eu

graphics-studio: init-content
	@$(PYTHON) $(SCRIPTS_DIR)/authoring/graphics_studio.py \
		--profile $(CONTENT_PROFILE) --payload $(or $(GRAPHICS_PAYLOAD),0)

# Every content model, workspace and Studio check against both cartridges.
.PHONY: check-content
check-content: init-content-all
	@$(MAKE) --no-print-directory check-map-references check-level-model \
		check-level-map-model check-level-studio check-graphics-models \
		check-graphics-workspace check-graphics-studio check-screen-model \
		check-screen-workspace check-screen-studio check-text-workspace \
		check-text-studio check-sound-model check-sound-workspace check-sound-studio

extends "res://tests/test_base.gd"

# 11-phone-os-shell ticket 02: standalone tests for the app-tile component,
# exercised directly via configure() rather than through a live app grid
# (ticket 07 wires an actual grid later) — same "component testable before
# any screen uses it" split tests/test_map_bubble.gd documents for MapBubble.
#
# AppTile.new()/_ready() is safe to call directly without adding it to a
# live scene tree, same reasoning tests/test_map_bubble.gd/test_bag_drawer.gd
# already rely on: nothing _ready() touches (UI.*, plain Control/TextureRect/
# Label construction) depends on get_tree()/get_viewport() having run.


func _synthetic_tap() -> InputEventScreenTouch:
	var event := InputEventScreenTouch.new()
	event.pressed = true
	return event


func run() -> void:
	run_case("a_provided_icon_texture_renders_and_hides_the_text_fallback", func():
		var tile := AppTile.new()
		tile._ready()

		var texture := PlaceholderTexture2D.new()
		tile.configure({ "id": "messages", "label": "Messages", "icon": texture })

		assert_true(tile._icon_rect.visible, "the icon texture is shown")
		assert_eq(tile._icon_rect.texture, texture, "the provided texture is the one rendered")
		assert_true(not tile._fallback_label.visible, "the text fallback is hidden when art is present")

		tile.free()
	)

	run_case("a_missing_icon_falls_back_to_the_apps_own_label_instead_of_failing_to_render", func():
		var tile := AppTile.new()
		tile._ready()

		# No asset exists at the contract path for this id (docs/adr/
		# 0003-app-icon-asset-contract.md) — ResourceLoader.exists() is false,
		# so this exercises the real load_icon() miss, not a stubbed one.
		tile.configure({ "id": "does_not_exist_yet", "label": "Coming Soon" })

		assert_true(not tile._icon_rect.visible, "no texture is rendered when the art is absent")
		assert_true(tile._fallback_label.visible, "a legible text fallback is shown instead")
		assert_eq(tile._fallback_label.text, "Coming Soon", "the fallback shows the app's own label")

		tile.free()
	)

	# 09-family-2-chrome-phone-apps, ui-vision.md §10 implementation note:
	# reversed from the pre-Family-2 behaviour this test used to assert --
	# real icon art is now expected to be a full, self-contained square with
	# its own background baked in, so the frame panel would peek through any
	# transparent corners if drawn behind it. It's suppressed once real art
	# exists; a label-fallback tile keeps its dark chip so the fallback text
	# stays legible.
	run_case("the_background_frame_is_suppressed_once_real_icon_art_is_present", func():
		var with_art := AppTile.new()
		with_art._ready()
		with_art.configure({ "id": "messages", "label": "Messages", "icon": PlaceholderTexture2D.new() })

		assert_true(is_instance_valid(with_art._background), "the background node still exists")
		assert_true(not with_art._background.visible, "the background panel is suppressed once real icon art is present")

		with_art.free()

		var without_art := AppTile.new()
		without_art._ready()
		without_art.configure({ "id": "does_not_exist_yet", "label": "Coming Soon" })

		assert_true(is_instance_valid(without_art._background), "a background node exists even without real icon art")
		assert_true(without_art._background.visible, "the background stays visible when falling back to text, so the fallback label reads against a dark chip")

		without_art.free()
	)

	run_case("the_background_frame_tints_locked_the_same_as_the_rest_of_the_tile", func():
		var tile := AppTile.new()
		tile._ready()

		tile.configure({ "id": "map", "label": "Map", "locked": true })
		assert_eq(tile._background.modulate, AppTile.LOCKED_TINT, "the background greys out to the locked tint")

		tile.configure({ "id": "map", "label": "Map", "locked": false })
		assert_eq(tile._background.modulate, AppTile.NORMAL_TINT, "the background returns to full colour when unlocked")

		tile.free()
	)

	run_case("a_locked_tile_shows_the_padlock_overlay_and_greys_out", func():
		var tile := AppTile.new()
		tile._ready()

		tile.configure({ "id": "map", "label": "Map", "locked": true })

		assert_true(tile._lock_overlay.visible, "the padlock overlay is shown")
		assert_eq(tile._name_label.modulate, AppTile.LOCKED_TINT, "the label greys out to the locked tint")
		assert_eq(tile._fallback_label.modulate, AppTile.LOCKED_TINT, "the icon frame greys out to the locked tint")

		tile.free()
	)

	run_case("an_unlocked_tile_has_no_padlock_overlay_and_normal_colour", func():
		var tile := AppTile.new()
		tile._ready()

		tile.configure({ "id": "map", "label": "Map", "locked": false })

		assert_true(not tile._lock_overlay.visible, "no padlock overlay when unlocked")
		assert_eq(tile._name_label.modulate, AppTile.NORMAL_TINT, "the label is full colour when unlocked")

		tile.free()
	)

	run_case("a_locked_tile_still_occupies_its_normal_slot_rather_than_being_hidden", func():
		var tile := AppTile.new()
		tile._ready()

		tile.configure({ "id": "map", "label": "Map", "locked": true })

		assert_true(tile.visible, "the tile itself is never hidden for being locked")
		assert_true(tile.custom_minimum_size.x > 0 and tile.custom_minimum_size.y > 0, "the tile keeps its normal grid footprint")

		tile.free()
	)

	run_case("a_badge_dot_renders_when_requested", func():
		var tile := AppTile.new()
		tile._ready()

		tile.configure({ "id": "messages", "label": "Messages", "badge": true })

		assert_true(tile._badge.visible, "the badge dot is shown")

		tile.free()
	)

	run_case("no_badge_dot_by_default", func():
		var tile := AppTile.new()
		tile._ready()

		tile.configure({ "id": "messages", "label": "Messages" })

		assert_true(not tile._badge.visible, "no badge dot when the caller doesn't request one")

		tile.free()
	)

	run_case("tapping_the_tile_emits_tile_pressed_with_its_app_id", func():
		var tile := AppTile.new()
		tile._ready()
		tile.configure({ "id": "notes", "label": "Notes" })

		var pressed_ids := []
		tile.tile_pressed.connect(func(app_id): pressed_ids.append(app_id))

		tile._on_gui_input(_synthetic_tap())

		assert_eq(pressed_ids, ["notes"], "tapping the tile identifies which app it is")

		tile.free()
	)

	run_case("a_release_event_does_not_emit_tile_pressed", func():
		var tile := AppTile.new()
		tile._ready()
		tile.configure({ "id": "notes", "label": "Notes" })

		var pressed_ids := []
		tile.tile_pressed.connect(func(app_id): pressed_ids.append(app_id))

		var release := InputEventScreenTouch.new()
		release.pressed = false
		tile._on_gui_input(release)

		assert_eq(pressed_ids, [], "a release event doesn't count as a tap")

		tile.free()
	)

	run_case("an_active_tile_highlights_its_frame_style_distinct_from_the_default", func():
		var tile := AppTile.new()
		tile._ready()

		tile.configure({ "id": "map", "label": "Map", "active": true })

		assert_eq(tile._frame_style.bg_color, AppTile.ACTIVE_BG_COLOUR, "the active tile's frame fills with the accent tint")
		assert_eq(tile._frame_style.border_color, AppTile.ACTIVE_BORDER_COLOUR, "the active tile's frame border switches to the accent colour")
		assert_eq(tile._frame_style.border_width_left, AppTile.ACTIVE_BORDER_WIDTH, "the active tile's border thickens to read as the current tab")

		tile.free()
	)

	run_case("an_inactive_tile_keeps_the_default_frame_style", func():
		var tile := AppTile.new()
		tile._ready()

		tile.configure({ "id": "map", "label": "Map", "active": false })

		assert_eq(tile._frame_style.bg_color, AppTile.FRAME_BG_COLOUR, "an inactive tile keeps the ordinary frame background")
		assert_eq(tile._frame_style.border_color, AppTile.FRAME_BORDER_COLOUR, "an inactive tile keeps the ordinary frame border")

		tile.free()
	)

	# ── 09-family-2-chrome-phone-apps, ui-vision.md §10 ──────────────────

	run_case("the_fallback_label_and_name_label_use_family2_light_ink", func():
		var tile := AppTile.new()
		tile._ready()
		tile.configure({ "id": "does_not_exist_yet", "label": "Coming Soon" })

		assert_eq(tile._fallback_label.get_theme_color("font_color"), GameData.PALETTE["phone_text_primary"], "the fallback label must read against the dark device shell, not the engine's default near-black ink")
		assert_eq(tile._name_label.get_theme_color("font_color"), GameData.PALETTE["phone_text_primary"], "the tile's own name label is repainted the same way")

		tile.free()
	)

	run_case("the_badge_dot_colour_is_locked_to_the_exact_ui_action_red_hex", func():
		assert_eq(AppTile.BADGE_COLOUR, GameData.PALETTE["ui_action_red"], "the badge dot must match ui_action_red exactly, not a close approximation")
	)

	run_case("the_default_frame_colour_matches_the_phone_bg_home_palette_entry", func():
		var tile := AppTile.new()
		tile._ready()
		tile.configure({ "id": "does_not_exist_yet", "label": "Coming Soon" })

		assert_eq(tile._frame_style.bg_color, GameData.PALETTE["phone_bg_home"], "a fallback tile's chip is the Family 2 home-grid ground colour")

		tile.free()
	)

	run_case("active_defaults_to_false_when_omitted", func():
		var tile := AppTile.new()
		tile._ready()

		tile.configure({ "id": "map", "label": "Map" })

		assert_eq(tile._frame_style.bg_color, AppTile.FRAME_BG_COLOUR, "no active flag means the default, unhighlighted frame")

		tile.free()
	)

	# 119-phone-home-grid-tiles-overlap: see _ensure_built()'s own comment on
	# _icon_rect.expand_mode (above, in app_tile.gd) for why this matters.
	# Checked directly against the icon_rect's own configuration here rather
	# than rendered pixel geometry (which needs a live, laid-out tree -- see
	# tests/test_phone_home_grid.gd's own live-tree case for that level).
	run_case("the_icon_rect_never_grows_past_its_frame_regardless_of_the_source_textures_native_size", func():
		var tile := AppTile.new()
		tile._ready()

		assert_eq(tile._icon_rect.expand_mode, TextureRect.EXPAND_IGNORE_SIZE, "expand_mode must not default to EXPAND_KEEP_SIZE, or a real icon's native pixel size becomes this rect's minimum size and blows out past the tile")

		tile.free()
	)

	# 120-app-icon-rounded-mask: COVERED crops non-square art to fill the
	# frame edge-to-edge like a real phone icon; CENTERED would letterbox it
	# and leave frame background showing around the art.
	run_case("the_icon_rect_crops_to_fill_its_frame_rather_than_letterboxing", func():
		var tile := AppTile.new()
		tile._ready()

		assert_eq(tile._icon_rect.stretch_mode, TextureRect.STRETCH_KEEP_ASPECT_COVERED, "non-square art must crop to fill the icon frame, not shrink to fit inside it with visible gaps")

		tile.free()
	)

	# 120-app-icon-rounded-mask: real icon art is a plain square PNG with no
	# rounded corners of its own (see the ticket) -- AppTile must clip/mask
	# _icon_rect itself to the frame's rounded-rect shape rather than relying
	# on art baking that in. Pixel-level corner inspection isn't available
	# headless, so this asserts the mechanism (a ShaderMaterial applied,
	# sized/radiused to match the frame it's clipping) rather than pixels.
	run_case("the_icon_rect_is_masked_to_a_rounded_rect_matching_the_frame", func():
		var tile := AppTile.new()
		tile._ready()

		var big_texture := PlaceholderTexture2D.new()
		big_texture.size = Vector2(512, 512)
		tile.configure({ "id": "property", "label": "Harrow's", "icon": big_texture })

		assert_true(tile._icon_rect.material is ShaderMaterial, "the icon is clipped via a shader mask, not left to the raw texture's own corners")
		var mat: ShaderMaterial = tile._icon_rect.material
		assert_eq(mat.get_shader_parameter("mask_size"), Vector2(AppTile.FRAME_SIZE, AppTile.FRAME_SIZE), "the mask is sized to the dock frame")
		assert_eq(mat.get_shader_parameter("corner_radius"), float(AppTile.FRAME_CORNER_RADIUS), "the mask radius matches the dock frame's own corner radius")

		tile.free()

		var large_tile := AppTile.new(true)
		large_tile._ready()
		large_tile.configure({ "id": "property", "label": "Harrow's", "icon": big_texture })

		var large_mat: ShaderMaterial = large_tile._icon_rect.material
		assert_eq(large_mat.get_shader_parameter("mask_size"), Vector2(AppTile.LARGE_FRAME_SIZE, AppTile.LARGE_FRAME_SIZE), "the mask is sized to the large home-grid frame")
		assert_eq(large_mat.get_shader_parameter("corner_radius"), float(AppTile.LARGE_FRAME_CORNER_RADIUS), "the mask radius matches the large frame's own corner radius")

		large_tile.free()
	)

	run_case("reconfigure_replaces_the_previous_state_rather_than_accumulating_it", func():
		var tile := AppTile.new()
		tile._ready()

		tile.configure({ "id": "messages", "label": "Messages", "locked": true, "badge": true, "active": true })
		# "not_yet_drawn": no real art file, same as "messages" above -- keeps
		# this case on the fallback path so _frame_style is actually
		# recomputed (and not just left stale from the first, active
		# configure()) by the second call, same reasoning app_tile.gd's own
		# suppression comment documents. "notes" itself now has real art
		# (08-family-2-chrome-contacts) and would exercise a different path.
		tile.configure({ "id": "not_yet_drawn", "label": "Notes", "locked": false, "badge": false, "active": false })

		assert_true(not tile._lock_overlay.visible, "locked state from the first configure() doesn't linger")
		assert_true(not tile._badge.visible, "badge state from the first configure() doesn't linger")
		assert_eq(tile._frame_style.bg_color, AppTile.FRAME_BG_COLOUR, "active state from the first configure() doesn't linger")
		assert_eq(tile._name_label.text, "Notes", "the label reflects the latest configure() call")

		tile.free()
	)

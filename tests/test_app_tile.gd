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

	run_case("the_background_frame_renders_regardless_of_icon_art_presence", func():
		var with_art := AppTile.new()
		with_art._ready()
		with_art.configure({ "id": "messages", "label": "Messages", "icon": PlaceholderTexture2D.new() })

		assert_true(is_instance_valid(with_art._background), "a background node exists even with real icon art")
		assert_true(with_art._background.visible, "the background is visible when icon art is present")

		with_art.free()

		var without_art := AppTile.new()
		without_art._ready()
		without_art.configure({ "id": "does_not_exist_yet", "label": "Coming Soon" })

		assert_true(is_instance_valid(without_art._background), "a background node exists even without real icon art")
		assert_true(without_art._background.visible, "the background is visible when falling back to text")

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

	run_case("reconfigure_replaces_the_previous_state_rather_than_accumulating_it", func():
		var tile := AppTile.new()
		tile._ready()

		tile.configure({ "id": "messages", "label": "Messages", "locked": true, "badge": true })
		tile.configure({ "id": "notes", "label": "Notes", "locked": false, "badge": false })

		assert_true(not tile._lock_overlay.visible, "locked state from the first configure() doesn't linger")
		assert_true(not tile._badge.visible, "badge state from the first configure() doesn't linger")
		assert_eq(tile._name_label.text, "Notes", "the label reflects the latest configure() call")

		tile.free()
	)

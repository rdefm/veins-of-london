extends "res://tests/test_base.gd"

# 10-map-interaction-model ticket 02: the standalone anchored bubble/popup
# component, exercised directly (open()/close(), synthetic taps) rather than
# through a live map tap -- tickets 03/04 wire an actual tap flow into this
# later.
#
# MapBubble.new() is safe to call _ready() on directly without adding it to a
# live scene tree, same reasoning tests/test_map_controls.gd already relies
# on for MapControls: nothing _ready() touches (UI.*, ColorRect/PanelContainer/
# VBoxContainer construction) depends on get_tree()/get_viewport() having run.


func _synthetic_tap() -> InputEventScreenTouch:
	var event := InputEventScreenTouch.new()
	event.pressed = true
	return event


func run() -> void:
	run_case("open_renders_one_row_per_option_and_shows_the_panel", func():
		var bubble := MapBubble.new()
		bubble._ready()

		bubble.open(Vector2(100, 100), [
			{ "id": "prospect", "label": "Prospect" },
			{ "id": "view", "label": "View Veins" },
		], Vector2(390, 844))

		assert_true(bubble.visible, "the popup itself is visible after open()")
		assert_eq(bubble._content.get_child_count(), 2, "one row per option")

		bubble.free()
	)

	run_case("tapping_an_option_emits_option_selected_with_its_id_and_closes_the_popup", func():
		var bubble := MapBubble.new()
		bubble._ready()
		bubble.open(Vector2(100, 100), [
			{ "id": "cultivate", "label": "Cultivate" },
			{ "id": "harvest", "label": "Harvest" },
		], Vector2(390, 844))

		var selected := []
		bubble.option_selected.connect(func(id): selected.append(id))

		var row := bubble._content.get_child(1)
		var button := row.get_child(0) as Button
		assert_eq(button.text, "Harvest", "the second row's button is the second option")
		button.pressed.emit()

		assert_eq(selected, ["harvest"], "tapping a row's button identifies which option was tapped")
		assert_true(not bubble.visible, "selecting an option closes the popup")

		bubble.free()
	)

	run_case("tapping_outside_the_popup_closes_it_without_selecting_anything", func():
		var bubble := MapBubble.new()
		bubble._ready()
		bubble.open(Vector2(100, 100), [{ "id": "a", "label": "A" }], Vector2(390, 844))

		var selected := []
		bubble.option_selected.connect(func(id): selected.append(id))
		var closed_count := [0]
		bubble.closed.connect(func(): closed_count[0] += 1)

		bubble._on_dim_gui_input(_synthetic_tap())

		assert_true(not bubble.visible, "outside tap closes the popup")
		assert_eq(selected, [], "no option was selected")
		assert_eq(closed_count[0], 1, "closed signal fires")

		bubble.free()
	)

	run_case("a_release_event_on_the_dim_does_not_close_the_popup", func():
		var bubble := MapBubble.new()
		bubble._ready()
		bubble.open(Vector2(100, 100), [{ "id": "a", "label": "A" }], Vector2(390, 844))

		var release := InputEventScreenTouch.new()
		release.pressed = false
		bubble._on_dim_gui_input(release)

		assert_true(bubble.visible, "a release event doesn't dismiss the popup")

		bubble.free()
	)

	run_case("a_disabled_option_is_shown_disabled_with_its_reason_rather_than_hidden", func():
		var bubble := MapBubble.new()
		bubble._ready()
		bubble.open(Vector2(100, 100), [
			{ "id": "prospect", "label": "Prospect", "disabled": true, "reason": "Site cap reached" },
		], Vector2(390, 844))

		var row := bubble._content.get_child(0)
		var button := row.get_child(0) as Button
		assert_true(button.disabled, "the option row's button is disabled")
		assert_eq(row.get_child_count(), 2, "a reason label is added alongside the disabled button, not instead of the row")

		bubble.free()
	)

	run_case("an_enabled_option_has_no_reason_row", func():
		var bubble := MapBubble.new()
		bubble._ready()
		bubble.open(Vector2(100, 100), [{ "id": "a", "label": "A" }], Vector2(390, 844))

		var row := bubble._content.get_child(0)
		assert_eq(row.get_child_count(), 1, "no reason label when the option isn't disabled")

		bubble.free()
	)

	run_case("an_option_with_an_icon_callable_renders_a_glyph_alongside_its_label", func():
		var bubble := MapBubble.new()
		bubble._ready()
		bubble.open(Vector2(100, 100), [
			{ "id": "home", "label": "Home", "icon": Icons.draw_home },
		], Vector2(390, 844))

		var row := bubble._content.get_child(0)
		var button := row.get_child(0) as Button
		# Icon buttons wrap an inner HBoxContainer (icon glyph + label) rather
		# than setting Button.text directly, same as UI.icon_button()'s glyph
		# approach -- see UI.gd's own header comment on why raw glyph text
		# doesn't render on the exported build's font.
		assert_eq(button.get_child_count(), 1, "the icon+label row is a single child of the button")

		bubble.free()
	)

	run_case("tapping_an_icon_option_still_identifies_which_option_was_tapped", func():
		var bubble := MapBubble.new()
		bubble._ready()
		bubble.open(Vector2(100, 100), [
			{ "id": "manage", "label": "Manage", "icon": Icons.draw_padlock },
		], Vector2(390, 844))

		var selected := []
		bubble.option_selected.connect(func(id): selected.append(id))

		var row := bubble._content.get_child(0)
		var button := row.get_child(0) as Button
		button.pressed.emit()

		assert_eq(selected, ["manage"], "icon options fire the same option_selected contract as text-only ones")

		bubble.free()
	)

	run_case("closing_an_already_closed_popup_does_not_re_emit_closed", func():
		var bubble := MapBubble.new()
		bubble._ready()

		var closed_count := [0]
		bubble.closed.connect(func(): closed_count[0] += 1)

		bubble.close()

		assert_eq(closed_count[0], 0, "close() on a popup that was never open is a no-op, not a spurious signal")

		bubble.free()
	)

	run_case("reopening_with_a_new_option_list_replaces_the_old_rows", func():
		var bubble := MapBubble.new()
		bubble._ready()
		bubble.open(Vector2(0, 0), [
			{ "id": "a", "label": "A" }, { "id": "b", "label": "B" }, { "id": "c", "label": "C" },
		], Vector2(390, 844))
		assert_eq(bubble._content.get_child_count(), 3)

		bubble.open(Vector2(200, 200), [{ "id": "x", "label": "X" }], Vector2(390, 844))
		assert_eq(bubble._content.get_child_count(), 1, "the old rows are torn down, not accumulated")

		bubble.free()
	)

	run_case("the_popup_panel_is_positioned_via_bubble_layout_and_never_off_screen", func():
		var bounds := Vector2(390, 844)
		var bubble := MapBubble.new()
		bubble._ready()

		# Anchored right at the bottom-right corner -- the popup must still
		# land fully inside `bounds`, exercising the same clamp
		# tests/test_bubble_layout.gd checks in isolation, now wired through
		# a real MapBubble.
		bubble.open(bounds, [
			{ "id": "a", "label": "A" }, { "id": "b", "label": "Longer option label" },
		], bounds)

		var panel_size: Vector2 = bubble._panel.size
		var panel_pos: Vector2 = bubble._panel.position
		assert_true(panel_pos.x >= BubbleLayout.EDGE_MARGIN - 0.01, "left edge respects the margin")
		assert_true(panel_pos.y >= BubbleLayout.EDGE_MARGIN - 0.01, "top edge respects the margin")
		assert_true(panel_pos.x + panel_size.x <= bounds.x + 0.01, "right edge stays inside bounds")
		assert_true(panel_pos.y + panel_size.y <= bounds.y + 0.01, "bottom edge stays inside bounds")

		bubble.free()
	)

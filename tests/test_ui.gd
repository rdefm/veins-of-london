extends "res://tests/test_base.gd"

# UI.format_cost_label (D4.4) — the shared cost-label helper every
# cost-gated button routes through.


func run() -> void:
	run_case("ore_cost_label_matches_D4_4_example", func():
		var cost := { "label": "Seed", "resource": "physics", "amount": 40 }
		var holdings := { "physics": 52 }
		assert_eq(UI.format_cost_label(cost, holdings), "Seed — 40 physics (have 52)", "ore cost format")
	)

	run_case("cash_cost_label_matches_D4_4_example", func():
		var cost := { "label": "Bribe", "resource": "cash", "amount": 50 }
		var holdings := { "cash": 210 }
		assert_eq(UI.format_cost_label(cost, holdings), "Bribe — £50 (have £210)", "cash cost format")
	)

	run_case("missing_holding_defaults_to_zero", func():
		var cost := { "label": "Craft", "resource": "fate", "amount": 10 }
		assert_eq(UI.format_cost_label(cost, {}), "Craft — 10 fate (have 0)", "missing holdings key reads as 0")
	)

	run_case("empty_label_omits_the_dash", func():
		var cost := { "label": "", "resource": "cash", "amount": 5 }
		var holdings := { "cash": 5 }
		assert_eq(UI.format_cost_label(cost, holdings), "£5 (have £5)", "no label means no leading dash")
	)

	# ── block_cost_suffix / format_block_cost_label (D3 — travel is free,
	# faction-resource-economy ticket 05: no more travel surcharge or suffix) ──

	run_case("block_cost_suffix_singular_block", func():
		assert_eq(UI.block_cost_suffix(1), "1 block", "singular unit")
	)

	run_case("block_cost_suffix_plural_blocks", func():
		assert_eq(UI.block_cost_suffix(2), "2 blocks", "plural unit")
	)

	run_case("format_block_cost_label_matches_the_action_cost_with_no_travel_suffix", func():
		assert_eq(UI.format_block_cost_label("Harvest", 1), "Harvest — 1 block", "no travel surcharge — same cost regardless of district")
	)

	run_case("format_block_cost_label_default_action_blocks_is_one", func():
		assert_eq(UI.format_block_cost_label("Prospect"), "Prospect — 1 block", "default action cost is 1 block")
	)

	# Bugfixes ticket 05: a Button's minimum_size grows to fit its full text
	# by default, so one long dynamic label (e.g. a cost string built from a
	# huge cash balance) can force a whole card/sheet wider than the screen.
	# Every UI.button() must clip instead of demanding that width.
	run_case("button_clips_text_instead_of_growing_its_minimum_size", func():
		var b := UI.button("Upgrade to Basic Lock — £20 (have £1000000)", func(): pass)
		assert_true(b.clip_text, "clip_text must be on so a long label can't force its container wider than the screen")
		assert_eq(b.text_overrun_behavior, TextServer.OVERRUN_TRIM_ELLIPSIS, "clipped text should ellipsize, not cut off mid-character")
		b.free()
	)

	# Bugfixes ticket 08: clip_text (above) drops ALL of a button's text-driven
	# minimum width, not just the overflow past some cap — so a button placed
	# directly in a plain HBoxContainer (which sizes a non-expand child to
	# exactly its minimum size) collapsed to just its style padding, with zero
	# room left for the label to draw into. It read as fully blank rather than
	# ellipsized. UI.button() must reserve real width for its own text so this
	# can't happen regardless of which container it ends up in.
	run_case("button_reserves_real_width_for_its_text_not_just_padding", func():
		var b := UI.button("Travel", func(): pass)
		var style: StyleBox = preload("res://theme/main_theme.tres").get_stylebox("normal", "Button")
		var padding_only: float = style.get_minimum_size().x
		# get_combined_minimum_size() -- not custom_minimum_size directly -- is
		# what a HBoxContainer actually reads to size a non-expand child, so
		# this is the literal value that collapsed to padding-only before the fix.
		assert_true(b.get_combined_minimum_size().x > padding_only, "a short label must get room beyond bare padding, or it renders blank inside a bare HBoxContainer")
		b.free()
	)

	run_case("button_text_width_reservation_is_capped_for_long_labels", func():
		var b := UI.button("Upgrade to Basic Lock — £20 (have £1000000)", func(): pass)
		assert_true(b.custom_minimum_size.x <= UI.MAX_BUTTON_TEXT_WIDTH, "the width reserved for text must stay capped, or a huge dynamic label (bugfixes ticket 05) blows its container out again")
		b.free()
	)

	run_case("short_button_label_is_not_needlessly_capped", func():
		var b := UI.button("Travel", func(): pass)
		assert_true(b.custom_minimum_size.x < UI.MAX_BUTTON_TEXT_WIDTH, "an ordinary short label should get its own natural width, not be stretched out to the cap")
		b.free()
	)

	# Bugfixes ticket 13: icon-only buttons (map.gd's hamburger/bag) can't
	# fall back to Button.text the way UI.button() rows do -- there's no
	# text to fall back to, that's the whole bug this replaces. So the
	# glyph has to be a real drawn child, and a fixed touch target size
	# (rather than the text-derived width UI.button() computes) since
	# there's no text to measure.
	run_case("icon_button_has_no_text_and_a_fixed_touch_target", func():
		# GDScript lambdas capture outer locals by value, not reference, so
		# a plain `var pressed := false` mutated inside the callback would
		# never be visible out here -- an Array's contents, not the local
		# itself, are what has to be captured to observe the callback firing.
		var pressed := [false]
		var b := UI.icon_button(Icons.draw_bag, func(): pressed[0] = true)
		assert_eq(b.text, "", "an icon button must never carry a raw emoji/unicode glyph as Button.text")
		assert_eq(b.custom_minimum_size, Vector2(UI.ICON_BUTTON_SIZE, UI.ICON_BUTTON_SIZE), "fixed square touch target, since there's no text to size it from")
		assert_eq(b.get_child_count(), 1, "the drawn glyph must be a real child, or nothing shows at all")

		b.pressed.emit()
		assert_true(pressed[0], "the button must still fire its callback like any other button")

		b.free()
	)

	# Bugfixes ticket 16: PanelContainer defaults to MOUSE_FILTER_STOP, unlike
	# plain Container subclasses (PASS by default) -- a card built with the
	# engine default swallows a drag gesture before it reaches an ancestor
	# TouchScrollContainer's _gui_input(), so scrolling only worked from the
	# narrow gaps between cards, not from on top of one.
	run_case("card_panel_passes_input_through_instead_of_stopping_it", func():
		var c := UI.card()
		assert_eq(c["panel"].mouse_filter, Control.MOUSE_FILTER_PASS, "a card must not swallow a drag that starts on top of it, or scrolling only works in the gaps between cards")
		c["panel"].free()
	)

	# Same audit, applied to UI.bar(): ProgressBar also defaults to STOP, and
	# it's a read-only display no player ever taps -- it shouldn't be able to
	# block a scroll drag either.
	run_case("bar_passes_input_through_instead_of_stopping_it", func():
		var b := UI.bar(5, 10)
		assert_eq(b.mouse_filter, Control.MOUSE_FILTER_PASS, "a progress bar must not swallow a drag that starts on top of it")
		b.free()
	)

	# Ticket 16's third checklist item: a card switching to PASS must not
	# regress a real Button placed inside it -- the button itself still
	# needs to default to STOP (interactive leaves are unaffected by their
	# non-interactive ancestor's filter) and still fire its own callback.
	run_case("a_button_inside_a_pass_filtered_card_still_captures_its_own_tap", func():
		var pressed := [false]
		var c := UI.card()
		var b := UI.button("Go", func(): pressed[0] = true)
		c["content"].add_child(b)

		assert_eq(b.mouse_filter, Control.MOUSE_FILTER_STOP, "a button inside a card must keep capturing its own taps, unaffected by the card's now-PASS filter")
		b.pressed.emit()
		assert_true(pressed[0], "a button nested in a card must still fire its callback")

		c["panel"].free()
	)

	# Bugfixes ticket 20: no headless run ever opens a real window
	# (DisplayServer.window_get_size() reports (0, 0) here, same as
	# check_runner.gd), so the only behaviour this rig can pin down is the
	# safe zero-inset fallback -- the nonzero on-device case is human QA per
	# the ticket.
	run_case("safe_area_insets_is_zero_with_no_window_open", func():
		var insets := UI.safe_area_insets()
		assert_eq(insets["top"], 0.0, "no window open means no safe-area data to scale")
		assert_eq(insets["bottom"], 0.0, "no window open means no safe-area data to scale")
		assert_eq(insets["left"], 0.0, "no window open means no safe-area data to scale")
		assert_eq(insets["right"], 0.0, "no window open means no safe-area data to scale")
	)

	run_case("safe_area_bottom_and_top_inset_helpers_match_the_dict", func():
		assert_eq(UI.safe_area_bottom_inset(), UI.safe_area_insets()["bottom"], "bottom helper must read the same value as the dict")
		assert_eq(UI.safe_area_top_inset(), UI.safe_area_insets()["top"], "top helper must read the same value as the dict")
	)

	# Bugfixes ticket 24: collapsible_section() -- HQ's Rooms/Security accordion primitive.

	run_case("collapsible_section_honours_the_initial_expanded_state", func():
		var collapsed := UI.collapsible_section("Security (2/6)", false)
		assert_true(not collapsed["content"].visible, "expanded:false must start with content hidden")

		var expanded := UI.collapsible_section("Security (2/6)", true)
		assert_true(expanded["content"].visible, "expanded:true must start with content shown")

		collapsed["panel"].free()
		expanded["panel"].free()
	)

	run_case("collapsible_section_header_shows_a_chevron_matching_its_state", func():
		var collapsed := UI.collapsible_section("Rooms (1/4)", false)
		var expanded := UI.collapsible_section("Rooms (1/4)", true)

		var collapsed_header := collapsed["panel"].get_child(0) as Button
		var expanded_header := expanded["panel"].get_child(0) as Button
		assert_eq(collapsed_header.text, "Rooms (1/4) ▸", "collapsed header must show the closed chevron")
		assert_eq(expanded_header.text, "Rooms (1/4) ▾", "expanded header must show the open chevron")

		collapsed["panel"].free()
		expanded["panel"].free()
	)

	run_case("tapping_the_header_toggles_content_visibility_and_the_chevron", func():
		var section := UI.collapsible_section("Security (2/6)", false)
		var header := section["panel"].get_child(0) as Button

		header.pressed.emit()
		assert_true(section["content"].visible, "a tap on a collapsed header must expand it")
		assert_eq(header.text, "Security (2/6) ▾", "chevron must flip to open on expand")

		header.pressed.emit()
		assert_true(not section["content"].visible, "a second tap must collapse it again")
		assert_eq(header.text, "Security (2/6) ▸", "chevron must flip back to closed on collapse")

		section["panel"].free()
	)

	run_case("tapping_the_header_fires_on_toggle_with_the_new_state", func():
		# Array, not a bare bool -- see icon_button test above for why a
		# lambda-captured local can't be mutated directly from the callback.
		var seen := []
		var section := UI.collapsible_section("Rooms (1/4)", false, func(v): seen.append(v))
		var header := section["panel"].get_child(0) as Button

		header.pressed.emit()
		assert_eq(seen, [true], "on_toggle must fire with the section's new (now expanded) state")

		header.pressed.emit()
		assert_eq(seen, [true, false], "on_toggle must fire again with the new (now collapsed) state")

		section["panel"].free()
	)

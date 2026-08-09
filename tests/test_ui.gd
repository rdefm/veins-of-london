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

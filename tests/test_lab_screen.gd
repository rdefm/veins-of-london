extends "res://tests/test_base.gd"

# calc-discovery ticket 06: Lab home renders the found-effects list and the
# known-approaches sentence straight from state.player.bench, same
# headless-scene pattern as tests/test_map_screen.gd -- LabScreen.new()
# then _ready() (no add_child to a live tree needed; _build_home() only
# touches GameState/GameData and UI.* factory calls).


# Collects every Label's text under root, in the same spirit as
# test_map_screen.gd's _buttons_labelled() helper for Buttons.
static func _label_texts(root: Node) -> Array[String]:
	var texts: Array[String] = []
	for l in root.find_children("", "Label", true, false):
		texts.append((l as Label).text)
	return texts


# calc-discovery ticket 07: the picker/pairing panel tests below need to
# tell "rendered as a tappable Button" apart from "rendered as an inert
# Label" -- that distinction IS the untappable/dimmed contract (M3 §3.1),
# so a plain text search across both node types wouldn't catch a regression
# that turned a Label into a Button or vice versa.
static func _button_texts(root: Node) -> Array[String]:
	var texts: Array[String] = []
	for b in root.find_children("", "Button", true, false):
		texts.append((b as Button).text)
	return texts


static func _find_button(root: Node, text: String) -> Button:
	for b in root.find_children("", "Button", true, false):
		if (b as Button).text == text:
			return b
	return null


# calc-discovery ticket 10: the found list can now hold several cards on a
# fresh game (the taughtBy tutorial recipes), so "the first Button labelled
# X" is no longer specific enough to reach one particular card. Every card
# is a flat UI.card() -> content VBoxContainer of [heading, description,
# button] (scenes/components/ui.gd), so a button and the heading Label
# beside it always share a direct parent -- this scopes the search to the
# card whose heading is `label_text`.
static func _find_button_in_card(root: Node, label_text: String, button_text: String) -> Button:
	for l in root.find_children("", "Label", true, false):
		if (l as Label).text == label_text:
			for sibling in l.get_parent().get_children():
				if sibling is Button and (sibling as Button).text == button_text:
					return sibling
	return null


func run() -> void:
	run_case("lab_home_shows_the_known_approaches_sentence_for_a_fresh_game", func():
		GameState.reset()

		var screen := LabScreen.new()
		screen._ready()

		assert_true(_label_texts(screen).has("You work the bench by Heat and Grinding."), "fresh game starts knowing Heat + Grinding (data/approaches.json source:start)")

		screen.free()
	)

	run_case("lab_home_found_list_is_honest_when_nothing_is_found_yet", func():
		GameState.reset()
		# calc-discovery ticket 10: the tutorial always teaches timePearl/
		# enhancementPowder/rewind before the bench is reachable, so a truly
		# fresh save already has 3 found effects -- force their cells back
		# to untried here to exercise the found list's empty-state branch
		# in isolation.
		for recipe_key in ["timePearl", "enhancementPowder", "rewind"]:
			var discovery: Dictionary = GameData.RECIPES[recipe_key]["discovery"]
			var key := Bench.cell_key(discovery["types"], discovery["approach"])
			GameState.state["player"]["bench"]["cells"][key] = { "state": "untried", "misses": 0, "refine": 0 }

		var screen := LabScreen.new()
		screen._ready()

		assert_true(_label_texts(screen).has("Nothing found yet."), "an empty found list must say so plainly, never a checklist of what's missing")

		screen.free()
	)

	run_case("lab_home_renders_a_found_effect_from_player_bench_cells", func():
		GameState.reset()
		GameData.RECIPES["_testBenchEffect"] = {
			"name": "Test Effect", "symbol": "☾", "description": "Does a thing, allegedly.",
			"discovery": { "types": ["life", "time"], "approach": "heat" },
		}
		var key := Bench.cell_key(["life", "time"], "heat")
		GameState.state["player"]["bench"]["cells"][key] = { "state": "found", "misses": 0, "refine": 0 }

		var screen := LabScreen.new()
		screen._ready()

		var texts := _label_texts(screen)
		assert_true(texts.has("☾ Test Effect"), "found effect's symbol+name must render")
		assert_true(texts.has("Does a thing, allegedly."), "found effect's description must render")
		assert_true(not texts.has("Nothing found yet."), "the empty-state line must not show once something is found")

		GameData.RECIPES.erase("_testBenchEffect")
		screen.free()
	)

	run_case("lab_home_never_lists_an_untried_or_hot_cell_as_found", func():
		GameState.reset()
		GameData.RECIPES["_testBenchEffect"] = {
			"name": "Test Effect", "symbol": "☾", "description": "Does a thing, allegedly.",
			"discovery": { "types": ["life", "time"], "approach": "heat" },
		}
		var key := Bench.cell_key(["life", "time"], "heat")
		GameState.state["player"]["bench"]["cells"][key] = { "state": "hot", "misses": 2, "refine": 0 }

		var screen := LabScreen.new()
		screen._ready()

		assert_true(not _label_texts(screen).has("☾ Test Effect"), "a hot (not yet found) cell must not appear in the found list")

		GameData.RECIPES.erase("_testBenchEffect")
		screen.free()
	)

	run_case("benchNav_home_to_picker_and_back_actually_drives_which_bench_screen_is_shown", func():
		GameState.reset()

		var screen := LabScreen.new()
		screen._ready()
		assert_eq(GameState.state["benchNav"]["view"], "home", "starts on home")
		assert_true(_label_texts(screen).has("The Lab"), "home view renders")

		BenchNav.open_picker()
		assert_eq(GameState.state["benchNav"]["view"], "picker")
		assert_true(_label_texts(screen).has("What are you working with?"), "screen re-rendered the real picker off the state_changed signal")

		BenchNav.go_home()
		assert_eq(GameState.state["benchNav"]["view"], "home")
		assert_true(_label_texts(screen).has("The Lab"), "back to home re-renders the home view")

		screen.free()
	)

	run_case("hq_lab_card_opens_the_lab_screen_on_its_home_view", func():
		GameState.reset()
		GameState.state["flags"]["homeUnlocked"] = true
		GameState.state["benchNav"]["view"] = "notes"  # simulate having been left mid-stub last session

		var hq := HqScreen.new()
		hq._ready()
		var lab_card_button: Button = null
		for b in hq.find_children("", "Button", true, false):
			if (b as Button).text == "Open":
				lab_card_button = b
		assert_true(lab_card_button != null, "HQ must render a third card with an Open button for the Lab")
		lab_card_button.pressed.emit()

		assert_eq(GameState.state["currentScreen"], "lab", "Open must navigate to the lab screen")
		assert_eq(GameState.state["benchNav"]["view"], "home", "opening the Lab from HQ must always land on its home view")

		hq.free()
	)

	# ── ticket 07: type picker ───────────────────────────────────────────

	run_case("picker_lists_all_five_types_with_held_quantities_and_nothing_else", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"] = { "time": 24, "physics": 8, "life": 31, "fate": 0, "emotion": 12 }
		BenchNav.open_picker()

		var screen := LabScreen.new()
		screen._ready()

		var buttons := _button_texts(screen)
		assert_true(buttons.has("⧖ Time — 24 held"), "row must show held ore, not census/state")
		assert_true(buttons.has("↯ Physics — 8 held"))
		assert_true(buttons.has("✦ Life — 31 held"))
		assert_true(buttons.has("⚄ Fate — 0 held"))
		assert_true(buttons.has("❋ Emotion — 12 held"))
		assert_true(not buttons.has("Continue"), "no Continue button until something is selected")

		screen.free()
	)

	run_case("picker_tap_selects_a_type_and_marks_it_selected_in_words_not_a_glyph", func():
		GameState.reset()
		BenchNav.open_picker()

		var screen := LabScreen.new()
		screen._ready()

		var life_button := _find_button(screen, "✦ Life — 0 held")
		assert_true(life_button != null)
		life_button.pressed.emit()

		assert_eq(GameState.state["benchNav"]["types"], ["life"])
		assert_true(_button_texts(screen).has("✦ Life — 0 held (selected)"), "the row re-renders with the selected tag written in words")
		assert_true(_button_texts(screen).has("Continue"), "Continue appears once something is selected")

		screen.free()
	)

	run_case("picker_tapping_an_already_selected_type_deselects_it", func():
		GameState.reset()
		BenchNav.select_type("time")
		BenchNav.select_type("time")
		assert_eq(GameState.state["benchNav"]["types"], [], "a second tap on the same type should toggle it off")
	)

	run_case("picker_third_tap_replaces_the_oldest_selection_not_the_newest", func():
		GameState.reset()
		BenchNav.select_type("time")
		BenchNav.select_type("life")
		assert_eq(GameState.state["benchNav"]["types"], ["time", "life"])

		BenchNav.select_type("fate")

		assert_eq(GameState.state["benchNav"]["types"], ["life", "fate"], "tapping a third type replaces the earlier (oldest) selection, per M3 §8.2")
	)

	run_case("picker_continue_advances_to_the_pairing_panel_with_the_selected_types", func():
		GameState.reset()
		BenchNav.open_picker()
		BenchNav.select_type("time")

		var screen := LabScreen.new()
		screen._ready()

		_find_button(screen, "Continue").pressed.emit()

		assert_eq(GameState.state["benchNav"]["view"], "pairing")
		assert_eq(GameState.state["benchNav"]["types"], ["time"])

		screen.free()
	)

	# ── ticket 07: pairing panel ─────────────────────────────────────────

	run_case("pairing_panel_not_yet_surveyed_reads_distinctly_from_barren", func():
		GameState.reset()
		# fate+physics has no authored effect at any approach (calc-discovery
		# ticket 10) -- genuinely barren, unlike life+time which now holds
		# real content.
		BenchNav.open_pairing_for_types(["fate", "physics"])

		var screen := LabScreen.new()
		screen._ready()
		assert_true(_label_texts(screen).has("Not yet surveyed."), "no probe has been made on this pairing yet")
		screen.free()

		GameState.state["player"]["orichalchum"]["fate"] = 100
		GameState.state["player"]["orichalchum"]["physics"] = 100
		Bench.probe(["fate", "physics"], "heat")  # no recipe registered here -> resolves inert, surveys to 0

		var screen2 := LabScreen.new()
		screen2._ready()
		assert_true(_label_texts(screen2).has("Barren. There was never anything in this pairing."), "surveyed-but-empty must read distinctly from not-yet-surveyed")
		screen2.free()
	)

	run_case("pairing_panel_known_approach_rows_render_found_hot_inert_and_untried_state_text", func():
		GameState.reset()
		GameState.state["home"]["rooms"] = ["workshop", "lab"]  # compression + distilling now known
		# fate+physics has no authored effect at any approach (calc-discovery
		# ticket 10) -- genuinely barren, unlike life+time which now holds
		# real content on heat/grinding/distilling and would collide with
		# this test's own synthetic recipe.
		GameData.RECIPES["_testPairingFound"] = {
			"name": "Test Found Effect", "symbol": "☾", "description": "Does a thing, allegedly.",
			"discovery": { "types": ["fate", "physics"], "approach": "heat" },
		}
		GameState.state["player"]["bench"]["cells"]["fate+physics|heat"] = { "state": "found", "misses": 0, "refine": 0 }
		GameState.state["player"]["bench"]["cells"]["fate+physics|grinding"] = { "state": "hot", "misses": 2, "refine": 0 }
		GameState.state["player"]["bench"]["cells"]["fate+physics|compression"] = { "state": "inert", "misses": 0, "refine": 0 }
		# distilling is left absent -> untried

		BenchNav.open_pairing_for_types(["fate", "physics"])
		var screen := LabScreen.new()
		screen._ready()

		var labels := _label_texts(screen)
		var buttons := _button_texts(screen)

		assert_true(buttons.has("Heat"), "a found row's approach name is still tappable (refine)")
		assert_true(labels.has("☾ Test Found Effect · refine to tier 1"), "found row names the effect and its next refine tier")

		assert_true(buttons.has("Grinding"), "a hot row's approach name is tappable (retry)")
		assert_true(labels.has("something nearly took"), "hot row states plainly that something is there")

		assert_true(not buttons.has("Compression"), "an inert row must be untappable")
		assert_true(labels.has("Compression"), "inert row's name still renders, just dimmed")
		assert_true(labels.has("nothing in it, and never was"), "inert row states plainly there was never anything there")

		assert_true(buttons.has("Distilling"), "an untried row's approach name is tappable -- this is the game")
		assert_eq(labels.size(), 6, "heading + census + inert's 2 lines + found's 1 line + hot's 1 line -- untried adds nothing at all")

		GameData.RECIPES.erase("_testPairingFound")
		screen.free()
	)

	run_case("pairing_panel_unlearned_approach_rows_show_source_text_instead_of_a_lock_icon", func():
		GameState.reset()
		BenchNav.open_pairing_for_types(["life", "time"])

		var screen := LabScreen.new()
		screen._ready()

		var labels := _label_texts(screen)
		var buttons := _button_texts(screen)

		assert_true(not buttons.has("Compression"), "an unlearned approach must be untappable")
		assert_true(labels.has("Compression"))
		assert_true(labels.has("Needs the Workshop."), "unlearned approach shows plain-words source text, never a lock icon")

		assert_true(not buttons.has("Distilling"))
		assert_true(labels.has("Distilling"))
		assert_true(labels.has("Needs the Improved Lab."))

		screen.free()
	)

	run_case("home_found_card_view_button_navigates_to_the_pairing_panel_for_that_effects_types", func():
		GameState.reset()
		GameData.RECIPES["_testBenchEffect"] = {
			"name": "Test Effect", "symbol": "☾", "description": "Does a thing, allegedly.",
			"discovery": { "types": ["life", "time"], "approach": "heat" },
		}
		var key := Bench.cell_key(["life", "time"], "heat")
		GameState.state["player"]["bench"]["cells"][key] = { "state": "found", "misses": 0, "refine": 0 }

		var screen := LabScreen.new()
		screen._ready()

		var view_button := _find_button_in_card(screen, "☾ Test Effect", "View")
		assert_true(view_button != null)
		view_button.pressed.emit()

		assert_eq(GameState.state["benchNav"]["view"], "pairing", "tapping View must navigate into the pairing panel")
		assert_eq(GameState.state["benchNav"]["types"], ["life", "time"])

		GameData.RECIPES.erase("_testBenchEffect")
		screen.free()
	)

	# ── ticket 08: confirm / resolving / result ──────────────────────────

	run_case("pairing_panel_tapping_an_untried_approach_row_opens_the_confirm_screen", func():
		GameState.reset()
		BenchNav.open_pairing_for_types(["life", "time"])

		var screen := LabScreen.new()
		screen._ready()

		_find_button(screen, "Heat").pressed.emit()

		assert_eq(GameState.state["benchNav"]["view"], "confirm", "tapping an untried row must open the confirm screen")
		assert_eq(GameState.state["benchNav"]["approach"], "heat")

		screen.free()
	)

	run_case("confirm_screen_shows_pity_inclusive_odds_and_cost_and_block_cost_for_a_probe", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["time"] = 50
		GameState.state["player"]["orichalchum"]["life"] = 50
		GameState.state["player"]["bench"]["cells"]["life+time|heat"] = { "state": "hot", "misses": 3, "refine": 0 }
		BenchNav.open_pairing_for_types(["life", "time"])
		BenchNav.open_confirm("heat")

		var screen := LabScreen.new()
		screen._ready()

		var labels := _label_texts(screen)
		assert_true(labels.has("3 time (have 50)"), "ore cost per type must render via UI.format_cost_label")
		assert_true(labels.has("3 life (have 50)"))
		assert_true(labels.has("Run experiment — 1 block"), "block cost must render via UI.format_block_cost_label")

		var expected_chance := Bench.discovery_chance(["life", "time"], "heat", GameState.state["player"]["craftingSkill"])
		assert_true(labels.has("Odds: %d%%" % int(round(expected_chance * 100))), "odds shown must already include the pity bonus from the 3 recorded misses")

		screen.free()
	)

	run_case("confirm_screen_shows_refine_cost_odds_and_tier_progression_for_a_found_cell", func():
		GameState.reset()
		GameData.RECIPES["_testBenchEffect"] = {
			"name": "Test Effect", "symbol": "☾", "description": "Does a thing, allegedly.",
			"discovery": { "types": ["life", "time"], "approach": "heat" },
			"effectPower": 8, "refineStep": { "field": "effectPower", "add": 3 },
		}
		GameState.state["player"]["orichalchum"]["time"] = 50
		GameState.state["player"]["orichalchum"]["life"] = 50
		GameState.state["player"]["bench"]["cells"]["life+time|heat"] = { "state": "found", "misses": 0, "refine": 0 }
		BenchNav.open_pairing_for_types(["life", "time"])
		BenchNav.open_confirm("heat")

		var screen := LabScreen.new()
		screen._ready()

		var labels := _label_texts(screen)
		assert_true(labels.has("6 time (have 50)"), "tier-1 refine cost is 3 * (1 + 1) per type")
		assert_true(labels.has("Refine — 1 block"))
		assert_true(labels.has("Tier 0 → 1"), "confirm shows current and next tier for a refinement")

		var expected_chance := Bench.refine_chance(["life", "time"], "heat", GameState.state["player"]["craftingSkill"])
		assert_true(labels.has("Odds: %d%%" % int(round(expected_chance * 100))))

		GameData.RECIPES.erase("_testBenchEffect")
		screen.free()
	)

	run_case("confirm_button_runs_the_probe_exactly_once_then_moves_to_resolving_with_the_result_stored", func():
		GameData.RECIPES["_testBenchEffect"] = { "discovery": { "types": ["life", "time"], "approach": "heat" } }

		# Find a success-roll seed cheaply (direct Bench.probe(), no screen)
		# before spinning up a LabScreen to test the button wiring itself.
		var seed := -1
		for candidate in range(500):
			GameState.reset()
			GameState.state["player"]["orichalchum"]["time"] = 100
			GameState.state["player"]["orichalchum"]["life"] = 100
			GameState.state["player"]["craftingSkill"] = 5
			Rng.set_seed(candidate)
			if Bench.probe(["life", "time"], "heat").get("outcome") == "found":
				seed = candidate
				break
		assert_true(seed != -1, "should find a discovery-success roll within 500 tries")

		GameState.reset()
		GameState.state["player"]["orichalchum"]["time"] = 100
		GameState.state["player"]["orichalchum"]["life"] = 100
		GameState.state["player"]["craftingSkill"] = 5
		BenchNav.open_pairing_for_types(["life", "time"])
		BenchNav.open_confirm("heat")
		Rng.set_seed(seed)

		var screen := LabScreen.new()
		screen._ready()
		_find_button(screen, "Run experiment").pressed.emit()

		assert_eq(GameState.state["player"]["orichalchum"]["time"], 97, "confirming must deduct ore exactly once")
		assert_eq(GameState.state["player"]["orichalchum"]["life"], 97)
		assert_eq(GameState.state["benchNav"]["view"], "resolving", "confirming moves to the resolving (animation) view")
		assert_eq(GameState.state["benchNav"]["result"]["outcome"], "found", "the already-decided outcome is stashed for the reveal")
		assert_eq(GameState.state["player"]["bench"]["notes"]["life+time"].size(), 1, "exactly one note entry, not duplicated")

		screen.free()
		GameData.RECIPES.erase("_testBenchEffect")
	)

	run_case("resolving_screen_skip_button_reveals_the_result", func():
		GameState.reset()
		BenchNav.open_pairing_for_types(["life", "time"])
		BenchNav.open_confirm("heat")
		BenchNav.show_resolving({ "ok": true, "outcome": "inert", "recipeKey": "" })

		var screen := LabScreen.new()
		screen._ready()

		var skip_button := _find_button(screen, "Skip")
		assert_true(skip_button != null, "resolving view must offer a Skip button")
		skip_button.pressed.emit()

		assert_eq(GameState.state["benchNav"]["view"], "result", "Skip must reveal the result immediately")

		screen.free()
	)

	run_case("result_screen_renders_the_found_outcome_with_symbol_name_description_and_craftable_now", func():
		GameState.reset()
		GameData.RECIPES["_testBenchEffect"] = {
			"name": "Test Effect", "symbol": "☾", "description": "Does a thing, allegedly.",
			"discovery": { "types": ["life", "time"], "approach": "heat" },
		}
		BenchNav.open_pairing_for_types(["life", "time"])
		BenchNav.open_confirm("heat")
		BenchNav.show_resolving({ "ok": true, "outcome": "found", "recipeKey": "_testBenchEffect" })
		BenchNav.reveal_result()

		var screen := LabScreen.new()
		screen._ready()

		var labels := _label_texts(screen)
		assert_true(labels.has("Found it."))
		assert_true(labels.has("☾ Test Effect. Does a thing, allegedly. Craftable now."))

		GameData.RECIPES.erase("_testBenchEffect")
		screen.free()
	)

	run_case("result_screen_renders_the_hot_outcome_as_a_lure_not_a_consolation", func():
		GameState.reset()
		BenchNav.open_pairing_for_types(["life", "time"])
		BenchNav.open_confirm("heat")
		BenchNav.show_resolving({ "ok": true, "outcome": "hot", "recipeKey": "_testBenchEffect" })
		BenchNav.reveal_result()

		var screen := LabScreen.new()
		screen._ready()

		var labels := _label_texts(screen)
		assert_true(labels.has("Something's there."))
		assert_true(labels.has("Something's in there. It didn't come out this time."))

		screen.free()
	)

	run_case("result_screen_renders_the_inert_outcome_flatly", func():
		GameState.reset()
		BenchNav.open_pairing_for_types(["life", "time"])
		BenchNav.open_confirm("heat")
		BenchNav.show_resolving({ "ok": true, "outcome": "inert", "recipeKey": "" })
		BenchNav.reveal_result()

		var screen := LabScreen.new()
		screen._ready()

		var labels := _label_texts(screen)
		assert_true(labels.has("Inert."))
		assert_true(labels.has("Nothing in it. Never was."))

		screen.free()
	)

	# ── ticket 09: bench notes screen ─────────────────────────────────────

	run_case("bench_notes_only_lists_touched_pairings", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["time"] = 100
		GameState.state["player"]["orichalchum"]["life"] = 100
		Bench.probe(["life", "time"], "heat")  # touches "life+time"; "fate" is left untouched

		BenchNav.open_notes()
		var screen := LabScreen.new()
		screen._ready()

		var labels := _label_texts(screen)
		assert_true(labels.has("Life and Time"), "a touched pairing's card must appear")
		assert_true(not labels.has("Fate"), "an untouched pairing must never appear on bench notes")

		screen.free()
	)

	run_case("bench_notes_says_so_plainly_when_nothing_has_been_touched_yet", func():
		GameState.reset()
		BenchNav.open_notes()

		var screen := LabScreen.new()
		screen._ready()

		assert_true(_label_texts(screen).has("Nothing recorded yet."), "an empty bench-notes screen must say so plainly")

		screen.free()
	)

	run_case("bench_notes_shows_the_exact_numeric_census_count_for_a_touched_pairing", func():
		GameState.reset()
		# fate+physics has no authored effect at any approach (calc-discovery
		# ticket 10) -- genuinely barren, unlike life+time which now holds 3
		# real effects and would inflate the census past the expected 2.
		GameData.RECIPES["_testBenchHeat"] = { "discovery": { "types": ["fate", "physics"], "approach": "heat" } }
		GameData.RECIPES["_testBenchGrinding"] = { "discovery": { "types": ["fate", "physics"], "approach": "grinding" } }
		GameState.state["player"]["orichalchum"]["fate"] = 100
		GameState.state["player"]["orichalchum"]["physics"] = 100
		Bench.probe(["fate", "physics"], "heat")  # surveys the pairing to 2 total
		GameState.state["player"]["bench"]["cells"]["fate+physics|heat"]["state"] = "found"

		BenchNav.open_notes()
		var screen := LabScreen.new()
		screen._ready()

		assert_true(_label_texts(screen).has("1/2"), "exact found/total numeric count must render, per ticket 04's reveal data")

		GameData.RECIPES.erase("_testBenchHeat")
		GameData.RECIPES.erase("_testBenchGrinding")
		screen.free()
	)

	run_case("bench_notes_renders_correct_prose_per_stored_outcome_enum", func():
		GameState.reset()
		GameState.state["player"]["bench"]["notes"]["life+time"] = [
			{ "day": 3, "approach": "heat", "outcome": "inert" },
			{ "day": 5, "approach": "grinding", "outcome": "hot" },
			{ "day": 7, "approach": "heat", "outcome": "found" },
			{ "day": 9, "approach": "heat", "outcome": "refined" },
			{ "day": 11, "approach": "heat", "outcome": "refine_failed" },
		]

		BenchNav.open_notes()
		var screen := LabScreen.new()
		screen._ready()

		var labels := _label_texts(screen)
		assert_true(labels.has("Day 3 — Heat: Inert."), "prose is generated at render time from the stored outcome enum, not stored as prose")
		assert_true(labels.has("Day 5 — Grinding: Something's there."))
		assert_true(labels.has("Day 7 — Heat: Found it."))
		assert_true(labels.has("Day 9 — Heat: Refined."))
		assert_true(labels.has("Day 11 — Heat: No better this time."))

		screen.free()
	)

	run_case("bench_notes_respects_the_20_entry_cap_and_renders_only_what_is_stored", func():
		GameState.reset()
		for i in range(25):
			GameState.state["world"]["day"] = i
			Bench._append_note(["life", "time"], "heat", "hot")

		BenchNav.open_notes()
		var screen := LabScreen.new()
		screen._ready()

		var history_lines: Array[String] = []
		for text in _label_texts(screen):
			if text.begins_with("Day "):
				history_lines.append(text)

		assert_eq(history_lines.size(), 20, "the screen renders exactly what's in state -- already capped at 20 by Bench._append_note()")
		assert_true(history_lines.has("Day 5 — Heat: Something's there."), "the oldest 5 entries (days 0-4) were already dropped in state")
		assert_true(not history_lines.has("Day 0 — Heat: Something's there."))

		screen.free()
	)

	run_case("result_screen_renders_the_refined_outcome_with_old_value_arrow_new_value", func():
		GameState.reset()
		# fate+physics has no authored effect at any approach (calc-discovery
		# ticket 10) -- genuinely barren, unlike life+time/heat which now
		# holds the real Healing Burst recipe and would win the cell lookup
		# instead of this test's own synthetic recipe.
		GameData.RECIPES["_testBenchEffect"] = {
			"name": "Test Effect", "symbol": "☾", "description": "Does a thing, allegedly.",
			"discovery": { "types": ["fate", "physics"], "approach": "heat" },
			"effectPower": 8, "refineStep": { "field": "effectPower", "add": 3 },
		}
		GameState.state["player"]["bench"]["cells"]["fate+physics|heat"] = { "state": "found", "misses": 0, "refine": 1 }
		BenchNav.open_pairing_for_types(["fate", "physics"])
		BenchNav.open_confirm("heat")
		BenchNav.show_resolving({ "ok": true, "outcome": "refined" })
		BenchNav.reveal_result()

		var screen := LabScreen.new()
		screen._ready()

		var labels := _label_texts(screen)
		assert_true(labels.has("Refined."))
		assert_true(labels.has("Test Effect, tier 1 now. 8 → 11."), "old value (tier 0 = base 8) -> new value (tier 1 = 11), plainly")

		GameData.RECIPES.erase("_testBenchEffect")
		screen.free()
	)

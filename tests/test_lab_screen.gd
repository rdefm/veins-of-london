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
		BenchNav.open_pairing_for_types(["life", "time"])

		var screen := LabScreen.new()
		screen._ready()
		assert_true(_label_texts(screen).has("Not yet surveyed."), "no probe has been made on this pairing yet")
		screen.free()

		GameState.state["player"]["orichalchum"]["time"] = 100
		GameState.state["player"]["orichalchum"]["life"] = 100
		Bench.probe(["life", "time"], "heat")  # no recipe registered here -> resolves inert, surveys to 0

		var screen2 := LabScreen.new()
		screen2._ready()
		assert_true(_label_texts(screen2).has("Barren. There was never anything in this pairing."), "surveyed-but-empty must read distinctly from not-yet-surveyed")
		screen2.free()
	)

	run_case("pairing_panel_known_approach_rows_render_found_hot_inert_and_untried_state_text", func():
		GameState.reset()
		GameState.state["home"]["rooms"] = ["workshop", "lab"]  # compression + distilling now known
		GameData.RECIPES["_testPairingFound"] = {
			"name": "Test Found Effect", "symbol": "☾", "description": "Does a thing, allegedly.",
			"discovery": { "types": ["life", "time"], "approach": "heat" },
		}
		GameState.state["player"]["bench"]["cells"]["life+time|heat"] = { "state": "found", "misses": 0, "refine": 0 }
		GameState.state["player"]["bench"]["cells"]["life+time|grinding"] = { "state": "hot", "misses": 2, "refine": 0 }
		GameState.state["player"]["bench"]["cells"]["life+time|compression"] = { "state": "inert", "misses": 0, "refine": 0 }
		# distilling is left absent -> untried

		BenchNav.open_pairing_for_types(["life", "time"])
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

		var view_button := _find_button(screen, "View")
		assert_true(view_button != null)
		view_button.pressed.emit()

		assert_eq(GameState.state["benchNav"]["view"], "pairing", "tapping View must navigate into the pairing panel")
		assert_eq(GameState.state["benchNav"]["types"], ["life", "time"])

		GameData.RECIPES.erase("_testBenchEffect")
		screen.free()
	)

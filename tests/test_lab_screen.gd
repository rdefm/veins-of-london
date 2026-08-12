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
		assert_true(_label_texts(screen).has("Pick a pairing"), "screen re-rendered the picker stub off the state_changed signal")

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

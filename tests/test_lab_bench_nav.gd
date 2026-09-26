extends "res://tests/test_base.gd"

# docs/hq-diorama-vision.md §5: LabBenchNav's own nav state
# (systems/lab_bench_nav.gd) -- which notebook mode is held and which ore
# types are selected. Screen-level tap dispatch is covered by
# tests/test_hq_lab_bench.gd; these cases are the pure state transitions only.


func run() -> void:
	run_case("open_emits_state_changed", func():
		GameState.reset()
		var received := [false]
		var on_changed := func(): received[0] = true
		EventBus.state_changed.connect(on_changed)
		LabBenchNav.open()
		EventBus.state_changed.disconnect(on_changed)

		assert_true(received[0], "state_changed should fire")
	)

	run_case("open_does_not_disturb_an_already_held_mode", func():
		GameState.reset()
		GameState.state["labBenchNav"]["mode"] = "recipes"
		LabBenchNav.open()
		assert_eq(GameState.state["labBenchNav"]["mode"], "recipes", "§5.2: the held notebook stays open for the whole session, including across re-entering the bench")
	)

	run_case("tap_notebook_sets_the_mode_when_none_is_held", func():
		GameState.reset()
		LabBenchNav.tap_notebook(LabBenchNav.MODE_RECIPES)
		assert_eq(GameState.state["labBenchNav"]["mode"], "recipes")
	)

	run_case("tap_notebook_on_the_held_notebook_keeps_it_held", func():
		GameState.reset()
		LabBenchNav.tap_notebook(LabBenchNav.MODE_EXPERIMENTS)
		LabBenchNav.tap_notebook(LabBenchNav.MODE_EXPERIMENTS)
		assert_eq(GameState.state["labBenchNav"]["mode"], "experiments", "§5.2: re-tapping the held notebook never toggles it off")
	)

	run_case("tap_notebook_switches_modes_freely", func():
		GameState.reset()
		LabBenchNav.tap_notebook(LabBenchNav.MODE_RECIPES)
		LabBenchNav.tap_notebook(LabBenchNav.MODE_EXPERIMENTS)
		assert_eq(GameState.state["labBenchNav"]["mode"], "experiments", "§5.2: the player can switch modes freely, no confirmation")
	)

	# ── ticket 07, §5.4: ore-stop selection ────────────────────────────────

	run_case("select_ore_adds_up_to_two_types", func():
		GameState.reset()
		LabBenchNav.select_ore("life")
		assert_eq(GameState.state["labBenchNav"]["selectedOre"], ["life"])
		LabBenchNav.select_ore("time")
		assert_eq(GameState.state["labBenchNav"]["selectedOre"], ["life", "time"])
	)

	run_case("select_ore_on_a_third_type_is_ignored", func():
		GameState.reset()
		LabBenchNav.select_ore("life")
		LabBenchNav.select_ore("time")
		LabBenchNav.select_ore("fate")
		assert_eq(GameState.state["labBenchNav"]["selectedOre"], ["life", "time"], "two selected: a third tap leaves the selection unchanged")
	)

	run_case("select_ore_frees_a_slot_after_deselecting_at_the_cap", func():
		GameState.reset()
		LabBenchNav.select_ore("life")
		LabBenchNav.select_ore("time")
		LabBenchNav.select_ore("life")
		LabBenchNav.select_ore("fate")
		assert_eq(GameState.state["labBenchNav"]["selectedOre"], ["time", "fate"])
	)

	run_case("select_ore_on_an_already_selected_type_deselects_it", func():
		GameState.reset()
		LabBenchNav.select_ore("life")
		LabBenchNav.select_ore("life")
		assert_eq(GameState.state["labBenchNav"]["selectedOre"], [])
	)

	run_case("select_ore_emits_state_changed", func():
		GameState.reset()
		var received := [false]
		var on_changed := func(): received[0] = true
		EventBus.state_changed.connect(on_changed)
		LabBenchNav.select_ore("life")
		EventBus.state_changed.disconnect(on_changed)
		assert_true(received[0])
	)

	run_case("open_resets_selected_ore_but_leaves_mode_untouched", func():
		GameState.reset()
		GameState.state["labBenchNav"]["selectedOre"] = ["life", "time"]
		GameState.state["labBenchNav"]["mode"] = "recipes"
		LabBenchNav.open()
		assert_eq(GameState.state["labBenchNav"]["selectedOre"], [], "re-entering the bench must not open on a stale pairing from last session")
		assert_eq(GameState.state["labBenchNav"]["mode"], "recipes", "mode still stays held across a re-entry, unlike selectedOre")
	)

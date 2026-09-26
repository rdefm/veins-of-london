extends "res://tests/test_base.gd"

# docs/hq-diorama-vision.md §5: LabBenchNav's own nav state
# (systems/lab_bench_nav.gd) -- which ore types are selected, and which
# confirm variant / readiness a gear has for that selection. Screen-level tap dispatch is covered by
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

	run_case("open_resets_selected_ore", func():
		GameState.reset()
		GameState.state["labBenchNav"]["selectedOre"] = ["life", "time"]
		LabBenchNav.open()
		assert_eq(GameState.state["labBenchNav"]["selectedOre"], [], "re-entering the bench must not open on a stale pairing from last session")
	)

	# ── §5.3: gear confirm variant + readiness ─────────────────────────────

	run_case("confirm_variant_follows_the_cell_state", func():
		GameState.reset()
		GameState.state["player"]["bench"]["cells"]["fate|heat"] = { "state": "inert", "misses": 0, "refine": 0 }
		GameState.state["player"]["bench"]["cells"]["physics|grinding"] = { "state": "hot", "misses": 1, "refine": 0 }
		assert_eq(LabBenchNav.confirm_variant(["time"], "heat"), LabBenchNav.CONFIRM_CRAFT, "rewind is tutorial-found")
		assert_eq(LabBenchNav.confirm_variant(["physics"], "heat"), LabBenchNav.CONFIRM_PROBE, "untried")
		assert_eq(LabBenchNav.confirm_variant(["physics"], "grinding"), LabBenchNav.CONFIRM_PROBE, "hot")
		assert_eq(LabBenchNav.confirm_variant(["fate"], "heat"), LabBenchNav.CONFIRM_INERT)
	)

	run_case("gear_ready_for_a_legal_probe_or_a_found_recipe_only", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["physics"] = Bench.ORE_COST_PER_TYPE
		GameState.state["player"]["orichalchum"]["time"] = 0
		GameState.state["player"]["bench"]["cells"]["physics|grinding"] = { "state": "inert", "misses": 0, "refine": 0 }
		assert_true(LabBenchNav.gear_ready(["physics"], "heat"), "affordable probe")
		assert_true(not LabBenchNav.gear_ready(["physics"], "grinding"), "inert is never ready")
		assert_true(LabBenchNav.gear_ready(["time"], "heat"), "a found recipe is ready even with no ore")
		assert_true(not LabBenchNav.gear_ready(["time"], "grinding"), "unaffordable probe")
		assert_true(not LabBenchNav.gear_ready([], "heat"), "no selection")
	)

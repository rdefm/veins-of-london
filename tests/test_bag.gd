extends "res://tests/test_base.gd"

# D4.4's global bag drawer toggle. Mirrors test_modal.gd's shape.


func run() -> void:
	run_projection()
	run_case("open_sets_bagDrawerOpen_and_emits", func():
		GameState.reset()
		var received := [false]
		var on_change := func(): received[0] = true
		EventBus.state_changed.connect(on_change)
		Bag.open()
		EventBus.state_changed.disconnect(on_change)

		assert_eq(GameState.state["bagDrawerOpen"], true, "bagDrawerOpen set")
		assert_true(received[0], "state_changed should fire")
	)

	run_case("close_clears_bagDrawerOpen", func():
		GameState.reset()
		Bag.open()
		Bag.close()
		assert_eq(GameState.state["bagDrawerOpen"], false, "bagDrawerOpen cleared")
	)

	run_case("new_game_state_starts_closed", func():
		GameState.reset()
		assert_eq(GameState.state["bagDrawerOpen"], false, "closed by default")
	)


func _give(key: String, tier: int, qty: int) -> void:
	Crafting.inventory_add(key, tier, qty)


func _find_row(proj: Dictionary, key: String) -> Dictionary:
	for category in proj["categories"]:
		for row in category["rows"]:
			if row["key"] == key:
				return row
	return {}


func run_projection() -> void:
	run_case("projection_lists_only_held_items_and_hides_empty_categories", func():
		GameState.reset()
		var empty: Dictionary = Bag.projection("", true)
		assert_eq(empty["categories"].size(), 0, "nothing held -> no categories")
		assert_eq(empty["filters"].size(), 0, "nothing held -> no filters")
		_give("timePearl", 1, 2)
		var proj: Dictionary = Bag.projection("", true)
		assert_eq(proj["categories"].size(), 1, "one category")
		assert_eq(proj["categories"][0]["ore"], "time", "time pearl under time")
		assert_eq(proj["filters"], ["time"], "filter for held ore only")
	)

	run_case("projection_row_carries_total_stash_tiers_and_use", func():
		GameState.reset()
		_give("healingSalve", 1, 1)
		_give("healingSalve", 3, 2)
		Stash.move_item_to_stash("healingSalve", 1)
		var row: Dictionary = _find_row(Bag.projection("", true), "healingSalve")
		assert_eq(row["total"], 3, "total counts shared + stash")
		assert_eq(row["stash"], 1, "stash quantity")
		assert_eq(row["tiers"], [1, 3], "held tiers")
		assert_true(row["usable"], "usable in management")
		assert_eq(row["useAction"], "healingSalve", "use action")
	)

	run_case("projection_use_hidden_outside_management_and_filter_narrows", func():
		GameState.reset()
		_give("healingSalve", 1, 1)
		_give("timePearl", 1, 1)
		var row: Dictionary = _find_row(Bag.projection("", false), "healingSalve")
		assert_true(not row["usable"], "no Use in combat")
		var narrowed: Dictionary = Bag.projection("time", true)
		assert_eq(narrowed["categories"].size(), 1, "filter shows one category")
		assert_eq(narrowed["categories"][0]["ore"], "time", "filtered to time")
		assert_eq(narrowed["filters"].size(), 2, "filters stay full")
	)

	run_case("projection_multi_variant_gets_its_own_row_and_no_use", func():
		GameState.reset()
		_give("blast", 1, 1)
		_give("blast_multi", 1, 1)
		var found: Array = []
		for category in Bag.projection("", true)["categories"]:
			for row in category["rows"]:
				if row["key"] == "blast":
					found.append(row)
		assert_true(found.size() >= 2, "single and multi rows")
		for row in found:
			if row["multi"]:
				assert_true(not row["usable"], "multi never usable")
	)

	run_case("use_with_tier_consumes_that_tier", func():
		GameState.reset()
		_give("healingSalve", 1, 1)
		_give("healingSalve", 3, 1)
		var result: Dictionary = Bag.use("healingSalve", 3)
		assert_true(result["ok"], "used")
		assert_eq(Stash.player_item_tier_qty("healingSalve", 3), 0, "tier 3 spent")
		assert_eq(Stash.player_item_tier_qty("healingSalve", 1), 1, "tier 1 kept")
	)

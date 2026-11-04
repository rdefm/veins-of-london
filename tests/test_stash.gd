extends "res://tests/test_base.gd"

# Ticket 22: personal stash -- shared/reserve split. Mirrors test_crafting.gd's
# tier-bucket assertions and test_bag.gd's state_changed-emits shape.


func run() -> void:
	run_case("move_ore_to_stash_subtracts_from_shared_and_credits_stash", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["time"] = 10
		Stash.move_ore_to_stash("time", 4)
		assert_eq(GameState.state["player"]["orichalchum"]["time"], 6, "shared pool debited")
		assert_eq(Stash.stashed_ore_qty("time"), 4, "stash credited")
	)

	run_case("move_ore_to_shared_reverses_it", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["time"] = 10
		Stash.move_ore_to_stash("time", 4)
		Stash.move_ore_to_shared("time", 3)
		assert_eq(GameState.state["player"]["orichalchum"]["time"], 9, "shared pool credited back")
		assert_eq(Stash.stashed_ore_qty("time"), 1, "stash debited")
	)

	run_case("move_ore_to_stash_clamps_to_available_shared_qty", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["time"] = 3
		Stash.move_ore_to_stash("time", 99)
		assert_eq(GameState.state["player"]["orichalchum"]["time"], 0, "only what was actually there moves")
		assert_eq(Stash.stashed_ore_qty("time"), 3, "stash gets exactly the clamped amount")
	)

	run_case("move_ore_to_shared_clamps_to_available_stash_qty", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["time"] = 5
		Stash.move_ore_to_stash("time", 5)
		Stash.move_ore_to_shared("time", 99)
		assert_eq(GameState.state["player"]["orichalchum"]["time"], 5, "clamped to what stash actually held")
		assert_eq(Stash.stashed_ore_qty("time"), 0, "stash drained, not negative")
	)

	run_case("move_ore_ignores_nonpositive_qty_and_does_not_emit", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["time"] = 5
		var received := [false]
		var on_change := func(): received[0] = true
		EventBus.state_changed.connect(on_change)
		Stash.move_ore_to_stash("time", 0)
		Stash.move_ore_to_stash("time", -3)
		EventBus.state_changed.disconnect(on_change)
		assert_eq(GameState.state["player"]["orichalchum"]["time"], 5, "nothing moved")
		assert_true(not received[0], "no-op move should not emit state_changed")
	)

	run_case("move_ore_to_stash_emits_state_changed", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["time"] = 5
		var received := [false]
		var on_change := func(): received[0] = true
		EventBus.state_changed.connect(on_change)
		Stash.move_ore_to_stash("time", 2)
		EventBus.state_changed.disconnect(on_change)
		assert_true(received[0], "state_changed should fire")
	)

	run_case("move_item_to_stash_preserves_tier", func():
		GameState.reset()
		Crafting.inventory_add("timePearl", 3, 2)
		Crafting.inventory_add("timePearl", 1, 1)
		Stash.move_item_to_stash("timePearl", 2)
		# Lowest-tier-first: the tier-1 unit moves first, then one of the two
		# tier-3 units.
		var stash_buckets: Dictionary = GameState.state["player"]["stash"]["inventory"]["timePearl"]
		assert_eq(stash_buckets.get("1", 0), 1, "tier 1 unit moved")
		assert_eq(stash_buckets.get("3", 0), 1, "one tier 3 unit moved")
		var shared_buckets: Dictionary = GameState.state["player"]["inventory"]["timePearl"]
		assert_eq(shared_buckets.get("1", 0), 0, "tier 1 bucket emptied and pruned")
		assert_eq(shared_buckets.get("3", 0), 1, "one tier 3 unit remains")
		assert_eq(Crafting.inventory_qty("timePearl"), 1, "shared inventory total reflects the move")
		assert_eq(Stash.stashed_item_qty("timePearl"), 2, "stash total reflects the move")
	)

	run_case("move_item_to_shared_restores_exact_tier", func():
		GameState.reset()
		Crafting.inventory_add("timePearl", 5, 1)
		Stash.move_item_to_stash("timePearl", 1)
		Stash.move_item_to_shared("timePearl", 1)
		var shared_buckets: Dictionary = GameState.state["player"]["inventory"]["timePearl"]
		assert_eq(shared_buckets.get("5", 0), 1, "unit returns to its original tier 5 bucket, not tier 0")
		assert_eq(Stash.stashed_item_qty("timePearl"), 0, "stash drained")
	)

	run_case("move_item_to_stash_clamps_to_available_and_prunes_empty_source_recipe", func():
		GameState.reset()
		Crafting.inventory_add("timePearl", 2, 3)
		Stash.move_item_to_stash("timePearl", 99)
		assert_eq(Crafting.inventory_qty("timePearl"), 0, "only what was there moved")
		assert_eq(Stash.stashed_item_qty("timePearl"), 3, "stash got exactly the clamped amount")
	)

	run_case("move_item_zero_qty_or_empty_source_is_a_noop_and_does_not_emit", func():
		GameState.reset()
		var received := [false]
		var on_change := func(): received[0] = true
		EventBus.state_changed.connect(on_change)
		Stash.move_item_to_stash("timePearl", 5)
		Stash.move_item_to_stash("rewind", 0)
		EventBus.state_changed.disconnect(on_change)
		assert_eq(Stash.stashed_item_qty("timePearl"), 0, "nothing to move")
		assert_true(not received[0], "no-op move should not emit state_changed")
	)

	run_case("stashed_calc_is_invisible_to_the_lab", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["time"] = 5
		Stash.move_ore_to_stash("time", 5)
		assert_eq(Lab.calc_available("time"), 0, "the Lab reads player.orichalchum, which the stash move already emptied")
	)

	run_case("ore_move_qty_defaults_to_1_and_steps_clamp_to_1_and_max", func():
		GameState.reset()
		assert_eq(Stash.get_ore_move_qty("time"), 1, "default qty is 1")
		Stash.adjust_ore_move_qty("time", 5, 3)
		assert_eq(Stash.get_ore_move_qty("time"), 3, "clamped to max_qty")
		Stash.adjust_ore_move_qty("time", -10, 3)
		assert_eq(Stash.get_ore_move_qty("time"), 1, "floored at 1")
	)

	run_case("item_move_qty_defaults_to_1_and_steps_clamp_to_1_and_max", func():
		GameState.reset()
		assert_eq(Stash.get_item_move_qty("timePearl"), 1, "default qty is 1")
		Stash.adjust_item_move_qty("timePearl", 5, 2)
		assert_eq(Stash.get_item_move_qty("timePearl"), 2, "clamped to max_qty")
		Stash.adjust_item_move_qty("timePearl", -10, 2)
		assert_eq(Stash.get_item_move_qty("timePearl"), 1, "floored at 1")
	)

	run_case("ore_and_item_move_qty_keys_are_independent", func():
		GameState.reset()
		Stash.adjust_ore_move_qty("time", 2, 10)
		assert_eq(Stash.get_item_move_qty("time"), 1, "an ore key and an item key of the same string never collide")
	)

	run_case("player_item_remove_spends_shared_then_stash_preserving_tiers", func():
		GameState.reset()
		Crafting.inventory_add("timePearl", 2, 1)
		Crafting.inventory_add("timePearl", 4, 1)
		Stash.move_item_to_stash("timePearl", 1)  # tier 2 -> stash
		assert_eq(Stash.player_item_qty("timePearl"), 2, "total includes stashed")
		var taken: Array = Stash.player_item_remove("timePearl", 2)
		assert_eq(taken, [{ "tier": 4, "qty": 1 }, { "tier": 2, "qty": 1 }], "shared tier 4 first, then stashed tier 2")
		assert_eq(Stash.player_item_qty("timePearl"), 0, "all spent")
		assert_eq(Stash.stashed_item_qty("timePearl"), 0, "stash pruned")
	)

	run_case("stashed_only_item_is_usable_from_bag", func():
		GameState.reset()
		GameState.state["player"]["hp"] = 1
		Crafting.inventory_add("healingBurst", 1, 1)
		Stash.move_item_to_stash("healingBurst", 1)
		var result: Dictionary = Consumables.use_healing_burst()
		assert_true(result["ok"], "used from stash")
		assert_eq(Stash.player_item_qty("healingBurst"), 0, "unit consumed")
	)

	run_case("stashed_only_vein_item_is_listed_and_spent_by_hand", func():
		GameState.reset()
		var item: String = Cultivating.boost_items()[0]
		Crafting.inventory_add(item, 3, 1)
		Stash.move_item_to_stash(item, 1)
		var stacks: Array = Cultivating.usable_boost_stacks([item])
		assert_eq(stacks.size(), 1, "stashed stack listed")
		assert_eq(stacks[0]["tier"], 3, "tier preserved")
		var place := {}
		var result: Dictionary = Cultivating.spend_and_record_boost(place, item, 3)
		assert_true(result["ok"], "spent from stash")
		assert_eq(Stash.stashed_item_qty(item), 0, "stash debited")
	)

	run_case("player_spend_ore_takes_shared_then_stash", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["time"] = 5
		Stash.move_ore_to_stash("time", 3)  # 2 shared, 3 stash
		assert_eq(Stash.player_ore_qty("time"), 5, "total includes stash")
		assert_eq(Stash.player_spend_ore("time", 4), 4, "spent 4")
		assert_eq(GameState.state["player"]["orichalchum"]["time"], 0, "shared drained first")
		assert_eq(Stash.stashed_ore_qty("time"), 1, "stash covers the rest")
		assert_eq(Stash.player_spend_ore("time", 9), 1, "clamped to what exists")
	)

	run_case("shared_only_readers_ignore_the_stash", func():
		GameState.reset()
		Crafting.inventory_add("timePearl", 2, 1)
		Stash.move_item_to_stash("timePearl", 1)
		GameState.state["player"]["orichalchum"]["time"] = 2
		Stash.move_ore_to_stash("time", 2)
		assert_eq(Crafting.inventory_qty("timePearl"), 0, "automated systems see no stashed items")
		assert_eq(Lab.calc_available("time"), 0, "Lab sees no stashed ore")
	)

	run_case("new_game_starts_with_an_empty_stash", func():
		GameState.reset()
		assert_eq(GameState.state["player"]["stash"]["orichalchum"], {}, "empty ore stash by default")
		assert_eq(GameState.state["player"]["stash"]["inventory"], {}, "empty item stash by default")
	)

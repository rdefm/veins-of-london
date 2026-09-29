extends "res://tests/test_base.gd"

const Fixtures := preload("res://tests/support/fixtures.gd")
const SAVE_TEST_SLOT := 88


func run() -> void:
	run_case("stock_moves_units_of_one_tier_from_inventory_to_the_kit", func():
		var vein := _seed(1)
		Crafting.inventory_add("shield", 3, 2)
		Crafting.inventory_add("shield", 1, 1)
		var result := GuardKit.stock("v1", "shield", 3, 2)
		assert_true(result["ok"], result["reason"])
		assert_eq(vein["guardKit"], { "shield": { "3": 2 } })
		assert_eq(GameState.state["player"]["inventory"]["shield"].get("3", 0), 0, "tier-3 units left the inventory")
		assert_eq(GameState.state["player"]["inventory"]["shield"]["1"], 1, "other tiers untouched")
	)

	run_case("stock_refuses_items_off_the_allowlist", func():
		var vein := _seed(2)
		for recipe_key in ["healingSalve", "wormhole", "pansPrank"]:
			Crafting.inventory_add(recipe_key, 1, 1)
			var before: Dictionary = GameState.deep_copy(GameState.state)
			assert_true(not GuardKit.stock("v1", recipe_key, 1, 1)["ok"], recipe_key + " refused")
			assert_eq(GameState.state, before, recipe_key + " left no change")
		assert_eq(vein["guardKit"], {})
	)

	run_case("stock_refuses_when_too_few_are_held_at_that_tier", func():
		_seed(2)
		Crafting.inventory_add("blast", 1, 1)
		Crafting.inventory_add("blast", 2, 5)
		var before: Dictionary = GameState.deep_copy(GameState.state)
		assert_true(not GuardKit.stock("v1", "blast", 1, 2)["ok"])
		assert_eq(GameState.state, before)
	)

	run_case("stock_refuses_a_vein_that_isnt_the_players", func():
		_seed(1)
		Fixtures.seed_faction_vein("fv1", 50)
		Crafting.inventory_add("blast", 1, 1)
		var before: Dictionary = GameState.deep_copy(GameState.state)
		assert_true(not GuardKit.stock("fv1", "blast", 1, 1)["ok"])
		assert_true(not GuardKit.stock("nope", "blast", 1, 1)["ok"])
		assert_eq(GameState.state, before)
	)

	run_case("stock_refuses_a_vein_with_no_guards", func():
		_seed(0)
		Crafting.inventory_add("blast", 1, 1)
		var before: Dictionary = GameState.deep_copy(GameState.state)
		assert_true(not GuardKit.stock("v1", "blast", 1, 1)["ok"])
		assert_eq(GameState.state, before)
	)

	run_case("stock_refuses_an_over_capacity_result", func():
		var vein := _seed(1)  # capacity 2
		Crafting.inventory_add("blast", 1, 3)
		var before: Dictionary = GameState.deep_copy(GameState.state)
		assert_true(not GuardKit.stock("v1", "blast", 1, 3)["ok"], "3 units into 2 slots refused")
		assert_eq(GameState.state, before)
		assert_true(GuardKit.stock("v1", "blast", 1, 2)["ok"], "exactly filling capacity is allowed")
		assert_eq(GuardKit.unit_count(vein["guardKit"]), 2)
		assert_true(not GuardKit.stock("v1", "blast", 1, 1)["ok"], "refused at capacity")
	)

	run_case("unstock_returns_units_to_inventory_at_their_tier", func():
		var vein := _seed(1)
		vein["guardKit"] = { "shield": { "3": 2 } }
		var result := GuardKit.unstock("v1", "shield", 3, 1)
		assert_true(result["ok"], result["reason"])
		assert_eq(vein["guardKit"], { "shield": { "3": 1 } })
		assert_eq(GameState.state["player"]["inventory"]["shield"]["3"], 1)
		assert_true(GuardKit.unstock("v1", "shield", 3, 1)["ok"])
		assert_eq(vein["guardKit"], {}, "emptied buckets are dropped")
	)

	run_case("unstock_works_over_capacity_and_with_no_guards", func():
		var vein := _seed(0)
		vein["guardKit"] = { "blast": { "1": 4 } }
		assert_true(GuardKit.unstock("v1", "blast", 1, 3)["ok"])
		assert_eq(vein["guardKit"], { "blast": { "1": 1 } })
		assert_eq(GameState.state["player"]["inventory"]["blast"]["1"], 3)
	)

	run_case("unstock_refuses_more_than_the_kit_holds", func():
		var vein := _seed(1)
		vein["guardKit"] = { "blast": { "1": 1 } }
		var before: Dictionary = GameState.deep_copy(GameState.state)
		assert_true(not GuardKit.unstock("v1", "blast", 1, 2)["ok"])
		assert_true(not GuardKit.unstock("v1", "blast", 2, 1)["ok"], "wrong tier")
		assert_eq(GameState.state, before)
	)

	run_case("active_units_takes_allowlist_order_then_highest_tier_first", func():
		var vein := _seed(2)  # capacity 4
		vein["guardKit"] = {
			"rewind": { "1": 1 },
			"shield": { "1": 1, "3": 1 },
			"blast": { "0": 1, "2": 1 },
		}
		assert_eq(GuardKit.active_units(vein), { "blast": { "2": 1, "0": 1 }, "shield": { "3": 1, "1": 1 } })
		assert_eq(GuardKit.active_units_of(vein["guardKit"], 1, 3), { "blast": { "2": 1, "0": 1 }, "shield": { "3": 1 } }, "kit-dict helper honours its own slots-per-guard")
	)

	run_case("dropping_a_guard_keeps_the_kit_but_makes_the_excess_inactive", func():
		var vein := _seed(2)
		Crafting.inventory_add("blast", 1, 4)
		assert_true(GuardKit.stock("v1", "blast", 1, 4)["ok"])
		assert_true(Cultivating.drop_vein_guard(vein))
		assert_eq(vein["guardKit"], { "blast": { "1": 4 } }, "kit intact")
		assert_eq(GuardKit.active_units(vein), { "blast": { "1": 2 } })
		Crafting.inventory_add("shield", 1, 1)
		assert_true(not GuardKit.stock("v1", "shield", 1, 1)["ok"], "refused while over capacity")
		assert_true(Cultivating.drop_vein_guard(vein))
		assert_eq(GuardKit.active_units(vein), {}, "0 guards: whole kit inactive")
	)

	run_case("stock_and_unstock_emit_state_changed", func():
		_seed(1)
		Crafting.inventory_add("blast", 1, 1)
		var hits := [0]
		var on_changed := func(): hits[0] += 1
		EventBus.state_changed.connect(on_changed)
		GuardKit.stock("v1", "blast", 1, 1)
		GuardKit.unstock("v1", "blast", 1, 1)
		EventBus.state_changed.disconnect(on_changed)
		assert_eq(hits[0], 2)
	)

	run_case("new_player_veins_carry_an_empty_guard_kit", func():
		var vein := Cultivating.make_vein("time", GameData.VEIN_GROWTH["seedGrowth"], "shoreditch", null, { "tier": "fair", "bonuses": [] })
		assert_eq(vein["guardKit"], {})
	)

	run_case("old_save_backfills_an_empty_kit_on_every_player_vein", func():
		GameState.reset()
		var save: Dictionary = GameState.deep_copy(GameState.state)
		save["player"]["veins"] = [Fixtures.player_vein_with(), Fixtures.player_vein_with({ "id": "v2" })]
		var result: Dictionary = SaveManager.backfill_defaults(save)
		for vein in result["player"]["veins"]:
			assert_eq(vein["guardKit"], {})
	)

	run_case("guard_kit_round_trips_through_save_and_load", func():
		var vein := _seed(2)
		vein["guardKit"] = { "shield": { "3": 2 }, "blast": { "0": 1 } }
		assert_true(SaveManager.save_to_slot(SAVE_TEST_SLOT)["ok"])
		GameState.reset()
		assert_true(SaveManager.load_from_slot(SAVE_TEST_SLOT)["ok"])
		SaveManager.delete_slot(SAVE_TEST_SLOT)
		var loaded: Dictionary = Cultivating.find_vein("v1")
		assert_eq(loaded["guardKit"], { "shield": { "3": 2 }, "blast": { "0": 1 } })
		assert_eq(typeof(loaded["guardKit"]["shield"]["3"]), TYPE_INT)
	)


	run_case("summary_lists_units_per_item_in_allowlist_order", func():
		assert_eq(GuardKit.summary_text({ "shield": { "3": 2 }, "blast": { "1": 1 } }), "Blast ×1 · Shield ×2")
		assert_eq(GuardKit.summary_text({ "shield": { "1": 1, "3": 2 } }), "Shield ×3", "tiers sum per item")
		assert_eq(GuardKit.summary_text({}), "")
	)

	run_case("a_vein_kit_target_reads_and_moves_that_veins_kit", func():
		var vein := _seed(2)
		Crafting.inventory_add("shield", 2, 3)
		var target := { "kind": "vein", "veinId": "v1" }
		assert_eq(GuardKit.target_capacity(target), 4)
		assert_eq(GuardKit.target_guard_count(target), 2)
		assert_true(GuardKit.stock_target(target, "shield", 2, 3)["ok"])
		assert_eq(GuardKit.target_kit(target), { "shield": { "2": 3 } })
		assert_true(GuardKit.unstock_target(target, "shield", 2, 1)["ok"])
		assert_eq(vein["guardKit"], { "shield": { "2": 2 } })
	)

	run_case("an_unknown_kit_target_is_empty_and_refuses_moves", func():
		_seed(2)
		Crafting.inventory_add("shield", 2, 1)
		var target := { "kind": "nowhere" }
		assert_eq(GuardKit.target_kit(target), {})
		assert_eq(GuardKit.target_capacity(target), 0)
		var before: Dictionary = GameState.deep_copy(GameState.state)
		assert_true(not GuardKit.stock_target(target, "shield", 2, 1)["ok"])
		assert_eq(GameState.state, before)
	)

# One player vein "v1" with `guards` guards (tier guard + extras).
func _seed(guards: int) -> Dictionary:
	GameState.reset()
	var vein := Fixtures.seed_vein("v1", 50)
	vein["guardKit"] = {}
	if guards > 0:
		vein["security"] = "guarded"
		vein["extraGuards"] = guards - 1
	return vein

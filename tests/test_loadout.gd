extends "res://tests/test_base.gd"

# Player loadout slots (systems/loadout.gd): equip/unequip conservation,
# allowlist, preferred-recipe memory, save round trip, old-save backfill.

const TEST_SLOT := 94


func _stock(recipe_key: String, tier: int) -> int:
	return int(GameState.state["player"]["inventory"].get(recipe_key, {}).get(str(tier), 0))


func run() -> void:
	run_case("a_fresh_game_has_two_empty_slots_with_no_remembered_recipe", func():
		GameState.reset()
		assert_eq(Loadout.slot_count(), 2)
		assert_eq(Loadout.slot(0), null)
		assert_eq(Loadout.slot(1), null)
		assert_eq(Loadout.last_recipe(0), "")
		assert_eq(Loadout.last_recipe(1), "")
	)

	run_case("equip_then_unequip_conserves_the_exact_tiered_unit", func():
		GameState.reset()
		Crafting.inventory_add("blast", 3, 2)
		Crafting.inventory_add("blast", 1, 1)
		assert_true(Loadout.equip(0, "blast", 3)["ok"])
		assert_eq(_stock("blast", 3), 1, "one tier-3 unit left shared inventory")
		assert_eq(_stock("blast", 1), 1, "other tiers untouched")
		assert_eq(Loadout.slot(0), { "recipe": "blast", "tier": 3 })
		assert_true(Loadout.unequip(0)["ok"])
		assert_eq(_stock("blast", 3), 2, "unit returns at its stored tier")
		assert_eq(Loadout.slot(0), null)
		assert_eq(Loadout.last_recipe(0), "blast", "unequip keeps the remembered recipe")
	)

	run_case("same_recipe_can_fill_both_slots", func():
		GameState.reset()
		Crafting.inventory_add("shield", 2, 2)
		assert_true(Loadout.equip(0, "shield", 2)["ok"])
		assert_true(Loadout.equip(1, "shield", 2)["ok"])
		assert_eq(_stock("shield", 2), 0)
		assert_eq(Loadout.equipped_units().size(), 2)
	)

	run_case("equip_fails_cleanly_with_no_stock_or_a_filled_slot", func():
		GameState.reset()
		var before: Dictionary = GameState.deep_copy(GameState.state["player"])
		assert_true(not Loadout.equip(0, "blast", 1)["ok"], "no stock")
		assert_eq(GameState.state["player"], before, "failed equip changes nothing")
		Crafting.inventory_add("blast", 1, 2)
		Loadout.equip(0, "blast", 1)
		assert_true(not Loadout.equip(0, "blast", 1)["ok"], "occupied slot")
		assert_true(not Loadout.equip(5, "blast", 1)["ok"], "bad index")
		assert_true(not Loadout.unequip(1)["ok"], "empty slot")
	)

	run_case("non_equippable_items_are_rejected_and_special_ones_allowed", func():
		GameState.reset()
		Crafting.inventory_add("healingSalve", 1, 1)
		assert_true(not Loadout.equip(0, "healingSalve", 1)["ok"], "Healing Salve rejected")
		assert_eq(_stock("healingSalve", 1), 1)
		for key in ["failsafe", "rewind", "wormhole"]:
			Crafting.inventory_add(key, 1, 1)
			assert_true(Loadout.equip(0, key, 1)["ok"], key)
			Loadout.unequip(0)
	)

	run_case("slots_and_remembered_recipe_survive_save_and_load", func():
		GameState.reset()
		Crafting.inventory_add("timePearl", 2, 1)
		Crafting.inventory_add("blast", 4, 1)
		Loadout.equip(1, "timePearl", 2)
		Loadout.equip(0, "blast", 4)
		Loadout.unequip(0)
		assert_true(SaveManager.save_to_slot(TEST_SLOT)["ok"])
		GameState.reset()
		assert_true(SaveManager.load_from_slot(TEST_SLOT)["ok"])
		assert_eq(Loadout.slot(0), null)
		assert_eq(Loadout.slot(1), { "recipe": "timePearl", "tier": 2 }, "tier restored as int")
		assert_eq(Loadout.last_recipe(0), "blast")
		assert_eq(Loadout.last_recipe(1), "timePearl")
		SaveManager.delete_slot(TEST_SLOT)
	)

	run_case("an_old_save_without_loadout_loads_with_empty_slots", func():
		GameState.reset()
		var raw: Dictionary = GameState.deep_copy(GameState.state)
		raw["player"].erase("loadout")
		var filled: Dictionary = SaveManager.backfill_defaults(raw)
		assert_eq(filled["player"]["loadout"], { "slots": [null, null], "lastRecipe": ["", ""] })
	)

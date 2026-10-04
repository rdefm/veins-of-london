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

	run_case("equipped_units_are_not_sellable", func():
		GameState.reset()
		Crafting.inventory_add("blast", 2, 2)
		Loadout.equip(0, "blast", 2)
		Loadout.equip(1, "blast", 2)
		var cash: int = int(GameState.state["player"]["cash"])
		GameState.state["sellState"]["con_blast_2"] = 2
		Economy.sell_from_sell_state()
		assert_eq(int(GameState.state["player"]["cash"]), cash, "nothing sold")
		assert_eq(Loadout.equipped_units().size(), 2, "slots untouched")
		Loadout.unequip(1)
		GameState.state["sellState"]["con_blast_2"] = 2
		Economy.sell_from_sell_state()
		assert_eq(_stock("blast", 2), 0, "only the unequipped remainder sold")
		assert_eq(Loadout.equipped_units().size(), 1, "equipped unit stays")
	)

	run_case("equipped_units_cannot_be_gifted", func():
		GameState.reset()
		Crafting.inventory_add("prophetsBreath", 1, 1)
		Loadout.equip(0, "prophetsBreath", 1)
		assert_true(not Diplomacy.giftable_items().has("prophetsBreath"), "not offered")
		assert_true(not Diplomacy.gift_item("lusk", "prophetsBreath")["ok"], "refused")
		assert_eq(Loadout.slot(0), { "recipe": "prophetsBreath", "tier": 1 })
		Crafting.inventory_add("prophetsBreath", 1, 1)
		assert_true(Diplomacy.gift_item("lusk", "prophetsBreath")["ok"], "remainder giftable")
		assert_eq(Loadout.slot(0), { "recipe": "prophetsBreath", "tier": 1 })
	)

	run_case("equipped_units_cannot_stock_a_guard_kit", func():
		GameState.reset()
		Crafting.inventory_add("blast", 1, 1)
		Loadout.equip(0, "blast", 1)
		var owner: Dictionary = {}
		assert_true(not GuardKit.stock_into(owner, "guardKit", 4, "blast", 1, 1)["ok"], "refused")
		assert_eq(Loadout.slot(0), { "recipe": "blast", "tier": 1 })
		Crafting.inventory_add("blast", 1, 1)
		assert_true(GuardKit.stock_into(owner, "guardKit", 4, "blast", 1, 1)["ok"], "remainder stockable")
		assert_eq(Loadout.slot(0), { "recipe": "blast", "tier": 1 })
	)

	run_case("an_equipped_rewind_is_not_event_usable_stock", func():
		GameState.reset()
		Crafting.inventory_add("rewind", 1, 1)
		assert_eq(EventItems._count({ "source": "consumable", "recipeKey": "rewind" }), 1)
		Loadout.equip(0, "rewind", 1)
		assert_eq(EventItems._count({ "source": "consumable", "recipeKey": "rewind" }), 0)
		assert_eq(Crafting.inventory_qty("rewind"), 0)
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

	run_case("combat_equip_and_unequip_are_refused", func():
		GameState.reset()
		Crafting.inventory_add("blast", 1, 1)
		Combat.start_mugging()
		assert_true(not Loadout.equip(0, "blast", 1)["ok"])
		Combat.exit_combat()
		Loadout.equip(0, "blast", 1)
		Combat.start_mugging()
		assert_true(not Loadout.unequip(0)["ok"])
	)

	run_case("using_a_slot_spends_it_with_no_refund_and_marks_it_used", func():
		GameState.reset()
		Crafting.inventory_add("blast", 3, 1)
		Loadout.equip(0, "blast", 3)
		Combat.start_mugging()
		var result: Dictionary = Combat.use_slot(0)
		assert_true(result["ok"])
		assert_eq(Loadout.slot(0), null)
		assert_eq(Crafting.inventory_qty("blast"), 0, "the spent unit is not refunded")
		assert_eq(GameState.state["combat"]["slotsUsed"], [0])
	)

	run_case("settlement_refills_a_used_slot_from_the_highest_tier_available", func():
		GameState.reset()
		Crafting.inventory_add("blast", 1, 1)
		Loadout.equip(0, "blast", 1)
		Crafting.inventory_add("blast", 2, 1)
		Crafting.inventory_add("blast", 4, 1)
		Combat.start_mugging()
		Combat.use_slot(0)
		Combat.exit_combat()
		assert_eq(Loadout.slot(0), { "recipe": "blast", "tier": 4 })
		assert_eq(_stock("blast", 4), 0)
		assert_eq(_stock("blast", 2), 1)
	)

	run_case("settlement_refills_slot_one_before_slot_two_and_may_run_short", func():
		GameState.reset()
		Crafting.inventory_add("blast", 1, 2)
		Loadout.equip(0, "blast", 1)
		Loadout.equip(1, "blast", 1)
		Crafting.inventory_add("blast", 3, 1)
		Combat.start_mugging()
		GameState.state["combat"]["enemies"][0]["hp"] = 1000
		GameState.state["combat"]["enemies"][0]["hpMax"] = 1000
		Combat.use_slot(1)
		Combat.use_slot(0)
		Combat.exit_combat()
		assert_eq(Loadout.slot(0), { "recipe": "blast", "tier": 3 }, "slot 1 takes the only unit")
		assert_eq(Loadout.slot(1), null, "slot 2 stays empty")
	)

	run_case("a_failed_refill_stays_empty_when_stock_arrives_later", func():
		GameState.reset()
		Crafting.inventory_add("blast", 1, 1)
		Loadout.equip(0, "blast", 1)
		Combat.start_mugging()
		Combat.use_slot(0)
		Combat.exit_combat()
		assert_eq(Loadout.slot(0), null)
		Crafting.inventory_add("blast", 2, 1)
		Combat.start_mugging()
		Combat.exit_combat()
		assert_eq(Loadout.slot(0), null, "a fight that used no slot never auto-fills")
		assert_eq(_stock("blast", 2), 1)
	)

	run_case("unused_units_stay_equipped_after_every_outcome", func():
		for outcome in ["win", "loss", "fled"]:
			GameState.reset()
			Crafting.inventory_add("blast", 2, 1)
			Loadout.equip(0, "blast", 2)
			Combat.start_mugging()
			GameState.state["combat"]["outcome"] = outcome
			Combat.exit_combat()
			assert_eq(Loadout.slot(0), { "recipe": "blast", "tier": 2 }, "kept after %s" % outcome)
	)

	run_case("a_rewind_slot_is_spent_not_refunded", func():
		GameState.reset()
		Crafting.inventory_add("rewind", 1, 1)
		Loadout.equip(0, "rewind", 1)
		Combat.start_mugging()
		Combat.push_combat_snapshot()
		var result: Dictionary = Combat.combat_rewind(0)
		assert_true(result["ok"])
		assert_eq(Loadout.slot(0), null)
		assert_eq(Crafting.inventory_qty("rewind"), 0)
	)

	run_case("slot_block_reason_covers_empty_reactive_and_rewind", func():
		GameState.reset()
		Combat.start_mugging()
		assert_eq(Combat.slot_block_reason(0), Combat.REASON_SLOT_EMPTY)
		GameState.state["player"]["loadout"]["slots"][0] = { "recipe": "failsafe", "tier": 1 }
		GameState.state["player"]["loadout"]["slots"][1] = { "recipe": "rewind", "tier": 1 }
		assert_eq(Combat.slot_block_reason(0), Combat.REASON_SLOT_REACTIVE)
		GameState.state["combat"]["snapshots"] = []
		assert_eq(Combat.slot_block_reason(1), Combat.REASON_NOTHING_TO_UNDO)
		Combat.push_combat_snapshot()
		assert_eq(Combat.slot_block_reason(1), "")
	)

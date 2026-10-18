extends "res://tests/test_base.gd"

const Fixtures := preload("res://tests/support/fixtures.gd")

# Multi-target crafting (Crafting.multi_craft_available, "_multi" inventory
# key) and combat honouring it through Loadout slots.

func _set_tier(recipe_key: String, tier: int) -> void:
	GameState.state["lab"]["bestRanks"][recipe_key] = tier

func _stock(key: String, tier: int) -> int:
	return int(GameState.state["player"]["inventory"].get(key, {}).get(str(tier), 0))

func run() -> void:
	run_case("checkbox_offered_only_from_tier_3_and_never_for_black_hole", func():
		GameState.reset()
		_set_tier("blast", 2)
		assert_true(not Crafting.multi_craft_available("blast"), "tier 2: hidden")
		_set_tier("blast", 3)
		assert_true(Crafting.multi_craft_available("blast"), "tier 3: shown")
		_set_tier("blackHole", 5)
		assert_true(not Crafting.multi_craft_available("blackHole"), "always multi: no checkbox")
		assert_true(Crafting.is_always_multi("blackHole"))
		_set_tier("timePearl", 5)
		assert_true(not Crafting.multi_craft_available("timePearl"), "not a targeted item")
	)

	run_case("equip_multi_then_unequip_conserves_the_multi_unit", func():
		GameState.reset()
		Crafting.inventory_add("blast_multi", 3, 1)
		var stock := Loadout.equippable_stock()
		assert_eq(stock, [{ "recipe": "blast", "tier": 3, "qty": 1, "multi": true }])
		assert_true(Loadout.equip(0, "blast", 3, "", true)["ok"])
		assert_eq(Loadout.slot(0), { "recipe": "blast", "tier": 3, "multi": true })
		Loadout.unequip(0)
		assert_eq(_stock("blast_multi", 3), 1)
		assert_eq(Crafting.inventory_qty("blast"), 0)
	)

	run_case("settlement_refills_the_same_variant", func():
		GameState.reset()
		Crafting.inventory_add("blast_multi", 3, 2)
		Crafting.inventory_add("blast", 5, 1)
		Loadout.equip(0, "blast", 3, "", true)
		Combat.start_street_mugging()
		Loadout.consume(0)
		Loadout.refill_used([0])
		assert_eq(Loadout.slot(0), { "recipe": "blast", "tier": 3, "multi": true })
		assert_eq(_stock("blast", 5), 1, "single stock left alone")
	)

	run_case("dial_load_and_unload_round_trip_the_multi_key", func():
		GameState.reset()
		GameState.state["player"]["dial"] = Fixtures.dial_with_loaded("shield", 1, 5)
		GameState.state["player"]["dial"]["loadedComplications"].clear()
		GameState.state["player"]["dial"]["capacityMax"] = 3
		Crafting.inventory_add("shield_multi", 3, 1)
		assert_true(Dial.load_complication("shield", 3, "", true)["ok"])
		assert_eq(GameState.state["player"]["dial"]["loadedComplications"][0]["multi"], true)
		assert_eq(_stock("shield_multi", 3), 0)
		Dial.unload_complication(0)
		assert_eq(_stock("shield_multi", 3), 1)
		assert_eq(Crafting.inventory_qty("shield"), 0)
	)

	run_case("multi_pan_items_craftable_at_tier_3_only", func():
		for key in ["panic", "panger", "pandemonium", "pansRapture"]:
			_set_tier(key, 2)
			assert_true(not Crafting.multi_craft_available(key), "%s tier 2: hidden" % key)
			_set_tier(key, 3)
			assert_true(Crafting.multi_craft_available(key), "%s tier 3: shown" % key)
	)



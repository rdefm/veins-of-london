extends "res://tests/test_base.gd"

const Fixtures := preload("res://tests/support/fixtures.gd")

# Multi-target crafting (Crafting.multi_craft_available, "_multi" inventory
# key) and combat honouring it through Loadout slots.


func _set_tier(recipe_key: String, tier: int) -> void:
	var d: Dictionary = GameData.RECIPES[recipe_key]["discovery"]
	var key := Bench.cell_key(d["types"], d["approach"])
	GameState.state["player"]["bench"]["cells"][key] = { "state": "hot", "misses": 0, "tier": tier, "progress": 0 }


func _stock(key: String, tier: int) -> int:
	return int(GameState.state["player"]["inventory"].get(key, {}).get(str(tier), 0))


func _fight(enemy_count: int, allies: Array = []) -> Dictionary:
	var enemies: Array = []
	for i in range(enemy_count):
		enemies.append({
			"name": "Enemy %d" % i, "hp": 100, "hpMax": 100, "attackMin": 0, "attackMax": 0,
			"isMugging": false, "weapon": null, "ability": null, "evadeChance": 0.0, "speed": 10, "koed": false,
		})
	GameState.state["combat"] = {
		"active": true, "context": Combat.CONTEXT_RAID, "veinId": null,
		"enemies": enemies, "selection": { "type": "enemy", "index": 0 },
		"log": [], "outcome": null, "frozenTurns": 0, "motionTurns": 0, "motionPower": 0,
		"evadeTurns": 0, "evadeChance": 0.0, "onWin": "", "snapshots": [], "beatsSinceSnapshot": [],
		"allies": allies,
		"turnCursor": { "queue": [], "index": 0, "round": 0 },
	}
	return GameState.state["combat"]


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

	run_case("multi_craft_files_under_the_multi_key", func():
		GameState.reset()
		_set_tier("blast", 3)
		GameState.state["player"]["orichalchum"]["physics"] = 50
		GameState.state["player"]["craftingSkill"] = 5
		var saved: float = GameData.RECIPES["blast"]["baseSuccess"]
		GameData.RECIPES["blast"]["baseSuccess"] = 5.0
		var result := Crafting.attempt_craft("blast", true)
		GameData.RECIPES["blast"]["baseSuccess"] = saved
		assert_true(result["success"])
		assert_eq(_stock("blast_multi", 3), 1, "multi unit in parallel key")
		assert_eq(Crafting.inventory_qty("blast"), 0, "single stock untouched")
	)

	run_case("multi_request_ignored_below_tier_3", func():
		GameState.reset()
		_set_tier("blast", 2)
		GameState.state["player"]["orichalchum"]["physics"] = 50
		GameState.state["player"]["craftingSkill"] = 5
		var saved: float = GameData.RECIPES["blast"]["baseSuccess"]
		GameData.RECIPES["blast"]["baseSuccess"] = 5.0
		Crafting.attempt_craft("blast", true)
		GameData.RECIPES["blast"]["baseSuccess"] = saved
		assert_eq(_stock("blast_multi", 2), 0)
		assert_eq(_stock("blast", 2), 1, "falls back to single")
	)

	run_case("equip_multi_then_unequip_conserves_the_multi_unit", func():
		GameState.reset()
		Crafting.inventory_add("blast_multi", 3, 1)
		var stock := Loadout.equippable_stock()
		assert_eq(stock, [{ "recipe": "blast", "tier": 3, "qty": 1, "multi": true }])
		assert_true(Loadout.equip(0, "blast", 3, "", true)["ok"])
		assert_eq(Loadout.slot(0), { "recipe": "blast", "tier": 3, "multi": true })
		assert_true(Loadout.slot_is_multi(0))
		Loadout.unequip(0)
		assert_eq(_stock("blast_multi", 3), 1)
		assert_eq(Crafting.inventory_qty("blast"), 0)
	)

	run_case("multi_blast_hits_every_living_enemy_without_a_selection", func():
		GameState.reset()
		Crafting.inventory_add("blast_multi", 3, 1)
		Loadout.equip(0, "blast", 3, "", true)
		var combat := _fight(3)
		combat["enemies"][2]["koed"] = true
		combat["selection"] = { "type": "ally", "index": 0 }
		var result := Combat.use_slot(0)
		assert_true(result["ok"], str(result))
		assert_eq(combat["enemies"][0]["hp"], 92)
		assert_eq(combat["enemies"][1]["hp"], 92)
		assert_eq(combat["enemies"][2]["hp"], 100, "koed enemy skipped")
	)

	run_case("single_blast_still_hits_only_the_selected_enemy", func():
		GameState.reset()
		Crafting.inventory_add("blast", 3, 1)
		Loadout.equip(0, "blast", 3)
		var combat := _fight(2)
		combat["selection"] = { "type": "enemy", "index": 1 }
		Combat.use_slot(0)
		assert_eq(combat["enemies"][0]["hp"], 100)
		assert_eq(combat["enemies"][1]["hp"], 92)
	)

	run_case("multi_shield_covers_the_allies_too", func():
		GameState.reset()
		GameState.state["contacts"]["archie"]["recruited"] = true
		Crafting.inventory_add("shield_multi", 3, 1)
		Loadout.equip(0, "shield", 3, "", true)
		var combat := _fight(1, [Contacts.build_combat_ally("archie")])
		var power: int = int(Crafting.effect_power("shield", 3))
		var result := Combat.use_slot(0)
		assert_true(result["ok"], str(result))
		assert_eq(GameState.state["player"]["shieldPool"], power)
		assert_eq(combat["allies"][0]["shieldPool"], power)
	)

	run_case("multi_healing_burst_heals_every_standing_ally_and_the_player", func():
		GameState.reset()
		GameState.state["contacts"]["archie"]["recruited"] = true
		Crafting.inventory_add("healingBurst_multi", 3, 1)
		Loadout.equip(0, "healingBurst", 3, "", true)
		var ally := Contacts.build_combat_ally("archie")
		ally["hp"] = 1
		var combat := _fight(1, [ally])
		GameState.state["player"]["hp"] = 1
		var power: int = int(Crafting.effect_power("healingBurst", 3))
		var result := Combat.use_slot(0)
		assert_true(result["ok"], str(result))
		assert_eq(combat["allies"][0]["hp"], mini(1 + power, combat["allies"][0]["hpMax"]))
		assert_eq(GameState.state["player"]["hp"], mini(1 + power, GameState.state["player"]["hpMax"]))
	)

	run_case("black_hole_hits_every_enemy_with_no_multi_flag", func():
		GameState.reset()
		Crafting.inventory_add("blackHole", 1, 1)
		Loadout.equip(0, "blackHole", 1)
		var combat := _fight(2)
		combat["selection"] = { "type": "ally", "index": 0 }
		assert_true(Loadout.slot_is_multi(0))
		var result := Combat.use_slot(0)
		assert_true(result["ok"], str(result))
		assert_true(combat["enemies"][0]["hp"] < 100)
		assert_true(combat["enemies"][1]["hp"] < 100)
	)

	run_case("settlement_refills_the_same_variant", func():
		GameState.reset()
		Crafting.inventory_add("blast_multi", 3, 2)
		Crafting.inventory_add("blast", 5, 1)
		Loadout.equip(0, "blast", 3, "", true)
		_fight(1)
		Combat.use_slot(0)
		Loadout.refill_used([0])
		assert_eq(Loadout.slot(0), { "recipe": "blast", "tier": 3, "multi": true })
		assert_eq(_stock("blast", 5), 1, "single stock left alone")
	)

	run_case("dial_multi_shield_covers_allies_single_shield_only_the_caster", func():
		for multi in [true, false]:
			GameState.reset()
			GameState.state["contacts"]["archie"]["recruited"] = true
			var combat := _fight(1, [Contacts.build_combat_ally("archie")])
			var dial: Dictionary = Fixtures.dial_with_loaded("shield", 3, 5)
			if multi:
				dial["loadedComplications"][0]["multi"] = true
			GameState.state["player"]["dial"] = dial
			var result := Combat.cast_complication(0)
			assert_true(result["ok"], str(result))
			assert_true(GameState.state["player"]["shieldPool"] > 0, "caster shielded")
			assert_eq(int(combat["allies"][0].get("shieldPool", 0)) > 0, multi, "ally shielded only when multi")
	)

	run_case("dial_multi_blast_hits_all_without_a_selection", func():
		GameState.reset()
		var combat := _fight(2)
		combat["selection"] = { "type": "ally", "index": 0 }
		var dial: Dictionary = Fixtures.dial_with_loaded("blast", 3, 5)
		dial["loadedComplications"][0]["multi"] = true
		GameState.state["player"]["dial"] = dial
		var result := Combat.cast_complication(0)
		assert_true(result["ok"], str(result))
		assert_true(combat["enemies"][0]["hp"] < 100 and combat["enemies"][1]["hp"] < 100)
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

	run_case("multi_pan_statuses_hit_every_living_unafflicted_enemy_from_loadout", func():
		for key in ["panic", "pansRapture", "panger", "pandemonium"]:
			GameState.reset()
			Crafting.inventory_add(key + "_multi", 3, 1)
			Loadout.equip(0, key, 3, "", true)
			var combat := _fight(4)
			combat["enemies"][2]["koed"] = true
			combat["enemies"][3]["raptureTurns"] = 2
			combat["selection"] = { "type": "ally", "index": 0 }
			var result := Combat.use_slot(0)
			assert_true(result["ok"], "%s: %s" % [key, str(result)])
			for i in [0, 1]:
				assert_true(Combat._has_pan_status(combat["enemies"][i]), "%s hits enemy %d" % [key, i])
			assert_true(not Combat._has_pan_status(combat["enemies"][2]), "%s skips koed" % key)
			assert_eq(combat["enemies"][3].get("panicTurns", 0), 0, "%s skips already afflicted" % key)
	)

	run_case("dial_multi_pan_statuses_hit_every_enemy_without_a_selection", func():
		for key in ["panic", "pansRapture", "panger", "pandemonium"]:
			GameState.reset()
			var combat := _fight(3)
			combat["selection"] = { "type": "ally", "index": 0 }
			var dial: Dictionary = Fixtures.dial_with_loaded(key, 3, 5)
			dial["loadedComplications"][0]["multi"] = true
			GameState.state["player"]["dial"] = dial
			var result := Combat.cast_complication(0)
			assert_true(result["ok"], "%s: %s" % [key, str(result)])
			for i in range(3):
				assert_true(Combat._has_pan_status(combat["enemies"][i]), "%s hits enemy %d" % [key, i])
	)

	run_case("multi_pan_refused_when_every_enemy_already_afflicted", func():
		GameState.reset()
		var combat := _fight(2)
		for enemy in combat["enemies"]:
			enemy["panicTurns"] = 1
		var dial: Dictionary = Fixtures.dial_with_loaded("panger", 3, 5)
		dial["loadedComplications"][0]["multi"] = true
		GameState.state["player"]["dial"] = dial
		assert_true(not Combat.cast_complication(0)["ok"])
		assert_eq(GameState.state["player"]["dial"]["currentCharge"], 5, "no charge spent")
	)

extends "res://tests/test_base.gd"

# dial-device ticket 01. Every case calls Dial.* directly against
# GameState.state, same seam as test_sites.gd/test_devices.gd. Rng.set_seed
# determinism follows test_devices.gd's own
# device_build_progress_ladder_10_to_100_in_18_successes pattern: loop
# seeds until the desired success/failure outcome is observed.

const HAFT_ID := "collective_brolly"


static func _fund_seed_cost(multiplier: int = 1) -> void:
	var orichalchum: Dictionary = GameState.state["player"]["orichalchum"]
	for ore_type in GameData.DIAL_SEED_COST:
		orichalchum[ore_type] = GameData.DIAL_SEED_COST[ore_type] * multiplier


# ticket 02 fixtures.

static func _dial_no_movement() -> Dictionary:
	return { "level": 1, "xp": 0, "currentCharge": 0, "maxCharge": 0, "rechargeRate": 0, "combatRegenTurnCounter": 0, "lastRegenDay": 1, "capacityMax": 0, "movement": null, "loadedComplications": [], "haftId": HAFT_ID }


# Same shape as test_sites.gd/test_cultivating.gd's own _find_seed_for.
static func _find_seed_for(max_tries: int, fn: Callable) -> int:
	for seed in range(max_tries):
		var snapshot: Dictionary = GameState.deep_copy(GameState.state)
		Rng.set_seed(seed)
		if fn.call():
			return seed
		GameState.state = snapshot
	return -1


func run() -> void:
	run_case("attempt_seed_refuses_with_no_gift_flag", func():
		GameState.reset()
		_fund_seed_cost(10)
		var result := Dial.attempt_seed(HAFT_ID)
		assert_true(not result["ok"], "seeding should be refused with no gift flag")
		assert_eq(GameState.state["player"]["dial"], null, "no dial should be created")
	)

	run_case("attempt_seed_refuses_without_enough_calc", func():
		GameState.reset()
		GameState.state["flags"]["dialGiftGranted"] = true
		var result := Dial.attempt_seed(HAFT_ID)
		assert_true(not result["ok"], "seeding should be refused without the full mixed cost on hand")
	)

	run_case("attempt_seed_refuses_an_unknown_haft", func():
		GameState.reset()
		GameState.state["flags"]["dialGiftGranted"] = true
		_fund_seed_cost(10)
		var result := Dial.attempt_seed("not_a_real_haft")
		assert_true(not result["ok"], "seeding should be refused for a haft not in the whitelist")
		assert_eq(GameState.state["player"]["dial"], null, "no dial should be created")
	)

	run_case("attempt_seed_consumes_the_full_mixed_cost_on_success", func():
		GameState.reset()
		GameState.state["flags"]["dialGiftGranted"] = true
		GameState.state["player"]["craftingSkill"] = 5
		GameState.state["player"]["cultivatingSkill"] = 5  # high combined chance, fewer seed retries needed
		_fund_seed_cost(1)

		var success := false
		var seed := 0
		while not success and seed < 2000:
			var snapshot: Dictionary = GameState.deep_copy(GameState.state)
			Rng.set_seed(seed)
			var result := Dial.attempt_seed(HAFT_ID)
			seed += 1
			if result["success"]:
				success = true
			else:
				GameState.state = snapshot
				_fund_seed_cost(1)

		assert_true(success, "should find a successful seed within 2000 tries at high combined skill")
		for ore_type in GameData.DIAL_SEED_COST:
			assert_eq(GameState.state["player"]["orichalchum"][ore_type], 0, "%s should be fully spent on a successful seed" % ore_type)
	)

	run_case("attempt_seed_consumes_the_full_mixed_cost_on_failure_with_no_partial_dial", func():
		GameState.reset()
		GameState.state["flags"]["dialGiftGranted"] = true
		GameState.state["player"]["craftingSkill"] = 1
		GameState.state["player"]["cultivatingSkill"] = 1  # low combined chance, plenty of fails to observe

		var found_failure := false
		var seed := 0
		while not found_failure and seed < 2000:
			GameState.state["player"]["dial"] = null
			_fund_seed_cost(1)
			Rng.set_seed(seed)
			var result := Dial.attempt_seed(HAFT_ID)
			seed += 1
			if not result["success"]:
				found_failure = true
				for ore_type in GameData.DIAL_SEED_COST:
					assert_eq(GameState.state["player"]["orichalchum"][ore_type], 0, "%s should be fully spent even on a failed seed" % ore_type)
				assert_eq(GameState.state["player"]["dial"], null, "a failed seed must leave no partial dial state")

		assert_true(found_failure, "should find a failed seed within 2000 tries at low combined skill")
	)

	run_case("attempt_seed_success_produces_an_inert_no_movement_dial", func():
		GameState.reset()
		GameState.state["flags"]["dialGiftGranted"] = true
		GameState.state["player"]["craftingSkill"] = 5
		GameState.state["player"]["cultivatingSkill"] = 5
		_fund_seed_cost(1)

		var success := false
		var seed := 0
		while not success and seed < 2000:
			var snapshot: Dictionary = GameState.deep_copy(GameState.state)
			Rng.set_seed(seed)
			var result := Dial.attempt_seed(HAFT_ID)
			seed += 1
			if result["success"]:
				success = true
			else:
				GameState.state = snapshot
				_fund_seed_cost(1)

		assert_true(success, "should find a successful seed within 2000 tries")
		var dial: Variant = GameState.state["player"]["dial"]
		assert_true(dial != null, "a successful seed should produce a non-null dial")
		assert_eq(dial["movement"], null, "a freshly-seeded dial has no Movement seated")
		assert_eq(dial["currentCharge"], 0, "a freshly-seeded dial has no charge")
		assert_eq(dial["maxCharge"], 0, "a freshly-seeded dial has no charge pool")
		assert_eq(dial["rechargeRate"], 0, "a freshly-seeded dial has no regen")
		assert_eq(dial["loadedComplications"], [], "a freshly-seeded dial has no loaded Complications")
		assert_eq(dial["level"], 1, "a freshly-seeded dial starts at level 1")
		assert_eq(dial["xp"], 0, "a freshly-seeded dial starts at 0 xp")
		assert_eq(dial["haftId"], HAFT_ID, "the seeded dial records the chosen haft")
	)

	run_case("attempt_seed_refuses_outright_once_a_dial_already_exists", func():
		GameState.reset()
		GameState.state["flags"]["dialGiftGranted"] = true
		GameState.state["player"]["dial"] = { "level": 1, "xp": 0, "currentCharge": 0, "maxCharge": 0, "rechargeRate": 0, "capacityMax": 0, "movement": null, "loadedComplications": [], "haftId": HAFT_ID }
		_fund_seed_cost(10)

		var result := Dial.attempt_seed(HAFT_ID)
		assert_true(not result["ok"], "seeding a second dial should be refused outright")
	)

	run_case("set_haft_swaps_freely_with_no_validation_beyond_haft_exists", func():
		GameState.reset()
		GameState.state["player"]["dial"] = { "level": 1, "xp": 0, "currentCharge": 0, "maxCharge": 0, "rechargeRate": 0, "capacityMax": 0, "movement": null, "loadedComplications": [], "haftId": HAFT_ID }

		var ok_result := Dial.set_haft("guild_cane")
		assert_true(ok_result["ok"], "swapping to any whitelisted haft should succeed")
		assert_eq(GameState.state["player"]["dial"]["haftId"], "guild_cane", "haftId should update to the newly chosen haft")

		var bad_result := Dial.set_haft("not_a_real_haft")
		assert_true(not bad_result["ok"], "an unknown haft should be refused")
		assert_eq(GameState.state["player"]["dial"]["haftId"], "guild_cane", "a refused swap must not change haftId")
	)

	run_case("set_haft_refuses_with_no_dial", func():
		GameState.reset()
		var result := Dial.set_haft(HAFT_ID)
		assert_true(not result["ok"], "setting a haft with no dial should be refused")
	)

	# ── ticket 02: Movement crafting ────────────────────────────────────

	run_case("attempt_craft_movement_refuses_an_unknown_archetype", func():
		GameState.reset()
		var result := Dial.attempt_craft_movement("not_a_real_archetype", "time")
		assert_true(not result["ok"], "an unknown archetype should be refused")
	)

	run_case("attempt_craft_movement_refuses_an_unknown_ore_type", func():
		GameState.reset()
		var result := Dial.attempt_craft_movement("impact", "not_a_real_ore")
		assert_true(not result["ok"], "an unknown ore type should be refused")
	)

	run_case("attempt_craft_movement_refuses_without_enough_calc", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["time"] = 5
		var result := Dial.attempt_craft_movement("impact", "time")
		assert_true(not result["ok"], "insufficient calc should be refused")
	)

	run_case("attempt_craft_movement_deducts_ingredient_regardless_of_outcome", func():
		GameState.reset()
		GameState.state["player"]["craftingSkill"] = 1
		GameState.state["player"]["orichalchum"]["time"] = 100
		Dial.attempt_craft_movement("impact", "time")
		assert_eq(GameState.state["player"]["orichalchum"]["time"], 80, "ingredientBase 20 deducted regardless of success/fail, at skill 1")
	)

	run_case("attempt_craft_movement_success_records_the_chosen_ore_type_as_attunement_and_tier_from_skill", func():
		var seed := _find_seed_for(200, func():
			GameState.reset()
			GameState.state["player"]["craftingSkill"] = 5
			GameState.state["player"]["orichalchum"]["physics"] = 1000
			var result := Dial.attempt_craft_movement("capacitor", "physics")
			return result.get("success", false)
		)
		assert_true(seed != -1, "should find a successful Movement craft within 200 tries")

		var inventory: Array = GameState.state["player"]["movementInventory"]
		assert_eq(inventory.size(), 1, "one crafted Movement lands in movementInventory")
		assert_eq(inventory[0]["archetype"], "capacitor", "archetype matches what was crafted")
		assert_eq(inventory[0]["oreType"], "physics", "the chosen ore type becomes the Movement's attunement")
		assert_eq(inventory[0]["tier"], 5, "tier is set from crafting skill at craft time, exactly like Crafting.quality_tier()'s non-refined branch")
	)

	run_case("attempt_craft_movement_failure_leaves_no_partial_movement", func():
		var seed := _find_seed_for(200, func():
			GameState.reset()
			GameState.state["player"]["craftingSkill"] = 1
			GameState.state["player"]["orichalchum"]["time"] = 1000
			var result := Dial.attempt_craft_movement("recharge", "time")
			return not result.get("success", true)
		)
		assert_true(seed != -1, "should find a failed Movement craft within 200 tries")
		assert_eq(GameState.state["player"]["movementInventory"], [], "a failed craft must leave no partial Movement in inventory")
	)

	# ── ticket 02: seating / unseating ───────────────────────────────────

	run_case("seat_movement_refuses_with_no_dial", func():
		GameState.reset()
		GameState.state["player"]["movementInventory"] = [{ "archetype": "impact", "oreType": "time", "tier": 1 }]
		var result := Dial.seat_movement(0)
		assert_true(not result["ok"], "seating with no Dial should be refused")
	)

	run_case("seat_movement_refuses_an_out_of_range_index", func():
		GameState.reset()
		GameState.state["player"]["dial"] = _dial_no_movement()
		var result := Dial.seat_movement(0)
		assert_true(not result["ok"], "seating from an empty movementInventory should be refused")
	)

	run_case("seat_movement_moves_it_out_of_inventory_and_into_the_dial", func():
		GameState.reset()
		GameState.state["player"]["dial"] = _dial_no_movement()
		GameState.state["player"]["movementInventory"] = [{ "archetype": "impact", "oreType": "time", "tier": 3 }]

		var result := Dial.seat_movement(0)
		assert_true(result["ok"], "seating a valid inventory index should succeed")
		assert_eq(GameState.state["player"]["movementInventory"], [], "the seated Movement leaves movementInventory")
		assert_eq(GameState.state["player"]["dial"]["movement"], { "archetype": "impact", "oreType": "time", "tier": 3 }, "the Movement is now seated on the dial")
	)

	run_case("seat_movement_swaps_the_previously_seated_movement_back_into_inventory", func():
		GameState.reset()
		var dial := _dial_no_movement()
		dial["movement"] = { "archetype": "recharge", "oreType": "life", "tier": 2 }
		GameState.state["player"]["dial"] = dial
		GameState.state["player"]["movementInventory"] = [{ "archetype": "impact", "oreType": "time", "tier": 3 }]

		Dial.seat_movement(0)
		assert_eq(GameState.state["player"]["dial"]["movement"], { "archetype": "impact", "oreType": "time", "tier": 3 }, "the newly chosen Movement is now seated")
		assert_eq(GameState.state["player"]["movementInventory"], [{ "archetype": "recharge", "oreType": "life", "tier": 2 }], "the previously seated Movement returns to inventory intact, not destroyed")
	)

	run_case("unseat_movement_refuses_with_no_dial", func():
		GameState.reset()
		var result := Dial.unseat_movement()
		assert_true(not result["ok"], "unseating with no Dial should be refused")
	)

	run_case("unseat_movement_refuses_with_nothing_seated", func():
		GameState.reset()
		GameState.state["player"]["dial"] = _dial_no_movement()
		var result := Dial.unseat_movement()
		assert_true(not result["ok"], "unseating an already-empty Dial should be refused")
	)

	run_case("unseat_movement_returns_it_to_inventory_intact", func():
		GameState.reset()
		var dial := _dial_no_movement()
		dial["movement"] = { "archetype": "spread", "oreType": "fate", "tier": 4 }
		GameState.state["player"]["dial"] = dial

		var result := Dial.unseat_movement()
		assert_true(result["ok"], "unseating a seated Movement should succeed")
		assert_eq(GameState.state["player"]["dial"]["movement"], null, "the dial has no Movement seated afterward")
		assert_eq(GameState.state["player"]["movementInventory"], [{ "archetype": "spread", "oreType": "fate", "tier": 4 }], "the unseated Movement returns to inventory intact, not destroyed")
	)

	# ── ticket 02: attunement bonus ──────────────────────────────────────

	run_case("attunement_bonus_is_zero_with_no_dial", func():
		GameState.reset()
		assert_eq(Dial.attunement_bonus("time"), 0.0, "no Dial means no attunement bonus")
	)

	run_case("attunement_bonus_is_zero_with_a_dial_but_no_movement_seated", func():
		GameState.reset()
		GameState.state["player"]["dial"] = _dial_no_movement()
		assert_eq(Dial.attunement_bonus("time"), 0.0, "an inert Dial grants no attunement bonus")
	)

	run_case("attunement_bonus_is_zero_on_a_mismatched_ore_type", func():
		GameState.reset()
		var dial := _dial_no_movement()
		dial["movement"] = { "archetype": "impact", "oreType": "physics", "tier": 3 }
		GameState.state["player"]["dial"] = dial
		assert_eq(Dial.attunement_bonus("time"), 0.0, "a mismatched ore type must not receive the bonus")
	)

	run_case("attunement_bonus_matches_the_tier_indexed_curve_on_a_matching_ore_type", func():
		GameState.reset()
		var dial := _dial_no_movement()
		dial["movement"] = { "archetype": "impact", "oreType": "physics", "tier": 3 }
		GameState.state["player"]["dial"] = dial
		assert_almost_eq(Dial.attunement_bonus("physics"), GameData.DIAL_ATTUNEMENT_BONUS_BY_TIER[3], 0.0001, "a matching ore type gets exactly the seated Movement's tier-indexed bonus")
	)

	run_case("attunement_bonus_changes_immediately_when_a_different_movement_is_seated", func():
		GameState.reset()
		var dial := _dial_no_movement()
		dial["movement"] = { "archetype": "impact", "oreType": "time", "tier": 1 }
		GameState.state["player"]["dial"] = dial
		var before: float = Dial.attunement_bonus("time")

		GameState.state["player"]["movementInventory"] = [{ "archetype": "capacitor", "oreType": "time", "tier": 5 }]
		Dial.seat_movement(0)
		var after: float = Dial.attunement_bonus("time")
		assert_true(after > before, "reseating a higher-tier Movement should raise the bonus immediately")
	)

	run_case("attunement_bonus_disappears_once_unseated", func():
		GameState.reset()
		var dial := _dial_no_movement()
		dial["movement"] = { "archetype": "impact", "oreType": "time", "tier": 5 }
		GameState.state["player"]["dial"] = dial
		assert_true(Dial.attunement_bonus("time") > 0.0, "a seated matching Movement should grant a nonzero bonus")

		Dial.unseat_movement()
		assert_eq(Dial.attunement_bonus("time"), 0.0, "the bonus disappears once no Movement is seated")
	)

	run_case("attunement_bonus_is_unaffected_by_loadedComplications", func():
		GameState.reset()
		var dial := _dial_no_movement()
		dial["movement"] = { "archetype": "impact", "oreType": "time", "tier": 3 }
		dial["loadedComplications"] = [{ "recipeKey": "blast", "tier": 5, "capacityCost": 3, "detent": 0 }]
		GameState.state["player"]["dial"] = dial
		assert_almost_eq(Dial.attunement_bonus("time"), GameData.DIAL_ATTUNEMENT_BONUS_BY_TIER[3], 0.0001, "loadedComplications must never affect the attunement bonus")
	)

	# ── ticket 03: capacity budget ───────────────────────────────────────

	run_case("capacity_max_reads_the_dial_level_lookup_table", func():
		for level in range(GameData.DIAL_CAPACITY_BY_LEVEL.size()):
			assert_eq(Dial.capacity_max(level), GameData.DIAL_CAPACITY_BY_LEVEL[level], "capacity_max(%d) should match the data table" % level)
	)

	run_case("capacityMax_is_unaffected_by_seating_or_unseating_a_movement", func():
		GameState.reset()
		var dial := _dial_no_movement()
		dial["capacityMax"] = 7
		GameState.state["player"]["dial"] = dial
		GameState.state["player"]["movementInventory"] = [{ "archetype": "capacitor", "oreType": "physics", "tier": 5 }]

		Dial.seat_movement(0)
		assert_eq(GameState.state["player"]["dial"]["capacityMax"], 7, "seating a Movement (even a high-tier one) must not change capacityMax")

		Dial.unseat_movement()
		assert_eq(GameState.state["player"]["dial"]["capacityMax"], 7, "unseating a Movement must not change capacityMax either")
	)

	run_case("attempt_seed_success_populates_capacityMax_from_the_level_1_lookup", func():
		GameState.reset()
		GameState.state["flags"]["dialGiftGranted"] = true
		GameState.state["player"]["craftingSkill"] = 5
		GameState.state["player"]["cultivatingSkill"] = 5
		_fund_seed_cost(1)

		var success := false
		var seed := 0
		while not success and seed < 2000:
			var snapshot: Dictionary = GameState.deep_copy(GameState.state)
			Rng.set_seed(seed)
			var result := Dial.attempt_seed(HAFT_ID)
			seed += 1
			if result["success"]:
				success = true
			else:
				GameState.state = snapshot
				_fund_seed_cost(1)

		assert_true(success, "should find a successful seed within 2000 tries")
		assert_eq(GameState.state["player"]["dial"]["capacityMax"], GameData.DIAL_CAPACITY_BY_LEVEL[1], "a freshly-seeded level-1 dial's capacityMax comes from the lookup table, not zero")
	)

	# ── ticket 03: loading Complications ─────────────────────────────────

	run_case("load_complication_refuses_with_no_dial", func():
		GameState.reset()
		Crafting.inventory_add("timePearl", 3)
		var result := Dial.load_complication("timePearl", 3)
		assert_true(not result["ok"], "loading with no Dial should be refused")
	)

	run_case("load_complication_refuses_an_unknown_recipe", func():
		GameState.reset()
		var dial := _dial_no_movement()
		dial["capacityMax"] = 10
		GameState.state["player"]["dial"] = dial
		var result := Dial.load_complication("not_a_real_recipe", 1)
		assert_true(not result["ok"], "an unknown recipe should be refused")
	)

	run_case("load_complication_refuses_with_nothing_in_that_tier_bucket", func():
		GameState.reset()
		var dial := _dial_no_movement()
		dial["capacityMax"] = 10
		GameState.state["player"]["dial"] = dial
		Crafting.inventory_add("timePearl", 3, 1)
		var result := Dial.load_complication("timePearl", 2)
		assert_true(not result["ok"], "loading from a tier bucket with no stock should be refused")
		assert_eq(GameState.state["player"]["dial"]["loadedComplications"], [], "a refused load must not append anything")
	)

	run_case("load_complication_decrements_inventory_and_appends_at_the_recipes_fixed_capacity_cost", func():
		GameState.reset()
		var dial := _dial_no_movement()
		dial["capacityMax"] = 10
		GameState.state["player"]["dial"] = dial
		Crafting.inventory_add("blast", 4, 1)

		var result := Dial.load_complication("blast", 4)
		assert_true(result["ok"], "loading a unit that exists in that tier bucket should succeed")
		assert_eq(Crafting.inventory_qty("blast"), 0, "the loaded unit leaves the regular tiered inventory")
		var loaded: Array = GameState.state["player"]["dial"]["loadedComplications"]
		assert_eq(loaded.size(), 1, "one Complication should now be loaded")
		assert_eq(loaded[0]["recipeKey"], "blast", "recipeKey is recorded")
		assert_eq(loaded[0]["tier"], 4, "the loaded unit keeps the tier it was crafted at, unchanged")
		assert_eq(loaded[0]["capacityCost"], GameData.RECIPES["blast"]["capacityCost"], "capacityCost is copied from the recipe's fixed data field")
	)

	run_case("load_complication_capacity_cost_is_independent_of_crafted_tier", func():
		GameState.reset()
		var dial := _dial_no_movement()
		dial["capacityMax"] = 10
		GameState.state["player"]["dial"] = dial
		Crafting.inventory_add("blast", 1, 1)
		Crafting.inventory_add("blast", 5, 1)

		Dial.load_complication("blast", 1)
		Dial.load_complication("blast", 5)
		var loaded: Array = GameState.state["player"]["dial"]["loadedComplications"]
		assert_eq(loaded[0]["capacityCost"], loaded[1]["capacityCost"], "capacityCost must be identical regardless of the crafted quality tier loaded")
	)

	run_case("load_complication_refuses_once_it_would_exceed_capacityMax", func():
		GameState.reset()
		var dial := _dial_no_movement()
		dial["capacityMax"] = GameData.RECIPES["blast"]["capacityCost"]  # room for exactly one Blast
		GameState.state["player"]["dial"] = dial
		Crafting.inventory_add("blast", 1, 2)

		var first := Dial.load_complication("blast", 1)
		assert_true(first["ok"], "the first load within budget should succeed")
		var second := Dial.load_complication("blast", 1)
		assert_true(not second["ok"], "a load that would push capacityUsed past capacityMax should be refused")
		assert_eq(Crafting.inventory_qty("blast"), 1, "a refused load must not touch inventory")
		assert_eq(GameState.state["player"]["dial"]["loadedComplications"].size(), 1, "a refused load must not append anything")
	)

	run_case("load_unload_complication_works_identically_with_no_movement_seated", func():
		GameState.reset()
		var dial := _dial_no_movement()
		dial["capacityMax"] = 10
		assert_eq(dial["movement"], null, "fixture starts with no Movement seated")
		GameState.state["player"]["dial"] = dial
		Crafting.inventory_add("timePearl", 2, 1)

		var load_result := Dial.load_complication("timePearl", 2)
		assert_true(load_result["ok"], "loading should succeed with no Movement seated")
		var unload_result := Dial.unload_complication(0)
		assert_true(unload_result["ok"], "unloading should succeed with no Movement seated")
	)

	# ── ticket 03: unloading Complications ───────────────────────────────

	run_case("unload_complication_refuses_with_no_dial", func():
		GameState.reset()
		var result := Dial.unload_complication(0)
		assert_true(not result["ok"], "unloading with no Dial should be refused")
	)

	run_case("unload_complication_refuses_an_out_of_range_index", func():
		GameState.reset()
		GameState.state["player"]["dial"] = _dial_no_movement()
		var result := Dial.unload_complication(0)
		assert_true(not result["ok"], "unloading from an empty loadedComplications should be refused")
	)

	run_case("unload_complication_reverses_load_exactly_returning_the_unit_to_its_original_tier_bucket", func():
		GameState.reset()
		var dial := _dial_no_movement()
		dial["capacityMax"] = 10
		GameState.state["player"]["dial"] = dial
		Crafting.inventory_add("blast", 4, 1)
		Dial.load_complication("blast", 4)

		var result := Dial.unload_complication(0)
		assert_true(result["ok"], "unloading a valid loadedComplications index should succeed")
		assert_eq(GameState.state["player"]["dial"]["loadedComplications"], [], "the unloaded Complication leaves loadedComplications")
		var buckets: Dictionary = GameState.state["player"]["inventory"]["blast"]
		assert_eq(buckets, { "4": 1 }, "the unit returns to the exact tier bucket it was loaded from, not duplicated or destroyed")
	)

	run_case("unload_complication_frees_capacity_for_a_subsequent_load", func():
		GameState.reset()
		var dial := _dial_no_movement()
		dial["capacityMax"] = GameData.RECIPES["blast"]["capacityCost"]
		GameState.state["player"]["dial"] = dial
		Crafting.inventory_add("blast", 1, 2)

		Dial.load_complication("blast", 1)
		var blocked := Dial.load_complication("blast", 1)
		assert_true(not blocked["ok"], "no room for a second Blast yet")

		Dial.unload_complication(0)
		var retried := Dial.load_complication("blast", 1)
		assert_true(retried["ok"], "unloading should free enough capacity for the next load")
	)

	# ── ticket 04: charge pool activation/deactivation ───────────────────

	run_case("seat_movement_activates_the_charge_pool_sized_by_archetype_and_tier", func():
		GameState.reset()
		GameState.state["player"]["dial"] = _dial_no_movement()
		GameState.state["player"]["movementInventory"] = [{ "archetype": "recharge", "oreType": "time", "tier": 3 }]

		Dial.seat_movement(0)
		var dial: Dictionary = GameState.state["player"]["dial"]
		var m: Dictionary = GameData.DIAL_MOVEMENTS["recharge"]
		var expected_max: int = int(GameData.DIAL_BASE_MAX_CHARGE - m["downside"][3])
		var expected_rate: float = GameData.DIAL_BASE_RECHARGE_RATE + m["bonus"][3]
		assert_eq(dial["maxCharge"], expected_max, "Recharge's downside should lower maxCharge from the base")
		assert_almost_eq(dial["rechargeRate"], expected_rate, 0.0001, "Recharge's bonus should raise rechargeRate from the base")
		assert_eq(dial["currentCharge"], 0, "a freshly-activated charge pool starts empty")
	)

	run_case("seat_movement_biases_capacitor_toward_maxCharge_over_rechargeRate", func():
		GameState.reset()
		GameState.state["player"]["dial"] = _dial_no_movement()
		GameState.state["player"]["movementInventory"] = [{ "archetype": "capacitor", "oreType": "physics", "tier": 3 }]

		Dial.seat_movement(0)
		var dial: Dictionary = GameState.state["player"]["dial"]
		var m: Dictionary = GameData.DIAL_MOVEMENTS["capacitor"]
		var expected_max: int = int(GameData.DIAL_BASE_MAX_CHARGE + m["bonus"][3])
		var expected_rate: float = GameData.DIAL_BASE_RECHARGE_RATE - m["downside"][3]
		assert_eq(dial["maxCharge"], expected_max, "Capacitor's bonus should raise maxCharge from the base")
		assert_almost_eq(dial["rechargeRate"], expected_rate, 0.0001, "Capacitor's downside should lower rechargeRate from the base, below tier 5")
	)

	run_case("tier_5_capacitor_movement_sets_natural_rechargeRate_to_zero", func():
		GameState.reset()
		GameState.state["player"]["dial"] = _dial_no_movement()
		GameState.state["player"]["movementInventory"] = [{ "archetype": "capacitor", "oreType": "physics", "tier": 5 }]

		Dial.seat_movement(0)
		assert_eq(GameState.state["player"]["dial"]["rechargeRate"], 0.0, "tier-5 Capacitor's defining trait: zero natural rechargeRate")
		assert_true(GameState.state["player"]["dial"]["maxCharge"] > GameData.DIAL_BASE_MAX_CHARGE, "tier-5 Capacitor should still carry a much bigger reserve")
	)

	run_case("unseat_movement_deactivates_the_charge_pool", func():
		GameState.reset()
		var dial := _dial_no_movement()
		dial["movement"] = { "archetype": "capacitor", "oreType": "physics", "tier": 5 }
		dial["maxCharge"] = 52
		dial["rechargeRate"] = 0
		dial["currentCharge"] = 30
		GameState.state["player"]["dial"] = dial

		Dial.unseat_movement()
		var d: Dictionary = GameState.state["player"]["dial"]
		assert_eq(d["maxCharge"], 0, "unseating should zero maxCharge, matching ticket 01's inert-Dial story")
		assert_eq(d["rechargeRate"], 0, "unseating should zero rechargeRate")
		assert_eq(d["currentCharge"], 0, "unseating should zero currentCharge")
	)

	run_case("reseating_a_different_movement_starts_the_charge_pool_fresh_not_inheriting_the_previous_reserve", func():
		GameState.reset()
		var dial := _dial_no_movement()
		dial["movement"] = { "archetype": "recharge", "oreType": "time", "tier": 3 }
		dial["maxCharge"] = 16
		dial["rechargeRate"] = 2.7
		dial["currentCharge"] = 12
		GameState.state["player"]["dial"] = dial
		GameState.state["player"]["movementInventory"] = [{ "archetype": "capacitor", "oreType": "physics", "tier": 3 }]

		Dial.seat_movement(0)
		assert_eq(GameState.state["player"]["dial"]["currentCharge"], 0, "reseating a different Movement should not carry over the previous reserve")
	)

	# ── ticket 04: winding ────────────────────────────────────────────────

	run_case("wind_refuses_with_no_dial", func():
		GameState.reset()
		var result := Dial.wind(1)
		assert_true(not result["ok"], "winding with no Dial should be refused")
	)

	run_case("wind_refuses_with_no_movement_seated", func():
		GameState.reset()
		GameState.state["player"]["dial"] = _dial_no_movement()
		var result := Dial.wind(1)
		assert_true(not result["ok"], "winding with no Movement seated should be refused")
	)

	run_case("wind_adds_charge_and_spends_the_seated_movements_attuned_ore_type", func():
		GameState.reset()
		var dial := _dial_no_movement()
		dial["movement"] = { "archetype": "recharge", "oreType": "life", "tier": 2 }
		dial["maxCharge"] = 10
		dial["currentCharge"] = 0
		dial["rechargeRate"] = 1
		GameState.state["player"]["dial"] = dial
		GameState.state["player"]["orichalchum"]["life"] = 100

		var cost: int = Dial.winding_cost_per_charge("recharge", 2)
		var result := Dial.wind(1)
		assert_true(result["ok"], "winding with enough calc and headroom should succeed")
		assert_eq(GameState.state["player"]["dial"]["currentCharge"], 1, "winding should add exactly the requested charge")
		assert_eq(GameState.state["player"]["orichalchum"]["life"], 100 - cost, "winding should spend the seated Movement's attuned ore type at its cost-per-charge")
	)

	run_case("wind_refuses_without_enough_calc", func():
		GameState.reset()
		var dial := _dial_no_movement()
		dial["movement"] = { "archetype": "capacitor", "oreType": "emotion", "tier": 1 }
		dial["maxCharge"] = 10
		dial["currentCharge"] = 0
		GameState.state["player"]["dial"] = dial
		GameState.state["player"]["orichalchum"]["emotion"] = 0

		var result := Dial.wind(1)
		assert_true(not result["ok"], "winding without enough calc should be refused")
		assert_eq(GameState.state["player"]["dial"]["currentCharge"], 0, "a refused wind must not add charge")
	)

	run_case("wind_refuses_when_charge_is_already_full", func():
		GameState.reset()
		var dial := _dial_no_movement()
		dial["movement"] = { "archetype": "recharge", "oreType": "time", "tier": 1 }
		dial["maxCharge"] = 5
		dial["currentCharge"] = 5
		GameState.state["player"]["dial"] = dial
		GameState.state["player"]["orichalchum"]["time"] = 1000

		var result := Dial.wind(1)
		assert_true(not result["ok"], "winding a full charge pool should be refused")
	)

	run_case("wind_has_no_time_block_cost", func():
		GameState.reset()
		var dial := _dial_no_movement()
		dial["movement"] = { "archetype": "recharge", "oreType": "time", "tier": 1 }
		dial["maxCharge"] = 5
		dial["currentCharge"] = 0
		GameState.state["player"]["dial"] = dial
		GameState.state["player"]["orichalchum"]["time"] = 1000
		var blocks_before: Array = GameState.state["world"]["timeBlocksDone"].duplicate()

		Dial.wind(1)
		assert_eq(GameState.state["world"]["timeBlocksDone"], blocks_before, "winding must not consume a time block")
	)

	run_case("winding_cost_per_charge_is_independent_of_dial_level_and_maxCharge", func():
		GameState.reset()
		var dial := _dial_no_movement()
		dial["movement"] = { "archetype": "impact", "oreType": "fate", "tier": 3 }
		dial["level"] = 1
		dial["capacityMax"] = 4
		dial["maxCharge"] = 5
		dial["currentCharge"] = 0
		GameState.state["player"]["dial"] = dial
		GameState.state["player"]["orichalchum"]["fate"] = 1000
		Dial.wind(1)
		var spent_low_level: int = 1000 - GameState.state["player"]["orichalchum"]["fate"]

		GameState.reset()
		dial = _dial_no_movement()
		dial["movement"] = { "archetype": "impact", "oreType": "fate", "tier": 3 }
		dial["level"] = 5
		dial["capacityMax"] = 16
		dial["maxCharge"] = 500  # a much bigger pool, simulating heavy dial-level growth
		dial["currentCharge"] = 0
		GameState.state["player"]["dial"] = dial
		GameState.state["player"]["orichalchum"]["fate"] = 1000
		Dial.wind(1)
		var spent_high_level: int = 1000 - GameState.state["player"]["orichalchum"]["fate"]

		assert_eq(spent_low_level, spent_high_level, "winding cost-per-charge must be unaffected by dial level/maxCharge at a fixed archetype/tier")
	)

	# ── ticket 04: daily regen ───────────────────────────────────────────

	run_case("daily_regen_adds_rechargeRate_once_per_day_capped_at_maxCharge", func():
		GameState.reset()
		var dial := _dial_no_movement()
		dial["maxCharge"] = 10
		dial["currentCharge"] = 3
		dial["rechargeRate"] = 4
		dial["lastRegenDay"] = 1
		GameState.state["player"]["dial"] = dial
		GameState.state["world"]["day"] = 1

		Dial.daily_regen()
		assert_eq(GameState.state["player"]["dial"]["currentCharge"], 3, "regen must not apply again on the same day")

		GameState.state["world"]["day"] = 2
		Dial.daily_regen()
		assert_eq(GameState.state["player"]["dial"]["currentCharge"], 7, "regen should add rechargeRate exactly once for the new day")

		GameState.state["world"]["day"] = 3
		GameState.state["player"]["dial"]["currentCharge"] = 9
		Dial.daily_regen()
		assert_eq(GameState.state["player"]["dial"]["currentCharge"], 10, "regen should cap at maxCharge, not overshoot")
	)

	run_case("daily_regen_is_a_no_op_with_no_dial", func():
		GameState.reset()
		Dial.daily_regen()
		assert_eq(GameState.state["player"]["dial"], null, "no dial means nothing to regen")
	)

	# ── ticket 05: casting a loaded Complication ─────────────────────────

	run_case("cast_complication_refuses_with_no_dial", func():
		GameState.reset()
		var result := Dial.cast_complication(0)
		assert_true(not result["ok"], "casting with no Dial should be refused")
	)

	run_case("cast_complication_refuses_an_out_of_range_index", func():
		GameState.reset()
		GameState.state["player"]["dial"] = _dial_no_movement()
		var result := Dial.cast_complication(0)
		assert_true(not result["ok"], "casting from an empty loadedComplications should be refused")
	)

	run_case("cast_complication_refuses_with_currentCharge_at_zero", func():
		GameState.reset()
		var dial := _dial_no_movement()
		dial["maxCharge"] = 10
		dial["currentCharge"] = 0
		dial["loadedComplications"] = [{ "recipeKey": "blast", "tier": 4, "capacityCost": 3, "detent": 0 }]
		GameState.state["player"]["dial"] = dial

		var result := Dial.cast_complication(0)
		assert_true(not result["ok"], "casting at 0 currentCharge should be refused")
	)

	run_case("cast_complication_spends_exactly_one_charge_and_does_not_touch_inventory", func():
		GameState.reset()
		var dial := _dial_no_movement()
		dial["maxCharge"] = 10
		dial["currentCharge"] = 5
		dial["loadedComplications"] = [{ "recipeKey": "blast", "tier": 4, "capacityCost": 3, "detent": 0 }]
		GameState.state["player"]["dial"] = dial

		var result := Dial.cast_complication(0)
		assert_true(result["ok"], "casting with charge available and a valid index should succeed")
		assert_eq(GameState.state["player"]["dial"]["currentCharge"], 4, "casting should spend exactly one charge")
		assert_eq(GameState.state["player"]["dial"]["loadedComplications"].size(), 1, "casting must not unload the Complication")
		assert_eq(Crafting.inventory_qty("blast"), 0, "casting must never touch the regular tiered inventory")
	)

	run_case("cast_complication_effect_is_effect_power_at_the_loaded_tier_with_no_movement_seated", func():
		GameState.reset()
		var dial := _dial_no_movement()
		dial["maxCharge"] = 10
		dial["currentCharge"] = 5
		dial["loadedComplications"] = [{ "recipeKey": "blast", "tier": 4, "capacityCost": 3, "detent": 0 }]
		GameState.state["player"]["dial"] = dial

		var result := Dial.cast_complication(0)
		assert_eq(result["power"], Crafting.effect_power("blast", 4), "cast power should equal effect_power() at the loaded unit's own tier, unamplified with no Movement seated")
		assert_eq(result["targets"], 1, "no Movement seated means a single, unextended target")
	)

	run_case("cast_complication_ignores_the_players_current_crafting_skill_and_uses_the_loaded_tier_instead", func():
		GameState.reset()
		GameState.state["player"]["craftingSkill"] = 1  # would give a much lower effect_power if read instead of the loaded tier
		var dial := _dial_no_movement()
		dial["maxCharge"] = 10
		dial["currentCharge"] = 5
		dial["loadedComplications"] = [{ "recipeKey": "blast", "tier": 5, "capacityCost": 3, "detent": 0 }]
		GameState.state["player"]["dial"] = dial

		var result := Dial.cast_complication(0)
		assert_eq(result["power"], Crafting.effect_power("blast", 5), "cast power must come from the loaded tier, not the player's current crafting skill")
	)

	run_case("cast_complication_impact_movement_amplifies_power_by_its_tier_bonus", func():
		GameState.reset()
		var dial := _dial_no_movement()
		dial["maxCharge"] = 10
		dial["currentCharge"] = 5
		dial["movement"] = { "archetype": "impact", "oreType": "physics", "tier": 5 }
		dial["loadedComplications"] = [{ "recipeKey": "blast", "tier": 4, "capacityCost": 3, "detent": 0 }]
		GameState.state["player"]["dial"] = dial

		var result := Dial.cast_complication(0)
		var base_power: int = Crafting.effect_power("blast", 4)
		var expected: int = GameState.round_epsilon(float(base_power) * (1.0 + GameData.DIAL_MOVEMENTS["impact"]["bonus"][5]))
		assert_eq(result["power"], expected, "an Impact Movement should multiply the base power by its tier-indexed bonus")
		assert_eq(result["targets"], 1, "Impact never extends the target count")
	)

	run_case("cast_complication_spread_movement_hits_every_target_at_full_power_no_dilution", func():
		GameState.reset()
		var dial := _dial_no_movement()
		dial["maxCharge"] = 10
		dial["currentCharge"] = 5
		dial["movement"] = { "archetype": "spread", "oreType": "physics", "tier": 3 }
		dial["loadedComplications"] = [{ "recipeKey": "blast", "tier": 4, "capacityCost": 3, "detent": 0 }]
		GameState.state["player"]["dial"] = dial

		var result := Dial.cast_complication(0)
		var base_power: int = Crafting.effect_power("blast", 4)
		var expected_targets: int = 1 + int(GameData.DIAL_MOVEMENTS["spread"]["bonus"][3])
		assert_eq(result["power"], base_power, "Spread must never dilute per-target power")
		assert_eq(result["targets"], expected_targets, "Spread's tier-indexed bonus is an extra-target count on top of the normal single target")
		assert_true(result["targets"] > 1, "a Spread cast at tier 3 should extend to more than one target")
	)

	run_case("cast_complication_recharge_or_capacitor_seated_leaves_the_cast_unamplified", func():
		GameState.reset()
		var dial := _dial_no_movement()
		dial["maxCharge"] = 10
		dial["currentCharge"] = 5
		dial["movement"] = { "archetype": "capacitor", "oreType": "physics", "tier": 5 }
		dial["loadedComplications"] = [{ "recipeKey": "blast", "tier": 4, "capacityCost": 3, "detent": 0 }]
		GameState.state["player"]["dial"] = dial

		var result := Dial.cast_complication(0)
		assert_eq(result["power"], Crafting.effect_power("blast", 4), "Capacitor's bonus is charge economy, not effect magnitude -- casting under it is unamplified")
		assert_eq(result["targets"], 1, "Capacitor never extends the target count")
	)

	# ── ticket 05: direct-throw regression (untouched by this whole PRD) ──

	run_case("direct_throw_of_an_unloaded_consumable_still_destroys_the_unit_and_applies_no_amplification", func():
		GameState.reset()
		GameState.state["player"]["craftingSkill"] = 3
		Crafting.inventory_add("blast", 3, 1)
		GameState.state["combat"] = {
			"active": true, "context": Combat.CONTEXT_MUGGING, "veinId": null,
			"enemy": { "name": "Test Enemy", "hp": 100, "hpMax": 100, "attackMin": 5, "attackMax": 5, "veinId": null, "isMugging": true, "weapon": null, "ability": null, "evadeChance": 0.0 },
			"log": [], "outcome": null, "frozenTurns": 0, "motionTurns": 0, "motionPower": 0,
			"evadeTurns": 0, "evadeChance": 0.0, "onWin": "muggingWon", "snapshots": [],
			"allies": [],
		}
		# A high-tier Impact Movement seated on the player's Dial must have
		# zero effect on this path -- amplification is exclusive to
		# Dial.cast_complication() (User story 23).
		var dial := _dial_no_movement()
		dial["capacityMax"] = 10
		GameState.state["player"]["dial"] = dial
		GameState.state["player"]["movementInventory"] = [{ "archetype": "impact", "oreType": "physics", "tier": 5 }]
		Dial.seat_movement(0)

		Combat.use_blast()

		var expected_power: int = Crafting.effect_power("blast", 3)
		var enemy: Dictionary = GameState.state["combat"]["enemy"]
		assert_eq(enemy["hp"], 100 - expected_power, "direct-thrown Blast must deal exactly its unamplified effect_power, ignoring the seated Impact Movement entirely")
		assert_eq(Crafting.inventory_qty("blast"), 0, "throwing directly still destroys the unit, exactly as before this PRD")
	)

	# ── ticket 05: tier-5 Recharge Movement's in-combat regen ────────────

	run_case("combat_turn_tick_is_a_no_op_with_no_dial", func():
		GameState.reset()
		Dial.combat_turn_tick()
		assert_eq(GameState.state["player"]["dial"], null, "no dial means nothing to tick")
	)

	run_case("combat_turn_tick_is_a_no_op_with_no_movement_seated", func():
		GameState.reset()
		GameState.state["player"]["dial"] = _dial_no_movement()
		Dial.combat_turn_tick()
		assert_eq(GameState.state["player"]["dial"]["currentCharge"], 0, "no Movement seated means nothing to tick")
	)

	run_case("combat_turn_tick_is_a_no_op_for_a_below_tier_5_recharge_movement", func():
		GameState.reset()
		var dial := _dial_no_movement()
		dial["movement"] = { "archetype": "recharge", "oreType": "time", "tier": 4 }
		dial["maxCharge"] = 20
		dial["currentCharge"] = 0
		GameState.state["player"]["dial"] = dial

		for i in range(GameData.DIAL_RECHARGE_COMBAT_REGEN_TURNS * 2):
			Dial.combat_turn_tick()
		assert_eq(GameState.state["player"]["dial"]["currentCharge"], 0, "only a tier-5 Recharge Movement gets in-combat regen")
	)

	run_case("combat_turn_tick_is_a_no_op_for_a_tier_5_non_recharge_movement", func():
		GameState.reset()
		var dial := _dial_no_movement()
		dial["movement"] = { "archetype": "capacitor", "oreType": "physics", "tier": 5 }
		dial["maxCharge"] = 20
		dial["currentCharge"] = 0
		GameState.state["player"]["dial"] = dial

		for i in range(GameData.DIAL_RECHARGE_COMBAT_REGEN_TURNS * 2):
			Dial.combat_turn_tick()
		assert_eq(GameState.state["player"]["dial"]["currentCharge"], 0, "in-combat regen is exclusive to the Recharge archetype")
	)

	run_case("combat_turn_tick_regenerates_charge_every_n_turns_for_a_tier_5_recharge_movement", func():
		GameState.reset()
		var dial := _dial_no_movement()
		dial["movement"] = { "archetype": "recharge", "oreType": "time", "tier": 5 }
		dial["maxCharge"] = 20
		dial["currentCharge"] = 0
		GameState.state["player"]["dial"] = dial

		var turns: int = GameData.DIAL_RECHARGE_COMBAT_REGEN_TURNS
		for i in range(turns - 1):
			Dial.combat_turn_tick()
		assert_eq(GameState.state["player"]["dial"]["currentCharge"], 0, "no regen tick until the full turn cadence has elapsed")

		Dial.combat_turn_tick()
		assert_eq(GameState.state["player"]["dial"]["currentCharge"], GameData.DIAL_RECHARGE_COMBAT_REGEN_AMOUNT, "a full cadence of turns should add exactly one regen tick's worth of charge")

		for i in range(turns - 1):
			Dial.combat_turn_tick()
		assert_eq(GameState.state["player"]["dial"]["currentCharge"], GameData.DIAL_RECHARGE_COMBAT_REGEN_AMOUNT, "the counter should have reset after firing, not fire again early")
	)

	run_case("combat_turn_tick_caps_at_maxCharge", func():
		GameState.reset()
		var dial := _dial_no_movement()
		dial["movement"] = { "archetype": "recharge", "oreType": "time", "tier": 5 }
		dial["maxCharge"] = GameData.DIAL_RECHARGE_COMBAT_REGEN_AMOUNT
		dial["currentCharge"] = GameData.DIAL_RECHARGE_COMBAT_REGEN_AMOUNT
		GameState.state["player"]["dial"] = dial

		for i in range(GameData.DIAL_RECHARGE_COMBAT_REGEN_TURNS):
			Dial.combat_turn_tick()
		assert_eq(GameState.state["player"]["dial"]["currentCharge"], GameData.DIAL_RECHARGE_COMBAT_REGEN_AMOUNT, "in-combat regen should cap at maxCharge, not overshoot")
	)

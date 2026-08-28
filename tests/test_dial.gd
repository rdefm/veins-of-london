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

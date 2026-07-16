extends "res://tests/test_base.gd"


# Finds a seed (within max_tries) for which fn() returns true, restoring
# GameState.state between misses so each attempt starts from the same
# baseline. Returns the winning seed, or -1 if none found.
static func _find_seed_for(max_tries: int, fn: Callable) -> int:
	for seed in range(max_tries):
		var snapshot: Dictionary = GameState.deep_copy(GameState.state)
		Rng.set_seed(seed)
		if fn.call():
			return seed
		GameState.state = snapshot
	return -1


func run() -> void:
	run_case("seed_deducts_40_ore_always_regardless_of_outcome", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["time"] = 100
		Cultivating.seed("time")
		assert_true(GameState.state["player"]["orichalchum"]["time"] == 60, "40 ore deducted after one seed attempt")
	)

	run_case("seed_blocked_below_40_ore_no_side_effects", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["time"] = 39
		var day_before: int = GameState.state["world"]["day"]
		var result := Cultivating.seed("time")
		assert_true(not result["ok"], "should refuse with < 40 ore")
		assert_eq(GameState.state["player"]["orichalchum"]["time"], 39, "no ore deducted when blocked")
		assert_eq(GameState.state["world"]["day"], day_before, "no block spent when blocked")
	)

	run_case("seed_blocked_when_time_exhausted_no_side_effects", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["time"] = 100
		GameState.state["world"]["timeBlocksDone"] = [0, 1, 2]
		var result := Cultivating.seed("time")
		assert_true(not result["ok"], "should refuse when time is exhausted")
		assert_eq(GameState.state["player"]["orichalchum"]["time"], 100, "no ore deducted when blocked")
	)

	run_case("successful_seed_creates_lv1_vein_with_devBar_1_plus_skill", func():
		var seed := _find_seed_for(200, func():
			GameState.reset()
			GameState.state["player"]["orichalchum"]["time"] = 100
			GameState.state["player"]["cultivatingSkill"] = 3
			var result := Cultivating.seed("time")
			return result.get("success", false)
		)
		assert_true(seed != -1, "should find a successful seed roll within 200 tries")
		var veins: Array = GameState.state["player"]["veins"]
		assert_eq(veins.size(), 1, "exactly one vein created")
		var vein: Dictionary = veins[0]
		assert_eq(vein["level"], 1, "new vein starts at level 1")
		assert_eq(vein["devBar"], 1 + 3, "devBar = 1 + skill (skill 3)")
		assert_eq(vein["charged"], false, "new vein starts uncharged")
		assert_eq(vein["security"], "none", "new vein starts unsecured")
		assert_eq(vein["oreType"], "time", "vein ore type matches seeded type")
		assert_true(vein["location"].contains(","), "location should be 'street, suffix'")
	)

	run_case("xp_thresholds_level_the_skill_at_exactly_80", func():
		GameState.reset()
		GameState.state["player"]["cultivatingSkill"] = 1
		GameState.state["player"]["cultivatingXP"] = 0

		Cultivating.award_xp(79)
		assert_eq(GameState.state["player"]["cultivatingSkill"], 1, "79 XP should not yet level up (threshold is 80)")

		Cultivating.award_xp(1)
		assert_eq(GameState.state["player"]["cultivatingXP"], 80, "XP now at exactly 80")
		assert_eq(GameState.state["player"]["cultivatingSkill"], 2, "should level up at exactly 80 XP")
	)

	run_case("cultivate_fills_bar_and_levels_up_at_devBarMax", func():
		var seed := _find_seed_for(200, func():
			GameState.reset()
			GameState.state["player"]["cultivatingSkill"] = 5
			var vein := {
				"id": "test_vein", "oreType": "time", "level": 1, "levelLabel": "Trace",
				"devBar": 3, "charged": false, "chargeBlocks": 0, "security": "none",
				"location": "Test St, nowhere", "claimedOnDay": 1, "district": "shoreditch",
				"hospitability": { "tier": "fair", "bonuses": [] },
			}
			GameState.state["player"]["veins"] = [vein]
			var result := Cultivating.cultivate("test_vein")
			return result.get("success", false)
		)
		assert_true(seed != -1, "should find a successful cultivate roll within 200 tries")
		var vein: Dictionary = GameState.state["player"]["veins"][0]
		# skill 5 -> gain 6; devBar 3+6=9 >= Lv1 devBarMax (8) -> levels up, devBar resets to 0
		assert_eq(vein["level"], 2, "vein should have levelled up to 2")
		assert_eq(vein["devBar"], 0, "devBar resets to 0 on level up")
		assert_eq(vein["levelLabel"], "Minor", "levelLabel updates with the new level")
	)

	run_case("cultivate_lv5_is_the_cap_even_with_devBar_far_past_threshold", func():
		var seed := _find_seed_for(200, func():
			GameState.reset()
			GameState.state["player"]["cultivatingSkill"] = 5
			var vein := {
				"id": "capped_vein", "oreType": "time", "level": 5, "levelLabel": "Lode",
				"devBar": 20000, "charged": false, "chargeBlocks": 0, "security": "none",
				"location": "Test St, nowhere", "claimedOnDay": 1, "district": "shoreditch",
				"hospitability": { "tier": "fair", "bonuses": [] },
			}
			GameState.state["player"]["veins"] = [vein]
			var result := Cultivating.cultivate("capped_vein")
			return result.get("success", false)
		)
		assert_true(seed != -1, "should find a successful cultivate roll within 200 tries")
		var vein: Dictionary = GameState.state["player"]["veins"][0]
		assert_eq(vein["level"], 5, "level 5 is the hard cap in M0 (no hospitability maxLevel bonus)")
	)

	run_case("harvest_full_drains_devBar_and_triggers_level_down_at_or_below_0", func():
		GameState.reset()
		var vein := {
			"id": "drain_vein", "oreType": "physics", "level": 2, "levelLabel": "Minor",
			"devBar": 2, "charged": true, "chargeBlocks": 0, "security": "none",
			"location": "Roman Rd, in the car park", "claimedOnDay": 1, "district": "shoreditch",
			"hospitability": { "tier": "fair", "bonuses": [] },
		}
		GameState.state["player"]["veins"] = [vein]
		Rng.set_seed(1)
		var result := Cultivating.harvest_full("drain_vein")

		assert_true(result["ok"], "harvest_full should succeed on a charged vein")
		assert_true(result["levelledDown"], "devBar 2 - devBarHarvestCost 3 = -1 <= 0 should trigger a level-down")
		var remaining: Array = GameState.state["player"]["veins"]
		assert_eq(remaining.size(), 1, "level 2 -> 1 demotes, does not delete")
		var demoted: Dictionary = remaining[0]
		assert_eq(demoted["level"], 1, "demoted to level 1")
		assert_eq(demoted["devBar"], int(floor(8 * 0.8)), "devBar = floor(Lv1 devBarMax * 0.8) = 6")
	)

	run_case("lv1_level_down_deletes_the_vein", func():
		GameState.reset()
		var vein := {
			"id": "doomed_vein", "oreType": "life", "level": 1, "levelLabel": "Trace",
			"devBar": 1, "charged": true, "chargeBlocks": 0, "security": "none",
			"location": "Brick Lane, near the off-licence", "claimedOnDay": 1, "district": "shoreditch",
			"hospitability": { "tier": "fair", "bonuses": [] },
		}
		GameState.state["player"]["veins"] = [vein]
		Rng.set_seed(1)
		var result := Cultivating.harvest_full("doomed_vein")

		assert_true(result["levelledDown"], "devBar 1 - devBarHarvestCost 2 <= 0 should trigger a level-down")
		assert_eq(GameState.state["player"]["veins"], [], "a level-1 vein that levels down should be deleted, not demoted")
	)

	run_case("harvest_cautious_requires_charged_and_yields_within_range", func():
		GameState.reset()
		var vein := {
			"id": "cautious_vein", "oreType": "fate", "level": 1, "levelLabel": "Trace",
			"devBar": 5, "charged": true, "chargeBlocks": 0, "security": "none",
			"location": "Vallance Rd, by the bus stop", "claimedOnDay": 1, "district": "shoreditch",
			"hospitability": { "tier": "fair", "bonuses": [] },
		}
		GameState.state["player"]["veins"] = [vein]
		Rng.set_seed(1)
		var result := Cultivating.harvest_cautious("cautious_vein")

		assert_true(result["ok"], "should succeed on a charged vein")
		assert_true(result["amount"] >= 1 and result["amount"] <= 2, "Lv1 yieldCautious is [1,2]")
		assert_eq(GameState.state["player"]["orichalchum"]["fate"], result["amount"], "ore credited to player")
		assert_eq(vein["charged"], false, "vein discharges after harvest")
	)

	run_case("harvest_blocked_when_not_charged", func():
		GameState.reset()
		var vein := {
			"id": "uncharged_vein", "oreType": "fate", "level": 1, "levelLabel": "Trace",
			"devBar": 5, "charged": false, "chargeBlocks": 0, "security": "none",
			"location": "Vallance Rd, by the bus stop", "claimedOnDay": 1, "district": "shoreditch",
			"hospitability": { "tier": "fair", "bonuses": [] },
		}
		GameState.state["player"]["veins"] = [vein]
		var result := Cultivating.harvest_cautious("uncharged_vein")
		assert_true(not result["ok"], "should refuse an uncharged vein")
	)

	run_case("recharge_veins_increments_and_flips_charged_at_threshold", func():
		GameState.reset()
		var vein := {
			"id": "recharge_vein", "oreType": "time", "level": 1, "levelLabel": "Trace",
			"devBar": 1, "charged": false, "chargeBlocks": 3, "security": "none",
			"location": "Hackney Rd, under the railway arch", "claimedOnDay": 1, "district": "shoreditch",
			"hospitability": { "tier": "fair", "bonuses": [] },
		}
		GameState.state["player"]["veins"] = [vein]
		# Lv1 rechargeBlocks is 4; chargeBlocks 3 -> 4 should flip charged true
		Cultivating.recharge_veins()
		var v: Dictionary = GameState.state["player"]["veins"][0]
		assert_eq(v["chargeBlocks"], 4, "chargeBlocks increments by 1")
		assert_eq(v["charged"], true, "charged flips true once chargeBlocks reaches rechargeBlocks")
	)

	run_case("location_name_uses_the_verbatim_street_and_suffix_arrays", func():
		Rng.set_seed(42)
		var location := Cultivating.generate_location_name()
		var parts := location.split(", ")
		assert_eq(parts.size(), 2, "location should be 'street, suffix'")
		assert_true(Cultivating.LOCATION_STREETS.has(parts[0]), "street should come from the verbatim HTML array")
		assert_true(Cultivating.LOCATION_SUFFIXES.has(parts[1]), "suffix should come from the verbatim HTML array")
	)

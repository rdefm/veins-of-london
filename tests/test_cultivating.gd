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
		assert_eq(GameState.state["modal"]["type"], "seed_result", "seed should open the seed_result modal")
		assert_eq(GameState.state["modal"]["data"]["success"], true, "modal data reflects the outcome")
	)

	run_case("failed_seed_still_opens_seed_result_modal", func():
		var seed := _find_seed_for(200, func():
			GameState.reset()
			GameState.state["player"]["orichalchum"]["time"] = 100
			GameState.state["player"]["cultivatingSkill"] = 1
			var result := Cultivating.seed("time")
			return not result.get("success", true)
		)
		assert_true(seed != -1, "should find a failed seed roll within 200 tries")
		assert_eq(GameState.state["modal"]["type"], "seed_result", "failure should still open the modal")
		assert_eq(GameState.state["modal"]["data"]["success"], false, "modal data reflects the failure")
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
		assert_eq(GameState.state["modal"]["type"], "cultivate_result", "cultivate should open the cultivate_result modal")
		assert_eq(GameState.state["modal"]["data"]["levelledUp"], true, "modal data reflects the level-up")
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

	run_case("cultivate_in_a_different_district_costs_the_same_1_block_no_travel_surcharge", func():
		GameState.reset()
		GameState.state["player"]["cultivatingSkill"] = 5
		var vein := {
			"id": "away_vein", "oreType": "time", "level": 1, "levelLabel": "Trace",
			"devBar": 0, "charged": false, "chargeBlocks": 0, "security": "none",
			"location": "Test St, nowhere", "claimedOnDay": 1, "district": "camden",
			"hospitability": { "tier": "fair", "bonuses": [] },
		}
		GameState.state["player"]["veins"] = [vein]
		Rng.set_seed(1)
		var result := Cultivating.cultivate("away_vein")
		assert_true(result["ok"], "should succeed with a full day's blocks available")
		assert_eq(GameState.state["world"]["currentDistrict"], "camden", "acting in the vein's district updates currentDistrict")
		assert_eq(GameState.state["world"]["timeBlocksDone"].size(), 1, "D3: no travel surcharge — just the 1 cultivate block")
	)

	run_case("cultivate_in_a_different_district_succeeds_with_only_1_block_left", func():
		GameState.reset()
		GameState.state["world"]["timeBlocksDone"] = [0, 1]
		var vein := {
			"id": "away_vein2", "oreType": "time", "level": 1, "levelLabel": "Trace",
			"devBar": 0, "charged": false, "chargeBlocks": 0, "security": "none",
			"location": "Test St, nowhere", "claimedOnDay": 1, "district": "camden",
			"hospitability": { "tier": "fair", "bonuses": [] },
		}
		GameState.state["player"]["veins"] = [vein]
		var result := Cultivating.cultivate("away_vein2")
		assert_true(result["ok"], "D3: no travel surcharge — cultivate(1) alone fits in the 1 remaining block")
		assert_eq(GameState.state["world"]["currentDistrict"], "camden", "currentDistrict updates")
	)

	run_case("cultivate_in_a_different_district_blocked_when_time_exhausted", func():
		GameState.reset()
		GameState.state["world"]["timeBlocksDone"] = [0, 1, 2]
		var vein := {
			"id": "away_vein3", "oreType": "time", "level": 1, "levelLabel": "Trace",
			"devBar": 0, "charged": false, "chargeBlocks": 0, "security": "none",
			"location": "Test St, nowhere", "claimedOnDay": 1, "district": "camden",
			"hospitability": { "tier": "fair", "bonuses": [] },
		}
		GameState.state["player"]["veins"] = [vein]
		var result := Cultivating.cultivate("away_vein3")
		assert_true(not result["ok"], "no blocks left for the cultivate action itself")
		assert_eq(GameState.state["world"]["timeBlocksDone"], [0, 1, 2], "no block spent when blocked")
		assert_eq(GameState.state["world"]["currentDistrict"], "shoreditch", "currentDistrict unchanged when blocked")
	)

	run_case("cultivate_in_the_current_district_costs_only_1_block", func():
		GameState.reset()
		var vein := {
			"id": "home_vein", "oreType": "time", "level": 1, "levelLabel": "Trace",
			"devBar": 0, "charged": false, "chargeBlocks": 0, "security": "none",
			"location": "Test St, nowhere", "claimedOnDay": 1, "district": "shoreditch",
			"hospitability": { "tier": "fair", "bonuses": [] },
		}
		GameState.state["player"]["veins"] = [vein]
		Rng.set_seed(1)
		var result := Cultivating.cultivate("home_vein")
		assert_true(result["ok"], "should succeed")
		assert_eq(GameState.state["world"]["timeBlocksDone"].size(), 1, "no travel needed, 1 block total")
	)

	run_case("harvest_cautious_in_a_different_district_costs_the_same_1_block_no_travel_surcharge", func():
		GameState.reset()
		var vein := {
			"id": "away_harvest_vein", "oreType": "fate", "level": 1, "levelLabel": "Trace",
			"devBar": 5, "charged": true, "chargeBlocks": 0, "security": "none",
			"location": "Vallance Rd, by the bus stop", "claimedOnDay": 1, "district": "greenwich",
			"hospitability": { "tier": "fair", "bonuses": [] },
		}
		GameState.state["player"]["veins"] = [vein]
		Rng.set_seed(1)
		var result := Cultivating.harvest_cautious("away_harvest_vein")
		assert_true(result["ok"], "should succeed with a full day's blocks available")
		assert_eq(GameState.state["world"]["currentDistrict"], "greenwich", "acting there updates currentDistrict")
		assert_eq(GameState.state["world"]["timeBlocksDone"].size(), 1, "D3: no travel surcharge — just the 1 harvest block")
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

	# ── map-animations ticket 04: drain event queuing ───────────────────

	run_case("harvest_cautious_queues_a_drain_event_on_the_true_to_false_transition", func():
		GameState.reset()
		var vein := {
			"id": "cautious_drain_vein", "oreType": "fate", "level": 1, "levelLabel": "Trace",
			"devBar": 5, "charged": true, "chargeBlocks": 0, "security": "none",
			"location": "Vallance Rd, by the bus stop", "claimedOnDay": 1, "district": "shoreditch",
			"hospitability": { "tier": "fair", "bonuses": [] },
		}
		GameState.state["player"]["veins"] = [vein]
		Rng.set_seed(1)
		Cultivating.harvest_cautious("cautious_drain_vein")
		assert_true(MapEvents.has_pending(), "a drain event is queued on the true -> false transition")
		var event = MapEvents.current()
		assert_eq(event["type"], "drain")
		assert_eq(event["district"], "shoreditch")
		assert_eq(event["veinId"], "cautious_drain_vein")
	)

	run_case("harvest_full_queues_a_drain_event_on_the_true_to_false_transition", func():
		GameState.reset()
		var vein := {
			"id": "full_drain_vein", "oreType": "physics", "level": 3, "levelLabel": "Modest",
			"devBar": 20, "charged": true, "chargeBlocks": 0, "security": "none",
			"location": "Roman Rd, in the car park", "claimedOnDay": 1, "district": "shoreditch",
			"hospitability": { "tier": "fair", "bonuses": [] },
		}
		GameState.state["player"]["veins"] = [vein]
		Rng.set_seed(1)
		Cultivating.harvest_full("full_drain_vein")
		assert_true(MapEvents.has_pending(), "a drain event is queued on the true -> false transition")
		var event = MapEvents.current()
		assert_eq(event["type"], "drain")
		assert_eq(event["district"], "shoreditch")
		assert_eq(event["veinId"], "full_drain_vein")
	)

	run_case("harvest_full_still_queues_a_drain_event_when_the_harvest_deletes_the_vein", func():
		GameState.reset()
		var vein := {
			"id": "doomed_drain_vein", "oreType": "life", "level": 1, "levelLabel": "Trace",
			"devBar": 1, "charged": true, "chargeBlocks": 0, "security": "none",
			"location": "Brick Lane, near the off-licence", "claimedOnDay": 1, "district": "shoreditch",
			"hospitability": { "tier": "fair", "bonuses": [] },
		}
		GameState.state["player"]["veins"] = [vein]
		Rng.set_seed(1)
		var result := Cultivating.harvest_full("doomed_drain_vein")
		assert_true(result["levelledDown"], "devBar 1 - devBarHarvestCost 2 <= 0 should trigger a level-down")
		assert_eq(GameState.state["player"]["veins"], [], "a level-1 vein that levels down should be deleted")
		var event = MapEvents.current()
		assert_eq(event["type"], "drain", "drain still queues even though the vein itself was deleted this call")
		assert_eq(event["veinId"], "doomed_drain_vein")
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

	# ── M1 hospitability bonuses (M1-LONDON.md D2) ─────────────────

	run_case("get_level_cap_is_5_without_maxLevel_bonus_6_with_it", func():
		var plain := { "hospitability": { "tier": "fair", "bonuses": [] } }
		var boosted := { "hospitability": { "tier": "saturated", "bonuses": ["recharge", "maxLevel", "yield"] } }
		assert_eq(Cultivating.get_level_cap(plain), 5, "no maxLevel bonus -> cap stays 5")
		assert_eq(Cultivating.get_level_cap(boosted), 6, "maxLevel bonus -> cap raises to 6")
	)

	run_case("level_up_vein_respects_the_maxLevel_bonus_cap", func():
		var boosted := {
			"id": "v1", "level": 5, "devBar": 0, "levelLabel": "Lode",
			"hospitability": { "tier": "saturated", "bonuses": ["maxLevel"] },
		}
		Cultivating.level_up_vein(boosted)
		assert_eq(boosted["level"], 6, "maxLevel bonus allows levelling past the normal cap of 5")
		assert_eq(boosted["levelLabel"], "Deep", "levelLabel updates to the Lv6 label")

		Cultivating.level_up_vein(boosted)
		assert_eq(boosted["level"], 6, "level 6 is the hard cap even with the maxLevel bonus")
	)

	run_case("get_effective_recharge_blocks_applies_recharge_bonus_and_kingscross_stacking", func():
		var plain := { "level": 1, "district": "shoreditch", "hospitability": { "tier": "fair", "bonuses": [] } }
		var bonus_only := { "level": 1, "district": "shoreditch", "hospitability": { "tier": "rich", "bonuses": ["recharge"] } }
		var kingscross_only := { "level": 1, "district": "kingscross", "hospitability": { "tier": "fair", "bonuses": [] } }
		var both := { "level": 1, "district": "kingscross", "hospitability": { "tier": "rich", "bonuses": ["recharge"] } }

		assert_eq(Cultivating.get_effective_recharge_blocks(plain), 4, "Lv1 base rechargeBlocks unchanged")
		assert_eq(Cultivating.get_effective_recharge_blocks(bonus_only), 3, "recharge bonus: -1")
		assert_eq(Cultivating.get_effective_recharge_blocks(kingscross_only), 3, "King's Cross special: -1")
		assert_eq(Cultivating.get_effective_recharge_blocks(both), 2, "recharge bonus stacks with King's Cross: -2")
	)

	run_case("get_effective_recharge_blocks_floors_at_1_even_when_stacked", func():
		var deep_both := { "level": 6, "district": "kingscross", "hospitability": { "tier": "saturated", "bonuses": ["recharge"] } }
		# Lv6 base rechargeBlocks is already 1; -1 (bonus) -1 (King's Cross) would go to -1
		assert_eq(Cultivating.get_effective_recharge_blocks(deep_both), 1, "floors at 1, never lower, even fully stacked")
	)

	# ── map-animations ticket 03: charge event queuing ─────────────────

	run_case("recharge_veins_queues_a_charge_event_on_the_false_to_true_transition", func():
		GameState.reset()
		var vein := {
			"id": "recharge_vein", "oreType": "time", "level": 1, "levelLabel": "Trace",
			"devBar": 1, "charged": false, "chargeBlocks": 3, "security": "none",
			"location": "Hackney Rd, under the railway arch", "claimedOnDay": 1, "district": "shoreditch",
			"hospitability": { "tier": "fair", "bonuses": [] },
		}
		GameState.state["player"]["veins"] = [vein]
		# Lv1 rechargeBlocks is 4; chargeBlocks 3 -> 4 flips charged true this tick
		Cultivating.recharge_veins()
		assert_true(MapEvents.has_pending(), "a charge event is queued on the false -> true transition")
		var event = MapEvents.current()
		assert_eq(event["type"], "charge")
		assert_eq(event["district"], "shoreditch")
		assert_eq(event["veinId"], "recharge_vein")
	)

	run_case("recharge_veins_does_not_queue_when_a_vein_is_still_charging", func():
		GameState.reset()
		var vein := {
			"id": "still_charging", "oreType": "time", "level": 1, "levelLabel": "Trace",
			"devBar": 1, "charged": false, "chargeBlocks": 0, "security": "none",
			"location": "Hackney Rd, under the railway arch", "claimedOnDay": 1, "district": "shoreditch",
			"hospitability": { "tier": "fair", "bonuses": [] },
		}
		GameState.state["player"]["veins"] = [vein]
		# Lv1 rechargeBlocks is 4; chargeBlocks 0 -> 1 stays uncharged
		Cultivating.recharge_veins()
		assert_true(not MapEvents.has_pending(), "no event queued while a vein hasn't reached its recharge threshold")
	)

	run_case("recharge_veins_does_not_requeue_a_vein_that_stays_charged", func():
		GameState.reset()
		var vein := {
			"id": "already_charged", "oreType": "time", "level": 1, "levelLabel": "Trace",
			"devBar": 1, "charged": true, "chargeBlocks": 4, "security": "none",
			"location": "Hackney Rd, under the railway arch", "claimedOnDay": 1, "district": "shoreditch",
			"hospitability": { "tier": "fair", "bonuses": [] },
		}
		GameState.state["player"]["veins"] = [vein]
		# Already charged and at the threshold coming into this tick -- the
		# block below is a no-op for it, so it must not requeue every day
		# it just sits there charged.
		Cultivating.recharge_veins()
		assert_true(not MapEvents.has_pending(), "no requeue on a tick where the vein was already charged")
	)

	run_case("recharge_veins_charges_faster_with_recharge_bonus_and_kingscross_stacked", func():
		GameState.reset()
		var boosted_vein := {
			"id": "boosted", "oreType": "time", "level": 1, "levelLabel": "Trace",
			"devBar": 0, "charged": false, "chargeBlocks": 0, "security": "none",
			"location": "Test St, nowhere", "claimedOnDay": 1, "district": "kingscross",
			"hospitability": { "tier": "rich", "bonuses": ["recharge"] },
		}
		GameState.state["player"]["veins"] = [boosted_vein]

		Cultivating.recharge_veins()
		assert_eq(boosted_vein["charged"], false, "1 block isn't enough yet (needs 2, effective recharge)")
		Cultivating.recharge_veins()
		assert_eq(boosted_vein["charged"], true, "2 blocks charges it — Lv1's base 4 minus recharge bonus minus King's Cross")
	)

	run_case("apply_yield_bonus_guarantees_at_least_plus_1_over_the_base_roll", func():
		var vein_with_yield := { "hospitability": { "tier": "saturated", "bonuses": ["yield"] } }
		var vein_without := { "hospitability": { "tier": "fair", "bonuses": [] } }

		# A small roll where 1.15x rounds away to nothing without the +1 floor.
		assert_eq(Cultivating.apply_yield_bonus(vein_with_yield, 1), 2, "rolled 1 -> max(2, round(1.15))=2, the +1 floor is what bites here")
		assert_eq(Cultivating.apply_yield_bonus(vein_with_yield, 4), 5, "rolled 4 -> max(5, round(4.6))=5")
		assert_eq(Cultivating.apply_yield_bonus(vein_with_yield, 20), 23, "rolled 20 -> max(21, round(23))=23, the 1.15x multiplier wins here")
		assert_eq(Cultivating.apply_yield_bonus(vein_without, 1), 1, "no yield bonus -> roll passes through unchanged")
	)

	run_case("harvest_cautious_applies_the_yield_bonus_on_top_of_the_rolled_amount", func():
		GameState.reset()
		var vein := {
			"id": "yield_vein", "oreType": "time", "level": 1, "levelLabel": "Trace",
			"devBar": 5, "charged": true, "chargeBlocks": 0, "security": "none",
			"location": "Test St, nowhere", "claimedOnDay": 1, "district": "shoreditch",
			"hospitability": { "tier": "saturated", "bonuses": ["yield"] },
		}
		GameState.state["player"]["veins"] = [vein]
		Rng.set_seed(1)
		var result := Cultivating.harvest_cautious("yield_vein")
		assert_true(result["ok"], "should succeed on a charged vein")
		# Lv1 yieldCautious is [1,2]; apply_yield_bonus(1)=2, apply_yield_bonus(2)=3
		assert_true(result["amount"] >= 2 and result["amount"] <= 3, "yield bonus should raise the credited amount above the raw [1,2] range")
	)

	# ── vein security (M1-LONDON.md D4 site/vein sheet) ─────────────

	run_case("next_security_tier_id_walks_the_ladder_and_tops_out_at_guarded", func():
		assert_eq(Cultivating.next_security_tier_id("none"), "basic", "none -> basic")
		assert_eq(Cultivating.next_security_tier_id("basic"), "warded", "basic -> warded")
		assert_eq(Cultivating.next_security_tier_id("warded"), "guarded", "warded -> guarded")
		assert_eq(Cultivating.next_security_tier_id("guarded"), null, "guarded is the top of the ladder")
	)

	run_case("upgrade_vein_security_deducts_cash_and_advances_one_tier", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 100
		var vein := {
			"id": "sec_vein", "oreType": "time", "level": 1, "levelLabel": "Trace",
			"devBar": 0, "charged": false, "chargeBlocks": 0, "security": "none",
			"location": "Test St, nowhere", "claimedOnDay": 1, "district": "shoreditch",
			"hospitability": { "tier": "fair", "bonuses": [] },
		}
		GameState.state["player"]["veins"] = [vein]
		var result := Cultivating.upgrade_vein_security("sec_vein")
		assert_true(result["ok"], "should succeed with enough cash")
		assert_eq(vein["security"], "basic", "security advances to the next tier")
		assert_eq(GameState.state["player"]["cash"], 100 - GameData.VEIN_SECURITY["basic"]["cost"], "cash deducted by the tier's cost")
	)

	run_case("upgrade_vein_security_refuses_without_enough_cash", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 0
		var vein := {
			"id": "poor_vein", "oreType": "time", "level": 1, "levelLabel": "Trace",
			"devBar": 0, "charged": false, "chargeBlocks": 0, "security": "none",
			"location": "Test St, nowhere", "claimedOnDay": 1, "district": "shoreditch",
			"hospitability": { "tier": "fair", "bonuses": [] },
		}
		GameState.state["player"]["veins"] = [vein]
		var result := Cultivating.upgrade_vein_security("poor_vein")
		assert_true(not result["ok"], "should refuse without enough cash")
		assert_eq(vein["security"], "none", "security unchanged when refused")
	)

	run_case("upgrade_vein_security_refuses_at_maximum_tier", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 100000
		var vein := {
			"id": "maxed_vein", "oreType": "time", "level": 1, "levelLabel": "Trace",
			"devBar": 0, "charged": false, "chargeBlocks": 0, "security": "guarded",
			"location": "Test St, nowhere", "claimedOnDay": 1, "district": "shoreditch",
			"hospitability": { "tier": "fair", "bonuses": [] },
		}
		GameState.state["player"]["veins"] = [vein]
		var result := Cultivating.upgrade_vein_security("maxed_vein")
		assert_true(not result["ok"], "already at guarded, nowhere higher to go")
		assert_eq(GameState.state["player"]["cash"], 100000, "no cash spent when refused")
	)

	run_case("upgrade_vein_security_is_not_districted_no_block_or_travel_spent", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 100
		var vein := {
			"id": "away_sec_vein", "oreType": "time", "level": 1, "levelLabel": "Trace",
			"devBar": 0, "charged": false, "chargeBlocks": 0, "security": "none",
			"location": "Test St, nowhere", "claimedOnDay": 1, "district": "camden",
			"hospitability": { "tier": "fair", "bonuses": [] },
		}
		GameState.state["player"]["veins"] = [vein]
		var result := Cultivating.upgrade_vein_security("away_sec_vein")
		assert_true(result["ok"], "should succeed even though the vein is in a district the player isn't currently in")
		assert_eq(GameState.state["world"]["timeBlocksDone"], [], "security upgrades aren't in D3's districted-action list — no block spent")
		assert_eq(GameState.state["world"]["currentDistrict"], "shoreditch", "currentDistrict unchanged — no travel triggered")
	)

	# ── vein alarm (vein-raiding ticket 05) ─────────────

	run_case("fresh_vein_has_no_alarm_upgrade_by_default", func():
		var vein := Cultivating.make_vein("time", 0, "shoreditch", null, { "tier": "fair", "bonuses": [] })
		assert_eq(vein["alarmUpgrades"], [], "a freshly made vein starts with no alarm upgrades")
	)

	run_case("add_alarm_deducts_cash_and_records_the_upgrade", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 1000
		var vein := {
			"id": "alarm_vein", "oreType": "time", "level": 1, "levelLabel": "Trace",
			"devBar": 0, "charged": false, "chargeBlocks": 0, "security": "none",
			"alarmUpgrades": [], "location": "Test St, nowhere", "claimedOnDay": 1,
			"district": "shoreditch", "hospitability": { "tier": "fair", "bonuses": [] },
		}
		GameState.state["player"]["veins"] = [vein]
		var result := Cultivating.add_alarm("alarm_vein")
		assert_true(result["ok"], "should succeed with enough cash")
		assert_eq(vein["alarmUpgrades"], ["alarm"], "alarm upgrade id recorded on the vein")
		assert_eq(GameState.state["player"]["cash"], 1000 - GameData.VEIN_ALARM["alarm"]["cost"], "cash deducted by the alarm upgrade's cost")
	)

	run_case("add_alarm_refuses_without_enough_cash", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 0
		var vein := {
			"id": "poor_alarm_vein", "oreType": "time", "level": 1, "levelLabel": "Trace",
			"devBar": 0, "charged": false, "chargeBlocks": 0, "security": "none",
			"alarmUpgrades": [], "location": "Test St, nowhere", "claimedOnDay": 1,
			"district": "shoreditch", "hospitability": { "tier": "fair", "bonuses": [] },
		}
		GameState.state["player"]["veins"] = [vein]
		var result := Cultivating.add_alarm("poor_alarm_vein")
		assert_true(not result["ok"], "should refuse without enough cash")
		assert_eq(vein["alarmUpgrades"], [], "no upgrade recorded when refused")
		assert_eq(GameState.state["player"]["cash"], 0, "no cash spent when refused")
	)

	run_case("add_alarm_is_idempotent_re_purchasing_is_blocked", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 100000
		var vein := {
			"id": "alarmed_vein", "oreType": "time", "level": 1, "levelLabel": "Trace",
			"devBar": 0, "charged": false, "chargeBlocks": 0, "security": "none",
			"alarmUpgrades": ["alarm"], "location": "Test St, nowhere", "claimedOnDay": 1,
			"district": "shoreditch", "hospitability": { "tier": "fair", "bonuses": [] },
		}
		GameState.state["player"]["veins"] = [vein]
		var cash_before: int = GameState.state["player"]["cash"]
		var result := Cultivating.add_alarm("alarmed_vein")
		assert_true(not result["ok"], "already-installed alarm upgrade should refuse re-purchase")
		assert_eq(vein["alarmUpgrades"], ["alarm"], "alarmUpgrades unchanged, not duplicated")
		assert_eq(GameState.state["player"]["cash"], cash_before, "no cash spent on a blocked re-purchase")
	)

	run_case("add_alarm_is_not_districted_no_block_or_travel_spent", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 1000
		var vein := {
			"id": "away_alarm_vein", "oreType": "time", "level": 1, "levelLabel": "Trace",
			"devBar": 0, "charged": false, "chargeBlocks": 0, "security": "none",
			"alarmUpgrades": [], "location": "Test St, nowhere", "claimedOnDay": 1,
			"district": "camden", "hospitability": { "tier": "fair", "bonuses": [] },
		}
		GameState.state["player"]["veins"] = [vein]
		var result := Cultivating.add_alarm("away_alarm_vein")
		assert_true(result["ok"], "should succeed even though the vein is in a district the player isn't currently in")
		assert_eq(GameState.state["world"]["timeBlocksDone"], [], "alarm upgrades aren't in D3's districted-action list — no block spent")
		assert_eq(GameState.state["world"]["currentDistrict"], "shoreditch", "currentDistrict unchanged — no travel triggered")
	)

	run_case("add_alarm_refuses_for_unknown_vein", func():
		GameState.reset()
		var result := Cultivating.add_alarm("does_not_exist")
		assert_true(not result["ok"], "should refuse when the vein id doesn't exist")
	)

	run_case("location_name_uses_the_verbatim_street_and_suffix_arrays", func():
		Rng.set_seed(42)
		var location := Cultivating.generate_location_name()
		var parts := location.split(", ")
		assert_eq(parts.size(), 2, "location should be 'street, suffix'")
		assert_true(Cultivating.LOCATION_STREETS.has(parts[0]), "street should come from the verbatim HTML array")
		assert_true(Cultivating.LOCATION_SUFFIXES.has(parts[1]), "suffix should come from the verbatim HTML array")
	)

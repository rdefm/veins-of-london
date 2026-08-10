extends "res://tests/test_base.gd"


func run() -> void:
	run_case("three_blocks_tick_a_day", func():
		GameState.reset()
		assert_eq(GameState.state["world"]["day"], 1, "starts on day 1")

		TimeSystem.advance_time_block()
		assert_eq(GameState.state["world"]["day"], 1, "still day 1 after block 1")
		assert_eq(GameState.state["world"]["timeBlock"], 1, "timeBlock 1 after block 1")

		TimeSystem.advance_time_block()
		assert_eq(GameState.state["world"]["day"], 1, "still day 1 after block 2")
		assert_eq(GameState.state["world"]["timeBlock"], 2, "timeBlock 2 after block 2")

		TimeSystem.advance_time_block()
		assert_eq(GameState.state["world"]["day"], 2, "day rolls to 2 after the 3rd block")
		assert_eq(GameState.state["world"]["timeBlock"], 0, "timeBlock resets to 0 on rollover")
		assert_eq(GameState.state["world"]["timeBlocksDone"], [], "timeBlocksDone resets on rollover")
	)

	run_case("is_time_exhausted_tracks_blocks_done", func():
		GameState.reset()
		assert_true(not TimeSystem.is_time_exhausted(), "not exhausted at day start")
		TimeSystem.advance_time_block()
		TimeSystem.advance_time_block()
		assert_true(not TimeSystem.is_time_exhausted(), "not exhausted after 2 of 3 blocks")
	)

	run_case("rest_heals_20_percent_of_hp_max", func():
		GameState.reset()
		GameState.state["player"]["hp"] = 50
		GameState.state["player"]["hpMax"] = 100
		TimeSystem.do_rest()
		assert_eq(GameState.state["player"]["hp"], 70, "50 + round(100*0.2) = 70")
	)

	run_case("rest_heal_is_capped_at_hp_max", func():
		GameState.reset()
		GameState.state["player"]["hp"] = 95
		GameState.state["player"]["hpMax"] = 100
		TimeSystem.do_rest()
		assert_eq(GameState.state["player"]["hp"], 100, "heal caps at hpMax, not 95+20=115")
	)

	run_case("rest_rolls_to_next_day_and_runs_daily_tick", func():
		GameState.reset()
		var start_day: int = GameState.state["world"]["day"]
		var start_cash: int = GameState.state["player"]["cash"]
		TimeSystem.do_rest()
		assert_eq(GameState.state["world"]["day"], start_day + 1, "rest advances the day")
		assert_true(GameState.state["player"]["cash"] < start_cash, "daily_tick's living costs should have run")
	)

	run_case("daily_cost_applies_inflation_multiplier", func():
		GameState.reset()
		GameState.state["barometer"]["political"] = "stable"
		GameState.state["barometer"]["social"] = "stable"
		GameState.state["barometer"]["economic"] = "inflation"
		GameState.state["player"]["cash"] = 1000
		TimeSystem.daily_tick()
		# DAILY_COST = round(50 * (1 + 0.30)) = 65
		assert_eq(GameState.state["player"]["cash"], 1000 - 65, "inflation's +0.30 dailyCost should apply")
	)

	run_case("daily_cost_notification_flags_flat_broke", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 10
		TimeSystem.daily_tick()
		assert_eq(GameState.state["player"]["cash"], 0, "cash floors at 0")
		var last: Dictionary = GameState.state["notifications"][GameState.state["notifications"].size() - 1]
		assert_true(last["text"].contains("flat broke"), "should flag flat broke once cash hits 0")
	)

	run_case("buyer_event_tutorial_trigger_fires_on_day_2", func():
		GameState.reset()
		GameState.state["flags"]["tutorialStage"] = "buyer_event"
		GameState.state["flags"]["buyerEventSeen"] = false
		GameState.state["world"]["day"] = 2
		TimeSystem.daily_tick()
		var found := false
		for n in GameState.state["notifications"]:
			if n["text"].contains("Archie texted"):
				found = true
		assert_true(found, "day >= 2 in buyer_event stage should notify")
	)

	run_case("buyer_event_tutorial_trigger_does_not_fire_once_seen", func():
		GameState.reset()
		GameState.state["flags"]["tutorialStage"] = "buyer_event"
		GameState.state["flags"]["buyerEventSeen"] = true
		GameState.state["world"]["day"] = 2
		TimeSystem.daily_tick()
		var found := false
		for n in GameState.state["notifications"]:
			if n["text"].contains("Archie texted"):
				found = true
		assert_true(not found, "buyerEventSeen should suppress the reminder")
	)

	run_case("day_rollover_resets_currentDistrict_to_shoreditch", func():
		GameState.reset()
		GameState.state["world"]["currentDistrict"] = "camden"
		TimeSystem.advance_time_block()
		TimeSystem.advance_time_block()
		assert_eq(GameState.state["world"]["currentDistrict"], "camden", "still in camden mid-day")
		TimeSystem.advance_time_block()
		assert_eq(GameState.state["world"]["currentDistrict"], "shoreditch", "day rollover resets currentDistrict to home")
	)

	run_case("rest_resets_currentDistrict_to_shoreditch", func():
		GameState.reset()
		GameState.state["world"]["currentDistrict"] = "hampstead"
		TimeSystem.do_rest()
		assert_eq(GameState.state["world"]["currentDistrict"], "shoreditch", "resting resets currentDistrict to home")
	)

	run_case("daily_tick_wires_in_npc_claim_step", func():
		var hit := false
		for seed in range(300):
			GameState.reset()
			var site := {
				"id": "s1", "district": "shoreditch", "tier": "saturated", "oreType": "time",
				"bonuses": [], "discoveredDay": 1, "claimed": false, "factionVein": null,
				"hasNaturalVein": false,
			}
			GameState.state["world"]["sites"] = [site]
			GameState.state["world"]["day"] = 40
			Rng.set_seed(seed)
			TimeSystem.daily_tick()
			if Sites.find_site("s1")["factionVein"] != null:
				hit = true
				break
		assert_true(hit, "daily_tick should reach step 5b (Sites.roll_npc_claims) within 300 tries")
	)

	run_case("daily_tick_wires_in_npc_abandonment_step_right_after_claim_step", func():
		var hit := false
		for seed in range(300):
			GameState.reset()
			var site := {
				"id": "s1", "district": "shoreditch", "tier": "rich", "oreType": "time",
				"bonuses": [], "discoveredDay": 1, "claimed": false,
				"factionVein": { "id": "fv1", "factionId": "collective", "oreType": "time", "level": 1, "devBar": 0, "security": "none", "claimedOnDay": 1 },
				"hasNaturalVein": false,
			}
			GameState.state["world"]["sites"] = [site]
			GameState.state["world"]["day"] = 200
			Rng.set_seed(seed)
			TimeSystem.daily_tick()
			if Sites.find_site("s1") == null:
				hit = true
				break
		assert_true(hit, "daily_tick should reach step 5c (Sites.roll_npc_abandonment) within 300 tries")
	)

	run_case("daily_tick_wires_in_faction_vein_growth_step_right_after_abandonment_step", func():
		var hit := false
		for seed in range(300):
			GameState.reset()
			var site := {
				"id": "s1", "district": "shoreditch", "tier": "fair", "oreType": "time",
				"bonuses": [], "discoveredDay": 1, "claimed": false,
				"factionVein": { "id": "fv1", "factionId": "collective", "oreType": "time", "level": 1, "levelLabel": "Trace", "devBar": 0, "security": "none", "claimedOnDay": 1, "hospitability": { "tier": "fair", "bonuses": [] } },
				"hasNaturalVein": false,
			}
			GameState.state["world"]["sites"] = [site]
			GameState.state["world"]["day"] = 5
			Rng.set_seed(seed)
			TimeSystem.daily_tick()
			var found_site: Variant = Sites.find_site("s1")
			if found_site != null and found_site["factionVein"]["devBar"] > 0:
				hit = true
				break
		assert_true(hit, "daily_tick should reach step 5d (Sites.roll_faction_vein_growth) within 300 tries")
	)

	run_case("daily_tick_wires_in_faction_passive_income_step_right_after_vein_growth_step", func():
		GameState.reset()
		var before: int = GameState.state["factions"]["collective"]["resources"]
		TimeSystem.daily_tick()
		var after: int = GameState.state["factions"]["collective"]["resources"]
		assert_true(after > before, "daily_tick should reach step 5e (Factions.apply_passive_income)")
	)

	run_case("daily_tick_wires_in_faction_vein_income_step_right_after_passive_income_step", func():
		GameState.reset()
		var site := {
			"id": "s1", "district": "shoreditch", "tier": "fair", "oreType": "fate",
			"bonuses": [], "discoveredDay": 1, "claimed": false,
			"factionVein": { "id": "fv1", "factionId": "collective", "oreType": "fate", "level": 5, "levelLabel": "Lode", "devBar": 0, "security": "none", "claimedOnDay": 1, "hospitability": { "tier": "fair", "bonuses": [] } },
			"hasNaturalVein": false,
		}
		GameState.state["world"]["sites"] = [site]
		GameState.state["world"]["day"] = 5
		var before: int = GameState.state["factions"]["collective"]["resources"]
		TimeSystem.daily_tick()
		var after: int = GameState.state["factions"]["collective"]["resources"]
		var passive_only: int = 0
		for industry in GameData.FACTIONS["collective"].get("industries", []):
			passive_only += Factions.INDUSTRY_INCOME.get(industry, 0)
		assert_true(after - before > passive_only, "daily_tick should reach step 5f (Factions.apply_vein_income) on top of passive income")
	)

	run_case("daily_tick_wires_in_faction_security_upgrade_step_right_after_vein_income_step", func():
		GameState.reset()
		var site := {
			"id": "s1", "district": "shoreditch", "tier": "fair", "oreType": "fate",
			"bonuses": [], "discoveredDay": 1, "claimed": false,
			"factionVein": { "id": "fv1", "factionId": "collective", "oreType": "fate", "level": 5, "levelLabel": "Lode", "devBar": 0, "security": "none", "claimedOnDay": 5, "hospitability": { "tier": "fair", "bonuses": [] } },
			"hasNaturalVein": false,
		}
		GameState.state["world"]["sites"] = [site]
		GameState.state["world"]["day"] = 5
		GameState.state["factions"]["collective"]["resources"] = 100000  # affordability guaranteed regardless of this tick's income
		TimeSystem.daily_tick()
		assert_eq(site["factionVein"]["security"], "basic", "daily_tick should reach step 5g (Factions.apply_security_upgrades) and upgrade the affordable eligible vein")
	)

	run_case("daily_tick_wires_in_rivalry_resolution_step_right_after_security_upgrade_step", func():
		# A rich, unsecured collective-owned vein facing a well-resourced Firm
		# (raiding industry, good odds) -- run many seeds and confirm daily_tick
		# eventually reaches step 5h and flips ownership.
		var hit := false
		for seed in range(500):
			GameState.reset()
			var site := {
				"id": "s1", "district": "shoreditch", "tier": "fair", "oreType": "fate",
				"bonuses": [], "discoveredDay": 1, "claimed": false,
				"factionVein": { "id": "fv1", "factionId": "collective", "oreType": "fate", "level": 3, "levelLabel": "Seam", "devBar": 0, "security": "none", "claimedOnDay": 999, "hospitability": { "tier": "fair", "bonuses": [] } },
				"hasNaturalVein": false,
			}
			GameState.state["world"]["sites"] = [site]
			GameState.state["world"]["day"] = 999
			GameState.state["factions"]["firm"]["resources"] = 5000
			GameState.state["factions"]["collective"]["resources"] = 0
			Rng.set_seed(seed)
			TimeSystem.daily_tick()
			if Sites.find_site("s1")["factionVein"]["factionId"] == "firm":
				hit = true
				break
		assert_true(hit, "daily_tick should reach step 5h (Factions.apply_rivalry_resolution) within 500 tries")
	)

	run_case("stub_daily_tick_steps_do_not_crash", func():
		GameState.reset()
		# Just confirms daily_tick runs end to end with the T04/T05/T06/T09
		# stubs in place; those steps get real bodies as those tasks land.
		TimeSystem.daily_tick()
		assert_true(true, "daily_tick completed without error")
	)

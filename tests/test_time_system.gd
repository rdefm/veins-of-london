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
		# do_rest's daily_tick also fires passive regen (bugfixes-42): 50 + round(100*0.05) = 55,
		# then the rest heal itself: 55 + round(100*0.2) = 75.
		assert_eq(GameState.state["player"]["hp"], 75, "50 + passive regen 5 + rest heal 20 = 75")
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

		var bank_log: Array = GameState.state["bankLog"]
		assert_eq(bank_log.size(), 1, "living costs record one bank transaction")
		assert_eq(bank_log[0]["amount"], -65, "the recorded amount matches the inflation-adjusted daily cost")
		assert_eq(bank_log[0]["label"], "Living costs", "the recorded label names the deduction")
	)

	run_case("daily_cost_notification_flags_flat_broke", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 10
		TimeSystem.daily_tick()
		assert_eq(GameState.state["player"]["cash"], 0, "cash floors at 0")
		var last: Dictionary = GameState.state["notifications"][GameState.state["notifications"].size() - 1]
		assert_true(last["text"].contains("flat broke"), "should flag flat broke once cash hits 0")

		var bank_log: Array = GameState.state["bankLog"]
		assert_eq(bank_log[0]["amount"], -10, "the recorded amount is what was actually deducted (10), not the nominal daily cost (50), since cash floored at 0")
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

	# vein-growth-state ticket 01: faction-vein movement now happens at step
	# ④ (Cultivating.drift_veins(), the same pass every vein drifts on), not
	# step ⑤c — Sites.roll_faction_vein_growth() is a no-op placeholder
	# until vein-growth-state ticket 04 lands its prune-back-at-85 body.
	run_case("daily_tick_drifts_a_faction_vein_at_step_4_and_still_reaches_step_5c_without_crashing", func():
		GameState.reset()
		var site := {
			"id": "s1", "district": "shoreditch", "tier": "fair", "oreType": "time",
			"bonuses": [], "discoveredDay": 1, "claimed": false,
			"factionVein": { "id": "fv1", "factionId": "collective", "oreType": "time", "growth": 56, "rampantDays": 0, "security": "none", "claimedOnDay": 1, "hospitability": { "tier": "fair", "bonuses": [] } },
			"hasNaturalVein": false,
		}
		GameState.state["world"]["sites"] = [site]
		GameState.state["world"]["day"] = 5
		TimeSystem.daily_tick()
		var found_site: Variant = Sites.find_site("s1")
		assert_true(found_site != null, "the site should survive an ordinary tick")
		assert_true(found_site["factionVein"]["growth"] > 56, "the faction vein should have drifted right at step 4")
	)

	run_case("daily_tick_wires_in_faction_passive_income_step_right_after_vein_growth_step", func():
		GameState.reset()
		var before: int = GameState.state["factions"]["collective"]["resources"]
		TimeSystem.daily_tick()
		var after: int = GameState.state["factions"]["collective"]["resources"]
		assert_true(after > before, "daily_tick should reach step 5d (Factions.apply_passive_income)")
	)

	run_case("daily_tick_wires_in_faction_vein_income_step_right_after_passive_income_step", func():
		GameState.reset()
		# growth 70, not 100: below FACTION_PRUNE_BACK_THRESHOLD (85), so
		# step ⑤c's prune-back roll never fires here -- this test doesn't
		# seed Rng, so leaving growth at 100 (crossing that threshold) made
		# the resulting value_tier, and therefore the income delta this test
		# asserts on, depend on whatever Rng state happened to carry in from
		# every earlier-run test in the suite. 70 still yields a solidly
		# positive vein income (value_tier 4) with no such roll involved.
		var site := {
			"id": "s1", "district": "shoreditch", "tier": "fair", "oreType": "fate",
			"bonuses": [], "discoveredDay": 1, "claimed": false,
			"factionVein": { "id": "fv1", "factionId": "collective", "oreType": "fate", "growth": 70, "rampantDays": 0, "security": "none", "claimedOnDay": 1, "hospitability": { "tier": "fair", "bonuses": [] } },
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
		assert_true(after - before > passive_only, "daily_tick should reach step 5e (Factions.apply_vein_income) on top of passive income")
	)

	run_case("daily_tick_wires_in_faction_security_upgrade_step_right_after_vein_income_step", func():
		GameState.reset()
		var site := {
			"id": "s1", "district": "shoreditch", "tier": "fair", "oreType": "fate",
			"bonuses": [], "discoveredDay": 1, "claimed": false,
			"factionVein": { "id": "fv1", "factionId": "collective", "oreType": "fate", "growth": 100, "rampantDays": 0, "security": "none", "claimedOnDay": 5, "hospitability": { "tier": "fair", "bonuses": [] } },
			"hasNaturalVein": false,
		}
		GameState.state["world"]["sites"] = [site]
		GameState.state["world"]["day"] = 5
		GameState.state["factions"]["collective"]["resources"] = 100000  # affordability guaranteed regardless of this tick's income
		TimeSystem.daily_tick()
		assert_eq(site["factionVein"]["security"], "basic", "daily_tick should reach step 5f (Factions.apply_security_upgrades) and upgrade the affordable eligible vein")
	)

	run_case("daily_tick_wires_in_rivalry_resolution_step_right_after_security_upgrade_step", func():
		# A rich, unsecured collective-owned vein facing a well-resourced Firm
		# (raiding industry, good odds) -- run many seeds and confirm daily_tick
		# eventually reaches step 5g and flips ownership.
		var hit := false
		for seed in range(500):
			GameState.reset()
			var site := {
				"id": "s1", "district": "shoreditch", "tier": "fair", "oreType": "fate",
				"bonuses": [], "discoveredDay": 1, "claimed": false,
				"factionVein": { "id": "fv1", "factionId": "collective", "oreType": "fate", "growth": 50, "rampantDays": 0, "security": "none", "claimedOnDay": 999, "hospitability": { "tier": "fair", "bonuses": [] } },
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
		assert_true(hit, "daily_tick should reach step 5g (Factions.apply_rivalry_resolution) within 500 tries")
	)

	run_case("daily_tick_wires_in_direction_b_raid_resolution_step_right_after_rivalry_resolution_step", func():
		# A hated, unsecured, rough-district player vein facing a faction it's
		# burned relation with -- run many seeds and confirm daily_tick
		# eventually reaches step 5h and flips the vein to that faction.
		var hit := false
		for seed in range(500):
			GameState.reset()
			var vein := {
				"id": "pv1", "oreType": "fate", "growth": 50, "rampantDays": 0,
				"security": "none", "alarmUpgrades": [],
				"location": "Test St, nowhere", "claimedOnDay": 0, "district": "camden",
				"siteId": "s1", "hospitability": { "tier": "fair", "bonuses": [] },
			}
			GameState.state["player"]["veins"] = [vein]
			GameState.state["world"]["sites"] = [{
				"id": "s1", "district": "camden", "tier": "fair", "oreType": "fate",
				"bonuses": [], "discoveredDay": 1, "claimed": true, "factionVein": null,
				"hasNaturalVein": false,
			}]
			GameState.state["factions"]["firm"]["relation"] = -200  # camden's factionPresence
			Rng.set_seed(seed)
			TimeSystem.daily_tick()
			var site: Variant = Sites.find_site("s1")
			if site != null and site["factionVein"] != null and site["factionVein"]["factionId"] == "firm":
				hit = true
				break
		assert_true(hit, "daily_tick should reach step 5h (Raiding.apply_raid_resolution) within 500 tries")
	)

	# ── bugfixes-30: James job proactive daily offer + deadline expiry ──

	run_case("daily_tick_wires_in_james_job_offer_roll_step", func():
		GameState.reset()
		GameState.state["player"]["cash"] = Jobs.FLAT_PAY_LOW_CASH_THRESHOLD  # guarantees a 100% flatPay roll
		TimeSystem.daily_tick()
		assert_eq(GameState.state["flags"]["jamesJobActive"], true, "daily_tick should reach the James job offer roll step")
		assert_eq(GameState.state["jamesJob"]["type"], "flatPay", "low cash should always roll the flatPay job")
	)

	run_case("daily_tick_wires_in_james_job_expiry_step_before_the_offer_roll", func():
		GameState.reset()
		GameState.state["world"]["day"] = 10
		GameState.state["player"]["cash"] = Jobs.FLAT_PAY_LOW_CASH_THRESHOLD + 1000  # keep the offer roll from being forced to 100%
		var job := Jobs.generate_james_job()
		job["byDay"] = 9  # already overdue as of day 10
		GameState.state["jamesJob"] = job
		GameState.state["flags"]["jamesJobActive"] = true
		GameState.state["flags"]["jamesJobAccepted"] = true
		var relation_before: int = GameState.state["contacts"]["james"]["relation"]

		Rng.set_seed(1)
		TimeSystem.daily_tick()

		assert_eq(GameState.state["contacts"]["james"]["relation"], relation_before + Jobs.MISSED_DEADLINE_RELATION_PENALTY, "daily_tick should reach the James job expiry step and dock relation for the missed deadline")
	)

	# ── calc-effect-wiring-02: healing salve HoT ────────────────────────

	run_case("healing_salve_ticks_daily_amount_and_decrements_days_left", func():
		GameState.reset()
		GameState.state["player"]["hp"] = 50
		GameState.state["player"]["hpMax"] = 100
		GameState.state["player"]["healingSalveDaysLeft"] = 2
		GameState.state["player"]["healingSalveDailyAmount"] = 5
		TimeSystem.daily_tick()
		# 50 + salve 5 + passive regen round(100*0.05)=5 (bugfixes-42, stacks with the salve) = 60.
		assert_eq(GameState.state["player"]["hp"], 60, "should heal by the daily amount, plus passive regen stacking on top")
		assert_eq(GameState.state["player"]["healingSalveDaysLeft"], 1, "daysLeft should decrement by 1")
	)

	run_case("healing_salve_stops_once_days_left_hits_zero", func():
		GameState.reset()
		GameState.state["player"]["hp"] = 50
		GameState.state["player"]["hpMax"] = 100
		GameState.state["player"]["healingSalveDaysLeft"] = 0
		GameState.state["player"]["healingSalveDailyAmount"] = 5
		TimeSystem.daily_tick()
		# no salve heal, but passive regen (bugfixes-42) still fires unconditionally: 50 + 5 = 55.
		assert_eq(GameState.state["player"]["hp"], 55, "no salve active -> no salve heal, but passive regen still applies")
	)

	run_case("healing_salve_heal_is_capped_at_hpMax", func():
		GameState.reset()
		GameState.state["player"]["hp"] = 98
		GameState.state["player"]["hpMax"] = 100
		GameState.state["player"]["healingSalveDaysLeft"] = 1
		GameState.state["player"]["healingSalveDailyAmount"] = 5
		TimeSystem.daily_tick()
		assert_eq(GameState.state["player"]["hp"], 100, "heal caps at hpMax, not 98+5=103")
	)

	# ── bugfixes-42: passive HP regen ───────────────────────────────────

	run_case("passive_regen_heals_5_percent_of_hp_max_unconditionally", func():
		GameState.reset()
		GameState.state["player"]["hp"] = 50
		GameState.state["player"]["hpMax"] = 100
		TimeSystem.daily_tick()
		assert_eq(GameState.state["player"]["hp"], 55, "50 + round(100*0.05) = 55")
	)

	run_case("passive_regen_caps_at_hp_max", func():
		GameState.reset()
		GameState.state["player"]["hp"] = 98
		GameState.state["player"]["hpMax"] = 100
		TimeSystem.daily_tick()
		assert_eq(GameState.state["player"]["hp"], 100, "heal caps at hpMax, not 98+5=103")
	)

	run_case("passive_regen_skips_notification_when_already_at_full_hp", func():
		GameState.reset()
		GameState.state["player"]["hp"] = GameState.state["player"]["hpMax"]
		TimeSystem.daily_tick()
		var found := false
		for n in GameState.state["notifications"]:
			if n["text"].contains("rest easy"):
				found = true
		assert_true(not found, "no passive regen notification when already at full HP")
	)

	run_case("passive_regen_stacks_with_an_active_healing_salve_tick_on_the_same_day", func():
		GameState.reset()
		GameState.state["player"]["hp"] = 50
		GameState.state["player"]["hpMax"] = 100
		GameState.state["player"]["healingSalveDaysLeft"] = 1
		GameState.state["player"]["healingSalveDailyAmount"] = 5
		TimeSystem.daily_tick()
		# salve heal 5 (50->55) then passive regen round(100*0.05)=5 (55->60) -- both apply, neither replaces the other.
		assert_eq(GameState.state["player"]["hp"], 60, "salve heal and passive regen should both apply the same day")
		assert_eq(GameState.state["player"]["healingSalveDaysLeft"], 0, "salve daysLeft should still decrement independently")
	)

	run_case("stub_daily_tick_steps_do_not_crash", func():
		GameState.reset()
		# Just confirms daily_tick runs end to end with the T04/T05/T06/T09
		# stubs in place; those steps get real bodies as those tasks land.
		TimeSystem.daily_tick()
		assert_true(true, "daily_tick completed without error")
	)

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
		# rented bedsit bill = round(50 * (1 + 0.30)) = 65
		assert_eq(GameState.state["player"]["cash"], 1000 - 65, "inflation's +0.30 dailyCost should apply")

		var bank_log: Array = GameState.state["bankLog"]
		assert_eq(bank_log.size(), 1, "living costs record one bank transaction")
		assert_eq(bank_log[0]["amount"], -65, "the recorded amount matches the inflation-adjusted daily cost")
		assert_eq(bank_log[0]["label"], "Living costs", "the recorded label names the deduction")
	)

	run_case("daily_bill_charges_rent_when_rented", func():
		GameState.reset()
		GameState.state["home"]["tier"] = "flat"
		GameState.state["home"]["tenure"] = "rented"
		GameState.state["player"]["cash"] = 500
		TimeSystem._apply_living_costs()
		assert_eq(GameState.state["player"]["cash"], 420, "rented flat pays rent 80")
	)

	run_case("daily_bill_charges_utilities_when_owned", func():
		GameState.reset()
		GameState.state["home"]["tier"] = "townhouse"
		GameState.state["home"]["tenure"] = "owned"
		GameState.state["player"]["cash"] = 500
		TimeSystem._apply_living_costs()
		assert_eq(GameState.state["player"]["cash"], 435, "owned townhouse pays its ownedDailyCost 65")
	)

	run_case("daily_bill_rent_scales_with_inflation", func():
		GameState.reset()
		GameState.state["barometer"]["economic"] = "inflation"
		GameState.state["home"]["tier"] = "flat"
		GameState.state["home"]["tenure"] = "rented"
		GameState.state["player"]["cash"] = 500
		TimeSystem._apply_living_costs()
		assert_eq(GameState.state["player"]["cash"], 396, "rented flat under inflation pays round(80 × 1.3) = 104")
	)

	run_case("daily_bill_notification_states_the_amount_actually_paid", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 30
		TimeSystem._apply_living_costs()
		var last: Dictionary = GameState.state["notifications"][GameState.state["notifications"].size() - 1]
		assert_true(last["text"].contains("-£30 living costs"), "notification shows the 30 paid, not the nominal 50: %s" % last["text"])
		assert_true(last["text"].contains("£20 short"), "notification states the shortfall: %s" % last["text"])
		assert_eq(last["category"], Notify.CATEGORY_WARNING)
	)

	run_case("arrears_zero_cash_rented_bedsit", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 0
		TimeSystem._apply_living_costs()
		assert_eq(GameState.state["home"]["arrears"], 50)
		assert_eq(GameState.state["home"]["arrearsDays"], 1)
		assert_eq(GameState.state["player"]["cash"], 0)
	)

	run_case("arrears_partial_cash_rented_bedsit", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 30
		TimeSystem._apply_living_costs()
		assert_eq(GameState.state["player"]["cash"], 0)
		assert_eq(GameState.state["home"]["arrears"], 20)
		assert_eq(GameState.state["home"]["arrearsDays"], 1)
	)

	run_case("arrears_partial_payment_does_not_reset_the_clock", func():
		GameState.reset()
		GameState.state["home"]["arrears"] = 100
		GameState.state["home"]["arrearsDays"] = 3
		GameState.state["player"]["cash"] = 60
		TimeSystem._apply_living_costs()
		assert_eq(GameState.state["player"]["cash"], 0)
		assert_eq(GameState.state["home"]["arrears"], 90, "no interest at days 3; 60 off 100, then bill 50 unpaid")
		assert_eq(GameState.state["home"]["arrearsDays"], 4)
		var bank_log: Array = GameState.state["bankLog"]
		assert_eq(bank_log.size(), 1)
		assert_eq(bank_log[0]["label"], "Arrears")
		assert_eq(bank_log[0]["amount"], -60)
		var last: Dictionary = GameState.state["notifications"][GameState.state["notifications"].size() - 1]
		assert_true(last["text"].contains("-£60 off arrears"), last["text"])
		assert_true(last["text"].contains("owed £90"), last["text"])
	)

	run_case("arrears_rented_flat_ten_rollover_table_ends_in_rented_studio_with_debt_kept", func():
		GameState.reset()
		var home: Dictionary = GameState.state["home"]
		home["tier"] = "flat"
		home["tenure"] = "rented"
		var expected := [80, 160, 240, 320, 400, 500, 605, 715, 831]
		for i in expected.size():
			GameState.state["player"]["cash"] = 0
			TimeSystem._apply_living_costs()
			assert_eq(home["arrears"], expected[i], "rollover %d arrears" % (i + 1))
			assert_eq(home["arrearsDays"], i + 1, "rollover %d days" % (i + 1))
			assert_eq(home["tier"], "flat", "no downgrade before rollover 10")
		TimeSystem._apply_living_costs()
		assert_eq(home["tier"], "studio", "rollover 10 drops one tier")
		assert_eq(home["tenure"], "rented")
		assert_eq(home["arrears"], 953, "rented tier lost: arrears kept")
		assert_eq(home["arrearsDays"], 0, "clock restarts")
		var last: Dictionary = GameState.state["notifications"][GameState.state["notifications"].size() - 1]
		assert_eq(last["category"], Notify.CATEGORY_WARNING, "downgrade gets its own warning")
		assert_true(last["text"].contains("owe £953"), last["text"])

		# Interest resumes only from rollover 6 of the new count.
		for i in 5:
			TimeSystem._apply_living_costs()
		assert_eq(home["arrears"], 953 + 300, "5 rollovers at the studio, no interest yet")
		TimeSystem._apply_living_costs()
		assert_eq(home["arrears"], 1253 + GameState.round_epsilon(1253 * 0.05) + 60, "interest on the 6th rollover")
	)

	run_case("arrears_owned_flat_table_ends_in_rented_studio_with_debt_cleared", func():
		GameState.reset()
		var home: Dictionary = GameState.state["home"]
		home["tier"] = "flat"
		home["tenure"] = "owned"
		var expected := [58, 116, 174, 232, 290, 363, 439, 519, 603]
		for i in expected.size():
			GameState.state["player"]["cash"] = 0
			TimeSystem._apply_living_costs()
			assert_eq(home["arrears"], expected[i], "rollover %d arrears" % (i + 1))
		TimeSystem._apply_living_costs()
		assert_eq(home["tier"], "studio")
		assert_eq(home["tenure"], "rented")
		assert_eq(home["arrears"], 0, "owned tier lost: arrears cleared")
		assert_eq(home["arrearsDays"], 0)
	)

	run_case("arrears_owned_flat_rollover_10_reaches_691_before_the_drop", func():
		GameState.reset()
		var home: Dictionary = GameState.state["home"]
		home["tier"] = "flat"
		home["tenure"] = "owned"
		home["arrears"] = 603
		home["arrearsDays"] = 8
		GameState.state["player"]["cash"] = 0
		# The ADR's rollover-10 balance, with the clock held one day short so
		# the drop's debt-clear doesn't hide it.
		TimeSystem._apply_living_costs()
		assert_eq(home["arrears"], 603 + 30 + 58, "interest 30 + utilities 58 = 691")
	)

	run_case("arrears_recovery_partial_still_in_arrears", func():
		GameState.reset()
		var home: Dictionary = GameState.state["home"]
		home["arrears"] = 400
		home["arrearsDays"] = 5
		GameState.state["player"]["cash"] = 300
		TimeSystem._apply_living_costs()
		assert_eq(home["arrears"], 170)
		assert_eq(home["arrearsDays"], 6)
		assert_eq(GameState.state["player"]["cash"], 0)
	)

	run_case("arrears_recovery_full_clears_debt_and_clock", func():
		GameState.reset()
		var home: Dictionary = GameState.state["home"]
		home["arrears"] = 400
		home["arrearsDays"] = 5
		GameState.state["player"]["cash"] = 600
		TimeSystem._apply_living_costs()
		assert_eq(home["arrears"], 0)
		assert_eq(home["arrearsDays"], 0)
		assert_eq(GameState.state["player"]["cash"], 130)
	)

	run_case("arrears_exact_affordability_clears_everything", func():
		GameState.reset()
		var home: Dictionary = GameState.state["home"]
		home["arrears"] = 70
		home["arrearsDays"] = 2
		GameState.state["player"]["cash"] = 120
		TimeSystem._apply_living_costs()
		assert_eq(home["arrears"], 0)
		assert_eq(home["arrearsDays"], 0)
		assert_eq(GameState.state["player"]["cash"], 0)
	)

	run_case("arrears_interest_ignores_the_barometer", func():
		GameState.reset()
		GameState.state["barometer"]["economic"] = "inflation"
		var home: Dictionary = GameState.state["home"]
		home["arrears"] = 400
		home["arrearsDays"] = 5
		GameState.state["player"]["cash"] = 0
		TimeSystem._apply_living_costs()
		# interest round(400 × 0.05) = 20 unscaled; only today's bill scales: round(50 × 1.3) = 65.
		assert_eq(home["arrears"], 400 + 20 + 65)
	)

	run_case("arrears_bedsit_never_downgrades", func():
		GameState.reset()
		var home: Dictionary = GameState.state["home"]
		for i in 15:
			GameState.state["player"]["cash"] = 0
			TimeSystem._apply_living_costs()
		assert_eq(home["tier"], "bedsit")
		assert_eq(home["arrearsDays"], 15, "clock keeps running at the floor")
		assert_true(home["arrears"] > 750, "interest keeps accruing")
	)

	run_case("forced_downgrade_wipes_rooms_unassigns_staff_reverts_gym_and_drops_security", func():
		GameState.reset()
		var home: Dictionary = GameState.state["home"]
		var player: Dictionary = GameState.state["player"]
		home["tier"] = "flat"
		home["tenure"] = "rented"
		home["security"] = ["lock", "alarm"]
		player["cash"] = 2000
		assert_true(Home.add_room("homeGym")["ok"])
		var contact_id: String = GameState.state["contacts"].keys()[0]
		GameState.state["contacts"][contact_id]["recruited"] = true
		Contacts.assign_to_room(contact_id, "homeGym")
		var hp_max_with_gym: int = player["hpMax"]
		player["hp"] = hp_max_with_gym
		player["cash"] = 0
		home["arrears"] = 100
		home["arrearsDays"] = 9
		TimeSystem._apply_living_costs()
		assert_eq(home["tier"], "studio")
		assert_eq(home["rooms"], [], "rooms wiped")
		assert_eq(Contacts.get_contact_in_room("homeGym"), null, "staff unassigned")
		assert_eq(player["hpMax"], hp_max_with_gym - 10, "gym bonus reverted")
		assert_eq(player["hp"], player["hpMax"], "hp clamped")
		assert_eq(home["security"], ["lock", "alarm"], "lock and alarm (minTier studio) kept")
		assert_eq(player["cash"], 0, "cash never negative")
	)

	run_case("arrears_snapshot_round_trip_restores_arrears_clock_and_tenure", func():
		GameState.reset()
		var home: Dictionary = GameState.state["home"]
		home["tier"] = "flat"
		home["tenure"] = "owned"
		home["arrears"] = 603
		home["arrearsDays"] = 9
		GameState.state["player"]["cash"] = 0
		var snapshot: Dictionary = GameState.deep_copy(GameState.state)
		TimeSystem._apply_living_costs()
		assert_eq(GameState.state["home"]["tier"], "studio", "sanity: downgrade happened")
		GameState.state = snapshot
		assert_eq(GameState.state["home"]["tier"], "flat")
		assert_eq(GameState.state["home"]["tenure"], "owned")
		assert_eq(GameState.state["home"]["arrears"], 603)
		assert_eq(GameState.state["home"]["arrearsDays"], 9)
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

	# 83-contacts-archie-james-sms-port: the day>=2 "Archie texted" beat is
	# now the real queued SMS content itself (Messages.has_any_unread()),
	# not a separate Notify banner -- same as every other queue_pending_
	# message caller (archie_cultivation.json's col_a1_intro, ...).
	run_case("buyer_event_tutorial_trigger_fires_on_day_2", func():
		GameState.reset()
		GameState.state["flags"]["tutorialStage"] = "buyer_event"
		GameState.state["flags"]["buyerEventSeen"] = false
		GameState.state["world"]["day"] = 2
		TimeSystem.daily_tick()
		assert_true(Messages.has_unread("archie"), "day >= 2 in buyer_event stage should queue the SMS content")
	)

	run_case("buyer_event_tutorial_trigger_does_not_fire_once_seen", func():
		GameState.reset()
		GameState.state["flags"]["tutorialStage"] = "buyer_event"
		GameState.state["flags"]["buyerEventSeen"] = true
		# bugfixes-95: suppress the unrelated Archie tag-along deal roll (also
		# a daily-tick step now, also queued onto the "archie" thread) so it
		# can't be mistaken for the reminder this case is actually checking --
		# same convention test_time_system.gd's own James-job-expiry case
		# uses to suppress that roll (jamesJobActive).
		GameState.state["flags"]["archieDealActive"] = true
		GameState.state["world"]["day"] = 2
		TimeSystem.daily_tick()
		assert_true(not Messages.has_unread("archie"), "buyerEventSeen should suppress the reminder")
	)

	# 83-contacts-archie-james-sms-port: ARCHIE_SMS_2's content, ported off
	# the old sms_archie_2.gd screen into the generic message thread.
	run_case("buyer_event_day_trigger_queues_the_archie_2_sms_content_exactly_once", func():
		GameState.reset()
		GameState.state["flags"]["tutorialStage"] = "buyer_event"
		GameState.state["flags"]["buyerEventSeen"] = false
		# bugfixes-95: suppress the unrelated Archie tag-along deal roll (see
		# this file's own comment on buyer_event_tutorial_trigger_does_not_fire_once_seen above).
		GameState.state["flags"]["archieDealActive"] = true
		GameState.state["world"]["day"] = 2

		TimeSystem.daily_tick()
		assert_eq(GameState.state["messages"]["archie"].size(), 5, "all 5 of ARCHIE_SMS_2's lines land in the thread (4 push_message + the pending entry's own text)")
		assert_eq(Messages.pending_for("archie").size(), 1, "the 5th (final) line also becomes the pending Continue entry")
		assert_eq(Messages.pending_for("archie")[0]["kind"], "buyer", "the pending entry starts the buyer event")
		assert_true(GameState.state["flags"]["archieBuyerSmsQueued"], "idempotency guard is set")

		# Another day tick under the same still-unresolved condition (player
		# hasn't acted yet) must not queue a second copy of the thread.
		GameState.state["world"]["day"] = 3
		TimeSystem.daily_tick()
		assert_eq(GameState.state["messages"]["archie"].size(), 5, "no duplicate lines queued on a later day tick")
		assert_eq(Messages.pending_for("archie").size(), 1, "no duplicate pending entry queued on a later day tick")
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

	run_case("daily_tick_wires_in_hakim_intel_step_right_after_raid_resolution_step", func():
		# collective1-17: unlocked, well past the 3-day gap, both districts
		# nowhere near siteCap -- run many seeds and confirm daily_tick
		# eventually reaches step 5i and queues Hakim's text.
		var hit := false
		for seed in range(200):
			GameState.reset()
			GameState.state["flags"]["hakimIntelUnlocked"] = true
			GameState.state["world"]["day"] = 20
			Rng.set_seed(seed)
			TimeSystem.daily_tick()
			if not Messages.pending_for("hakim").is_empty():
				hit = true
				break
		assert_true(hit, "daily_tick should reach step 5i (Collective.maybe_trigger_hakim_intel) within 200 tries")
	)

	run_case("daily_tick_wires_in_the_collective_ore_stock_restock_step_right_after_hakim_intel_step", func():
		# collective-ore-stock T01: run many seeds and confirm daily_tick
		# eventually reaches step 5j and rolls the Collective's ore stock.
		# Full behavioural coverage (range, all-5-together, fire rate, the
		# unlock-moment pre-roll) lives in tests/test_ore_stock.gd -- this is
		# just the wiring check, matching every other step's test above.
		var hit := false
		for seed in range(200):
			GameState.reset()
			Rng.set_seed(seed)
			TimeSystem.daily_tick()
			if not GameState.state["factions"]["collective"]["oreStock"].is_empty():
				hit = true
				break
		assert_true(hit, "daily_tick should reach step 5j (Factions.maybe_restock_ore) within 200 tries")
	)

	# ── bugfixes-30: James job proactive daily offer + deadline expiry ──

	run_case("daily_tick_wires_in_james_job_offer_roll_step", func():
		GameState.reset()
		GameState.state["flags"]["jamesMotionEventSeen"] = true
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

	# dial-device ticket 07: step ⑦ now calls Dial.daily_regen() in place of
	# the old Devices.reset_daily_charges().
	run_case("daily_tick_wires_in_dial_daily_regen_step", func():
		GameState.reset()
		var player: Dictionary = GameState.state["player"]
		player["dial"] = {
			"level": 1, "xp": 0, "currentCharge": 5, "maxCharge": 20, "rechargeRate": 2.0,
			"combatRegenTurnCounter": 0, "lastRegenDay": GameState.state["world"]["day"] - 1,
			"capacityMax": 4, "movement": { "archetype": "recharge", "oreType": "time", "tier": 1 },
			"loadedComplications": [], "haftId": "collective_brolly",
		}
		TimeSystem.daily_tick()
		assert_almost_eq(GameState.state["player"]["dial"]["currentCharge"], 7.0, 0.0001, "daily_tick should reach step 7 (Dial.daily_regen adding rechargeRate)")
	)

	run_case("stub_daily_tick_steps_do_not_crash", func():
		GameState.reset()
		# Just confirms daily_tick runs end to end with the T04/T05/T06/T09
		# stubs in place; those steps get real bodies as those tasks land.
		TimeSystem.daily_tick()
		assert_true(true, "daily_tick completed without error")
	)

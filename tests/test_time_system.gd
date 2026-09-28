extends "res://tests/test_base.gd"

const Fixtures := preload("res://tests/support/fixtures.gd")


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

	run_case("advance_time_block_runs_the_staff_step_before_any_rollover", func():
		GameState.reset()
		var veins := _staff_overgrown_veins(4)
		TimeSystem.advance_time_block()
		assert_eq(veins[0]["growth"], 70, "the block that just ended pruned the first vein")
		assert_eq(veins[1]["growth"], 95, "one action per block")
		TimeSystem.advance_time_block()
		TimeSystem.advance_time_block()
		assert_eq(GameState.state["world"]["day"], 2)
		assert_eq(GameState.state["contacts"]["archie"]["cultivatingXP"], 3 * GameData.CULTIVATOR_ACTION_XP, "3 actions in the day, none added by the rollover")
		assert_true(MorningAccounts.latest()["production"]["ore"]["time"] > 0, "the Morning Brief aggregates the day's block yields")
	)

	run_case("do_rest_runs_the_staff_step_for_every_remaining_block", func():
		GameState.reset()
		_staff_overgrown_veins(6)
		TimeSystem.advance_time_block()
		TimeSystem.do_rest()
		assert_eq(GameState.state["world"]["day"], 2)
		assert_eq(GameState.state["contacts"]["archie"]["cultivatingXP"], 3 * GameData.CULTIVATOR_ACTION_XP, "1 block played + 2 rested = 3 actions")
		TimeSystem.do_rest()
		assert_eq(GameState.state["contacts"]["archie"]["cultivatingXP"], 6 * GameData.CULTIVATOR_ACTION_XP, "a full rested day is 3 more")
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
		GameState.state["world"]["day"] = 7  # SUN, so the rest rolls into MON
		var start_cash: int = GameState.state["player"]["cash"]
		TimeSystem.do_rest()
		assert_eq(GameState.state["world"]["day"], 8, "rest advances the day")
		assert_true(GameState.state["player"]["cash"] < start_cash, "daily_tick's Monday living costs should have run")
	)

	run_case("living_costs_charge_only_on_the_rollover_into_monday", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 100000
		var charged_days: Array = []
		for day in range(2, 16):
			GameState.state["world"]["day"] = day
			var before: int = GameState.state["player"]["cash"]
			var result: Dictionary = TimeSystem._apply_living_costs()
			if GameState.state["player"]["cash"] != before:
				charged_days.append(day)
				assert_eq(before - GameState.state["player"]["cash"], 350, "one weekly bill: 7 × the bedsit's 50")
			else:
				assert_eq(result, { "interest": 0, "shortfall": 0, "arrears": 0, "downgrade": {} }, "day %d: nothing happens" % day)
		assert_eq(charged_days, [8, 15], "only MON day 8 and MON day 15 charge")
		var labels: Array = GameState.state["bankLog"].map(func(e: Dictionary) -> String: return e["label"])
		assert_eq(labels, ["Weekly living costs", "Weekly living costs"])
	)

	run_case("daily_cost_applies_inflation_multiplier", func():
		GameState.reset()
		GameState.state["barometer"]["political"] = "stable"
		GameState.state["barometer"]["social"] = "stable"
		GameState.state["barometer"]["economic"] = "inflation"
		GameState.state["player"]["cash"] = 1000
		TimeSystem.daily_tick()
		# Day 1 is MON: rented bedsit weekly bill = round(350 * (1 + 0.30)) = 455
		assert_eq(GameState.state["player"]["cash"], 1000 - 455, "inflation's +0.30 dailyCost should apply")

		var bank_log: Array = GameState.state["bankLog"]
		assert_eq(bank_log.size(), 1, "living costs record one bank transaction")
		assert_eq(bank_log[0]["amount"], -455, "the recorded amount matches the inflation-adjusted weekly cost")
		assert_eq(bank_log[0]["label"], "Weekly living costs", "the recorded label names the deduction")
	)

	run_case("weekly_bill_charges_rent_when_rented", func():
		GameState.reset()
		GameState.state["home"]["tier"] = "flat"
		GameState.state["home"]["tenure"] = "rented"
		GameState.state["player"]["cash"] = 1000
		TimeSystem._apply_living_costs()
		assert_eq(GameState.state["player"]["cash"], 440, "rented flat pays rent 7 × 80")
	)

	run_case("weekly_bill_charges_utilities_when_owned", func():
		GameState.reset()
		GameState.state["home"]["tier"] = "townhouse"
		GameState.state["home"]["tenure"] = "owned"
		GameState.state["player"]["cash"] = 1000
		TimeSystem._apply_living_costs()
		assert_eq(GameState.state["player"]["cash"], 545, "owned townhouse pays 7 × its ownedDailyCost 65")
	)

	run_case("weekly_bill_rent_scales_with_inflation", func():
		GameState.reset()
		GameState.state["barometer"]["economic"] = "inflation"
		GameState.state["home"]["tier"] = "flat"
		GameState.state["home"]["tenure"] = "rented"
		GameState.state["player"]["cash"] = 1000
		TimeSystem._apply_living_costs()
		assert_eq(GameState.state["player"]["cash"], 272, "rented flat under inflation pays round(560 × 1.3) = 728")
	)

	run_case("weekly_bill_notification_states_the_amount_actually_paid", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 30
		TimeSystem._apply_living_costs()
		var last: Dictionary = GameState.state["notifications"][GameState.state["notifications"].size() - 1]
		assert_true(last["text"].contains("-£30 weekly living costs"), "notification shows the 30 paid, not the nominal 350: %s" % last["text"])
		assert_true(last["text"].contains("£320 short"), "notification states the shortfall: %s" % last["text"])
		assert_eq(last["category"], Notify.CATEGORY_WARNING)
	)

	run_case("arrears_zero_cash_rented_bedsit", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 0
		TimeSystem._apply_living_costs()
		assert_eq(GameState.state["home"]["arrears"], 350)
		assert_eq(GameState.state["home"]["arrearsWeeks"], 1)
		assert_eq(GameState.state["player"]["cash"], 0)
	)

	run_case("arrears_partial_cash_rented_bedsit", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 30
		TimeSystem._apply_living_costs()
		assert_eq(GameState.state["player"]["cash"], 0)
		assert_eq(GameState.state["home"]["arrears"], 320)
		assert_eq(GameState.state["home"]["arrearsWeeks"], 1)
	)

	run_case("arrears_partial_payment_does_not_reset_the_clock", func():
		GameState.reset()
		GameState.state["home"]["arrears"] = 100
		GameState.state["home"]["arrearsWeeks"] = 1
		GameState.state["player"]["cash"] = 60
		TimeSystem._apply_living_costs()
		assert_eq(GameState.state["player"]["cash"], 0)
		assert_eq(GameState.state["home"]["arrears"], 395, "interest 5 on 100; 60 off 105, then bill 350 unpaid")
		assert_eq(GameState.state["home"]["arrearsWeeks"], 2)
		var bank_log: Array = GameState.state["bankLog"]
		assert_eq(bank_log.size(), 1)
		assert_eq(bank_log[0]["label"], "Arrears")
		assert_eq(bank_log[0]["amount"], -60)
		var last: Dictionary = GameState.state["notifications"][GameState.state["notifications"].size() - 1]
		assert_true(last["text"].contains("-£60 off arrears"), last["text"])
		assert_true(last["text"].contains("owed £395"), last["text"])
	)

	run_case("arrears_rented_flat_second_monday_ends_in_rented_studio_with_debt_kept", func():
		GameState.reset()
		var home: Dictionary = GameState.state["home"]
		home["tier"] = "flat"
		home["tenure"] = "rented"
		GameState.state["player"]["cash"] = 0
		TimeSystem._apply_living_costs()
		assert_eq(home["arrears"], 560, "first Monday: the week's 560 unpaid")
		assert_eq(home["arrearsWeeks"], 1)
		assert_eq(home["tier"], "flat", "no downgrade on the first missed week")
		TimeSystem._apply_living_costs()
		assert_eq(home["tier"], "studio", "the second missed week drops one tier")
		assert_eq(home["tenure"], "rented")
		assert_eq(home["arrears"], 560 + 28 + 560, "interest 28, rented tier lost: arrears kept")
		assert_eq(home["arrearsWeeks"], 0, "clock restarts")
		var last: Dictionary = GameState.state["notifications"][GameState.state["notifications"].size() - 1]
		assert_eq(last["category"], Notify.CATEGORY_WARNING, "downgrade gets its own warning")
		assert_true(last["text"].contains("owe £1148"), last["text"])

		# Interest resumes only from the second Monday of the new count.
		TimeSystem._apply_living_costs()
		assert_eq(home["arrears"], 1148 + 420, "first Monday at the studio, no interest yet")
		TimeSystem._apply_living_costs()
		assert_eq(home["arrears"], 1568 + GameState.round_epsilon(1568 * 0.05) + 420, "interest on the second Monday")
	)

	run_case("arrears_owned_flat_ends_in_rented_studio_with_debt_cleared", func():
		GameState.reset()
		var home: Dictionary = GameState.state["home"]
		home["tier"] = "flat"
		home["tenure"] = "owned"
		GameState.state["player"]["cash"] = 0
		TimeSystem._apply_living_costs()
		assert_eq(home["arrears"], 406, "7 × utilities 58")
		var result: Dictionary = TimeSystem._apply_living_costs()
		assert_eq(result["arrears"], 406 + 20 + 406, "interest 20 + utilities 406 = 832 before the drop")
		assert_eq(home["tier"], "studio")
		assert_eq(home["tenure"], "rented")
		assert_eq(home["arrears"], 0, "owned tier lost: arrears cleared")
		assert_eq(home["arrearsWeeks"], 0)
	)

	run_case("arrears_downgrade_lands_seven_days_after_the_first_missed_bill", func():
		GameState.reset()
		var home: Dictionary = GameState.state["home"]
		home["tier"] = "flat"
		home["tenure"] = "rented"
		var downgrade_day := 0
		for day in range(1, 16):
			GameState.state["world"]["day"] = day
			GameState.state["player"]["cash"] = 0
			TimeSystem._apply_living_costs()
			if downgrade_day == 0 and home["tier"] == "studio":
				downgrade_day = day
			if day < 8:
				assert_eq(home["arrears"], 560, "day %d: arrears only move on a Monday" % day)
		assert_eq(downgrade_day, 8, "missed MON day 1, lost the flat MON day 8")
	)

	run_case("arrears_recovery_partial_still_in_arrears", func():
		GameState.reset()
		var home: Dictionary = GameState.state["home"]
		home["arrears"] = 400
		home["arrearsWeeks"] = 1
		GameState.state["player"]["cash"] = 300
		TimeSystem._apply_living_costs()
		assert_eq(home["arrears"], 470, "interest 20; 300 off 420; bill 350 unpaid")
		assert_eq(home["arrearsWeeks"], 2)
		assert_eq(GameState.state["player"]["cash"], 0)
	)

	run_case("arrears_recovery_full_clears_debt_and_clock", func():
		GameState.reset()
		var home: Dictionary = GameState.state["home"]
		home["arrears"] = 400
		home["arrearsWeeks"] = 1
		GameState.state["player"]["cash"] = 1000
		TimeSystem._apply_living_costs()
		assert_eq(home["arrears"], 0)
		assert_eq(home["arrearsWeeks"], 0)
		assert_eq(GameState.state["player"]["cash"], 230)
	)

	run_case("arrears_exact_affordability_clears_everything", func():
		GameState.reset()
		var home: Dictionary = GameState.state["home"]
		home["arrears"] = 100
		home["arrearsWeeks"] = 1
		GameState.state["player"]["cash"] = 455
		TimeSystem._apply_living_costs()
		assert_eq(home["arrears"], 0)
		assert_eq(home["arrearsWeeks"], 0)
		assert_eq(GameState.state["player"]["cash"], 0)
	)

	run_case("arrears_interest_ignores_the_barometer", func():
		GameState.reset()
		GameState.state["barometer"]["economic"] = "inflation"
		var home: Dictionary = GameState.state["home"]
		home["arrears"] = 400
		home["arrearsWeeks"] = 1
		GameState.state["player"]["cash"] = 0
		TimeSystem._apply_living_costs()
		# interest round(400 × 0.05) = 20 unscaled; only the week's bill scales: round(350 × 1.3) = 455.
		assert_eq(home["arrears"], 400 + 20 + 455)
	)

	run_case("arrears_bedsit_never_downgrades", func():
		GameState.reset()
		var home: Dictionary = GameState.state["home"]
		for i in 4:
			GameState.state["player"]["cash"] = 0
			TimeSystem._apply_living_costs()
		assert_eq(home["tier"], "bedsit")
		assert_eq(home["arrearsWeeks"], 4, "clock keeps running at the floor")
		assert_true(home["arrears"] > 4 * 350, "interest keeps accruing")
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
		home["arrearsWeeks"] = 1
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
		home["arrearsWeeks"] = 1
		GameState.state["player"]["cash"] = 0
		var snapshot: Dictionary = GameState.deep_copy(GameState.state)
		TimeSystem._apply_living_costs()
		assert_eq(GameState.state["home"]["tier"], "studio", "sanity: downgrade happened")
		GameState.state = snapshot
		assert_eq(GameState.state["home"]["tier"], "flat")
		assert_eq(GameState.state["home"]["tenure"], "owned")
		assert_eq(GameState.state["home"]["arrears"], 603)
		assert_eq(GameState.state["home"]["arrearsWeeks"], 1)
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

	# Faction-vein drift happens at step ④ (Cultivating.drift_veins(), the
	# same pass every vein drifts on); step ⑤e only tends/prunes.
	run_case("daily_tick_drifts_a_faction_vein_at_step_4_and_still_reaches_step_5e_without_crashing", func():
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

	run_case("daily_tick_wires_in_faction_passive_income_step", func():
		GameState.reset()
		# No London buying, so the day's only cash movement in is industryIncome.
		var trading: Dictionary = GameData.FACTIONS["collective"]["trading"]
		var saved_buy_mult: float = trading["maxBuyMult"]
		trading["maxBuyMult"] = 0.0
		var before: int = GameState.state["factions"]["collective"]["resources"]
		TimeSystem.daily_tick()
		var after: int = GameState.state["factions"]["collective"]["resources"]
		trading["maxBuyMult"] = saved_buy_mult
		assert_true(after > before, "daily_tick should reach step 5h (Factions.apply_passive_income)")
	)

	run_case("daily_tick_prunes_a_ceiling_faction_vein_into_holdings_at_step_5e", func():
		GameState.reset()
		var site := {
			"id": "s1", "district": "shoreditch", "tier": "fair", "oreType": "fate",
			"bonuses": [], "discoveredDay": 1, "claimed": false,
			"factionVein": { "id": "fv1", "factionId": "collective", "oreType": "fate", "growth": 100, "rampantDays": 0, "security": "none", "claimedOnDay": 1, "siteId": "s1", "level": 3, "hospitability": { "tier": "fair", "bonuses": [] } },
			"hasNaturalVein": false,
		}
		GameState.state["world"]["sites"] = [site]
		GameState.state["world"]["day"] = 5
		var fate_before: int = FactionSim.ore_held("collective", "fate")
		GameState.state["factions"]["collective"]["resources"] = 0  # nothing affordable at step 5j
		# Rivalry (step 5c) runs before the prune; a warm Collective relation
		# drives every rival's odds to 0 so the vein stays the Collective's.
		for attacker_id in GameData.FACTIONS:
			if attacker_id != "collective":
				GameState.state["factionRelations"]["collective"][attacker_id] = 1000
		TimeSystem.daily_tick()
		assert_true(FactionSim.ore_held("collective", "fate") > fate_before, "step 5e prunes the ceiling vein into collective's holdings")
		assert_true(site["factionVein"]["growth"] < 100, "the prune cut the vein's growth")
	)

	run_case("daily_tick_wires_in_faction_security_upgrade_step", func():
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
		assert_eq(site["factionVein"]["security"], "basic", "daily_tick should reach step 5j (Factions.apply_security_upgrades) and upgrade the affordable eligible vein")
	)

	run_case("daily_tick_wires_in_rivalry_resolution_step_right_after_npc_claims", func():
		GameData.FACTION_RIVALRY = true
		# A rich, unsecured collective-owned vein facing a well-resourced Firm
		# (raiding industry, good odds) -- run many seeds and confirm daily_tick
		# eventually reaches step 5c and flips ownership.
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
		assert_true(hit, "daily_tick should reach step 5c (Factions.apply_rivalry_resolution) within 500 tries")
		GameData.FACTION_RIVALRY = false
	)

	run_case("daily_tick_wires_in_direction_b_raid_resolution_step_right_after_rivalry_resolution_step", func():
		# A hated, unsecured, rough-district player vein facing a faction it's
		# burned relation with -- run many seeds and confirm daily_tick
		# eventually reaches step 5d and flips the vein to that faction.
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
		assert_true(hit, "daily_tick should reach step 5d (Raiding.apply_raid_resolution) within 500 tries")
	)

	run_case("daily_tick_wires_in_hakim_intel_step_after_security_upgrades", func():
		# collective1-17: unlocked, well past the 3-day gap, both districts
		# nowhere near siteCap -- run many seeds and confirm daily_tick
		# eventually reaches step 5k and queues Hakim's text.
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
		assert_true(hit, "daily_tick should reach step 5k (Collective.maybe_trigger_hakim_intel) within 200 tries")
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


# Archie staffs the Vein Station with count veins all at 95 against target
# 70, so every block has a vein to prune.
func _staff_overgrown_veins(count: int) -> Array:
	GameState.state["contacts"]["archie"]["recruited"] = true
	Contacts.assign_to_room("archie", "veinStation")
	var veins: Array = []
	for i in count:
		var vein_id := "sv%d" % i
		veins.append(Fixtures.player_vein_with({ "id": vein_id, "growth": 95, "rampantDays": 0 }))
		GameState.state["veinStationTargets"][vein_id] = 70
	GameState.state["player"]["veins"] = veins
	GameState.state["cultivatorVeins"] = { "archie": veins.map(func(v): return v["id"]) }
	return veins

extends "res://tests/test_base.gd"


func run() -> void:
	run_case("blocks_needed_zero_for_current_district", func():
		GameState.reset()
		assert_eq(Travel.blocks_needed("shoreditch"), 0, "no surcharge for the district you're already in")
	)

	run_case("blocks_needed_zero_for_a_different_district", func():
		GameState.reset()
		assert_eq(Travel.blocks_needed("camden"), 0, "D3: travel is free — no surcharge for a different district either")
	)

	run_case("ensure_district_same_district_spends_no_block", func():
		GameState.reset()
		var result := Travel.ensure_district("shoreditch")
		assert_true(result["ok"], "should succeed")
		assert_true(not result["travelled"], "not travelled — already there")
		assert_eq(GameState.state["world"]["timeBlocksDone"], [], "ensure_district itself spends no block")
	)

	run_case("ensure_district_cross_district_updates_currentDistrict_and_spends_no_extra_block", func():
		GameState.reset()
		var result := Travel.ensure_district("camden")
		assert_true(result["ok"], "should succeed")
		assert_true(result["travelled"], "travelled — currentDistrict changed")
		assert_eq(GameState.state["world"]["timeBlocksDone"], [], "no block spent by ensure_district — only the caller's own action block")
		assert_eq(GameState.state["world"]["currentDistrict"], "camden", "currentDistrict updates as a side effect")
	)

	run_case("ensure_district_cross_district_succeeds_with_only_1_block_remaining", func():
		GameState.reset()
		GameState.state["world"]["timeBlocksDone"] = [0, 1]  # 1 block remaining
		var result := Travel.ensure_district("camden")
		assert_true(result["ok"], "no travel surcharge — the action's own 1 block is all that's needed")
		assert_eq(GameState.state["world"]["currentDistrict"], "camden", "currentDistrict updates")
	)

	run_case("ensure_district_cross_district_blocked_when_time_exhausted", func():
		GameState.reset()
		GameState.state["world"]["timeBlocksDone"] = [0, 1, 2]
		var result := Travel.ensure_district("camden")
		assert_true(not result["ok"], "no blocks left for the action itself")
		assert_eq(GameState.state["world"]["currentDistrict"], "shoreditch", "currentDistrict unchanged when blocked")
	)

	run_case("ensure_district_same_district_blocked_when_time_exhausted", func():
		GameState.reset()
		GameState.state["world"]["timeBlocksDone"] = [0, 1, 2]
		var result := Travel.ensure_district("shoreditch")
		assert_true(not result["ok"], "no blocks left for the action itself")
	)

	# ── can_afford() ──────────────────────────────────────────────

	run_case("can_afford_true_with_a_full_day_for_a_different_district", func():
		GameState.reset()
		assert_true(Travel.can_afford("camden", 1), "3 blocks available, needs only 1 for the action")
	)

	run_case("can_afford_true_with_only_1_block_left_for_a_different_district", func():
		GameState.reset()
		GameState.state["world"]["timeBlocksDone"] = [0, 1]
		assert_true(Travel.can_afford("camden", 1), "no travel surcharge — 1 block remaining is enough")
	)

	run_case("can_afford_false_with_no_blocks_left", func():
		GameState.reset()
		GameState.state["world"]["timeBlocksDone"] = [0, 1, 2]
		assert_true(not Travel.can_afford("camden", 1), "0 blocks remaining, action needs 1")
	)

	# ── travel_to() ───────────────────────────────────────────────

	run_case("travel_to_a_different_district_is_free", func():
		GameState.reset()
		var result := Travel.travel_to("camden")
		assert_true(result["ok"], "should succeed")
		assert_eq(GameState.state["world"]["currentDistrict"], "camden", "currentDistrict updates")
		assert_eq(GameState.state["world"]["timeBlocksDone"], [], "travel spends no block at all")
	)

	run_case("travel_to_the_current_district_refuses_as_a_no_op", func():
		GameState.reset()
		var result := Travel.travel_to("shoreditch")
		assert_true(not result["ok"], "travelling to where you already are should refuse, not silently succeed")
		assert_eq(GameState.state["world"]["timeBlocksDone"], [], "no block spent")
	)

	run_case("travel_to_succeeds_even_with_no_blocks_remaining", func():
		GameState.reset()
		GameState.state["world"]["timeBlocksDone"] = [0, 1, 2]
		var result := Travel.travel_to("camden")
		assert_true(result["ok"], "travel is free — it doesn't need any of today's blocks")
		assert_eq(GameState.state["world"]["currentDistrict"], "camden", "currentDistrict updates")
	)

	# ── travel_via_wormhole() (calc-effect-wiring-03) ────────────────────

	run_case("travel_via_wormhole_moves_districts_and_consumes_one", func():
		GameState.reset()
		GameState.state["player"]["inventory"]["wormhole"] = 2
		var result := Travel.travel_via_wormhole("camden")
		assert_true(result["ok"], "should succeed with a wormhole in hand")
		assert_eq(GameState.state["world"]["currentDistrict"], "camden", "currentDistrict updates")
		assert_eq(GameState.state["player"]["inventory"]["wormhole"], 1, "one wormhole consumed")
	)

	run_case("travel_via_wormhole_fails_with_none_in_inventory", func():
		GameState.reset()
		GameState.state["player"]["inventory"]["wormhole"] = 0
		var result := Travel.travel_via_wormhole("camden")
		assert_true(not result["ok"], "should fail with no wormhole")
		assert_eq(GameState.state["world"]["currentDistrict"], "shoreditch", "currentDistrict unchanged")
	)

	run_case("travel_via_wormhole_refuses_a_no_op_trip_to_the_current_district", func():
		GameState.reset()
		GameState.state["player"]["inventory"]["wormhole"] = 1
		var result := Travel.travel_via_wormhole("shoreditch")
		assert_true(not result["ok"], "travelling to where you already are should refuse, same as travel_to()")
		assert_eq(GameState.state["player"]["inventory"]["wormhole"], 1, "no wormhole consumed when blocked")
	)

	run_case("travel_via_wormhole_succeeds_even_with_no_blocks_remaining", func():
		GameState.reset()
		GameState.state["player"]["inventory"]["wormhole"] = 1
		GameState.state["world"]["timeBlocksDone"] = [0, 1, 2]
		var result := Travel.travel_via_wormhole("camden")
		assert_true(result["ok"], "wormhole travel is free, same as plain travel")
	)

	# The district-deck-skip and defend-raid-skip assertions below can't spy
	# on DistrictDeck.maybe_trigger()/Raiding.maybe_trigger_defend() directly
	# (both are static funcs, no test-double seam) -- instead each proves the
	# skip by demonstrating the exact same seed/fixture that WOULD trigger
	# via plain travel_to() (test_district_deck.gd's/test_raiding.gd's own
	# patterns) produces no such effect via travel_via_wormhole().

	run_case("travel_via_wormhole_skips_the_district_deck_roll_even_on_a_seed_that_would_otherwise_trigger", func():
		GameState.reset()
		var original_events: Dictionary = GameData.EVENTS
		GameData.EVENTS = GameData.EVENTS.duplicate()
		for event_id in GameData.EVENTS.keys():
			if GameData.EVENTS[event_id].has("deck"):
				GameData.EVENTS.erase(event_id)
		GameData.EVENTS["e_wormhole_trigger"] = {
			"id": "e_wormhole_trigger",
			"cards": [{ "type": "narration", "label": null, "speaker": null, "text": "x" }],
			"on_complete": [],
			"deck": { "district": "any", "weight": 1 },
		}

		var seed := -1
		for candidate in range(200):
			Rng.set_seed(candidate)
			if Rng.chance(DistrictDeck.TRIGGER_CHANCE):
				seed = candidate
				break
		assert_true(seed != -1, "should find a triggering seed within 200 tries")

		GameState.state["player"]["inventory"]["wormhole"] = 1
		Rng.set_seed(seed)
		Travel.travel_via_wormhole("camden")

		assert_eq(GameState.state["event"], null, "a wormhole trip must never draw a district event, even on a seed that would otherwise hit")
		assert_eq(GameState.state["world"]["recentEvents"], [], "nothing should be recorded either")

		GameData.EVENTS = original_events
	)

	run_case("travel_via_wormhole_skips_a_pending_defend_raid_arrival_the_same_district_would_otherwise_trigger", func():
		GameState.reset()
		var vein := {
			"id": "pv_test", "oreType": "time", "level": 2,
			"levelLabel": GameData.VEIN_LEVELS["2"]["label"], "devBar": 0,
			"charged": false, "chargeBlocks": 0, "security": "none", "alarmUpgrades": [],
			"location": "Test St, nowhere", "claimedOnDay": 0, "district": "camden",
			"siteId": "s_player", "hospitability": { "tier": "fair", "bonuses": [] },
		}
		GameState.state["player"]["veins"] = [vein]
		GameState.state["world"]["sites"] = [{
			"id": "s_player", "district": "camden", "tier": "fair", "oreType": "time",
			"bonuses": [], "discoveredDay": 1, "claimed": true, "factionVein": null,
			"hasNaturalVein": false,
		}]
		var outcome := { "attackerId": "firm", "veinId": "pv_test", "siteId": "s_player", "success": true }
		GameState.state["world"]["pendingDefendRaids"] = [outcome]
		GameState.state["player"]["inventory"]["wormhole"] = 1

		var result := Travel.travel_via_wormhole("camden")

		assert_true(result["ok"])
		assert_true(not GameState.state["combat"]["active"], "a wormhole arrival must never trigger the pending defend combat")
		assert_eq(GameState.state["world"]["pendingDefendRaids"], [outcome], "the pending entry should be left queued, not popped")
	)

extends "res://tests/test_base.gd"

const Fixtures := preload("res://tests/support/fixtures.gd")


static func _counts(n1: int, n2: int = 0, n3: int = 0, n4: int = 0, n5: int = 0) -> Array:
	return [n1, n2, n3, n4, n5]


# A "firm" vein on site s1 posting `guards`, with the vein raid event running.
static func _raid(guards: Array) -> Dictionary:
	GameState.reset()
	var vein := Fixtures.seed_faction_vein("fv1", 50, "firm")
	vein["guards"] = guards
	GameState.state["world"]["sites"][0]["id"] = "s1"
	vein["siteId"] = "s1"
	Events.start_event(Raiding.RAID_EVENT_ID, { "site_id": "s1" })
	return vein


static func _koe_all_enemies() -> void:
	var combat: Dictionary = GameState.state["combat"]
	for c in combat["combatants"]:
		if c["side"] == CombatRounds.SIDE_ENEMY:
			c["koed"] = true


func run() -> void:
	run_case("injured_guard_returns_to_the_reserve_after_injury_days", func():
		GameState.reset()
		var day := int(GameState.state["world"]["day"])
		Muscle.faction_injure("firm", 3)
		Muscle.faction_daily_tick()
		assert_eq(Muscle.faction_reserve("firm")[2], 0, "still out")
		GameState.state["world"]["day"] = day + int(GameData.MUSCLE["injuryDays"])
		Muscle.faction_daily_tick()
		assert_eq(Muscle.faction_reserve("firm")[2], 1, "back in the Reserve")
		assert_eq(Muscle.faction_state("firm")["injured"].size(), 0)
	)

	run_case("reinforcement_draw_takes_two_highest_then_none_in_the_same_block", func():
		GameState.reset()
		var reserve := Muscle.faction_reserve("firm")
		reserve.assign(_counts(2, 0, 1, 1, 0))
		assert_eq(Muscle.faction_draw_reinforcements("firm"), [4, 3])
		assert_eq(Muscle.faction_draw_reinforcements("firm"), [], "already answered this block")
		GameState.state["world"]["timeBlock"] = int(GameState.state["world"]["timeBlock"]) + 1
		assert_eq(Muscle.faction_draw_reinforcements("firm"), [4, 3], "next block answers again")
	)

	run_case("reinforcement_draw_from_an_empty_reserve_is_empty", func():
		GameState.reset()
		Muscle.faction_reserve("firm").assign(Muscle.empty_counts())
		assert_eq(Muscle.faction_draw_reinforcements("firm"), [])
	)

	run_case("claiming_a_vein_sends_its_guards_to_the_faction_reserve", func():
		var vein := _raid(_counts(0, 2, 1))
		Muscle.faction_reserve("firm").assign(Muscle.empty_counts())
		Raiding.claim_vein("s1")
		assert_eq(Muscle.faction_reserve("firm"), _counts(0, 2, 1))
		assert_true(not GameState.state["player"]["veins"][0].has("guards"))
		assert_true(vein["id"] == GameState.state["player"]["veins"][0]["id"])
	)

	run_case("raid_enemies_match_the_posted_counts_by_level_and_show_it", func():
		_raid(_counts(0, 2, 1))
		Events._start_raid_combat({ "guards": "vein", "template": "veinGuard" })
		var combat: Dictionary = GameState.state["combat"]
		var levels := []
		for e in combat["enemies"] + combat["enemyQueue"]:
			levels.append(e["level"])
		levels.sort()
		assert_eq(levels, [2, 2, 3])
		var shown := []
		for c in combat["combatants"]:
			if c["side"] == CombatRounds.SIDE_ENEMY:
				shown.append(c["level"])
		shown.sort()
		assert_eq(shown, [2, 2, 3], "combatants carry the guard level")
	)

	run_case("fallen_posted_guards_leave_their_vein_and_return_after_three_days", func():
		var vein := _raid(_counts(0, 2, 1))
		Events._start_raid_combat({ "guards": "vein", "template": "veinGuard" })
		_koe_all_enemies()
		GameState.state["combat"]["outcome"] = "win"
		Combat.exit_combat()
		assert_eq(vein["guards"], Muscle.empty_counts(), "all three guards are out of the posts")
		assert_eq(Muscle.faction_state("firm")["injured"].size(), 3)
		assert_eq(Events._pending_guards_down(), 0, "later fights don't take them off twice")
		var back := int(GameState.state["world"]["day"]) + int(GameData.MUSCLE["injuryDays"])
		GameState.state["world"]["day"] = back
		var before := Muscle.counts_total(Muscle.faction_reserve("firm"))
		Muscle.faction_daily_tick()
		assert_eq(Muscle.counts_total(Muscle.faction_reserve("firm")), before + 3)
	)

	run_case("a_lost_fight_injures_only_the_guards_that_fell", func():
		var vein := _raid(_counts(0, 2))
		Events._start_raid_combat({ "guards": "vein", "template": "veinGuard" })
		var combat: Dictionary = GameState.state["combat"]
		for c in combat["combatants"]:
			if c["side"] == CombatRounds.SIDE_ENEMY and int(c["rid"]) == 0:
				c["koed"] = true
		combat["outcome"] = "lose"
		Combat.exit_combat()
		assert_eq(Muscle.counts_total(vein["guards"]), 1)
		assert_eq(Muscle.faction_state("firm")["injured"].size(), 1)
	)

	run_case("reserve_answers_the_alarm_with_two_highest_and_empty_reserve_sends_no_one", func():
		var vein := _raid(_counts(1))
		GameState.state["event"]["context"]["securityProfile"] = { "alarm": true }
		Muscle.faction_reserve("firm").assign(_counts(1, 0, 1, 1))
		Events._apply_alert({ "atLeast": 2 })
		for _i in range(4):
			Events._tick_reinforcement()
		assert_true(Events.reinforcements_arrived())
		assert_eq(GameState.state["event"]["reinforce"]["levels"], [4, 3])
		Events._start_raid_combat({ "guards": "vein", "template": "veinGuard" })
		var combat: Dictionary = GameState.state["combat"]
		assert_eq(combat["enemies"].size() + combat["enemyQueue"].size(), Muscle.counts_total(vein["guards"]) + 2)
	)

	run_case("empty_reserve_sends_no_one_and_the_arrival_never_plays", func():
		_raid(_counts(1))
		GameState.state["event"]["context"]["securityProfile"] = { "alarm": true }
		Muscle.faction_reserve("firm").assign(Muscle.empty_counts())
		Events._apply_alert({ "atLeast": 2 })
		for _i in range(8):
			Events._tick_reinforcement()
		assert_true(not Events.reinforcements_arrived())
		assert_true(Events.condition_met({ "reinforcements": "none" }), "the variant card's condition")
		assert_true(not Events.reinforcements_pending())
	)

	run_case("rivalry_failure_injures_an_attacker_reserve_guard_and_success_a_vein_guard", func():
		GameState.reset()
		var vein := Fixtures.seed_faction_vein("fv1", 50, "firm")
		vein["guards"] = _counts(1, 1)
		Muscle.faction_reserve("collective").assign(_counts(0, 1))
		var outcome := { "attackerId": "collective", "defenderId": "firm", "veinSiteId": "site_fv1" }
		outcome["success"] = false
		Factions._injure_rivalry_loser(outcome)
		assert_eq(Muscle.faction_reserve("collective"), Muscle.empty_counts())
		assert_eq(Muscle.faction_state("collective")["injured"].size(), 1)
		outcome["success"] = true
		Factions._injure_rivalry_loser(outcome)
		assert_eq(vein["guards"], _counts(0, 1), "lowest guard of the raided vein")
		assert_eq(Muscle.faction_state("firm")["injured"].size(), 1)
	)

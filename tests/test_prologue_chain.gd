extends "res://tests/test_base.gd"

const EventPlay := preload("res://tests/support/event_play.gd")

# The Prologue chain (docs/story-restructure.md "Prologue"): a new game plays
# its nine beats in order, one undone ToDo objective at a time, and the rent
# goal row stays on from the cold open until the ending.


func _play(event_id: String) -> void:
	Events.start_event(event_id)
	for step in range(200):
		if GameState.state["event"] == null:
			break
		if GameState.state["combat"]["active"]:
			_finish_practice_fight()
			continue
		if Events.is_awaiting_choice():
			Events.choose(maxi(Events.hub_exit_index(), 0))
			if LessonSession.is_open():
				Lab.add_ore("timePearl", "time")
				Lab.perform_step("compression", 70.0)
				Lab.perform_step("heat", 25.0)
				Lab.finish_run()
				LessonSession.resume()
		Events.advance()


func _finish_practice_fight() -> void:
	var combat: Dictionary = GameState.state["combat"]
	if CombatRounds.is_demo(combat):
		for i in range(int(combat["demo"]["rounds"])):
			Combat.demo_step()
	else:
		combat["coach"] = null
		combat["combatants"][1]["hp"] = 1
		Combat.choose_move("strike", 1)
	Combat.exit_combat()


func _current_id() -> String:
	return String(Todo.current_objective().get("id", ""))


func _undone_count() -> int:
	for section in Todo.get_questline_sections():
		if section["questline"] == "tutorial":
			return section["items"].filter(func(item): return not item["done"]).size()
	return 0


func _has_pending(kind: String) -> bool:
	return GameState.state["pendingMessages"].any(func(entry): return entry["kind"] == kind)


func _check_beat(objective_id: String, label: String) -> void:
	assert_eq(_current_id(), objective_id, "%s: current objective" % label)
	assert_eq(_undone_count(), 1, "%s: exactly one undone Prologue objective" % label)


func run() -> void:
	run_case("pub_questions_hub_answers_in_any_order_and_exits_to_the_buyer_stage", func():
		GameState.reset()
		Events.start_event("pub")
		assert_true(Events.is_awaiting_choice(), "pub opens on the question hub")
		assert_true(Events.hub_exit_available(), "advance anytime: the exit is open before any question")
		EventPlay.choose_id("whereFrom")
		Events.advance()
		assert_true(GameState.state["flags"]["introAskedSource"], "asking where it comes from sets introAskedSource")
		assert_true(Events.is_awaiting_choice(), "the answer returns to the hub")
		Events.choose(Events.hub_exit_index())
		for step in range(20):
			if GameState.state["event"] == null:
				break
			Events.advance()
		assert_true(GameState.state["flags"]["metArchie"], "pub completes")
		assert_eq(GameState.state["flags"]["tutorialStage"], "buyer_event", "stage moves to buyer_event")
	)

	run_case("new_game_plays_all_nine_beats_in_order", func():
		GameState.reset()
		_check_beat("pro_cold_open", "new game")

		# 1-2. Cold open chains into the pub.
		_play("cold_open")
		assert_true(GameState.state["flags"]["rentGoal"], "rent goal row on from the cold open")
		assert_true(GameState.state["flags"]["metArchie"], "pub done")
		_check_beat("pro_first_sale", "after the pub")

		# 3. First sale: Archie's text arrives on day 2.
		TimeSystem.do_rest()
		assert_true(_has_pending("buyer"), "day 2: Archie's buyer text")
		_play("buyer")
		assert_true(GameState.state["flags"]["buyerEventSeen"], "buyer done")
		_check_beat("pro_first_craft", "after the first sale")

		# 4. First craft.
		assert_true(_has_pending("james_meeting"), "buyer queues james_meeting")
		_play("james_meeting")
		assert_true(Lab.is_known("timePearl"), "james_meeting grants timePearl")
		_check_beat("pro_gym", "after the first craft")

		# 5. Gym.
		assert_true(_has_pending("gym"), "james_meeting queues the gym")
		_play("gym")
		assert_true(GameState.state["flags"]["gymUnlocked"], "gym done")
		_check_beat("pro_pearls_sold", "after the gym")

		# 6. Archie sells your pearls.
		assert_true(_has_pending("archie_sells_pearls"), "gym queues archie_sells_pearls")
		_play("archie_sells_pearls")
		assert_true(GameState.state["flags"]["homeRaidEventPending"], "the raid is pending")
		_check_beat("pro_flat_raid", "after the pearl sale")

		# 7. Flat raid, won.
		_play("home_raid_debrief_win")
		assert_true(GameState.state["flags"]["homeRaidEventSeen"], "raid done")
		assert_eq(GameState.state["flags"]["depositGoalTier"], "studio", "the raid debrief sets the deposit goal")
		assert_eq(GameState.state["player"]["veins"].size(), 1, "the raid debrief hands over the first vein")
		_check_beat("pro_first_vein", "after the flat raid")

		# 8. First vein.
		_play("archie_cultivation")
		assert_true(GameState.state["flags"]["cultivationTutorialSeen"], "vein lesson done")
		assert_true(GameState.state["flags"]["rentGoal"], "rent goal row still on")
		_check_beat("pro_pay_rent", "after the first vein")

		# 9. Pay rent, then the ending.
		GameState.state["flags"]["rentPaid"] = true
		TimeSystem.daily_tick()
		assert_true(_has_pending("prologue_ending"), "rent paid queues the ending")
		_play("prologue_ending")
		assert_true(not GameState.state["flags"]["rentGoal"], "rent goal row off after the ending")
		assert_true(GameState.state["flags"]["prologueDone"], "prologue done")
		assert_eq(GameState.state["flags"]["tutorialStage"], "free", "tutorial stage released")
		assert_true(_has_pending("col_a1_intro"), "the ending hands off to Des")
		var headlines: Array = GameState.state["barometer"].get("headlines", [])
		assert_true(headlines.any(func(entry): return entry.get("source", "") == "prologueSqueeze"), "the ending posts the Ticker article")
		var story_rises: Array = GameState.state["market"].get("storyRises", [])
		assert_eq(story_rises.size(), 1, "the ending starts the emotion demand rise")
		assert_eq(story_rises[0]["ore"], "emotion", "the rise is on emotion calc")
		assert_true(GameState.state["flags"]["prologueNudgePending"], "the other-arc nudge waits for the next day")
		TimeSystem.daily_tick()
		assert_true(not GameState.state["flags"]["prologueNudgePending"], "the nudge fires on the next tick")
		assert_true(Messages.latest_preview("archie").begins_with("Deposit"), "Archie nudges toward Harrow's and the deposit")
		assert_eq(_current_id(), "", "no Prologue objective left pending")
	)

	run_case("home_raid_cant_be_won_without_the_pearl", func():
		GameState.reset()
		Events.apply_effects([{ "op": "add_item", "item": "timePearl", "qty": 2, "equip": true }])
		Events.start_event("home_raid_intro")
		for i in range(GameData.EVENTS["home_raid_intro"]["cards"].size()):
			Events.advance()
		assert_true(CombatPrep.commit()["ok"], "the raid starts")
		var combat: Dictionary = GameState.state["combat"]
		var lock: Dictionary = combat["pearlLock"]
		var you: Dictionary = combat["combatants"][CombatRounds.PLAYER_INDEX]
		you["hp"] = 999
		you["hpMax"] = 999

		var refusal := {}
		for i in range(60):
			var result := Combat.choose_move("strike", 1)
			if not result["ok"]:
				refusal = result
				break
		assert_eq(combat["outcome"], null, "strikes alone never win")
		assert_true(CombatRounds.pearl_locked(combat), "the fight locks on the pearl")
		assert_eq(refusal.get("reason", ""), lock["prompt"], "a strike is refused with the pearl prompt")
		assert_eq(CombatRounds.lock_prompt(combat), lock["prompt"], "the prompt line tells you to use the pearl")
		assert_true(int(combat["combatants"][1]["hp"]) >= 1, "the raider is still up")

		assert_true(Combat.choose_item(Loadout.find_slot("timePearl"))["ok"], "the pearl plays at the lock")
		assert_true(not CombatRounds.pearl_locked(combat), "the lock lifts once the pearl is thrown")
		var after_pearl: int = combat["log"].size()
		var strikes := 0
		while combat["outcome"] == null and strikes < 4:
			Combat.choose_move("strike", 1)
			strikes += 1
		assert_eq(combat["outcome"], "win", "the pearl, then a few strikes, wins")
		var hits: Array = combat["log"].slice(after_pearl).filter(func(b): return b["actor"] == CombatRounds.PLAYER_INDEX and b["kind"] in ["hit", "chip"])
		assert_true(not hits.is_empty() and hits.all(func(b): return b["crit"]), "every hit after the pearl crits")
	)

	run_case("home_raid_timeline_keeps_the_raider_first_before_and_after_picks", func():
		GameState.reset()
		Events.apply_effects([{ "op": "add_item", "item": "timePearl", "qty": 2, "equip": true }])
		Events.start_event("home_raid_intro")
		for i in range(GameData.EVENTS["home_raid_intro"]["cards"].size()):
			Events.advance()
		assert_true(CombatPrep.commit()["ok"], "the raid starts")
		var combat: Dictionary = GameState.state["combat"]
		combat["combatants"][CombatRounds.PLAYER_INDEX]["hp"] = 999
		combat["combatants"][CombatRounds.PLAYER_INDEX]["hpMax"] = 999
		var unpicked: Array = CombatRounds.timeline(combat)
		assert_eq(unpicked[0]["actor"], 1, "the raider leads before any pick")
		var next_actors: Array = CombatRounds.next_round_timeline(combat).map(func(e): return e["actor"])
		assert_eq(next_actors.slice(0, 2), [1, 0], "next round's raider card also leads")
		assert_true(Combat.choose_move("strike", 1)["ok"])
		var picked: Array = CombatRounds.timeline(combat)
		assert_eq(picked.map(func(e): return [e["index"], e["actor"]]), unpicked.map(func(e): return [e["index"], e["actor"]]), "a pick doesn't reorder the strip")
	)

	run_case("home_raid_raider_counters_every_pick", func():
		GameState.reset()
		Events.apply_effects([{ "op": "add_item", "item": "timePearl", "qty": 2, "equip": true }])
		Events.start_event("home_raid_intro")
		for i in range(GameData.EVENTS["home_raid_intro"]["cards"].size()):
			Events.advance()
		assert_true(CombatPrep.commit()["ok"], "the raid starts")
		var combat: Dictionary = GameState.state["combat"]
		combat["combatants"][CombatRounds.PLAYER_INDEX]["hp"] = 999
		combat["combatants"][CombatRounds.PLAYER_INDEX]["hpMax"] = 999
		var raider: int = CombatRounds.side_indices(combat, CombatRounds.SIDE_ENEMY)[0]
		var picks := [["strike", "guard"], ["stun", "guard"], ["guard", "feint"], ["guard", "strike"], ["feint", "guard"], ["guard", "feint"]]
		for pick in picks:
			var from: int = combat["log"].size()
			assert_true(Combat.choose_move(pick[0], raider if pick[0] != "guard" else -1)["ok"], "%s plays" % pick[0])
			var beats: Array = combat["log"].slice(from)
			var raider_beats := beats.filter(func(b): return b["actor"] == raider)
			assert_eq(raider_beats[0]["move"], pick[1], "%s is answered with %s" % [pick[0], pick[1]])
			assert_true(beats.find(raider_beats[0]) < beats.find(beats.filter(func(b): return b["actor"] == CombatRounds.PLAYER_INDEX)[0]), "the answer lands ahead of the %s" % pick[0])
		assert_eq(CombatRounds.enemy_intents(combat, raider).filter(func(i): return not i.get("unread", false)).size(), 0, "the raider's plan stays unread")

		var cycle := ["strike", "feint", "guard", "stun", "guard", "strike"]
		for i in range(80):
			var move_id: String = cycle[i % cycle.size()]
			if not Combat.choose_move(move_id, raider if move_id != "guard" else -1)["ok"]:
				break
		assert_eq(combat["outcome"], null, "no plan without the pearl wins")
		assert_true(CombatRounds.pearl_locked(combat), "the lock still steers to the pearl")
		assert_eq(int(combat["combatants"][raider]["hpMax"]), int(GameData.ENEMY_HOME_RAID_RAIDER["hp"]), "raider stats unchanged")
	)

	run_case("later_home_raids_have_no_pearl_lock", func():
		GameState.reset()
		Events.apply_effects([{ "op": "add_item", "item": "timePearl", "qty": 2, "equip": true }])
		Combat.start_home_alarm_defend_combat()
		assert_eq(GameState.state["combat"]["pearlLock"], null, "an alarm defence keeps normal rules")
	)

	run_case("ending_waits_for_the_goal_the_vein_lesson_and_rent", func():
		GameState.reset()
		var flags: Dictionary = GameState.state["flags"]
		flags["rentPaid"] = true
		TimeSystem.daily_tick()
		assert_true(not flags["prologueEndingQueued"], "no rent goal (legacy save): no ending")
		flags["rentGoal"] = true
		TimeSystem.daily_tick()
		assert_true(not flags["prologueEndingQueued"], "vein lesson not done: no ending")
		flags["cultivationTutorialSeen"] = true
		TimeSystem.daily_tick()
		assert_true(flags["prologueEndingQueued"], "all three: ending queued")
		var queued: int = GameState.state["pendingMessages"].filter(func(entry): return entry["kind"] == "prologue_ending").size()
		TimeSystem.daily_tick()
		assert_eq(GameState.state["pendingMessages"].filter(func(entry): return entry["kind"] == "prologue_ending").size(), queued, "queued once")
	)

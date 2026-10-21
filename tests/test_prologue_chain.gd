extends "res://tests/test_base.gd"

# The Prologue chain (docs/story-restructure.md "Prologue"): a new game plays
# its nine beats in order, one undone ToDo objective at a time, and the rent
# goal row stays on from the cold open until the ending.


func _play(event_id: String) -> void:
	Events.start_event(event_id)
	for step in range(200):
		if GameState.state["event"] == null:
			break
		if Events.is_awaiting_choice():
			Events.choose(0)
		Events.advance()


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
		assert_eq(_current_id(), "", "no Prologue objective left pending")
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

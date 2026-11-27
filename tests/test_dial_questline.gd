extends "res://tests/test_base.gd"

# The "dial" ToDo questline (R§3.9c): James's Dial chain shown one goal at a
# time, driven through the real summons, events and seeding.

const LENS_ORE := "fate"


func _fresh() -> void:
	GameState.reset()
	GameState.state["contacts"]["james"]["unlocked"] = true
	GameState.state["flags"]["jamesExperimentSeen"] = true
	GameState.state["player"]["craftingSkill"] = int(GameData.DIAL_JAMES_QUEST["minCraftingSkill"])


# Plays the pending summons of `kind` to its end, taking each choice card's
# exit choice (else its last). Capped.
func _play_pending(kind: String) -> bool:
	var entries: Array = GameState.state["pendingMessages"].filter(func(e: Dictionary) -> bool: return e["kind"] == kind)
	if entries.size() != 1:
		return _walk_fail("expected one %s summons, found %d" % [kind, entries.size()], "")
	Messages.resolve_pending(entries[0]["id"])
	Events.start_event(kind, entries[0]["payload"])
	for _i in 200:
		if GameState.state["event"] == null:
			return true
		if Events.is_awaiting_choice():
			var choices: Array = Events.current_card().get("choices", [])
			var pick := choices.size() - 1
			for i in choices.size():
				if choices[i].get("exit", false):
					pick = i
			Events.choose(pick)
		else:
			Events.advance()
	return _walk_fail("%s did not end" % kind, Events.current_card_key())


func _page() -> Dictionary:
	for page in Todo.get_pages():
		if page["id"] == "dial":
			return page
	return {}


func _ids(items: Array) -> Array:
	return items.map(func(item: Dictionary) -> String: return item["id"])


# Asserts the page's one open goal and the done goals behind it.
func _assert_goals(open_id: String, done_ids: Array, msg: String) -> void:
	var page := _page()
	assert_true(not page.is_empty(), "%s: Dial page listed" % msg)
	if page.is_empty():
		return
	assert_eq(_ids(page["active"]), [open_id], "%s: open goal" % msg)
	assert_eq(_ids(page["done"]), done_ids, "%s: done goals" % msg)
	assert_eq(page["status"], "active", "%s: status" % msg)


func _gather_detail() -> String:
	for item in _page().get("active", []) + _page().get("done", []):
		if item["id"] == "dial_gather_calc":
			return item["detail"]
	return ""


func _hold_time(qty: int) -> void:
	GameState.state["player"]["orichalchum"]["time"] = qty
	GameState.state["player"]["stash"]["orichalchum"]["time"] = 0


# Real chain up to the end of the offer: seeding unlocked, lesson not yet sent.
func _play_through_offer() -> void:
	_fresh()
	JamesDial.daily_tick()
	assert_true(_play_pending(JamesDial.EVALUATION), "evaluation ends")
	_hold_time(int(GameState.state["flags"]["jamesDialCalcQty"]))
	JamesDial.daily_tick()
	assert_true(_play_pending(JamesDial.REPAIR), "repair ends")
	JamesDial.daily_tick()
	assert_true(_play_pending(JamesDial.OFFER), "offer ends")


func _play_lesson() -> void:
	JamesDial.daily_tick()
	assert_true(_play_pending(JamesDial.PLAYER_DIAL), "lesson ends")


# Seeds until the roll comes out as `want`, restoring state between tries.
func _seed_until(want: bool) -> bool:
	var player: Dictionary = GameState.state["player"]
	for ore in GameData.DIAL_SEED_COST:
		player["orichalchum"][ore] = GameData.DIAL_SEED_COST[ore]
	var snapshot: Dictionary = GameState.deep_copy(GameState.state)
	for seed_value in 2000:
		Rng.set_seed(seed_value)
		var result := Dial.attempt_seed(LENS_ORE)
		if result.get("success", not want) == want:
			return true
		GameState.state = GameState.deep_copy(snapshot)
	return false


# A save carrying `flags` but no Dial objective runtime, reloaded.
func _reload_with(flags: Array, seeded: bool) -> void:
	GameState.reset()
	for flag in flags:
		GameState.state["flags"][flag] = true
	GameState.state["flags"]["jamesDialCalcQty"] = 38
	if seeded:
		GameState.state["player"]["dial"] = Dial.new_dial()
	GameState.state["flags"].erase("playerDialSeeded")
	for id in GameData.OBJECTIVES:
		if GameData.OBJECTIVES[id]["questline"] == "dial":
			GameState.state["objectives"].erase(id)
	var day: int = GameState.state["world"]["day"]
	var exported := SaveManager.export_string()
	GameState.reset()
	assert_true(SaveManager.import_string(exported)["ok"], "imports")
	assert_eq(GameState.state["world"]["day"], day, "no day advanced")


# The Story row with every other questline's goals ticked off.
func _story_row() -> Dictionary:
	for id in GameState.state["objectives"]:
		if GameData.OBJECTIVES[id]["questline"] != "dial":
			GameState.state["objectives"][id]["complete"] = true
	var rows := DailyBrief.items().filter(func(r: Dictionary) -> bool: return r["kind"] == "story")
	return {} if rows.is_empty() else rows[0]


func _assert_story(id: String, action: Dictionary, label: String) -> void:
	var row := _story_row()
	assert_eq([row.get("key"), row.get("action"), row.get("actionLabel")], ["story:%s" % id, action, label], "%s story row" % id)


func run() -> void:
	run_case("no_dial_page_until_jamess_first_dial_text", func():
		_fresh()
		GameState.state["player"]["craftingSkill"] -= 1
		JamesDial.daily_tick()
		Objectives.refresh()
		assert_eq(_page(), {}, "hidden before the text")
		GameState.state["player"]["craftingSkill"] += 1
		JamesDial.daily_tick()
		_assert_goals("dial_bench_job", [], "first text")
		assert_true(_page()["pip"], "new page is pipped")
	)

	run_case("goals_appear_one_at_a_time_and_tick_off_through_the_chain", func():
		_fresh()
		JamesDial.daily_tick()
		assert_true(_play_pending(JamesDial.EVALUATION), "evaluation ends")
		_assert_goals("dial_gather_calc", ["dial_bench_job"], "bench job done")
		var quoted := int(GameState.state["flags"]["jamesDialCalcQty"])

		_hold_time(3)
		assert_eq(_gather_detail(), "3 of %d" % quoted, "live count")
		GameState.state["player"]["stash"]["orichalchum"]["time"] = 2
		assert_eq(_gather_detail(), "5 of %d" % quoted, "stash counts")
		_hold_time(quoted + 4)
		Objectives.refresh()
		assert_eq(_gather_detail(), "%d of %d" % [quoted, quoted], "capped at the quote")
		_assert_goals("dial_gather_calc", ["dial_bench_job"], "holding the quote is not enough")
		_hold_time(0)
		Objectives.refresh()
		assert_eq(_gather_detail(), "0 of %d" % quoted, "spent calc leaves no tick")

		_hold_time(quoted)
		JamesDial.daily_tick()
		_assert_goals("dial_bring_calc", ["dial_bench_job", "dial_gather_calc"], "bring-it text queued")

		assert_true(_play_pending(JamesDial.REPAIR), "repair ends")
		assert_eq(_gather_detail(), "%d of %d" % [quoted, quoted], "a done count stays full once the calc is gone")
		_assert_goals("dial_offer", ["dial_bench_job", "dial_gather_calc", "dial_bring_calc"], "calc brought")

		JamesDial.daily_tick()
		assert_true(_play_pending(JamesDial.OFFER), "offer ends")
		_assert_goals("dial_lesson", ["dial_bench_job", "dial_gather_calc", "dial_bring_calc", "dial_offer"], "offer seen")

		_play_lesson()
		_assert_goals("dial_seed", ["dial_bench_job", "dial_gather_calc", "dial_bring_calc", "dial_offer", "dial_lesson"], "lesson seen")
	)

	run_case("failed_seed_leaves_the_goal_open_and_success_finishes_the_page", func():
		_play_through_offer()
		_play_lesson()
		assert_true(_seed_until(false), "found a failing seed")
		assert_eq(_ids(_page()["active"]), ["dial_seed"], "failure leaves it open")
		assert_true(_seed_until(true), "found a successful seed")
		var page := _page()
		assert_eq(page["status"], "done", "page finished")
		assert_eq(page["active"], [], "nothing open")
		assert_eq(page["done"].size(), 6, "all six ticked")
	)

	run_case("seeding_before_the_lesson_finishes_the_page_after_the_lesson", func():
		_play_through_offer()
		assert_true(_seed_until(true), "seeded at the offer")
		_assert_goals("dial_lesson", ["dial_bench_job", "dial_gather_calc", "dial_bring_calc", "dial_offer"], "lesson still open")
		_play_lesson()
		assert_eq(_page()["status"], "done", "page finished")
		assert_eq(_page()["done"].size(), 6, "all six ticked")
	)

	run_case("a_block_rewind_keeps_the_seeded_dial_and_the_finished_page", func():
		_play_through_offer()
		_play_lesson()
		Crafting.inventory_add("rewind", 1, 1)
		Rewind.mark_block_start()
		assert_true(_seed_until(true), "seeded")
		assert_true(Rewind.rewind_to_block_start()["ok"], "rewound")
		assert_true(GameState.state["player"]["dial"] != null, "Dial kept")
		assert_eq(_page()["status"], "done", "page still finished")
	)

	run_case("a_done_count_with_no_quote_shows_no_numbers", func():
		_reload_with(["jamesDialEvaluationQueued", "jamesDialRepairRequested", "jamesDialRepairQueued"], false)
		GameState.state["flags"]["jamesDialCalcQty"] = 0
		assert_eq(_gather_detail(), "", "no 0 of 0")
	)

	run_case("a_loaded_save_shows_the_right_goals_without_a_day_passing", func():
		var chain := ["jamesDialEvaluationQueued", "jamesDialRepairRequested", "jamesDialRepairQueued", "jamesDialRestored", "jamesDialOfferSeen", "jamesPlayerDialSeen"]
		var goals := ["dial_bench_job", "dial_gather_calc", "dial_bring_calc", "dial_offer", "dial_lesson", "dial_seed"]
		_reload_with([], false)
		assert_eq(_page(), {}, "chain not started")
		for i in chain.size():
			_reload_with(chain.slice(0, i + 1), false)
			_assert_goals(goals[i], goals.slice(0, i), chain[i])
		_reload_with(chain.slice(0, 5), true)
		_assert_goals("dial_lesson", goals.slice(0, 4), "seeded before the lesson")
		_reload_with(chain, true)
		assert_eq(_page().get("status"), "done", "seeded after the lesson")
		assert_eq(_page().get("done", []).size(), 6)
	)

	run_case("story_row_follows_the_current_dial_goal_to_the_right_place", func():
		var james := { "to": "thread", "contactId": "james" }
		_fresh()
		JamesDial.daily_tick()
		_assert_story("dial_bench_job", james, "Read message")
		assert_true(_play_pending(JamesDial.EVALUATION), "evaluation ends")
		_assert_story("dial_gather_calc", { "to": "map" }, "Open map")
		_hold_time(int(GameState.state["flags"]["jamesDialCalcQty"]))
		JamesDial.daily_tick()
		_assert_story("dial_bring_calc", james, "Read message")
		assert_true(_play_pending(JamesDial.REPAIR), "repair ends")
		_assert_story("dial_offer", james, "Read message")
		JamesDial.daily_tick()
		assert_true(_play_pending(JamesDial.OFFER), "offer ends")
		_assert_story("dial_lesson", james, "Read message")
		_play_lesson()
		_assert_story("dial_seed", { "to": "dial" }, "Open Dial bench")
		BizBriefApp.new()._open_today_action({ "to": "dial" })
		assert_eq(GameState.state["currentScreen"], "hq_dial", "action opens the Dial bench")
	)

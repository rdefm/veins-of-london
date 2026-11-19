extends "res://tests/test_base.gd"

# James's Dial chain (systems/james_dial.gd): evaluation -> repair -> offer ->
# player Dial creation, each a once-only James summons whose gate is met.


func _fresh() -> void:
	GameState.reset()
	GameState.state["contacts"]["james"]["unlocked"] = true


func _pending(kind: String) -> Array:
	return GameState.state["pendingMessages"].filter(func(e: Dictionary) -> bool: return e["kind"] == kind)


# Plays the pending summons of `kind` to its end, taking each choice card's
# exit choice (else its last, the hubs' forward exit). Capped.
func _play_pending(kind: String) -> bool:
	var entries := _pending(kind)
	assert_eq(entries.size(), 1, "one %s summons" % kind)
	if entries.is_empty():
		return false
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


func _evaluation_ready() -> void:
	GameState.state["flags"]["jamesExperimentSeen"] = true
	GameState.state["player"]["craftingSkill"] = int(GameData.DIAL_JAMES_QUEST["minCraftingSkill"])


func run() -> void:
	run_case("evaluation_waits_for_james_experiment_and_crafting_skill", func():
		_fresh()
		GameState.state["player"]["craftingSkill"] = int(GameData.DIAL_JAMES_QUEST["minCraftingSkill"])
		JamesDial.daily_tick()
		assert_eq(_pending(JamesDial.EVALUATION).size(), 0, "no summons before james_experiment")
		GameState.state["flags"]["jamesExperimentSeen"] = true
		GameState.state["player"]["craftingSkill"] -= 1
		JamesDial.daily_tick()
		assert_eq(_pending(JamesDial.EVALUATION).size(), 0, "no summons below the crafting gate")
	)

	run_case("evaluation_quotes_two_recharge_attempts_once", func():
		_fresh()
		_evaluation_ready()
		JamesDial.daily_tick()
		JamesDial.daily_tick()
		var entries := _pending(JamesDial.EVALUATION)
		assert_eq(entries.size(), 1, "queued once")
		var attempt := Dial.movement_calc_cost("recharge", int(GameState.state["player"]["craftingSkill"]))
		assert_eq(entries[0]["payload"], { "attemptCost": attempt, "calcQty": attempt * 2 })
		assert_eq(GameState.state["flags"]["jamesDialCalcQty"], attempt * 2, "quote kept for the repair")
	)

	run_case("evaluation_completes_with_the_quote_text_and_repair_request", func():
		_fresh()
		_evaluation_ready()
		JamesDial.daily_tick()
		var cash := int(GameState.state["player"]["cash"])
		assert_true(_play_pending(JamesDial.EVALUATION), "evaluation ends")
		assert_true(GameState.state["flags"]["jamesDialRepairRequested"], "repair requested")
		assert_eq(int(GameState.state["player"]["cash"]), cash + 300, "paid")
		var qty := int(GameState.state["flags"]["jamesDialCalcQty"])
		assert_true(Messages.latest_preview("james").begins_with("%d time calc." % qty), "quote text filled")
	)

	run_case("repair_waits_for_the_quoted_calc_and_carries_todays_pay", func():
		_fresh()
		var flags: Dictionary = GameState.state["flags"]
		flags["jamesDialRepairRequested"] = true
		flags["jamesDialCalcQty"] = 38
		flags["jamesDialAttemptCost"] = 19
		GameState.state["player"]["orichalchum"]["time"] = 37
		JamesDial.daily_tick()
		assert_eq(_pending(JamesDial.REPAIR).size(), 0, "not without the full quote")
		GameState.state["player"]["orichalchum"]["time"] = 40
		JamesDial.daily_tick()
		var entries := _pending(JamesDial.REPAIR)
		assert_eq(entries.size(), 1, "queued")
		var pay := Market.line_total("ore", Market.quote("ore", "time"), 38)
		assert_eq(entries[0]["payload"], { "calcQty": 38, "attemptCost": 19, "calcPay": pay })
		var cash := int(GameState.state["player"]["cash"])
		assert_true(_play_pending(JamesDial.REPAIR), "repair ends")
		assert_eq(int(GameState.state["player"]["cash"]), cash + pay, "paid what the card said")
		assert_eq(Stash.player_ore_qty("time"), 2, "quoted calc taken")
		assert_true(flags["jamesDialRestored"], "restored")
	)

	run_case("offer_then_player_dial_creation_follow_on_later_mornings", func():
		_fresh()
		var flags: Dictionary = GameState.state["flags"]
		flags["jamesDialRestored"] = true
		JamesDial.daily_tick()
		assert_eq(_pending(JamesDial.PLAYER_DIAL).size(), 0, "creation waits for the offer")
		assert_true(_play_pending(JamesDial.OFFER), "offer ends")
		assert_true(flags["dialGiftGranted"], "seeding unlocked")
		JamesDial.daily_tick()
		assert_eq(_pending(JamesDial.OFFER).size(), 0, "offer not re-queued")
		assert_true(_play_pending(JamesDial.PLAYER_DIAL), "creation ends")
		assert_true(flags["jamesPlayerDialSeen"], "seen")
		assert_eq(GameState.state["currentScreen"], "hq_dial", "sent to the Dial bench")
	)

	run_case("queued_quote_survives_a_save_round_trip_as_ints", func():
		_fresh()
		_evaluation_ready()
		JamesDial.daily_tick()
		var original: Dictionary = GameState.deep_copy(GameState.state)
		var exported := SaveManager.export_string()
		GameState.reset()
		assert_true(SaveManager.import_string(exported)["ok"], "imports")
		assert_eq(GameState.state, original, "quote flags and payload stay ints")
	)

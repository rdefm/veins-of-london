extends "res://tests/test_base.gd"

# The Prologue cold open (R§3.7b Scripted fights): the event grants a T5 Rewind,
# the scripted fight locks to it, and the Rewind flees back to the resume cards.
# Also covers add_item's optional `tier` / `equip`.


func _reach_fight() -> void:
	GameState.reset()
	Events.start_event("cold_open")
	for step in range(30):
		if GameState.state["combat"]["active"]:
			return
		if Events.is_awaiting_choice():
			Events.choose(0)
		else:
			Events.advance()


func run() -> void:
	run_case("add_item_tier_defaults_to_one_and_names_a_tier", func():
		GameState.reset()
		Events.apply_effects([{ "op": "add_item", "item": "rewind", "qty": 1 }])
		assert_eq(GameState.state["player"]["inventory"]["rewind"], { "1": 1 }, "no tier: tier 1")
		Events.apply_effects([{ "op": "add_item", "item": "rewind", "qty": 1, "tier": 5 }])
		assert_eq(GameState.state["player"]["inventory"]["rewind"], { "1": 1, "5": 1 }, "tier 5 bucket")
		assert_eq(Loadout.slot(0), null, "not equipped unless asked")
	)

	run_case("add_item_equip_fills_the_first_empty_slot", func():
		GameState.reset()
		Events.apply_effects([{ "op": "add_item", "item": "rewind", "qty": 1, "tier": 5, "equip": true }])
		assert_eq(Loadout.slot(0), { "recipe": "rewind", "tier": 5 })
		assert_eq(Crafting.inventory_qty("rewind"), 0, "moved out of inventory")
	)

	run_case("cold_open_opens_on_archie_standing_and_plays_his_ko", func():
		_reach_fight()
		var combat: Dictionary = GameState.state["combat"]
		var before: Dictionary = combat["roundFrames"][0]
		assert_true(not before["combatants"][1]["koed"], "Archie stands as the fight opens")
		var beats := CombatRounds.opening_beats(combat)
		var ko: int = beats.find_custom(func(b): return b["kind"] == "ko" and int(b["target"]) == 1)
		assert_true(ko >= 0, "the KO on Archie is an opening beat")
		var hit: int = beats.find_custom(func(b): return int(b["actor"]) == 2 and int(b["target"]) == 1 and CombatDirector.beat_is_damaging(b))
		assert_true(hit >= 0 and hit < ko, "Nick's hit lands before the KO")
		assert_true(str(beats[ko]["text"]) != "", "the KO has a transcript line")
		assert_true(combat["combatants"][1]["koed"], "Archie is down after it")
		Combat.choose_move("guard")
		assert_eq(CombatRounds.opening_beats(combat), [], "a pick ends the opening")
	)

	run_case("cold_open_rewind_plays_back_through_archies_ko_then_the_post_plan", func():
		_reach_fight()
		var combat: Dictionary = GameState.state["combat"]
		for step in range(8):
			if CombatRounds.script_locked(combat):
				break
			Combat.choose_move("strike", 2)
		var host := CombatScreen.new()
		host._ready()
		var screen: CombatRoundsScreen = host._round_screen
		screen._ready()
		var log_before: Array = combat["log"].duplicate()
		var undone := screen.begin_rewind_playback()
		assert_eq(undone.size(), log_before.size(), "every beat back to the opening")
		assert_eq(undone[0]["text"], log_before[-1]["text"], "newest first")
		var ko: int = undone.find_custom(func(b): return b["kind"] == "ko" and int(b["target"]) == 1)
		assert_true(ko >= 0, "Archie's KO plays back")
		assert_true(not screen._rewind_replay.is_empty() and not screen._rewind_replay["beats"].is_empty(), "the post-Rewind plan is left to play forward")
		assert_true(not screen._rewind_replay["restored"]["combatants"][1]["koed"], "it plays from Archie standing")
		screen._end_playback()
		host.free()
	)

	run_case("cold_open_post_rewind_pearl_freezes_nick_through_the_escape", func():
		_reach_fight()
		var combat: Dictionary = GameState.state["combat"]
		for step in range(8):
			if CombatRounds.script_locked(combat):
				break
			Combat.choose_move("strike", 2)
		var replay: Array = combat["log"].slice(int(Combat.round_rewind()["logKept"]))
		var pearl: int = replay.find_custom(func(b): return b["kind"] == "timePearl")
		assert_true(pearl >= 0, "the pearl plays after the Rewind")
		assert_eq(int(replay[pearl]["actor"]), 1, "Archie plays it")
		assert_eq(replay[pearl]["affected"], [2], "it lands on Nick")
		assert_true(combat["combatants"][1]["loadout"][0]["used"], "from Archie's slot 0")
		assert_true(str(replay[pearl]["text"]) != "", "the pearl has a transcript line")
		var cues: Array = CombatRoundsScreen.beat_cues(replay[pearl])
		assert_true(cues.any(func(c): return c["call"] == "throw" and int(c["who"]) == 1), "Archie throws it on stage")
		for i in range(pearl, replay.size()):
			assert_true(replay[i]["marks"][2]["frozen"], "Nick frozen at beat %d (%s)" % [i, replay[i]["kind"]])
		assert_eq(combat["outcome"], "fled", "the fight resolves into the escape")
		assert_true(int(combat["combatants"][2]["frozenActions"]) > 0, "still frozen at the end")
	)

	run_case("rewind_playback_is_quicker_than_forward_pacing", func():
		var speed: float = GameData.COMBAT_VISUALS["pacing"]["rewindSpeed"]
		assert_eq(CombatDirector.rewind_speed(), speed, "from data")
		assert_true(speed > 1.0, "faster than forward")
	)

	run_case("cold_open_plays_fight_lock_rewind_and_hands_off_to_the_pub", func():
		_reach_fight()
		var combat: Dictionary = GameState.state["combat"]
		assert_true(combat["active"], "the fight opens")
		assert_eq(Loadout.slot(0), { "recipe": "rewind", "tier": 5 }, "the T5 Rewind is equipped")
		assert_true(combat["combatants"][1]["koed"], "the sucker punch drops Archie")
		for step in range(8):
			if CombatRounds.script_locked(combat):
				break
			Combat.choose_move("strike", 2)
		assert_true(CombatRounds.script_locked(combat), "the bar locks within a few rounds")
		assert_true(Combat.round_rewind()["ok"], "the player taps the Rewind")
		assert_eq(combat["outcome"], "fled")
		Combat.exit_combat()
		for step in range(10):
			if GameState.state["event"] == null or GameState.state["event"]["eventId"] != "cold_open":
				break
			Events.advance()
		assert_true(GameState.state["flags"]["coldOpenSeen"])
		assert_eq(GameState.state["event"]["eventId"], "pub", "hands off to the pub")
	)

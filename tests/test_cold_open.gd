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

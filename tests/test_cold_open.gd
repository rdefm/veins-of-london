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

extends "res://tests/test_base.gd"

# combat-presentation ticket 03, docs/combat-animation-vision.md §2.5: the
# Dial widget's own selection/trigger logic, tested independently of
# CombatScreen's wiring (tests/test_combat_screen.gd covers that half: deck
# placement, hiding the widget when nothing's loaded, and selection
# persisting across a refresh). Same "test the logic, not the gesture
# plumbing" split TurnOrderStrip's own tests use -- handle_rotate/
# handle_trigger are public exactly so these cases don't have to simulate
# InputEvents.


func _dial(loaded_recipe_keys: Array, current_charge: int = 3, max_charge: int = 5) -> Dictionary:
	var loaded: Array = []
	for key in loaded_recipe_keys:
		loaded.append({ "recipeKey": key, "tier": 1, "capacityCost": 1 })
	return {
		"level": 1, "xp": 0, "currentCharge": current_charge, "maxCharge": max_charge,
		"rechargeRate": 0, "combatRegenTurnCounter": 0, "lastRegenDay": 1,
		"capacityMax": Dial.capacity_max(1), "movement": null, "loadedComplications": loaded,
		"haftId": "stub",
	}


func run() -> void:
	run_case("configure_clamps_a_stale_selected_index_to_the_current_list_size", func():
		var widget := DialWidget.new()
		widget.configure(_dial(["blast"]), 5, Callable())

		assert_eq(widget.current_index(), 0, "only one Complication is loaded -- a stale index 5 must clamp down")
	)

	run_case("handle_rotate_cycles_forward_and_reports_the_new_index_via_the_callback", func():
		var widget := DialWidget.new()
		var received: Array = []
		widget.configure(_dial(["blast", "shield", "blackHole"]), 0, func(i): received.append(i))

		widget.handle_rotate(1)

		assert_eq(received, [1])
		assert_eq(widget.current_index(), 0, "handle_rotate() only reports through the callback -- like TurnOrderStrip.handle_swipe(), it never mutates its own selection; the caller (CombatScreen) owns persisting it via a fresh configure()")
	)

	run_case("handle_rotate_wraps_around_at_either_end_unlike_the_turn_order_strips_clamp", func():
		var widget := DialWidget.new()
		var received: Array = []
		widget.configure(_dial(["blast", "shield", "blackHole"]), 2, func(i): received.append(i))

		widget.handle_rotate(1)

		assert_eq(received, [0], "rotating forward past the last Complication should wrap to the first -- a dial spins continuously")
	)

	run_case("handle_rotate_backward_wraps_to_the_last_entry", func():
		var widget := DialWidget.new()
		var received: Array = []
		widget.configure(_dial(["blast", "shield", "blackHole"]), 0, func(i): received.append(i))

		widget.handle_rotate(-1)

		assert_eq(received, [2])
	)

	run_case("handle_rotate_is_a_no_op_with_only_one_complication_loaded", func():
		var widget := DialWidget.new()
		var received: Array = []
		widget.configure(_dial(["blast"]), 0, func(i): received.append(i))

		widget.handle_rotate(1)

		assert_eq(widget.current_index(), 0)
		assert_eq(received.size(), 0, "nothing to cycle to -- the callback should not fire")
	)

	run_case("handle_trigger_casts_the_selected_complication_via_Combat_cast_complication", func():
		GameState.reset()
		GameState.state["player"]["dial"] = _dial(["blast", "shield"], 3, 5)
		GameState.state["combat"] = {
			"active": true, "context": Combat.CONTEXT_RAID, "veinId": null,
			"enemies": [{ "name": "Enemy", "hp": 20, "hpMax": 20, "attackMin": 1, "attackMax": 1, "isMugging": false, "weapon": null, "ability": null, "evadeChance": 0.0, "speed": 10, "koed": false }],
			"focusedEnemyIndex": 0, "log": [], "outcome": null, "frozenTurns": 0,
			"motionTurns": 0, "motionPower": 0, "evadeTurns": 0, "evadeChance": 0.0,
			"onWin": "", "snapshots": [], "allies": [],
		}
		var widget := DialWidget.new()
		widget.configure(GameState.state["player"]["dial"], 1, Callable())  # index 1 -> shield

		widget.handle_trigger()

		assert_true(GameState.state["player"]["shieldPool"] > 0, "triggering the selected (shield) Complication should apply its effect")
		assert_eq(GameState.state["player"]["dial"]["currentCharge"], 2, "a successful cast should spend one charge")
	)

	run_case("handle_trigger_is_refused_without_enough_charge_same_as_the_old_bag_drawer_button", func():
		GameState.reset()
		GameState.state["player"]["dial"] = _dial(["blast"], 0, 5)
		GameState.state["combat"] = {
			"active": true, "context": Combat.CONTEXT_RAID, "veinId": null,
			"enemies": [{ "name": "Enemy", "hp": 20, "hpMax": 20, "attackMin": 1, "attackMax": 1, "isMugging": false, "weapon": null, "ability": null, "evadeChance": 0.0, "speed": 10, "koed": false }],
			"focusedEnemyIndex": 0, "log": [], "outcome": null, "frozenTurns": 0,
			"motionTurns": 0, "motionPower": 0, "evadeTurns": 0, "evadeChance": 0.0,
			"onWin": "", "snapshots": [], "allies": [],
		}
		var widget := DialWidget.new()
		widget.configure(GameState.state["player"]["dial"], 0, Callable())
		var enemy_hp_before: int = GameState.state["combat"]["enemies"][0]["hp"]

		widget.handle_trigger()

		assert_eq(GameState.state["combat"]["enemies"][0]["hp"], enemy_hp_before, "zero charge should refuse the cast -- no effect applied")
	)

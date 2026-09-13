extends "res://tests/test_base.gd"

# combat-presentation ticket 03, docs/combat-animation-vision.md §2.5: the
# Dial widget's own selection/trigger logic, tested independently of
# CombatScreen's wiring (tests/test_combat_screen.gd covers that half: deck
# placement, showing the widget once a Dial is seeded, and selection
# persisting across a refresh). Same "test the logic, not the gesture
# plumbing" split TurnOrderStrip's own tests use -- handle_select/
# handle_trigger are public exactly so these cases don't have to simulate
# InputEvents.
#
# combat-presentation ticket 18 (human direction, 2026-09-09): handle_rotate()
# (relative, wrapping cycle) is replaced by handle_select(index) (direct,
# tap-one-of-4-screws selection) -- see dial_widget.gd's own top comment.


func _dial(loaded_recipe_keys: Array, current_charge: int = 3, max_charge: int = 5) -> Dictionary:
	var loaded: Array = []
	for key in loaded_recipe_keys:
		loaded.append({ "recipeKey": key, "tier": 1 })
	return {
		"level": 1, "xp": 0, "currentCharge": current_charge, "maxCharge": max_charge,
		"rechargeRate": 0, "combatRegenTurnCounter": 0, "lastRegenDay": 1,
		"capacityMax": Dial.capacity_max(1), "movement": null, "loadedComplications": loaded,
		"haftId": "stub",
	}


func run() -> void:
	# ui-chrome-pass ticket 03: the confirmed-by-screenshot bug this ticket
	# fixes was WIDGET_SIZE (formerly VISIBLE_BOX_SIZE) being smaller than the
	# rendered art, cropping it down to a small headshot -- guard that it
	# never regresses back to a box narrower/shorter than the render it's
	# meant to fully contain, and that the four screw hit-targets (which used
	# to sit right at the crop's own edge) all land safely inside the box.
	run_case("widget_size_fully_contains_the_rendered_umbrella_with_no_cropping", func():
		# ticket 108: WIDGET_SIZE.x is checked against RENDERED_WIDTH, not
		# HANDLE_DISPLAY_SIZE -- this widget now deliberately crops the source
		# texture's own blank native margin (CROP_NATIVE_X's own comment), so
		# HANDLE_DISPLAY_SIZE (a full 500-native-unit span) is no longer the
		# rendered width. RENDERED_WIDTH is what actually gets drawn on
		# screen, and the box must still fully contain THAT without cropping.
		assert_true(DialWidget.WIDGET_SIZE.x >= DialWidget.RENDERED_WIDTH, "the box must be at least as wide as the rendered (cropped) art -- narrower crops the sides off again")
		assert_true(DialWidget.WIDGET_SIZE.y >= DialWidget.HANDLE_DISPLAY_SIZE, "the box must be at least as tall as the rendered art -- shorter crops the top/bottom off again")

		var widget := DialWidget.new()
		widget.configure(_dial(["blast", "shield", "blackHole", "healingBurst"]), 0, Callable())

		# The whole HIT RECT (not just the dot's own centre point) must sit
		# inside the box -- code-review finding, 2026-09-11: the topmost
		# screw's centre alone can pass this check while its tap-rect still
		# pokes out past y=0 (unreachable there -- _gui_input() only ever
		# sees positive local coordinates), silently shrinking that screw's
		# real tap target. See TOP_PADDING's own comment for the fix this
		# guards against regressing.
		for i in range(DialWidget.MAX_DOTS):
			var rect: Rect2 = widget._dot_rect(i)
			assert_true(rect.position.x >= 0.0 and rect.position.y >= 0.0 and rect.end.x <= DialWidget.WIDGET_SIZE.x and rect.end.y <= DialWidget.WIDGET_SIZE.y, "screw %d's whole tap-rect must land inside the widget's own box, not just its centre -- got %s, box %s" % [i, rect, DialWidget.WIDGET_SIZE])

		var button_rect: Rect2 = widget._button_rect()
		assert_true(button_rect.position.x >= 0.0 and button_rect.position.y >= 0.0 and button_rect.end.x <= DialWidget.WIDGET_SIZE.x and button_rect.end.y <= DialWidget.WIDGET_SIZE.y, "the trigger switch's whole tap-rect must land inside the widget's own box too")
	)

	run_case("configure_clamps_a_stale_selected_index_to_the_current_list_size", func():
		var widget := DialWidget.new()
		widget.configure(_dial(["blast"]), 5, Callable())

		assert_eq(widget.current_index(), 0, "only one Complication is loaded -- a stale index 5 must clamp down")
	)

	run_case("handle_select_reports_the_tapped_index_via_the_callback", func():
		var widget := DialWidget.new()
		var received: Array = []
		widget.configure(_dial(["blast", "shield", "blackHole"]), 0, func(i): received.append(i))

		widget.handle_select(2)

		assert_eq(received, [2])
		assert_eq(widget.current_index(), 0, "handle_select() only reports through the callback -- like TurnOrderStrip.handle_swipe(), it never mutates its own selection; the caller (CombatScreen) owns persisting it via a fresh configure()")
	)

	run_case("handle_select_reports_regardless_of_which_screw_it_is_relative_to_the_current_one", func():
		var widget := DialWidget.new()
		var received: Array = []
		widget.configure(_dial(["blast", "shield", "blackHole"]), 2, func(i): received.append(i))

		widget.handle_select(0)

		assert_eq(received, [0], "a direct tap jumps straight to whichever screw was tapped, not a relative step")
	)

	run_case("handle_select_is_a_no_op_past_the_end_of_the_loaded_list", func():
		var widget := DialWidget.new()
		var received: Array = []
		widget.configure(_dial(["blast"]), 0, func(i): received.append(i))

		widget.handle_select(1)

		assert_eq(widget.current_index(), 0)
		assert_eq(received.size(), 0, "nothing loaded into that screw -- the callback should not fire")
	)

	run_case("handle_select_is_a_no_op_for_a_negative_index", func():
		var widget := DialWidget.new()
		var received: Array = []
		widget.configure(_dial(["blast", "shield"]), 0, func(i): received.append(i))

		widget.handle_select(-1)

		assert_eq(received.size(), 0)
	)

	run_case("handle_trigger_casts_the_selected_complication_via_Combat_cast_complication", func():
		GameState.reset()
		GameState.state["player"]["dial"] = _dial(["blast", "shield"], 3, 5)
		GameState.state["combat"] = {
			"active": true, "context": Combat.CONTEXT_RAID, "veinId": null,
			"enemies": [{ "name": "Enemy", "hp": 20, "hpMax": 20, "attackMin": 1, "attackMax": 1, "isMugging": false, "weapon": null, "ability": null, "evadeChance": 0.0, "speed": 10, "koed": false }],
			"focusedEnemyIndex": 0, "log": [], "outcome": null, "frozenTurns": 0,
			"motionTurns": 0, "motionPower": 0, "evadeTurns": 0, "evadeChance": 0.0,
			"onWin": "", "snapshots": [], "beatsSinceSnapshot": [], "allies": [],
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
			"onWin": "", "snapshots": [], "beatsSinceSnapshot": [], "allies": [],
		}
		var widget := DialWidget.new()
		widget.configure(GameState.state["player"]["dial"], 0, Callable())
		var enemy_hp_before: int = GameState.state["combat"]["enemies"][0]["hp"]

		widget.handle_trigger()

		assert_eq(GameState.state["combat"]["enemies"][0]["hp"], enemy_hp_before, "zero charge should refuse the cast -- no effect applied")
	)

	# combat-presentation ticket 05: handle_trigger()'s new on_triggered report.

	run_case("handle_trigger_reports_the_cast_result_through_on_triggered", func():
		GameState.reset()
		GameState.state["player"]["dial"] = _dial(["blast"], 3, 5)
		GameState.state["combat"] = {
			"active": true, "context": Combat.CONTEXT_RAID, "veinId": null,
			"enemies": [{ "name": "Enemy", "hp": 20, "hpMax": 20, "attackMin": 1, "attackMax": 1, "isMugging": false, "weapon": null, "ability": null, "evadeChance": 0.0, "speed": 10, "koed": false }],
			"focusedEnemyIndex": 0, "log": [], "outcome": null, "frozenTurns": 0,
			"motionTurns": 0, "motionPower": 0, "evadeTurns": 0, "evadeChance": 0.0,
			"onWin": "", "snapshots": [], "beatsSinceSnapshot": [], "allies": [],
		}
		var received: Array = []
		var widget := DialWidget.new()
		widget.configure(GameState.state["player"]["dial"], 0, Callable(), func(result): received.append(result))

		widget.handle_trigger()

		assert_eq(received.size(), 1, "a successful trigger should report exactly once")
		assert_true(received[0]["ok"])
		assert_true(received[0]["beats"].size() > 0, "the reported result should carry Blast's own damaging beat")
	)

	run_case("handle_trigger_reports_even_a_refused_cast_through_on_triggered", func():
		GameState.reset()
		GameState.state["player"]["dial"] = _dial(["blast"], 0, 5)
		GameState.state["combat"] = {
			"active": true, "context": Combat.CONTEXT_RAID, "veinId": null,
			"enemies": [{ "name": "Enemy", "hp": 20, "hpMax": 20, "attackMin": 1, "attackMax": 1, "isMugging": false, "weapon": null, "ability": null, "evadeChance": 0.0, "speed": 10, "koed": false }],
			"focusedEnemyIndex": 0, "log": [], "outcome": null, "frozenTurns": 0,
			"motionTurns": 0, "motionPower": 0, "evadeTurns": 0, "evadeChance": 0.0,
			"onWin": "", "snapshots": [], "beatsSinceSnapshot": [], "allies": [],
		}
		var received: Array = []
		var widget := DialWidget.new()
		widget.configure(GameState.state["player"]["dial"], 0, Callable(), func(result): received.append(result))

		widget.handle_trigger()

		assert_eq(received.size(), 1, "a refused cast should still be reported, just with ok == false")
		assert_true(not received[0]["ok"])
	)

	run_case("handle_trigger_with_no_on_triggered_callback_still_casts_normally", func():
		GameState.reset()
		GameState.state["player"]["dial"] = _dial(["blast"], 3, 5)
		GameState.state["combat"] = {
			"active": true, "context": Combat.CONTEXT_RAID, "veinId": null,
			"enemies": [{ "name": "Enemy", "hp": 20, "hpMax": 20, "attackMin": 1, "attackMax": 1, "isMugging": false, "weapon": null, "ability": null, "evadeChance": 0.0, "speed": 10, "koed": false }],
			"focusedEnemyIndex": 0, "log": [], "outcome": null, "frozenTurns": 0,
			"motionTurns": 0, "motionPower": 0, "evadeTurns": 0, "evadeChance": 0.0,
			"onWin": "", "snapshots": [], "beatsSinceSnapshot": [], "allies": [],
		}
		var widget := DialWidget.new()
		# 3-arg configure() -- every pre-ticket-05 call site, unchanged.
		widget.configure(GameState.state["player"]["dial"], 0, Callable())

		widget.handle_trigger()

		assert_true(GameState.state["combat"]["enemies"][0]["hp"] < 20, "the cast itself must still happen with no on_triggered wired at all")
	)

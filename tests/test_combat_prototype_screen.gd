extends "res://tests/test_base.gd"

# Build-only smoke coverage for scenes/screens/combat_prototype.gd across
# setup, planning, mid-fight and finished states (off-tree Screen.new();
# _ready(), same as tests/test_combat_screen.gd). Rules coverage lives in
# tests/test_combat_prototype.gd.


func _render() -> CombatPrototypeScreen:
	var screen := CombatPrototypeScreen.new()
	screen._ready()
	assert_true(screen._content.get_child_count() > 0)
	return screen


func run() -> void:
	run_case("setup_renders_when_no_fight_is_on", func():
		GameState.reset()
		_render()
	)

	run_case("planning_renders_with_a_partly_filled_plan", func():
		GameState.reset()
		CombatPrototype.start({ "seed": 1 })
		CombatPrototype.set_plan_action(0, "guard")
		_render()
	)

	run_case("refresh_after_a_committed_round_rebuilds_the_same_body", func():
		GameState.reset()
		CombatPrototype.start({ "seed": 2 })
		var screen := _render()
		var content_before := screen._content
		CombatPrototype.resolve_round([{ "move": "guard" }, { "move": "strike" }])
		assert_eq(screen._content, content_before, "only the body's children rebuild per refresh")
		assert_true(screen._content.get_child_count() > 0)
	)

	run_case("finished_fight_renders_the_outcome_card", func():
		GameState.reset()
		CombatPrototype.start({ "seed": 3 })
		GameState.state["combatPrototype"]["combatants"][1]["hp"] = 1
		CombatPrototype.resolve_round([{ "move": "strike" }, { "move": "strike" }])
		assert_eq(GameState.state["combatPrototype"]["outcome"], "win")
		_render()
	)

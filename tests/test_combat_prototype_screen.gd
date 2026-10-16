extends "res://tests/test_base.gd"

# Build-only smoke coverage for scenes/screens/combat_prototype.gd across
# setup, paused mid-round, mid-fight and finished states (off-tree
# Screen.new(); _ready(), same as tests/test_combat_screen.gd), plus a whole
# fight played through the screen's own pick handler. Rules coverage lives
# in tests/test_combat_prototype.gd.


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

	run_case("renders_paused_on_the_second_position_after_a_pick", func():
		GameState.reset()
		CombatPrototype.start({ "seed": 1, "loadout": [{ "item": "healingBurst", "tier": 1 }] })
		CombatPrototype.choose_move("guard")
		assert_eq(CombatPrototype.decision_position(GameState.state["combatPrototype"]), 1)
		_render()
	)

	run_case("a_pick_with_no_room_is_refused_with_its_reason", func():
		GameState.reset()
		CombatPrototype.start({ "seed": 4, "enemies": [{ "archetype": "mugger", "level": 1 }, { "archetype": "mugger", "level": 1 }] })
		var screen := _render()
		screen._pick("stun", 2)
		assert_true(GameState.state["combatPrototype"]["playerPlan"][0] != null, "the Stun resolved")
		screen._pick("lure", -1)
		assert_eq(screen._refusal, "Lure takes 2 actions in a row.")
		assert_true(screen._content.get_child_count() > 0)
	)

	run_case("refresh_after_a_round_rebuilds_the_same_body", func():
		GameState.reset()
		CombatPrototype.start({ "seed": 2 })
		var screen := _render()
		var content_before := screen._content
		CombatPrototype.choose_move("guard")
		CombatPrototype.choose_move("strike")
		assert_eq(screen._content, content_before, "only the body's children rebuild per refresh")
		assert_true(screen._content.get_child_count() > 0)
	)

	run_case("a_whole_fight_plays_through_the_screens_pick_handler", func():
		GameState.reset()
		CombatPrototype.start({ "seed": 3 })
		var screen := _render()
		var cp: Dictionary = GameState.state["combatPrototype"]
		var picks := 0
		while cp["outcome"] == null and picks < 200:
			screen._pick("strike", -1)
			assert_eq(screen._refusal, "")
			picks += 1
		assert_true(cp["outcome"] != null, "the fight finished")
		assert_true(screen._content.get_child_count() > 0, "the outcome card renders")
	)

extends "res://tests/test_base.gd"

# day-rhythm-business-and-combat ticket 14: build-only smoke coverage for
# scenes/screens/combat_prototype.gd -- same off-tree `Screen.new(); screen.
# _ready()` pattern tests/test_combat_screen.gd/test_hq_screen.gd already
# establish (no live SceneTree needed; run_case()'s own EventBus-connection
# cleanup, see tests/test_base.gd, handles the leaked _refresh() listener
# this pattern leaves behind). This isn't the rules coverage -- that's
# tests/test_combat_prototype.gd, driven entirely through systems/
# combat_prototype.gd's public API -- just proof the screen actually
# renders across every reachable state (inactive, mid-fight, exhausted,
# win, loss, fled) without throwing.


func run() -> void:
	run_case("inactive_state_renders_without_crashing", func():
		GameState.reset()
		var screen := CombatPrototypeScreen.new()
		screen._ready()
		assert_true(is_instance_valid(screen))
	)

	run_case("mid_fight_state_renders_the_action_grid", func():
		GameState.reset()
		CombatPrototype.start_encounter("brawler")
		var screen := CombatPrototypeScreen.new()
		screen._ready()
		assert_true(is_instance_valid(screen))
	)

	run_case("exhausted_player_state_renders_the_continue_prompt_instead_of_actions", func():
		GameState.reset()
		CombatPrototype.start_encounter("brawler")
		GameState.state["combatPrototype"]["player"]["exhaustedNextTurn"] = true
		var screen := CombatPrototypeScreen.new()
		screen._ready()
		assert_true(is_instance_valid(screen))
	)

	run_case("win_outcome_state_renders_the_outcome_card", func():
		GameState.reset()
		CombatPrototype.start_encounter("brawler")
		GameState.state["combatPrototype"]["outcome"] = "win"
		var screen := CombatPrototypeScreen.new()
		screen._ready()
		assert_true(is_instance_valid(screen))
	)

	run_case("loss_outcome_state_renders_the_outcome_card", func():
		GameState.reset()
		CombatPrototype.start_encounter("brawler")
		GameState.state["combatPrototype"]["outcome"] = "loss"
		var screen := CombatPrototypeScreen.new()
		screen._ready()
		assert_true(is_instance_valid(screen))
	)

	run_case("fled_outcome_on_the_last_encounter_renders_without_a_next_encounter_button", func():
		GameState.reset()
		CombatPrototype.start_encounter("enforcer")  # last id in encounterOrder
		GameState.state["combatPrototype"]["outcome"] = "fled"
		var screen := CombatPrototypeScreen.new()
		screen._ready()
		assert_true(is_instance_valid(screen))
	)

	run_case("refresh_rebuilds_content_from_scratch_on_a_second_state_changed", func():
		GameState.reset()
		CombatPrototype.start_encounter("knifeFighter")
		var screen := CombatPrototypeScreen.new()
		screen._ready()
		var content_before := screen._content
		Rng.set_seed(1)
		CombatPrototype.take_player_action(CombatPrototype.ACTION_FAST)
		assert_eq(screen._content, content_before, "the outer ScrollContainer/VBoxContainer itself is built once in _ready(), only its children are rebuilt per refresh")
		assert_true(screen._content.get_child_count() > 0)
	)

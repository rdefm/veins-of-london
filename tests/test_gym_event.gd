extends "res://tests/test_base.gd"

# The Prologue gym beat (Flip Reverse): intro cards, a guided practice spar
# (R1 Guard, R2 Feint -> Strike, R3 Stun), a watch-only demo, then gymUnlocked
# with the three free sessions intact.


func _advance_to_choice() -> void:
	for step in range(20):
		if Events.is_awaiting_choice():
			return
		Events.advance()


func _guided_win() -> Dictionary:
	GameState.reset()
	Events.start_event("gym")
	_advance_to_choice()
	Events.choose(0)
	var combat: Dictionary = GameState.state["combat"]
	assert_true(combat["active"] and CombatRounds.is_spar(combat), "practice spar opens")
	return combat


func run() -> void:
	run_case("guided_spar_lessons_are_achievable_with_the_allowed_moves", func():
		var combat := _guided_win()
		assert_eq(CombatRounds.coach_allowed(combat), ["guard"])
		assert_true(Combat.choose_move("guard")["ok"])
		assert_true(Combat.choose_move("guard")["ok"])
		assert_eq(int(combat["round"]), 2, "round 1 done")
		assert_true(Combat.choose_move("feint", 1)["ok"], "R2 Feint")
		assert_true(Combat.choose_move("strike", 1)["ok"], "R2 Strike")
		var beats: Array = combat["log"].map(func(b): return b["kind"])
		assert_true(beats.has("open") or beats.has("hit"), "the Strike lands on an Open Arnie")
		assert_eq(int(combat["round"]), 3, "round 2 done")
		assert_true(Combat.choose_move("stun", 1)["ok"], "R3 Stun")
		var stunned: Array = combat["log"].filter(func(b): return b["kind"] == "stun")
		assert_true(stunned.size() > 0, "the Stun lands on his open guard")
	)

	run_case("guided_spar_win_resumes_the_event_and_keeps_free_sessions", func():
		var combat := _guided_win()
		var sessions := Sparring.sessions_taken()
		combat["coach"] = null
		combat["combatants"][1]["hp"] = 1
		assert_true(Combat.choose_move("strike", 1)["ok"])
		assert_eq(combat["outcome"], "win")
		Combat.exit_combat()
		assert_eq(GameState.state["event"]["cardIndex"], 6, "resumes after the spar")
		assert_eq(Sparring.sessions_taken(), sessions, "no session used")
	)

	run_case("demo_then_exit_sets_gym_unlocked", func():
		var combat := _guided_win()
		combat["coach"] = null
		combat["combatants"][1]["hp"] = 1
		Combat.choose_move("strike", 1)
		Combat.exit_combat()
		_advance_to_choice()
		Events.choose(0)
		combat = GameState.state["combat"]
		assert_true(CombatRounds.is_demo(combat), "demo opens")
		for i in range(2):
			Combat.demo_step()
		Combat.exit_combat()
		for step in range(10):
			if GameState.state["event"] == null:
				break
			Events.advance()
		assert_true(GameState.state["flags"]["gymUnlocked"])
		assert_eq(Sparring.free_sessions_left(), 3, "free sessions intact")
	)

	run_case("prose_has_no_firm_hints", func():
		var text := JSON.stringify(GameData.EVENTS["gym"]).to_lower()
		for banned in ["nick", "reginald", "firm"]:
			assert_true(not text.contains(banned), "no '%s'" % banned)
	)

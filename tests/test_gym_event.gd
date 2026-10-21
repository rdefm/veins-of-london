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


# The guided spar won and exited, then the watch-only demo opened.
func _demo() -> Dictionary:
	var combat := _guided_win()
	combat["coach"] = null
	combat["combatants"][1]["hp"] = 1
	Combat.choose_move("strike", 1)
	Combat.exit_combat()
	_advance_to_choice()
	Events.choose(0)
	combat = GameState.state["combat"]
	assert_true(CombatRounds.is_demo(combat), "demo opens")
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

	run_case("guided_spar_lessons_name_the_move_and_beats_get_coach_notes", func():
		var combat := _guided_win()
		var notes: Dictionary = combat["coach"]["notes"]
		var picks := { 1: [["guard", -1], ["guard", -1]], 2: [["feint", 1], ["strike", 1]], 3: [["stun", 1], ["strike", 1]] }
		for round_no in [1, 2, 3]:
			assert_eq(int(combat["round"]), round_no)
			var lesson := CombatRounds.coach_lesson(combat).to_lower()
			for id in CombatRounds.coach_allowed(combat):
				assert_true(lesson.contains(str(id)), "R%d lesson names %s" % [round_no, id])
			for pick in picks[round_no]:
				var result: Dictionary = Combat.choose_move(pick[0], pick[1]) if pick[1] >= 0 else Combat.choose_move(pick[0])
				assert_true(result["ok"], "R%d %s" % [round_no, pick[0]])
			var noted: Array = combat["log"].filter(func(b): return int(b["round"]) == round_no and b.has("coachNote"))
			assert_eq(noted.size(), notes[str(round_no)].size(), "R%d: each note shows once" % round_no)
			for beat in noted:
				var at: int = combat["transcript"].find(beat["text"])
				assert_true(at >= 0 and combat["transcript"].find(beat["coachNote"], at) == at + 1, "note follows its beat line")
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
		_demo()
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

	run_case("demo_beats_carry_arnie_voiceover_and_hp_shows_for_both", func():
		var combat := _demo()
		var host := CombatScreen.new()
		host._ready()
		var screen: CombatRoundsScreen = host._round_screen
		screen._ready()
		var hp_label: Label = screen.find_child("DemoHp", true, false)
		for i in range(2):
			Combat.demo_step()
			screen._refresh()
			for idx in [1, 2]:
				var c: Dictionary = combat["combatants"][idx]
				assert_true(hp_label.visible and hp_label.text.contains("%s %d/%d HP" % [c["name"], c["hp"], c["hpMax"]]), "%s hp shown: %s" % [c["name"], hp_label.text])
		var at := 0
		for beat in combat["log"]:
			assert_true(beat.has("coachNote"), "R%d %s has a voiceover" % [beat["round"], beat["kind"]])
			at = combat["transcript"].find(beat["text"], at)
			assert_true(at >= 0 and combat["transcript"][at + 1] == beat.get("coachNote"), "voiceover follows its beat line")
		var kinds: Array = combat["log"].map(func(b): return b["kind"])
		for kind in ["feint", "autoguard", "retaliate"]:
			assert_true(kinds.has(kind), "demo shows %s" % kind)
		host.free()
	)

	run_case("prose_has_no_firm_hints", func():
		var text := JSON.stringify(GameData.EVENTS["gym"]).to_lower()
		for banned in ["nick", "reginald", "firm"]:
			assert_true(not text.contains(banned), "no '%s'" % banned)
	)

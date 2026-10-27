extends "res://tests/test_scripted_fight.gd"

# Unlocked and practice scripted fights (R§3.7b Scripted fights): a script
# with no Rewind lock plays as a normal fight on its fixed plans and resumes
# the event on any outcome; `practice` runs it under spar rules.


# The guided-spar shape: Arnie (combatant 1, faster than the player) swings
# twice in round 1, covers up in round 2 and swings first in round 3, so the
# coached R1 Guard, R2 Feint -> Strike, R3 Stun all land.
func _guided(practice: bool = false) -> Dictionary:
	var script := {
		"seed": 7, "intro": ["Mats down."],
		"enemies": [{
			"name": "Arnie", "hpMax": 500, "attackMin": 4, "attackMax": 4, "level": 1, "speed": 99,
			"moveLevels": MOVE_LEVELS,
			"plans": [["strike", "strike"], ["guard", "guard"], ["strike", "guard"]],
		}],
		"coach": {
			"lessons": { "1": "Guard it.", "2": "Feint, then hit.", "3": "He's open. Stun." },
			"allowed": { "1": ["guard"], "2": ["feint", "strike"], "3": ["stun", "strike"] },
		},
		"resumeCard": RESUME_CARD,
	}
	if practice:
		script["practice"] = true
	return script


func _win(combat: Dictionary) -> void:
	combat["coach"] = null
	combat["combatants"][1]["hp"] = 1
	assert_true(Combat.choose_move("strike", 1)["ok"], "the finishing Strike")
	assert_eq(combat["outcome"], "win")


func _exit_resumes(outcome: String) -> void:
	assert_eq(GameState.state["combat"]["outcome"], outcome)
	var result := Combat.exit_combat()
	assert_eq(result["nextScreen"], "event", "%s goes back to the event" % outcome)
	assert_eq(GameState.state["event"]["cardIndex"], RESUME_CARD, "%s resumes at the script's card" % outcome)


func run() -> void:
	run_case("an_unlocked_script_validates_and_plays_the_coached_plan", func():
		var errors: Array[String] = []
		GameData._validate_effect_list([{ "op": "start_scripted_fight", "script": _guided(true) }], "t", errors)
		assert_eq(errors, [])
		var combat := _start(_guided())
		assert_eq(combat["script"]["phase"], CombatRounds.SCRIPT_OPEN)
		assert_true(not CombatRounds.script_locked(combat), "no lock")
		assert_eq(CombatRounds.coach_lesson(combat), "Guard it.")
		for pick in [["guard"], ["guard"], ["feint", 1], ["strike", 1]]:
			assert_true(Combat.choose_move(pick[0], pick[1] if pick.size() > 1 else -1)["ok"], "%s plays" % pick[0])
		assert_eq(int(combat["round"]), 3)
		assert_eq(CombatRounds.decision_position(combat), 0)
		assert_true(CombatRounds.is_open(combat, combat["combatants"][1]), "Arnie's swing leaves him Open for the R3 Stun")
		assert_true(Combat.choose_move("stun", 1)["ok"])
		assert_true(_kinds(combat["log"]).has("stun"), "the Stun lands")
	)

	run_case("a_partial_lock_is_flagged", func():
		var errors: Array[String] = []
		var script := _guided()
		script["lockBelowHp"] = 10
		GameData._validate_effect_list([{ "op": "start_scripted_fight", "script": script }], "t", errors)
		assert_eq(errors.size(), 2, "prompt and post missing")
		script = _guided()
		script["practice"] = "yes"
		errors = []
		GameData._validate_effect_list([{ "op": "start_scripted_fight", "script": script }], "t", errors)
		assert_eq(errors.size(), 1, "practice must be a bool")
	)

	run_case("unlocked_win_loss_and_fled_all_resume_the_event", func():
		_win(_start(_guided()))
		_exit_resumes("win")
		var combat := _start(_guided())
		combat["coach"] = null
		combat["combatants"][0]["hp"] = 1
		assert_true(Combat.choose_move("strike", 1)["ok"])
		_exit_resumes("loss")
		combat = _start(_guided())
		combat["coach"] = null
		combat["combatants"][0]["fleeBoost"] = 1.0
		assert_true(Combat.choose_move("legIt")["ok"])
		_exit_resumes("fled")
	)

	run_case("an_unlocked_fight_drops_people_and_pays_normal_xp", func():
		var combat := _start(_guided())
		_win(combat)
		var xp: int = GameState.state["player"]["bodyXP"]
		assert_true(combat["combatants"][1]["koed"], "Arnie goes down")
		Combat.exit_combat()
		assert_eq(GameState.state["player"]["bodyXP"], xp + Combat.ROUND_XP_WIN)
	)

	run_case("practice_runs_under_spar_rules", func():
		var combat := _start(_guided(true))
		var player: Dictionary = GameState.state["player"]
		var cash: int = player["cash"]
		var sessions := Sparring.sessions_taken()
		var xp: int = player["bodyXP"]
		var guard_xp: int = MoveLevels.record("")["guard"]["xp"]
		assert_true(CombatRounds.is_spar(combat))
		for i in range(3):
			assert_true(Combat.choose_move("guard")["ok"])
			assert_true(Combat.choose_move("guard")["ok"])
			assert_eq(Combat.round_rewind_block_reason(Combat.REWIND_PAY_FREE), "", "house Rewind %d open" % i)
			assert_true(Combat.round_rewind(Combat.REWIND_PAY_FREE)["ok"])
		assert_eq(Loadout.slot(0)["recipe"], "rewind", "the free Rewind spends nothing")
		assert_true(int(MoveLevels.record("")["guard"]["xp"]) > guard_xp, "move XP banked")
		Loadout.consume(0)
		player["hp"] = 5
		_win(combat)
		xp = player["bodyXP"]
		_exit_resumes("win")
		assert_eq(player["hp"], 30, "hp back as it was")
		assert_eq(Loadout.slot(0)["recipe"], "rewind", "items back as they were")
		assert_eq(player["bodyXP"], xp + Sparring.xp_for("win"), "spar XP with the win bonus")
		assert_eq(player["cash"], cash, "no cash")
		assert_eq(Sparring.sessions_taken(), sessions, "no spar session used")
	)

	run_case("save_and_load_mid_practice_keeps_position", func():
		var combat := _start(_guided(true))
		Combat.choose_move("guard")
		Combat.choose_move("guard")
		var round_before: int = combat["round"]
		assert_true(SaveManager.import_string(SaveManager.export_string())["ok"], "save loads")
		combat = GameState.state["combat"]
		assert_eq(int(combat["round"]), round_before, "same round")
		assert_eq(CombatRounds.decision_position(combat), 0)
		assert_true(CombatRounds.is_spar(combat), "still practice")
		assert_eq(combat["script"]["phase"], CombatRounds.SCRIPT_OPEN)
		assert_eq(CombatRounds.coach_allowed(combat), ["feint", "strike"], "coach still on round 2")
		GameData.EVENTS.erase(EVENT_ID)
	)

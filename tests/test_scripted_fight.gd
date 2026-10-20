extends "res://tests/test_base.gd"

# Scripted fights (R§3.7b Scripted fights): an event's start_scripted_fight op
# opens a fixed-plan fight with a forced sucker-punch KO, a lock to the Rewind
# below a set HP, and a scripted post-Rewind resolution that exits as `fled`
# back to the event at the script's resume card.

const EVENT_ID := "test_scripted_fight_event"
const RESUME_CARD := 2
const LOCK_PROMPT := "Break it. Now."

const MOVE_LEVELS := { "strike": 1, "guard": 1, "feint": 1, "stun": 1, "legIt": 1 }


# The cold-open shape: Archie (combatant 1, fast, holding a Time Pearl) and a
# Lieutenant (combatant 2) who strikes first; his first punch KOs Archie.
func _script(lieutenant_hp: int = 500) -> Dictionary:
	return {
		"seed": 5, "enemyFirst": true, "intro": ["The buyers arrive."],
		"enemies": [{
			"name": "The Lieutenant", "hpMax": lieutenant_hp, "attackMin": 8, "attackMax": 8, "level": 1, "speed": 60,
			"moveLevels": MOVE_LEVELS,
			"plans": [[{ "move": "strike", "target": 1 }, { "move": "strike", "target": 0 }], [{ "move": "strike", "target": 0 }, { "move": "strike", "target": 0 }]],
		}],
		"allies": [{
			"name": "Archie", "hpMax": 60, "attackMin": 3, "attackMax": 3, "level": 1, "speed": 99,
			"slots": [{ "recipe": "timePearl", "tier": 1 }], "moveLevels": MOVE_LEVELS,
			"plans": [["guard", "guard"]],
		}],
		"forcedHits": [{ "actor": 2, "target": 1, "crit": true, "ko": true }],
		"lockBelowHp": 30, "prompt": LOCK_PROMPT,
		"post": {
			"allyPlans": { "1": ["guard", { "move": "timePearl", "slot": 0 }] },
			"playerPlan": ["guard", "legIt"],
		},
		"resumeCard": RESUME_CARD,
	}


func _start(script: Dictionary) -> Dictionary:
	GameState.reset()
	GameState.state["player"]["hp"] = 30
	GameState.state["player"]["hpMax"] = 30
	GameState.state["player"]["loadout"]["slots"][0] = { "recipe": "rewind", "tier": 5 }
	GameData.EVENTS[EVENT_ID] = {
		"id": EVENT_ID,
		"cards": [
			{ "type": "narration", "label": null, "speaker": null, "text": "Setup" },
			{ "type": "narration", "label": null, "speaker": null, "text": "The fight" },
			{ "type": "narration", "label": null, "speaker": null, "text": "After" },
		],
	}
	Events.start_event(EVENT_ID)
	GameState.state["event"]["cardIndex"] = 1
	Events.apply_effects([{ "op": "start_scripted_fight", "script": script }])
	return GameState.state["combat"]


func _kinds(beats: Array) -> Array:
	return beats.map(func(b): return b["kind"])


func run() -> void:
	run_case("op_opens_a_scripted_fight_with_no_prep_and_the_sucker_punch_ko", func():
		var combat := _start(_script())
		assert_true(combat["active"] and GameState.state["currentScreen"] == "combat", "straight into the fight")
		assert_eq(GameState.state["combatPrep"], null, "no prep screen to cancel out of")
		assert_eq(combat["context"], Combat.CONTEXT_SCRIPTED)
		var punch: Dictionary = combat["log"].filter(func(b): return b["kind"] == "hit" and b["target"] == 1)[0]
		assert_true(punch["crit"], "forced crit")
		assert_eq(punch["actor"], 2, "the Lieutenant throws it, before the first pick")
		assert_true(combat["combatants"][1]["koed"], "Archie goes down")
		assert_eq(combat["outcome"], null)
		assert_eq(CombatRounds.decision_position(combat), 0, "the player's first pick is still to come")
	)

	run_case("all_moves_open_until_the_hp_lock_then_only_the_rewind", func():
		var combat := _start(_script())
		assert_eq(CombatRounds.move_block_reason(combat, "strike", 2), "", "open above the lock")
		assert_eq(CombatRounds.move_block_reason(combat, "legIt"), "", "Leg it too")
		assert_true(Combat.choose_move("guard")["ok"])
		assert_true(CombatRounds.script_locked(combat), "hit below 30")
		assert_eq(CombatRounds.script_prompt(combat), LOCK_PROMPT)
		for move_id in ["strike", "guard", "feint", "stun", "legIt"]:
			assert_eq(CombatRounds.move_block_reason(combat, move_id, 2), LOCK_PROMPT, "%s locked" % move_id)
		assert_eq(Combat.round_rewind_block_reason(), "", "the Rewind stays open")
		assert_eq(combat["outcome"], null, "nothing fires on its own")
		assert_eq(combat["script"]["phase"], CombatRounds.SCRIPT_PRE)
	)

	run_case("the_fight_cant_be_won_or_lost_or_fled_before_the_rewind", func():
		var combat := _start(_script(1))
		assert_true(Combat.choose_move("strike", 2)["ok"], "a Strike that would drop him")
		assert_eq(combat["combatants"][2]["hp"], 1, "he stays standing")
		assert_eq(combat["outcome"], null, "no win")
		combat = _start(_script())
		assert_true(Combat.choose_move("legIt")["ok"], "Leg it is tried")
		assert_eq(combat["outcome"], null, "it never gets away")
		assert_true(combat["combatants"][0]["hp"] >= 1)
	)

	run_case("tapping_the_rewind_plays_the_script_and_flees_back_to_the_event", func():
		var combat := _start(_script())
		Combat.choose_move("guard")
		assert_true(Combat.round_rewind()["ok"], "the player taps it")
		assert_eq(Loadout.slot(0), null, "the unit is spent")
		assert_eq(combat["outcome"], "fled")
		assert_eq(combat["script"]["phase"], CombatRounds.SCRIPT_POST)
		assert_true(not combat["combatants"][1]["koed"], "Archie never went down")
		assert_eq(combat["combatants"][0]["hp"], 30, "back to the fight's start")
		var kinds := _kinds(combat["log"])
		assert_true(kinds.has("guard"), "Archie guards")
		assert_true(kinds.has("timePearl"), "Archie throws the Pearl")
		assert_true(kinds.has("frozen"), "and the freeze shows")
		assert_eq(kinds[-1], "fled", "Leg it lands")
		assert_true(not kinds.slice(kinds.rfind("timePearl")).has("ko"), "no KO after the rewind")
		var xp: int = GameState.state["player"]["combatXP"]
		var result := Combat.exit_combat()
		assert_eq(result["nextScreen"], "event")
		assert_eq(GameState.state["currentScreen"], "event")
		assert_eq(GameState.state["event"]["cardIndex"], RESUME_CARD, "resumes at the script's card")
		assert_eq(GameState.state["player"]["combatXP"], xp + Combat.ROUND_XP_FLED, "normal fled XP")
		assert_eq(Loadout.slot(0), null, "the Rewind stays spent")
	)

	run_case("save_and_load_mid_fight_keep_the_lock_and_the_script", func():
		var combat := _start(_script())
		Combat.choose_move("guard")
		var text := SaveManager.export_string()
		assert_true(SaveManager.import_string(text)["ok"], "save loads")
		combat = GameState.state["combat"]
		assert_true(CombatRounds.script_locked(combat), "still locked")
		assert_true(combat["script"]["forcedHits"][0]["spent"], "the spent punch stays spent")
		assert_true(Combat.round_rewind()["ok"])
		assert_eq(combat["outcome"], "fled", "the script still plays")
	)

	run_case("op_validates_its_script_keys", func():
		var errors: Array[String] = []
		GameData._validate_effect_list([{ "op": "start_scripted_fight", "script": { "enemies": [] } }], "t", errors)
		assert_true(errors.size() >= 1, "missing keys flagged")
		errors = []
		GameData._validate_effect_list([{ "op": "start_scripted_fight", "script": _script() }], "t", errors)
		assert_eq(errors, [])
		GameData.EVENTS.erase(EVENT_ID)
	)

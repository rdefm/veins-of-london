extends "res://tests/test_base.gd"

# Demo fights (R§3.7b Demo fights): an event's start_demo_fight op plays a
# watch-only NPC-vs-NPC fight (a Feint L5 gym owner against Archie) round by
# round, the showcased autoguard and retaliate guaranteed, then resumes the
# event at the script's card with the player untouched.

const EVENT_ID := "test_demo_fight_event"
const RESUME_CARD := 2
const OWNER := 2
const ARCHIE := 1


func _script() -> Dictionary:
	return {
		"seed": 11, "rounds": 2, "label": "Sparring", "intro": ["The gym owner squares up."],
		"enemies": [{
			"name": "Gym Owner", "hpMax": 200, "attackMin": 6, "attackMax": 6, "level": 5, "speed": 99,
			"moveLevels": { "strike": 1, "guard": 1, "feint": 5, "stun": 1, "legIt": 1 },
			"plans": [[{ "move": "strike", "target": ARCHIE }, { "move": "feint", "target": ARCHIE }]],
		}],
		"allies": [{
			"name": "Archie", "hpMax": 200, "attackMin": 4, "attackMax": 4, "level": 1, "speed": 10,
			"moveLevels": { "strike": 1, "guard": 1, "feint": 1, "stun": 1, "legIt": 1 },
			"plans": [["guard", { "move": "strike", "target": OWNER }]],
		}],
		"procs": [{ "kind": "autoguard", "target": OWNER }, { "kind": "retaliate", "target": OWNER }],
		"resumeCard": RESUME_CARD,
	}


func _start(script: Dictionary) -> Dictionary:
	GameState.reset()
	GameState.state["player"]["loadout"]["slots"][0] = { "recipe": "rewind", "tier": 5 }
	GameData.EVENTS[EVENT_ID] = {
		"id": EVENT_ID,
		"cards": [
			{ "type": "narration", "label": null, "speaker": null, "text": "Setup" },
			{ "type": "narration", "label": null, "speaker": null, "text": "The spar" },
			{ "type": "narration", "label": null, "speaker": null, "text": "After" },
		],
	}
	Events.start_event(EVENT_ID)
	GameState.state["event"]["cardIndex"] = 1
	Events.apply_effects([{ "op": "start_demo_fight", "script": script }])
	return GameState.state["combat"]


func _kinds(beats: Array) -> Array:
	return beats.map(func(b): return b["kind"])


func run() -> void:
	run_case("op_opens_a_demo_fight_that_waits_for_its_first_round", func():
		var combat := _start(_script())
		assert_true(combat["active"] and GameState.state["currentScreen"] == "combat", "straight into the fight")
		assert_eq(combat["context"], Combat.CONTEXT_SCRIPTED)
		assert_true(CombatRounds.is_demo(combat))
		assert_eq(combat["log"], [], "nothing has played yet")
		assert_eq(combat["outcome"], null)
	)

	run_case("the_showcased_beats_fire_whatever_the_dice_say", func():
		for seed_value in [1, 2, 3, 4, 5, 6]:
			var script := _script()
			script["seed"] = seed_value
			var combat := _start(script)
			var kinds := _kinds(Combat.demo_step()["beats"])
			var guard_at := kinds.find("autoguard")
			assert_true(guard_at >= 0, "autoguard fires (seed %d)" % seed_value)
			assert_eq(kinds[guard_at + 1], "chip", "the Strike is a chip")
			assert_true(kinds.has("retaliate"), "and Archie is hit back (seed %d)" % seed_value)
			assert_eq(combat["outcome"], null, "one round is not the whole demo")
	)

	run_case("the_player_cant_act_or_be_changed", func():
		var combat := _start(_script())
		var player: Dictionary = GameState.state["player"]
		var before := [player["hp"], player["combatXP"], Loadout.slot(0)]
		assert_eq(CombatRounds.move_block_reason(combat, "strike", OWNER), CombatRounds.DEMO_REASON)
		assert_true(not Combat.choose_move("guard")["ok"], "no move accepted")
		assert_true(not Combat.round_rewind()["ok"], "no Rewind")
		assert_true(combat["combatants"][0]["koed"] and combat["playerKoed"], "the player sits it out")
		Combat.demo_step()
		Combat.demo_step()
		assert_eq([player["hp"], player["combatXP"], Loadout.slot(0)], before, "hp, XP and the Rewind untouched")
	)

	run_case("rounds_end_the_fight_fled_and_exit_resumes_the_event", func():
		var combat := _start(_script())
		var first := Combat.demo_step()
		assert_eq(first["outcome"], null)
		assert_eq(combat["round"], 2)
		var second := Combat.demo_step()
		assert_eq(second["outcome"], "fled", "ends after its last round")
		assert_true(not combat["combatants"][ARCHIE]["koed"] and not combat["combatants"][OWNER]["koed"], "no one drops")
		assert_eq(Combat.demo_step()["beats"], [], "nothing more to play")
		var xp: int = GameState.state["player"]["combatXP"]
		var result := Combat.exit_combat()
		assert_eq(result["nextScreen"], "event")
		assert_eq(GameState.state["currentScreen"], "event")
		assert_eq(GameState.state["event"]["cardIndex"], RESUME_CARD, "resumes at the script's card")
		assert_eq(GameState.state["player"]["combatXP"], xp, "no XP")
	)

	run_case("save_and_load_mid_demo_keep_its_position", func():
		_start(_script())
		Combat.demo_step()
		assert_true(SaveManager.import_string(SaveManager.export_string())["ok"], "save loads")
		var combat: Dictionary = GameState.state["combat"]
		assert_eq(combat["round"], 2)
		assert_true(combat["demo"]["procs"][0]["spent"], "the spent proc stays spent")
		assert_eq(Combat.demo_step()["outcome"], "fled")
	)

	run_case("op_validates_its_script_keys", func():
		var errors: Array[String] = []
		GameData._validate_effect_list([{ "op": "start_demo_fight", "script": { "enemies": [] } }], "t", errors)
		assert_true(errors.size() >= 1, "missing keys flagged")
		errors = []
		GameData._validate_effect_list([{ "op": "start_demo_fight", "script": _script() }], "t", errors)
		assert_eq(errors, [])
		GameData.EVENTS.erase(EVENT_ID)
	)

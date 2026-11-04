extends "res://tests/test_base.gd"

# The start_fight op (R§3.7b Event fights): data-driven enemy groups, entered
# through a forced Preparation, resuming the event at its win or lose card.

const EVENT_ID := "test_event_fight_event"
const WIN_CARD := 2
const LOSE_CARD := 3


func _start(enemies: Array, win: Variant = "won", lose: Variant = "lost") -> void:
	GameState.reset()
	GameData.EVENTS[EVENT_ID] = {
		"id": EVENT_ID,
		"cards": [
			{ "type": "narration", "label": null, "speaker": null, "text": "Setup" },
			{ "type": "narration", "label": null, "speaker": null, "text": "The fight" },
			{ "type": "narration", "key": "won", "label": null, "speaker": null, "text": "Won" },
			{ "type": "narration", "key": "lost", "label": null, "speaker": null, "text": "Lost" },
		],
	}
	Events.start_event(EVENT_ID)
	GameState.state["event"]["cardIndex"] = 1
	Events.apply_effects([{ "op": "start_fight", "enemies": enemies, "win": win, "lose": lose }])


func _errors(effect: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	GameData._validate_effect_list([effect], "t", errors)
	return errors


func _op(overrides: Dictionary = {}) -> Dictionary:
	var op := { "op": "start_fight", "enemies": [{ "template": "veinGuard", "count": 1, "level": 1 }], "win": "won", "lose": "lost" }
	op.merge(overrides, true)
	return op


func run() -> void:
	run_case("op_is_valid_and_validated_at_load", func():
		assert_true(GameData.VALID_EFFECT_OPS.has("start_fight"))
		assert_eq(_errors(_op()), [])
		assert_true(not _errors(_op({ "enemies": [] })).is_empty(), "empty list")
		assert_true(not _errors(_op({ "enemies": [{ "template": "nope", "count": 1, "level": 1 }] })).is_empty(), "unknown template")
		assert_true(not _errors(_op({ "enemies": [{ "squad": "nope", "count": 1, "level": 1 }] })).is_empty(), "unknown faction")
		assert_true(not _errors(_op({ "enemies": [{ "template": "veinGuard", "squad": "firm", "count": 1, "level": 1 }] })).is_empty(), "both kinds")
		assert_true(not _errors(_op({ "enemies": [{ "template": "veinGuard", "count": 0, "level": 1 }] })).is_empty(), "zero count")
		assert_true(not _errors(_op({ "enemies": [{ "template": "veinGuard", "count": 1 }] })).is_empty(), "no level")
		var no_lose := _op()
		no_lose.erase("lose")
		assert_true(not _errors(no_lose).is_empty(), "lose is required")
	)

	run_case("stat_blocks_are_rejected", func():
		assert_true(not _errors(_op({ "enemies": [{ "template": "veinGuard", "count": 1, "level": 1, "hpMax": 99 }] })).is_empty(), "group stat key")
		assert_true(not _errors(_op({ "enemies": [{ "name": "Boss", "hpMax": 50, "attackMin": 1, "attackMax": 2, "plans": [] }] })).is_empty(), "inline stat block")
		assert_true(not _errors(_op({ "script": { "enemies": [] } })).is_empty(), "script key")
	)

	run_case("entry_is_a_forced_prep_in_a_non_vein_event", func():
		_start([{ "template": "veinGuard", "count": 2, "level": 2 }])
		var prep: Dictionary = GameState.state["combatPrep"]
		assert_eq(prep["kind"], CombatPrep.KIND_EVENT_FIGHT)
		assert_true(prep["forced"], "no cancel")
		assert_true(not CombatPrep.cancel(), "cancel refused")
		assert_eq(GameState.state["currentScreen"], "combat_prep")
		assert_true(not GameState.state["combat"]["active"], "nothing starts before Fight")
	)

	run_case("template_group_spawns_count_at_level", func():
		_start([{ "template": "veinGuard", "count": 3, "level": 4 }])
		assert_true(CombatPrep.commit()["ok"])
		var combat: Dictionary = GameState.state["combat"]
		assert_eq(combat["context"], Combat.CONTEXT_EVENT_FIGHT)
		var enemies: Array = combat["enemies"] + combat["enemyQueue"]
		assert_eq(enemies.size(), 3)
		for enemy in enemies:
			assert_eq(int(enemy["level"]), 4)
			assert_eq(enemy["template"], "veinGuard")
	)

	run_case("squad_group_spawns_a_faction_squad_at_level_per_count", func():
		_start([{ "squad": "firm", "count": 2, "level": 3 }])
		CombatPrep.commit()
		var combat: Dictionary = GameState.state["combat"]
		var enemies: Array = combat["enemies"] + combat["enemyQueue"]
		assert_true(enemies.size() >= 4, "two squads of at least two")
		for enemy in enemies:
			assert_eq(int(enemy["level"]), 3)
	)

	run_case("groups_mix_templates_and_squads", func():
		_start([{ "template": "orichalchumDealer", "count": 1, "level": 1 }, { "squad": "collective", "count": 1, "level": 2 }])
		CombatPrep.commit()
		var combat: Dictionary = GameState.state["combat"]
		var enemies: Array = combat["enemies"] + combat["enemyQueue"]
		assert_eq(int(enemies[0]["level"]), 1)
		assert_eq(int(enemies[-1]["level"]), 2)
		assert_true(enemies.size() >= 3)
	)

	run_case("win_resumes_at_the_win_card", func():
		_start([{ "template": "veinGuard", "count": 1, "level": 1 }])
		CombatPrep.commit()
		GameState.state["combat"]["outcome"] = "win"
		assert_eq(Combat.exit_combat()["nextScreen"], "event")
		assert_eq(GameState.state["event"]["cardIndex"], WIN_CARD)
	)

	run_case("loss_and_flee_resume_at_the_lose_card", func():
		for outcome in ["loss", "fled"]:
			_start([{ "template": "veinGuard", "count": 1, "level": 1 }])
			CombatPrep.commit()
			GameState.state["combat"]["outcome"] = outcome
			assert_eq(Combat.exit_combat()["nextScreen"], "event")
			assert_eq(GameState.state["event"]["cardIndex"], LOSE_CARD, outcome)
	)

	run_case("cards_may_be_named_by_index", func():
		_start([{ "template": "veinGuard", "count": 1, "level": 1 }], WIN_CARD, LOSE_CARD)
		var args: Dictionary = GameState.state["combatPrep"]["args"]
		assert_eq(args["winCard"], WIN_CARD)
		assert_eq(args["loseCard"], LOSE_CARD)
	)

	run_case("unknown_card_key_starts_no_fight", func():
		_start([{ "template": "veinGuard", "count": 1, "level": 1 }], "nowhere", "lost")
		assert_eq(GameState.state["combatPrep"], null)
	)

	GameData.EVENTS.erase(EVENT_ID)

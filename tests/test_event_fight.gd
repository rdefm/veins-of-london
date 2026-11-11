extends "res://tests/test_base.gd"


const Fixtures := preload("res://tests/support/fixtures.gd")
# The start_fight op (R§3.7b Event fights): data-driven enemy groups, entered
# through a forced Preparation, resuming the event at its win or lose card.

const EVENT_ID := "test_event_fight_event"
const FIGHT_KEY := "fight"
const WIN_KEY := "won"
const LOSE_KEY := "lost"


func _start(enemies: Array, win: Variant = "won", lose: Variant = "lost") -> void:
	GameState.reset()
	GameData.EVENTS[EVENT_ID] = {
		"id": EVENT_ID,
		"cards": [
			{ "type": "narration", "label": null, "speaker": null, "text": "Setup" },
			{ "type": "narration", "label": null, "speaker": null, "text": "The fight", "key": FIGHT_KEY },
			{ "type": "narration", "key": WIN_KEY, "label": null, "speaker": null, "text": "Won" },
			{ "type": "narration", "key": LOSE_KEY, "label": null, "speaker": null, "text": "Lost" },
		],
	}
	Events.start_event(EVENT_ID)
	GameState.state["event"]["cardIndex"] = Events.card_index(EVENT_ID, FIGHT_KEY)
	Events.apply_effects([{ "op": "start_fight", "enemies": enemies, "win": win, "lose": lose }])


# Units of `recipe_key` in a raider pool: still held plus reserved by the enemies' plans.
func _pool_units(pool: Dictionary, recipe_key: String) -> int:
	return GuardKit.unit_count({ recipe_key: pool["items"].get(recipe_key, {}) }) + GuardKit.unit_count({ recipe_key: pool.get("reserved", {}).get(recipe_key, {}) })


# Resets and opens the test event with `ctx` as its context, on the fight card.
func _begin(ctx: Dictionary) -> void:
	_start([{ "template": "veinGuard", "count": 1, "level": 1 }])
	GameState.state["combatPrep"] = null
	GameState.state["event"]["context"] = ctx


# A faction vein on site "fv1" guarded by `guards` (level-1 counts), its kit and the faction's stock.
func _firm_vein(guards: int) -> void:
	var vein := {
		"id": "fv_fv1", "factionId": "firm", "oreType": "physics", "growth": 50, "rampantDays": 0,
		"security": "warded", "guards": FactionSim.stockpile_counts(guards), "alarmUpgrades": [], "claimedOnDay": 1,
		"district": "shoreditch", "siteId": "fv1", "level": 3, "developmentStreak": 0,
		"hospitability": { "tier": "fair", "bonuses": [] }, "kit": { "shield": 2 },
	}
	GameState.state["world"]["sites"] = [Fixtures.site_with_vein("fv1", vein)]
	GameState.state["factions"]["firm"]["holdings"]["items"]["shield"] = { "2": 3 }


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
		assert_eq(Events.current_card_key(), WIN_KEY)
	)

	run_case("loss_and_flee_resume_at_the_lose_card", func():
		for outcome in ["loss", "fled"]:
			_start([{ "template": "veinGuard", "count": 1, "level": 1 }])
			CombatPrep.commit()
			GameState.state["combat"]["outcome"] = outcome
			assert_eq(Combat.exit_combat()["nextScreen"], "event")
			assert_eq(Events.current_card_key(), LOSE_KEY, outcome)
	)

	run_case("cards_may_be_named_by_index", func():
		_start([{ "template": "veinGuard", "count": 1, "level": 1 }])
		var win_index: int = Events.card_index(EVENT_ID, WIN_KEY)
		var lose_index: int = Events.card_index(EVENT_ID, LOSE_KEY)
		_start([{ "template": "veinGuard", "count": 1, "level": 1 }], win_index, lose_index)
		var args: Dictionary = GameState.state["combatPrep"]["args"]
		assert_eq(args["winCard"], win_index)
		assert_eq(args["loseCard"], lose_index)
	)

	run_case("unknown_card_key_starts_no_fight", func():
		_start([{ "template": "veinGuard", "count": 1, "level": 1 }], "nowhere", "lost")
		assert_eq(GameState.state["combatPrep"], null)
	)

	run_case("kit_and_vein_keys_validate", func():
		var vein_group := { "template": "veinGuard", "guards": "vein", "level": 2 }
		assert_eq(_errors(_op({ "enemies": [vein_group] })), [])
		assert_true(not _errors(_op({ "enemies": [{ "template": "veinGuard", "guards": "vein", "count": 2, "level": 2 }] })).is_empty(), "guards and count")
		assert_true(not _errors(_op({ "enemies": [{ "template": "veinGuard", "guards": "all", "level": 2 }] })).is_empty(), "guards must be vein")
		assert_eq(_errors(_op({ "kit": "guardKit", "alertWaves": true })), [])
		assert_eq(_errors(_op({ "kit": "custom", "items": { "shield": { "2": 2 } } })), [])
		assert_true(not _errors(_op({ "kit": "custom" })).is_empty(), "custom needs items")
		assert_true(not _errors(_op({ "kit": "custom", "items": { "nope": { "1": 1 } } })).is_empty(), "unknown recipe")
		assert_true(not _errors(_op({ "kit": "custom", "items": { "shield": { "9": 1 } } })).is_empty(), "tier out of range")
		assert_true(not _errors(_op({ "kit": "guardKit", "items": { "shield": { "1": 1 } } })).is_empty(), "items need custom")
		assert_true(not _errors(_op({ "kit": "bogus" })).is_empty(), "unknown mode")
		for key in ["kit", "items", "loadout", "slots"]:
			assert_true(not _errors(_op({ "enemies": [{ "template": "veinGuard", "count": 1, "level": 1, key: {} }] })).is_empty(), "per-enemy " + key)
	)

	run_case("vein_sized_group_takes_the_vein_guards_less_this_events_adjustment", func():
		var group := { "template": "veinGuard", "guards": "vein", "level": 2 }
		_begin({ "site_id": "nowhere" })
		Events.apply_effects([_op({ "enemies": [group] })])
		assert_eq(GameState.state["combatPrep"], null, "no vein, no guards, no fight")
		_begin({ "site_id": "fv1" })
		_firm_vein(3)
		Events.add_raid_guards_down(1)
		Events.apply_effects([_op({ "enemies": [group] })])
		CombatPrep.commit()
		var combat: Dictionary = GameState.state["combat"]
		assert_eq((combat["enemies"] + combat["enemyQueue"]).size(), 2, "3 guards less 1 down")
		assert_eq(Cultivating.vein_guard_count(Sites.find_site("fv1")["factionVein"]), 3, "vein itself unchanged")
	)

	run_case("guard_kit_at_a_vein_is_the_veins_real_kit_and_settles_off_it", func():
		_begin({ "site_id": "fv1" })
		_firm_vein(2)
		Events.apply_effects([_op({ "kit": "guardKit" })])
		CombatPrep.commit()
		var combat: Dictionary = GameState.state["combat"]
		assert_eq(_pool_units(combat["raiderKit"], "shield"), 2, "capped at the vein's own kit of 2")
		combat["raiderKit"]["used"] = { "shield": { "2": 1 } }
		combat["outcome"] = "win"
		Combat.exit_combat()
		assert_eq(Sites.find_site("fv1")["factionVein"]["kit"], { "shield": 1 }, "vein allocation spent")
		assert_eq(GameState.state["factions"]["firm"]["holdings"]["items"]["shield"], { "2": 2 }, "faction stock spent")
	)

	run_case("guard_kit_at_a_stockpile_is_the_factions_defend_kit_and_settles_off_stock", func():
		_begin({ "faction_id": "firm" })
		GameState.state["factions"]["firm"]["holdings"]["items"]["shield"] = { "2": 3 }
		Events.apply_effects([_op({ "kit": "guardKit" })])
		CombatPrep.commit()
		var combat: Dictionary = GameState.state["combat"]
		assert_true(combat["raiderKit"]["items"].has("shield"), "faction defend kit")
		combat["raiderKit"]["used"] = { "shield": { "2": 1 } }
		combat["outcome"] = "loss"
		Combat.exit_combat()
		assert_eq(GameState.state["factions"]["firm"]["holdings"]["items"]["shield"], { "2": 2 })
	)

	run_case("guard_kit_with_no_vein_or_faction_starts_no_fight", func():
		_begin({})
		Events.apply_effects([_op({ "kit": "guardKit" })])
		assert_eq(GameState.state["combatPrep"], null)
	)

	run_case("custom_kit_applies_in_any_event_and_changes_no_stock", func():
		_begin({})
		var stock_before: Dictionary = GameState.state["factions"]["firm"]["holdings"]["items"].duplicate(true)
		var inv_before: Dictionary = GameState.state["player"]["inventory"].duplicate(true)
		Events.apply_effects([_op({ "kit": "custom", "items": { "shield": { "1": 2 } } })])
		CombatPrep.commit()
		var combat: Dictionary = GameState.state["combat"]
		assert_eq(_pool_units(combat["raiderKit"], "shield"), 2, "the authored two")
		combat["raiderKit"]["used"] = { "shield": { "1": 1 } }
		combat["outcome"] = "win"
		Combat.exit_combat()
		assert_eq(GameState.state["factions"]["firm"]["holdings"]["items"], stock_before, "faction stock untouched")
		assert_eq(GameState.state["player"]["inventory"], inv_before, "player stock untouched")
	)

	run_case("alert_waves_add_reinforcements_and_situational_mods_apply", func():
		_begin({ "site_id": "fv1" })
		_firm_vein(2)
		GameState.state["event"]["reinforce"] = { "ticks": 0, "length": 3, "arrived": true }
		var mods := [{ "if": { "cash": { "atLeast": 0 } }, "oneAtATime": true }]
		Events.apply_effects([_op({ "enemies": [{ "template": "veinGuard", "count": 1, "level": 2 }], "alertWaves": true, "situational": mods })])
		CombatPrep.commit()
		var combat: Dictionary = GameState.state["combat"]
		assert_eq(combat["enemies"].size() + combat["enemyQueue"].size(), 3, "1 + the 2 who have arrived")
		assert_eq(combat["enemies"].size(), 1, "oneAtATime")
	)

	GameData.EVENTS.erase(EVENT_ID)

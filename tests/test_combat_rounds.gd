extends "res://tests/test_base.gd"

# Live round fights (R§3.7b): a street mugging on CombatPrototype's rules
# core over state.combat -- opening from prep, the real player's stats and
# hp, the six moves' guard rules, Leg it, outcomes and the XP lump through
# exit_combat(), save/load mid-fight, the Gym card's curves and the combat
# screen hosting the round-fight screen. Rules detail lives in
# tests/test_combat_prototype.gd.


func _mugger(hp: int = 28) -> Dictionary:
	return {
		"name": "A mugger", "hp": hp, "hpMax": hp, "attackMin": 4, "attackMax": 10,
		"isMugging": true, "weapon": null, "ability": null, "evadeChance": 0.0,
		"speed": Combat.MUGGER_SPEED, "archetype": Combat.MUGGER_ARCHETYPE, "level": Combat.MUGGER_LEVEL,
	}


# A seeded street mugging against one mugger playing `plan` (an Array of
# rounds of move ids, every round targeting the player), fog off.
func _start(plan: Array, seed_value: int = 1, mugger_hp: int = 28) -> Dictionary:
	Combat._start_round_combat(Combat.CONTEXT_EVENT_MUGGING, null, [_mugger(mugger_hp)], [], "", [], null,
		{ "seed": seed_value, "fog": false, "enemyPlans": [plan] })
	return GameState.state["combat"]


func _kinds(beats: Array) -> Array:
	return beats.map(func(b): return b["kind"])


func _first(beats: Array, kind: String) -> Dictionary:
	for beat in beats:
		if beat["kind"] == kind:
			return beat
	return {}


func _row(screen: CombatPrototypeScreen, row_name: String) -> Button:
	var found: Button = null
	for node in screen._dock.find_children(row_name, "Button", true, false):
		if not node.is_queued_for_deletion():
			found = node
	return found


func run() -> void:
	run_case("street_mugging_from_prep_opens_a_round_fight_on_the_real_player", func():
		GameState.reset()
		var player: Dictionary = GameState.state["player"]
		player["combatSkill"] = 3
		player["hpMax"] = 120
		player["hp"] = 90
		CombatPrep.request(CombatPrep.KIND_STREET_MUGGING)
		assert_true(CombatPrep.commit()["ok"], "prep commits")
		var combat: Dictionary = GameState.state["combat"]
		assert_true(Combat.is_round_engine(combat), "round engine")
		assert_eq(combat["context"], Combat.CONTEXT_EVENT_MUGGING)
		assert_eq(GameState.state["currentScreen"], "combat")
		var you: Dictionary = combat["combatants"][CombatPrototype.PLAYER_INDEX]
		assert_eq(you["level"], 3, "player level from combatSkill")
		assert_eq(you["hpMax"], 120, "real hpMax")
		var attack := Combat.get_attack_range()
		assert_eq([you["attackMin"], you["attackMax"]], [attack["min"], attack["max"]], "real attack range")
		assert_eq(you["speed"], GameData.COMBAT_SPEED_BY_LEVEL[3], "speed curve")
		var enemy: Dictionary = combat["combatants"][1]
		assert_eq(enemy["archetype"], Combat.MUGGER_ARCHETYPE)
		assert_eq(enemy["level"], 1)
		assert_eq(enemy["speed"], Combat.MUGGER_SPEED, "level 1 keeps its own speed")
		assert_eq(enemy["template"], Combat.MUGGER_TEMPLATE_KEY)
		# Fog off the player's level: (.21 - .03 x 2 levels below) x 1.0.
		assert_almost_eq(CombatPrototype.unread_chance(combat, 1, 1), 0.15, 0.0001, "fog from player level")
		assert_true(CombatPrototype.decision_position(combat) >= 0 or combat["outcome"] != null, "paused for a pick")
	)

	run_case("harder_mugger_spawns_as_muggerV2_level_2", func():
		GameState.reset()
		var entry := Combat._spawn_mugger_instance(true)
		assert_eq(entry["archetype"], Combat.HARD_MUGGER_ARCHETYPE)
		assert_eq(entry["level"], Combat.HARD_MUGGER_LEVEL)
	)

	run_case("guarded_player_takes_chip_then_strikes_an_open_mugger_for_full", func():
		GameState.reset()
		var combat := _start([["strike", "strike"]])
		var opening: Dictionary = _first(combat["log"], "chip")
		assert_eq(opening.get("target", -1), CombatPrototype.PLAYER_INDEX, "the mugger's opening strike chips the Guarded player")
		var you: Dictionary = combat["combatants"][CombatPrototype.PLAYER_INDEX]
		assert_eq(you["hp"], you["hpMax"] - int(opening["dmg"]), "real hp spent")
		assert_eq(GameState.state["player"]["hp"], you["hp"], "player hp follows the fight")
		var result := Combat.choose_move("strike", 1)
		assert_true(result["ok"], "strike plays")
		var hit: Dictionary = _first(result["beats"], "hit")
		assert_eq(hit.get("actor", -1), CombatPrototype.PLAYER_INDEX, "full hit on the mugger left Open by its strike")
		assert_eq(int(hit["dmg"]), int(hit["roll"]) * (2 if hit["crit"] else 1), "full damage")
		var counter: Array = result["beats"].filter(func(b): return b["actor"] == 1 and b["kind"] == "hit")
		assert_eq(counter.size(), 1, "the mugger's second strike lands full on the now-Open player")
	)

	run_case("feint_opens_a_guarded_mugger", func():
		GameState.reset()
		var combat := _start([["guard", "guard"]])
		assert_eq(combat["combatants"][1]["guard"], CombatPrototype.GUARDED)
		var result := Combat.choose_move("feint", 1)
		var feint: Dictionary = _first(result["beats"], "feint")
		assert_true(not feint.is_empty(), "feint beat")
		assert_eq(feint["marks"][1]["guard"], CombatPrototype.OPEN, "the mugger stands Open after the Feint")
		assert_eq(combat["combatants"][1]["guard"], CombatPrototype.GUARDED, "its next Guard closes it again")
	)

	run_case("stun_on_an_open_mugger_drops_its_next_action", func():
		GameState.reset()
		_start([["strike", "guard"]])
		var result := Combat.choose_move("stun", 1)
		assert_true(_kinds(result["beats"]).has("stun"), "stun lands on the Open mugger")
		var lost: Dictionary = _first(result["beats"], "lost")
		assert_eq(lost.get("actor", -1), 1, "the mugger loses its Guard")
	)

	run_case("lure_exposes_the_first_mugger_to_attack", func():
		GameState.reset()
		var combat := _start([["guard", "strike"]])
		var result := Combat.choose_move("lure")
		assert_true(result["ok"], "lure plays across both actions")
		var sprung: Dictionary = _first(result["beats"], "exposed")
		assert_eq([sprung.get("actor", -1), sprung.get("target", -1)], [CombatPrototype.PLAYER_INDEX, 1], "the mugger's strike springs it")
		assert_eq(combat["combatants"][1]["exposedUntil"], 2, "Exposed through next round")
	)

	run_case("leg_it_success_flees_and_failure_loses_the_round", func():
		var fled := false
		var failed := false
		for seed_value in range(1, 80):
			if fled and failed:
				break
			GameState.reset()
			var combat := _start([["guard", "guard"]], seed_value)
			var xp: int = GameState.state["player"]["combatXP"]
			var result := Combat.choose_move("legIt")
			if result["outcome"] == "fled" and not fled:
				fled = true
				assert_eq(Combat.exit_combat()["nextScreen"], "event", "a fled street mugging resumes the event")
				assert_eq(GameState.state["player"]["combatXP"], xp, "Leg it earns no XP")
				assert_true(not GameState.state["combat"]["active"], "torn down")
			elif result["outcome"] == null and not failed:
				failed = true
				assert_true(_kinds(result["beats"]).has("fleeFailed"), "fail beat")
				assert_eq(combat["combatants"][CombatPrototype.PLAYER_INDEX]["guard"], CombatPrototype.OPEN, "left Open")
				assert_eq([combat["round"], CombatPrototype.decision_position(combat)], [2, 0], "the rest of the round's actions are lost")
		assert_true(fled and failed, "seeds cover both Leg it results")
	)

	run_case("win_pays_30_xp_and_resumes_the_event", func():
		GameState.reset()
		var combat := _start([["guard", "guard"]], 1, 1)
		var xp: int = GameState.state["player"]["combatXP"]
		var result := Combat.choose_move("strike", 1)
		assert_eq(result["outcome"], "win")
		var hp: int = combat["combatants"][CombatPrototype.PLAYER_INDEX]["hp"]
		assert_eq(Combat.exit_combat()["nextScreen"], "event")
		assert_eq(GameState.state["player"]["combatXP"], xp + Combat.ROUND_XP_WIN, "win +30")
		assert_eq(GameState.state["player"]["hp"], hp, "hp carried out of the fight")
		assert_true(not Combat.is_round_engine(GameState.state["combat"]), "torn down to the old shape")
	)

	run_case("loss_settles_ko_hp_and_pays_3_xp", func():
		GameState.reset()
		var player: Dictionary = GameState.state["player"]
		player["hp"] = 1
		var combat := _start([["strike", "strike"]])
		assert_eq(combat["outcome"], "loss", "the opening chip KOs a 1-hp player")
		assert_eq(player["hp"], maxi(1, GameState.round_epsilon(player["hpMax"] * Combat.PLAYER_KO_HP_FRACTION)), "KO hp")
		var xp: int = player["combatXP"]
		Combat.exit_combat()
		assert_eq(player["combatXP"], xp + Combat.ROUND_XP_LOSS, "loss +3")
	)

	run_case("save_mid_fight_resumes_at_the_same_pause", func():
		GameState.reset()
		Combat._start_round_combat(Combat.CONTEXT_EVENT_MUGGING, null, [_mugger(), _mugger()], [], "", [], null, { "seed": 7 })
		var combat: Dictionary = GameState.state["combat"]
		var rng_state: int = combat["rngState"]
		var pause := CombatPrototype.decision_position(combat)
		var text := SaveManager.export_string()
		var first := Combat.choose_move("strike", 1)
		var hps: Array = GameState.state["combat"]["combatants"].map(func(c): return c["hp"])
		assert_true(SaveManager.import_string(text)["ok"], "save loads")
		combat = GameState.state["combat"]
		assert_true(Combat.is_round_engine(combat), "still a round fight")
		assert_eq(combat["rngState"], rng_state, "RNG state survives exactly")
		assert_eq(CombatPrototype.decision_position(combat), pause, "same pause")
		var second := Combat.choose_move("strike", 1)
		assert_eq(second["beats"].map(func(b): return b["text"]), first["beats"].map(func(b): return b["text"]), "the pick replays identically")
		assert_eq(combat["combatants"].map(func(c): return c["hp"]), hps, "same hp after")
	)

	run_case("gym_card_shows_actions_per_round_and_crit", func():
		GameState.reset()
		var s := Combat.skill_summary()
		assert_eq(s["stats"]["actionsPerRound"], 2)
		assert_almost_eq(s["stats"]["critChance"], 0.03, 0.0001)
		assert_eq(s["nextStats"]["actionsPerRound"], GameData.COMBAT_PROTOTYPE["actionsPerRound"][2])
		var text := HqGymModal.stats_text(s["stats"])
		assert_true(text.contains("ACT 2") and text.contains("CRIT 3%"), "card text: %s" % text)
	)

	run_case("other_contexts_stay_on_the_old_engine", func():
		GameState.reset()
		Combat.start_archie_deal_mugging()
		assert_true(not Combat.is_round_engine(GameState.state["combat"]), "archie deal mugging")
		assert_true(GameState.state["combat"].has("turnCursor"), "old shape")
		GameState.reset()
		Combat.start_home_raid_combat()
		assert_true(not Combat.is_round_engine(GameState.state["combat"]), "home raid")
	)

	run_case("combat_screen_hosts_the_round_screen_and_plays_to_the_outcome", func():
		GameState.reset()
		GameState.state["player"]["loadout"]["slots"][0] = { "recipe": "timePearl", "tier": 1 }
		_start([["guard", "guard"]], 1, 1)
		var host := CombatScreen.new()
		host._ready()
		var screen: CombatPrototypeScreen = host._round_screen
		assert_true(screen != null and screen.live, "round screen hosted")
		screen._ready()
		for move_id in ["guard", "strike", "feint", "stun", "lure", "legIt"]:
			assert_true(_row(screen, "MoveRow_%s" % move_id) != null, "%s row" % move_id)
		var item := _row(screen, "ItemRow_0")
		assert_true(item != null and item.disabled, "real loadout slot shown, blocked")
		assert_true(_row(screen, "ItemRow_1") != null, "empty slot shown")
		assert_eq(Combat.round_item_block_reason(0), Combat.REASON_ROUND_ITEM_PENDING)
		assert_eq(Combat.round_item_block_reason(1), Combat.REASON_SLOT_EMPTY)
		_row(screen, "MoveRow_strike").pressed.emit()
		assert_eq(GameState.state["combat"]["outcome"], "win", "the pick resolves")
		var buttons: Array = screen._footer_holder.find_children("*", "Button", true, false).filter(func(b): return not b.is_queued_for_deletion())
		assert_true(buttons.any(func(b): return b.text == "✅ They've legged it"), "outcome button")
		Combat.exit_combat()
		assert_eq(GameState.state["currentScreen"], "event", "outcome hands off to exit_combat")
		host.free()
	)

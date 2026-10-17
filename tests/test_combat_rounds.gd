extends "res://tests/test_base.gd"

const Fixtures := preload("res://tests/support/fixtures.gd")

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
		"speed": Combat.MUGGER_SPEED, "archetype": Combat.MUGGER_ARCHETYPE, "level": 1,
	}


func _seeded() -> void:
	GameState.reset()
	Rng.set_seed(7)


# The live fight is a round fight in `context` whose every active enemy is
# at `level`, with the archetype `archetypes` names for its spawn template
# (every template, when `archetypes` is empty, just has one).
func _assert_enemies(context: String, archetypes: Dictionary, level: int) -> void:
	var combat: Dictionary = GameState.state["combat"]
	assert_true(Combat.is_round_engine(combat), "%s on the round engine" % context)
	assert_eq(combat["context"], context)
	var fighters: Array = combat["combatants"].filter(func(c): return c["side"] == CombatPrototype.SIDE_ENEMY)
	assert_eq(fighters.size(), combat["enemies"].size(), "every active enemy fights")
	for i in range(fighters.size()):
		var entry: Dictionary = combat["enemies"][i]
		assert_eq(fighters[i]["level"], level, "%s enemy %d level" % [context, i])
		assert_eq(fighters[i]["archetype"], entry["archetype"])
		if archetypes.is_empty():
			assert_true(GameData.COMBAT_PROTOTYPE["archetypes"].has(entry["archetype"]), "a real archetype")
		else:
			assert_eq(entry["archetype"], archetypes[entry["template"]], "%s %s archetype" % [context, entry["template"]])


# A seeded street mugging against one mugger playing `plan` (an Array of
# rounds of move ids, every round targeting the player), fog off.
func _start(plan: Array, seed_value: int = 1, mugger_hp: int = 28) -> Dictionary:
	Combat._start_round_combat(Combat.CONTEXT_EVENT_MUGGING, null, [_mugger(mugger_hp)], [], "", [], null,
		{ "seed": seed_value, "fog": false, "enemyPlans": [plan] })
	return GameState.state["combat"]


# A seeded round fight with `allies` (live ally dicts) against one mugger
# playing `plan`, its fog off unless `fog` (then `unread` per round).
func _start_with_allies(allies: Array, plan: Array, seed_value: int = 1, fog: bool = false, unread: Array = []) -> void:
	var config := { "seed": seed_value, "fog": fog, "enemyPlans": [plan] }
	if not unread.is_empty():
		config["enemyUnread"] = [unread]
	Combat._start_round_combat(Combat.CONTEXT_EVENT_MUGGING, null, [_mugger()], [], "", allies, null, config)


func _recruit(contact_id: String) -> void:
	GameState.state["contacts"][contact_id]["recruited"] = true


func _kinds(beats: Array) -> Array:
	return beats.map(func(b): return b["kind"])


func _first(beats: Array, kind: String) -> Dictionary:
	for beat in beats:
		if beat["kind"] == kind:
			return beat
	return {}


# A seeded street mugging (as _start()) with `units` ({ recipe, tier,
# multi? } or null) in the player's real loadout slots.
func _start_armed(units: Array, plan: Array, seed_value: int = 1, mugger_hp: int = 28) -> Dictionary:
	for i in range(units.size()):
		GameState.state["player"]["loadout"]["slots"][i] = units[i]
		if units[i] != null:
			GameState.state["player"]["loadout"]["lastRecipe"][i] = units[i]["recipe"]
	return _start(plan, seed_value, mugger_hp)


# A mugger slower than a level-1 player, so the player acts first at each
# action index.
func _slow_mugger(hp: int = 28) -> Dictionary:
	var mugger := _mugger(hp)
	mugger["speed"] = 1
	return mugger


# A seeded street mugging against `enemies` (live enemy dicts) playing
# `plans` with `units` in the player's real loadout slots; fog on when
# `unread` (per enemy, per round) is given, else off.
func _start_vs(enemies: Array, plans: Array, units: Array, seed_value: int = 1, unread: Array = []) -> Dictionary:
	for i in range(units.size()):
		GameState.state["player"]["loadout"]["slots"][i] = units[i]
	var config := { "seed": seed_value, "fog": not unread.is_empty(), "enemyPlans": plans }
	if not unread.is_empty():
		config["enemyUnread"] = unread
	Combat._start_round_combat(Combat.CONTEXT_EVENT_MUGGING, null, enemies, [], "", [], null, config)
	return GameState.state["combat"]


# A Strike beat's expected dmg from its roll and crit: chip on a Guarded
# target, then `factor` (the attacker's and target's anger).
func _strike_dmg(beat: Dictionary, factor: float) -> int:
	var dmg: int = int(beat["roll"])
	if beat["guarded"]:
		dmg = maxi(1, GameState.round_epsilon(dmg * 0.25))
	if beat["crit"]:
		dmg *= 2
	return GameState.round_epsilon(dmg * factor)


func _actor_beats(beats: Array, actor: int, kinds: Array) -> Array:
	return beats.filter(func(b): return int(b["actor"]) == actor and kinds.has(b["kind"]))


# The fight as a Rewind restores it: everything but the snapshot stack, the
# per-pick loadout copy and the used slots (the Rewinds' own payments).
func _fight_state(combat: Dictionary) -> Dictionary:
	var state: Dictionary = combat.duplicate(true)
	for key in ["snapshots", "loadoutSlots", "slotsUsed"]:
		state.erase(key)
	return state


# Every round: two Strikes aimed at the player.
func _strikes_at_player() -> Array:
	return [[{ "move": "strike", "target": CombatPrototype.PLAYER_INDEX }, { "move": "strike", "target": CombatPrototype.PLAYER_INDEX }]]


# A seeded street mugging on a 1-hp player who acts first, against a slow
# mugger striking the player, so the player's first Guard is lethal.
func _start_lethal(units: Array, allies: Array = [], live: Dictionary = {}) -> Dictionary:
	GameState.state["player"]["hp"] = 1
	for i in range(units.size()):
		GameState.state["player"]["loadout"]["slots"][i] = units[i]
	var ally_plans: Array = allies.map(func(_a): return [["guard", "guard"]])
	Combat._start_round_combat(Combat.CONTEXT_EVENT_MUGGING, null, [_slow_mugger(200)], [], "", allies, null,
		{ "seed": 1, "fog": false, "enemyPlans": [_strikes_at_player()], "allyPlans": ally_plans }, live)
	return GameState.state["combat"]


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
		assert_eq(entry["level"], 2, "R§3.7b table 2: harder mugger")
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

	# ── Every context on the round engine (R§3.7b tables 1-2) ──

	run_case("sale_mugging_runs_mugger_level_1_or_muggerV2_level_2_with_archie", func():
		_seeded()
		Combat.start_mugging()
		_assert_enemies(Combat.CONTEXT_MUGGING, { "mugger": Combat.MUGGER_ARCHETYPE }, 1)
		assert_eq(GameState.state["combat"]["combatants"][1]["template"], "archie", "archie fights")
		_seeded()
		Combat.start_mugging(true)
		_assert_enemies(Combat.CONTEXT_MUGGING, { "mugger": Combat.HARD_MUGGER_ARCHETYPE }, 2)
	)

	run_case("archie_deal_mugging_runs_mugger_level_1", func():
		_seeded()
		Combat.start_archie_deal_mugging()
		_assert_enemies(Combat.CONTEXT_ARCHIE_DEAL_MUGGING, { "mugger": Combat.MUGGER_ARCHETYPE }, 1)
	)

	run_case("raid_level_follows_combined_magnitude", func():
		for row in [[1, 1], [2, 2], [3, 3], [4, 3], [5, 4], [6, 4], [7, 5], [9, 5]]:
			_seeded()
			Combat.start_raid("v1", row[0], 1, "veinGuard")
			_assert_enemies(Combat.CONTEXT_RAID, { "veinGuard": "turtle" }, row[1])
		_seeded()
		Combat.start_raid("v1", 3, 1, "veinGuard")
		var guard: Dictionary = GameState.state["combat"]["combatants"][1]
		var entry: Dictionary = GameState.state["combat"]["enemies"][0]
		assert_eq(guard["hpMax"], int(entry["hpMax"]) + GameData.COMBAT_HP_BONUS_BY_LEVEL[3], "level 3 HP bonus on the unscaled template hp")
		assert_true(int(entry["hpMax"]) <= 35, "no magnitude hp scaling left on the entry")
		assert_eq(guard["speed"], 8 + GameData.COMBAT_SPEED_BY_LEVEL[3] - GameData.COMBAT_SPEED_BY_LEVEL[1], "speed rule")
	)

	run_case("event_raid_runs_on_the_round_engine_at_magnitude_level", func():
		_seeded()
		Combat.start_raid("v1", 2, 2, Combat.SCRAPPER_TEMPLATE_KEY, Combat.CONTEXT_EVENT_RAID)
		_assert_enemies(Combat.CONTEXT_EVENT_RAID, { Combat.SCRAPPER_TEMPLATE_KEY: "bruiser" }, 2)
		var combat: Dictionary = GameState.state["combat"]
		for i in range(2):
			assert_eq(combat["combatants"][1 + i]["template"], combat["enemies"][i]["variant"], "a scrapper keeps its variant sprite")
			assert_true(str(combat["combatants"][1 + i]["name"]).begins_with("Territorial Scrapper"), "and its name")
	)

	run_case("stockpile_raid_carries_its_raider_kit_and_faction", func():
		_seeded()
		Combat.start_stockpile_raid("firm", 5, 2, "orichalchumDealer")
		_assert_enemies(Combat.CONTEXT_EVENT_RAID, { "orichalchumDealer": "mugger" }, 4)
		var combat: Dictionary = GameState.state["combat"]
		assert_eq(combat["stockpileFactionId"], "firm")
		assert_eq(combat["raiderKit"], FactionSim.raider_kit("firm", "defend", 2), "the defend kit rides along for settlement")
	)

	run_case("faction_ambush_level_follows_the_ambushers_turf_tier", func():
		for row in [[Turf.TIER_NONE, 1], [Turf.TIER_FOOTHOLD, 2], [Turf.TIER_CONTROL, 3]]:
			_seeded()
			GameState.state["turf"]["shoreditch"] = { "controller": "", "shares": {}, "tiers": { "firm": row[0] } }
			Combat.start_faction_ambush("firm", "shoreditch")
			_assert_enemies(Combat.CONTEXT_FACTION_AMBUSH, { "veinGuard": "turtle", "orichalchumDealer": "mugger" }, row[1])
			assert_eq(GameState.state["combat"]["ambushFactionId"], "firm")
	)

	run_case("defend_vein_level_follows_combined_magnitude_and_keeps_the_guard_kit", func():
		_seeded()
		Combat.start_defend_vein("v1", 7)
		_assert_enemies(Combat.CONTEXT_DEFEND_VEIN, {}, 5)
		assert_true(GameState.state["combat"].has("guardKit"), "guard pool slot kept for settlement")
	)

	run_case("home_raid_runs_the_raider_as_a_level_1_bruiser", func():
		_seeded()
		Combat.start_home_raid_combat()
		_assert_enemies(Combat.CONTEXT_HOME_RAID, { Combat.HOME_RAIDER_TEMPLATE_KEY: "bruiser" }, 1)
		assert_eq(GameState.state["combat"]["onWin"], "homeRaidWon")
	)

	run_case("home_raid_hp_multiplier_lowers_starting_hp_only", func():
		_seeded()
		Combat.start_home_raid_combat({ "enemyHpMult": 0.7 })
		var raider: Dictionary = GameState.state["combat"]["combatants"][1]
		assert_eq([raider["hp"], raider["hpMax"]], [roundi(35 * 0.7), 35])
	)

	run_case("home_raid_enemy_first_leads_every_round_1_slot", func():
		_seeded()
		Combat.start_home_raid_combat()
		var combat: Dictionary = GameState.state["combat"]
		assert_true(combat["combatants"][0]["speed"] > combat["combatants"][1]["speed"], "the player is faster than the raider")
		assert_eq(CombatPrototype.timeline(combat)[0]["actor"], CombatPrototype.PLAYER_INDEX, "no mod: speed leads")
		_seeded()
		Combat.start_home_raid_combat({ "enemyFirst": true })
		combat = GameState.state["combat"]
		var order: Array = CombatPrototype.timeline(combat).map(func(e): return [e["index"], e["actor"]])
		assert_eq(order.slice(0, 4), [[0, 1], [0, 0], [1, 1], [1, 0]], "raider first at each slot, slots still alternate")
		assert_eq(CombatPrototype.next_round_timeline(combat)[0]["actor"], CombatPrototype.PLAYER_INDEX, "round 2 back to speed order")
	)

	run_case("home_alarm_defend_runs_the_raider_at_level_2", func():
		_seeded()
		Combat.start_home_alarm_defend_combat()
		_assert_enemies(Combat.CONTEXT_HOME_ALARM_DEFEND, { Combat.HOME_RAIDER_TEMPLATE_KEY: "bruiser" }, 2)
	)

	run_case("debug_launcher_runs_on_the_round_engine_at_the_picked_tier", func():
		_seeded()
		Combat.start_debug_combat(Combat.CONTEXT_RAID, "", 5, 1, "veinGuard", [])
		_assert_enemies(Combat.CONTEXT_RAID, { "veinGuard": "turtle" }, 4)
	)

	run_case("enemy_level_table_and_archetypes_are_validated_at_boot", func():
		var bad: Dictionary = GameData.snapshot().duplicate(true)
		bad["enemy_levels"]["veinMagnitude"][2]["level"] = 9
		bad["enemy_levels"]["veinMagnitude"][3]["magnitude"] = 2
		bad["enemy_levels"]["ambushTurf"].erase("control")
		bad["enemy_raid_guards"]["veinGuard"]["archetype"] = "nobody"
		bad["enemy_home_raid_raider"].erase("archetype")
		var errors := " | ".join(GameData.validate_tables(bad))
		for needle in ["veinMagnitude[2].level", "veinMagnitude[3].magnitude", "ambushTurf.control", "raidGuards.veinGuard.archetype", "homeRaidRaider"]:
			assert_true(errors.contains(needle), "flags %s: %s" % [needle, errors])
		assert_eq(GameData.validate_tables(GameData.snapshot()).filter(func(e): return e.contains("enemyLevels") or e.contains("archetype")), [], "shipped data clean")
	)

	run_case("combat_screen_hosts_the_round_screen_and_plays_to_the_outcome", func():
		GameState.reset()
		GameState.state["player"]["loadout"]["slots"][0] = { "recipe": "rewind", "tier": 1 }
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
		assert_eq(Combat.round_item_block_reason(0), Combat.REASON_SLOT_REWIND)
		assert_eq(Combat.round_item_block_reason(1), Combat.REASON_SLOT_EMPTY)
		_row(screen, "MoveRow_strike").pressed.emit()
		assert_eq(GameState.state["combat"]["outcome"], "win", "the pick resolves")
		var buttons: Array = screen._footer_holder.find_children("*", "Button", true, false).filter(func(b): return not b.is_queued_for_deletion())
		assert_true(buttons.any(func(b): return b.text == "✅ They've legged it"), "outcome button")
		Combat.exit_combat()
		assert_eq(GameState.state["currentScreen"], "event", "outcome hands off to exit_combat")
		host.free()
	)

	run_case("time_pearl_from_real_stock_freezes_at_tier_power_and_refills", func():
		GameState.reset()
		var combat := _start_armed([{ "recipe": "timePearl", "tier": 3 }], [["strike", "strike"]])
		Crafting.inventory_add("timePearl", 2, 1)
		var entry: Dictionary = combat["combatants"][CombatPrototype.PLAYER_INDEX]["loadout"][0]
		assert_eq([entry["item"], entry["tier"], entry["power"], entry["sourceSlot"]], ["timePearl", 3, 3, 0], "real slot at its tier's power")
		var result := Combat.use_slot(0)
		assert_true(result["ok"], "use_slot plays it as a pick")
		assert_true(_kinds(result["beats"]).has("timePearl"), "freeze beat")
		var mugger: Dictionary = combat["combatants"][1]
		# The mugger's second action drops; two more of its three stay lost.
		assert_eq(_first(result["beats"], "frozen").get("actor", -1), 1, "its next action frozen")
		assert_eq(mugger["frozenActions"], 2, "power 3 - 1 spent")
		assert_true(CombatPrototype.is_open(combat, mugger), "Open while frozen")
		assert_eq(CombatPrototype.decision_position(combat), 1, "one action, the next pick is the player's second")
		assert_eq(Loadout.slot(0), null, "real unit consumed")
		assert_eq(combat["slotsUsed"], [0], "marked for settlement")
		combat["outcome"] = "fled"
		Combat.exit_combat()
		assert_eq(Loadout.slot(0), { "recipe": "timePearl", "tier": 2 }, "refilled from stock")
	)

	run_case("black_hole_pulls_through_guard_and_drops_actions", func():
		GameState.reset()
		var combat := _start_armed([{ "recipe": "blackHole", "tier": 2 }], [["guard", "guard"]])
		var mugger: Dictionary = combat["combatants"][1]
		assert_eq(mugger["guard"], CombatPrototype.GUARDED)
		var result := Combat.choose_item(0)
		assert_true(result["ok"])
		assert_eq(int(_first(result["beats"], "pull")["dmg"]), 8, "tier 2 power, guard ignored")
		assert_eq(mugger["hp"], 20)
		# 1 + floor(8 / 8) = 2 actions lost; its second action this round is one.
		assert_eq(_first(result["beats"], "lost").get("actor", -1), 1)
		assert_eq(mugger["actionsLost"], 1)
		assert_eq(combat["combatants"][CombatPrototype.PLAYER_INDEX]["guard"], CombatPrototype.GUARDED, "user's guard unchanged")
	)

	run_case("blast_hits_through_guard_and_boosts_the_next_leg_it_once", func():
		var boosted := false
		for seed_value in range(1, 200):
			GameState.reset()
			var combat := _start_armed([{ "recipe": "blast", "tier": 2 }], [["guard", "guard"]], seed_value)
			var result := Combat.choose_item(0, 1)
			assert_eq(int(_first(result["beats"], "blast")["dmg"]), 6, "tier 2 power on a Guarded mugger")
			var you: Dictionary = combat["combatants"][CombatPrototype.PLAYER_INDEX]
			assert_almost_eq(float(you["fleeBoost"]), 0.9, 0.0001, "Leg it boost armed")
			var plain: Dictionary = combat.duplicate(true)
			plain["combatants"][CombatPrototype.PLAYER_INDEX]["fleeBoost"] = 0.0
			var with_boost := CombatPrototype.play_pick(combat, { "move": "legIt", "target": -1 }, Combat.ROUND_SNAPSHOT_STACK)
			var without := CombatPrototype.play_pick(plain, { "move": "legIt", "target": -1 }, Combat.ROUND_SNAPSHOT_STACK)
			assert_eq(float(you["fleeBoost"]), 0.0, "spent on the one Leg it")
			if with_boost["outcome"] == "fled" and without["outcome"] == null:
				boosted = true
				break
		assert_true(boosted, "the same roll fails at 0.65 and flees at 0.90")
	)

	run_case("shield_holds_guarded_whatever_the_moves", func():
		GameState.reset()
		var combat := _start_armed([{ "recipe": "shield", "tier": 2 }], [["guard", "guard"]])
		assert_true(Combat.choose_item(0)["ok"])
		var you: Dictionary = combat["combatants"][CombatPrototype.PLAYER_INDEX]
		assert_eq(you["shield"], 4, "tier 2 pool")
		assert_true(Combat.choose_move("strike", 1)["ok"])
		assert_eq(you["guard"], CombatPrototype.OPEN, "the strike opens its own guard")
		assert_true(not CombatPrototype.is_open(combat, you), "but the pool keeps it Guarded")
	)

	run_case("enhancement_powder_adds_an_action_this_round", func():
		GameState.reset()
		var combat := _start_armed([{ "recipe": "enhancementPowder", "tier": 5 }], [["guard", "guard"]])
		var base := CombatPrototype.actions_per_round(combat["combatants"][CombatPrototype.PLAYER_INDEX])
		assert_true(Combat.choose_item(0)["ok"])
		assert_eq(CombatPrototype.actions_this_round(combat, CombatPrototype.PLAYER_INDEX), base + 1, "extra action this round")
		assert_eq(CombatPrototype.actions_next_round(combat, CombatPrototype.PLAYER_INDEX), base + 1, "power 3 runs two rounds")
		GameState.reset()
		combat = _start_armed([{ "recipe": "enhancementPowder", "tier": 1 }], [["guard", "guard"]])
		assert_true(Combat.choose_item(0)["ok"])
		assert_eq(CombatPrototype.actions_this_round(combat, CombatPrototype.PLAYER_INDEX), base + 1)
		assert_eq(CombatPrototype.actions_next_round(combat, CombatPrototype.PLAYER_INDEX), base, "power 1, one round")
	)

	run_case("prophets_breath_gives_sight_from_resolution", func():
		GameState.reset()
		GameState.state["player"]["loadout"]["slots"][0] = { "recipe": "prophetsBreath", "tier": 4 }
		Combat._start_round_combat(Combat.CONTEXT_EVENT_MUGGING, null, [_mugger()], [], "", [], null,
			{ "seed": 1, "fog": true, "enemyPlans": [[["guard", "guard"]]], "enemyUnread": [[[false, true]]] })
		var combat: Dictionary = GameState.state["combat"]
		assert_true(not CombatPrototype.is_read(combat, 1, 1), "fogged before")
		assert_true(Combat.choose_item(0)["ok"])
		assert_eq(combat["combatants"][CombatPrototype.PLAYER_INDEX]["sightUntil"], 3, "power 2 rounds after this one")
		assert_true(CombatPrototype.has_sight(combat))
		assert_true(not CombatPrototype.enemy_intents(combat, 1, true).is_empty(), "next round read")
	)

	run_case("healing_burst_heals_self_or_an_ally", func():
		GameState.reset()
		_recruit("archie")
		GameState.state["contacts"]["archie"]["combatHp"] = 10
		GameState.state["player"]["loadout"]["slots"][0] = { "recipe": "healingBurst", "tier": 2 }
		GameState.state["player"]["loadout"]["slots"][1] = { "recipe": "healingBurst", "tier": 1 }
		_start_with_allies([Contacts.build_combat_ally("archie")], [["guard", "guard"]])
		var combat: Dictionary = GameState.state["combat"]
		var archie: Dictionary = combat["combatants"][1]
		var before: int = archie["hp"]
		var result := Combat.choose_item(0, 1)
		assert_eq(int(_first(result["beats"], "heal")["amount"]), 8, "tier 2 on archie")
		assert_eq(archie["hp"], before + 8)
		var you: Dictionary = combat["combatants"][CombatPrototype.PLAYER_INDEX]
		you["hp"] = you["hpMax"] - 3
		result = Combat.choose_item(1)
		assert_eq(int(_first(result["beats"], "healSelf")["amount"]), 3, "self by default, capped at hpMax")
		assert_eq(GameState.state["player"]["hp"], you["hpMax"], "real hp follows")
	)

	run_case("be_a_lady_equips_and_gives_max_rolls_from_resolution", func():
		GameState.reset()
		Crafting.inventory_add("beALady", 4, 1)
		assert_true(Loadout.equip(0, "beALady", 4)["ok"], "player can equip it")
		assert_true(not Loadout.is_equippable("beALady", "archie"), "allies can't")
		var combat := _start([["guard", "guard"]])
		var you: Dictionary = combat["combatants"][CombatPrototype.PLAYER_INDEX]
		assert_true(not CombatPrototype.has_lady(combat, you), "not before use")
		assert_true(Combat.choose_item(0)["ok"])
		assert_eq(you["ladyUntil"], 2, "power 2: this round and next")
		assert_eq(CombatPrototype.damage_range(combat, CombatPrototype.PLAYER_INDEX), [you["attackMax"], you["attackMax"]], "max rolls")
		assert_almost_eq(float(you["ladyCrit"]), 0.333333, 0.0001, "1/3 crit")
		assert_eq(Loadout.slot(0), null, "real unit consumed")
	)

	run_case("multi_blast_hits_every_living_enemy", func():
		GameState.reset()
		GameState.state["player"]["loadout"]["slots"][0] = { "recipe": "blast", "tier": 3, "multi": true }
		Combat._start_round_combat(Combat.CONTEXT_EVENT_MUGGING, null, [_mugger(), _mugger()], [], "", [], null,
			{ "seed": 1, "fog": false, "enemyPlans": [[["guard", "guard"]], [["guard", "guard"]]] })
		var result := Combat.choose_item(0)
		assert_true(result["ok"], "no target pick needed")
		var hits: Array = result["beats"].filter(func(b): return b["kind"] == "blast")
		assert_eq(hits.map(func(b): return [b["target"], b["dmg"]]), [[1, 8], [2, 8]], "full power on each")
	)

	run_case("carry_in_sight_and_lady_apply_from_round_1", func():
		GameState.reset()
		var expires := ActiveEffects.absolute_block() + 1
		GameState.state["player"]["activeEffects"] = [
			{ "item": "prophetsBreath", "level": 1, "expiresAtBlock": expires },
			{ "item": "beALady", "level": 1, "expiresAtBlock": expires },
		]
		Combat._start_round_combat(Combat.CONTEXT_EVENT_MUGGING, null, [_mugger()], [], "", [], null,
			{ "seed": 1, "fog": true, "enemyPlans": [[["guard", "guard"]]], "enemyUnread": [[[true, true]]] })
		var combat: Dictionary = GameState.state["combat"]
		assert_true(CombatPrototype.is_read(combat, 1, 1), "sight from round 1")
		var you: Dictionary = combat["combatants"][CombatPrototype.PLAYER_INDEX]
		assert_eq(CombatPrototype.damage_range(combat, CombatPrototype.PLAYER_INDEX), [you["attackMax"], you["attackMax"]], "max rolls")
		assert_almost_eq(float(you["ladyCrit"]), 0.333333, 0.0001, "1/3 crit")
		for i in range(4):
			Combat.choose_move("guard")
		assert_true(combat["round"] >= 3 and CombatPrototype.has_sight(combat) and CombatPrototype.has_lady(combat, you), "whole fight")
		assert_true(ActiveEffects.prophets_breath_active(), "still blocks ambushes")
		GameState.reset()
		_start([["guard", "guard"]])
		assert_true(not CombatPrototype.has_sight(GameState.state["combat"]), "none without an active effect")
	)

	run_case("empty_or_ineligible_slots_show_a_block_reason", func():
		GameState.reset()
		_start_armed([{ "recipe": "failsafe", "tier": 1 }, null], [["guard", "guard"]])
		assert_eq(Combat.round_item_block_reason(0), Combat.REASON_SLOT_REACTIVE)
		assert_eq(Combat.round_item_block_reason(1), Combat.REASON_SLOT_EMPTY)
		assert_true(not Combat.choose_item(1)["ok"], "empty refused")
		GameState.reset()
		_start_armed([{ "recipe": "healingBurst", "tier": 1 }, { "recipe": "rewind", "tier": 1 }], [["guard", "guard"]])
		assert_eq(Combat.round_item_block_reason(0, 1), "Pick a target.", "no healing the mugger")
		assert_eq(Combat.round_item_block_reason(0), "", "self is fine")
		assert_eq(Combat.round_item_block_reason(1), Combat.REASON_SLOT_REWIND)
	)

	run_case("live_dock_item_row_plays_the_real_slot", func():
		GameState.reset()
		_start_armed([{ "recipe": "blast", "tier": 1 }], [["guard", "guard"]], 1, 4)
		var host := CombatScreen.new()
		host._ready()
		var screen: CombatPrototypeScreen = host._round_screen
		screen._ready()
		var item := _row(screen, "ItemRow_0")
		assert_true(item != null and not item.disabled, "usable row")
		item.pressed.emit()
		assert_eq(GameState.state["combat"]["outcome"], "win", "the blast drops the 4-hp mugger")
		assert_eq(Loadout.slot(0), null, "real unit spent")
		host.free()
	)

	run_case("allies_fight_at_their_table_3_level", func():
		GameState.reset()
		_recruit("archie")
		assert_eq(Contacts.build_combat_ally("archie")["level"], 2, "archie's combat-kit level")
		GameState.state["contacts"]["archie"]["combatSkill"] = 4
		assert_eq(Contacts.build_combat_ally("archie")["level"], 4, "own combatSkill wins")
		GameState.state["contacts"]["archie"].erase("combatSkill")
		assert_eq(Combat.build_guard_ally()["level"], 1, "hired guard's authored level")
		var muscle: Dictionary = GameData.FACTION_PERKS["factions"]["firm"]["partner"][0]
		assert_eq(int(muscle["params"]["ally"]["level"]), 2, "firm muscle's authored level")
		var guard := Combat.build_guard_ally()
		_start_with_allies([Contacts.build_combat_ally("archie"), guard, Combat.build_guard_ally()], [["guard", "guard"]])
		var combat: Dictionary = GameState.state["combat"]
		var archie: Dictionary = combat["combatants"][1]
		assert_eq(archie["side"], CombatPrototype.SIDE_ALLY)
		assert_eq(archie["level"], 2)
		assert_eq(archie["hpMax"], 50, "level 2 keeps authored hp")
		assert_eq([archie["attackMin"], archie["attackMax"]], [6, 11], "attack bonus at level 2")
		assert_eq(archie["speed"], 9 + GameData.COMBAT_SPEED_BY_LEVEL[2] - GameData.COMBAT_SPEED_BY_LEVEL[1], "speed rule")
		assert_eq(archie["template"], "archie", "contact sprite")
		var hired: Dictionary = combat["combatants"][2]
		assert_eq(hired["level"], 1)
		assert_eq(hired["speed"], int(guard["speed"]), "level 1 keeps its own speed")
		assert_eq(hired["template"], "", "no contact sprite")
		assert_eq(combat["allies"].size(), 2, "two friendly places beside the player")
		assert_eq(combat["allyQueue"].size(), 1, "the third waits")
		assert_eq(combat["combatants"][3]["side"], CombatPrototype.SIDE_ENEMY, "queued ally isn't a combatant")
	)

	run_case("ally_plans_read_and_react_to_read_intents_only", func():
		GameState.reset()
		_recruit("archie")
		# The mugger strikes archie twice; the second strike is unread.
		var strikes := [{ "move": "strike", "target": 1 }, { "move": "strike", "target": 1 }]
		_start_with_allies([Contacts.build_combat_ally("archie")], [strikes], 3, true, [[false, true]])
		var combat: Dictionary = GameState.state["combat"]
		assert_eq(CombatPrototype.decision_position(combat), 0, "paused on the player's first pick")
		var plan: Array = combat["combatants"][1]["plan"]
		assert_eq(plan.size(), 2, "ally plan committed before the pick")
		assert_true(CombatPrototype.is_read(combat, 1, 0) and CombatPrototype.is_read(combat, 1, 1), "ally plans always read")
		assert_eq(plan[0]["move"], "guard", "guards the read strike")
		assert_eq(plan[1]["move"], "strike", "an unread strike isn't guarded against")
		assert_eq(int(plan[1]["target"]), 2, "strikes the mugger left Open by its read strike")
	)

	run_case("ally_loadout_spends_real_stock_and_refills_at_settlement", func():
		GameState.reset()
		_recruit("archie")
		Crafting.inventory_add("healingBurst", 1, 1)
		assert_true(Loadout.equip(0, "healingBurst", 1, "archie")["ok"], "equip archie")
		Crafting.inventory_add("healingBurst", 2, 1)
		GameState.state["contacts"]["archie"]["combatHp"] = 10
		_start_with_allies([Contacts.build_combat_ally("archie")], [["guard", "guard"]])
		var combat: Dictionary = GameState.state["combat"]
		var archie: Dictionary = combat["combatants"][1]
		assert_eq(archie["loadout"].size(), 1, "real slot carried in")
		assert_eq(archie["loadout"][0]["power"], int(Crafting.effect_power("healingBurst", 1)), "unit's tier power")
		assert_eq(archie["plan"][0]["move"], "healingBurst", "heals itself below the threshold")
		assert_true(Combat.choose_move("guard")["ok"], "player pick")
		assert_true(archie["loadout"][0]["used"], "spent on resolution")
		assert_eq(combat["allies"][0]["slotsUsed"], [0], "real slot marked for settlement")
		assert_eq(combat["allies"][0]["hp"], archie["hp"], "live ally hp follows")
		combat["outcome"] = "fled"
		Combat.exit_combat()
		assert_eq(Loadout.slot(0, "archie"), { "recipe": "healingBurst", "tier": 2 }, "refilled from stock")
		assert_eq(int(GameState.state["player"]["inventory"]["healingBurst"].get("2", 0)), 0, "stock spent on refill")
	)

	run_case("prep_recruit_order_is_the_fight_ally_order", func():
		GameState.reset()
		_recruit("archie")
		_recruit("james")
		CombatPrep.request(CombatPrep.KIND_HQ_DEFEND)
		assert_eq(CombatPrep.pending()["args"]["allyIds"], ["archie", "james"], "contact order by default")
		assert_true(CombatPrep.move_recruit("james", -1), "reorder")
		var ids := CombatPrep.chosen_recruits(CombatPrep.KIND_HQ_DEFEND, CombatPrep.pending()["args"])
		_start_with_allies(Combat._gather_defend_allies([], ids), [["guard", "guard"]])
		var combat: Dictionary = GameState.state["combat"]
		assert_eq(combat["allies"].map(func(a): return a["contactId"]), ["james", "archie"])
		assert_eq(combat["combatants"][1]["template"], "james", "first recruit first")
		assert_eq(combat["combatants"][2]["template"], "archie")
	)

	run_case("an_ally_ko_starts_its_contact_cooldown", func():
		GameState.reset()
		_recruit("archie")
		GameState.state["contacts"]["archie"]["combatHp"] = 1
		var strikes := [{ "move": "strike", "target": 1 }, { "move": "strike", "target": 1 }]
		# Archie (speed 11) and the mugger act before the player's first
		# pick; even a chip takes his last hp.
		_start_with_allies([Contacts.build_combat_ally("archie")], [strikes])
		var combat: Dictionary = GameState.state["combat"]
		assert_true(combat["combatants"][1]["koed"], "archie down")
		assert_true(combat["allies"][0]["koed"], "live ally KO'd")
		assert_true(Contacts.can_join_combat("archie"), "no cooldown while a Rewind could undo it")
		Combat.exit_combat()
		assert_true(not Contacts.can_join_combat("archie"), "cooldown started at the fight's end")
	)

	run_case("panic_turns_bolt_or_cower_and_read_as_panic", func():
		var seen := { "bolt": false, "cower": false }
		for seed_value in range(1, 100):
			GameState.reset()
			# Tier 1: power 2. The mugger's second action is fogged.
			var combat := _start_vs([_slow_mugger()], [[["strike", "strike"]]], [{ "recipe": "panic", "tier": 1 }], seed_value, [[[false, true]]])
			var result := Combat.choose_item(0, 1)
			assert_eq(_first(result["beats"], "panic").get("target", -1), 1, "lands on the mugger")
			var mugger: Dictionary = combat["combatants"][1]
			if _kinds(result["beats"]).has("bolt"):
				assert_true(mugger["koed"] and mugger["hp"] == 0, "bolting is a KO")
				assert_eq(combat["outcome"], "win", "the last enemy gone wins it")
				seen["bolt"] = true
			else:
				assert_true(_kinds(result["beats"]).has("cower"), "else it cowers")
				assert_eq(mugger["guard"], CombatPrototype.OPEN, "cowering leaves it Open")
				assert_eq(mugger["panicActions"], 1, "one panic turn left")
				assert_true(CombatPrototype.is_read(combat, 1, 1), "the fogged action reads")
				var intent: Dictionary = CombatPrototype.enemy_intents(combat, 1)[1]
				assert_eq([intent["move"], intent["name"], intent.get("status", false)], ["panic", "Panic", true], "as a panic intent")
				assert_eq(CombatPrototype.guard_preview(combat, 1)[2], CombatPrototype.OPEN, "previewed Open")
				assert_eq(GameState.state["player"]["hp"], GameState.state["player"]["hpMax"], "no strike landed")
				seen["cower"] = true
			if seen["bolt"] and seen["cower"]:
				break
		assert_true(seen["bolt"] and seen["cower"], "both outcomes over the seeds")
	)

	run_case("a_removed_action_doesnt_tick_a_status", func():
		GameState.reset()
		var combat := _start_vs([_slow_mugger()], [[["guard", "guard"]]], [])
		var mugger: Dictionary = combat["combatants"][1]
		mugger["raptureActions"] = 1
		mugger["actionsLost"] = 1
		assert_eq(CombatPrototype.status_turn(combat, 1, 0), "", "the lost action isn't the rapture turn")
		assert_eq(CombatPrototype.status_turn(combat, 1, 1), CombatPrototype.STATUS_RAPTURE, "the next one is")
		Combat.choose_move("guard")
		assert_eq(mugger["raptureActions"], 1, "still pending after the loss")
	)

	run_case("pans_rapture_idles_its_actions_open", func():
		GameState.reset()
		var combat := _start_vs([_slow_mugger()], [[["strike", "strike"]]], [{ "recipe": "pansRapture", "tier": 1 }])
		var result := Combat.choose_item(0, 1)
		var mugger: Dictionary = combat["combatants"][1]
		assert_true(_kinds(result["beats"]).has("enraptured"), "idles")
		assert_eq(mugger["guard"], CombatPrototype.OPEN, "idle leaves it Open")
		assert_eq(CombatPrototype.enemy_intents(combat, 1)[1]["name"], "Rapture", "read rapture intent")
		result = Combat.choose_move("guard")
		assert_eq(mugger["raptureActions"], 0, "power 2 spent over two actions")
		assert_eq(GameState.state["player"]["hp"], GameState.state["player"]["hpMax"], "no strikes all round")
		assert_eq(CombatPrototype.enemy_intents(combat, 1)[0]["move"], "strike", "round 2 plays its own plan")
		assert_eq(Loadout.slot(0), null, "real unit consumed")
	)

	run_case("panger_scales_dealt_and_taken_by_phase_then_ends", func():
		GameState.reset()
		# Tier 2: X = 50.
		var combat := _start_vs([_slow_mugger(200)], [[["strike", "strike"]]], [{ "recipe": "panger", "tier": 2 }])
		var result := Combat.choose_item(0, 1)
		var mugger: Dictionary = combat["combatants"][1]
		assert_eq([mugger["angerPct"], mugger["fury"]], [50, false], "25 x tier")
		var swing: Dictionary = _actor_beats(result["beats"], 1, ["hit", "chip"])[0]
		assert_eq(int(swing["dmg"]), _strike_dmg(swing, 1.5), "first phase deals +50%")
		assert_eq(mugger["angerActions"], 3, "ticked by its own action")
		assert_eq(CombatPrototype.status_badges(mugger), ["Anger +50%"], "badge")
		assert_eq(CombatPrototype.stage_marks(combat)[1]["badges"], ["Anger +50%"], "on the stage")
		result = Combat.choose_move("strike", 1)
		var hit: Dictionary = _actor_beats(result["beats"], 0, ["hit", "chip"])[0]
		assert_eq(int(hit["dmg"]), _strike_dmg(hit, 0.5), "and takes -50%")
		assert_eq(mugger["angerActions"], 2)
		assert_almost_eq(CombatPrototype.anger_factor(mugger, true), 0.5, 0.0001, "second phase deals -50%")
		assert_almost_eq(CombatPrototype.anger_factor(mugger, false), 1.5, 0.0001, "takes +50%")
		assert_eq(CombatPrototype.status_badges(mugger), ["Anger −50%"])
		Combat.choose_move("guard")
		result = Combat.choose_move("guard")
		assert_true(_kinds(result["beats"]).has("calm"), "comes down after four actions")
		assert_eq([mugger["angerActions"], mugger["angerPct"]], [0, 0])
		assert_eq(CombatPrototype.anger_factor(mugger, true), 1.0)
	)

	run_case("pandemonium_turns_strikes_on_its_own_side", func():
		GameState.reset()
		var combat := _start_vs([_slow_mugger(200), _slow_mugger(200)], [[["strike", "strike"]], [["guard", "guard"]]], [{ "recipe": "pandemonium", "tier": 1 }])
		var result := Combat.choose_item(0, 1)
		assert_true(combat["combatants"][1]["fury"], "furious")
		var swing: Dictionary = _actor_beats(result["beats"], 1, ["hit", "chip"])[0]
		assert_eq(int(swing["target"]), 2, "swings at the other mugger")
		assert_eq(int(swing["dmg"]), _strike_dmg(swing, 1.25), "with tier 1's +25%")
		assert_true(CombatPrototype.enemy_intents(combat, 1)[1].get("targetUnread", false), "target reads ?")
		assert_eq(CombatPrototype.status_badges(combat["combatants"][1]), ["Fury +25%"])
		GameState.reset()
		combat = _start_vs([_slow_mugger(200)], [[["strike", "strike"]]], [{ "recipe": "pandemonium", "tier": 1 }])
		result = Combat.choose_item(0, 1)
		assert_eq(int(_actor_beats(result["beats"], 1, ["hit", "chip"])[0]["target"]), 0, "alone, it strikes as planned")
	)

	run_case("a_pan_statused_enemy_refuses_another", func():
		GameState.reset()
		_start_vs([_slow_mugger(200)], [[["guard", "guard"]]], [{ "recipe": "panger", "tier": 1 }, { "recipe": "panic", "tier": 1 }])
		assert_true(Combat.choose_item(0, 1)["ok"])
		assert_eq(Combat.round_item_block_reason(1, 1), CombatPrototype.REASON_PAN_STATUSED, "already angry")
		GameState.reset()
		var combat := _start_vs([_slow_mugger(200), _slow_mugger(200)], [[["guard", "guard"]], [["guard", "guard"]]], [{ "recipe": "pansRapture", "tier": 3, "multi": true }])
		combat["combatants"][1]["angerActions"] = 4
		var result := Combat.choose_item(0)
		assert_eq(result["beats"].filter(func(b): return b["kind"] == "rapture").map(func(b): return b["target"]), [2], "multi skips the statused one")
		assert_eq(combat["combatants"][1]["raptureActions"], 0)
	)

	run_case("wormhole_ends_the_fight_fled_and_allies_refuse_it", func():
		GameState.reset()
		var combat := _start_armed([{ "recipe": "wormhole", "tier": 1 }], [["strike", "strike"]])
		var hp_before: int = GameState.state["player"]["hp"]
		var result := Combat.choose_item(0)
		assert_true(_kinds(result["beats"]).has("wormhole"), "wormhole beat")
		assert_eq(combat["outcome"], "fled", "fled at once, no roll")
		assert_eq(result["beats"].size(), 1, "no parting shot")
		assert_eq(GameState.state["player"]["hp"], hp_before)
		assert_eq(Loadout.slot(0), null, "real unit consumed")
		GameState.reset()
		_recruit("archie")
		assert_true(not Loadout.is_equippable("wormhole", "archie"), "allies can't equip it")
		var ally := Contacts.build_combat_ally("archie")
		ally["slots"] = [{ "recipe": "wormhole", "tier": 1 }, { "recipe": "blast", "tier": 1 }]
		_start_with_allies([ally], [["guard", "guard"]])
		var items: Array = GameState.state["combat"]["combatants"][1]["loadout"].map(func(e): return e["item"])
		assert_eq(items, ["blast"], "and never carry it into a fight")
	)

	run_case("blast_disarm_strips_the_weapon_and_locks_the_ability", func():
		var disarmed := false
		for seed_value in range(1, 200):
			GameState.reset()
			var armed := _slow_mugger(200)
			armed["weapon"] = { "min": 2, "max": 3 }
			armed["ability"] = { "id": "shank", "lockedTurns": 0 }
			var combat := _start_vs([armed], [[["guard", "guard"]]], [{ "recipe": "blast", "tier": 1 }], seed_value)
			var mugger: Dictionary = combat["combatants"][1]
			var attack := [mugger["attackMin"], mugger["attackMax"]]
			var result := Combat.choose_item(0, 1)
			if not _kinds(result["beats"]).has("disarm"):
				assert_true(not mugger["disarmed"], "no disarm without the beat")
				continue
			assert_eq([mugger["attackMin"], mugger["attackMax"]], [attack[0] - 2, attack[1] - 3], "weapon bonus gone")
			assert_eq(mugger["weapon"], null)
			assert_eq(mugger["ability"]["lockedTurns"], 2, "ability locked two rounds")
			assert_eq(CombatPrototype.status_badges(mugger), ["Disarmed (2)"], "disarm badge")
			Combat.choose_move("guard")
			assert_eq(mugger["ability"]["lockedTurns"], 1, "ticks at the round boundary")
			assert_true(mugger["disarmed"], "for the fight")
			disarmed = true
			break
		assert_true(disarmed, "15% lands over the seeds")
	)

	run_case("statuses_show_on_the_strip_and_readouts", func():
		GameState.reset()
		var combat := _start_vs([_slow_mugger(200)], [[["strike", "strike"]]], [{ "recipe": "panger", "tier": 1 }])
		Combat.choose_item(0, 1)
		var entries := CombatPrototypeScreen.strip_entries(combat)
		var enemy_cards: Array = entries.filter(func(e): return e["actor"] == 1)
		assert_true(not enemy_cards.is_empty() and enemy_cards.all(func(e): return e["statusBadge"] == "Anger +25%"), "every enemy card carries it")
		assert_true(entries.filter(func(e): return e["actor"] == 0).all(func(e): return e["statusBadge"] == ""), "none on the player")
	)

	run_case("rewind_spends_a_rewind_unit_then_a_dial_cast_and_says_why_not", func():
		GameState.reset()
		_start_armed([{ "recipe": "rewind", "tier": 1 }, null], [["guard", "guard"]], 1, 200)
		assert_eq(Combat.round_rewind_block_reason(), Combat.REASON_NOTHING_TO_UNDO, "no pick yet")
		assert_true(Combat.choose_move("guard")["ok"])
		assert_eq(Combat.round_rewind_block_reason(), "")
		assert_true(Combat.round_rewind()["ok"], "the unit pays")
		assert_eq(Loadout.slot(0), null, "unit spent")
		assert_true(GameState.state["combat"]["slotsUsed"].has(0), "and settled as used")
		assert_true(Combat.choose_move("guard")["ok"])
		var refused := Combat.round_rewind()
		assert_true(not refused["ok"], "neither a unit nor a Dial cast")
		assert_eq(refused["reason"], Combat.REASON_NO_REWIND)
		GameState.state["player"]["dial"] = Fixtures.dial_with_loaded("rewind", 1, 3)
		assert_true(Combat.round_rewind()["ok"], "a loaded Dial rewind pays")
		assert_eq(GameState.state["player"]["dial"]["currentCharge"], 2, "one charge")
	)

	run_case("rewind_steps_back_two_picks_across_a_round_with_plans_fog_and_rolls_intact", func():
		GameState.reset()
		GameState.state["player"]["loadout"]["slots"] = [{ "recipe": "rewind", "tier": 1 }, { "recipe": "rewind", "tier": 1 }]
		Combat._start_round_combat(Combat.CONTEXT_EVENT_MUGGING, null, [_mugger(200)], [], "", [], null, { "seed": 3 })
		var combat: Dictionary = GameState.state["combat"]
		assert_eq(CombatPrototype.actions_this_round(combat, CombatPrototype.PLAYER_INDEX), 2, "two picks a round")
		var round_no: int = combat["round"]
		var before_first := _fight_state(combat)
		var first := Combat.choose_move("guard")
		var before_second := _fight_state(combat)
		Combat.choose_move("guard")
		assert_eq(combat["round"], round_no + 1, "the second pick crossed into the next round")
		assert_true(Combat.round_rewind()["ok"])
		assert_eq(_fight_state(combat), before_second, "one pick back")
		assert_true(Combat.round_rewind()["ok"])
		assert_eq(_fight_state(combat), before_first, "two back: that round's plans, fog marks and RNG states")
		assert_eq(GameState.state["player"]["loadout"]["slots"], [null, null], "the first Rewind's unit stays spent too")
		assert_eq(Combat.round_rewind_block_reason(), Combat.REASON_NOTHING_TO_UNDO, "cap 2")
		assert_eq(Combat.choose_move("guard")["beats"], first["beats"], "the same pick replays the same rolls")
	)

	run_case("rewind_returns_units_spent_since_but_not_its_own", func():
		GameState.reset()
		var combat := _start_armed([{ "recipe": "blast", "tier": 1 }, { "recipe": "rewind", "tier": 1 }], [["guard", "guard"]], 1, 200)
		var mugger_hp: int = combat["combatants"][1]["hp"]
		assert_true(Combat.choose_item(0, 1)["ok"], "blast")
		assert_eq(Loadout.slot(0), null)
		assert_true(Combat.round_rewind()["ok"])
		assert_eq(Loadout.slot(0), { "recipe": "blast", "tier": 1 }, "blast back in its slot")
		assert_eq(Loadout.slot(1), null, "the rewind stays spent")
		assert_eq(combat["slotsUsed"], [1], "only the rewind settles as used")
		assert_eq(combat["combatants"][1]["hp"], mugger_hp, "blast undone")
		assert_eq(Combat.round_item_block_reason(0, 1), "", "blast playable again")
	)

	run_case("failsafe_undoes_a_lethal_pick_then_the_next_ko_loses", func():
		GameState.reset()
		var combat := _start_lethal([{ "recipe": "failsafe", "tier": 1 }, null])
		var result := Combat.choose_move("guard")
		assert_eq(result.get("saved", ""), Combat.LINE_FAILSAFE, "failsafe fires")
		assert_eq(combat["outcome"], null)
		assert_eq(GameState.state["player"]["hp"], 1, "back before the pick")
		assert_eq(Loadout.slot(0), null, "failsafe spent")
		assert_true(CombatPrototype.decision_position(combat) >= 0, "the pick is open again")
		assert_true(not Combat.choose_move("guard").has("saved"), "nothing left to save")
		assert_eq(combat["outcome"], "loss")
	)

	run_case("an_allys_rewind_saves_the_player_after_failsafe_while_units_last", func():
		GameState.reset()
		var kit := { "items": { "rewind": { "1": 1 } }, "used": {} }
		var combat := _start_lethal([{ "recipe": "failsafe", "tier": 1 }, null], [Combat.build_guard_ally()], { "guardKit": kit })
		assert_eq(Combat.choose_move("guard").get("saved", ""), Combat.LINE_FAILSAFE, "failsafe first")
		assert_eq(combat["guardKit"]["used"], {}, "kit untouched")
		var guard_name: String = combat["combatants"][1]["name"]
		assert_eq(Combat.choose_move("guard").get("saved", ""), Combat.LINE_ALLY_REWIND % guard_name, "then the guard's rewind")
		assert_eq(combat["guardKit"]["used"], { "rewind": { "1": 1 } }, "spent from the kit")
		assert_eq(combat["outcome"], null)
		assert_true(not Combat.choose_move("guard").has("saved"), "kit empty")
		assert_eq(combat["outcome"], "loss")
	)

	run_case("a_rewind_past_an_ally_ko_undoes_its_cooldown", func():
		GameState.reset()
		_recruit("archie")
		var archie := Contacts.build_combat_ally("archie")
		archie["hp"] = 1
		var cooldown = GameState.state["contacts"]["archie"]["koCooldownUntilDay"]
		GameState.state["player"]["loadout"]["slots"][0] = { "recipe": "rewind", "tier": 1 }
		Combat._start_round_combat(Combat.CONTEXT_EVENT_MUGGING, null, [_slow_mugger(200)], [], "", [archie], null,
			{ "seed": 1, "fog": false, "enemyPlans": [[[{ "move": "strike", "target": 1 }, { "move": "strike", "target": 1 }]]], "allyPlans": [[["guard", "guard"]]] })
		var combat: Dictionary = GameState.state["combat"]
		Combat.choose_move("guard")
		assert_true(combat["allies"][0]["koed"], "archie down")
		assert_eq(GameState.state["contacts"]["archie"]["koCooldownUntilDay"], cooldown, "no cooldown mid-fight")
		assert_true(Combat.round_rewind()["ok"])
		assert_true(not combat["allies"][0]["koed"], "archie back up")
		Combat.exit_combat()
		assert_eq(GameState.state["contacts"]["archie"]["koCooldownUntilDay"], cooldown, "no cooldown for an undone KO")
		GameState.reset()
		_recruit("archie")
		Combat._start_round_combat(Combat.CONTEXT_EVENT_MUGGING, null, [_slow_mugger(200)], [], "", [archie], null,
			{ "seed": 1, "fog": false, "enemyPlans": [[[{ "move": "strike", "target": 1 }, { "move": "strike", "target": 1 }]]], "allyPlans": [[["guard", "guard"]]] })
		Combat.choose_move("guard")
		Combat.exit_combat()
		assert_eq(GameState.state["contacts"]["archie"]["koCooldownUntilDay"], GameState.state["world"]["day"] + GameState.state["contacts"]["archie"]["koCooldownDays"], "a standing KO starts it at the end")
	)

	run_case("live_screen_rewind_plays_the_undone_beats_or_shows_the_refusal", func():
		GameState.reset()
		_start_armed([{ "recipe": "rewind", "tier": 1 }, null], [["guard", "guard"]], 1, 200)
		var host := CombatScreen.new()
		host._ready()
		var screen: CombatPrototypeScreen = host._round_screen
		screen._ready()
		assert_true(screen._rewind_button != null and screen._rewind_button.disabled, "nothing to undo yet")
		var played: Array = Combat.choose_move("guard")["beats"]
		screen._refresh()
		assert_true(not screen._rewind_button.disabled, "enabled after a pick")
		var undone := screen.begin_rewind_playback()
		assert_eq(undone.size(), played.size(), "the pick's beats")
		assert_eq(undone[0]["text"], played[-1]["text"], "newest first")
		screen._end_playback()
		Combat.choose_move("guard")
		assert_eq(screen.begin_rewind_playback(), [], "no unit left")
		assert_eq(screen._refusal, Combat.REASON_NO_REWIND)
		screen._end_playback()
		host.free()
	)

extends "res://tests/test_base.gd"

const Fixtures := preload("res://tests/support/fixtures.gd")

# Live round fights (R§3.7b): a street mugging on CombatRounds's rules
# core over state.combat -- opening from prep, the real player's stats and
# hp, the six moves' guard rules, Leg it, outcomes and the XP lump through
# exit_combat(), save/load mid-fight, the Gym card's curves and the combat
# screen hosting the round-fight screen. Rules detail lives in
# tests/test_combat_rounds.gd.


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
	assert_true(combat["active"] and combat.has("combatants"), "%s on the round rules" % context)
	assert_eq(combat["context"], context)
	var fighters: Array = combat["combatants"].filter(func(c): return c["side"] == CombatRounds.SIDE_ENEMY)
	assert_eq(fighters.size(), combat["enemies"].size(), "every active enemy fights")
	for i in range(fighters.size()):
		var entry: Dictionary = combat["enemies"][i]
		assert_eq(fighters[i]["level"], level, "%s enemy %d level" % [context, i])
		assert_eq(fighters[i]["archetype"], entry["archetype"])
		if archetypes.is_empty():
			assert_true(GameData.COMBAT_ROUNDS["archetypes"].has(entry["archetype"]), "a real archetype")
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


# James (recruited, his Dial granted beforehand) as a level-1 ally slower
# than the player, so his actions resolve after each of the player's picks.
func _slow_james() -> Dictionary:
	var james := Contacts.build_combat_ally("james")
	james["level"] = 1
	james["speed"] = 1
	return james


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
# per-pick loadout copy, the used slots (the Rewinds' own payments) and the
# transcript (which gains each Rewind's line).
# _fight_state() without the move levels, hp and beat log, which a Rewind
# keeps earned (move XP) or replays with them.
func _fight_plan_state(combat: Dictionary) -> Dictionary:
	var state := _fight_state(combat)
	state.erase("log")
	for fighter in state["combatants"]:
		fighter.erase("moveLevels")
		fighter.erase("hp")
	return state


func _fight_state(combat: Dictionary) -> Dictionary:
	var state: Dictionary = combat.duplicate(true)
	for key in ["snapshots", "roundFrames", "loadoutSlots", "slotsUsed", "transcript"]:
		state.erase(key)
	return state


# Every round: two Strikes aimed at the player.
func _strikes_at_player() -> Array:
	return [[{ "move": "strike", "target": CombatRounds.PLAYER_INDEX }, { "move": "strike", "target": CombatRounds.PLAYER_INDEX }]]


# A seeded street mugging against `count` guarding muggers, any past the
# third waiting in enemyQueue.
func _start_reinforced(count: int) -> Dictionary:
	var muggers: Array = range(count).map(func(_i): return _mugger())
	Combat._start_round_combat(Combat.CONTEXT_EVENT_MUGGING, null, muggers, [], "", [], null,
		{ "seed": 1, "fog": false, "enemyPlans": muggers.map(func(_m): return [["guard", "guard"]]) })
	return GameState.state["combat"]


# Guards out the player's picks until round `round_no` ends.
func _finish_round(combat: Dictionary, round_no: int) -> void:
	while combat["round"] == round_no and combat["outcome"] == null:
		assert_true(Combat.choose_move("guard")["ok"])


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


# A seeded street mugging, fog off unless `unread` (per enemy, per round),
# with recruit Archie at level 1 carrying `units` ({ recipe, tier, multi? })
# against `enemies` playing `plans`. Archie at `speed` 99 acts first at each
# index, so his first action has resolved by the player's first pick.
func _start_ally_armed(units: Array, enemies: Array, plans: Array, unread: Array = [], speed: int = 99, hp: int = -1) -> Dictionary:
	_recruit("archie")
	var archie := Contacts.build_combat_ally("archie")
	archie["slots"] = units
	archie["level"] = 1
	archie["speed"] = speed
	if hp > 0:
		archie["hp"] = hp
	var config := { "seed": 1, "fog": not unread.is_empty(), "enemyPlans": plans }
	if not unread.is_empty():
		config["enemyUnread"] = unread
	Combat._start_round_combat(Combat.CONTEXT_EVENT_MUGGING, null, enemies, [], "", [archie], null, config)
	return GameState.state["combat"]


func _row(screen: CombatRoundsScreen, row_name: String) -> Button:
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
		assert_true(combat.has("combatants"), "a round fight")
		assert_eq(combat["context"], Combat.CONTEXT_EVENT_MUGGING)
		assert_eq(GameState.state["currentScreen"], "combat")
		var you: Dictionary = combat["combatants"][CombatRounds.PLAYER_INDEX]
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
		assert_almost_eq(CombatRounds.unread_chance(combat, 1, 1), 0.15, 0.0001, "fog from player level")
		assert_true(CombatRounds.decision_position(combat) >= 0 or combat["outcome"] != null, "paused for a pick")
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
		assert_eq(opening.get("target", -1), CombatRounds.PLAYER_INDEX, "the mugger's opening strike chips the Guarded player")
		var you: Dictionary = combat["combatants"][CombatRounds.PLAYER_INDEX]
		assert_eq(you["hp"], you["hpMax"] - int(opening["dmg"]), "real hp spent")
		assert_eq(GameState.state["player"]["hp"], you["hp"], "player hp follows the fight")
		var result := Combat.choose_move("strike", 1)
		assert_true(result["ok"], "strike plays")
		var hit: Dictionary = _first(result["beats"], "hit")
		assert_eq(hit.get("actor", -1), CombatRounds.PLAYER_INDEX, "full hit on the mugger left Open by its strike")
		assert_eq(int(hit["dmg"]), int(hit["roll"]) * (2 if hit["crit"] else 1), "full damage")
		var counter: Array = result["beats"].filter(func(b): return b["actor"] == 1 and b["kind"] == "hit")
		assert_eq(counter.size(), 1, "the mugger's second strike lands full on the now-Open player")
	)

	run_case("feint_opens_a_guarded_mugger", func():
		GameState.reset()
		var combat := _start([["guard", "guard"]])
		assert_eq(combat["combatants"][1]["guard"], CombatRounds.GUARDED)
		var result := Combat.choose_move("feint", 1)
		var feint: Dictionary = _first(result["beats"], "feint")
		assert_true(not feint.is_empty(), "feint beat")
		assert_eq(feint["marks"][1]["guard"], CombatRounds.OPEN, "the mugger stands Open after the Feint")
		assert_eq(combat["combatants"][1]["guard"], CombatRounds.OPEN, "its next Guard failed, consumed")
		assert_true(not combat["combatants"][1]["guardFailed"], "failure spent")
	)

	run_case("feint_on_an_open_mugger_still_fails_its_next_guard", func():
		GameState.reset()
		var combat := _start([["strike", "guard"]])
		Combat.choose_move("feint", 1)
		assert_eq(combat["combatants"][1]["guard"], CombatRounds.OPEN, "its planned Guard after the Feint failed")
		assert_true(not combat["combatants"][1]["guardFailed"], "consumed")
	)

	run_case("strike_after_feint_vs_a_guarding_enemy_lands_full", func():
		GameState.reset()
		var combat := _start([["guard", "guard"]])
		Combat.choose_move("feint", 1)
		var result := Combat.choose_move("strike", 1)
		assert_true(not _first(result["beats"], "hit").is_empty(), "full damage, not a chip")
		assert_true(_first(result["beats"], "chip").is_empty(), "no chip")
	)

	run_case("guard_works_normally_after_the_failed_one", func():
		GameState.reset()
		var combat := _start([["guard", "guard"]])
		Combat.choose_move("feint", 1)
		Combat.choose_move("guard")
		assert_eq(combat["combatants"][1]["guard"], CombatRounds.GUARDED, "second Guard closes it")
	)

	run_case("an_in_flight_save_with_lure_fields_loads_cleanly", func():
		GameState.reset()
		var combat := _start([["guard", "guard"]])
		for c in combat["combatants"]:
			c["lure"] = "active"
			c["lureExposedRounds"] = 1
			c["exposedUntil"] = 2
			c.erase("guardFailed")
		var back = JSON.parse_string(JSON.stringify(GameState.state))
		assert_true(back != null, "round-trips")
		SaveManager._restore_combat_int_types(back["combat"])
		for c in back["combat"]["combatants"]:
			assert_true(not c.has("lure") and not c.has("exposedUntil") and c["guardFailed"] == false, "old fields stripped, new defaulted")
		GameState.state = back
		var result := Combat.choose_move("guard")
		assert_true(result["ok"], "the fight plays on: %s" % str(result.get("reason", "")))
	)

	run_case("stun_on_an_open_mugger_drops_its_next_action", func():
		GameState.reset()
		_start([["strike", "guard"]])
		var result := Combat.choose_move("stun", 1)
		assert_true(_kinds(result["beats"]).has("stun"), "stun lands on the Open mugger")
		var lost: Dictionary = _first(result["beats"], "lost")
		assert_eq(lost.get("actor", -1), 1, "the mugger loses its Guard")
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
				assert_eq(combat["combatants"][CombatRounds.PLAYER_INDEX]["guard"], CombatRounds.OPEN, "left Open")
				assert_eq([combat["round"], CombatRounds.decision_position(combat)], [2, 0], "the rest of the round's actions are lost")
		assert_true(fled and failed, "seeds cover both Leg it results")
	)

	run_case("strike_level_damage_bonus_and_crit_unlock", func():
		GameState.reset()
		var combat := _start([["guard", "guard"]])
		var you: Dictionary = combat["combatants"][CombatRounds.PLAYER_INDEX]
		for pair in [[1, 0], [2, 2], [3, 4], [4, 8], [5, 12]]:
			you["moveLevels"]["strike"] = pair[0]
			assert_eq(CombatRounds.damage_range(combat, CombatRounds.PLAYER_INDEX), [you["attackMin"] + pair[1], you["attackMax"] + pair[1]], "L%d bonus" % pair[0])
		var crits := {}
		for level in [1, 3, 5]:
			you["moveLevels"]["strike"] = level
			var hits := 0
			for seed_value in range(400):
				var rng := RandomNumberGenerator.new()
				rng.seed = seed_value
				var beats: Array = []
				combat["combatants"][1]["hp"] = 1000
				combat["combatants"][1]["guard"] = CombatRounds.OPEN
				CombatRounds._strike(combat, CombatRounds.PLAYER_INDEX, 1, "strike", rng, beats)
				if beats[0].get("crit", false):
					hits += 1
			crits[level] = hits
		assert_true(crits[3] > crits[1] + 8 and crits[5] > crits[1] + 8, "L3+ adds ~6%% crit (%s)" % str(crits))
	)

	run_case("chip_multiplier_combines_strike_l5_with_guard_level", func():
		GameState.reset()
		var combat := _start([["guard", "guard"]])
		var you: Dictionary = combat["combatants"][CombatRounds.PLAYER_INDEX]
		var mugger: Dictionary = combat["combatants"][1]
		for pair in [[1, 0.25], [2, 0.20], [3, 0.17], [4, 0.14], [5, 0.10]]:
			mugger["moveLevels"]["guard"] = pair[0]
			you["moveLevels"]["strike"] = 1
			assert_almost_eq(CombatRounds.chip_multiplier(you, mugger), pair[1], 0.0001, "Guard L%d chip" % pair[0])
		you["moveLevels"]["strike"] = 4
		mugger["moveLevels"]["guard"] = 1
		assert_almost_eq(CombatRounds.chip_multiplier(you, mugger), 0.25, 0.0001, "Strike L4 keeps base chip")
		you["moveLevels"]["strike"] = 5
		assert_almost_eq(CombatRounds.chip_multiplier(you, mugger), 0.55, 0.0001, "Strike L5 vs Guard L1")
		mugger["moveLevels"]["guard"] = 5
		assert_almost_eq(CombatRounds.chip_multiplier(you, mugger), 0.22, 0.0001, "Strike L5 x Guard L5 = 0.55 x 0.10/0.25")
	)

	run_case("guard_levels_block_hits_and_blast_ignores_them", func():
		GameState.reset()
		var combat := _start([["guard", "guard"]])
		var you: Dictionary = combat["combatants"][CombatRounds.PLAYER_INDEX]
		var mugger: Dictionary = combat["combatants"][1]
		you["guard"] = CombatRounds.GUARDED
		you["hp"] = 1000
		var blocks := {}
		for level in [1, 3]:
			mugger["moveLevels"]["guard"] = 1
			you["moveLevels"]["guard"] = level
			var blocked := 0
			for seed_value in range(300):
				var rng := RandomNumberGenerator.new()
				rng.seed = seed_value
				var beats: Array = []
				CombatRounds._strike(combat, 1, CombatRounds.PLAYER_INDEX, "strike", rng, beats)
				if beats[0]["kind"] == "block":
					blocked += 1
			blocks[level] = blocked
		assert_eq(blocks[1], 0, "L1 never fully blocks")
		assert_true(blocks[3] > 60 and blocks[3] < 120, "L3 blocks about 30%% (%d)" % blocks[3])
		you["moveLevels"]["guard"] = 5
		you["firstHitSpent"] = false
		var rng2 := RandomNumberGenerator.new()
		rng2.seed = 3
		var first: Array = []
		CombatRounds._strike(combat, 1, CombatRounds.PLAYER_INDEX, "strike", rng2, first)
		assert_eq(first[0]["kind"], "block", "L5 first hit does 0")
		assert_eq(first[0]["dmg"], 0, "no damage")
		assert_true(you["firstHitSpent"], "spent")
		var before: int = you["hp"]
		CombatRounds._deal_damage(combat, 1, CombatRounds.PLAYER_INDEX, 9, "blast", "blast", [], {})
		assert_eq(you["hp"], before - 9, "item damage ignores Guard level")
	)

	run_case("feint_level_adds_damage_to_the_opening_until_the_target_sets_guard", func():
		GameState.reset()
		var combat := _start([["guard", "guard"]])
		var you: Dictionary = combat["combatants"][CombatRounds.PLAYER_INDEX]
		var mugger: Dictionary = combat["combatants"][1]
		you["moveLevels"]["feint"] = 4
		mugger["guard"] = CombatRounds.GUARDED
		CombatRounds._feint(combat, CombatRounds.PLAYER_INDEX, 1, "feint", [])
		assert_eq(mugger["feintPct"], 30, "L4 Feint: +30%%")
		you["attackMin"] = 10
		you["attackMax"] = 10
		var landed := 0
		for seed_value in range(40):
			var rng := RandomNumberGenerator.new()
			rng.seed = seed_value
			var beats: Array = []
			CombatRounds._strike(combat, CombatRounds.PLAYER_INDEX, 1, "strike", rng, beats)
			var hit: Dictionary = _first(beats, "hit")
			if hit.is_empty() or hit["crit"]:
				continue
			landed += 1
			assert_eq(hit["dmg"], 13, "10 +30%%")
			mugger["hp"] = 1000
		assert_true(landed > 0, "some non-crit hits landed")
		mugger["feintPct"] = 0
		var rng2 := RandomNumberGenerator.new()
		rng2.seed = 1
		var plain: Array = []
		CombatRounds._strike(combat, CombatRounds.PLAYER_INDEX, 1, "strike", rng2, plain)
		assert_true(_first(plain, "hit").is_empty() or _first(plain, "hit")["dmg"] % 10 == 0, "no bonus once the opening ends")
	)

	run_case("feint_autoguard_chips_one_hit_at_the_stated_chance_only_after_a_feint", func():
		GameState.reset()
		var combat := _start([["guard", "guard"]])
		var you: Dictionary = combat["combatants"][CombatRounds.PLAYER_INDEX]
		you["hp"] = 100000
		you["guard"] = CombatRounds.OPEN
		var counts := {}
		for level in [2, 3, 4, 5]:
			you["moveLevels"]["feint"] = level
			you["lastMove"] = "feint"
			var fired := 0
			for seed_value in range(300):
				var rng := RandomNumberGenerator.new()
				rng.seed = seed_value
				var beats: Array = []
				CombatRounds._strike(combat, 1, CombatRounds.PLAYER_INDEX, "strike", rng, beats, true)
				if not _first(beats, "autoguard").is_empty():
					fired += 1
					assert_true(not _first(beats, "chip").is_empty() or not _first(beats, "block").is_empty(), "autoguarded hit chips")
			counts[level] = fired
		assert_eq(counts[2], 0, "no autoguard below L3")
		assert_true(counts[3] > 70 and counts[3] < 130, "L3 about 33%% (%d)" % counts[3])
		assert_true(counts[4] > 120 and counts[4] < 180, "L4 about 50%% (%d)" % counts[4])
		assert_true(counts[5] > 170 and counts[5] < 230, "L5 about 66%% (%d)" % counts[5])
		you["lastMove"] = "strike"
		you["moveLevels"]["feint"] = 5
		for seed_value in range(50):
			var rng := RandomNumberGenerator.new()
			rng.seed = seed_value
			var beats: Array = []
			CombatRounds._strike(combat, 1, CombatRounds.PLAYER_INDEX, "strike", rng, beats, true)
			assert_true(_first(beats, "autoguard").is_empty(), "no autoguard when the last action wasn't a Feint")
	)

	run_case("feint_l5_retaliates_free_without_chaining", func():
		GameState.reset()
		var combat := _start([["guard", "guard"]])
		var you: Dictionary = combat["combatants"][CombatRounds.PLAYER_INDEX]
		var mugger: Dictionary = combat["combatants"][1]
		you["hp"] = 100000
		mugger["hp"] = 100000
		mugger["moveLevels"]["feint"] = 5
		mugger["lastMove"] = "feint"
		you["moveLevels"]["feint"] = 5
		you["lastMove"] = "feint"
		var retaliated := 0
		for seed_value in range(300):
			var rng := RandomNumberGenerator.new()
			rng.seed = seed_value
			var beats: Array = []
			CombatRounds._strike(combat, 1, CombatRounds.PLAYER_INDEX, "strike", rng, beats)
			var n := beats.filter(func(b): return b["kind"] == "retaliate").size()
			assert_true(n <= 1, "never chains")
			if n == 1:
				retaliated += 1
				var at: int = beats.find_custom(func(b): return b["kind"] == "retaliate")
				assert_eq(beats[at]["actor"], CombatRounds.PLAYER_INDEX, "the defender retaliates")
				assert_eq(beats[at]["target"], 1, "at the attacker")
		assert_true(retaliated > 70 and retaliated < 130, "about 33%% (%d)" % retaliated)
		you["moveLevels"]["feint"] = 4
		for seed_value in range(50):
			var rng := RandomNumberGenerator.new()
			rng.seed = seed_value
			var beats: Array = []
			CombatRounds._strike(combat, 1, CombatRounds.PLAYER_INDEX, "strike", rng, beats)
			assert_true(_first(beats, "retaliate").is_empty(), "L4 doesn't retaliate")
	)

	run_case("stun_levels_reach_guarded_targets_and_hold_open", func():
		GameState.reset()
		var combat := _start([["guard", "guard"]])
		var you: Dictionary = combat["combatants"][CombatRounds.PLAYER_INDEX]
		var mugger: Dictionary = combat["combatants"][1]
		var stun := CombatRounds.move("stun")
		var results := {}
		for level in [1, 3, 5]:
			you["moveLevels"]["stun"] = level
			var through := 0
			for seed_value in range(200):
				var rng := RandomNumberGenerator.new()
				rng.seed = seed_value
				mugger["guard"] = CombatRounds.GUARDED
				mugger["actionsLost"] = 0
				mugger["openActions"] = 0
				var beats: Array = []
				CombatRounds._stun(combat, CombatRounds.PLAYER_INDEX, 1, "stun", stun, rng, beats)
				if beats[0]["kind"] == "stunThrough":
					through += 1
					assert_eq(mugger["actionsLost"], 1, "it loses its action")
					assert_eq(mugger["openActions"], 2 if level == 5 else 0, "L5 holds it Open for 2 actions")
			results[level] = through
		assert_eq(results[1], 0, "L1 fizzles on a guard")
		assert_true(results[3] > 135 and results[3] < 185, "L3 works ~80%% (%d)" % results[3])
		you["moveLevels"]["stun"] = 5
		mugger["guard"] = CombatRounds.OPEN
		mugger["actionsLost"] = 0
		mugger["openActions"] = 0
		CombatRounds._stun(combat, CombatRounds.PLAYER_INDEX, 1, "stun", stun, RandomNumberGenerator.new(), [])
		mugger["guard"] = CombatRounds.GUARDED
		assert_true(CombatRounds.is_open(combat, mugger), "held Open while guarded")
		CombatRounds._tick_open(mugger)
		CombatRounds._tick_open(mugger)
		assert_true(not CombatRounds.is_open(combat, mugger), "hold over after 2 actions")
	)

	run_case("leg_it_levels_set_chance_and_failure_consequences", func():
		GameState.reset()
		var combat := _start([["guard", "guard"]])
		var you: Dictionary = combat["combatants"][CombatRounds.PLAYER_INDEX]
		for pair in [[1, 0.65], [2, 0.70], [3, 0.75], [4, 0.80], [5, 0.85]]:
			you["moveLevels"]["legIt"] = pair[0]
			assert_almost_eq(CombatRounds.flee_chance(you), pair[1], 0.0001, "L%d chance" % pair[0])
		for level in [1, 3, 5]:
			var checked := false
			for seed_value in range(1, 80):
				if checked:
					break
				GameState.reset()
				var c := _start([["guard", "guard"]], seed_value)
				c["combatants"][CombatRounds.PLAYER_INDEX]["moveLevels"]["legIt"] = level
				var result := Combat.choose_move("legIt")
				if result["outcome"] != null:
					continue
				checked = true
				var pos := [c["round"], CombatRounds.decision_position(c)]
				var guard: String = c["combatants"][CombatRounds.PLAYER_INDEX]["guard"]
				if level == 1:
					assert_eq(pos, [2, 0], "L1 loses the rest of the round")
					assert_eq(guard, CombatRounds.OPEN, "L1 left Open")
				elif level == 3:
					assert_eq(pos, [1, 1], "L3 keeps its next action")
					assert_eq(guard, CombatRounds.OPEN, "L3 left Open")
				else:
					assert_eq(pos, [1, 1], "L5 keeps its next action")
					assert_eq(guard, CombatRounds.GUARDED, "L5 left Guarded")
			assert_true(checked, "a failed flee at L%d" % level)
	)

	run_case("win_pays_30_xp_and_resumes_the_event", func():
		GameState.reset()
		var combat := _start([["guard", "guard"]], 1, 1)
		var xp: int = GameState.state["player"]["combatXP"]
		var result := Combat.choose_move("strike", 1)
		assert_eq(result["outcome"], "win")
		var hp: int = combat["combatants"][CombatRounds.PLAYER_INDEX]["hp"]
		assert_eq(Combat.exit_combat()["nextScreen"], "event")
		assert_eq(GameState.state["player"]["combatXP"], xp + Combat.ROUND_XP_WIN, "win +30")
		assert_eq(GameState.state["player"]["hp"], hp, "hp carried out of the fight")
		assert_eq(GameState.state["combat"], Combat.idle_state(), "torn down to the idle dict")
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
		var pause := CombatRounds.decision_position(combat)
		var text := SaveManager.export_string()
		var first := Combat.choose_move("strike", 1)
		var hps: Array = GameState.state["combat"]["combatants"].map(func(c): return c["hp"])
		assert_true(SaveManager.import_string(text)["ok"], "save loads")
		combat = GameState.state["combat"]
		assert_true(combat["active"] and combat.has("combatants"), "still a round fight")
		assert_eq(combat["rngState"], rng_state, "RNG state survives exactly")
		assert_eq(CombatRounds.decision_position(combat), pause, "same pause")
		var second := Combat.choose_move("strike", 1)
		assert_eq(second["beats"].map(func(b): return b["text"]), first["beats"].map(func(b): return b["text"]), "the pick replays identically")
		assert_eq(combat["combatants"].map(func(c): return c["hp"]), hps, "same hp after")
	)

	run_case("gym_card_shows_actions_per_round_and_crit", func():
		GameState.reset()
		var s := Combat.skill_summary()
		assert_eq(s["stats"]["actionsPerRound"], 2)
		assert_almost_eq(s["stats"]["critChance"], 0.03, 0.0001)
		assert_eq(s["nextStats"]["actionsPerRound"], GameData.COMBAT_ROUNDS["actionsPerRound"][2])
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
		var kit: Dictionary = combat["raiderKit"]
		var units: int = GuardKit.unit_count(kit["items"]) + GuardKit.unit_count(kit.get("reserved", {})) + GuardKit.unit_count(kit["used"])
		assert_eq(units, GuardKit.unit_count(FactionSim.raider_kit("firm", "defend", 2)["items"]), "the defend kit rides along for settlement")
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
		assert_eq(CombatRounds.timeline(combat)[0]["actor"], CombatRounds.PLAYER_INDEX, "no mod: speed leads")
		_seeded()
		Combat.start_home_raid_combat({ "enemyFirst": true })
		combat = GameState.state["combat"]
		var order: Array = CombatRounds.timeline(combat).map(func(e): return [e["index"], e["actor"]])
		assert_eq(order.slice(0, 4), [[0, 1], [0, 0], [1, 1], [1, 0]], "raider first at each slot, slots still alternate")
		assert_eq(CombatRounds.next_round_timeline(combat)[0]["actor"], CombatRounds.PLAYER_INDEX, "round 2 back to speed order")
	)

	run_case("home_alarm_defend_runs_the_raider_at_level_2", func():
		_seeded()
		Combat.start_home_alarm_defend_combat()
		_assert_enemies(Combat.CONTEXT_HOME_ALARM_DEFEND, { Combat.HOME_RAIDER_TEMPLATE_KEY: "bruiser" }, 2)
	)

	run_case("debug_launcher_runs_on_the_round_engine_at_the_picked_level", func():
		_seeded()
		Combat.start_debug_combat({ "context": Combat.CONTEXT_RAID, "enemies": [{ "template": "veinGuard", "level": 4 }] })
		_assert_enemies(Combat.CONTEXT_RAID, { "veinGuard": "turtle" }, 4)
	)

	run_case("debug_launcher_takes_template_archetype_level_and_fight_only_player_level", func():
		_seeded()
		var player: Dictionary = GameState.state["player"]
		Combat.start_debug_combat({
			"context": Combat.CONTEXT_DEFEND_VEIN, "locationKey": "camden", "playerLevel": 3, "fog": false,
			"enemies": [
				{ "template": Combat.MUGGER_TEMPLATE_KEY, "archetype": "turtleV2", "level": 2 },
				{ "template": Combat.HOME_RAIDER_TEMPLATE_KEY, "archetype": "", "level": 2 },
			],
		})
		var combat: Dictionary = GameState.state["combat"]
		assert_eq(combat["locationKey"], "camden")
		assert_true(not combat["fog"])
		var fighters: Array = combat["combatants"].filter(func(c): return c["side"] == CombatRounds.SIDE_ENEMY)
		assert_eq(fighters.map(func(c): return c["archetype"]), ["turtleV2", "bruiser"], "override, then the template's own")
		assert_eq(fighters.map(func(c): return c["level"]), [2, 2])
		var me: Dictionary = combat["combatants"][CombatRounds.PLAYER_INDEX]
		assert_eq(me["level"], 3, "fight at the picked level")
		assert_eq(me["speed"], int(GameData.COMBAT_SPEED_BY_LEVEL[3]))
		assert_eq(me["attackMin"], int(player["attackMin"]) + int(GameData.COMBAT_ATTACK_BONUS_BY_LEVEL[3]))
		assert_eq(me["hpMax"], int(player["hpMax"]), "real HP")
		assert_eq(player["combatSkill"], 1, "real Combat Skill untouched")
	)

	run_case("debug_launcher_seats_debug_allies_at_their_level_with_their_slots", func():
		_seeded()
		Combat.start_debug_combat({
			"context": Combat.CONTEXT_RAID, "enemies": [{ "template": "veinGuard", "level": 1 }],
			"allies": [{ "level": 4, "slots": [{ "recipe": "blast", "tier": 2 }] }, { "level": 2, "slots": [] }],
		})
		var allies: Array = GameState.state["combat"]["combatants"].filter(func(c): return c["side"] == CombatRounds.SIDE_ALLY)
		assert_eq(allies.map(func(c): return c["level"]), [4, 2])
		assert_eq(allies[0]["loadout"].map(func(e): return [e["item"], e["tier"]]), [["blast", 2]])
		assert_eq(allies[0]["hpMax"], int(GameData.COMBAT_ROUNDS["allyBase"]["hpBase"]) + int(GameData.COMBAT_HP_BONUS_BY_LEVEL[4]))
		Combat.exit_combat()
		assert_true(not GameState.state["combat"]["active"], "debug allies settle without a contact")
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
		var screen: CombatRoundsScreen = host._round_screen
		assert_true(screen != null, "round screen hosted")
		screen._ready()
		for move_id in ["guard", "strike", "feint", "stun", "legIt"]:
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
		var entry: Dictionary = combat["combatants"][CombatRounds.PLAYER_INDEX]["loadout"][0]
		assert_eq([entry["item"], entry["tier"], entry["power"], entry["sourceSlot"]], ["timePearl", 3, 3, 0], "real slot at its tier's power")
		var result := Combat.choose_item(0)
		assert_true(result["ok"], "choose_item plays it as a pick")
		assert_true(_kinds(result["beats"]).has("timePearl"), "freeze beat")
		var mugger: Dictionary = combat["combatants"][1]
		# The mugger's second action drops; two more of its three stay lost.
		assert_eq(_first(result["beats"], "frozen").get("actor", -1), 1, "its next action frozen")
		assert_eq(mugger["frozenActions"], 2, "power 3 - 1 spent")
		assert_true(CombatRounds.is_open(combat, mugger), "Open while frozen")
		assert_eq(CombatRounds.decision_position(combat), 1, "one action, the next pick is the player's second")
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
		assert_eq(mugger["guard"], CombatRounds.GUARDED)
		var result := Combat.choose_item(0)
		assert_true(result["ok"])
		assert_eq(int(_first(result["beats"], "pull")["dmg"]), 8, "tier 2 power, guard ignored")
		assert_eq(mugger["hp"], 20)
		# 1 + floor(8 / 8) = 2 actions lost; its second action this round is one.
		assert_eq(_first(result["beats"], "lost").get("actor", -1), 1)
		assert_eq(mugger["actionsLost"], 1)
		assert_eq(combat["combatants"][CombatRounds.PLAYER_INDEX]["guard"], CombatRounds.GUARDED, "user's guard unchanged")
	)

	run_case("blast_hits_through_guard_and_boosts_the_next_leg_it_once", func():
		var boosted := false
		for seed_value in range(1, 200):
			GameState.reset()
			var combat := _start_armed([{ "recipe": "blast", "tier": 2 }], [["guard", "guard"]], seed_value)
			var result := Combat.choose_item(0, 1)
			assert_eq(int(_first(result["beats"], "blast")["dmg"]), 6, "tier 2 power on a Guarded mugger")
			var you: Dictionary = combat["combatants"][CombatRounds.PLAYER_INDEX]
			assert_almost_eq(float(you["fleeBoost"]), 0.9, 0.0001, "Leg it boost armed")
			var plain: Dictionary = combat.duplicate(true)
			plain["combatants"][CombatRounds.PLAYER_INDEX]["fleeBoost"] = 0.0
			var with_boost := CombatRounds.play_pick(combat, { "move": "legIt", "target": -1 }, Combat.ROUND_SNAPSHOT_STACK)
			var without := CombatRounds.play_pick(plain, { "move": "legIt", "target": -1 }, Combat.ROUND_SNAPSHOT_STACK)
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
		var you: Dictionary = combat["combatants"][CombatRounds.PLAYER_INDEX]
		assert_eq(you["shield"], 4, "tier 2 pool")
		assert_true(Combat.choose_move("strike", 1)["ok"])
		assert_eq(you["guard"], CombatRounds.OPEN, "the strike opens its own guard")
		assert_true(not CombatRounds.is_open(combat, you), "but the pool keeps it Guarded")
	)

	run_case("enhancement_powder_adds_an_action_this_round", func():
		GameState.reset()
		var combat := _start_armed([{ "recipe": "enhancementPowder", "tier": 5 }], [["guard", "guard"]])
		var base := CombatRounds.actions_per_round(combat["combatants"][CombatRounds.PLAYER_INDEX])
		assert_true(Combat.choose_item(0)["ok"])
		assert_eq(CombatRounds.actions_this_round(combat, CombatRounds.PLAYER_INDEX), base + 1, "extra action this round")
		assert_eq(CombatRounds.actions_next_round(combat, CombatRounds.PLAYER_INDEX), base + 1, "power 3 runs two rounds")
		GameState.reset()
		combat = _start_armed([{ "recipe": "enhancementPowder", "tier": 1 }], [["guard", "guard"]])
		assert_true(Combat.choose_item(0)["ok"])
		assert_eq(CombatRounds.actions_this_round(combat, CombatRounds.PLAYER_INDEX), base + 1)
		assert_eq(CombatRounds.actions_next_round(combat, CombatRounds.PLAYER_INDEX), base, "power 1, one round")
	)

	run_case("prophets_breath_gives_sight_from_resolution", func():
		GameState.reset()
		GameState.state["player"]["loadout"]["slots"][0] = { "recipe": "prophetsBreath", "tier": 4 }
		Combat._start_round_combat(Combat.CONTEXT_EVENT_MUGGING, null, [_mugger()], [], "", [], null,
			{ "seed": 1, "fog": true, "enemyPlans": [[["guard", "guard"]]], "enemyUnread": [[[false, true]]] })
		var combat: Dictionary = GameState.state["combat"]
		assert_true(not CombatRounds.is_read(combat, 1, 1), "fogged before")
		assert_true(Combat.choose_item(0)["ok"])
		assert_eq(combat["combatants"][CombatRounds.PLAYER_INDEX]["sightUntil"], 3, "power 2 rounds after this one")
		assert_true(CombatRounds.has_sight(combat))
		assert_true(not CombatRounds.enemy_intents(combat, 1, true).is_empty(), "next round read")
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
		var you: Dictionary = combat["combatants"][CombatRounds.PLAYER_INDEX]
		you["hp"] = you["hpMax"] - 3
		result = Combat.choose_item(1)
		assert_eq(int(_first(result["beats"], "healSelf")["amount"]), 3, "self by default, capped at hpMax")
		assert_eq(GameState.state["player"]["hp"], you["hpMax"], "real hp follows")
	)

	run_case("be_a_lady_equips_and_gives_max_rolls_from_resolution", func():
		GameState.reset()
		Crafting.inventory_add("beALady", 4, 1)
		assert_true(Loadout.equip(0, "beALady", 4)["ok"], "player can equip it")
		assert_true(Loadout.is_equippable("beALady", "archie"), "allies can too")
		var combat := _start([["guard", "guard"]])
		var you: Dictionary = combat["combatants"][CombatRounds.PLAYER_INDEX]
		assert_true(not CombatRounds.has_lady(combat, you), "not before use")
		assert_true(Combat.choose_item(0)["ok"])
		assert_eq(you["ladyUntil"], 2, "power 2: this round and next")
		assert_eq(CombatRounds.damage_range(combat, CombatRounds.PLAYER_INDEX), [you["attackMax"], you["attackMax"]], "max rolls")
		assert_almost_eq(float(you["ladyCrit"]), 0.333333, 0.0001, "1/3 crit")
		assert_eq(you["ladyTier"], 4, "the unit's tier")
		assert_eq(Loadout.slot(0), null, "real unit consumed")
	)

	run_case("enemy_evade_misses_a_strike_outright", func():
		GameState.reset()
		var mugger := _mugger()
		mugger["evadeChance"] = 1.0
		var combat := _start_vs([mugger], [[["guard", "guard"]]], [])
		var enemy: Dictionary = combat["combatants"][1]
		assert_eq(enemy["evadeChance"], 1.0, "carried from the enemy entry")
		var result := Combat.choose_move("strike", 1)
		assert_eq(_actor_beats(result["beats"], CombatRounds.PLAYER_INDEX, ["evade", "hit", "chip"]).map(func(b): return b["kind"]), ["evade"], "missed, no damage beat")
		assert_eq(enemy["hp"], enemy["hpMax"], "untouched")
	)

	run_case("evade_chance_is_zero_on_a_stunned_target", func():
		GameState.reset()
		var mugger := _mugger()
		mugger["evadeChance"] = 0.5
		var combat := _start_vs([mugger], [[["guard", "guard"]]], [])
		var you: Dictionary = combat["combatants"][CombatRounds.PLAYER_INDEX]
		var enemy: Dictionary = combat["combatants"][1]
		assert_almost_eq(CombatRounds.evade_chance(combat, you, enemy), 0.5, 0.0001, "as authored")
		enemy["actionsLost"] = 1
		assert_eq(CombatRounds.evade_chance(combat, you, enemy), 0.0, "stunned or frozen")
	)

	run_case("be_a_lady_cuts_evade_5_points_per_tier", func():
		GameState.reset()
		var mugger := _mugger()
		mugger["evadeChance"] = 0.5
		var combat := _start_vs([mugger], [[["guard", "guard"]]], [])
		var you: Dictionary = combat["combatants"][CombatRounds.PLAYER_INDEX]
		var enemy: Dictionary = combat["combatants"][1]
		you["ladyUntil"] = combat["round"]
		you["ladyTier"] = 2
		assert_almost_eq(CombatRounds.evade_chance(combat, you, enemy), 0.4, 0.0001, "tier 2: -10 points")
		enemy["evadeChance"] = 0.2
		you["ladyTier"] = 1
		assert_almost_eq(CombatRounds.evade_chance(combat, you, enemy), 0.15, 0.0001, "tier 1: 20% to 15%")
		you["ladyTier"] = 5
		assert_eq(CombatRounds.evade_chance(combat, you, enemy), 0.0, "floored at 0")
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
		assert_true(CombatRounds.is_read(combat, 1, 1), "sight from round 1")
		var you: Dictionary = combat["combatants"][CombatRounds.PLAYER_INDEX]
		assert_eq(CombatRounds.damage_range(combat, CombatRounds.PLAYER_INDEX), [you["attackMax"], you["attackMax"]], "max rolls")
		assert_almost_eq(float(you["ladyCrit"]), 0.333333, 0.0001, "1/3 crit")
		assert_eq(you["ladyTier"], 1, "the effect's level")
		for i in range(4):
			Combat.choose_move("guard")
		assert_true(combat["round"] >= 3 and CombatRounds.has_sight(combat) and CombatRounds.has_lady(combat, you), "whole fight")
		assert_true(ActiveEffects.prophets_breath_active(), "still blocks ambushes")
		GameState.reset()
		_start([["guard", "guard"]])
		assert_true(not CombatRounds.has_sight(GameState.state["combat"]), "none without an active effect")
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
		var screen: CombatRoundsScreen = host._round_screen
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
		assert_eq(archie["side"], CombatRounds.SIDE_ALLY)
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
		assert_eq(combat["combatants"][3]["side"], CombatRounds.SIDE_ENEMY, "queued ally isn't a combatant")
	)

	run_case("ally_plans_read_and_react_to_read_intents_only", func():
		GameState.reset()
		_recruit("archie")
		# The mugger strikes archie twice; the second strike is unread.
		var strikes := [{ "move": "strike", "target": 1 }, { "move": "strike", "target": 1 }]
		_start_with_allies([Contacts.build_combat_ally("archie")], [strikes], 3, true, [[false, true]])
		var combat: Dictionary = GameState.state["combat"]
		assert_eq(CombatRounds.decision_position(combat), 0, "paused on the player's first pick")
		var plan: Array = combat["combatants"][1]["plan"]
		assert_eq(plan.size(), 2, "ally plan committed before the pick")
		assert_true(CombatRounds.is_read(combat, 1, 0) and CombatRounds.is_read(combat, 1, 1), "ally plans always read")
		assert_eq(plan[0]["move"], "guard", "guards the read strike")
		assert_eq(plan[1]["move"], "strike", "an unread strike isn't guarded against")
		assert_eq(int(plan[1]["target"]), 2, "strikes the mugger left Open by its read strike")
	)

	run_case("ally_vs_a_lone_guarding_enemy_feints_then_strikes_and_chips", func():
		GameState.reset()
		var combat := _start_ally_armed([], [_slow_mugger(100000)], [[["guard", "guard"]]])
		var plans: Array = []
		for r in range(1, 41):
			plans.append(combat["combatants"][1]["plan"].map(func(a): return a["move"]))
			_finish_round(combat, r)
		var moves: Array = []
		for p in plans:
			moves.append_array(p)
		assert_true(moves.has("strike") and moves.has("feint"), "strikes and feints, not only guards")
		assert_true(plans.any(func(p): return p.size() >= 2 and p[0] == "feint" and p[1] == "strike"), "a Feint followed by the Strike that lands on it")
		assert_true(GameData.COMBAT_ROUNDS["allyChipStrikeChance"] is float, "chip chance is data")
	)

	run_case("turtle_patterns_never_all_guard", func():
		for id in ["turtle", "turtleV2"]:
			for pattern in GameData.COMBAT_ROUNDS["archetypes"][id]["patterns"]:
				assert_true(pattern["moves"].has("strike"), "%s pattern %s strikes" % [id, pattern["moves"]])
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

	run_case("recruits_can_equip_every_item_but_wormhole", func():
		GameState.reset()
		for recipe in GameData.LOADOUT["items"]:
			assert_eq(Loadout.is_equippable(recipe, "archie"), recipe != "wormhole", recipe)
	)

	run_case("ally_breathes_prophets_breath_for_the_player_while_an_enemy_action_is_unread", func():
		GameState.reset()
		var combat := _start_ally_armed([{ "recipe": "prophetsBreath", "tier": 4 }], [_slow_mugger()], [[["guard", "guard"]]], [[[false, true]]])
		var archie: Dictionary = combat["combatants"][1]
		assert_eq(archie["plan"][0]["move"], "prophetsBreath")
		assert_eq(int(archie["plan"][0]["target"]), CombatRounds.PLAYER_INDEX)
		assert_true(CombatRounds.is_read(combat, 1, 0), "ally item intents read")
		assert_true(archie["loadout"][0]["used"], "spent on resolution")
		assert_eq(combat["combatants"][0]["sightUntil"], 1 + int(archie["loadout"][0]["power"]), "sight for power rounds")
		GameState.reset()
		combat = _start_ally_armed([{ "recipe": "prophetsBreath", "tier": 4 }], [_slow_mugger()], [[["guard", "guard"]]])
		assert_true(not combat["combatants"][1]["plan"].any(func(a): return a["move"] == "prophetsBreath"), "held with everything read")
	)

	run_case("ally_shields_itself_from_a_read_strike", func():
		GameState.reset()
		var plan := [["guard", { "move": "strike", "target": 1 }]]
		var combat := _start_ally_armed([{ "recipe": "shield", "tier": 3 }], [_slow_mugger()], [plan])
		var archie: Dictionary = combat["combatants"][1]
		assert_eq(archie["plan"][0]["move"], "shield")
		assert_eq(int(archie["plan"][0]["target"]), 1, "self")
		assert_eq(archie["shield"], int(archie["loadout"][0]["power"]), "tier power")
		GameState.reset()
		combat = _start_ally_armed([{ "recipe": "shield", "tier": 3 }], [_slow_mugger()], [[["guard", { "move": "strike", "target": 0 }]]])
		assert_true(not combat["combatants"][1]["plan"].any(func(a): return a["move"] == "shield"), "held when nobody strikes it")
		GameState.reset()
		combat = _start_ally_armed([{ "recipe": "shield", "tier": 3, "multi": true }], [_slow_mugger()], [[["guard", { "move": "strike", "target": 0 }]]])
		archie = combat["combatants"][1]
		assert_eq(archie["plan"][0]["move"], "shield", "multi: for any struck friendly")
		assert_eq(combat["combatants"][0]["shield"], int(archie["loadout"][0]["power"]), "the team's shielded")
	)

	run_case("ally_cracks_a_time_pearl_or_black_hole_on_a_crowd", func():
		for recipe in ["timePearl", "blackHole"]:
			GameState.reset()
			var combat := _start_ally_armed([{ "recipe": recipe, "tier": 3 }], [_slow_mugger(), _slow_mugger()], [[["guard", "guard"]], [["guard", "guard"]]])
			var archie: Dictionary = combat["combatants"][1]
			var power := int(archie["loadout"][0]["power"])
			assert_eq(archie["plan"][0]["move"], recipe)
			if recipe == "timePearl":
				assert_eq(combat["combatants"][2]["actionsLost"], power, "loses power actions")
			else:
				var pulls := _actor_beats(combat["log"], 1, ["pull"])
				assert_eq(pulls.size(), 2, "both pulled")
				assert_eq(int(pulls[0]["dmg"]), power, "tier power")
	)

	run_case("ally_blasts_the_biggest_enemy_it_can_drop_else_the_weakest", func():
		GameState.reset()
		var guards := [["guard", "guard"]]
		var power := int(Crafting.effect_power("blast", 3))
		var combat := _start_ally_armed([{ "recipe": "blast", "tier": 3 }], [_slow_mugger(power + 20), _slow_mugger(power), _slow_mugger(1)], [guards, guards, guards])
		assert_eq(int(combat["combatants"][1]["plan"][0]["target"]), 3, "the biggest it drops")
		assert_eq(int(_first(combat["log"], "blast")["dmg"]), power, "tier power")
		assert_true(combat["combatants"][3]["koed"])
		GameState.reset()
		combat = _start_ally_armed([{ "recipe": "blast", "tier": 3 }], [_slow_mugger(power + 20), _slow_mugger(power + 10)], [guards, guards])
		assert_eq(int(combat["combatants"][1]["plan"][0]["target"]), 3, "none droppable: the lowest hp")
	)

	run_case("ally_powders_up_once_per_fight_and_gets_the_action", func():
		GameState.reset()
		var units := [{ "recipe": "enhancementPowder", "tier": 1 }, { "recipe": "enhancementPowder", "tier": 1 }]
		var combat := _start_ally_armed(units, [_slow_mugger(200)], [[["guard", "guard"]]])
		var archie: Dictionary = combat["combatants"][1]
		var base := CombatRounds.actions_per_round(archie)
		assert_eq(archie["plan"][0]["move"], "enhancementPowder")
		assert_eq(archie["powderUntil"], 1, "power 1: this round")
		assert_eq(archie["plan"].size(), base + 1, "the extra action joins its plan")
		_finish_round(combat, 1)
		assert_eq(archie["plan"].size(), base, "round 2 unpowered")
		assert_true(not archie["plan"].any(func(a): return a["move"] == "enhancementPowder"), "once per fight")
		assert_true(not archie["loadout"][1]["used"])
		GameState.reset()
		combat = _start_ally_armed([{ "recipe": "enhancementPowder", "tier": 5 }], [_slow_mugger(200)], [[["guard", "guard"]]])
		_finish_round(combat, 1)
		assert_eq(combat["combatants"][1]["plan"].size(), base + 1, "a long Powder's next round plans the extra action")
	)

	run_case("ally_puts_on_be_a_lady_on_round_ones_first_action", func():
		GameState.reset()
		var combat := _start_ally_armed([{ "recipe": "beALady", "tier": 4 }], [_slow_mugger(200)], [[["guard", "guard"]]])
		var archie: Dictionary = combat["combatants"][1]
		assert_eq(archie["plan"][0]["move"], "beALady")
		assert_eq(archie["ladyUntil"], int(archie["loadout"][0]["power"]), "power rounds from round 1")
		assert_eq(archie["ladyCrit"], float(GameData.COMBAT_ROUNDS["items"]["beALady"]["params"]["critChance"]))
		assert_true(CombatRounds.has_lady(combat, archie))
	)

	run_case("ally_pans_the_enemy_with_the_most_read_offence", func():
		var fields := { "panic": "panicActions", "pansRapture": "raptureActions", "panger": "angerActions", "pandemonium": "angerActions" }
		var striker := [[{ "move": "strike", "target": 0 }, { "move": "strike", "target": 0 }]]
		var guards := [["guard", "guard"]]
		for recipe in fields:
			GameState.reset()
			var combat := _start_ally_armed([{ "recipe": recipe, "tier": 2 }], [_slow_mugger(), _slow_mugger()], [guards, striker])
			var archie: Dictionary = combat["combatants"][1]
			assert_eq(archie["plan"][0]["move"], recipe)
			assert_eq(int(archie["plan"][0]["target"]), 3, "%s: the striker" % recipe)
			var mugger: Dictionary = combat["combatants"][3]
			if recipe in ["panic", "pansRapture"]:
				assert_eq(mugger[fields[recipe]], int(archie["loadout"][0]["power"]), "%s: power turns" % recipe)
			else:
				assert_eq(mugger["angerPct"], int(GameData.COMBAT_ROUNDS["anger"]["pctPerTier"]) * 2, "%s: tier percent" % recipe)
			assert_eq(mugger["fury"], recipe == "pandemonium")
		GameState.reset()
		var combat := _start_ally_armed([{ "recipe": "panic", "tier": 2 }], [_slow_mugger()], [guards])
		assert_eq(int(combat["combatants"][1]["plan"][0]["target"]), 2, "panic: a guarding enemy still bolts")
		for held in ["panger", "pandemonium"]:
			GameState.reset()
			combat = _start_ally_armed([{ "recipe": held, "tier": 2 }], [_slow_mugger()], [guards])
			assert_true(not combat["combatants"][1]["plan"].any(func(a): return a["move"] == held), "%s held on a lone guarding enemy" % held)
	)

	run_case("a_furious_enemy_turns_every_action_on_its_own_side", func():
		GameState.reset()
		var guards := [["guard", "guard"]]
		var combat := _start_vs([_slow_mugger(200), _slow_mugger(200)], [guards, guards], [{ "recipe": "pandemonium", "tier": 2 }])
		assert_true(Combat.choose_item(0, 1)["ok"])
		var intent: Dictionary = CombatRounds.enemy_intents(combat, 1)[1]
		assert_eq(intent["move"], "strike", "a planned Guard reads as a Strike")
		assert_true(intent.get("targetUnread", false))
		var hits := _actor_beats(combat["log"], 1, ["hit", "chip"])
		assert_eq(hits.size(), 1, "its Guard struck instead")
		assert_eq(int(hits[0]["target"]), 2, "at its teammate")
		GameState.reset()
		combat = _start_vs([_slow_mugger(200)], [guards], [{ "recipe": "pandemonium", "tier": 2 }])
		assert_true(Combat.choose_item(0, 1)["ok"])
		assert_eq(CombatRounds.enemy_intents(combat, 1)[1]["move"], "guard", "alone, it acts as planned")
	)

	run_case("an_allys_fizzled_or_removed_item_keeps_its_unit", func():
		GameState.reset()
		GameState.state["player"]["loadout"]["slots"][0] = { "recipe": "panic", "tier": 2 }
		var striker := [[{ "move": "strike", "target": 0 }, { "move": "strike", "target": 0 }]]
		var combat := _start_ally_armed([{ "recipe": "panic", "tier": 2 }], [_slow_mugger()], [striker], [], 1)
		var archie: Dictionary = combat["combatants"][1]
		assert_eq(archie["plan"][0]["move"], "panic")
		assert_true(Combat.choose_item(0)["ok"], "the player panics the mugger first")
		assert_true(_actor_beats(combat["log"], 1, ["fizzle"]).size() == 1, "archie's fizzles")
		assert_true(not archie["loadout"][0]["used"], "unit kept")
		GameState.reset()
		var fast := _mugger(200)
		fast["speed"] = 50
		combat = _start_ally_armed([{ "recipe": "blast", "tier": 3 }], [fast], [[[{ "move": "strike", "target": 1 }, "guard"]]], [], 1, 1)
		archie = combat["combatants"][1]
		assert_eq(archie["plan"][0]["move"], "blast")
		Combat.choose_move("guard")
		assert_true(archie["koed"], "dropped before it acts")
		assert_true(not archie["loadout"][0]["used"], "a removed action keeps its unit")
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
				assert_eq(mugger["guard"], CombatRounds.OPEN, "cowering leaves it Open")
				assert_eq(mugger["panicActions"], 1, "one panic turn left")
				assert_true(CombatRounds.is_read(combat, 1, 1), "the fogged action reads")
				var intent: Dictionary = CombatRounds.enemy_intents(combat, 1)[1]
				assert_eq([intent["move"], intent["name"], intent.get("status", false)], ["panic", "Panic", true], "as a panic intent")
				assert_eq(CombatRounds.guard_preview(combat, 1)[2], CombatRounds.OPEN, "previewed Open")
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
		assert_eq(CombatRounds.status_turn(combat, 1, 0), "", "the lost action isn't the rapture turn")
		assert_eq(CombatRounds.status_turn(combat, 1, 1), CombatRounds.STATUS_RAPTURE, "the next one is")
		Combat.choose_move("guard")
		assert_eq(mugger["raptureActions"], 1, "still pending after the loss")
	)

	run_case("pans_rapture_idles_its_actions_open", func():
		GameState.reset()
		var combat := _start_vs([_slow_mugger()], [[["strike", "strike"]]], [{ "recipe": "pansRapture", "tier": 1 }])
		var result := Combat.choose_item(0, 1)
		var mugger: Dictionary = combat["combatants"][1]
		assert_true(_kinds(result["beats"]).has("enraptured"), "idles")
		assert_eq(mugger["guard"], CombatRounds.OPEN, "idle leaves it Open")
		assert_eq(CombatRounds.enemy_intents(combat, 1)[1]["name"], "Rapture", "read rapture intent")
		result = Combat.choose_move("guard")
		assert_eq(mugger["raptureActions"], 0, "power 2 spent over two actions")
		assert_eq(GameState.state["player"]["hp"], GameState.state["player"]["hpMax"], "no strikes all round")
		assert_eq(CombatRounds.enemy_intents(combat, 1)[0]["move"], "strike", "round 2 plays its own plan")
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
		assert_eq(CombatRounds.status_badges(mugger), ["Anger +50%"], "badge")
		assert_eq(CombatRounds.stage_marks(combat)[1]["badges"], ["Anger +50%"], "on the stage")
		result = Combat.choose_move("strike", 1)
		var hit: Dictionary = _actor_beats(result["beats"], 0, ["hit", "chip"])[0]
		assert_eq(int(hit["dmg"]), _strike_dmg(hit, 0.5), "and takes -50%")
		assert_eq(mugger["angerActions"], 2)
		assert_almost_eq(CombatRounds.anger_factor(mugger, true), 0.5, 0.0001, "second phase deals -50%")
		assert_almost_eq(CombatRounds.anger_factor(mugger, false), 1.5, 0.0001, "takes +50%")
		assert_eq(CombatRounds.status_badges(mugger), ["Anger −50%"])
		Combat.choose_move("guard")
		result = Combat.choose_move("guard")
		assert_true(_kinds(result["beats"]).has("calm"), "comes down after four actions")
		assert_eq([mugger["angerActions"], mugger["angerPct"]], [0, 0])
		assert_eq(CombatRounds.anger_factor(mugger, true), 1.0)
	)

	run_case("pandemonium_turns_strikes_on_its_own_side", func():
		GameState.reset()
		var combat := _start_vs([_slow_mugger(200), _slow_mugger(200)], [[["strike", "strike"]], [["guard", "guard"]]], [{ "recipe": "pandemonium", "tier": 1 }])
		var result := Combat.choose_item(0, 1)
		assert_true(combat["combatants"][1]["fury"], "furious")
		var swing: Dictionary = _actor_beats(result["beats"], 1, ["hit", "chip"])[0]
		assert_eq(int(swing["target"]), 2, "swings at the other mugger")
		assert_eq(int(swing["dmg"]), _strike_dmg(swing, 1.25), "with tier 1's +25%")
		assert_true(CombatRounds.enemy_intents(combat, 1)[1].get("targetUnread", false), "target reads ?")
		assert_eq(CombatRounds.status_badges(combat["combatants"][1]), ["Fury +25%"])
		GameState.reset()
		combat = _start_vs([_slow_mugger(200)], [[["strike", "strike"]]], [{ "recipe": "pandemonium", "tier": 1 }])
		result = Combat.choose_item(0, 1)
		assert_eq(int(_actor_beats(result["beats"], 1, ["hit", "chip"])[0]["target"]), 0, "alone, it strikes as planned")
	)

	run_case("a_pan_statused_enemy_refuses_another", func():
		GameState.reset()
		_start_vs([_slow_mugger(200)], [[["guard", "guard"]]], [{ "recipe": "panger", "tier": 1 }, { "recipe": "panic", "tier": 1 }])
		assert_true(Combat.choose_item(0, 1)["ok"])
		assert_eq(Combat.round_item_block_reason(1, 1), CombatRounds.REASON_PAN_STATUSED, "already angry")
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
			assert_eq(CombatRounds.status_badges(mugger), ["Disarmed (2)"], "disarm badge")
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
		var entries := CombatRoundsScreen.strip_entries(combat)
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

	run_case("rewind_pays_the_way_it_is_told_to", func():
		GameState.reset()
		_start_armed([{ "recipe": "rewind", "tier": 1 }, null], [["guard", "guard"]], 1, 200)
		GameState.state["player"]["dial"] = Fixtures.dial_with_loaded("rewind", 1, 3)
		assert_true(Combat.choose_move("guard")["ok"])
		assert_true(Combat.round_rewind(Combat.REWIND_PAY_DIAL)["ok"], "the Dial pays")
		assert_eq(GameState.state["player"]["dial"]["currentCharge"], 2, "one charge")
		assert_true(Loadout.slot(0) != null, "though a unit is equipped")
		assert_true(Combat.choose_move("guard")["ok"])
		assert_true(Combat.round_rewind(Combat.REWIND_PAY_LOADOUT)["ok"], "the unit pays")
		assert_eq(Loadout.slot(0), null)
		assert_eq(GameState.state["player"]["dial"]["currentCharge"], 2, "the Dial untouched")
		assert_true(Combat.choose_move("guard")["ok"])
		assert_eq(Combat.round_rewind_block_reason(Combat.REWIND_PAY_LOADOUT), Combat.REASON_NO_REWIND, "no unit left")
	)

	run_case("rewind_steps_back_two_picks_across_a_round_with_plans_fog_and_rolls_intact", func():
		GameState.reset()
		GameState.state["player"]["loadout"]["slots"] = [{ "recipe": "rewind", "tier": 1 }, { "recipe": "rewind", "tier": 1 }]
		Combat._start_round_combat(Combat.CONTEXT_EVENT_MUGGING, null, [_mugger(200)], [], "", [], null, { "seed": 3 })
		var combat: Dictionary = GameState.state["combat"]
		assert_eq(CombatRounds.actions_this_round(combat, CombatRounds.PLAYER_INDEX), 2, "two picks a round")
		var round_no: int = combat["round"]
		var before_first := _fight_state(combat)
		var first := Combat.choose_move("guard")
		var before_second := _fight_state(combat)
		Combat.choose_move("guard")
		assert_eq(combat["round"], round_no + 1, "the second pick crossed into the next round")
		assert_true(Combat.round_rewind()["ok"])
		assert_eq(_fight_state(combat), before_first, "a tier 1 unit: back a round, to that round's plans, fog marks and RNG states")
		assert_eq(GameState.state["player"]["loadout"]["slots"], [null, { "recipe": "rewind", "tier": 1 }], "only the paying unit is spent")
		assert_eq(Combat.round_rewind_block_reason(), Combat.REASON_NOTHING_TO_UNDO, "the fight's start is as far as it goes")
		# Move XP stays earned through the Rewind, so this second Guard reaches L2.
		var replay: Array = Combat.choose_move("guard")["beats"].filter(func(b): return b["kind"] != "levelUp")
		assert_eq(replay, first["beats"], "the same pick replays the same rolls")
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

	run_case("rewind_depth_follows_the_unit_tier", func():
		for tier in range(1, 5):
			GameState.reset()
			var combat := _start_vs([_slow_mugger(200)], [[["guard", "guard"]]], [{ "recipe": "rewind", "tier": tier }])
			var at_round := { combat["round"]: _fight_plan_state(combat) }
			while combat["round"] < 6:
				var round_no: int = combat["round"]
				while combat["round"] == round_no:
					assert_true(Combat.choose_move("guard")["ok"])
				at_round[combat["round"]] = _fight_plan_state(combat)
			assert_true(Combat.round_rewind()["ok"], "tier %d" % tier)
			assert_eq(combat["round"], 6 - tier, "tier %d: back %d rounds" % [tier, tier])
			assert_eq(_fight_plan_state(combat), at_round[6 - tier], "tier %d: that round's first decision point" % tier)
			assert_eq(Loadout.slot(0), null, "the unit is spent")
	)

	run_case("a_tier_5_rewind_goes_to_the_start_and_undoes_a_round_1_enemy_action", func():
		GameState.reset()
		var enemy_first := _mugger(200)
		enemy_first["speed"] = 99
		var plan := [[{ "move": "strike", "target": CombatRounds.PLAYER_INDEX }, { "move": "strike", "target": CombatRounds.PLAYER_INDEX }]]
		var combat := _start_vs([enemy_first], [plan], [{ "recipe": "rewind", "tier": 5 }])
		var first_pause := _fight_plan_state(combat)
		var opening: Dictionary = combat["roundFrames"][0]
		assert_true(combat["combatants"][CombatRounds.PLAYER_INDEX]["hp"] < opening["combatants"][CombatRounds.PLAYER_INDEX]["hp"], "the enemy's strike landed before the first pick")
		for i in range(6):
			assert_true(Combat.choose_move("guard")["ok"])
		assert_true(combat["round"] >= 3, "a few rounds in")
		assert_true(Combat.round_rewind()["ok"])
		assert_eq(combat["round"], 1, "the fight's start")
		assert_eq(_fight_plan_state(combat), first_pause, "round 1 resolved on to the first pick again, the same rolls")
		assert_true(combat["snapshots"].is_empty(), "no pick left to step back")
		assert_true(combat["combatants"][CombatRounds.PLAYER_INDEX]["hp"] < opening["combatants"][CombatRounds.PLAYER_INDEX]["hp"], "and the strike lands again on the replay")
	)

	run_case("rewind_depth_clamps_to_the_oldest_frame", func():
		GameState.reset()
		var combat := _start_vs([_slow_mugger(200)], [[["guard", "guard"]]], [{ "recipe": "rewind", "tier": 4 }])
		while combat["round"] < 3:
			assert_true(Combat.choose_move("guard")["ok"])
		assert_true(Combat.round_rewind()["ok"])
		assert_eq(combat["round"], 1, "tier 4 from round 3 stops at round 1")
	)

	run_case("round_frames_keep_the_opening_and_the_newest_five", func():
		GameState.reset()
		var combat := _start_vs([_slow_mugger(500)], [[["guard", "guard"]]], [])
		while combat["round"] < 12:
			assert_true(Combat.choose_move("guard")["ok"])
		var rounds: Array = combat["roundFrames"].map(func(f): return int(f["round"]))
		assert_eq(rounds, [1, 8, 9, 10, 11, 12])
	)

	run_case("failsafe_undoes_a_lethal_pick_then_the_next_ko_loses", func():
		GameState.reset()
		var combat := _start_lethal([{ "recipe": "failsafe", "tier": 1 }, null])
		var result := Combat.choose_move("guard")
		assert_eq(result.get("saved", ""), Combat.LINE_FAILSAFE, "failsafe fires")
		assert_eq(combat["outcome"], null)
		assert_eq(GameState.state["player"]["hp"], 1, "back before the pick")
		assert_eq(Loadout.slot(0), null, "failsafe spent")
		assert_true(CombatRounds.decision_position(combat) >= 0, "the pick is open again")
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
		var screen: CombatRoundsScreen = host._round_screen
		screen._ready()
		var played: Array = Combat.choose_move("guard")["beats"]
		screen._refresh()
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

	run_case("a_dial_cast_takes_one_action_keeps_guard_state_and_pays_charge_and_xp", func():
		GameState.reset()
		GameState.state["player"]["dial"] = Fixtures.dial_with_loaded("blast", 1, 3)
		var combat := _start_vs([_slow_mugger(200)], [[["guard", "guard"]]], [])
		assert_true(Combat.choose_move("strike")["ok"])
		var guard: String = combat["combatants"][0]["guard"]
		var mugger_hp: int = combat["combatants"][1]["hp"]
		var power: int = combat["combatants"][0]["dial"]["casts"][0]["power"]
		var result := Combat.cast_round_complication(0, 1)
		assert_true(result["ok"], "cast at the second pause")
		assert_eq(result["beats"][0]["kind"], "blast", "the cast resolves first")
		assert_eq(result["beats"][0]["actor"], CombatRounds.PLAYER_INDEX)
		assert_eq(combat["combatants"][1]["hp"], mugger_hp - power, "item damage at the cast's power")
		assert_eq(combat["combatants"][0]["guard"], guard, "guard state unchanged")
		assert_eq(combat["round"], 2, "one action: the round's second pick")
		assert_eq(GameState.state["player"]["dial"]["currentCharge"], 2, "one charge")
		assert_eq(GameState.state["player"]["dial"]["xp"], 10, "cast XP")
		assert_eq(combat["combatants"][0]["dial"]["charge"], 2, "the view follows")
	)

	run_case("a_dial_cast_sits_on_the_timeline_and_hits_the_selected_enemy", func():
		GameState.reset()
		GameState.state["player"]["dial"] = Fixtures.dial_with_loaded("blast", 1, 3)
		var combat := _start_vs([_slow_mugger(200), _slow_mugger(200)], [[["guard", "guard"]], [["guard", "guard"]]], [])
		var first_hp: int = combat["combatants"][1]["hp"]
		var second_hp: int = combat["combatants"][2]["hp"]
		assert_true(Combat.cast_round_complication(0, 2)["ok"])
		assert_eq(combat["playerPlan"][0]["dial"], 0, "the cast holds the player's first action")
		assert_eq(CombatRoundsScreen._position_text(combat, { "actor": 0, "index": 0 }), "Blast → %s" % CombatRounds.display_name(combat["combatants"][2]))
		assert_true(combat["combatants"][2]["hp"] < second_hp, "the selected enemy")
		assert_eq(combat["combatants"][1]["hp"], first_hp, "not the other")
	)

	run_case("a_dial_cast_is_refused_without_charge_or_for_a_rewind_unit_and_costs_nothing", func():
		GameState.reset()
		GameState.state["player"]["dial"] = Fixtures.dial_with_loaded("blast", 1, 0)
		GameState.state["player"]["dial"]["loadedComplications"].append({ "recipeKey": "rewind", "tier": 1, "detent": 1 })
		_start_vs([_slow_mugger(200)], [[["guard", "guard"]]], [])
		var refused := Combat.cast_round_complication(0, 1)
		assert_true(not refused["ok"])
		assert_eq(refused["reason"], CombatRounds.REASON_NO_CHARGE)
		assert_eq(Combat.round_cast_block_reason(1), "Use Rewind for a rewind unit.")
		assert_eq(GameState.state["player"]["dial"]["xp"], 0, "no XP")
		assert_eq(CombatRounds.decision_position(GameState.state["combat"]), 0, "the pick still open")
	)

	run_case("an_allys_dial_cast_shows_in_its_plan_before_the_pick_and_spends_on_resolution", func():
		GameState.reset()
		_recruit("james")
		Dial.grant_contact_dial("james")
		var james_dial: Dictionary = Dial.dial_of("james")
		var charge: float = float(james_dial["currentCharge"])
		GameState.state["player"]["hp"] = 5
		_start_with_allies([_slow_james()], [["guard", "guard"]])
		var combat: Dictionary = GameState.state["combat"]
		var planned: Dictionary = combat["combatants"][1]["plan"][0]
		assert_eq(planned["move"], "healingBurst", "heals the hurt player")
		assert_eq(planned["target"], CombatRounds.PLAYER_INDEX)
		assert_true(planned.has("dial"), "from its Dial")
		assert_eq(CombatRoundsScreen._position_text(combat, { "actor": 1, "index": 0 }), "Healing Burst T3 (Dial) → %s" % CombatRounds.display_name(combat["combatants"][0]))
		assert_eq(float(james_dial["currentCharge"]), charge, "nothing spent at plan time")
		Combat.choose_move("guard")
		assert_true(GameState.state["player"]["hp"] > 5, "healed")
		assert_eq(float(james_dial["currentCharge"]), charge - 1.0, "one charge on resolution")
		assert_eq(int(james_dial["xp"]), 10, "cast XP")
	)

	run_case("rewind_returns_the_charge_of_every_player_and_ally_cast_since", func():
		GameState.reset()
		_recruit("james")
		Dial.grant_contact_dial("james")
		var james_dial: Dictionary = Dial.dial_of("james")
		var james_charge: float = float(james_dial["currentCharge"])
		GameState.state["player"]["dial"] = Fixtures.dial_with_loaded("blast", 1, 3)
		GameState.state["player"]["loadout"]["slots"][0] = { "recipe": "rewind", "tier": 1 }
		GameState.state["player"]["hp"] = 5
		_start_with_allies([_slow_james()], [["guard", "guard"]])
		assert_true(Combat.cast_round_complication(0, 2)["ok"])
		assert_eq(GameState.state["player"]["dial"]["currentCharge"], 2, "player cast")
		assert_eq(float(james_dial["currentCharge"]), james_charge - 1.0, "ally cast")
		assert_true(Combat.round_rewind()["ok"])
		assert_eq(GameState.state["player"]["dial"]["currentCharge"], 3, "player charge back")
		assert_eq(float(james_dial["currentCharge"]), james_charge, "ally charge back")
		assert_eq(GameState.state["player"]["dial"]["xp"], 10, "XP stays earned")
		assert_eq(GameState.state["combat"]["combatants"][0]["dial"]["charge"], 3, "the view follows")
	)

	run_case("failsafe_and_an_allys_rewind_return_the_charge_of_casts_since", func():
		GameState.reset()
		GameState.state["player"]["dial"] = Fixtures.dial_with_loaded("blast", 1, 3)
		_start_lethal([{ "recipe": "failsafe", "tier": 1 }, null])
		assert_eq(Combat.cast_round_complication(0, 1).get("saved", ""), Combat.LINE_FAILSAFE, "a lethal cast pick")
		assert_eq(GameState.state["player"]["dial"]["currentCharge"], 3, "failsafe returns it")
		GameState.reset()
		GameState.state["player"]["dial"] = Fixtures.dial_with_loaded("blast", 1, 3)
		var kit := { "items": { "rewind": { "1": 1 } }, "used": {} }
		var combat := _start_lethal([], [Combat.build_guard_ally()], { "guardKit": kit })
		assert_eq(Combat.cast_round_complication(0, 2).get("saved", ""), Combat.LINE_ALLY_REWIND % combat["combatants"][1]["name"])
		assert_eq(GameState.state["player"]["dial"]["currentCharge"], 3, "the guard's rewind returns it")
	)

	run_case("a_dial_rewind_that_paid_stays_spent_through_a_second_rewind", func():
		GameState.reset()
		GameState.state["player"]["dial"] = Fixtures.dial_with_loaded("rewind", 1, 5)
		GameState.state["player"]["dial"]["loadedComplications"].append({ "recipeKey": "blast", "tier": 1, "detent": 1 })
		_start_vs([_slow_mugger(200)], [[["guard", "guard"]]], [])
		assert_true(Combat.choose_move("guard")["ok"])
		assert_true(Combat.cast_round_complication(1, 1)["ok"])
		assert_eq(GameState.state["player"]["dial"]["currentCharge"], 4, "blast cast")
		assert_true(Combat.round_rewind()["ok"])
		assert_eq(GameState.state["player"]["dial"]["currentCharge"], 4, "blast back, rewind paid")
		assert_true(Combat.choose_move("guard")["ok"])
		assert_true(Combat.round_rewind()["ok"])
		assert_eq(GameState.state["player"]["dial"]["currentCharge"], 3, "the second payment stays spent too")
	)

	run_case("tier_5_recharge_regens_a_charge_every_third_action_and_rewind_takes_it_back", func():
		GameState.reset()
		_recruit("james")
		Dial.grant_contact_dial("james")
		var recharge := { "archetype": "recharge", "oreType": "time", "tier": 5 }
		var james_dial: Dictionary = Dial.dial_of("james")
		james_dial["movement"] = recharge.duplicate()
		james_dial["currentCharge"] = 0
		var dial := Fixtures.dial_with_loaded("blast", 1, 1)
		dial["movement"] = recharge.duplicate()
		GameState.state["player"]["dial"] = dial
		GameState.state["player"]["loadout"]["slots"][0] = { "recipe": "rewind", "tier": 1 }
		Combat._start_round_combat(Combat.CONTEXT_EVENT_MUGGING, null, [_slow_mugger(200)], [], "", [_slow_james()], null,
			{ "seed": 1, "fog": false, "enemyPlans": [[["guard", "guard"]]], "allyPlans": [[["guard", "guard"]]] })
		Combat.choose_move("guard")
		Combat.choose_move("guard")
		assert_eq(float(dial["currentCharge"]), 1.0, "two actions: nothing yet")
		assert_eq(dial["combatRegenTurnCounter"], 2)
		Combat.choose_move("guard")
		assert_eq(float(dial["currentCharge"]), 2.0, "the third action regens one")
		assert_eq(float(james_dial["currentCharge"]), 1.0, "the ally's third action too")
		assert_true(Combat.round_rewind()["ok"])
		assert_eq(float(dial["currentCharge"]), 1.0, "rewind takes the regen back")
		assert_eq(dial["combatRegenTurnCounter"], 0, "and the count, from the round's start")
		assert_eq(float(james_dial["currentCharge"]), 0.0)
	)

	run_case("live_screen_shows_the_dial_and_its_trigger_casts_a_pick", func():
		GameState.reset()
		GameState.state["player"]["dial"] = Fixtures.dial_with_loaded("blast", 1, 3)
		_start_vs([_slow_mugger(200)], [[["guard", "guard"]]], [])
		var host := CombatScreen.new()
		host._ready()
		var screen: CombatRoundsScreen = host._round_screen
		screen._ready()
		var live_nodes: Array = screen._dock.find_children("*", "", true, false).filter(func(n): return not n.is_queued_for_deletion())
		var widgets: Array = live_nodes.filter(func(n): return n is DialWidget)
		assert_eq(widgets.size(), 1, "the Dial in the dock")
		assert_eq(live_nodes.filter(func(n): return n.name == "ComplicationRow").size(), 1, "its readout heads the rows")
		widgets[0].handle_trigger()
		assert_eq(GameState.state["player"]["dial"]["currentCharge"], 2, "cast through the round engine")
		assert_eq(CombatRounds.decision_position(GameState.state["combat"]), 1, "it took the first action")
		host.free()
	)

	run_case("live_dock_rewind_runs_from_its_loadout_slot_and_from_a_dial_rewind_complication", func():
		GameState.reset()
		_start_armed([{ "recipe": "rewind", "tier": 1 }, { "recipe": "rewind", "tier": 1 }], [["guard", "guard"]], 1, 200)
		var host := CombatScreen.new()
		host._ready()
		var screen: CombatRoundsScreen = host._round_screen
		screen._ready()
		var slot := _row(screen, "ItemRow_0")
		assert_true(slot.disabled, "nothing to undo yet")
		assert_eq(slot.tooltip_text, Combat.REASON_NOTHING_TO_UNDO, "the Rewind command's reason")
		_row(screen, "MoveRow_guard").pressed.emit()
		slot = _row(screen, "ItemRow_0")
		assert_true(not slot.disabled, "a pick to undo")
		slot.pressed.emit()
		assert_eq(Loadout.slot(0), null, "the slot paid for the Rewind")
		assert_eq(CombatRounds.decision_position(GameState.state["combat"]), 0, "the pick undone")

		GameState.state["player"]["dial"] = Fixtures.dial_with_loaded("rewind", 1, 3)
		_row(screen, "MoveRow_guard").pressed.emit()
		var widgets: Array = screen._dock.find_children("*", "", true, false).filter(func(n): return n is DialWidget and not n.is_queued_for_deletion())
		widgets[0].handle_trigger()
		assert_eq(GameState.state["player"]["dial"]["currentCharge"], 2, "the Dial paid for the Rewind")
		assert_true(Loadout.slot(1) != null, "the equipped rewind unit untouched")
		assert_eq(CombatRounds.decision_position(GameState.state["combat"]), 0, "the pick undone")
		host.free()
	)

	# ── Kits as planned intents (R§3.7b Table 5) ──────────────────────────

	run_case("a_raider_kit_blast_takes_the_first_strike_and_spends_on_resolution", func():
		GameState.reset()
		var hp: int = GameState.state["player"]["hp"]
		var kit := { "items": { "blast": { "2": 1 } }, "used": {} }
		Combat._start_round_combat(Combat.CONTEXT_EVENT_MUGGING, null, [_slow_mugger(200)], [], "", [], null,
			{ "seed": 1, "fog": false, "enemyPlans": [_strikes_at_player()] }, { "raiderKit": kit })
		var combat: Dictionary = GameState.state["combat"]
		var plan: Array = combat["combatants"][1]["plan"]
		assert_eq(plan[0]["move"], "blast", "the first Strike becomes the kit item")
		assert_eq(plan[0]["target"], CombatRounds.PLAYER_INDEX, "at the Strike's target")
		assert_eq(plan[1]["move"], "strike", "one item per enemy per round")
		assert_eq(combat["raiderKit"]["items"], {}, "reserved at commit")
		assert_eq(combat["raiderKit"]["used"], {}, "not spent yet")
		var beats: Array = Combat.choose_move("guard")["beats"]
		var blast := _first(beats, "blast")
		var power := int(GameData.RECIPES["blast"]["effectPower"][2])
		assert_eq(int(blast["actor"]), 1, "the mugger lets it off")
		assert_eq(int(blast["dmg"]), power, "at its tier's power, guard or no guard")
		assert_eq(GameState.state["player"]["hp"], hp - power)
		assert_eq(combat["raiderKit"]["used"], { "blast": { "2": 1 } }, "spent on resolution")
		assert_eq(combat["raiderKit"]["reserved"], {})
	)

	run_case("raider_kit_rule_order_heals_a_hurt_teammate_then_shields_itself", func():
		GameState.reset()
		var hurt := _slow_mugger(200)
		hurt["hp"] = 40
		var kit := { "items": { "healingBurst": { "1": 1 }, "shield": { "1": 1 } }, "used": {} }
		Combat._start_round_combat(Combat.CONTEXT_EVENT_MUGGING, null, [_slow_mugger(200), hurt], [], "", [], null,
			{ "seed": 1, "fog": false, "enemyPlans": [_strikes_at_player(), _strikes_at_player()] }, { "raiderKit": kit })
		var combat: Dictionary = GameState.state["combat"]
		var first: Dictionary = combat["combatants"][1]["plan"][0]
		assert_eq(first["move"], "healingBurst", "the first enemy heals")
		assert_eq(first["target"], 2, "its hurt teammate")
		assert_eq(combat["combatants"][2]["plan"][0]["move"], "shield", "the second, no patient left, shields itself")
		assert_eq(combat["combatants"][2]["plan"][0]["target"], 2)
	)

	run_case("unread_kit_intents_show_unread_until_they_resolve", func():
		GameState.reset()
		var kit := { "items": { "blast": { "1": 1 } }, "used": {} }
		Combat._start_round_combat(Combat.CONTEXT_EVENT_MUGGING, null, [_slow_mugger(200)], [], "", [], null,
			{ "seed": 1, "fog": true, "enemyPlans": [_strikes_at_player()], "enemyUnread": [[[true, false]]] }, { "raiderKit": kit })
		var combat: Dictionary = GameState.state["combat"]
		assert_eq(combat["combatants"][1]["plan"][0]["move"], "blast")
		assert_true(CombatRounds.enemy_intents(combat, 1)[0].get("unread", false), "the item hides behind ?")
		Combat.choose_move("guard")
		assert_eq(CombatRounds.enemy_intents(combat, 1)[0]["move"], "blast", "read once it resolves")
	)

	run_case("a_kit_unit_whose_action_never_resolves_goes_back_to_the_pool", func():
		GameState.reset()
		var kit := { "items": { "blast": { "1": 1 } }, "used": {} }
		Combat._start_round_combat(Combat.CONTEXT_EVENT_MUGGING, null, [_slow_mugger(1), _slow_mugger(200)], [], "", [], null,
			{ "seed": 1, "fog": false, "enemyPlans": [_strikes_at_player(), [["guard", "guard"], _strikes_at_player()[0]]] }, { "raiderKit": kit })
		var combat: Dictionary = GameState.state["combat"]
		assert_eq(combat["combatants"][1]["plan"][0]["move"], "blast", "the frail mugger holds the Blast")
		Combat.choose_move("strike", 1)
		assert_true(combat["combatants"][1]["koed"], "and goes down before using it")
		Combat.choose_move("guard")
		assert_eq(combat["round"], 2)
		assert_eq(combat["raiderKit"]["used"], {}, "never spent")
		assert_eq(combat["combatants"][2]["plan"][0]["move"], "blast", "back in the pool for round 2's commit")
	)

	run_case("a_guard_plans_its_kit_items_and_the_vein_kit_settles_as_before", func():
		_seeded()
		GameState.state["player"]["veins"].append({ "id": "gv", "district": "battersea", "security": Cultivating.GUARDED_TIER_ID, "extraGuards": 0,
			"guardKit": { "blast": { "2": 1 } } })
		Combat.start_defend_vein("gv", 2)
		var combat: Dictionary = GameState.state["combat"]
		var guard: int = CombatRounds.PLAYER_INDEX + 1
		assert_true(combat["combatants"][guard]["name"].begins_with(GameData.GUARD_KIT["guardAlly"]["name"]), "the guard joins")
		var blasts: Array = combat["combatants"][guard]["plan"].filter(func(a): return a["move"] == "blast")
		assert_eq(blasts.size(), 1, "it plans the Blast")
		assert_true(blasts[0].get("kit", "") == CombatRounds.KIT_GUARD, "from the guard kit")
		for _i in range(CombatRounds.actions_this_round(combat, CombatRounds.PLAYER_INDEX)):
			if combat["outcome"] == null and combat["round"] == 1:
				Combat.choose_move("guard")
		assert_eq(combat["guardKit"]["used"], { "blast": { "2": 1 } }, "spent on resolution")
		combat["outcome"] = "loss"
		Combat.exit_combat()
		assert_eq(Cultivating.find_vein("gv")["guardKit"], {}, "off the vein's kit at exit")
	)

	run_case("a_guards_own_failsafe_holds_it_on_1_hp_once_per_unit", func():
		GameState.reset()
		var guard := Combat.build_guard_ally()
		guard["hp"] = 1
		var kit := { "items": { "failsafe": { "1": 1 } }, "used": {} }
		var at_guard := [[{ "move": "strike", "target": 1 }, { "move": "strike", "target": 1 }]]
		Combat._start_round_combat(Combat.CONTEXT_EVENT_MUGGING, null, [_slow_mugger(200)], [], "", [guard], null,
			{ "seed": 1, "fog": false, "enemyPlans": [at_guard], "allyPlans": [[["guard", "guard"]]] }, { "guardKit": kit })
		var combat: Dictionary = GameState.state["combat"]
		assert_eq(combat["combatants"][1]["plan"].filter(func(a): return a["move"] == "failsafe").size(), 0, "never planned")
		var beats: Array = Combat.choose_move("guard")["beats"]
		assert_true(not _first(beats, "failsafe").is_empty(), "it fires on the lethal hit")
		assert_eq(combat["combatants"][1]["hp"], 1, "back on 1 hp")
		assert_true(not combat["combatants"][1]["koed"], "still standing")
		assert_eq(combat["guardKit"]["used"], { "failsafe": { "1": 1 } }, "one unit spent")
		Combat.choose_move("guard")
		assert_true(combat["combatants"][1]["koed"], "none left: KO'd")
	)

	run_case("a_recruits_failsafe_slot_saves_it_and_settles_as_used", func():
		GameState.reset()
		_recruit("archie")
		var archie := Contacts.build_combat_ally("archie")
		archie["hp"] = 1
		archie["level"] = 1
		archie["slots"] = [{ "recipe": "failsafe", "tier": 1 }, null]
		var at_archie := [[{ "move": "strike", "target": 1 }, { "move": "strike", "target": 1 }]]
		Combat._start_round_combat(Combat.CONTEXT_EVENT_MUGGING, null, [_slow_mugger(200)], [], "", [archie], null,
			{ "seed": 1, "fog": false, "enemyPlans": [at_archie], "allyPlans": [[["guard", "guard"]]] })
		var combat: Dictionary = GameState.state["combat"]
		var beats: Array = Combat.choose_move("guard")["beats"]
		assert_true(not _first(beats, "failsafe").is_empty(), "the slot's failsafe fires")
		assert_eq(combat["combatants"][1]["hp"], 1)
		assert_true(not combat["allies"][0]["koed"])
		assert_eq(combat["allies"][0]["slotsUsed"], [0], "the slot settles as used")
		Combat.choose_move("guard")
		assert_true(combat["allies"][0]["koed"], "none left: KO'd")
	)

	run_case("a_rewind_to_before_an_allys_failsafe_returns_the_unit", func():
		GameState.reset()
		GameState.state["player"]["loadout"]["slots"][0] = { "recipe": "rewind", "tier": 1 }
		var guard := Combat.build_guard_ally()
		guard["hp"] = 1
		var kit := { "items": { "failsafe": { "1": 1 } }, "used": {} }
		var at_guard := [[{ "move": "strike", "target": 1 }, { "move": "strike", "target": 1 }]]
		Combat._start_round_combat(Combat.CONTEXT_EVENT_MUGGING, null, [_slow_mugger(200)], [], "", [guard], null,
			{ "seed": 1, "fog": false, "enemyPlans": [at_guard], "allyPlans": [[["guard", "guard"]]] }, { "guardKit": kit })
		var combat: Dictionary = GameState.state["combat"]
		Combat.choose_move("guard")
		assert_eq(combat["guardKit"]["used"], { "failsafe": { "1": 1 } })
		assert_true(Combat.round_rewind()["ok"])
		assert_eq(combat["guardKit"]["used"], {}, "the save is undone")
		assert_eq(combat["guardKit"]["items"], { "failsafe": { "1": 1 } }, "and its unit back")
		assert_eq(combat["combatants"][1]["hp"], 1)
	)

	run_case("a_reinforcement_enters_at_the_round_boundary_with_a_committed_plan", func():
		GameState.reset()
		var combat := _start_reinforced(4)
		assert_eq([combat["enemies"].size(), combat["enemyQueue"].size()], [3, 1], "three fight, one waits")
		assert_eq(CombatRounds.side_indices(combat, CombatRounds.SIDE_ENEMY).size(), 3)
		var first: int = CombatRounds.side_indices(combat, CombatRounds.SIDE_ENEMY)[0]
		combat["combatants"][first]["hp"] = 1
		var round_no: int = combat["round"]
		assert_true(Combat.choose_move("strike", first)["ok"])
		assert_true(combat["combatants"][first]["koed"])
		if combat["round"] == round_no:
			assert_eq(combat["enemyQueue"].size(), 1, "still waiting mid-round")
		_finish_round(combat, round_no)
		assert_eq(combat["enemyQueue"], [], "the queue's spent")
		assert_eq(combat["enemies"].size(), 4, "the entrant joins the live roster")
		var entrant: int = combat["combatants"].size() - 1
		var fighter: Dictionary = combat["combatants"][entrant]
		assert_eq(fighter["side"], CombatRounds.SIDE_ENEMY)
		assert_eq(fighter["rid"], 3, "the fourth generated enemy")
		assert_true(not combat["enemies"][3].has("fighter"), "the live entry sheds its prebuilt combatant")
		assert_eq(fighter["plan"].size(), CombatRounds.actions_per_round(fighter), "a plan committed for its first round")
		assert_true(not fighter["nextPlan"].is_empty(), "and the round after's rolled")
		var entered: Array = combat["log"].filter(func(b): return b["kind"] == "enter")
		assert_eq(entered.map(func(b): return [b["actor"], b["round"]]), [[entrant, round_no + 1]], "one entry beat, at the boundary")
		assert_eq(CombatRoundsScreen.stage_roster(combat, -1)["combat"]["enemyQueue"], [], "no reserve left on the stage")
	)

	run_case("an_empty_enemy_field_ends_the_round_at_once_for_the_reserves", func():
		GameState.reset()
		var combat := _start_reinforced(4)
		var foes: Array = CombatRounds.side_indices(combat, CombatRounds.SIDE_ENEMY)
		for i in [foes[0], foes[1]]:
			combat["combatants"][i]["hp"] = 0
			combat["combatants"][i]["koed"] = true
		combat["combatants"][foes[2]]["hp"] = 1
		var round_no: int = combat["round"]
		assert_true(Combat.choose_move("strike", foes[2])["ok"])
		assert_eq(combat["round"], round_no + 1, "no picks against an empty field")
		assert_eq(combat["enemyQueue"], [], "the reserve's in")
		assert_eq(combat["outcome"], null)
		assert_eq(CombatRounds.decision_position(combat), 0, "paused on the new round's first pick")
	)

	run_case("a_rewind_across_an_entry_puts_the_entrant_back_in_the_queue", func():
		GameState.reset()
		GameState.state["player"]["loadout"]["slots"][0] = { "recipe": "rewind", "tier": 1 }
		var combat := _start_reinforced(4)
		var reserve: Array = CombatRoundsScreen.stage_roster(combat, -1)["combat"]["enemyQueue"]
		assert_eq(reserve.map(func(e): return e["rid"]), [3], "the reserve shows on the stage by rid")
		var first: int = CombatRounds.side_indices(combat, CombatRounds.SIDE_ENEMY)[0]
		combat["combatants"][first]["hp"] = 1
		var round_no: int = combat["round"]
		Combat.choose_move("strike", first)
		_finish_round(combat, round_no)
		var count: int = combat["combatants"].size()
		assert_true(Combat.round_rewind()["ok"])
		assert_eq(combat["round"], round_no, "back before the boundary")
		assert_eq(combat["combatants"].size(), count - 1, "the entrant's gone")
		assert_eq(combat["enemies"].size(), 3)
		assert_eq(combat["enemyQueue"].size(), 1, "waiting again")
		assert_true(combat["enemyQueue"][0].has("fighter"), "with its combatant")
	)

	run_case("a_player_ko_with_an_ally_standing_plays_on_to_the_end", func():
		GameState.reset()
		GameState.state["player"]["hp"] = 1
		Combat._start_round_combat(Combat.CONTEXT_EVENT_MUGGING, null, [_slow_mugger(12)], [], "", [Combat.build_guard_ally()], null,
			{ "seed": 1, "fog": false, "enemyPlans": [_strikes_at_player()], "allyPlans": [[["strike", "strike"]]] })
		var combat: Dictionary = GameState.state["combat"]
		var result := Combat.choose_move("guard")
		assert_true(combat["playerKoed"], "the player's down")
		assert_true(not result.has("saved"))
		var player_ko: int = result["beats"].find_custom(func(b): return b["kind"] == "ko" and int(b["target"]) == CombatRounds.PLAYER_INDEX)
		assert_true(player_ko >= 0, "the player's KO plays")
		assert_true(result["beats"].slice(player_ko + 1).any(func(b): return int(b["actor"]) == 1), "the guard fights on after it")
		assert_true(not result["beats"].slice(player_ko + 1).any(func(b): return int(b["actor"]) == CombatRounds.PLAYER_INDEX), "the player's actions are gone")
		assert_eq(combat["outcome"], "win", "the guard finishes it")
		assert_true(combat["combatants"][2]["koed"], "the mugger's down")
		assert_eq(GameState.state["player"]["hp"], maxi(1, GameState.round_epsilon(GameState.state["player"]["hpMax"] * Combat.PLAYER_KO_HP_FRACTION)), "KO hp after an ally-won win")
	)

	run_case("a_player_ko_frees_a_place_for_the_queued_ally", func():
		GameState.reset()
		GameState.state["player"]["hp"] = 1
		var guards: Array = range(3).map(func(_i): return Combat.build_guard_ally())
		var guarding: Array = guards.map(func(_g): return [["guard", "guard"]])
		Combat._start_round_combat(Combat.CONTEXT_EVENT_MUGGING, null, [_slow_mugger(200)], [], "", guards, null,
			{ "seed": 1, "fog": false, "enemyPlans": [_strikes_at_player()], "allyPlans": guarding })
		var combat: Dictionary = GameState.state["combat"]
		assert_eq(combat["allyQueue"].size(), 1)
		var result := Combat.choose_move("guard")
		assert_true(combat["playerKoed"])
		assert_eq(combat["allyQueue"], [], "the third guard came in")
		assert_eq(combat["allies"].size(), 3)
		var entered: Array = result["beats"].filter(func(b): return b["kind"] == "enter")
		assert_eq(entered.size(), 1)
		assert_eq(combat["combatants"][int(entered[0]["actor"])]["name"], "%s C" % Combat.build_guard_ally()["name"], "lettered with the rest")
		assert_eq(combat["outcome"], "loss", "guards who only guard go down in the end")
		assert_true(combat["allies"].all(func(a): return a["koed"]), "every friendly down before the loss")
	)

	run_case("a_player_ko_with_no_friendly_left_is_a_loss", func():
		GameState.reset()
		var combat := _start_lethal([null, null])
		var result := Combat.choose_move("guard")
		assert_eq(combat["outcome"], "loss")
		assert_true(not combat["playerKoed"], "nothing played on")
		assert_eq(result["beats"].back()["kind"], "ko", "the fight ends on the KO")
	)

	run_case("move_xp_resolved_use_10_fizzled_use_4", func():
		GameState.reset()
		var combat := _start([["guard", "guard"]], 1, 200)
		var record: Dictionary = GameState.state["player"]["moveLevels"]
		Combat.choose_move("strike")
		assert_eq(record["strike"]["xp"], 10, "a resolved Strike")
		var stun := Combat.choose_move("stun")
		assert_true(stun["beats"].any(func(b): return b["kind"] == "fizzle" and b["actor"] == CombatRounds.PLAYER_INDEX), "Stun on a Guarded mugger fizzles")
		assert_eq(record["stun"]["xp"], 4, "a fizzled Stun")
		assert_eq(record["guard"]["xp"], 0, "untouched moves")
		assert_eq(combat["combatants"][1]["moveOwner"], null, "the mugger has no record")
	)

	run_case("an_evaded_strike_and_a_failed_leg_it_are_fizzles", func():
		GameState.reset()
		var slippery := _mugger(200)
		slippery["evadeChance"] = 1.0
		Combat._start_round_combat(Combat.CONTEXT_EVENT_MUGGING, null, [slippery], [], "", [], null,
			{ "seed": 1, "fog": false, "enemyPlans": [[["guard", "guard"]]] })
		var strike := Combat.choose_move("strike")
		assert_true(strike["beats"].any(func(b): return b["kind"] == "evade"), "the Strike hits air")
		assert_eq(GameState.state["player"]["moveLevels"]["strike"]["xp"], 4, "an evaded Strike")
		var seen := {}
		for seed_value in range(1, 40):
			GameState.reset()
			_start([["guard", "guard"]], seed_value, 200)
			var kinds: Array = Combat.choose_move("legIt")["beats"].map(func(b): return b["kind"])
			var kind: String = "fleeFailed" if kinds.has("fleeFailed") else "fled"
			if seen.has(kind):
				continue
			seen[kind] = true
			assert_eq(GameState.state["player"]["moveLevels"]["legIt"]["xp"], 4 if kind == "fleeFailed" else 10, "Leg it %s" % kind)
		assert_eq(seen.size(), 2, "both a failed and a clean Leg it seen")
	)

	run_case("move_level_ups_at_the_thresholds_cap_at_5_with_one_notification_and_line", func():
		GameState.reset()
		var combat := _start([["guard", "guard"]], 1, 400)
		var strike: Dictionary = GameState.state["player"]["moveLevels"]["strike"]
		strike["xp"] = 20
		var notes_before: int = GameState.state["notifications"].size()
		var result := Combat.choose_move("strike")
		var ups: Array = result["beats"].filter(func(b): return b["kind"] == "levelUp")
		assert_eq(ups.size(), 1, "30 XP reaches L2")
		assert_eq(strike["level"], 2)
		assert_eq(combat["combatants"][CombatRounds.PLAYER_INDEX]["moveLevels"]["strike"], 2, "the fight level follows")
		assert_eq(ups[0]["text"], "Your Strike is coming on. Level 2.")
		assert_eq(combat["transcript"].count(ups[0]["text"]), 1, "one transcript line")
		assert_eq(GameState.state["notifications"].size(), notes_before + 1, "one Notification")
		assert_eq(GameState.state["notifications"].back()["text"], ups[0]["text"])
		for pair in [[2, 89, 3], [3, 199, 4], [4, 399, 5]]:
			strike["level"] = pair[0]
			strike["xp"] = pair[1]
			Combat.choose_move("strike")
			assert_eq(strike["level"], pair[2], "L%d at its threshold" % pair[2])
		Combat.choose_move("strike")
		assert_eq(strike["level"], 5, "capped at 5")
		assert_eq(strike["xp"], 419, "XP still counts past the cap")
		assert_eq(MoveLevels.level_for_xp(29), 1)
		assert_eq(MoveLevels.level_for_xp(30), 2)
		assert_eq(MoveLevels.level_for_xp(90), 3)
		assert_eq(MoveLevels.level_for_xp(200), 4)
		assert_eq(MoveLevels.level_for_xp(400), 5)
		assert_eq(MoveLevels.level_for_xp(9999), 5)
	)

	run_case("rewind_keeps_move_xp_and_levels", func():
		GameState.reset()
		GameState.state["player"]["loadout"]["slots"] = [{ "recipe": "rewind", "tier": 1 }, { "recipe": "rewind", "tier": 1 }]
		Combat._start_round_combat(Combat.CONTEXT_EVENT_MUGGING, null, [_mugger(200)], [], "", [], null,
			{ "seed": 3, "fog": false, "enemyPlans": [[["guard", "guard"]]] })
		var combat: Dictionary = GameState.state["combat"]
		var strike: Dictionary = GameState.state["player"]["moveLevels"]["strike"]
		strike["xp"] = 20
		Combat.choose_move("strike")
		assert_eq(strike["level"], 2)
		assert_true(Combat.round_rewind()["ok"])
		assert_eq(strike["xp"], 30, "the XP stays earned")
		assert_eq(strike["level"], 2, "so does the level")
		assert_eq(combat["combatants"][CombatRounds.PLAYER_INDEX]["moveLevels"]["strike"], 2, "the fight level comes back from the record")
		Combat.choose_move("strike")
		assert_eq(strike["xp"], 40, "replaying the pick earns again")
	)

	run_case("recruits_earn_move_xp_template_allies_do_not", func():
		GameState.reset()
		Combat._start_round_combat(Combat.CONTEXT_EVENT_MUGGING, null, [_mugger(400)], [], "",
			[Contacts.build_combat_ally("archie"), Combat.build_guard_ally()], null,
			{ "seed": 1, "fog": false, "enemyPlans": [[["guard", "guard"]]], "allyPlans": [[["guard", "guard"]], [["guard", "guard"]]] })
		var combat: Dictionary = GameState.state["combat"]
		for i in range(2):
			Combat.choose_move("guard")
		var archie: int = combat["combatants"].find_custom(func(c): return c.get("moveOwner") == "archie")
		assert_true(archie > 0, "archie fights on his own record")
		var guards: int = combat["log"].filter(func(b): return b["actor"] == archie and b["kind"] == "guard").size()
		assert_true(guards > 0, "archie guarded")
		assert_eq(GameState.state["contacts"]["archie"]["moveLevels"]["guard"]["xp"], guards * 10, "10 per resolved Guard")
		var hired: Dictionary = combat["combatants"].filter(func(c): return c["side"] == CombatRounds.SIDE_ALLY and c.get("moveOwner") == null)[0]
		assert_eq(hired["moveLevels"].size(), MoveLevels.move_ids().size(), "the hired guard rolled its levels")
	)

	run_case("rolled_move_levels_follow_the_weights_seeded", func():
		var rng := RandomNumberGenerator.new()
		rng.seed = 42
		var counts := { 3: 0, 2: 0, 1: 0 }
		var trials := 2000
		for i in range(trials):
			for level in MoveLevels.roll(3, rng).values():
				counts[level] += 1
		var total := float(trials * MoveLevels.move_ids().size())
		assert_true(absf(counts[3] / total - 0.5) < 0.02, "own level ~50%% (%d)" % counts[3])
		assert_true(absf(counts[2] / total - 0.3) < 0.02, "one below ~30%% (%d)" % counts[2])
		assert_true(absf(counts[1] / total - 0.2) < 0.02, "two below ~20%% (%d)" % counts[1])
		for i in range(50):
			assert_true(MoveLevels.roll(1, rng).values().all(func(l): return l == 1), "minimum 1")
		GameState.reset()
		Combat.start_debug_combat({ "context": Combat.CONTEXT_RAID, "enemies": [{ "template": "veinGuard", "level": 4 }], "seed": 9 })
		var first: Dictionary = GameState.state["combat"]["combatants"][1]["moveLevels"].duplicate()
		assert_true(first.values().all(func(l): return l >= 2 and l <= 4), "within two below level 4")
		GameState.reset()
		Combat.start_debug_combat({ "context": Combat.CONTEXT_RAID, "enemies": [{ "template": "veinGuard", "level": 4 }], "seed": 9 })
		assert_eq(GameState.state["combat"]["combatants"][1]["moveLevels"], first, "seeded off the fight")
		assert_eq(GameState.state["combat"]["combatants"][0]["moveLevels"], MoveLevels.levels_of(""), "the player's are its own")
	)

	run_case("fight_list_rows_carry_a_level_badge", func():
		var dock := CombatCommandDock.new()
		dock.configure([{ "name": "MoveRow_strike", "label": "Strike", "badge": "L3" }], [], { "name": "LegIt", "label": "Leg it" })
		var badge: Label = dock.find_child("LevelBadge", true, false)
		assert_true(badge != null, "badge drawn")
		assert_eq(badge.text, "L3")
		dock.free()
		GameState.reset()
		GameState.state["contacts"]["archie"]["moveLevels"]["feint"]["level"] = 3
		assert_true(ProfileApp.move_levels_text("archie").contains("Feint Lv3"), "a recruit's levels on Profile")
		assert_eq(MoveLevels.summary("")[0]["xpNext"], 30, "L1 shows the L2 threshold")
	)

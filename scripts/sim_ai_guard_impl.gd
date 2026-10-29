extends RefCounted

# Body of scripts/sim_ai_guard.gd (see there for usage). Each fight opens
# through Combat._start_round_combat() on a fresh GameState with recruited
# Archie and is driven through Combat.choose_move(); the move shares are read
# off the fight's beat log afterwards.

const ROUND_CAP := 60
const STRIKE_KINDS := ["hit", "chip", "block", "evade", "stun", "stunThrough", "fizzle"]
const SETUPS := [
	{ "label": "mugger + Archie", "enemies": ["mugger"], "archie": true },
	{ "label": "2 muggers + Archie", "enemies": ["mugger", "mugger"], "archie": true },
	{ "label": "bruiser + turtle + Archie", "enemies": ["bruiser", "turtle"], "archie": true },
	{ "label": "turtle + Archie", "enemies": ["turtle"], "archie": true },
	{ "label": "mugger solo (no ally)", "enemies": ["mugger"], "archie": false },
	{ "label": "all-guard enemy + Archie", "enemies": ["mugger"], "archie": true, "plans": [[["guard", "guard"]]] },
	{ "label": "all-guard hard mugger + Archie L1", "enemies": ["muggerV2"], "archie": true, "level": 1, "plans": [[["guard", "guard"]]] },
	{ "label": "all-guard hard mugger + Archie L3", "enemies": ["muggerV2"], "archie": true, "level": 3, "plans": [[["guard", "guard"]]] },
	{ "label": "L3 hard mugger + Archie", "enemies": ["muggerV2"], "archie": true, "level": 3 },
	{ "label": "L5 2 bruiserV2 + turtleV2 + Archie", "enemies": ["bruiserV2", "bruiserV2", "turtleV2"], "archie": true, "level": 5 },
]
const POLICIES := ["strike", "guard"]

# dump=<setup index>: also prints the beat-kind histogram of that setup's first
# guard-policy fight.
var dump_setup := -1


func run(raw: Dictionary) -> void:
	var n := int(raw.get("n", "200"))
	dump_setup = int(raw.get("dump", "-1"))
	if raw.has("chip"):
		GameData.COMBAT_ROUNDS["allyChipStrikeChance"] = float(raw["chip"])
	var base_seed := int(raw.get("seed", "1"))
	print("AI guard sim: n=%d seed=%d fog on, player level per setup" % [n, base_seed])
	print("%-28s %-6s | %-17s | %-17s | %-17s | %6s %4s %5s %6s %5s | %s" % [
		"setup", "player", "player S/G/F %", "ally S/G/F %", "enemy S/G/F %",
		"rounds", "p90", "win%", "noDmg%", "tmout", "ally guard: threat/fallback/chipStrike"])
	for s in range(SETUPS.size()):
		for policy in POLICIES:
			_run_setup(SETUPS[s], policy, n, base_seed, s)
	GameState.reset()


func _run_setup(setup: Dictionary, policy: String, n: int, base_seed: int, s: int) -> void:
	var rounds: Array = []
	var wins := 0
	var timeouts := 0
	var shares := { "player": [0, 0, 0], "ally": [0, 0, 0], "enemy": [0, 0, 0] }
	var dmg_rounds := 0
	var all_rounds := 0
	var reasons := { "threat": 0, "fallback": 0, "chip": 0 }
	for i in range(n):
		var fight_seed: int = base_seed * 1000003 + s * 10007 + i
		GameState.reset()
		Rng.set_seed(fight_seed)
		_open(setup, fight_seed)
		var cp: Dictionary = GameState.state["combat"]
		var outcome = cp["outcome"]
		var seen_round := 0
		while outcome == null and int(cp["round"]) <= ROUND_CAP:
			if int(cp["round"]) != seen_round:
				seen_round = int(cp["round"])
				_classify_allies(cp, reasons)
			var move: String = CombatRounds.MOVE_STRIKE if policy == "strike" else CombatRounds.MOVE_GUARD
			var result := Combat.choose_move(move, -1)
			cp = GameState.state["combat"]
			if not result["ok"]:
				outcome = cp["outcome"]
				break
			outcome = result["outcome"]
		rounds.append(int(cp["round"]))
		if outcome == null:
			timeouts += 1
		elif outcome == "win":
			wins += 1
		var damaged := {}
		if i == 0 and s == dump_setup and policy == "guard":
			var hist := {}
			for beat in cp["log"]:
				hist[beat["kind"]] = int(hist.get(beat["kind"], 0)) + 1
			print("  kinds: %s" % str(hist))
		for beat in cp["log"]:
			var side := _side_of(cp, int(beat["actor"]))
			var col := -1
			if beat["kind"] == "guard":
				col = 1
			elif beat["kind"] == "feint":
				col = 2
			elif STRIKE_KINDS.has(beat["kind"]):
				col = 0
			if col >= 0 and side != "":
				shares[side][col] += 1
			if beat["kind"] in ["hit", "chip", "stun", "stunThrough"]:
				damaged[int(beat["round"])] = true
		dmg_rounds += damaged.size()
		all_rounds += int(cp["round"])
	rounds.sort()
	var total := 0
	for r in rounds:
		total += r
	print("%-28s %-6s | %-17s | %-17s | %-17s | %6.1f %4d %4.0f%% %5.0f%% %5d | %d / %d / %d" % [
		setup["label"], policy, _pct(shares["player"]), _pct(shares["ally"]), _pct(shares["enemy"]),
		float(total) / n, rounds[mini(n - 1, int(ceil(0.9 * n)) - 1)], 100.0 * wins / n,
		100.0 * (all_rounds - dmg_rounds) / maxi(1, all_rounds), timeouts,
		reasons["threat"], reasons["fallback"], reasons["chip"]])


func _open(setup: Dictionary, fight_seed: int) -> void:
	var enemies: Array = []
	var used: Array = []
	for archetype in setup["enemies"]:
		enemies.append(Combat._debug_enemy({ "template": "mugger", "level": int(setup.get("level", 1)), "archetype": archetype }, used))
	var allies: Array = []
	if setup["archie"]:
		GameState.state["contacts"]["archie"]["recruited"] = true
		var archie := Contacts.build_combat_ally("archie")
		if setup.has("level"):
			archie["level"] = int(setup["level"])
		allies.append(archie)
	var config := { "seed": fight_seed, "fog": true, "playerLevel": int(setup.get("level", 1)) }
	if setup.has("plans"):
		config["enemyPlans"] = setup["plans"]
	Combat._start_round_combat(Combat.CONTEXT_EVENT_MUGGING, null, enemies, [], "", allies, null, config)


func _side_of(cp: Dictionary, actor: int) -> String:
	if actor < 0:
		return ""
	match cp["combatants"][actor]["side"]:
		CombatRounds.SIDE_PLAYER:
			return "player"
		CombatRounds.SIDE_ALLY:
			return "ally"
		CombatRounds.SIDE_ENEMY:
			return "enemy"
	return ""


# Why each of a living ally's freshly planned Guards was picked, replaying
# _ally_action()'s first rule: an enemy action at the same index, read and
# aimed at the ally, damaging.
func _classify_allies(cp: Dictionary, reasons: Dictionary) -> void:
	var combatants: Array = cp["combatants"]
	for a in range(combatants.size()):
		if combatants[a]["side"] != CombatRounds.SIDE_ALLY or combatants[a]["koed"]:
			continue
		var plan: Array = combatants[a]["plan"]
		for index in range(plan.size()):
			var action: Dictionary = plan[index]
			if action["move"] == CombatRounds.MOVE_STRIKE:
				var seen_open := false
				for e in CombatRounds._living_opponents(cp, a):
					seen_open = seen_open or CombatRounds._ally_sees_open(cp, e, a, index, [])
				if not seen_open:
					reasons["chip"] += 1
			elif action["move"] == CombatRounds.MOVE_GUARD:
				var threatened := false
				for e in CombatRounds._living_opponents(cp, a):
					var ep: Array = combatants[e]["plan"]
					threatened = threatened or (index < ep.size() and not CombatRounds._action_lost(cp, e, index)
						and CombatRounds.is_read(cp, e, index) and int(ep[index]["target"]) == a
						and CombatRounds.move(ep[index]["move"])["effect"] in [CombatRounds.EFFECT_DAMAGE, CombatRounds.EFFECT_STUN])
				reasons["threat" if threatened else "fallback"] += 1


func _pct(counts: Array) -> String:
	var total: int = counts[0] + counts[1] + counts[2]
	if total == 0:
		return "-"
	return "%3.0f / %3.0f / %3.0f" % [100.0 * counts[0] / total, 100.0 * counts[1] / total, 100.0 * counts[2] / total]

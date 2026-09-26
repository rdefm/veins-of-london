extends RefCounted

# Body of scripts/sim_combat_balance.gd (see there for usage).

const MATCHUPS := [
	# [label, combatSkill, raid template ("" = random per guard), value_tier,
	# guards]. A "mugging" label runs a street mugging (natural 1-3 roll)
	# instead. The "matched" ladder is one raid per Combat Skill level with
	# guard count/tier rising alongside it.
	["L1 vs Scrapper t1", 1, "territorialScrapper", 1, 1],
	["L1 vs Vein Guard t1", 1, "veinGuard", 1, 1],
	["L1 vs Dealer t1", 1, "orichalchumDealer", 1, 1],
	["L1 vs street mugging", 1, "", 1, 1],
	["L2 matched: 1 guard t2", 2, "", 2, 1],
	["L3 matched: 2 guards t2", 3, "", 2, 2],
	["L4 matched: 2 guards t3", 4, "", 3, 2],
	["L5 matched: 3 guards t4", 5, "", 4, 3],
	["L3 vs 1 guard t3", 3, "", 3, 1],
	["L5 vs street mugging", 5, "", 1, 1],
]


func run(opts: Dictionary) -> void:
	Rng.set_seed(12345)
	# shp/smin/smax: what-if overrides on the Scrapper template, run only.
	var scrapper: Dictionary = GameData.ENEMY_RAID_GUARDS["territorialScrapper"]
	for pair in [["shp", "hpBase"], ["smin", "attackMin"], ["smax", "attackMax"]]:
		if opts.has(pair[0]):
			scrapper[pair[1]] = opts[pair[0]]
	if opts.has("hpc"):
		GameData.COMBAT_HP_BONUS_BY_LEVEL = opts["hpc"]
	for m in MATCHUPS:
		_run(m, opts)


func _run(m: Array, opts: Dictionary) -> void:
	var n: int = opts["n"]
	var wins := 0
	var end_pcts: Array = []
	for _i in range(n):
		GameState.reset()
		var player: Dictionary = GameState.state["player"]
		if opts.has("hp"):
			player["hpMax"] = opts["hp"]
			player["hp"] = opts["hp"]
		if opts.has("min"):
			player["attackMin"] = opts["min"]
		if opts.has("max"):
			player["attackMax"] = opts["max"]
		player["combatSkill"] = m[1]
		# A fresh player is level 1; apply the HP curve as levelling would.
		var hp_bonus: int = GameData.COMBAT_HP_BONUS_BY_LEVEL[m[1]] - GameData.COMBAT_HP_BONUS_BY_LEVEL[1]
		player["hpMax"] += hp_bonus
		player["hp"] = player["hpMax"]
		player["combatXP"] = GameData.COMBAT_XP_LEVELS[m[1]]
		var template: String = m[2]
		var guards: int = m[4]
		if m[0].contains("mugging"):
			# Natural 1-3 mugger roll.
			Combat.start_street_mugging()
		else:
			Combat.start_raid("", m[3], guards, template)
		var combat: Dictionary = GameState.state["combat"]
		var guard := 0
		while combat["outcome"] == null and guard < 200:
			Combat.player_attack()
			guard += 1
		if combat["outcome"] == "win":
			wins += 1
			end_pcts.append(100.0 * player["hp"] / player["hpMax"])
	end_pcts.sort()
	var mean := 0.0
	for p in end_pcts:
		mean += p
	mean = mean / end_pcts.size() if not end_pcts.is_empty() else 0.0
	var median: float = end_pcts[end_pcts.size() / 2] if not end_pcts.is_empty() else 0.0
	var under40 := end_pcts.filter(func(p: float) -> bool: return p < 40.0).size()
	print("%-24s win %5.1f%%  endHP%% mean %5.1f  median %5.1f  wins<40%% %5.1f%%" % [
		m[0], 100.0 * wins / n, mean, median,
		100.0 * under40 / end_pcts.size() if not end_pcts.is_empty() else 0.0])

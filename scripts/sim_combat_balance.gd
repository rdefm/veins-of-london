extends SceneTree

# Headless combat balance sim: an itemless, ally-less player that always
# Attacks, run N times per matchup through the real Combat system.
#   godot --headless -s scripts/sim_combat_balance.gd
#   godot --headless -s scripts/sim_combat_balance.gd -- hp=40 min=3 max=7 n=2000
#   ... -- hpc=0,0,8,16,26,40   (what-if combatHpBonusByLevel curve)
# Overrides replace GameState's fresh-player stats / GameData curves for the
# run only; nothing is saved. Prints win rate and mean/median end-HP% of wins.
# The sim body lives in sim_combat_balance_impl.gd, load()ed after autoloads
# are live (an -s entry script compiles before any autoload registers).

func _initialize() -> void:
	var game_data: Node = root.get_node("GameData")
	if not game_data.loaded:
		game_data.load_all()
	await process_frame
	var opts := {"n": 2000}
	for arg in OS.get_cmdline_user_args():
		var kv: PackedStringArray = arg.split("=")
		if kv.size() == 2:
			opts[kv[0]] = Array(kv[1].split(",")).map(func(v: String) -> int: return int(v)) if kv[1].contains(",") else int(kv[1])
	load("res://scripts/sim_combat_balance_impl.gd").new().run(opts)
	quit(0)

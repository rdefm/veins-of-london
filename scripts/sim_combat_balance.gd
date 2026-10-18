extends SceneTree

# Headless combat balance sim on the live engine: N seeded fights per
# matchup over a grid, each opened by Combat.start_debug_combat() on a fresh
# GameState and played through Combat.choose_move() / choose_item(), a pick
# at each pause by two player policies (naive: always Strike; reader:
# guards incoming strikes, strikes openings, feints turtles). Prints rounds
# mean/p90, win %, HP left % and actions picked per matchup x policy, one
# table per fog mode (fog=both|on|off; both also prints the fog's cost).
#   godot --headless -s scripts/sim_combat_balance.gd
#   godot --headless -s scripts/sim_combat_balance.gd -- n=200 seed=7 levels=1,3,5 fog=on
#     elevels=match|1,3 enemies=mugger,veinGuard:turtleV2 counts=1,2 allies=0,1
#     loadouts=none,blast+shield,timePearl:2+healingBurst
#     archetypes.mugger.hpBase=45 chipMultiplier=0.3   (what-if data overrides)
# An enemies entry is a Combat.debug_enemy_templates() key, optionally
# ":archetype". Same seed + grid prints the same table. Not part of
# run_tests.sh. The body lives in sim_combat_balance_impl.gd, load()ed after
# autoloads are live (an -s entry script compiles before any autoload
# registers).

func _initialize() -> void:
	var game_data: Node = root.get_node("GameData")
	if not game_data.loaded:
		game_data.load_all()
	await process_frame
	var opts := {}
	for arg in OS.get_cmdline_user_args():
		var kv: PackedStringArray = arg.split("=")
		if kv.size() == 2:
			opts[kv[0]] = kv[1]
	load("res://scripts/sim_combat_balance_impl.gd").new().run(opts)
	quit(0)

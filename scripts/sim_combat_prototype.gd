extends SceneTree

# Headless balance sim for the Open/Guarded combat prototype: N seeded fights
# per matchup over a grid, played through CombatPrototype.start() /
# resolve_round() by two player policies (naive: always Strike; reader:
# guards incoming strikes, strikes openings, feints turtles). Prints rounds
# mean/p90, win %, HP left % and actions planned per matchup x policy.
#   godot --headless -s scripts/sim_combat_prototype.gd
#   godot --headless -s scripts/sim_combat_prototype.gd -- n=200 seed=7 levels=1,3,5
#     elevels=match|1,3 archetypes=mugger,turtle counts=1,2 allies=0,1
#     loadouts=none,blast+shield,timePearl:2+healingBurst
#     archetypes.mugger.hpBase=45 chipMultiplier=0.3   (what-if data overrides)
# Same seed + grid prints the same table. Not part of run_tests.sh. The body
# lives in sim_combat_prototype_impl.gd, load()ed after autoloads are live
# (an -s entry script compiles before any autoload registers).

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
	load("res://scripts/sim_combat_prototype_impl.gd").new().run(opts)
	quit(0)

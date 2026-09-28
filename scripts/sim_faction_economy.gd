extends SceneTree

# Headless faction-economy tuning sim (spec biz-act2-faction-economy §Tuning
# tool): runs the real daily rollover from a fresh start and prints London
# prices and per-producer ore/crafting shares.
#   godot --headless -s scripts/sim_faction_economy.gd
#   godot --headless -s scripts/sim_faction_economy.gd -- days=60 seed=7 player=25 playerOre=life
# player=N credits the player N ore of playerOre a day (an end-of-Act-1
# pruning pace) to the ore share tally and London supply. Nothing is saved
# beyond the rollover's own autosave. The body lives in
# sim_faction_economy_impl.gd, load()ed after autoloads are live.

func _initialize() -> void:
	var game_data: Node = root.get_node("GameData")
	if not game_data.loaded:
		game_data.load_all()
	await process_frame
	var opts := { "days": 60, "seed": 1, "player": 25, "playerOre": "life" }
	for arg in OS.get_cmdline_user_args():
		var kv: PackedStringArray = arg.split("=")
		if kv.size() == 2:
			opts[kv[0]] = int(kv[1]) if kv[1].is_valid_int() else kv[1]
	load("res://scripts/sim_faction_economy_impl.gd").new().run(opts)
	quit(0)

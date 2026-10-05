extends SceneTree

# Headless profile of block advance, rest and the daily tick on a late-game
# state (the faction sim run forward `warm` days). Prints per-step msec.
#   godot --headless -s scripts/profile_block_end.gd -- warm=60 seed=1 reps=5

func _initialize() -> void:
	var game_data: Node = root.get_node("GameData")
	if not game_data.loaded:
		game_data.load_all()
	await process_frame
	var opts := { "warm": 60, "seed": 1, "reps": 5 }
	for arg in OS.get_cmdline_user_args():
		var kv: PackedStringArray = arg.split("=")
		if kv.size() == 2:
			opts[kv[0]] = int(kv[1])
	load("res://scripts/profile_block_end_impl.gd").new().run(opts)
	quit(0)

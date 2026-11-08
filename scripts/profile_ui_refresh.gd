extends SceneTree

# Headless profile of UI refresh cost: boots Main, visits Map, Phone and HQ,
# and prints per-listener msec for a state_changed emit plus an end-of-day
# rollover (daily_tick + flushed state_changed) on a late-game state.
#   godot --headless -s scripts/profile_ui_refresh.gd -- warm=60 seed=1 reps=5

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
	await load("res://scripts/profile_ui_refresh_impl.gd").new().run(self, opts)
	quit(0)

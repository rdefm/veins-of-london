extends SceneTree

# Headless sim of the combat AI's guarding: N seeded fights per setup (real
# Archie ally against archetype enemies, fog on), the player a fixed policy
# (strike: always Strike; guard: always Guard). Prints per-side move share
# (strike / guard / feint), rounds to outcome, damage-free round share, and
# why the ally guarded (an enemy action at its index aims at it, or the
# fallback when no enemy is Open).
#   godot --headless -s scripts/sim_ai_guard.gd
#   godot --headless -s scripts/sim_ai_guard.gd -- n=300 seed=3
#     chip=0.6 (what-if allyChipStrikeChance)  dump=4 (beat-kind histogram of setup 4)
# Not part of run_tests.sh. The body lives in sim_ai_guard_impl.gd, load()ed
# after autoloads are live (an -s entry script compiles before any autoload
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
	load("res://scripts/sim_ai_guard_impl.gd").new().run(opts)
	quit(0)

extends SceneTree

# Dev-only visual check for the stage engine, run windowed (not --headless):
#   godot -s scripts/debug_stage_screenshot.gd [-- <rig_id>]
# Plays archie_craft_chat's EventScreen and saves a frame per sampled moment
# to .scratch/stage-engine/shots/ (or shots/<rig_id>/ when a rig id is given,
# which swaps Archie's rig in memory, e.g. archie_chibi).

const OUT_DIR := "res://.scratch/stage-engine/shots/"
const SHOTS := [[0, 0.5], [0, 2.0], [3, 1.6], [3, 3.5], [6, 5.0], [11, 2.0], [11, 2.6], [11, 4.5]]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_state := root.get_node("GameState")
	var out_dir := OUT_DIR
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		root.get_node("GameData").STAGES["archie_craft_chat"]["actors"]["archie"]["rig"] = args[0]
		out_dir = OUT_DIR + args[0] + "/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	game_state.reset()
	root.get_node("EventBus")
	Events.start_event("archie_craft_chat")
	var screen: Control = load("res://scenes/screens/event.gd").new()
	UI.anchor_full_rect(screen)
	root.add_child(screen)
	for shot in SHOTS:
		while game_state.state["event"]["cardIndex"] < shot[0]:
			Events.advance()
		var start := Time.get_ticks_msec()
		while (Time.get_ticks_msec() - start) / 1000.0 < shot[1]:
			await process_frame
		var img := root.get_texture().get_image()
		var path := out_dir + "card%d_t%.1f.png" % [shot[0] + 1, shot[1]]
		img.save_png(path)
		print("Saved %s" % path)
	quit()

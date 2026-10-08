extends SceneTree

# Dev-only visual check for the stage engine, run windowed (not --headless):
#   godot -s scripts/debug_stage_screenshot.gd [-- <rig_id> | slow | <event_id>]
# Plays archie_craft_chat's EventScreen and saves a frame per sampled moment
# to .scratch/stage-engine/shots/ (or shots/<arg>/ when given). A rig id swaps
# Archie's rig in memory, e.g. archie_chibi; "slow" adds a floor-thrown vial
# and a slow field around Archie on card 5; another staged event id (e.g.
# intro2) plays that event with INTRO_SHOTS (its six staged cards).

const OUT_DIR := "res://.scratch/stage-engine/shots/"
const SHOTS := [[0, 0.5], [0, 2.0], [3, 1.6], [3, 3.5], [6, 5.0], [11, 2.0], [11, 2.6], [11, 4.5]]
const INTRO_SHOTS := [[0, 1.0], [0, 4.5], [1, 1.2], [1, 3.4], [1, 6.0], [2, 1.0], [2, 3.4],
	[3, 0.5], [3, 2.2], [4, 0.6], [4, 1.4], [4, 2.8], [4, 5.0], [5, 0.6], [5, 2.4]]
const SLOW_SHOTS := [[4, 0.5], [4, 0.8], [4, 1.3], [4, 3.0], [5, 1.0]]
const SLOW_STEPS := [
	{"t": 0.0, "throw": {"prop": "falafel_crumb", "from": "archie.hand_l", "at": 205, "dur": 0.6, "arc": 30}},
	{"t": 0.6, "slow": {"x": 205, "radius": 45, "scale": 0.25, "grow": 0.6}},
]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_state := root.get_node("GameState")
	var game_data := root.get_node("GameData")
	var out_dir := OUT_DIR
	var shots := SHOTS
	var event_id := "archie_craft_chat"
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		var stage: Dictionary = game_data.STAGES["archie_craft_chat"]
		if game_data.STAGES.has(args[0]):
			event_id = args[0]
			shots = INTRO_SHOTS
		elif args[0] == "slow":
			stage["cards"][4]["steps"].append_array(SLOW_STEPS)
			shots = SLOW_SHOTS
		else:
			stage["actors"]["archie"]["rig"] = args[0]
		out_dir = OUT_DIR + args[0] + "/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	game_state.reset()
	root.get_node("EventBus")
	Events.start_event(event_id)
	var screen: Control = load("res://scenes/screens/event.gd").new()
	UI.anchor_full_rect(screen)
	root.add_child(screen)
	for shot in shots:
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

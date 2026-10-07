extends "res://tests/test_base.gd"

# Stage engine: direction data integrity, fold resolution, viewport fit, and a
# headless StagePlayer run through every card of archie_craft_chat.

const EVENT_ID := "archie_craft_chat"


func run() -> void:
	run_case("every_stage_references_resolve", func():
		assert_true(GameData.STAGES.has(EVENT_ID), "archie_craft_chat has a stage")
		for event_id in GameData.STAGES:
			var stage: Dictionary = GameData.STAGES[event_id]
			assert_true(GameData.EVENTS.has(event_id), "%s stage matches an event" % event_id)
			assert_true(stage["cards"].size() <= GameData.EVENTS[event_id]["cards"].size(), "%s: no more direction entries than cards" % event_id)
			assert_true(GameData.STAGE_SETS.has(stage["set"]), "%s: set exists" % event_id)
			var set_def: Dictionary = GameData.STAGE_SETS[stage["set"]]
			_assert_set_files(set_def)
			for actor_id in stage["actors"]:
				var rig_id: String = stage["actors"][actor_id]["rig"]
				assert_true(GameData.STAGE_RIGS.has(rig_id), "%s: rig %s exists" % [event_id, rig_id])
				_assert_rig_files(GameData.STAGE_RIGS[rig_id])
			for card in stage["cards"]:
				for step in card["steps"]:
					_assert_step_valid(event_id, stage, set_def, step)
	)

	run_case("fold_keeps_the_dropped_falafel_and_the_camera_move", func():
		var stage: Dictionary = GameData.STAGES[EVENT_ID]
		var start := StageDirection.resolve_start(stage, 0)
		assert_eq(start["camera_x"], float(stage["camera"]["x"]), "camera starts at the stage default")
		assert_eq(start["actors"]["archie"]["arm_l"], "hold", "rig defaults before card 1")
		assert_eq(StageDirection.resolve_start(stage, 3)["props"].size(), 0, "nothing on the floor before card 4")
		var card5 := StageDirection.resolve_start(stage, 4)
		assert_eq(card5["props"].size(), 1, "the falafel stays on the floor after card 4")
		assert_eq(card5["props"][0]["prop"], "falafel_crumb", "it is the falafel crumb")
		assert_eq(card5["actors"]["archie"]["mouth"], "agape", "mouth still hangs open entering card 5")
		var after_tilt := StageDirection.resolve_end(stage, 6)
		assert_eq(after_tilt["actors"]["archie"]["tilt"], -7, "card 7 ends with the head tilted")
		var last := StageDirection.resolve_end(stage, 11)
		assert_eq(last["camera_x"], 150.0, "card 12 pans to the bin")
		assert_eq(last["actors"]["archie"]["arm_l"], "rest", "throw action ends at rest")
		assert_eq(last["props"].size(), 1, "the falafel is still there at the end")
	)

	run_case("talk_seconds_counts_quoted_speech_and_clamps", func():
		var behaviour := {"talk_per_char": 0.1, "talk_min": 1.0, "talk_max": 3.0}
		assert_almost_eq(StageDirection.talk_seconds("\"Hello there.\" He tilts his head.", behaviour), 1.2, 0.001, "narration is silent")
		assert_almost_eq(StageDirection.talk_seconds("\"Hi\"", behaviour), 1.0, 0.001, "short line clamps up")
		assert_almost_eq(StageDirection.talk_seconds("x".repeat(100), behaviour), 3.0, 0.001, "unquoted long text clamps down")
	)

	run_case("viewport_fit_is_integer_scaled_and_covers_the_frame", func():
		var fit := StageDirection.viewport_fit(Vector2(1170, 1572), 180)
		assert_eq(fit["scale"], 6, "1170px wide -> 6x")
		assert_eq(fit["size"], Vector2i(195, 262), "viewport covers the frame")
		var small := StageDirection.viewport_fit(Vector2(100, 80), 180)
		assert_eq(small["scale"], 1, "never below 1x")
		assert_eq(small["size"], Vector2i(100, 80), "tiny frame maps 1:1")
	)

	run_case("events_uses_vn_mode_for_a_staged_event", func():
		GameState.reset()
		Events.start_event(EVENT_ID)
		assert_true(Events.has_stage(), "stage found for the live event")
		assert_true(Events.is_vn_mode(), "staged event renders in VN layout")
	)

	run_case("a_short_stage_covers_only_its_first_cards", func():
		GameState.reset()
		var original_stages: Dictionary = GameData.STAGES
		GameData.STAGES = GameData.STAGES.duplicate()
		var short: Dictionary = GameData.STAGES[EVENT_ID].duplicate()
		short["cards"] = short["cards"].slice(0, 2)
		GameData.STAGES[EVENT_ID] = short
		Events.start_event(EVENT_ID)
		assert_true(Events.is_staged_card(), "card 1 is staged")
		GameState.state["event"]["cardIndex"] = 2
		assert_true(not Events.is_staged_card(), "card 3 is past the stage")
		assert_true(Events.is_vn_mode(), "unstaged cards keep the VN layout")
		GameData.STAGES = original_stages
	)

	run_case("player_rests_and_wakes_cleanly", func():
		GameState.reset()
		GameState.state["meta"]["reducedMotion"] = false
		var player := _player()
		player.show_card(3)
		for _tick in range(5):
			player.advance(0.1)
		player.rest()
		assert_true(not player.visible, "a resting stage is hidden")
		assert_eq(player._steps.size() + player._fx.size(), 0, "nothing left queued or in flight")
		assert_eq(_resting_props(player), 0, "no props left behind")
		player.show_card(4)
		assert_true(player.visible, "the next staged card wakes it")
		assert_eq(_resting_props(player), 1, "falafel rebuilt from the fold")
		player.free()
	)

	run_case("player_steps_through_every_card", func():
		GameState.reset()
		GameState.state["meta"]["reducedMotion"] = false
		var player := _player()
		var stage: Dictionary = GameData.STAGES[EVENT_ID]
		for i in range(stage["cards"].size()):
			player.show_card(i)
			for _tick in range(80):
				player.advance(0.1)
			if i == 3:
				assert_eq(_resting_props(player), 1, "falafel lands and stays after card 4 plays")
				assert_eq(player._actors["archie"].attrs["mouth"], "agape", "mouth hangs open")
		assert_eq(player._fx.size(), 0, "every effect finished")
		assert_almost_eq(player._camera_x, 150.0, 0.01, "camera reached the bin")
		player.show_card(1)
		assert_almost_eq(player._camera_x, float(stage["camera"]["x"]), 0.01, "rewinding snaps the camera back")
		player.free()
	)

	run_case("reduced_motion_snaps_each_card_to_its_end_state", func():
		GameState.reset()
		GameState.state["meta"]["reducedMotion"] = true
		var player := _player()
		player.show_card(3)
		assert_eq(_resting_props(player), 1, "falafel already on the floor")
		assert_eq(player._steps.size(), 0, "no timed steps queued")
		assert_eq(player._actors["archie"].attrs["eyes"], "wide", "card 4 end look")
		player.free()
		GameState.state["meta"]["reducedMotion"] = false
	)


func _player() -> StagePlayer:
	var player := StagePlayer.new()
	player.size = Vector2(390, 520)
	player.setup(EVENT_ID)
	return player


func _resting_props(player: StagePlayer) -> int:
	var count := 0
	for child in player._props_root.get_children():
		if not child.is_queued_for_deletion():
			count += 1
	return count - player._fx.size()


func _assert_set_files(set_def: Dictionary) -> void:
	var dir: String = set_def["dir"]
	var files: Array = []
	for layer in set_def["layers"]:
		files.append(layer["file"])
	for walker in set_def["walkers"]["list"]:
		files.append_array(walker["frames"])
	for entry in set_def["ambient"]:
		files.append_array(entry["frames"])
	files.append(set_def["lights"]["file"])
	for obj in set_def["objects"].values():
		files.append(obj["back"])
		files.append(obj["front"])
	files.append_array(set_def["props"].values())
	for file in files:
		assert_true(ResourceLoader.exists(dir + String(file)), "set file %s exists" % file)


func _assert_rig_files(rig: Dictionary) -> void:
	for part_id in rig["order"]:
		for frame_id in rig["parts"][part_id]["frames"]:
			var path: String = String(rig["dir"]) + String(rig["parts"][part_id]["frames"][frame_id])
			assert_true(ResourceLoader.exists(path), "rig file %s exists" % path)
	for action_id in rig["actions"]:
		for step in rig["actions"][action_id]:
			for attr in step["set"]:
				assert_true(rig["parts"][attr]["frames"].has(step["set"][attr]), "action %s frame %s exists" % [action_id, step["set"][attr]])


func _assert_step_valid(event_id: String, stage: Dictionary, set_def: Dictionary, step: Dictionary) -> void:
	assert_true(step.has("t"), "%s: step has a time" % event_id)
	if step.has("set"):
		for path in step["set"]:
			var target := StageDirection.split_target(path)
			var rig := StageDirection.rig_for(stage, target[0])
			var value: Variant = step["set"][path]
			if target[1] == "tilt":
				assert_true(typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT, "%s: tilt is a number" % event_id)
			elif target[1] == "mouth":
				assert_true(rig["parts"]["mouth"]["frames"].has(value) or rig["mouth_states"].has(value), "%s: mouth %s exists" % [event_id, value])
			else:
				assert_true(rig["parts"][target[1]]["frames"].has(value), "%s: %s frame %s exists" % [event_id, target[1], value])
	elif step.has("play"):
		var target := StageDirection.split_target(step["play"])
		assert_true(StageDirection.rig_for(stage, target[0])["actions"].has(target[1]), "%s: action %s exists" % [event_id, step["play"]])
	elif step.has("talk"):
		assert_true(stage["actors"].has(step["talk"]), "%s: talking actor exists" % event_id)
	elif step.has("drop"):
		assert_true(set_def["props"].has(step["drop"]["prop"]), "%s: drop prop exists" % event_id)
	elif step.has("throw"):
		assert_true(set_def["props"].has(step["throw"]["prop"]), "%s: throw prop exists" % event_id)
		assert_true(set_def["objects"].has(step["throw"]["to"]), "%s: throw target exists" % event_id)
	else:
		assert_true(step.has("camera"), "%s: known step kind" % event_id)

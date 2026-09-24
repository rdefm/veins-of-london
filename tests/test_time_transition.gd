extends "res://tests/test_base.gd"

const UiSim := preload("res://tests/support/ui_sim.gd")
const Overlay := preload("res://scenes/components/time_transition.gd")

func _overlay() -> Control:
	GameState.reset()
	GameState.state["currentScreen"] = "hq"
	var overlay := Overlay.new()
	overlay._ready()
	overlay.set_anchors_preset(Control.PRESET_TOP_LEFT)
	overlay.size = Vector2(390, 844)
	return overlay


func run() -> void:
	run_case("paid_train_captures_once_and_notifies_before_overlay_without_replaying_effects", func():
		var overlay := _overlay()
		var result := Combat.train()
		assert_true(result["ok"])
		assert_eq(overlay.pending.size(), 1)
		assert_eq(overlay.pending[0]["source"], {"day": 1, "phase": 0})
		assert_eq(overlay.pending[0]["destination"], {"day": 1, "phase": 1})
		assert_true(not overlay.visible)
		assert_true(GameState.state["notifications"].back()["text"].contains("tomorrow"))
		var resolved := SaveManager.export_string()
		UiSim.advance(overlay, 0.8)
		assert_true(overlay.active)
		assert_eq(overlay.destination.text, "Day 1 — Afternoon")
		UiSim.advance(overlay, 1.6)
		assert_true(overlay.active, "non-skippable duration has not elapsed")
		UiSim.advance(overlay, 0.2)
		assert_true(not overlay.active)
		assert_eq(SaveManager.export_string(), resolved, "playback owns no gameplay effects")
		assert_eq(overlay.pending.size(), 0)
		overlay.free()
	)
	run_case("event_combat_result_and_bag_boundaries_hold_the_queue", func():
		var overlay := _overlay()
		TimeSystem.advance_time_block()
		GameState.state["event"] = {"id": "test"}
		UiSim.advance(overlay, 3)
		assert_true(not overlay.active)
		GameState.state["event"] = null
		GameState.state["combat"]["active"] = true
		UiSim.advance(overlay, 3)
		assert_true(not overlay.active)
		GameState.state["combat"]["active"] = false
		GameState.state["currentScreen"] = "combat"
		UiSim.advance(overlay, 3)
		assert_true(not overlay.active, "combat result playback still owns screen")
		GameState.state["currentScreen"] = "hq"
		Modal.open("james_job_complete", {"earned": 10})
		UiSim.advance(overlay, 3)
		assert_true(not overlay.active)
		Modal.close()
		GameState.state["bagDrawerOpen"] = true
		UiSim.advance(overlay, 3)
		assert_true(not overlay.active)
		GameState.state["bagDrawerOpen"] = false
		UiSim.advance(overlay, 0.8)
		assert_true(overlay.active)
		overlay.free()
	)
	run_case("rollover_and_rest_each_capture_one_transition_and_one_daily_tick", func():
		for phase in range(3):
			for rest in [false, true]:
				var overlay := _overlay()
				GameState.state["world"]["timeBlock"] = phase
				var ticks: Array = []
				var record := func(day: int): ticks.append(day)
				EventBus.day_ticked.connect(record)
				if rest:
					TimeSystem.do_rest()
				else:
					TimeSystem.advance_time_block()
				assert_eq(overlay.pending.size(), 1)
				assert_eq(overlay.pending[0]["source"]["phase"], phase)
				assert_eq(ticks.size(), 1 if rest or phase == 2 else 0)
				var resolved_account = GameState.deep_copy(GameState.state["morningAccounts"].get("latest"))
				var resolved_cash: int = GameState.state["player"]["cash"]
				UiSim.advance(overlay, 3)
				assert_true(not overlay.active)
				assert_eq(GameState.state["morningAccounts"].get("latest"), resolved_account, "playback never reruns or edits the account")
				assert_eq(GameState.state["player"]["cash"], resolved_cash, "playback never reruns daily effects")
				if rest or phase == 2:
					assert_eq(GameState.state["phoneNav"]["app"], "bizbrief", "overnight completion opens the brief")
				assert_eq(ticks.size(), 1 if rest or phase == 2 else 0)
				EventBus.day_ticked.disconnect(record)
				overlay.free()
	)
	run_case("free_and_blocked_actions_do_not_queue", func():
		var overlay := _overlay()
		Travel.ensure_district("shoreditch", 0)
		assert_eq(overlay.pending.size(), 0)
		GameState.state["world"]["timeBlocksDone"] = [0, 1, 2]
		assert_true(not Combat.train()["ok"])
		UiSim.advance(overlay, 3)
		assert_eq(overlay.pending.size(), 0)
		assert_true(not overlay.active)
		overlay.free()
	)
	run_case("reduced_motion_holds_destination_frame_and_preference_survives_load", func():
		var overlay := _overlay()
		preload("res://systems/preferences.gd").set_reduced_motion(true)
		TimeSystem.advance_time_block()
		UiSim.advance(overlay, 0.8)
		var frame: Dictionary = overlay.frame.duplicate(true)
		var position: Vector2 = overlay.art_position
		UiSim.advance(overlay, 1.0)
		assert_eq(overlay.frame, frame)
		assert_eq(overlay.art_position, position)
		assert_eq(overlay.frame["progress"], 1.0)
		assert_true(overlay.active)
		var saved := SaveManager.export_string()
		assert_true(SaveManager.import_string(saved)["ok"])
		overlay._process(0.05)
		assert_true(not overlay.active)
		assert_eq(overlay.pending.size(), 0)
		assert_true(GameState.state["meta"]["reducedMotion"])
		assert_eq(SaveManager.export_string(), saved)
		overlay.free()
	)
	run_case("park_art_is_square_with_transparent_sky_and_coloured_landmarks", func():
		var overlay := _overlay()
		var config: Dictionary = GameData.DAILY_CYCLE
		assert_eq(config["diameter"], 220)
		assert_eq(overlay.foreground.get_width(), overlay.foreground.get_height())
		var pixels := Image.new()
		assert_eq(pixels.load_png_from_buffer(FileAccess.get_file_as_bytes(config["foreground"])), OK)
		assert_eq(pixels.get_pixel(0, 0).a, 0.0)
		assert_true(pixels.get_pixel(627, 627).a < 0.01, "central sky remains transparent for animation")
		for point in [Vector2i(550, 660), Vector2i(850, 650), Vector2i(1150, 650)]:
			var colour := pixels.get_pixelv(point)
			assert_true(colour.a > 0.9, "all three landmark regions contain opaque art")
			assert_true(colour.r != colour.g or colour.g != colour.b, "landmarks carry colour")
		overlay.free()
	)
	run_case("circle_and_label_rise_hold_and_exit_together", func():
		var overlay := _overlay()
		TimeSystem.advance_time_block()
		UiSim.advance(overlay, 0.75)
		var start_y: float = overlay.art_position.y
		assert_true(start_y > overlay.size.y)
		assert_eq(overlay.destination.position.y, start_y + 232.0)
		UiSim.advance(overlay, 0.32)
		var hold_y: float = overlay.art_position.y
		assert_true(hold_y > 0.0 and hold_y < overlay.size.y - 220.0)
		assert_eq(overlay.art_position.x, 85.0)
		assert_eq(overlay.destination.size.x, 220.0)
		assert_eq(overlay.destination.position.y, hold_y + 232.0)
		UiSim.advance(overlay, 0.9)
		assert_eq(overlay.art_position.y, hold_y)
		UiSim.advance(overlay, 0.55)
		assert_true(overlay.art_position.y > overlay.size.y)
		overlay.free()
	)
	run_case("all_phase_clips_move_the_sun_and_moon_and_rest_traverses_order", func():
		for phase in range(3):
			var overlay := _overlay()
			GameState.state["world"]["timeBlock"] = phase
			TimeSystem.advance_time_block()
			UiSim.advance(overlay, 0.8)
			var start: Dictionary = overlay._sky_frame(0.0)
			var finish: Dictionary = overlay._sky_frame(1.0)
			assert_eq(start["clip"], GameData.DAILY_CYCLE["clips"][phase]["id"])
			assert_true(start["sun"] != finish["sun"])
			if phase > 0:
				assert_true(start["moon"] != finish["moon"])
			assert_true(start["top"] != finish["top"])
			overlay.free()
			var rest_overlay := _overlay()
			GameState.state["world"]["timeBlock"] = phase
			TimeSystem.do_rest()
			UiSim.advance(rest_overlay, 0.8)
			var clips: Array = GameData.DAILY_CYCLE["clips"]
			for index in range(phase, 3):
				var sample := (float(index - phase) + 0.5) / float(3 - phase)
				assert_eq(rest_overlay._sky_frame(sample)["clip"], clips[index]["id"])
			rest_overlay.free()
	)
	await run_case("live_overlay_blocks_press_and_held_release_then_returns_input", func():
		GameState.reset()
		GameState.state["currentScreen"] = "hq"
		var tree: SceneTree = Engine.get_main_loop()
		var host := Control.new()
		host.size = Vector2(390, 844)
		var button := Button.new()
		button.size = Vector2(390, 844)
		var presses: Array = []
		button.pressed.connect(func(): presses.append(true))
		host.add_child(button)
		var overlay := Overlay.new()
		host.add_child(overlay)
		tree.root.add_child(host)
		await tree.process_frame
		overlay.set_process(false)
		TimeSystem.advance_time_block()
		UiSim.advance(overlay, 0.8)
		var press := InputEventMouseButton.new()
		press.button_index = MOUSE_BUTTON_LEFT
		press.position = Vector2(20, 20)
		press.pressed = true
		tree.root.push_input(press, true)
		assert_true(overlay.active)
		assert_eq(presses.size(), 0)
		# A paused SceneTree cannot strand the always-processing overlay.
		tree.paused = true
		assert_true(overlay.can_process())
		UiSim.advance(overlay, 1.8)
		tree.paused = false
		press.pressed = false
		tree.root.push_input(press, true)
		assert_eq(presses.size(), 0)
		var motion := InputEventMouseMotion.new()
		motion.position = press.position
		tree.root.push_input(motion, true)
		press.pressed = true
		tree.root.push_input(press, true)
		press.pressed = false
		tree.root.push_input(press, true)
		assert_eq(presses.size(), 1)
		host.free()
	)

extends "res://tests/test_base.gd"

const UiSim := preload("res://tests/support/ui_sim.gd")
const Fixtures := preload("res://tests/support/fixtures.gd")
const AlarmPresentation := preload("res://scenes/components/alarm_presentation.gd")
const Overlay := preload("res://scenes/components/time_transition.gd")
const EventPlay := preload("res://tests/support/event_play.gd")

# Counters live in one-element Arrays: a captured int is a by-value snapshot
# inside a GDScript lambda.

func _count_replacements(fn: Callable) -> int:
	var count := [0]
	var on_replaced := func(): count[0] += 1
	EventBus.state_replaced.connect(on_replaced)
	fn.call()
	EventBus.state_replaced.disconnect(on_replaced)
	return count[0]


func _alarm_pending() -> void:
	GameState.state["player"]["veins"] = [Fixtures.alarmed_vein("v1", "camden", "time")]
	GameState.state["world"]["pendingDefendRaids"] = [{ "attackerId": "firm", "veinId": "v1", "siteId": "site_v1", "success": true, "notificationId": "n1" }]
	EventBus.state_changed.emit()


func run() -> void:
	run_case("reset_emits_state_replaced_once", func():
		assert_eq(_count_replacements(func(): GameState.reset()), 1)
	)

	run_case("save_import_emits_state_replaced_once", func():
		GameState.reset()
		var text := SaveManager.export_string()
		var result := {}
		assert_eq(_count_replacements(func(): result.merge(SaveManager.import_string(text))), 1)
		assert_true(result["ok"])
	)

	run_case("block_rewind_emits_state_replaced_once", func():
		GameState.reset()
		Crafting.inventory_add("rewind", 1, 1)
		TimeSystem.advance_time_block()
		var result := {}
		assert_eq(_count_replacements(func(): result.merge(Rewind.rewind_to_block_start())), 1)
		assert_true(result["ok"])
	)

	run_case("event_rewind_emits_state_replaced_once", func():
		GameState.reset()
		GameState.state["player"]["inventory"]["rewind"] = { "1": 2 }
		EventPlay.play_event("col_a1_intro")
		Events.advance()
		var result := {}
		assert_eq(_count_replacements(func(): result.merge(Events.rewind())), 1)
		assert_true(result["ok"])
	)

	run_case("alarm_presentation_processes_only_while_an_open_is_pending", func():
		GameState.reset()
		GameState.state["currentScreen"] = "hq"
		var node := AlarmPresentation.new()
		node._ready()
		node.haptics_hook = func(): pass
		assert_true(not node.is_processing(), "idle: no per-frame work")
		_alarm_pending()
		assert_true(node.pending_open)
		assert_true(node.is_processing(), "pending: counting the hold")
		UiSim.advance(node, 3)
		assert_eq(GameState.state["currentScreen"], "phone", "auto-opened after the hold")
		assert_true(not node.is_processing(), "opened: idle again")
		node.free()
	)

	run_case("a_state_swap_cancels_a_pending_alarm_open", func():
		GameState.reset()
		GameState.state["currentScreen"] = "hq"
		var node := AlarmPresentation.new()
		node._ready()
		node.haptics_hook = func(): pass
		_alarm_pending()
		assert_true(node.pending_open)
		GameState.reset()
		assert_true(not node.pending_open, "the new session has nothing pending")
		assert_true(not node.is_processing())
		assert_true(is_same(node.session, GameState.state))
		node.free()
	)

	run_case("time_transition_processes_only_while_queued_or_active", func():
		GameState.reset()
		GameState.state["currentScreen"] = "hq"
		var overlay := Overlay.new()
		overlay._ready()
		overlay.size = Vector2(390, 844)
		assert_true(not overlay.is_processing(), "idle: no per-frame work")
		TimeSystem.advance_time_block()
		assert_true(overlay.is_processing(), "queued")
		UiSim.advance(overlay, 0.8)
		assert_true(overlay.active)
		assert_true(overlay.is_processing(), "playing")
		UiSim.advance(overlay, 1.8)
		assert_true(not overlay.active)
		assert_true(not overlay.is_processing(), "finished: idle again")
		overlay.free()
	)

	run_case("a_state_swap_clears_a_live_time_transition", func():
		GameState.reset()
		GameState.state["currentScreen"] = "hq"
		var overlay := Overlay.new()
		overlay._ready()
		overlay.size = Vector2(390, 844)
		TimeSystem.advance_time_block()
		UiSim.advance(overlay, 0.8)
		assert_true(overlay.active)
		TimeSystem.advance_time_block()
		assert_eq(overlay.pending.size(), 1)
		GameState.reset()
		assert_true(not overlay.active)
		assert_true(not overlay.visible)
		assert_eq(overlay.pending.size(), 0)
		assert_true(not overlay.is_processing())
		overlay.free()
	)

	await run_case("charge_halo_stops_processing_while_its_map_is_hidden", func():
		var tree: SceneTree = Engine.get_main_loop()
		var host := Node2D.new()
		var halo := MapHalos.ChargeHalo.new()
		host.add_child(halo)
		tree.root.add_child(host)
		await tree.process_frame
		assert_true(halo.is_processing(), "pulses while shown")
		host.visible = false
		assert_true(not halo.is_processing(), "hidden: no per-frame redraw")
		host.visible = true
		assert_true(halo.is_processing(), "resumes when shown")
		host.free()
	)

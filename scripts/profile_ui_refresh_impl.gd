extends RefCounted

# Body of scripts/profile_ui_refresh.gd (see there for usage).

const SCREENS := ["map", "phone", "hq"]


func run(tree: SceneTree, opts: Dictionary) -> void:
	var root: Window = tree.root
	GameState.reset()
	Rng.set_seed(opts["seed"])
	Factions.seed_day_one_veins()
	for i in int(opts["warm"]):
		GameState.state["world"]["day"] += 1
		TimeSystem.daily_tick()
	GameState.state["world"]["timeBlock"] = 0
	GameState.state["world"]["timeBlocksDone"] = []
	GameState.state["currentScreen"] = "map"
	var main: Node = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await tree.process_frame
	var reps: int = opts["reps"]
	print("== warm %d days, reps %d ==" % [opts["warm"], reps])
	for screen in SCREENS:
		EventBus.screen_changed.emit(screen)
		GameState.state["currentScreen"] = screen
		await tree.process_frame
		await tree.process_frame
		var totals := {}
		var total_all := 0.0
		for r in reps:
			for conn in EventBus.state_changed.get_connections():
				var c: Callable = conn["callable"]
				var label := _label(c)
				var t0 := Time.get_ticks_usec()
				c.call()
				var ms := (Time.get_ticks_usec() - t0) / 1000.0
				totals[label] = float(totals.get(label, 0.0)) + ms
				total_all += ms
		print("-- %s: %d listeners, %.2f ms per emit --" % [screen, EventBus.state_changed.get_connections().size(), total_all / reps])
		var keys: Array = totals.keys()
		keys.sort_custom(func(a, b): return totals[a] > totals[b])
		for k in keys.slice(0, 8):
			print("  %-46s %8.2f ms avg" % [k, totals[k] / reps])
		var roll := 0.0
		for r in reps:
			GameState.state["world"]["day"] += 1
			var t0 := Time.get_ticks_usec()
			TimeSystem.daily_tick()
			EventBus.mark_changed()
			EventBus.flush_now()
			roll += (Time.get_ticks_usec() - t0) / 1000.0
		print("  %-46s %8.2f ms avg" % ["rollover (daily_tick+flush)", roll / reps])
	main.queue_free()


func _label(c: Callable) -> String:
	var obj: Object = c.get_object()
	var cls := "?"
	if obj != null:
		var s: Script = obj.get_script()
		cls = s.resource_path.get_file() if s != null else obj.get_class()
	return "%s::%s" % [cls, c.get_method()]

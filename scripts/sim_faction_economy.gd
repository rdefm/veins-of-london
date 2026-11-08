extends SceneTree

# Headless faction-economy tuning sim (spec biz-act2-faction-economy §Tuning
# tool): runs the real daily rollover from a fresh start and prints London
# prices, per-producer ore/crafting shares and (spec biz-act2-rivalry-diplomacy
# §Testing Decisions) per-day relation/stance/war/weariness/truce timelines.
#   godot --headless -s scripts/sim_faction_economy.gd
#   godot --headless -s scripts/sim_faction_economy.gd -- days=60 seed=7 player=25 playerOre=life
# every=N prints every Nth timeline day (0 = events only); rivalry=0 runs
# with constants.json factionRivalry off (the sim turns it on by default).
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
	var t0: int = Time.get_ticks_msec()
	load("res://scripts/sim_faction_economy_impl.gd").new().run(opts)
	var game_state: Node = root.get_node("GameState")
	var elapsed: int = Time.get_ticks_msec() - t0
	# Clock-derived ids ("v9794716878312") are masked so the hash is reproducible.
	var re := RegEx.create_from_string("\"v?\\d{6,}\"")
	var subset := {}
	for key in ["factions", "market", "factionEscalation", "shares"]:
		subset[key] = game_state.state.get(key, {})
	var json: String = re.sub(JSON.stringify(subset, "\t", true), "\"#\"", true)
	if opts.has("dump"):
		var f := FileAccess.open(str(opts["dump"]), FileAccess.WRITE)
		f.store_string(json)
	print("STATE_HASH %d  elapsed_ms %d" % [json.hash(), elapsed])
	quit(0)

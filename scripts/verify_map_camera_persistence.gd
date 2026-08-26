extends SceneTree

# Live-tree regression check for 86-map-camera-persistence-regression:
#   godot --headless -s scripts/verify_map_camera_persistence.gd
#
# tests/test_map_canvas.gd deliberately never gives MapCanvas a real
# ScrollContainer parent (see its own "initial view" section comment) because
# the shared tests/test_runner.gd harness runs every test file's run()
# synchronously inside SceneTree._initialize(), with no frame loop ever
# pumped -- so a real Container's deferred queue_sort() would never fire and
# any assertion depending on it would be meaningless. The bug this ticket
# fixes is exactly that deferred sort pass racing a same-frame scroll write
# (see MapCanvas._apply_initial_view()'s own comment), so it can only be
# proven with a real ScrollContainer inside a real, frame-pumped SceneTree --
# this script is that, kept outside tests/ so test_runner.gd's discovery
# never picks it up and its own synchronous run() contract is never violated.
#
# Every project autoload/class below is loaded dynamically (load(), not a
# static-typed top-level reference) -- same reason check_runner.gd's own
# comment gives: this script's own top-level compile happens before the
# engine finishes registering autoloads as singletons, so a static
# `MapCanvas`/`GameState` reference right here would fail to resolve even
# though the exact same reference works fine deep inside a script that's
# itself only load()ed at runtime (as every other project .gd file is).
#
# Exits 0 (PASS) if a persisted camera position survives a fresh MapCanvas
# _ready() once real layout has had a chance to settle; non-zero otherwise.

func _initialize() -> void:
	# Adding ANY child to `root` is what actually flushes the engine's
	# pending "ready" notification queue for every autoload -- GameState's
	# own _ready() (autoload/GameState.gd) calls reset() the first time that
	# happens, which would otherwise silently clobber this script's own
	# fixture setup below the moment the real ScrollContainer is added to the
	# tree later. Forcing that flush right now, before touching GameState at
	# all, means it's already spent by the time this script sets anything up.
	root.add_child(Node.new())
	await process_frame

	var game_data: Node = root.get_node_or_null("GameData")
	if game_data != null and not game_data.loaded:
		game_data.load_all()
		game_data.validate()

	var game_state: Node = root.get_node("GameState")
	game_state.reset()
	game_state.state["world"]["sites"] = [{
		"id": "s1", "district": "hampstead", "tier": "fair", "oreType": "time",
		"bonuses": [], "discoveredDay": 1, "claimed": true, "factionVein": null,
		"hasNaturalVein": false,
	}]
	game_state.state["player"]["veins"] = [{
		"id": "v1", "siteId": "s1", "oreType": "time", "growth": 20, "security": "none",
		"alarmUpgrades": [], "location": "Test Alley", "claimedOnDay": 1,
		"district": "hampstead", "hospitability": { "tier": "fair", "bonuses": [] },
	}]

	# Simulate a previous visit having left the camera zoomed in and panned
	# well away from (0,0) -- the exact "reopen restores where you left it"
	# case tickets 53/67 specified and this ticket reports as broken.
	var map_view: GDScript = load("res://systems/map_view.gd")
	map_view.mark_opened()
	var persisted_zoom := 1.6
	var persisted_scroll := Vector2(400, 500)
	map_view.save_view(persisted_zoom, persisted_scroll)

	var scroll := ScrollContainer.new()
	scroll.size = Vector2(390, 700)
	root.add_child(scroll)

	var map_canvas_script: GDScript = load("res://scenes/components/map_canvas.gd")
	var canvas: Control = map_canvas_script.new()
	scroll.add_child(canvas)  # triggers a real _ready() synchronously, same live-tree shape map.gd itself uses

	var immediate := Vector2(scroll.scroll_horizontal, scroll.scroll_vertical)

	# The regression this ticket fixes only shows up once the ScrollContainer
	# has had a chance to recompute its scroll range off the resize _ready()
	# just applied -- see MapCanvas._apply_initial_view()'s own comment.
	await process_frame

	var settled := Vector2(scroll.scroll_horizontal, scroll.scroll_vertical)

	var ok := is_equal_approx(canvas.zoom_level, persisted_zoom) and settled.is_equal_approx(persisted_scroll)
	print("zoom after _ready(): %s (want %s)" % [canvas.zoom_level, persisted_zoom])
	print("scroll immediately after _ready(): %s" % [immediate])
	print("scroll after one process_frame: %s (want %s)" % [settled, persisted_scroll])
	print("RESULT: %s" % ("PASS" if ok else "FAIL"))
	quit(0 if ok else 1)

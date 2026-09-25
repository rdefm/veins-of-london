extends SceneTree

# Dev-only Map dark-mode screenshot harness, run windowed (not --headless):
#   godot -s .scratch/map-dark-mode/capture_map.gd
# Seeds a busy synthetic Network, then saves each filter mode in light and
# dark (overview + one close-up + the open drawer) to OUT.

const OUT := "res://.scratch/map-dark-mode/screenshots/"


func _initialize() -> void:
	call_deferred("_run")


func _seed() -> void:
	var gs := root.get_node("GameState")
	var fx = load("res://tests/support/fixtures.gd")
	var factions_node = root.get_node("GameData").FACTIONS.keys()
	gs.reset()
	var districts := ["shoreditch", "city", "greenwich", "camden", "kingscross", "battersea", "hampstead", "whitechapel"]
	var ores := ["time", "physics", "life", "fate", "emotion"]
	var secs := ["none", "basic", "warded", "guarded"]
	var i := 0
	for d in districts:
		for k in range(2):
			var id := "pv_%d" % i
			var ore: String = ores[i % 5]
			var growth := 10 + (i * 13) % 90
			var tier: String = ["poor", "fair", "rich"][i % 3]
			var v = fx.player_vein(id, "site_" + id, d, ore, growth, "fair")
			v["security"] = secs[i % 4]
			gs.state["world"]["sites"].append(fx.site("site_" + id, ore, "fair", true, null, d))
			gs.state["player"]["veins"].append(v)
			i += 1
	var j := 0
	for f in factions_node:
		for k in range(3):
			var id := "fv_%d" % j
			var site = fx.site("site_" + id, ores[j % 5], "fair", false, null, districts[(j * 3) % districts.size()])
			var v = load("res://systems/factions.gd").create_faction_vein(f, site, 15 + (j * 17) % 80)
			v["id"] = id
			site["factionVein"] = v
			gs.state["world"]["sites"].append(site)
			j += 1
	for k in range(6):
		gs.state["world"]["sites"].append(fx.site("us_%d" % k, ores[k % 5], "fair", false, null, districts[(k * 5) % districts.size()]))


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	for dark in [false, true]:
		for mode in ["ownership", "type", "growth", "security", "faction"]:
			await _capture(dark, mode, false, 0.5)
		await _capture(dark, "security", false, 1.3)
	await _capture(true, "ownership", true, 0.5)
	quit(0)


func _capture(dark: bool, mode: String, drawer: bool, zoom: float) -> void:
	_seed()
	var gs := root.get_node("GameState")
	gs.state["meta"]["mapDarkMode"] = dark
	var screen: Control = load("res://scenes/screens/map.gd").new()
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(screen)
	for n in range(4):
		await process_frame
	var canvas = screen._map_canvas
	if mode == "faction":
		canvas.set_faction_filter("firm")
	else:
		canvas.set_filter(mode)
	var focus: Vector2 = canvas._map_size * 0.5 if zoom < 1.0 else canvas._vein_stops[0]["position"]
	await canvas.pan_to(focus, zoom, 0.05)
	if drawer:
		screen._map_controls.open()
	for n in range(8):
		await process_frame
	var name := "%s_%s%s%s" % ["dark" if dark else "light", mode, "_drawer" if drawer else "", "_close" if zoom >= 1.0 else ""]
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + name + ".png"))
	print("Saved ", name)
	root.remove_child(screen)
	screen.free()
	await process_frame

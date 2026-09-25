extends SceneTree

# Dev-only Map overlay screenshot harness, run windowed (not --headless):
#   godot -s .scratch/map-dark-mode/capture_overlays.gd
# Saves the district bubble + legend + drawer, the vein bubble, the site
# sheet and the vein detail sheet in light and dark to OUT.

const OUT := "res://.scratch/map-dark-mode/screenshots/"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	for dark in [false, true]:
		for shot in ["bubble", "vein_bubble", "site_sheet", "vein_sheet"]:
			await _capture(dark, shot)
	quit(0)


func _capture(dark: bool, shot: String) -> void:
	var gs := root.get_node("GameState")
	var fx = load("res://tests/support/fixtures.gd")
	gs.reset()
	gs.state["flags"]["cultivationTutorialSeen"] = true
	gs.state["flags"]["veinSaleUnlocked"] = true
	var fv = load("res://systems/factions.gd").create_faction_vein("firm", fx.site("s2", "fate", "fair", false, null, "camden"), 40)
	var faction_site = fx.site("s2", "fate", "fair", false, fv, "camden")
	var own = fx.player_vein("pv", "s1", "camden", "time", 60, "fair")
	gs.state["world"]["sites"] = [fx.site("s1", "time", "fair", true, null, "camden"), faction_site]
	gs.state["player"]["veins"] = [own]
	gs.state["meta"]["mapDarkMode"] = dark

	var host := Control.new()
	host.theme = load("res://theme/main_theme.tres")
	host.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(host)
	var screen: Control = load("res://scenes/screens/map.gd").new()
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.add_child(screen)
	for n in range(4):
		await process_frame

	match shot:
		"bubble":
			screen._map_legend._on_header_pressed()
			screen._bubble.open(Vector2(180, 300), screen._build_district_bubble_options("camden"), Vector2(390, 844), true)
		"vein_bubble":
			screen._map_controls.open()
			screen._vein_bubble.open(Vector2(250, 420), { "id": "pv", "kind": "vein", "vein": own, "owner": "player", "site": { "id": "s1" } }, Vector2(390, 844))
		"site_sheet":
			load("res://systems/map_nav.gd").select_district("camden")
			load("res://systems/map_nav.gd").select_site("s2")
		"vein_sheet":
			load("res://systems/map_nav.gd").select_district("camden")
			load("res://systems/map_nav.gd").select_site("s1")
	for n in range(8):
		await process_frame
	var name := "overlay_%s_%s" % ["dark" if dark else "light", shot]
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + name + ".png"))
	print("Saved ", name)
	root.remove_child(host)
	host.free()
	await process_frame

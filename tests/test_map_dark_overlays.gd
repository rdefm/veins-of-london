extends "res://tests/test_base.gd"

# Map dark mode across the Map tab's overlays (M1.5 §Map palette): a live
# MapScreen restyles its bubbles, sheets, legend, zoom pill, drawer and top
# row on a toggle, and keeps what's open and the selected filter.

const Fixtures := preload("res://tests/support/fixtures.gd")
const Preferences := preload("res://systems/preferences.gd")


func run() -> void:
	await run_case("live_map_overlays_follow_the_dark_toggle_and_keep_what_is_open", func():
		var tree := Engine.get_main_loop() as SceneTree
		await tree.process_frame

		GameState.reset()
		GameState.state["flags"]["cultivationTutorialSeen"] = true
		GameState.state["world"]["sites"] = [Fixtures.site("s1", "time", "fair", false, null, "camden")]
		MapNav.select_district("camden")
		MapNav.select_site("s1")

		var host := Control.new()
		host.size = Vector2(390, 844)
		tree.root.add_child(host)
		var screen := MapScreen.new()
		host.add_child(screen)
		await tree.process_frame

		screen._bubble.open(Vector2(100, 100), screen._build_district_bubble_options("camden"), Vector2(390, 844), true)
		screen._map_legend._on_header_pressed()
		screen._map_controls._select_filter("growth")
		screen._map_controls.open()

		_assert_overlays(screen, false, "light before toggling")

		Preferences.set_map_dark_mode(true)
		await tree.process_frame
		_assert_overlays(screen, true, "after toggling dark")
		assert_true(screen._bubble.visible, "the open bubble stays open")
		assert_true(_live_children(screen._bubble._content).size() > 0, "the open bubble is rebuilt, not emptied")
		assert_true(screen._map_legend._expanded, "the legend stays expanded")
		assert_true(screen._map_controls._is_open, "the drawer stays open")
		assert_eq(screen._map_controls._filter_mode, "growth", "the drawer keeps the selected filter")
		assert_eq(screen._map_canvas.filter_mode, "growth", "the diagram keeps the selected filter")
		assert_eq(GameState.state["mapNav"]["selectedSiteId"], "s1", "the site sheet stays open")

		Preferences.set_map_dark_mode(false)
		await tree.process_frame
		_assert_overlays(screen, false, "after toggling back")
		assert_true(not screen._top_title.has_theme_color_override("font_color"), "light top row goes back to the global theme")
		assert_true(not screen._top_buttons[0].has_theme_stylebox_override("normal"), "light icon buttons go back to the global theme")

		host.free()
		GameState.reset()
	)

	run_case("open_vein_bubble_restyles_in_place_and_keeps_the_harvest_chooser", func():
		GameState.reset()
		var vein := Fixtures.player_vein_with({ "growth": 60 })
		var bubble := VeinBubble.new()
		bubble._ready()
		bubble.open(Vector2(100, 100), { "id": vein["id"], "kind": "vein", "vein": vein, "owner": "player", "site": { "id": vein["siteId"] } }, Vector2(390, 844))
		bubble._chooser_open = true
		bubble._rebuild()

		Preferences.set_map_dark_mode(true)
		assert_eq(_panel_bg(bubble._panel), MapPalette.colour_in("cardPaper", true), "vein bubble card goes dark")
		assert_true(bubble.visible, "vein bubble stays open")
		assert_true(bubble._chooser_open, "the Harvest chooser stays showing")

		Preferences.set_map_dark_mode(false)
		assert_eq(_panel_bg(bubble._panel), MapPalette.colour_in("cardPaper", false), "vein bubble card goes back to light")

		bubble.free()
		GameState.reset()
	)


	run_case("vein_list_off_the_map_tab_stays_light_with_dark_mode_on", func():
		GameState.reset()
		GameState.state["meta"]["mapDarkMode"] = true
		var screen := VeinListScreen.new()
		screen._ready()

		var panel: PanelContainer = screen._content.get_child(0)
		assert_eq(_panel_bg(panel), MapPalette.colour_in("cardPaper", false), "vein list card keeps light paper")
		assert_true(MapPalette.is_dark(), "the light scope ends with the build")

		screen.free()
		GameState.reset()
	)


func _assert_overlays(screen: MapScreen, dark: bool, context: String) -> void:
	var paper := MapPalette.colour_in("cardPaper", dark)
	var ink := MapPalette.colour_in("cardInk", dark)
	var dim := MapPalette.colour_in("cardDim", dark)
	var chrome := MapPalette.colour_in("chromePaper", dark)
	var chrome_ink := MapPalette.colour_in("chromeInk", dark)

	var district_panel: PanelContainer = _live_children(screen._content)[0]
	assert_eq(_panel_bg(district_panel), paper, "%s: district panel paper" % context)
	var sheet: PanelContainer = _live_children(screen._sheet_layer)[1]
	assert_eq(_panel_bg(sheet), paper, "%s: site sheet paper" % context)
	var sheet_labels := _live_labels(sheet)
	assert_true(sheet_labels.any(func(l: Label) -> bool: return l.get_theme_color("font_color") == dim), "%s: site sheet dim text" % context)
	assert_true(sheet_labels.any(func(l: Label) -> bool: return l.get_theme_color("font_color") == ink), "%s: site sheet ink text" % context)

	assert_eq(_panel_bg(screen._bubble._panel), paper, "%s: bubble paper" % context)
	assert_true(_live_labels(screen._bubble._content).any(func(l: Label) -> bool: return l.get_theme_color("font_color") == ink), "%s: bubble ink text" % context)

	assert_eq(_panel_bg(screen._map_legend._panel), chrome, "%s: legend paper" % context)
	assert_eq(screen._map_legend._title.get_theme_color("font_color"), chrome_ink, "%s: legend title" % context)
	assert_eq(_panel_bg(screen._map_zoom_buttons._pill), chrome, "%s: zoom pill paper" % context)
	assert_eq(screen._map_zoom_buttons._zoom_in_button.get_theme_color("font_color"), chrome_ink, "%s: zoom glyph" % context)
	assert_eq(_panel_bg(screen._map_controls._panel), chrome, "%s: drawer paper" % context)
	for l in _live_labels(screen._map_controls._list):
		assert_eq(l.get_theme_color("font_color"), chrome_ink, "%s: drawer heading '%s'" % [context, l.text])

	if dark:
		assert_eq(screen._top_title.get_theme_color("font_color"), MapPalette.colour_in("ink", true), "%s: top-row title" % context)
		assert_eq((screen._top_buttons[1].get_theme_stylebox("normal") as StyleBoxFlat).bg_color, chrome, "%s: top-row icon button" % context)


func _panel_bg(panel: PanelContainer) -> Color:
	return (panel.get_theme_stylebox("panel") as StyleBoxFlat).bg_color


func _live_children(node: Node) -> Array:
	return node.get_children().filter(func(c: Node) -> bool: return not c.is_queued_for_deletion())


func _live_labels(root: Node) -> Array:
	var found: Array = []
	for l in root.find_children("", "Label", true, false):
		if not l.is_queued_for_deletion() and l.is_visible_in_tree():
			found.append(l)
	return found

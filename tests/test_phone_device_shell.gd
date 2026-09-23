extends "res://tests/test_base.gd"

const NodeQuery := preload("res://tests/support/node_query.gd")
const PhoneDeviceShellScript := preload("res://scenes/components/phone_device_shell.gd")


func run() -> void:
	await run_case("phone_home_is_a_clipped_device_between_the_external_bars", func():
		GameState.reset()

		var tree := Engine.get_main_loop() as SceneTree
		var phone := PhoneScreen.new()
		tree.root.add_child(phone)
		await tree.process_frame
		await tree.process_frame

		var shell: PhoneDeviceShellScript = _find_shell(phone)
		assert_true(shell != null, "Phone owns one persistent simulated-device shell")
		assert_true(shell.get_global_rect().position.y >= UI.top_bar_clearance(), "device starts below the external top board")
		assert_true(shell.get_global_rect().end.y <= phone.get_viewport_rect().size.y - NavBar.BAR_HEIGHT, "device ends above the external nav bar")
		assert_true(shell.display.clip_children == CanvasItem.CLIP_CHILDREN_AND_DRAW, "inner display clips wallpaper/content to its rounded silhouette")
		assert_eq(shell.wallpaper_path, "res://assets/phone/phone-wallpaper.jpg", "home uses the approved wallpaper asset")
		assert_true(shell.wallpaper.texture != null, "approved wallpaper decodes into the home texture")
		assert_eq(shell.wallpaper.stretch_mode, TextureRect.STRETCH_KEEP_ASPECT_COVERED, "wallpaper uses aspect-fill/cover")
		var tiles := _app_tiles(phone)
		assert_true(not tiles.is_empty(), "home renders launcher tiles")
		for tile in tiles:
			var icon_path := AppTile.icon_path(tile._app_id)
			assert_true(icon_path.begins_with("res://assets/phone/icons/"), "%s icon lives under the phone asset root" % tile._app_id)
			assert_true(tile._icon_rect.visible and tile._icon_rect.texture != null, "%s launcher icon loads" % tile._app_id)
		assert_true(not DirAccess.dir_exists_absolute("res://assets/icons"), "no phone-tab assets remain under the general icon directory")

		var texts := NodeQuery.label_texts(phone)
		for expected in ["08:14", "87%", "Tue, 14 May", "☁  12°C  ·  London", "Same city. Different rules."]:
			assert_true(texts.has(expected), "home renders fixed presentation text: %s" % expected)
		var widget_texts := NodeQuery.label_texts(shell.content.get_child(0))
		assert_true(not widget_texts.has("Phone"), "legacy Phone heading is absent from the home widget")
		assert_true(shell.wallpaper.visible and not shell.app_surface.visible, "home shows wallpaper rather than app surface")

		tree.root.remove_child(phone)
		phone.free()
	)

	run_case("opening_an_app_keeps_the_shell_but_switches_to_the_dark_content_surface", func():
		GameState.reset()
		PhoneNav.open_app("notes")

		var phone := PhoneScreen.new()
		phone._ready()
		var shell: PhoneDeviceShellScript = _find_shell(phone)

		assert_true(shell != null, "device shell remains present for opened apps")
		assert_true(not shell.wallpaper.visible and shell.app_surface.visible, "opened app replaces home wallpaper with dark Phone-OS surface")
		var texts := NodeQuery.label_texts(phone)
		assert_true(texts.has("08:14") and texts.has("87%"), "persistent internal status bar remains around app content")
		assert_true(not texts.has("Tue, 14 May") and not texts.has("Same city. Different rules."), "home widget is absent inside an app")

		phone.free()
	)

	run_case("phone_home_presentation_is_loaded_and_validated_by_GameData", func():
		assert_eq(GameData.PHONE_HOME["wallpaper"], "res://assets/phone/phone-wallpaper.jpg", "wallpaper reference is data-owned")
		assert_eq(GameData.PHONE_HOME["status"]["time"], "08:14", "status copy is data-owned")
		assert_eq(GameData.PHONE_HOME["widget"]["flavour"], "Same city. Different rules.", "widget copy is data-owned")

		var broken: Dictionary = GameData.snapshot().duplicate(true)
		broken["phone_home"]["widget"].erase("flavour")
		var errors := GameData.validate_tables(broken)
		assert_true(_contains_error(errors, "phone_home.widget"), "GameData rejects missing required home-widget copy")
		broken = GameData.snapshot().duplicate(true)
		broken["phone_home"]["status"]["time"] = "09:00"
		errors = GameData.validate_tables(broken)
		assert_true(_contains_error(errors, "phone_home.status.time"), "GameData rejects altered fixed presentation values")
	)

	run_case("device_shell_does_not_own_or_reparent_external_bars", func():
		GameState.reset()
		var phone := PhoneScreen.new()
		phone._ready()
		var shell: PhoneDeviceShellScript = _find_shell(phone)

		assert_true(not _contains_external_bar(shell), "external top board and nav bar are not inside the device")

		phone.free()
	)


func _find_shell(root: Node) -> PhoneDeviceShellScript:
	for child in root.get_children():
		if child is PhoneDeviceShellScript:
			return child
	return null


func _app_tiles(root: Node) -> Array[AppTile]:
	var found: Array[AppTile] = []
	for child in root.get_children():
		if child is AppTile:
			found.append(child)
		found.append_array(_app_tiles(child))
	return found


func _contains_external_bar(root: Node) -> bool:
	if root is TopBar or root is NavBar:
		return true
	for child in root.get_children():
		if _contains_external_bar(child):
			return true
	return false


func _contains_error(errors: Array[String], fragment: String) -> bool:
	for error in errors:
		if fragment in error:
			return true
	return false

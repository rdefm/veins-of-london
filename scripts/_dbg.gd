extends SceneTree
func _init() -> void:
	await process_frame
	var pressed := []
	var dock := CombatCommandDock.new()
	dock.configure([{ "iconKind": "attack", "label": "Strike", "callback": func(): pressed.append("strike") }], [], {"name":"LegIt","label":"x","callback":Callable()}, null)
	var fight = dock.find_child("Page_fight", true, false)
	var bs = fight.find_children("", "Button", true, false)
	print("buttons ", bs.map(func(b): return b.name))
	bs[0].pressed.emit()
	print("armed ", dock.armed_key())
	bs = fight.find_children("", "Button", true, false)
	print("buttons ", bs.map(func(b): return b.name))
	bs[0].pressed.emit()
	print(pressed)
	quit()

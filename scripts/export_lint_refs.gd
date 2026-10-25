extends SceneTree

# Writes tools/lint_refs.json, the reference lists tools/storyboard.html's
# content lint reads (flags, items, contacts, state paths, recipe rungs, event
# choice-card keys and option ids) plus the GDScript lint's violations per
# shipped event. Regenerate after changing events, recipes or state shape:
#   godot --headless -s scripts/export_lint_refs.gd   (the project's Godot 4.7: JSON layout differs across versions)
# The lint is loaded at runtime: autoload identifiers only resolve once the
# tree has booted (same reason as scripts/check_runner.gd).


func _initialize() -> void:
	var game_data: Node = root.get_node("GameData")
	if not game_data.loaded:
		game_data.load_all()
		game_data.validate()
	await process_frame
	root.get_node("GameState").reset()
	var lint: GDScript = load("res://tests/support/event_content_lint.gd")
	var file := FileAccess.open(lint.REFS_PATH, FileAccess.WRITE)
	if file == null:
		print("export_lint_refs: can't write %s" % lint.REFS_PATH)
		quit(1)
		return
	file.store_string(lint.export_text())
	file.close()
	print("export_lint_refs: wrote %s" % lint.REFS_PATH)
	quit(0)

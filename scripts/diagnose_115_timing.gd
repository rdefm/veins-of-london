extends SceneTree

# Scratch diagnostic for bugfixes ticket 115 -- NOT part of the permanent
# suite. Mirrors tests/test_runner.gd's own bootstrap/discovery but prints
# a per-file elapsed-time delta (msec) so a runaway can be localised to a
# specific file instead of just "the whole suite is slow/hangs". Delete
# after the ticket's findings are written up.

const TEST_DIR := "res://tests/"
const EXCLUDE := ["test_runner.gd", "test_base.gd"]


func _initialize() -> void:
	var game_data: Node = root.get_node_or_null("GameData")
	if game_data != null and not game_data.loaded:
		game_data.load_all()
		game_data.validate()

	var test_files := _discover_tests()
	if test_files.is_empty():
		print("No test files found in %s" % TEST_DIR)
		quit(1)
		return

	var total_passed := 0
	var total_failed := 0
	var start_ms := Time.get_ticks_msec()
	var last_ms := start_ms

	for path in test_files:
		var script: GDScript = load(path)
		var instance = script.new()
		await instance.run()
		total_passed += instance.passed
		total_failed += instance.failed
		var now_ms := Time.get_ticks_msec()
		print("%6d ms (+%6d ms)  %s  [%d pass / %d fail]" % [now_ms - start_ms, now_ms - last_ms, path.get_file(), instance.passed, instance.failed])
		last_ms = now_ms

	print("")
	print("TOTAL: %d passed, %d failed, %d ms elapsed" % [total_passed, total_failed, Time.get_ticks_msec() - start_ms])
	quit(1 if total_failed > 0 else 0)


func _discover_tests() -> Array[String]:
	var files: Array[String] = []
	var dir := DirAccess.open(TEST_DIR)
	if dir == null:
		return files

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.begins_with("test_") and file_name.ends_with(".gd") and not EXCLUDE.has(file_name):
			files.append(TEST_DIR + file_name)
		file_name = dir.get_next()
	dir.list_dir_end()

	files.sort()
	return files

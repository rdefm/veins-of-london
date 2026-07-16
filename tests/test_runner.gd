extends SceneTree

# Headless test runner: godot --headless -s tests/test_runner.gd
# Discovers tests/test_*.gd (excluding this file and test_base.gd),
# instantiates each, calls run(), aggregates PASS/FAIL, and exits
# non-zero if anything failed.

const TEST_DIR := "res://tests/"
const EXCLUDE := ["test_runner.gd", "test_base.gd"]


func _initialize() -> void:
	var test_files := _discover_tests()
	if test_files.is_empty():
		print("No test files found in %s" % TEST_DIR)
		quit(1)
		return

	var total_passed := 0
	var total_failed := 0

	for path in test_files:
		var script: GDScript = load(path)
		var instance = script.new()
		print("== %s ==" % path.get_file())
		instance.run()
		total_passed += instance.passed
		total_failed += instance.failed

	print("")
	print("TOTAL: %d passed, %d failed" % [total_passed, total_failed])
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

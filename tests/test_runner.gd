extends SceneTree

# Headless test runner: godot --headless -s tests/test_runner.gd
# Discovers tests/test_*.gd (excluding this file and test_base.gd),
# instantiates each, calls run(), aggregates PASS/FAIL, and exits
# non-zero if anything failed.

const TEST_DIR := "res://tests/"
const EXCLUDE := ["test_runner.gd", "test_base.gd"]


func _initialize() -> void:
	# Autoload _ready() callbacks are deferred and never get a chance to run
	# under a synchronous -s SceneTree script (there's no frame loop to flush
	# them), so GameData would still be empty when tests start. Force it to
	# load its tables right now instead of waiting on its own _ready().
	var game_data: Node = root.get_node_or_null("GameData")
	if game_data != null and not game_data.loaded:
		game_data.load_all()
		game_data.validate()

	# bugfixes ticket 124: flush one real engine frame up front so every
	# autoload's own deferred _ready() -- not just GameData's forced call
	# above -- has already run before any test case starts. Without this,
	# whichever case happens to be first in the whole process to `await` a
	# frame (test_hq_lab_bench.gd, historically) is also the first point
	# autoload/GameState.gd's EventBus.shared_stock_increased connection
	# actually appears (ticket 123), which run_case()'s teardown could then
	# mistake for a freshly leaked node. This closes that timing hazard at
	# its source; protect_autoloads() below is the backstop in case some
	# other autoload's _ready() ever grows the same pattern.
	await process_frame

	# bugfixes ticket 124: snapshot every registered autoload's instance id
	# so test_base.gd's run_case() teardown can tell a genuinely leaked
	# off-tree test node apart from an autoload singleton it must never
	# disconnect or free (122-diagnose-full-suite-segfault_COMPLETED.md).
	# load(), not a top-level preload() const: this file is itself the `-s`
	# entry script, and a top-level preload() of test_base.gd (which
	# references the EventBus autoload identifier) compiles before the
	# engine has registered any autoload, failing with "Identifier not
	# found: EventBus" -- load() from inside _initialize() runs after
	# autoloads are live, same as this same function's own `load(path)`
	# calls on each discovered test file below.
	var test_base_script: GDScript = load("res://tests/test_base.gd")
	test_base_script.protect_autoloads(root.get_children())

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
		# Awaited (not a bare call) so a test file whose run() awaits a real
		# engine frame (bugfixes ticket 88 — see test_base.gd's run_case)
		# actually finishes before its passed/failed counts are read below.
		# A no-op for every other file: GDScript only suspends at a real
		# await point, so a synchronous run() still completes immediately.
		await instance.run()
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

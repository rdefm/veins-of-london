extends SceneTree

# Headless syntax check:
#   godot --headless -s scripts/check_runner.gd                     # whole project
#   godot --headless -s scripts/check_runner.gd -- path/to/file.gd  # just this file
#   (paths after `--` may be project-relative or res://, one or many)
#
# Replaces the old check_all.sh loop of `godot --check-only --script X` per
# file (and CLAUDE.md's per-file check-only advice, same issue). That flag
# combo parses a single file with no SceneTree ever booted, so autoload
# identifiers (GameData, GameState, EventBus, ...) never resolve -- every
# file that references one false-positived as a compile error, regardless
# of whether the file was actually fine. Running from inside _initialize()
# instead means the engine has already registered autoloads as singletons
# in the tree (same reason tests/test_runner.gd's -s SceneTree script can
# see GameData), so a plain load() per file gets a real syntax/identifier
# check with no false positives.
#
# load() itself doesn't return null on a compile error -- it still hands
# back a GDScript object (the SCRIPT ERROR only prints to the console as a
# side effect), so failure has to be read off can_instantiate() instead,
# which is false for anything that failed to compile (verified against a
# deliberately broken scratch script).
#
# Exits non-zero if any file fails to load.

const EXCLUDE := ["check_runner.gd"]


func _initialize() -> void:
	var user_args := OS.get_cmdline_user_args()
	var files: Array[String] = []
	if user_args.is_empty():
		files = _discover_gd_files("res://")
		files.sort()
	else:
		for arg in user_args:
			files.append(arg if arg.begins_with("res://") else "res://" + arg.trim_prefix("./"))

	var fail := 0
	for path in files:
		var script: GDScript = load(path)
		if script == null or not script.can_instantiate():
			print("FAILED: %s" % path)
			fail += 1

	print("")
	print("Checked %d file(s)." % files.size())
	print("check_all: FAILED" if fail > 0 else "check_all: all clean")
	quit(1 if fail > 0 else 0)


# Skips any directory starting with "." (.godot, .godot-bin, .git, .claude,
# .scratch, ...) -- everything under those is engine cache, tooling, or
# prose, never project source.
func _discover_gd_files(dir_path: String) -> Array[String]:
	var files: Array[String] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return files

	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if dir.current_is_dir():
			if not name.begins_with("."):
				files.append_array(_discover_gd_files(dir_path.path_join(name)))
		elif name.ends_with(".gd") and not EXCLUDE.has(name):
			files.append(dir_path.path_join(name))
		name = dir.get_next()
	dir.list_dir_end()

	return files

extends RefCounted

# Base class for test files. Extend with `extends "res://tests/test_base.gd"`
# (path-based, not class_name — headless CLI runs can't rely on the editor
# having built a global class cache). Implement `run()` and call
# `run_case(name, fn)` once per case inside it.

var passed := 0
var failed := 0
var _case_failures: Array[String] = []


func run() -> void:
	push_error("test file did not override run()")


func run_case(case_name: String, fn: Callable) -> void:
	_case_failures = []
	var eventbus_before := _snapshot_eventbus_connections()
	# `await` here is a no-op for the overwhelming majority of cases, whose
	# `fn` never itself awaits anything -- GDScript only actually suspends at
	# a real await point, so a synchronous fn.call() still runs start-to-
	# finish, in order, before this line moves on (see bugfixes ticket 88's
	# own investigation notes for why this was verified directly rather than
	# assumed). It exists so a case that DOES need a real engine frame to
	# elapse (e.g. to prove a ScrollContainer's own deferred layout pass has
	# caught up) can `await (Engine.get_main_loop() as SceneTree).process_frame`
	# inside `fn` (test files are RefCounted, not Node, so there's no
	# get_tree() here) and have this call site actually wait for that —
	# every call site above this one
	# (run() in the case's own test file) then has to `await run_case(...)`
	# in turn for that suspension to actually propagate, same as
	# tests/test_runner.gd now `await`s each file's run().
	await fn.call()
	_disconnect_and_free_new_eventbus_connections(eventbus_before)
	if _case_failures.is_empty():
		passed += 1
		print("  PASS: %s" % case_name)
	else:
		failed += 1
		print("  FAIL: %s" % case_name)
		for msg in _case_failures:
			print("        %s" % msg)


# bugfixes ticket 116: off-tree `Screen.new(); screen._ready()` cases (the
# convention tests/test_hq_screen.gd etc. established) connect to EventBus
# signals in _ready() with no matching disconnect, and queue_free() alone
# never runs synchronously on a node that was never added to a live
# SceneTree (nothing ever flushes the deferred free), so the connection --
# and the node it targets -- both survive for the rest of the whole
# `godot --headless -s tests/test_runner.gd` process. Every later test
# file's GameState mutations then re-trigger every leaked screen's
# _refresh()/_sync(), compounding into the O(mutations * leaked listeners)
# runaway diagnosed in ticket 115. Rather than patch each of the dozen+
# affected test files individually, run_case snapshots EventBus's
# connections before each case and disconnects (and frees) whatever is new
# after -- catching any off-tree node any case builds and abandons, in any
# test file, present or future, with no per-file plumbing.
func _snapshot_eventbus_connections() -> Dictionary:
	var snapshot := {}
	for sig_name in _eventbus_signal_names():
		var callables: Array[Callable] = []
		for conn in EventBus.get_signal_connection_list(sig_name):
			callables.append(conn["callable"])
		snapshot[sig_name] = callables
	return snapshot


func _disconnect_and_free_new_eventbus_connections(before: Dictionary) -> void:
	var freed_ids := {}
	# Only the signals present in `before` can possibly have gained a new
	# connection since -- no need to re-list every EventBus signal here too.
	for sig_name in before:
		var before_callables: Array[Callable] = before[sig_name]
		for conn in EventBus.get_signal_connection_list(sig_name):
			var callable: Callable = conn["callable"]
			if before_callables.has(callable):
				continue
			EventBus.disconnect(sig_name, callable)
			var target := callable.get_object()
			if target is Node and not freed_ids.has(target.get_instance_id()):
				freed_ids[target.get_instance_id()] = true
				target.queue_free()


func _eventbus_signal_names() -> Array[String]:
	var names: Array[String] = []
	for sig in EventBus.get_signal_list():
		names.append(sig["name"])
	return names


func assert_eq(actual, expected, msg: String = "") -> void:
	if actual != expected:
		_case_failures.append("assert_eq: got %s, expected %s. %s" % [str(actual), str(expected), msg])


func assert_true(condition: bool, msg: String = "") -> void:
	if not condition:
		_case_failures.append("assert_true: condition was false. %s" % msg)


func assert_almost_eq(actual: float, expected: float, eps: float, msg: String = "") -> void:
	if absf(actual - expected) > eps:
		_case_failures.append("assert_almost_eq: got %s, expected %s (eps=%s). %s" % [str(actual), str(expected), str(eps), msg])

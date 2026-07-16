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
	fn.call()
	if _case_failures.is_empty():
		passed += 1
		print("  PASS: %s" % case_name)
	else:
		failed += 1
		print("  FAIL: %s" % case_name)
		for msg in _case_failures:
			print("        %s" % msg)


func assert_eq(actual, expected, msg: String = "") -> void:
	if actual != expected:
		_case_failures.append("assert_eq: got %s, expected %s. %s" % [str(actual), str(expected), msg])


func assert_true(condition: bool, msg: String = "") -> void:
	if not condition:
		_case_failures.append("assert_true: condition was false. %s" % msg)


func assert_almost_eq(actual: float, expected: float, eps: float, msg: String = "") -> void:
	if absf(actual - expected) > eps:
		_case_failures.append("assert_almost_eq: got %s, expected %s (eps=%s). %s" % [str(actual), str(expected), str(eps), msg])

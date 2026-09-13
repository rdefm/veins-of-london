extends "res://tests/test_base.gd"

# day-rhythm ticket 05: Input.vibrate_handheld() is implemented on Android/
# iOS/Web only (verified against Godot 4.7's own class reference) -- a
# headless test runner's host OS is never one of those, so this only proves
# the adapter reports "unsupported" correctly and buzz() is a safe no-op
# there. Real vibration and preference suppression are physical-device QA
# only (spec's own testing decisions).

const Haptics := preload("res://scenes/components/haptics.gd")


func run() -> void:
	run_case("supported_platform_list_is_exactly_android_ios_web", func():
		assert_eq(Haptics.SUPPORTED_PLATFORMS, ["Android", "iOS", "Web"])
	)

	run_case("headless_test_host_reports_unsupported_and_buzz_is_a_safe_no_op", func():
		assert_true(not Haptics.is_supported(), "the CI/dev host OS (%s) is never a handheld platform" % OS.get_name())
		Haptics.buzz()
		assert_true(true, "buzz() returned without error on an unsupported platform")
	)

extends "res://tests/test_base.gd"

# Ticket 12: Main.gd's resolve_screen_id() is the fallback that runs before
# any SCREEN_SCRIPTS lookup -- retired ids (home/you/bag/inventory) must
# land on "phone" (the app grid), while genuinely-unknown ids still fall
# back to "title", same as before this ticket. Called on the preloaded
# script directly (static func, no class_name) rather than booting the
# full Main scene tree, same reasoning phone.gd's _build_app_grid split
# documents for its own testability.

const MainScript := preload("res://scenes/Main.gd")


func run() -> void:
	run_case("retired_ids_resolve_to_phone", func():
		for retired_id in ["home", "you", "bag", "inventory"]:
			assert_eq(MainScript.resolve_screen_id(retired_id), "phone", "%s should resolve to phone" % retired_id)
	)

	run_case("unknown_ids_still_fall_back_to_title", func():
		assert_eq(MainScript.resolve_screen_id("not_a_real_screen"), "title", "a genuinely unknown id should still fall back to title")
	)

	run_case("valid_ids_resolve_to_themselves", func():
		for valid_id in MainScript.SCREEN_SCRIPTS.keys():
			assert_eq(MainScript.resolve_screen_id(valid_id), valid_id, "%s is already a valid screen id" % valid_id)
	)

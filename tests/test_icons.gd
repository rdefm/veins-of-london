extends "res://tests/test_base.gd"

# Icons (M1.5 N6 asset 2) — pure-logic coverage only. The draw_* functions
# themselves are immediate-mode CanvasItem drawing (only legal inside an
# active _draw() call) and, like map_canvas.gd's own _draw(), aren't
# exercised by this headless suite — same convention the rest of the
# Network Map's rendering code follows.


func run() -> void:
	run_case("kinds_match_n6s_8_icons_exactly", func():
		var expected := ["home", "pin", "padlock", "market", "phone", "bag", "legend", "news"]
		assert_eq(Icons.KINDS.size(), expected.size())
		for kind in expected:
			assert_true(Icons.KINDS.has(kind), kind)
	)

	run_case("is_valid_kind_matches_kinds_only", func():
		for kind in Icons.KINDS:
			assert_true(Icons.is_valid_kind(kind), kind)
		assert_true(not Icons.is_valid_kind("envelope"), "no 9th icon per N6")
		assert_true(not Icons.is_valid_kind(""))
	)

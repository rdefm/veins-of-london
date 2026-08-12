extends "res://tests/test_base.gd"

# Icons (M1.5 N6 asset 2) — pure-logic coverage only. The draw_* functions
# themselves are immediate-mode CanvasItem drawing (only legal inside an
# active _draw() call) and, like map_canvas.gd's own _draw(), aren't
# exercised by this headless suite — same convention the rest of the
# Network Map's rendering code follows.


func run() -> void:
	# Bugfixes ticket 13 added a 9th icon, "hamburger" — an approved
	# exception to N6's original "exactly 8, nothing added" (see icons.gd's
	# header comment and docs/M1.5-NETWORK-MAP.md's N6 asset list).
	run_case("kinds_match_n6s_8_icons_plus_ticket_13s_hamburger", func():
		var expected := ["home", "pin", "padlock", "market", "phone", "bag", "legend", "news", "hamburger"]
		assert_eq(Icons.KINDS.size(), expected.size())
		for kind in expected:
			assert_true(Icons.KINDS.has(kind), kind)
	)

	run_case("is_valid_kind_matches_kinds_only", func():
		for kind in Icons.KINDS:
			assert_true(Icons.is_valid_kind(kind), kind)
		assert_true(not Icons.is_valid_kind("envelope"), "still no 10th icon — the ✉ map pin glyph gap is a separate, already-flagged follow-up")
		assert_true(not Icons.is_valid_kind(""))
	)

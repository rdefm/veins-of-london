extends "res://tests/test_base.gd"

# Icons (M1.5 N6 asset 2) — KINDS/is_valid_kind() is pure-logic coverage.
#
# Ticket 35: draw_padlock and draw_pin are also now exercised for real, via
# tests/support/draw_spy.gd — the two `draw_*` functions ticket 34's spike
# retyped from `target: CanvasItem` to `target: Object` (shadowing a native
# CanvasItem method is a hard GDScript compile error, so a plain RefCounted
# double fills that seam; see ticket 34's `## Answer`). The other 7 draw_*
# kinds (home/market/phone/bag/legend/news/hamburger) stay CanvasItem-typed
# — out of ticket 35's scoped checklist, which names only draw_padlock/
# draw_pin — so they're still untested here, only legal inside a live
# _draw() call, same as the rest of the Network Map's rendering code.


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

	run_case("draw_padlock_draws_one_body_rect_and_one_shackle_arc", func():
		var spy := DrawSpy.new()
		var center := Vector2(10.0, 20.0)

		Icons.draw_padlock(spy, center, Color.RED, 1.0)

		assert_eq(spy.calls_matching("draw_rect").size(), 1, "one padlock body rect")
		assert_eq(spy.calls_matching("draw_arc").size(), 1, "one shackle arc")
	)

	run_case("draw_pin_draws_a_triangular_point_and_a_circular_head_returning_the_heads_own_centre", func():
		var spy := DrawSpy.new()
		var pos := Vector2(5.0, 5.0)

		var head := Icons.draw_pin(spy, pos, Color.BLUE, 1.0)

		assert_eq(spy.calls_matching("draw_colored_polygon").size(), 1, "one triangular point polygon down to `pos`")
		assert_eq(spy.calls_matching("draw_circle").size(), 1, "one circular head")
		var head_radius := 9.0
		assert_eq(head, pos + Vector2(0, -head_radius * 1.6), "returned head centre matches where the head circle was actually drawn")
		var head_circles: Array = spy.calls_matching("draw_circle")
		assert_eq(head_circles[0]["args"][0], head, "the recorded draw_circle call is centred on the returned head point")
	)

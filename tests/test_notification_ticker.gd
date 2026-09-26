extends "res://tests/test_base.gd"

# NotificationTicker (ui-vision.md §5): the top board's one-message notice
# row. Driven off-tree through advance() so timing is deterministic.

const WIDE := 2000.0


func _ticker(width: float = WIDE) -> NotificationTicker:
	var ticker := NotificationTicker.new()
	ticker.size = Vector2(width, NotificationTicker.row_height())
	return ticker


# Width of `chars` characters on the row, so a message of more than that
# many characters overflows.
func _width_for(chars: int) -> float:
	return DotMatrixFont.text_width("X".repeat(chars), NotificationTicker.DOT_SIZE, DotMatrixBoard.CHAR_GAP)


func run() -> void:
	run_case("enqueue_on_an_idle_board_rolls_the_message_up_immediately", func():
		var ticker := _ticker()
		ticker.enqueue("Hello")

		assert_eq(ticker.current_text, "HELLO")
		assert_eq(ticker.phase, NotificationTicker.Phase.ROLLING)
		assert_eq(ticker.queued(), [] as Array[String])

		ticker.free()
	)

	run_case("queued_messages_show_in_order_each_after_a_full_hold", func():
		var ticker := _ticker()
		ticker.enqueue("A")
		ticker.enqueue("B")
		ticker.enqueue("C")

		ticker.advance(NotificationTicker.ROLL_SECONDS)
		assert_eq(ticker.phase, NotificationTicker.Phase.HOLDING)
		ticker.advance(NotificationTicker.HOLD_SECONDS - 0.01)
		assert_eq(ticker.current_text, "A", "still holding just short of 4s")

		ticker.advance(0.02)
		assert_eq(ticker.current_text, "B", "the next rolls up once the hold ends")
		assert_eq(ticker.phase, NotificationTicker.Phase.ROLLING)
		assert_eq(ticker.queued(), ["C"] as Array[String])

		ticker.advance(NotificationTicker.ROLL_SECONDS + NotificationTicker.HOLD_SECONDS + 0.01)
		assert_eq(ticker.current_text, "C")

		ticker.free()
	)

	run_case("hold_is_four_seconds", func():
		assert_eq(NotificationTicker.HOLD_SECONDS, 4.0)
	)

	run_case("the_latest_message_stays_when_the_queue_is_empty", func():
		var ticker := _ticker()
		ticker.enqueue("Last word")

		ticker.advance(60.0)

		assert_eq(ticker.current_text, "LAST WORD")
		assert_eq(ticker.phase, NotificationTicker.Phase.IDLE)

		ticker.enqueue("Next")
		assert_eq(ticker.current_text, "NEXT", "an idle board rolls a newcomer up straight away")

		ticker.free()
	)

	run_case("an_overflowing_message_marquees_to_its_end_before_the_hold_starts", func():
		var ticker := _ticker(_width_for(5))
		ticker.enqueue("ABCDEFGHIJ")
		ticker.enqueue("NEXT")
		var overflow: float = _width_for(10) - _width_for(5)

		ticker.advance(NotificationTicker.ROLL_SECONDS + NotificationTicker.MARQUEE_LEAD_SECONDS + 0.001)
		assert_eq(ticker.phase, NotificationTicker.Phase.SCROLLING)
		assert_almost_eq(ticker.scroll_offset(), 0.0, 0.1, "starts from the message's first character")

		var scroll_seconds := overflow / NotificationTicker.MARQUEE_SPEED
		ticker.advance(scroll_seconds * 0.5)
		assert_almost_eq(ticker.scroll_offset(), overflow * 0.5, 0.1, "scrolls at MARQUEE_SPEED")

		ticker.advance(scroll_seconds * 0.5)
		assert_eq(ticker.phase, NotificationTicker.Phase.HOLDING, "the hold begins once the end is showing")
		assert_almost_eq(ticker.scroll_offset(), overflow, 0.01)

		ticker.advance(NotificationTicker.HOLD_SECONDS - 0.01)
		assert_eq(ticker.current_text, "ABCDEFGHIJ")
		ticker.advance(0.02)
		assert_eq(ticker.current_text, "NEXT")
		assert_eq(ticker.scroll_offset(), 0.0)

		ticker.free()
	)

	run_case("a_short_message_never_scrolls", func():
		var ticker := _ticker(_width_for(5))
		ticker.enqueue("ABC")

		ticker.advance(NotificationTicker.ROLL_SECONDS)

		assert_eq(ticker.phase, NotificationTicker.Phase.HOLDING, "fits, so straight to the hold")
		assert_eq(ticker.scroll_offset(), 0.0)

		ticker.free()
	)

	run_case("an_overflowing_latest_message_keeps_cycling_its_marquee_when_nothing_is_queued", func():
		var ticker := _ticker(_width_for(5))
		ticker.enqueue("ABCDEFGHIJ")

		ticker.advance(60.0)

		assert_eq(ticker.current_text, "ABCDEFGHIJ", "still the latest")
		assert_true(ticker.phase != NotificationTicker.Phase.IDLE and ticker.phase != NotificationTicker.Phase.ROLLING, "loops lead/scroll/hold so the start comes back round")

		ticker.free()
	)

	run_case("show_immediately_replaces_the_board_and_clears_the_queue_without_rolling", func():
		var ticker := _ticker()
		ticker.enqueue("A")
		ticker.enqueue("B")

		ticker.show_immediately("Fresh")

		assert_eq(ticker.current_text, "FRESH")
		assert_eq(ticker.queued(), [] as Array[String])
		assert_eq(ticker.phase, NotificationTicker.Phase.HOLDING)

		ticker.free()
	)

	run_case("a_blank_board_is_idle_so_the_first_message_rolls_up_at_once", func():
		var ticker := _ticker()
		ticker.show_immediately("")
		assert_eq(ticker.phase, NotificationTicker.Phase.IDLE)

		ticker.enqueue("First")
		assert_eq(ticker.current_text, "FIRST")
		assert_eq(ticker.phase, NotificationTicker.Phase.ROLLING)

		ticker.free()
	)

	run_case("mid_roll_both_messages_are_drawn_the_old_rising_out_and_the_new_from_below", func():
		var ticker := _ticker()
		ticker.show_immediately("A")
		ticker.enqueue("B")
		ticker.advance(NotificationTicker.HOLD_SECONDS + NotificationTicker.ROLL_SECONDS * 0.5)

		var spy := DrawSpy.new()
		ticker.render(spy)

		var rects: Array = spy.calls_matching("draw_rect")
		var row_h := NotificationTicker.row_height()
		var above: Array = rects.filter(func(c): return c["args"][0].position.y < 0.0)
		var below: Array = rects.filter(func(c): return c["args"][0].position.y + NotificationTicker.DOT_SIZE > row_h)
		assert_true(not above.is_empty(), "the outgoing message has risen partly above the row")
		assert_true(not below.is_empty(), "the incoming message is still partly below the row")
		assert_eq(rects.size(), 2 * DotMatrixFont.GLYPH_W * DotMatrixFont.GLYPH_H, "one character from each message")

		ticker.free()
	)

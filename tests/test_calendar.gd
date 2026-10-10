extends "res://tests/test_base.gd"


func run() -> void:
	run_case("day_one_is_tuesday_first_of_april", func():
		assert_eq(Calendar.format_day(1), "TUE 1 APR")
	)

	run_case("first_monday_is_day_seven", func():
		assert_eq(Calendar.format_day(7), "MON 7 APR")
		assert_true(not Calendar.is_monday(1), "day 1 is not a Monday")
		assert_eq(Calendar.monday_on_or_after(1), 7)
		assert_eq(Calendar.next_weekday_after(7, 0), 14)
	)

	run_case("start_weekday_comes_from_data", func():
		var original: Dictionary = GameData.CALENDAR
		GameData.CALENDAR = original.duplicate()
		GameData.CALENDAR["startWeekday"] = 0
		var monday_start := Calendar.format_day(1)
		GameData.CALENDAR = original
		assert_eq(monday_start, "MON 1 APR")
	)

	run_case("day_twenty_nine_rolls_to_may", func():
		assert_eq(Calendar.format_day(28), "MON 28 APR")
		assert_eq(Calendar.format_day(29), "TUE 1 MAY")
	)

	run_case("last_day_of_december_year_one_has_no_year", func():
		assert_eq(Calendar.format_day(252), "MON 28 DEC")
	)

	run_case("first_january_starts_year_two", func():
		assert_eq(Calendar.format_day(253), "TUE 1 JAN Y2")
		assert_eq(Calendar.date_parts(253), { "weekday": "TUE", "dayOfMonth": 1, "month": "JAN", "year": 2 })
	)

	run_case("deep_into_year_three", func():
		# day 253 + 336 = 1 JAN Y3; +100 days = 3 months (84) + 16 days → THU 17 APR Y3.
		assert_eq(Calendar.format_day(253 + 336 + 100), "THU 17 APR Y3")
	)

	run_case("new_game_first_monday_bill_lands_on_day_seven", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 100000
		for i in 14:
			TimeSystem.do_rest()
		var bills: Array = GameState.state["bankLog"].filter(func(e: Dictionary) -> bool: return e["label"] == "Weekly living costs")
		var charged_days: Array = bills.map(func(e: Dictionary) -> int: return e["day"])
		assert_eq(charged_days, [7, 14], "bills on MON day 7 and MON day 14")
	)

extends "res://tests/test_base.gd"


func run() -> void:
	run_case("day_one_is_monday_first_of_april", func():
		assert_eq(Calendar.format_day(1), "MON 1 APR")
	)

	run_case("day_eight_is_next_monday_same_month", func():
		assert_eq(Calendar.format_day(8), "MON 8 APR")
	)

	run_case("day_twenty_nine_rolls_to_may", func():
		assert_eq(Calendar.format_day(28), "SUN 28 APR")
		assert_eq(Calendar.format_day(29), "MON 1 MAY")
	)

	run_case("last_day_of_december_year_one_has_no_year", func():
		assert_eq(Calendar.format_day(252), "SUN 28 DEC")
	)

	run_case("first_january_starts_year_two", func():
		assert_eq(Calendar.format_day(253), "MON 1 JAN Y2")
		assert_eq(Calendar.date_parts(253), { "weekday": "MON", "dayOfMonth": 1, "month": "JAN", "year": 2 })
	)

	run_case("deep_into_year_three", func():
		# day 253 + 336 = 1 JAN Y3; +100 days = 3 months (84) + 16 days → WED 17 APR Y3.
		assert_eq(Calendar.format_day(253 + 336 + 100), "WED 17 APR Y3")
	)

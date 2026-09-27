class_name Calendar
extends RefCounted

# Converts the world.day integer into the player-facing calendar date per
# R§3.1 "Calendar". Pure: reads only GameData.CALENDAR, never state.


# { weekday, dayOfMonth, month, year } for a 1-based world.day. weekday and
# month are names from GameData.CALENDAR; dayOfMonth and year are 1-based.
static func date_parts(day: int) -> Dictionary:
	var cal: Dictionary = GameData.CALENDAR
	var days_per_month: int = cal["daysPerMonth"]
	var months: Array = cal["monthNames"]
	var weekdays: Array = cal["weekdayNames"]
	var days_per_year: int = days_per_month * months.size()
	var index: int = maxi(0, day - 1) + int(cal["startMonth"]) * days_per_month
	return {
		"weekday": weekdays[index % weekdays.size()],
		"dayOfMonth": index % days_per_month + 1,
		"month": months[(index % days_per_year) / days_per_month],
		"year": index / days_per_year + 1,
	}


# Display string, e.g. "MON 3 JAN"; from year 2 on, "MON 3 JAN Y2".
static func format_day(day: int) -> String:
	var cal: Dictionary = GameData.CALENDAR
	var parts := date_parts(day)
	var text: String = cal["dateFormat"] % [parts["weekday"], parts["dayOfMonth"], parts["month"]]
	if parts["year"] > 1:
		text += cal["yearSuffix"] % parts["year"]
	return text

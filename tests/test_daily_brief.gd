extends "res://tests/test_base.gd"

const Fixtures := preload("res://tests/support/fixtures.gd")


func run() -> void:
	calendar_start_weekday = 0  # fixtures count days from a Monday day 1
	run_case("projection_never_mutates_state", func():
		_seed_every_source()
		var before: Dictionary = GameState.deep_copy(GameState.state)
		DailyBrief.items()
		DailyBrief.badge_count()
		DailyBrief.summary()
		assert_eq(GameState.state, before, "state deep-equal before and after")
	)

	run_case("home_and_vein_alarms_are_urgent_rows_that_drop_off_when_resolved", func():
		GameState.reset()
		Fixtures.seed_vein("v1", 50)
		GameState.state["home"]["pendingRaid"] = true
		GameState.state["world"]["pendingDefendRaids"] = [{ "veinId": "v1", "siteId": "site_v1", "outcomeType": "claim", "notificationId": "n1" }]
		var alarms := _kind("alarm")
		assert_eq(alarms.size(), 2)
		assert_eq(alarms.map(func(r): return r["key"]), ["alarm:home", "alarm:v1"])
		for row in alarms:
			assert_eq([row["tier"], row["action"], row["done"]], ["urgent", { "to": "alarms" }, false])
		assert_true(String(alarms[0]["consequence"]).find("carried calc may be stolen") != -1, "consequence from the alarm row")
		GameState.state["home"]["pendingRaid"] = false
		GameState.state["world"]["pendingDefendRaids"] = []
		assert_eq(_kind("alarm"), [], "resolved alarms drop off")
	)

	run_case("guard_shortfall_is_an_urgent_row_with_its_deadline_until_resolved", func():
		_seed_guard_shortfall()
		var rows := _kind("guardShortfall")
		assert_eq(rows.size(), 1)
		var deadline: int = GuardUpkeep.pending_shortfall()["deadline"]
		assert_eq([rows[0]["tier"], rows[0]["action"], rows[0]["sort"]], ["urgent", { "to": "short_pay" }, deadline - int(GameState.state["world"]["day"])])
		assert_true(String(rows[0]["consequence"]).find(Calendar.format_day(deadline)) != -1, "names the walk-off day")
		GuardUpkeep.confirm_shortfall({})
		assert_eq(_kind("guardShortfall"), [])
	)

	run_case("wage_prompt_then_owed_wages_are_urgent_rows_until_paid", func():
		GameState.reset()
		Business.activate()
		var wage: Dictionary = GameState.state["business"]["wages"]["owen"]
		wage["owed"] = 120
		wage["unpaid"] = true
		wage["promptPending"] = true
		var rows := _kind("wages")
		assert_eq(rows.size(), 1)
		assert_eq([rows[0]["tier"], rows[0]["key"], rows[0]["action"]], ["urgent", "wages:owen", { "to": "wage_prompt", "contactId": "owen" }])
		assert_true(String(rows[0]["label"]).find("£120") != -1)
		Business.decline_wage_prompt("owen")
		rows = _kind("wages")
		assert_eq(rows[0]["action"], { "to": "bizbrief_staff", "contactId": "owen" }, "an answered prompt still owes: route to Staff")
		GameState.state["player"]["cash"] = 1000
		Business.top_up_and_pay_owed("owen")
		assert_eq(_kind("wages"), [], "paid wages drop off")
	)

	run_case("development_eligible_veins_are_routine_rows_that_open_the_vein", func():
		GameState.reset()
		Fixtures.seed_vein("eligible", 95)
		var capped := Fixtures.seed_vein("capped", 95)
		capped["level"] = 3
		var rows := _kind("development")
		assert_eq(rows.size(), 1)
		assert_eq([rows[0]["tier"], rows[0]["key"], rows[0]["action"]], ["routine", "development:eligible", { "to": "map_vein", "veinId": "eligible" }])
		assert_true(String(rows[0]["consequence"]).find(str(Cultivating.combined_magnitude(GameState.state["player"]["veins"][0]))) != -1, "raid exposure shown")
		Cultivating.prune("eligible", GameData.VEIN_GROWTH["pruneHardDepth"])
		assert_eq(_kind("development"), [], "pruned below the threshold drops off live")
	)

	run_case("unread_messages_are_not_rows", func():
		GameState.reset()
		Messages.append("archie", "them", "Call me.")
		assert_eq(DailyBrief.items(), [])
	)

	run_case("rows_order_by_tier_then_sort", func():
		_seed_every_source()
		var items := DailyBrief.items()
		var tiers: Array = GameData.DAILY_BRIEF["tierOrder"]
		for i in range(1, items.size()):
			var prev: Dictionary = items[i - 1]
			var cur: Dictionary = items[i]
			var prev_tier := tiers.find(prev["tier"])
			var cur_tier := tiers.find(cur["tier"])
			assert_true(prev_tier < cur_tier or (prev_tier == cur_tier and int(prev["sort"]) <= int(cur["sort"])), "%s before %s" % [prev["key"], cur["key"]])
		assert_eq(items[-1]["tier"], "routine", "the development row comes last")
		var urgent_keys: Array = items.filter(func(r): return r["tier"] == "urgent").map(func(r): return r["key"])
		assert_eq(urgent_keys[-1], "guardShortfall", "the guard deadline is days off, so it sorts after today's alarm")
	)

	run_case("badge_counts_urgent_and_story_only", func():
		GameState.reset()
		Fixtures.seed_vein("eligible", 95)
		assert_eq(DailyBrief.badge_count(), 0, "routine rows don't badge")
		GameState.state["home"]["pendingRaid"] = true
		assert_eq(DailyBrief.badge_count(), 1)
	)

	run_case("summary_reports_date_blocks_left_and_tier_counts", func():
		GameState.reset()
		Fixtures.seed_vein("eligible", 95)
		GameState.state["home"]["pendingRaid"] = true
		var summary := DailyBrief.summary()
		assert_eq(summary["dateLabel"], Calendar.widget_date(int(GameState.state["world"]["day"])), "same date helper as the phone widget")
		assert_eq(summary["blocksLeft"], TimeSystem.BLOCKS_PER_DAY)
		assert_eq(summary["counts"], { "urgent": 1, "story": 0, "opportunity": 0, "routine": 1 })
		GameState.state["world"]["timeBlocksDone"].append(0)
		assert_eq(DailyBrief.summary()["blocksLeft"], TimeSystem.BLOCKS_PER_DAY - 1)
	)

	run_case("works_before_the_business_pot_opens", func():
		GameState.reset()
		assert_true(not Business.is_pot_active())
		GameState.state["home"]["pendingRaid"] = true
		assert_eq(DailyBrief.items().size(), 1)
	)


func _kind(kind: String) -> Array:
	return DailyBrief.items().filter(func(r: Dictionary): return r["kind"] == kind)


# A guarded vein's Monday bill with no cash: a pending shortfall.
func _seed_guard_shortfall() -> void:
	GameState.reset()
	var vein := Fixtures.seed_vein("guarded", 50)
	vein["security"] = "guarded"
	GameState.state["world"]["day"] = Calendar.monday_on_or_after(8)
	GameState.state["player"]["cash"] = 0
	GuardUpkeep.pay_monday_bill()


# Every source this ticket projects: alarm, guard shortfall, wage prompt and
# a development-eligible vein.
func _seed_every_source() -> void:
	_seed_guard_shortfall()
	Fixtures.seed_vein("eligible", 95)
	GameState.state["home"]["pendingRaid"] = true
	Business.activate()
	var wage: Dictionary = GameState.state["business"]["wages"]["owen"]
	wage["owed"] = 120
	wage["promptPending"] = true

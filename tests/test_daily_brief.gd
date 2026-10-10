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

	run_case("low_sliding_veins_get_a_nights_estimate_from_the_drift_rule", func():
		GameState.reset()
		var vein := Fixtures.seed_vein("sliding", 14)
		var vg: Dictionary = GameData.VEIN_GROWTH
		var step: int = int(vein.get("level", 1)) + int((vg["driftRandomMin"] + vg["driftRandomMax"]) / 2.0)
		var nights := int(ceil(14.0 / step))
		var rows := _kind("veinAtRisk")
		assert_eq(rows.size(), 1)
		assert_eq(nights, Cultivating.days_to_wall(vein), "agrees with the expected-drift rule")
		var expected_tier := "urgent" if nights <= int(GameData.DAILY_BRIEF["veinCollapseNights"]) else "routine"
		assert_eq([rows[0]["tier"], rows[0]["key"], rows[0]["action"], rows[0]["sort"]], [expected_tier, "vein_collapse:sliding", { "to": "map_vein", "veinId": "sliding" }, nights])
		assert_true(String(rows[0]["consequence"]).find("~%d nights" % nights) != -1, "phrased as an estimate")
		assert_eq(rows[0]["actionLabel"], "Cultivate")
		vein["level"] = 3  # faster drift, fewer nights
		assert_true(int(_kind("veinAtRisk")[0]["sort"]) < nights, "level-driven drift shortens the estimate")
	)

	run_case("vein_at_risk_is_urgent_at_the_threshold_and_routine_above_it", func():
		GameState.reset()
		var threshold: int = GameData.DAILY_BRIEF["veinCollapseNights"]
		var near := Fixtures.seed_vein("near", 8)
		var far := Fixtures.seed_vein("far", 14)
		assert_eq(Cultivating.days_to_wall(near), threshold)
		assert_true(Cultivating.days_to_wall(far) > threshold)
		var tiers := {}
		for row in _kind("veinAtRisk"):
			tiers[row["key"]] = row["tier"]
		assert_eq(tiers, { "vein_collapse:near": "urgent", "vein_collapse:far": "routine" })
	)

	run_case("vein_at_risk_ignores_healthy_and_mid_band_veins_and_drops_off_once_lifted", func():
		GameState.reset()
		Fixtures.seed_vein("healthy", 70)
		Fixtures.seed_vein("thinning", 40)
		var sliding := Fixtures.seed_vein("sliding", 8)
		assert_eq(_kind("veinAtRisk").size(), 1)
		sliding["growth"] = 40
		assert_eq(_kind("veinAtRisk"), [], "out of the risk band: gone")
	)

	run_case("bill_row_only_inside_the_window_and_when_cash_is_short", func():
		GameState.reset()
		var window: int = GameData.DAILY_BRIEF["billWindowDays"]
		var bill := Home.weekly_bill_due()
		GameState.state["player"]["cash"] = bill - 270
		GameState.state["world"]["day"] = 8 - window - 1  # day 8 is the next Monday
		assert_eq(_kind("bill"), [], "outside the window")
		GameState.state["world"]["day"] = 8 - window
		var rows := _kind("bill")
		assert_eq(rows.size(), 1)
		assert_eq(Home.next_bill_day(), 8, "Home's due day")
		assert_eq([rows[0]["tier"], rows[0]["key"], rows[0]["action"], rows[0]["sort"]], ["urgent", "bill", { "to": "bank" }, window])
		assert_true(String(rows[0]["consequence"]).find("Short £270 for Monday") != -1, "shortfall against Home.weekly_bill_due()")
		assert_true(String(rows[0]["label"]).find("Rent") != -1, "rented: rent")
		GameState.state["player"]["cash"] = bill
		assert_eq(_kind("bill"), [], "cash covers the bill: drops off")
	)

	run_case("bill_shortfall_matches_what_the_monday_rollover_charges", func():
		GameState.reset()
		GameState.state["barometer"]["economic"] = "inflation"
		GameState.state["home"]["tier"] = GameData.HOME_TIER_ORDER[1]
		GameState.state["home"]["tenure"] = Home.TENURE_OWNED
		GameState.state["world"]["day"] = 7
		GameState.state["player"]["cash"] = 10
		var rows := _kind("bill")
		assert_true(String(rows[0]["label"]).find("Bills") != -1, "owned: utilities")
		var shortfall: int = Home.weekly_bill_due() - 10
		assert_true(Home.weekly_bill_due() > Home.weekly_bill_base(), "inflation scales the bill")
		assert_true(String(rows[0]["consequence"]).find("Short £%d" % shortfall) != -1)
		GameState.state["world"]["day"] = 8
		TimeSystem._apply_living_costs()
		assert_eq(GameState.state["home"]["arrears"], shortfall, "the rollover's shortfall is the row's")
	)

	run_case("arrears_row_shows_the_home_countdown_until_cleared", func():
		GameState.reset()
		GameState.state["world"]["day"] = 3
		GameState.state["player"]["cash"] = 1000000
		GameState.state["home"]["tier"] = GameData.HOME_TIER_ORDER[1]
		GameState.state["home"]["arrears"] = 400
		GameState.state["home"]["arrearsWeeks"] = 1
		var rows := _kind("arrears")
		assert_eq(rows.size(), 1)
		var countdown := Home.arrears_countdown()
		assert_eq([rows[0]["tier"], rows[0]["action"], rows[0]["sort"]], ["urgent", { "to": "property" }, mini(countdown["interestInDays"], countdown["downgradeInDays"])])
		assert_true(String(rows[0]["label"]).find("£400") != -1)
		assert_eq(rows[0]["consequence"], " ".join(MorningAccounts.countdown_lines(countdown)), "countdown text from arrears_countdown")
		GameState.state["home"]["arrears"] = 0
		assert_eq(_kind("arrears"), [], "cleared arrears drop off")
	)

	run_case("short_contract_period_is_an_urgent_row_naming_buyer_and_shortfall_until_stock_covers_it", func():
		GameState.reset()
		var contract := _accept_contract({ "kind": "ore", "type": "physics", "qty": 5 })
		var rows := _kind("contractAtRisk")
		assert_eq(rows.size(), 1)
		var buyer: String = GameData.FACTIONS[contract["counterparty"]]["shortName"]
		assert_eq([rows[0]["tier"], rows[0]["key"], rows[0]["action"]], ["urgent", "contract:%s" % contract["id"], { "to": "bizbrief_sales", "contractId": contract["id"] }])
		assert_eq(rows[0]["sort"], int(contract["dueDay"]) - int(GameState.state["world"]["day"]))
		assert_true(String(rows[0]["label"]).find(buyer) != -1 and String(rows[0]["label"]).find("short by 5") != -1, "buyer and shortfall")
		GameState.state["player"]["orichalchum"]["physics"] = 3
		assert_true(String(_kind("contractAtRisk")[0]["label"]).find("short by 2") != -1, "stock trims the shortfall")
		GameState.state["player"]["orichalchum"]["physics"] = 5
		assert_eq(_kind("contractAtRisk"), [], "stock covers the period: drops off")
	)

	run_case("filled_cancelled_and_delivered_periods_never_show", func():
		GameState.reset()
		var filled := _accept_contract({ "kind": "ore", "type": "physics", "qty": 5 })
		filled["periodFilled"] = true
		assert_eq(_kind("contractAtRisk"), [], "filled and locked")
		filled["periodFilled"] = false
		filled["delivered"] = { "physics": 5 }
		assert_eq(_kind("contractAtRisk"), [], "nothing remaining")
		filled["delivered"] = {}
		assert_eq(_kind("contractAtRisk").size(), 1)
		Contracts.cancel(filled["id"])
		assert_eq(_kind("contractAtRisk"), [], "cancelled")
	)

	run_case("contracts_earlier_in_priority_claim_shared_stock_first", func():
		GameState.reset()
		var first := _accept_contract({ "kind": "ore", "type": "physics", "qty": 4 })
		var second := _accept_contract({ "kind": "ore", "type": "physics", "qty": 4 })
		GameState.state["player"]["orichalchum"]["physics"] = 4
		var rows := _kind("contractAtRisk")
		assert_eq(rows.map(func(r): return r["key"]), ["contract:%s" % second["id"]], "the stock covers only %s" % first["id"])
	)

	run_case("reserved_production_counts_only_when_covered_staffed_and_affordable", func():
		GameState.reset()
		var contacts: Dictionary = GameState.state["contacts"]
		contacts["james"]["recruited"] = true
		contacts["james"]["craftingSkill"] = 5
		contacts["james"]["assignedRole"] = "production"
		_accept_contract({ "kind": "consumable", "type": "timePearl", "qty": 2 })
		var per_unit: int = Crafting.calc_cost("timePearl", 5)["time"]
		GameState.state["player"]["orichalchum"]["time"] = 2 * per_unit
		assert_eq(_kind("contractAtRisk").size(), 1, "lab not covering contracts: calc alone is no cover")
		GameState.state["labCoverContracts"]["timePearl"] = true
		assert_eq(_kind("contractAtRisk"), [], "covered, staffed, calc on hand")
		GameState.state["player"]["orichalchum"]["time"] = per_unit
		assert_true(String(_kind("contractAtRisk")[0]["label"]).find("short by 1") != -1, "calc for one unit")
		contacts["james"]["assignedRole"] = null
		GameState.state["player"]["orichalchum"]["time"] = 2 * per_unit
		assert_eq(_kind("contractAtRisk").size(), 1, "no working producer")
	)

	run_case("unread_messages_are_not_rows", func():
		GameState.reset()
		_quiet_story()
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
		_quiet_story()
		Fixtures.seed_vein("eligible", 95)
		assert_eq(DailyBrief.badge_count(), 0, "routine rows don't badge")
		GameState.state["home"]["pendingRaid"] = true
		assert_eq(DailyBrief.badge_count(), 1)
		GameState.state["objectives"]["tut_meet_archie"]["active"] = true
		assert_eq(DailyBrief.badge_count(), 2, "the Story row badges too")
	)

	run_case("summary_reports_date_blocks_left_and_tier_counts", func():
		GameState.reset()
		_quiet_story()
		Fixtures.seed_vein("eligible", 95)
		GameState.state["home"]["pendingRaid"] = true
		var summary := DailyBrief.summary()
		assert_eq(summary["dateLabel"], Calendar.widget_date(int(GameState.state["world"]["day"])), "same date helper as the phone widget")
		assert_eq(summary["blocksLeft"], TimeSystem.BLOCKS_PER_DAY)
		assert_eq(summary["counts"], { "urgent": 1, "story": 0, "opportunity": 0, "routine": 1 })
		GameState.state["world"]["timeBlocksDone"].append(0)
		assert_eq(DailyBrief.summary()["blocksLeft"], TimeSystem.BLOCKS_PER_DAY - 1)
	)

	run_case("story_row_wording_equals_todos_current_objective", func():
		GameState.reset()
		var rows := _kind("story")
		assert_eq(rows.size(), 1)
		var item := Todo.current_objective()
		assert_eq(rows[0]["label"], Todo.item_text(item))
		assert_eq(rows[0]["label"], "Get back to Archie. He's sorting the new buyer.")
		assert_eq([rows[0]["tier"], rows[0]["key"]], ["story", "story:tut_meet_archie"])
		assert_eq(DailyBrief.summary()["counts"]["story"], 1)
	)

	run_case("story_row_action_comes_from_the_objective_data_with_todo_fallback", func():
		GameState.reset()
		var row: Dictionary = _kind("story")[0]
		assert_eq([row["action"], row["actionLabel"]], [{ "to": "thread", "contactId": "archie" }, "Messages"])
		# An objective with no briefAction falls back to ToDo.
		_quiet_story()
		GameState.state["objectives"]["tut_home_raid"]["active"] = true
		row = _kind("story")[0]
		assert_eq([row["action"], row["actionLabel"]], [{ "to": "todo" }, "ToDo"])
		_quiet_story()
		GameState.state["objectives"]["col_a1_des_sites"]["active"] = true
		assert_eq(_kind("story")[0]["action"], { "to": "map" })
	)

	run_case("waiting_tutorial_objective_points_at_rest_until_the_text_arrives", func():
		GameState.reset()
		_quiet_story()
		GameState.state["objectives"]["tut_buyer_event"]["active"] = true
		GameState.state["world"]["day"] = 1
		var row: Dictionary = _kind("story")[0]
		assert_eq([row["action"], row["actionLabel"]], [{ "to": "rest" }, "Rest"])
		assert_eq(row["consequence"], "Rest at HQ to wait for Archie's text.")
		assert_eq(row["label"], "Wait for Archie's text — he's lining up the buyer.")
		GameState.state["world"]["day"] = 2
		row = _kind("story")[0]
		assert_eq(row["action"], { "to": "thread", "contactId": "archie" })
		assert_eq(row["consequence"], "")
	)

	run_case("todo_nothing_pressing_agrees_with_no_story_row", func():
		GameState.reset()
		assert_true(not Todo.current_objective().is_empty())
		assert_eq(_kind("story").size(), 1)
		_quiet_story()
		assert_true(Todo.current_objective().is_empty())
		assert_eq(_kind("story").size(), 0)
		# A finished objective is not pressing either.
		GameState.state["objectives"]["tut_meet_archie"]["active"] = true
		GameState.state["objectives"]["tut_meet_archie"]["complete"] = true
		assert_true(Todo.current_objective().is_empty())
		assert_eq(_kind("story").size(), 0)
	)

	run_case("offer_row_only_inside_the_expiry_window_and_drops_off_when_taken", func():
		GameState.reset()
		_quiet_story()
		var offer: Dictionary = _pending_offer()
		var today: int = GameState.state["world"]["day"]
		offer["expiresDay"] = today + 2
		assert_eq(_kind("offerExpiring"), [], "two days out: outside the 1-day window")
		offer["expiresDay"] = today + 1
		var rows := _kind("offerExpiring")
		assert_eq(rows.size(), 1)
		assert_eq([rows[0]["tier"], rows[0]["key"], rows[0]["action"], rows[0]["sort"]], ["opportunity", "offer:%s" % offer["id"], { "to": "bizbrief_offer", "offerId": offer["id"] }, 1])
		assert_true(String(rows[0]["label"]).find("£%d" % int(offer["quote"]["payment"])) != -1, "names the payment")
		Offers.decline_offer(offer["id"])
		assert_eq(_kind("offerExpiring"), [], "a declined offer drops off")
		offer = _pending_offer()
		offer["expiresDay"] = today
		assert_eq(_kind("offerExpiring"), [], "a lapsed offer drops off")
	)

	run_case("demand_row_only_for_held_goods_at_or_above_the_threshold", func():
		GameState.reset()
		_quiet_story()
		GameState.state["flags"]["canSellConsumables"] = true
		GameState.state["barometer"]["social"] = "festival"
		var fraction := Barometer.get_item_demand_mult("blast") - 1.0
		assert_true(fraction >= float(GameData.DAILY_BRIEF["demandThreshold"]), "festival lifts blast past the default threshold")
		assert_eq(_kind("demandSpike"), [], "not held: no row")
		Crafting.inventory_add("blast", 1, 3)
		var rows := _kind("demandSpike")
		assert_eq(rows.size(), 1)
		assert_eq([rows[0]["tier"], rows[0]["key"], rows[0]["action"], rows[0]["actionLabel"]], ["opportunity", "demand:blast", { "to": "trade" }, "Sell"])
		assert_true(String(rows[0]["label"]).find("%d%%" % roundi(fraction * 100.0)) != -1, "names the lift")
		var default_threshold: float = GameData.DAILY_BRIEF["demandThreshold"]
		GameData.DAILY_BRIEF["demandThreshold"] = fraction
		var at_boundary := _kind("demandSpike").size()
		GameData.DAILY_BRIEF["demandThreshold"] = fraction + 0.01
		var above_boundary := _kind("demandSpike").size()
		GameData.DAILY_BRIEF["demandThreshold"] = default_threshold
		assert_eq([at_boundary, above_boundary], [1, 0], "a lift exactly at the threshold counts; just under it doesn't")
		Crafting.inventory_remove("blast", 3)
		assert_eq(_kind("demandSpike"), [], "sold out: drops off")
		Crafting.inventory_add("blast", 1, 3)
		GameState.state["barometer"]["social"] = _neutral_social_state()
		assert_eq(_kind("demandSpike"), [], "demand falls: drops off")
	)

	run_case("favour_row_per_open_request_until_answered", func():
		GameState.reset()
		_quiet_story()
		var faction_id: String = GameData.FACTIONS.keys()[0]
		var contact_id := KeyMembers.speaker_for(faction_id)
		var day: int = GameState.state["world"]["day"]
		Messages.queue_pending(contact_id, Diplomacy.FAVOUR_KIND, "A favour.", { "factionId": faction_id, "favourId": "f1", "expiresDay": day + 2 })
		var rows := _kind("favour")
		assert_eq(rows.size(), 1)
		assert_eq([rows[0]["tier"], rows[0]["action"], rows[0]["sort"]], ["opportunity", { "to": "thread", "contactId": contact_id }, 2])
		Diplomacy.decline(GameState.state["pendingMessages"][0]["id"])
		assert_eq(_kind("favour"), [], "an answered favour drops off")
	)

	run_case("opportunity_rows_never_badge", func():
		GameState.reset()
		_quiet_story()
		_pending_offer()["expiresDay"] = int(GameState.state["world"]["day"]) + 1
		var faction_id: String = GameData.FACTIONS.keys()[0]
		Messages.queue_pending(KeyMembers.speaker_for(faction_id), Diplomacy.FAVOUR_KIND, "A favour.", { "factionId": faction_id, "favourId": "f1", "expiresDay": 99 })
		assert_eq(DailyBrief.summary()["counts"]["opportunity"], 2)
		assert_eq(DailyBrief.badge_count(), 0)
	)

	run_case("works_before_the_business_pot_opens", func():
		GameState.reset()
		assert_true(not Business.is_pot_active())
		_quiet_story()
		GameState.state["home"]["pendingRaid"] = true
		assert_eq(DailyBrief.items().size(), 1)
	)


var _next_offer := 0


func _accept_contract(request: Dictionary) -> Dictionary:
	_next_offer += 1
	var created: Dictionary = Offers.create_offer({
		"id": "t_brief_%d" % _next_offer, "source": "scripted", "contractType": "recurring", "weekday": 1,
		"request": request,
	})
	return Offers.accept_offer(created["offer"]["id"])["contract"]


func _pending_offer() -> Dictionary:
	_next_offer += 1
	return Offers.create_offer({
		"id": "t_brief_offer_%d" % _next_offer, "source": "scripted", "contractType": "oneOff",
		"request": { "kind": "ore", "type": "life", "qty": 10 },
	})["offer"]


# A social Ticker state with no item-demand effect.
func _neutral_social_state() -> String:
	for state_id in GameData.BAROMETER_STATES["social"]:
		if not GameData.BAROMETER_STATES["social"][state_id]["effects"].has("itemDemand"):
			return state_id
	return ""


func _kind(kind: String) -> Array:
	return DailyBrief.items().filter(func(r: Dictionary): return r["kind"] == kind)


# Deactivates every objective so ToDo has nothing pressing (no Story row).
func _quiet_story() -> void:
	for id in GameState.state["objectives"]:
		GameState.state["objectives"][id]["active"] = false


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

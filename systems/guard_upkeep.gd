class_name GuardUpkeep
extends RefCounted

# Guard wages (R§1.6 "Guard upkeep"): the prorated hire advance, the weekly
# guard cost shown on security rows, and the per-day, per-place guard cost
# history (state.guardUpkeep.history). Static funcs only.

# Place id for HQ guards in expenses and history; veins use their vein id.
const HOME_PLACE_ID := "home"
# Place id for a faction's stockpile guards in its Monday bill's walked list.
const STOCKPILE_PLACE_ID := "stockpile"
# Place id for training spend in the cost history (not a post).
const TRAINING_PLACE_ID := "training"
const HIRE_BANK_LABEL := "Guard hire"
const WAGES_BANK_LABEL := "Guard wages"
const RESERVE_BANK_LABEL := "Guard wage reserve"


static func weekly_wage() -> int:
	return int(GameData.GUARD_UPKEEP["weeklyWage"])


# guard_count × weeklyWage.
static func weekly_cost(guard_count: int) -> int:
	return guard_count * weekly_wage()


# Days from `day` through Sunday inclusive: 7 on a Monday, 1 on a Sunday.
static func days_left_in_week(day: int) -> int:
	return Calendar.days_per_week() - Calendar.weekday_index(day)


# What hiring one guard costs today: this week's remaining wage, prorated
# like staff wages (spec §Hiring).
static func hire_advance() -> int:
	return Business.prorated_wage(weekly_wage(), days_left_in_week(GameState.state["world"]["day"]))


# "£357 today, then £500/week" for a guard hire button.
static func hire_cost_text() -> String:
	return "£%d today, then £%d/week" % [hire_advance(), weekly_wage()]


# "£1000/week" for a security row, or "" with no guards.
static func weekly_cost_text(guard_count: int) -> String:
	if guard_count <= 0:
		return ""
	return "£%d/week" % weekly_cost(guard_count)


# The prorated advance for hiring muscle guard `g`: this week's remaining
# share of that guard's own wage.
static func guard_hire_advance(g: Dictionary) -> int:
	return Business.prorated_wage(Muscle.wage(g), days_left_in_week(GameState.state["world"]["day"]))


# Takes today's advance from player cash for one guard at place_id (a vein
# id, HOME_PLACE_ID or Muscle.POST_RESERVE). `weekly` is the hired guard's own
# wage, or -1 for the flat legacy wage. Refused, with nothing changed, when
# cash is short. The caller adds the guard itself.
static func pay_hire_advance(place_id: String, weekly: int = -1) -> Dictionary:
	var advance := hire_advance() if weekly < 0 else Business.prorated_wage(weekly, days_left_in_week(GameState.state["world"]["day"]))
	var player: Dictionary = GameState.state["player"]
	if int(player["cash"]) < advance:
		return { "ok": false, "reason": "Not enough cash." }
	player["cash"] -= advance
	Bank.record(-advance, HIRE_BANK_LABEL)
	record_payment(place_id, advance)
	FactionAI.note_spend(Shares.PLAYER, float(advance))
	return { "ok": true, "amount": advance }


# Ids of every hired guard, injured and Reserve included: the guards a short
# Monday bill puts at risk.
static func hired_guard_ids() -> Array:
	return Muscle.guards().map(func(g): return g["id"])


# Hired muscle's weekly wages by post (HOME_PLACE_ID, a vein id or
# Muscle.POST_RESERVE): { post: £ }, Reserve guards included.
static func muscle_wages_by_place() -> Dictionary:
	var wages := {}
	for g in Muscle.guards():
		wages[g["post"]] = int(wages.get(g["post"], 0)) + Muscle.wage(g)
	return wages


static func muscle_wage_total() -> int:
	var total := 0
	for amount in muscle_wages_by_place().values():
		total += int(amount)
	return total


# Player Monday bill before the pot exists (spec §Player Monday bill, R§3.1
# ⑥.4a): on the rollover into a Monday, weeklyWage per guard on duty, from
# cash in full or not at all (bank "Guard wages"). Short cash takes nothing
# and returns short = true. Any other day, or with the pot active, bills
# nothing. Returns { billed, short, due, paid, guards }.
#
# PROSE-REVIEW: the paid notification.
static func pay_monday_bill() -> Dictionary:
	var result := { "billed": false, "short": false, "due": 0, "paid": 0, "guards": 0 }
	if not Calendar.is_monday(GameState.state["world"]["day"]) or Business.is_pot_active():
		return result
	result["guards"] = Muscle.guards().size()
	if result["guards"] == 0:
		return result
	result["billed"] = true
	result["due"] = muscle_wage_total()
	var player: Dictionary = GameState.state["player"]
	if int(player["cash"]) < result["due"]:
		result["short"] = true
		start_shortfall(hired_guard_ids(), 0, result["due"])
		return result
	player["cash"] -= result["due"]
	Bank.record(-result["due"], WAGES_BANK_LABEL)
	var muscle_wages := muscle_wages_by_place()
	for place_id in muscle_wages:
		record_payment(place_id, int(muscle_wages[place_id]))
	result["paid"] = result["due"]
	Notify.push("Guard wages: -£%d for %d guard%s this week." % [result["paid"], result["guards"], "" if result["guards"] == 1 else "s"])
	EventBus.mark_changed()
	return result


# "HQ" for HOME_PLACE_ID, else the vein's "District — Ore", or "a lost vein"
# once it's gone.
static func place_label(place_id: String) -> String:
	if place_id == HOME_PLACE_ID:
		return "HQ"
	if place_id == Muscle.POST_RESERVE:
		return "Reserve"
	if place_id == TRAINING_PLACE_ID:
		return "Training"
	var vein: Variant = Cultivating.find_vein(place_id)
	if vein == null:
		return "a lost vein"
	return "%s — %s" % [GameData.DISTRICTS[vein["district"]]["name"], GameData.ORE_TYPES[vein["oreType"]]["name"]]


# A player guard payment: a guard expense in BusinessStats and today's
# history entry for place_id.
static func record_payment(place_id: String, amount: int) -> void:
	if amount <= 0:
		return
	BusinessStats.record_expense(amount, BusinessStats.EXPENSE_GUARD)
	record_history(place_id, amount)


# Adds amount to today's cost history entry for place_id (a post or
# TRAINING_PLACE_ID) without recording an expense.
static func record_history(place_id: String, amount: int) -> void:
	if amount <= 0:
		return
	var day: int = GameState.state["world"]["day"]
	var history: Array = GameState.state["guardUpkeep"]["history"]
	if history.is_empty() or int(history[-1]["day"]) != day:
		history.append({ "day": day, "places": {} })
	var places: Dictionary = history[-1]["places"]
	places[place_id] = int(places.get(place_id, 0)) + amount
	var oldest_kept: int = day - int(GameData.GUARD_UPKEEP["guardCostHistoryDays"]) + 1
	while not history.is_empty() and int(history[0]["day"]) < oldest_kept:
		history.remove_at(0)


# ── Guard Costs screen (spec §Visibility) ──

# Days the guard cost history covers, oldest first: the last
# guardCostHistoryDays days through today, never before day 1.
static func history_window_days() -> Array[int]:
	var today: int = GameState.state["world"]["day"]
	var days: Array[int] = []
	for day in range(maxi(1, today - int(GameData.GUARD_UPKEEP["guardCostHistoryDays"]) + 1), today + 1):
		days.append(day)
	return days


# One place's guard payments per window day, 0 where none.
static func cost_series(place_id: String) -> Array[int]:
	var by_day := {}
	for entry in GameState.state["guardUpkeep"]["history"]:
		by_day[int(entry["day"])] = int(entry["places"].get(place_id, 0))
	var values: Array[int] = []
	for day in history_window_days():
		values.append(int(by_day.get(day, 0)))
	return values


# Rows the Costs tab offers: HQ, player veins in list order, Reserve, training,
# then any other place (a vein the player has lost) with history in the window.
static func cost_places() -> Array[String]:
	var places: Array[String] = [HOME_PLACE_ID]
	for vein in GameState.state["player"]["veins"]:
		places.append(vein["id"])
	places.append(Muscle.POST_RESERVE)
	places.append(TRAINING_PLACE_ID)
	var oldest: int = history_window_days()[0]
	for entry in GameState.state["guardUpkeep"]["history"]:
		if int(entry["day"]) < oldest:
			continue
		for place_id in entry["places"]:
			if not places.has(place_id):
				places.append(place_id)
	return places


# Next Monday's player guard bill: each hired guard's own wage.
static func next_monday_bill() -> int:
	return muscle_wage_total()


# Spend since this week's Monday, from the cost history: { wages, training }.
# wages covers every place but training (hire advances included).
static func week_spend() -> Dictionary:
	var today: int = GameState.state["world"]["day"]
	var first_day := today - Calendar.weekday_index(today)
	var spend := { "wages": 0, "training": 0 }
	for entry in GameState.state["guardUpkeep"]["history"]:
		if int(entry["day"]) < first_day:
			continue
		for place_id in entry["places"]:
			var key := "training" if place_id == TRAINING_PLACE_ID else "wages"
			spend[key] += int(entry["places"][place_id])
	return spend


# One place's spend since this week's Monday, for the Costs tab rows.
static func place_week_spend(place_id: String) -> int:
	var today: int = GameState.state["world"]["day"]
	var first_day := today - Calendar.weekday_index(today)
	var total := 0
	for entry in GameState.state["guardUpkeep"]["history"]:
		if int(entry["day"]) >= first_day:
			total += int(entry["places"].get(place_id, 0))
	return total


# ── short-pay flow (spec §Short-pay flow) ──

# The pending guard shortfall record, or null.
static func pending_shortfall() -> Variant:
	return GameState.state["guardUpkeep"].get("pendingShortfall")


# Whether `notification` is the warning for the shortfall still pending.
static func is_pending_shortfall_notification(notification: Dictionary) -> bool:
	var shortfall: Variant = pending_shortfall()
	return shortfall != null and notification.get(Notify.META_GUARD_SHORTFALL) == true and int(notification["day"]) == int(shortfall["day"])


# Records the one pending shortfall for today's short Monday bill: guards is
# the ids of the guards at risk, reserve the £ set aside from pot and float
# (0 before the pot). The deadline is graceDays rollovers ahead; until then
# every guard stays on duty. A shortfall still pending is auto-resolved
# first, so there is never more than one.
#
# PROSE-REVIEW: the shortfall warning notification.
static func start_shortfall(guards: Array, reserve: int, due: int) -> void:
	if pending_shortfall() != null:
		_auto_resolve(pending_shortfall())
	var day: int = GameState.state["world"]["day"]
	var shortfall := {
		"day": day,
		"deadline": day + int(GameData.GUARD_UPKEEP["graceDays"]),
		"guards": guards.duplicate(),
		"reserve": reserve,
	}
	GameState.state["guardUpkeep"]["pendingShortfall"] = shortfall
	var places := shortfall_places(guards)
	var walk_text := "Unpaid guards walk on %s — %s." % [Calendar.format_day(shortfall["deadline"]), places_text(places)]
	if places.is_empty():
		walk_text = "Pay by %s." % Calendar.format_day(shortfall["deadline"])
	Notify.push("Guard wages short: £%d due. %s" % [due, walk_text], Notify.CATEGORY_WARNING, { Notify.META_GUARD_SHORTFALL: true })
	EventBus.mark_changed()


# Rollover step (R§3.1 ①b): once the grace deadline is reached, the pending
# shortfall resolves on its own. Returns _auto_resolve()'s result, or {}
# when nothing was due.
static func resolve_due_shortfall() -> Dictionary:
	var shortfall: Variant = pending_shortfall()
	if shortfall == null or int(GameState.state["world"]["day"]) < int(shortfall["deadline"]):
		return {}
	return _auto_resolve(shortfall)


# Drops guards in drop order until the rest are covered by the funds (the
# reserve with the pot active, else player cash); the kept are paid their own
# wage. Any leftover reserve goes to the float, or to cash before the pot.
# Clears the shortfall. Returns { paid, kept, walked: { place id: guards } }.
#
# PROSE-REVIEW: the walk-off notification.
static func _auto_resolve(shortfall: Dictionary) -> Dictionary:
	var order := drop_order(_guards_at_risk(shortfall["guards"]))
	var cost := 0
	for g in order:
		cost += Muscle.wage(g)
	var pot_era := Business.is_pot_active()
	var reserve: int = int(shortfall["reserve"])
	var player: Dictionary = GameState.state["player"]
	var funds: int = reserve if pot_era else int(player["cash"])
	var walked := {}
	while cost > funds and not order.is_empty():
		var g: Dictionary = order.pop_front()
		cost -= Muscle.wage(g)
		walked[g["post"]] = int(walked.get(g["post"], 0)) + 1
		Muscle.walk(g["id"])
	var kept := order.size()
	var paid := 0
	for g in order:
		record_payment(g["post"], Muscle.wage(g))
		paid += Muscle.wage(g)
	if pot_era:
		reserve -= paid
	elif paid > 0:
		player["cash"] -= paid
		Bank.record(-paid, WAGES_BANK_LABEL)
	_close_shortfall(reserve, paid, kept, walked)
	return { "paid": paid, "kept": kept, "walked": walked }


# Returns leftover reserve to the float (pot era) or cash, clears the
# shortfall and posts the paid and walk-off notifications.
static func _close_shortfall(leftover_reserve: int, paid: int, kept: int, walked: Dictionary) -> void:
	if leftover_reserve > 0:
		if Business.is_pot_active():
			GameState.state["business"]["float"] += leftover_reserve
		else:
			GameState.state["player"]["cash"] += leftover_reserve
			Bank.record(leftover_reserve, RESERVE_BANK_LABEL)
	GameState.state["guardUpkeep"]["pendingShortfall"] = null
	if paid > 0:
		Notify.push("Guard wages: -£%d for %d guard%s this week." % [paid, kept, "" if kept == 1 else "s"])
	if not walked.is_empty():
		GameState.state["guardUpkeep"]["lastWalkDay"] = int(GameState.state["world"]["day"])
		Notify.push("Unpaid guards walked off: %s." % walked_text(walked), Notify.CATEGORY_WARNING)
	EventBus.mark_changed()


# The short-pay checklist's rows: the pending shortfall's guards still hired
# and posted, in drop order (first to walk first). Empty with no shortfall.
static func short_pay_guards() -> Array:
	var shortfall: Variant = pending_shortfall()
	if shortfall == null:
		return []
	return drop_order(_guards_at_risk(shortfall["guards"]))


# What confirming `keep` (ids of the guards to keep) costs: { cost, reserve,
# cashNeeded }. Ids that aren't at risk are ignored.
static func short_pay_quote(keep: Array) -> Dictionary:
	var shortfall: Variant = pending_shortfall()
	var reserve := 0 if shortfall == null else int(shortfall["reserve"])
	var cost := 0
	for g in _kept_guards(keep):
		cost += Muscle.wage(g)
	return { "cost": cost, "reserve": reserve, "cashNeeded": maxi(cost - reserve, 0) }


# Short-pay confirm: exactly the ticked guards stay, each paid their own wage
# from the reserve first, then cash (bank "Guard wages"). Every other at-risk
# guard walks now, to the former list. Leftover reserve goes as on
# auto-resolve and the shortfall clears. Works without the Security Office.
# Refused, nothing changed, when cash can't cover the difference. Returns
# { ok, paid, walked: { place id: guards } } or { ok: false, reason }.
static func confirm_shortfall(keep: Array) -> Dictionary:
	if pending_shortfall() == null:
		return { "ok": false, "reason": "No guard wages are owed." }
	var quote := short_pay_quote(keep)
	var player: Dictionary = GameState.state["player"]
	if int(player["cash"]) < int(quote["cashNeeded"]):
		return { "ok": false, "reason": "Not enough cash." }
	var kept := _kept_guards(keep)
	var walked := {}
	for g in short_pay_guards():
		if kept.has(g):
			record_payment(g["post"], Muscle.wage(g))
		else:
			walked[g["post"]] = int(walked.get(g["post"], 0)) + 1
			Muscle.walk(g["id"])
	if int(quote["cashNeeded"]) > 0:
		player["cash"] -= int(quote["cashNeeded"])
		Bank.record(-int(quote["cashNeeded"]), WAGES_BANK_LABEL)
	var leftover := int(quote["reserve"]) - (int(quote["cost"]) - int(quote["cashNeeded"]))
	_close_shortfall(leftover, int(quote["cost"]), kept.size(), walked)
	return { "ok": true, "paid": quote["cost"], "walked": walked }


# The at-risk guards whose ids are in `keep`.
static func _kept_guards(keep: Array) -> Array:
	return short_pay_guards().filter(func(g): return keep.has(g["id"]))


# The recorded guards still hired and at a real post (a guard posted at a lost
# vein, or hired during grace, isn't at risk).
static func _guards_at_risk(ids: Array) -> Array:
	var at_risk := []
	for id in ids:
		var g := Muscle.guard(id)
		if not g.is_empty() and Muscle.is_post(g["post"]):
			at_risk.append(g)
	return at_risk


# Place ids of the recorded guards still at risk, for text: player veins in
# list order, then HQ, then Reserve.
static func shortfall_places(ids: Array) -> Array:
	var posts := {}
	for g in _guards_at_risk(ids):
		posts[g["post"]] = true
	var places := []
	for vein in GameState.state["player"]["veins"]:
		if posts.has(vein["id"]):
			places.append(vein["id"])
	for place_id in [HOME_PLACE_ID, Muscle.POST_RESERVE]:
		if posts.has(place_id):
			places.append(place_id)
	return places


# Walk-off order (spec §Short-pay flow): Reserve first (injured included),
# then posts on the least valuable vein first, then HQ; lowest level first
# within a place, ties by id. Returns a sorted copy of `guards`.
static func drop_order(guards: Array) -> Array:
	var veins: Array = GameState.state["player"]["veins"].duplicate()
	veins.sort_custom(Cultivating.value_order)
	veins.reverse()
	var rank := {}
	for i in veins.size():
		rank[veins[i]["id"]] = i
	var ordered := guards.duplicate()
	ordered.sort_custom(func(a, b):
		var key_a := _place_drop_rank(a["post"], rank)
		var key_b := _place_drop_rank(b["post"], rank)
		if key_a != key_b:
			return key_a < key_b
		if int(a["level"]) != int(b["level"]):
			return int(a["level"]) < int(b["level"])
		return str(a["id"]) < str(b["id"]))
	return ordered


# Sort key of a post in the drop order: Reserve, then veins (least valuable
# first), then HQ.
static func _place_drop_rank(post: String, vein_rank: Dictionary) -> int:
	if post == Muscle.POST_RESERVE:
		return 0
	if post == Muscle.POST_HOME:
		return 1 + vein_rank.size()
	return 1 + int(vein_rank.get(post, 0))


# ── faction guard hiring (spec §Faction guard upkeep, Hiring) ──

# What hiring one guard of `level` costs a faction today: this week's remaining
# share of that level's wage.
static func faction_hire_advance(level: int) -> int:
	return Business.prorated_wage(Muscle.level_wage(level), days_left_in_week(GameState.state["world"]["day"]))


# A faction hires a guard only when resources cover today's advance plus
# wageReserveWeeks of its weekly guard bill with that guard added.
static func faction_can_hire(faction_id: String, level: int = 1) -> bool:
	var reserve_weeks := int(GameData.GUARD_UPKEEP["faction"]["wageReserveWeeks"])
	var weekly := Muscle.counts_wage(Muscle.faction_all_counts(faction_id)) + Muscle.level_wage(level)
	var needed := faction_hire_advance(level) + reserve_weeks * weekly
	return int(GameState.state["factions"][faction_id]["resources"]) >= needed


# ── faction Monday bill (spec §Faction guard upkeep) ──

# R§3.1 ⑤h2: on the rollover into a Monday, each faction pays the level wage of
# every guard on its veins, stockpile and Reserve from resources, as many as it
# can cover. The rest walk now, lowest level first; within a level, vein posts
# (least valuable vein first), then the stockpile (walked key STOCKPILE_PLACE_ID),
# then the Reserve (walked key Muscle.POST_RESERVE). Resources never go negative.
# A vein claimed today isn't billed: its guards start on the next Monday.
# Returns { faction id: { due, paid, walked } } for billed factions.
static func pay_faction_monday_bills() -> Dictionary:
	var results := {}
	var day: int = GameState.state["world"]["day"]
	if not Calendar.is_monday(day):
		return results
	for faction_id in GameState.state["factions"]:
		var faction_state: Dictionary = GameState.state["factions"][faction_id]
		var places := []
		for vein in Muscle.faction_veins_low_to_high(faction_id):
			if int(vein.get("claimedOnDay", -1)) != day:
				places.append({ "id": vein["id"], "counts": Muscle.faction_guards_at(vein) })
		places.append({ "id": STOCKPILE_PLACE_ID, "counts": Muscle.faction_guards_at(faction_state["stockpile"]) })
		places.append({ "id": Muscle.POST_RESERVE, "counts": Muscle.faction_reserve(faction_id) })
		var due := 0
		for place in places:
			due += Muscle.counts_wage(place["counts"])
		if due == 0:
			continue
		var owed := due
		var walked := {}
		for level in range(1, GameData.MUSCLE["levels"].size() + 1):
			for place in places:
				while owed > int(faction_state["resources"]) and int(place["counts"][level - 1]) > 0:
					place["counts"][level - 1] = int(place["counts"][level - 1]) - 1
					owed -= Muscle.level_wage(level)
					walked[place["id"]] = int(walked.get(place["id"], 0)) + 1
		faction_state["resources"] -= owed
		results[faction_id] = { "due": due, "paid": owed, "walked": walked }
	return results


# "HQ, Soho — Time" for a list of place ids.
static func places_text(place_ids: Array) -> String:
	var labels := PackedStringArray()
	for place_id in place_ids:
		labels.append(place_label(place_id))
	return ", ".join(labels)


# "HQ (1), Soho — Time (2)" for { place id: guards }.
static func walked_text(walked: Dictionary) -> String:
	var labels := PackedStringArray()
	for place_id in walked:
		labels.append("%s (%d)" % [place_label(place_id), int(walked[place_id])])
	return ", ".join(labels)

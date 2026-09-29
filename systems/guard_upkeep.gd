class_name GuardUpkeep
extends RefCounted

# Guard wages (R§1.6 "Guard upkeep"): the prorated hire advance, the weekly
# guard cost shown on security rows, and the per-day, per-place guard cost
# history (state.guardUpkeep.history). Static funcs only.

# Place id for HQ guards in expenses and history; veins use their vein id.
const HOME_PLACE_ID := "home"
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


# Takes today's advance from player cash for one guard at place_id (a vein
# id or HOME_PLACE_ID). Refused, with nothing changed, when cash is short.
# The caller adds the guard itself.
static func pay_hire_advance(place_id: String) -> Dictionary:
	var advance := hire_advance()
	var player: Dictionary = GameState.state["player"]
	if int(player["cash"]) < advance:
		return { "ok": false, "reason": "Not enough cash." }
	player["cash"] -= advance
	Bank.record(-advance, HIRE_BANK_LABEL)
	record_payment(place_id, advance)
	return { "ok": true, "amount": advance }


# Guards on duty per place: { vein id or HOME_PLACE_ID: count }, player
# veins in list order then HQ, places with no guards left out. Only veins in
# player.veins count, so guards on a sold or lost vein aren't billed.
static func player_guards_by_place() -> Dictionary:
	var places := {}
	for vein in GameState.state["player"]["veins"]:
		var count := Cultivating.vein_guard_count(vein)
		if count > 0:
			places[vein["id"]] = count
	var hq_count := Home.get_guard_count()
	if hq_count > 0:
		places[HOME_PLACE_ID] = hq_count
	return places


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
	var places := player_guards_by_place()
	for place_id in places:
		result["guards"] += int(places[place_id])
	if result["guards"] == 0:
		return result
	result["billed"] = true
	result["due"] = weekly_cost(result["guards"])
	var player: Dictionary = GameState.state["player"]
	if int(player["cash"]) < result["due"]:
		result["short"] = true
		start_shortfall(places, 0, result["due"])
		return result
	player["cash"] -= result["due"]
	Bank.record(-result["due"], WAGES_BANK_LABEL)
	for place_id in places:
		record_payment(place_id, weekly_cost(int(places[place_id])))
	result["paid"] = result["due"]
	Notify.push("Guard wages: -£%d for %d guard%s this week." % [result["paid"], result["guards"], "" if result["guards"] == 1 else "s"])
	EventBus.state_changed.emit()
	return result


# "HQ" for HOME_PLACE_ID, else the vein's "District — Ore", or "a lost vein"
# once it's gone.
static func place_label(place_id: String) -> String:
	if place_id == HOME_PLACE_ID:
		return "HQ"
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
	var day: int = GameState.state["world"]["day"]
	var history: Array = GameState.state["guardUpkeep"]["history"]
	if history.is_empty() or int(history[-1]["day"]) != day:
		history.append({ "day": day, "places": {} })
	var places: Dictionary = history[-1]["places"]
	places[place_id] = int(places.get(place_id, 0)) + amount
	var oldest_kept: int = day - int(GameData.GUARD_UPKEEP["guardCostHistoryDays"]) + 1
	while not history.is_empty() and int(history[0]["day"]) < oldest_kept:
		history.remove_at(0)


# ── short-pay flow (spec §Short-pay flow) ──

# The pending guard shortfall record, or null.
static func pending_shortfall() -> Variant:
	return GameState.state["guardUpkeep"].get("pendingShortfall")


# Whether `notification` is the warning for the shortfall still pending.
static func is_pending_shortfall_notification(notification: Dictionary) -> bool:
	var shortfall: Variant = pending_shortfall()
	return shortfall != null and notification.get(Notify.META_GUARD_SHORTFALL) == true and int(notification["day"]) == int(shortfall["day"])


# Records the one pending shortfall for today's short Monday bill: places is
# { vein id or HOME_PLACE_ID: guards }, reserve the £ set aside from pot and
# float (0 before the pot). The deadline is graceDays rollovers ahead; until
# then every guard stays on duty. A shortfall still pending is auto-resolved
# first, so there is never more than one.
#
# PROSE-REVIEW: the shortfall warning notification.
static func start_shortfall(places: Dictionary, reserve: int, due: int) -> void:
	if pending_shortfall() != null:
		_auto_resolve(pending_shortfall())
	var day: int = GameState.state["world"]["day"]
	var shortfall := {
		"day": day,
		"deadline": day + int(GameData.GUARD_UPKEEP["graceDays"]),
		"places": places.duplicate(),
		"reserve": reserve,
	}
	GameState.state["guardUpkeep"]["pendingShortfall"] = shortfall
	Notify.push("Guard wages short: £%d due. Unpaid guards walk on %s — %s." % [due, Calendar.format_day(shortfall["deadline"]), places_text(places.keys())], Notify.CATEGORY_WARNING, { Notify.META_GUARD_SHORTFALL: true })
	EventBus.state_changed.emit()


# Rollover step (R§3.1 ①b): once the grace deadline is reached, the pending
# shortfall resolves on its own. Returns _auto_resolve()'s result, or {}
# when nothing was due.
static func resolve_due_shortfall() -> Dictionary:
	var shortfall: Variant = pending_shortfall()
	if shortfall == null or int(GameState.state["world"]["day"]) < int(shortfall["deadline"]):
		return {}
	return _auto_resolve(shortfall)


# Keeps as many guards as the funds cover (the reserve with the pot active,
# else player cash), each paid weeklyWage; the rest walk in drop order. Any
# leftover reserve goes to the float, or to cash before the pot. Clears the
# shortfall. Returns { paid, kept, walked: { place id: guards } }.
#
# PROSE-REVIEW: the walk-off notification.
static func _auto_resolve(shortfall: Dictionary) -> Dictionary:
	var at_risk := _guards_at_risk(shortfall["places"])
	var total := 0
	for place_id in at_risk:
		total += int(at_risk[place_id])
	var pot_era := Business.is_pot_active()
	var reserve: int = int(shortfall["reserve"])
	var player: Dictionary = GameState.state["player"]
	var funds: int = reserve if pot_era else int(player["cash"])
	var kept := mini(total, funds / weekly_wage())
	var walked := _drop_guards(at_risk, total - kept)
	var paid := 0
	for place_id in at_risk:
		var amount := weekly_cost(int(at_risk[place_id]) - int(walked.get(place_id, 0)))
		record_payment(place_id, amount)
		paid += amount
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
		Notify.push("Unpaid guards walked off: %s." % walked_text(walked), Notify.CATEGORY_WARNING)
	EventBus.state_changed.emit()


# The short-pay menu's rows: the pending shortfall's guards still at risk,
# { place id: guards }. Empty with no shortfall.
static func short_pay_places() -> Dictionary:
	var shortfall: Variant = pending_shortfall()
	if shortfall == null:
		return {}
	return _guards_at_risk(shortfall["places"])


# What confirming `keep` ({ place id: guards to keep }, clamped to
# 0..guards at risk) costs: { cost, reserve, cashNeeded } (spec §Short-pay
# flow, Menu).
static func short_pay_quote(keep: Dictionary) -> Dictionary:
	var shortfall: Variant = pending_shortfall()
	var reserve := 0 if shortfall == null else int(shortfall["reserve"])
	var cost := 0
	var kept := _clamp_keep(short_pay_places(), keep)
	for place_id in kept:
		cost += weekly_cost(int(kept[place_id]))
	return { "cost": cost, "reserve": reserve, "cashNeeded": maxi(cost - reserve, 0) }


# Short-pay confirm (spec §Short-pay flow, Confirm): each place keeps
# keep[place id] guards (missing = 0), paid weeklyWage each from the reserve
# first, then cash (bank "Guard wages"). Unkept guards walk now, newest
# extra first, tier guard last. Leftover reserve goes as on auto-resolve and
# the shortfall clears. Refused, nothing changed, when cash can't cover the
# difference. Returns { ok, paid, walked } or { ok: false, reason }.
static func confirm_shortfall(keep: Dictionary) -> Dictionary:
	if pending_shortfall() == null:
		return { "ok": false, "reason": "No guard wages are owed." }
	var quote := short_pay_quote(keep)
	var player: Dictionary = GameState.state["player"]
	if int(player["cash"]) < int(quote["cashNeeded"]):
		return { "ok": false, "reason": "Not enough cash." }
	var at_risk := short_pay_places()
	var kept_by_place := _clamp_keep(at_risk, keep)
	var walked := {}
	var kept := 0
	for place_id in at_risk:
		var keeping := int(kept_by_place[place_id])
		var dropping := int(at_risk[place_id]) - keeping
		for i in dropping:
			if place_id == HOME_PLACE_ID:
				Home.drop_guard()
			else:
				Cultivating.drop_vein_guard(Cultivating.find_vein(place_id))
		if dropping > 0:
			walked[place_id] = dropping
		record_payment(place_id, weekly_cost(keeping))
		kept += keeping
	if int(quote["cashNeeded"]) > 0:
		player["cash"] -= int(quote["cashNeeded"])
		Bank.record(-int(quote["cashNeeded"]), WAGES_BANK_LABEL)
	var leftover := int(quote["reserve"]) - (int(quote["cost"]) - int(quote["cashNeeded"]))
	_close_shortfall(leftover, int(quote["cost"]), kept, walked)
	return { "ok": true, "paid": quote["cost"], "walked": walked }


# keep counts for every at-risk place, each clamped to 0..its guards.
static func _clamp_keep(at_risk: Dictionary, keep: Dictionary) -> Dictionary:
	var kept := {}
	for place_id in at_risk:
		kept[place_id] = clampi(int(keep.get(place_id, 0)), 0, int(at_risk[place_id]))
	return kept


# Each recorded place's guards still on duty, capped at its recorded count:
# a vein outside player.veins drops out, and guards hired during grace (already
# paid their advance) aren't at risk.
static func _guards_at_risk(places: Dictionary) -> Dictionary:
	var current := player_guards_by_place()
	var at_risk := {}
	for place_id in places:
		var count := mini(int(places[place_id]), int(current.get(place_id, 0)))
		if count > 0:
			at_risk[place_id] = count
	return at_risk


# Drops `count` at-risk guards in drop order (spec §Short-pay flow): extras
# on the least valuable vein first (Cultivating.value_order), then tier
# guards least valuable first ("guarded" -> "warded"), then HQ guards.
# Returns { place id: guards dropped }.
static func _drop_guards(at_risk: Dictionary, count: int) -> Dictionary:
	var walked := {}
	if count <= 0:
		return walked
	var veins: Array = []
	for place_id in at_risk:
		if place_id != HOME_PLACE_ID:
			veins.append(Cultivating.find_vein(place_id))
	count = drop_vein_guards(veins, at_risk, count, walked)
	for i in mini(count, int(at_risk.get(HOME_PLACE_ID, 0))):
		Home.drop_guard()
		walked[HOME_PLACE_ID] = int(walked.get(HOME_PLACE_ID, 0)) + 1
	return walked


# The vein part of the drop order, shared by player and faction veins:
# extras on the least valuable vein first (Cultivating.value_order), then
# tier guards least valuable first ("guarded" -> "warded"). Drops at most
# `count` guards and at most at_risk[vein id] per vein, adds them to walked
# { vein id: guards dropped }, and returns how many of `count` are left.
static func drop_vein_guards(veins: Array, at_risk: Dictionary, count: int, walked: Dictionary) -> int:
	var ordered := veins.duplicate()
	ordered.sort_custom(Cultivating.value_order)
	ordered.reverse()
	for vein in ordered:
		var extras := mini(int(at_risk[vein["id"]]), int(vein.get("extraGuards", 0)))
		for i in mini(extras, count):
			Cultivating.drop_vein_guard(vein)
			walked[vein["id"]] = int(walked.get(vein["id"], 0)) + 1
			count -= 1
	for vein in ordered:
		if count > 0 and int(at_risk[vein["id"]]) > int(walked.get(vein["id"], 0)):
			Cultivating.drop_vein_guard(vein)
			walked[vein["id"]] = int(walked.get(vein["id"], 0)) + 1
			count -= 1
	return count


# ── faction Monday bill (spec §Faction guard upkeep) ──

# R§3.1 ⑤h2: on the rollover into a Monday, each faction pays weeklyWage per
# guard on its veins from resources, as many guards as it can cover. The
# rest walk now in drop order (drop_vein_guards()); resources never go
# negative. A vein claimed today isn't billed: its guards start on the next
# Monday. Returns { faction id: { due, paid, walked } } for billed factions.
static func pay_faction_monday_bills() -> Dictionary:
	var results := {}
	var day: int = GameState.state["world"]["day"]
	if not Calendar.is_monday(day):
		return results
	var veins_by_faction := {}
	for site in GameState.state["world"]["sites"]:
		var vein: Variant = site["factionVein"]
		if vein == null or int(vein.get("claimedOnDay", -1)) == day:
			continue
		if Cultivating.vein_guard_count(vein) > 0:
			if not veins_by_faction.has(vein["factionId"]):
				veins_by_faction[vein["factionId"]] = []
			veins_by_faction[vein["factionId"]].append(vein)
	for faction_id in veins_by_faction:
		var faction_state: Dictionary = GameState.state["factions"][faction_id]
		var at_risk := {}
		var guards := 0
		for vein in veins_by_faction[faction_id]:
			at_risk[vein["id"]] = Cultivating.vein_guard_count(vein)
			guards += int(at_risk[vein["id"]])
		var kept := clampi(floori(float(faction_state["resources"]) / float(weekly_wage())), 0, guards)
		var walked := {}
		drop_vein_guards(veins_by_faction[faction_id], at_risk, guards - kept, walked)
		faction_state["resources"] -= weekly_cost(kept)
		results[faction_id] = { "due": weekly_cost(guards), "paid": weekly_cost(kept), "walked": walked }
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

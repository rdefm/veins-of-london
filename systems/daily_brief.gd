class_name DailyBrief
extends RefCounted

# BizBrief's Today card (.scratch/bizbrief-today/spec.md): a pure projection
# of the day's plan over GameState. It never writes state. Each row is plain
# data; `action` is a destination descriptor BizBrief routes through
# existing navigation. Tiers, templates and labels live in
# data/daily_brief.json.

const BADGE_TIERS := ["urgent", "story"]


# Ordered rows: fixed tier order, then `sort` (lower = sooner), then source
# order.
static func items() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	_alarm_rows(rows)
	_guard_shortfall_rows(rows)
	_wage_rows(rows)
	_development_rows(rows)
	var tiers: Array = GameData.DAILY_BRIEF["tierOrder"]
	var order: Array = range(rows.size())
	order.sort_custom(func(a: int, b: int) -> bool:
		var tier_a: int = tiers.find(rows[a]["tier"])
		var tier_b: int = tiers.find(rows[b]["tier"])
		if tier_a != tier_b:
			return tier_a < tier_b
		if rows[a]["sort"] != rows[b]["sort"]:
			return rows[a]["sort"] < rows[b]["sort"]
		return a < b
	)
	var ordered: Array[Dictionary] = []
	for i in order:
		ordered.append(rows[i])
	return ordered


# Urgent + Story rows: what the Phone home BizBrief badge counts.
static func badge_count() -> int:
	return items().filter(func(row: Dictionary): return BADGE_TIERS.has(row["tier"])).size()


# Card header data: date label, time blocks left today, rows per tier.
static func summary() -> Dictionary:
	var counts := {}
	for tier in GameData.DAILY_BRIEF["tierOrder"]:
		counts[tier] = 0
	for row in items():
		counts[row["tier"]] += 1
	return {
		"dateLabel": Calendar.widget_date(int(GameState.state["world"]["day"])),
		"blocksLeft": TimeSystem.blocks_left(),
		"counts": counts,
	}


static func empty_text() -> String:
	return GameData.DAILY_BRIEF["emptyState"]


static func _alarm_rows(rows: Array[Dictionary]) -> void:
	for alarm in RaidAlarms.summary_rows():
		var values := { "title": alarm["title"], "deadline": alarm["deadline"], "consequence": alarm["consequence"] }
		if alarm["kind"] == "home":
			rows.append(_row("alarmHome", "alarm:home", values, { "to": "alarms" }, 0))
		else:
			rows.append(_row("alarmVein", "alarm:%s" % alarm["veinId"], values, { "to": "alarms" }, 0))


static func _guard_shortfall_rows(rows: Array[Dictionary]) -> void:
	var shortfall: Variant = GuardUpkeep.pending_shortfall()
	if shortfall == null:
		return
	var deadline: int = shortfall["deadline"]
	var values := { "deadline": Calendar.format_day(deadline), "places": GuardUpkeep.places_text(shortfall["places"].keys()) }
	rows.append(_row("guardShortfall", "guardShortfall", values, { "to": "short_pay" }, deadline - int(GameState.state["world"]["day"])))


static func _wage_rows(rows: Array[Dictionary]) -> void:
	var prompts := Business.pending_wage_prompts()
	for contact_id in Business.owed_contact_ids():
		var values := { "name": Contacts.display_name(contact_id), "owed": Business.owed(contact_id), "topUp": Business.top_up_needed(contact_id) }
		if prompts.has(contact_id):
			rows.append(_row("wagePrompt", "wages:%s" % contact_id, values, { "to": "wage_prompt", "contactId": contact_id }, 0))
		else:
			rows.append(_row("wagesOwed", "wages:%s" % contact_id, values, { "to": "bizbrief_staff", "contactId": contact_id }, 0))


# Live eligibility, re-derived from state every call, so a vein pruned past
# the threshold drops off at once.
static func _development_rows(rows: Array[Dictionary]) -> void:
	for vein in GameState.state["player"]["veins"]:
		if not Cultivating.is_development_eligible(vein):
			continue
		# R§3.4: combined_magnitude, so the vein's earned level shows in the
		# exposure figure.
		var values := {
			"ore": GameData.ORE_TYPES[vein["oreType"]]["name"],
			"district": GameData.DISTRICTS[vein["district"]]["name"],
			"exposure": Cultivating.combined_magnitude(vein),
		}
		rows.append(_row("development", "development:%s" % vein["id"], values, { "to": "map_vein", "veinId": vein["id"] }, 0))


static func _row(template_id: String, key: String, values: Dictionary, action: Dictionary, sort: int) -> Dictionary:
	var template: Dictionary = GameData.DAILY_BRIEF["rows"][template_id]
	return {
		"key": key,
		"tier": template["tier"],
		"kind": template["kind"],
		"label": String(template["label"]).format(values),
		"consequence": String(template["consequence"]).format(values),
		"action": action,
		"actionLabel": template["actionLabel"],
		"done": false,
		"sort": sort,
	}

class_name Payroll
extends RefCounted

# Weekly wage payment for the three assignable staff roles (Sales/
# Production/Procurement, each a one-contact-per-room assignment Contacts
# tracks, R§3.10 "Weekly cadence"). Runs in TimeSystem.daily_tick() after
# living costs, and charges only on the rollover into a Monday.
# "Default-then-review": affordable roles are paid automatically in a fixed
# priority order, and any left unpaid do no work until paid or the next
# Monday -- no debt, no mid-tick pause. A new hire works at once; their first
# part-week is billed, prorated, with the next Monday's wage. Static funcs only.

# Daily rate; the weekly wage is this × the days in a week.
const WAGE_BASE := 100
const WAGE_PER_SKILL_LEVEL := 50

# Priority order wages are attempted in when cash is short -- matches
# hq_floorplan.gd's ASSIGNABLE_ROOMS (Production, Procurement, Sales).
const ROLE_ROOMS: PackedStringArray = ["lab", "veinStation", "ops"]

# Room id -> the contact skill field that room's role uses ("<skill>Skill"),
# derived from GameData.HIRING_ROLES; every role with a room and skill counts.
static func role_skill_keys() -> Dictionary:
	var out := {}
	for role_id in GameData.HIRING_ROLES:
		var role: Dictionary = GameData.HIRING_ROLES[role_id]
		if role.get("room") != null and role.get("skill") != null:
			out[role["room"]] = "%sSkill" % role["skill"]
	return out


# Weekly wage: (£100 + £50 × (role skill − 1)) × 7, identical for all three
# roles. Returns 0 when the room has no assigned contact or a founder holds it.
static func wage_for_room(room_id: String) -> int:
	var contact_id: Variant = Contacts.get_contact_in_room(room_id)
	if contact_id == null or Contacts.is_founder(contact_id):
		return 0
	var skill: int = int(GameState.state["contacts"][contact_id].get(role_skill_keys()[room_id], 1))
	return (WAGE_BASE + WAGE_PER_SKILL_LEVEL * (skill - 1)) * Calendar.days_per_week()


# Whether room_id's assigned role is paid for the current week. Defaults
# true when payroll has not resolved this room since its hire -- an
# unassigned room has no wage to fail, and a new hire works at once.
static func is_paid_this_week(room_id: String) -> bool:
	return GameState.state["payroll"]["paidToday"].get(room_id, true)


# Contacts.assign_to_room() hook: a hire into a role room works at once and
# its first part-week is billed at the next Monday.
static func note_hire(contact_id: String, room_id: String) -> void:
	if not role_skill_keys().has(room_id) or Contacts.is_founder(contact_id):
		return
	var payroll: Dictionary = GameState.state["payroll"]
	payroll["hires"][room_id] = { "contactId": contact_id, "day": GameState.state["world"]["day"] }
	payroll["paidToday"].erase(room_id)


# Monday's wage for room_id: the weekly wage, plus round(weekly × days / 7)
# for the unbilled part-week of a hire still holding the room.
static func wage_due(room_id: String, day: int) -> int:
	var weekly := wage_for_room(room_id)
	var hire: Variant = GameState.state["payroll"]["hires"].get(room_id)
	if hire == null or hire["contactId"] != Contacts.get_contact_in_room(room_id):
		return weekly
	var days := maxi(0, day - int(hire["day"]))
	return weekly + GameState.round_epsilon(float(weekly) * float(days) / float(Calendar.days_per_week()))


# Pay now's price: the wage the last Monday failed to pay this occupant,
# else a full week's.
static func pay_now_amount(room_id: String) -> int:
	var summary: Variant = GameState.state["payroll"]["lastSummary"]
	if summary != null:
		for entry in summary["entries"]:
			if entry["room"] == room_id and entry["contactId"] == Contacts.get_contact_in_room(room_id) and not entry["paid"]:
				return int(entry["wage"])
	return wage_for_room(room_id)


# Whether a staffed contact acts at block ends (R§3.10 "Staff block step"):
# a room hire only while this week's wage is paid; a founder draws no room
# wage and acts unless the business owes them a weekly wage.
static func is_working(contact_id: String) -> bool:
	if Business.is_unpaid(contact_id):
		return false
	if Contacts.is_founder(contact_id):
		return true
	var room: Variant = GameState.state["contacts"][contact_id].get("assignedRoom")
	return room == null or is_paid_this_week(room)


# Called from TimeSystem.daily_tick(), after living costs. On the rollover
# into a Monday, pays every assigned role's wage_due() in ROLE_ROOMS
# priority order, spending only as far as remaining cash allows; every
# part-week hire is then billed or forgiven.
static func pay_wages() -> void:
	var day: int = GameState.state["world"]["day"]
	if not Calendar.is_monday(day):
		return
	var player: Dictionary = GameState.state["player"]
	var paid_today := {}
	var entries: Array = []
	var unpaid_names: Array = []

	for room_id in ROLE_ROOMS:
		var contact_id: Variant = Contacts.get_contact_in_room(room_id)
		# Founders never draw a room wage (R§3.10 "Staff roles").
		if contact_id == null or Contacts.is_founder(contact_id):
			continue
		var wage := wage_due(room_id, day)
		var paid: bool = player["cash"] >= wage
		if paid:
			player["cash"] -= wage
			Bank.record(-wage, "Wages: %s" % Contacts.display_name(contact_id))
			BusinessStats.record_expense(wage, BusinessStats.EXPENSE_STAFF)
		else:
			unpaid_names.append(Contacts.display_name(contact_id))
		paid_today[room_id] = paid
		entries.append({ "room": room_id, "contactId": contact_id, "wage": wage, "paid": paid })

	var payroll: Dictionary = GameState.state["payroll"]
	payroll["paidToday"] = paid_today
	payroll["hires"] = {}
	payroll["lastSummary"] = { "day": day, "entries": entries }

	if not unpaid_names.is_empty():
		# PROSE-REVIEW: new daily-tick payroll shortfall notification, drafted against CONTENT-GUIDE.md's tone bible.
		Notify.push("Payday came up short. Couldn't pay %s -- no work from them this week." % ", ".join(unpaid_names), Notify.CATEGORY_WARNING)

	EventBus.state_changed.emit()


# The "review/override" half of the default-then-review model: cash that
# arrives later in the week can be spent to clear a role pay_wages()
# skipped. Updates the same paidToday/lastSummary records pay_wages()
# writes, so a role paid this way immediately counts as staffed again.
static func pay_now(room_id: String) -> Dictionary:
	var contact_id: Variant = Contacts.get_contact_in_room(room_id)
	if contact_id == null:
		return { "ok": false, "reason": "No one assigned to that role." }
	if is_paid_this_week(room_id):
		return { "ok": false, "reason": "Already paid this week." }
	var wage := pay_now_amount(room_id)
	var player: Dictionary = GameState.state["player"]
	if player["cash"] < wage:
		return { "ok": false, "reason": "Not enough cash." }

	player["cash"] -= wage
	Bank.record(-wage, "Wages: %s" % Contacts.display_name(contact_id))
	BusinessStats.record_expense(wage, BusinessStats.EXPENSE_STAFF)
	GameState.state["payroll"]["paidToday"][room_id] = true
	var summary: Variant = GameState.state["payroll"]["lastSummary"]
	if summary != null:
		for entry in summary["entries"]:
			if entry["room"] == room_id:
				entry["paid"] = true
	EventBus.state_changed.emit()
	return { "ok": true, "wage": wage }

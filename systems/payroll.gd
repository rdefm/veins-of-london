class_name Payroll
extends RefCounted

# Daily wage payment for the three assignable staff roles (Sales/
# Production/Procurement, each a one-contact-per-room assignment Contacts
# tracks, R§3.10). Runs at the top of TimeSystem.daily_tick(), right after
# living costs. "Default-then-review": affordable roles are paid
# automatically in a fixed priority order, and any left unpaid simply do no
# work for the rest of that day -- no debt, no mid-tick pause, retried
# fresh next rollover. Static funcs only.

const WAGE_BASE := 100
const WAGE_PER_SKILL_LEVEL := 50

# Priority order wages are attempted in when cash is short -- matches
# hq_floorplan.gd's ASSIGNABLE_ROOMS (Production, Procurement, Sales).
const ROLE_ROOMS: PackedStringArray = ["lab", "veinStation", "ops"]

# Room id -> the contact skill field that room's role uses (Sales/
# salesSkill, Production/craftingSkill, Procurement/cultivatingSkill).
const ROLE_SKILL_KEYS := {
	"lab": "craftingSkill",
	"veinStation": "cultivatingSkill",
	"ops": "salesSkill",
}


# £100 + £50 × (role skill − 1), identical for all three roles. Returns 0
# when the room has no assigned contact or a founder holds it.
static func wage_for_room(room_id: String) -> int:
	var contact_id: Variant = Contacts.get_contact_in_room(room_id)
	if contact_id == null or Contacts.is_founder(contact_id):
		return 0
	var skill: int = int(GameState.state["contacts"][contact_id].get(ROLE_SKILL_KEYS[room_id], 1))
	return WAGE_BASE + WAGE_PER_SKILL_LEVEL * (skill - 1)


# Whether room_id's assigned role was paid on the rollover currently in
# progress (or the last completed one). Defaults true when payroll has
# never resolved this room -- an unassigned room has no wage to fail, and a
# fresh assignment (e.g. a direct test setup) should behave as staffed.
static func is_paid_today(room_id: String) -> bool:
	return GameState.state["payroll"]["paidToday"].get(room_id, true)


# Whether a staffed contact acts at block ends (R§3.10 "Staff block step"):
# a room hire only once today's wage is paid; a founder draws no daily wage
# and always acts.
static func is_working(contact_id: String) -> bool:
	if Contacts.is_founder(contact_id):
		return true
	var room: Variant = GameState.state["contacts"][contact_id].get("assignedRoom")
	return room == null or is_paid_today(room)


# Called from TimeSystem.daily_tick(), after living costs. Pays every
# assigned role's wage in ROLE_ROOMS priority order, spending only as far
# as remaining cash allows.
static func pay_wages() -> void:
	var player: Dictionary = GameState.state["player"]
	var paid_today := {}
	var entries: Array = []
	var unpaid_names: Array = []

	for room_id in ROLE_ROOMS:
		var contact_id: Variant = Contacts.get_contact_in_room(room_id)
		# Founders never draw a daily wage (R§3.10 "Staff roles").
		if contact_id == null or Contacts.is_founder(contact_id):
			continue
		var wage := wage_for_room(room_id)
		var paid: bool = player["cash"] >= wage
		if paid:
			player["cash"] -= wage
			Bank.record(-wage, "Wages: %s" % Contacts.display_name(contact_id))
		else:
			unpaid_names.append(Contacts.display_name(contact_id))
		paid_today[room_id] = paid
		entries.append({ "room": room_id, "contactId": contact_id, "wage": wage, "paid": paid })

	var payroll: Dictionary = GameState.state["payroll"]
	payroll["paidToday"] = paid_today
	payroll["lastSummary"] = { "day": GameState.state["world"]["day"], "entries": entries }

	if not unpaid_names.is_empty():
		# PROSE-REVIEW: new daily-tick payroll shortfall notification, drafted against CONTENT-GUIDE.md's tone bible.
		Notify.push("Payday came up short. Couldn't pay %s -- no work from them today." % ", ".join(unpaid_names), Notify.CATEGORY_WARNING)

	EventBus.state_changed.emit()


# The "review/override" half of the default-then-review model: cash that
# arrives later the same day can be spent to clear a role pay_wages()
# skipped. Updates the same paidToday/lastSummary records pay_wages()
# writes, so a role paid this way immediately counts as staffed again.
static func pay_now(room_id: String) -> Dictionary:
	var contact_id: Variant = Contacts.get_contact_in_room(room_id)
	if contact_id == null:
		return { "ok": false, "reason": "No one assigned to that role." }
	if is_paid_today(room_id):
		return { "ok": false, "reason": "Already paid today." }
	var wage := wage_for_room(room_id)
	var player: Dictionary = GameState.state["player"]
	if player["cash"] < wage:
		return { "ok": false, "reason": "Not enough cash." }

	player["cash"] -= wage
	Bank.record(-wage, "Wages: %s" % Contacts.display_name(contact_id))
	GameState.state["payroll"]["paidToday"][room_id] = true
	var summary: Variant = GameState.state["payroll"]["lastSummary"]
	if summary != null:
		for entry in summary["entries"]:
			if entry["room"] == room_id:
				entry["paid"] = true
	EventBus.state_changed.emit()
	return { "ok": true, "wage": wage }

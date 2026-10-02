class_name Payroll
extends RefCounted

# Who works for the business at block ends (R§3.10 "Business pot and
# payday"). Every staff wage is paid by Business at the Monday payday from
# the pot, then the float; player cash never pays a wage. Static funcs only.

# Room id -> the contact skill field that room's role uses ("<skill>Skill"),
# derived from GameData.HIRING_ROLES; every role with a room and skill counts.
static func role_skill_keys() -> Dictionary:
	var out := {}
	for role_id in GameData.HIRING_ROLES:
		var role: Dictionary = GameData.HIRING_ROLES[role_id]
		if role.get("room") != null and role.get("skill") != null:
			out[role["room"]] = "%sSkill" % role["skill"]
	return out


# Whether a staffed contact acts at block ends (R§3.10 "Staff block step"):
# everyone works unless the business owes them a wage.
static func is_working(contact_id: String) -> bool:
	return not Business.is_unpaid(contact_id)

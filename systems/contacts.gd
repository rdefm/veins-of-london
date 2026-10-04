class_name Contacts
extends RefCounted

# Contacts: relation, recruiting, room assignment, staff roles, contact XP.
# Per R§3.10. Static funcs only.

# Staffing a role-room makes its occupant a member of that role (R§3.10
# "Staff roles"). Room id -> role id, derived from GameData.HIRING_ROLES;
# every role with a room counts, enabled or not.
static func room_roles() -> Dictionary:
	var out := {}
	for role_id in GameData.HIRING_ROLES:
		var room: Variant = GameData.HIRING_ROLES[role_id].get("room")
		if room != null:
			out[room] = role_id
	return out


static func award_relation(contact_id: String, amount: int) -> void:
	var contacts: Dictionary = GameState.state["contacts"]
	if not contacts.has(contact_id):
		return
	contacts[contact_id]["relation"] = contacts[contact_id]["relation"] + amount
	EventBus.state_changed.emit()


static func can_recruit(contact_id: String) -> bool:
	var contacts: Dictionary = GameState.state["contacts"]
	if not contacts.has(contact_id):
		return false
	var c: Dictionary = contacts[contact_id]
	# Some contacts (Des/Nadia/Hakim) are never recruitable -- gated here
	# too, not just the UI, so there's no back door via a recruitThreshold
	# of 0 (met the instant they unlock).
	if not c.get("recruitable", true):
		return false
	return c["unlocked"] and not c["recruited"] and c["relation"] >= c["recruitThreshold"]


static func recruit(contact_id: String) -> Dictionary:
	if not can_recruit(contact_id):
		return { "ok": false, "reason": "Cannot recruit yet." }
	var c: Dictionary = GameState.state["contacts"][contact_id]
	c["recruited"] = true
	Dial.grant_contact_dial(contact_id)
	Notify.push("%s is now working with you. Assign them to a room via HQ." % display_name(contact_id), Notify.CATEGORY_SUCCESS)
	EventBus.state_changed.emit()
	return { "ok": true }


# Unconditional recruit for story beats (the home-raid debrief's Archie),
# bypassing can_recruit()'s relation/recruitable gates. Idempotent.
static func force_recruit(contact_id: String) -> void:
	var contacts: Dictionary = GameState.state["contacts"]
	if not contacts.has(contact_id):
		return
	contacts[contact_id]["recruited"] = true
	Dial.grant_contact_dial(contact_id)
	EventBus.state_changed.emit()


# Founders (constants.json roomFreeRoles) may hold a staff role without a room.
static func is_founder(contact_id: String) -> bool:
	return bool(GameData.CONTACTS_DEFAULTS.get(contact_id, {}).get("roomFreeRoles", false))


# The contact's staff role: their founder assignedRole, else the role of the
# room they staff, else null.
static func role_of(contact_id: String) -> Variant:
	var c: Dictionary = GameState.state["contacts"].get(contact_id, {})
	if c.is_empty() or not c["recruited"]:
		return null
	if c.get("assignedRole") != null:
		return c["assignedRole"]
	var room: Variant = c.get("assignedRoom")
	var roles := room_roles()
	if room != null and roles.has(room):
		return roles[room]
	return null


static func contacts_in_role(role: String) -> Array:
	var result: Array = []
	for contact_id in GameState.state["contacts"].keys():
		if role_of(contact_id) == role:
			result.append(contact_id)
	return result


# The contact whose salesSkill drives sourcing and who earns sales XP: the
# first Sales role holder, or null.
static func sales_contact() -> Variant:
	var holders := contacts_in_role("sales")
	return null if holders.is_empty() else holders[0]


# Room-free roles a founder may currently take, each unlocked by the flag
# its constants.json roleFlags entry names. Non-founders reach a role only
# by staffing its room, so this is always empty for them.
static func available_roles(contact_id: String) -> Array:
	var result: Array = []
	if not is_founder(contact_id):
		return result
	var role_flags: Dictionary = GameData.CONTACTS_DEFAULTS[contact_id].get("roleFlags", {})
	var flags: Dictionary = GameState.state["flags"]
	for role in role_flags.keys():
		if flags.get(role_flags[role], false):
			result.append(role)
	return result


static func is_role_available(contact_id: String, role: String) -> bool:
	return available_roles(contact_id).has(role)


# Sets a founder's room-free role (null clears it). Exclusive with
# assignedRoom: setting a role vacates any room they held.
static func set_role(contact_id: String, role: Variant) -> Dictionary:
	var contacts: Dictionary = GameState.state["contacts"]
	if not contacts.has(contact_id) or not contacts[contact_id]["recruited"]:
		return { "ok": false, "reason": "Not working with you." }
	if not is_founder(contact_id):
		return { "ok": false, "reason": "Assign them to a room instead." }
	if role != null and not is_role_available(contact_id, role):
		return { "ok": false, "reason": "That role isn't open to them yet." }
	var c: Dictionary = contacts[contact_id]
	c["assignedRole"] = role
	if role != null:
		c["assignedRoom"] = null
	EventBus.state_changed.emit()
	return { "ok": true }


# Recruited contacts staffing room_id, in contact order.
static func contacts_in_room(room_id: String) -> Array:
	var result: Array = []
	var contacts: Dictionary = GameState.state["contacts"]
	for contact_id in contacts.keys():
		var c: Dictionary = contacts[contact_id]
		if c["recruited"] and c["assignedRoom"] == room_id:
			result.append(contact_id)
	return result


# Seats in use in room_id: its occupants, less founders (who hold no
# seat, hiring-spec §5).
static func room_seats_used(room_id: String) -> int:
	var used := 0
	for contact_id in contacts_in_room(room_id):
		if not is_founder(contact_id):
			used += 1
	return used


# Assigns contact_id to room_id, clearing any role or other room they held.
# Refused while every seat is taken (no eviction). "none" vacates every
# occupant of the room.
static func assign_to_room(contact_id: String, room_id: String) -> Dictionary:
	var contacts: Dictionary = GameState.state["contacts"]
	if contact_id == "none":
		for cid in contacts.keys():
			if contacts[cid]["assignedRoom"] == room_id:
				contacts[cid]["assignedRoom"] = null
		EventBus.state_changed.emit()
		return { "ok": true }
	if not contacts.has(contact_id):
		return { "ok": false, "reason": "Not working with you." }
	var c: Dictionary = contacts[contact_id]
	if c["assignedRoom"] == room_id:
		return { "ok": true }
	if not is_founder(contact_id) and room_seats_used(room_id) >= Home.room_seats(room_id):
		return { "ok": false, "reason": "No free seat." }
	c["assignedRoom"] = room_id
	c["assignedRole"] = null
	EventBus.state_changed.emit()
	return { "ok": true }


# Takes contact_id out of whatever room they staff.
static func unassign_from_room(contact_id: String) -> void:
	var contacts: Dictionary = GameState.state["contacts"]
	if contacts.has(contact_id):
		contacts[contact_id]["assignedRoom"] = null
		EventBus.state_changed.emit()


# The XP ladder for a contact skill: levels[n] is the XP that reaches level n.
static func xp_levels(skill: String) -> Array:
	match skill:
		"crafting":
			return GameData.CRAFTING_XP_LEVELS
		"sales":
			return GameData.SALES_XP_LEVELS
	return GameData.CULTIVATING_XP_LEVELS


# The contact's skill level cap (constants.json / hiring.json skillCaps),
# else the top of the skill's XP ladder.
static func skill_cap(contact_id: String, skill: String) -> int:
	var max_level: int = xp_levels(skill).size() - 1
	var caps: Dictionary = GameData.CONTACTS_DEFAULTS.get(contact_id, {}).get("skillCaps", {})
	if caps.has(skill):
		max_level = mini(max_level, int(caps[skill]))
	return max_level


static func award_contact_xp(contact_id: String, skill: String, amount: int) -> void:
	var contacts: Dictionary = GameState.state["contacts"]
	if not contacts.has(contact_id):
		return
	var c: Dictionary = contacts[contact_id]
	if Hiring.candidate(contact_id).size() > 0 and Hiring.skill(contact_id) == skill:
		amount = int(round(amount * Hiring.trait_xp_mult(contact_id)))
	var xp_key: String = skill + "XP"
	var skill_key: String = skill + "Skill"
	var levels := xp_levels(skill)
	c[xp_key] = c[xp_key] + amount
	var max_level := skill_cap(contact_id, skill)
	var leveled := false
	while c[skill_key] < max_level and c[xp_key] >= levels[c[skill_key] + 1]:
		c[skill_key] += 1
		leveled = true
		Notify.push("%s's %s skill reached level %d." % [display_name(contact_id), skill, c[skill_key]], Notify.CATEGORY_SUCCESS)
	if leveled:
		Hiring.refresh_wage(contact_id)


# recruited is the only gate -- no relation check (unlike can_recruit's
# threshold). combatHpMax > 0 excludes any contact whose constants.json
# entry never defined a combat kit, without hardcoding contact_id.
static func can_join_combat(contact_id: String) -> bool:
	var contacts: Dictionary = GameState.state["contacts"]
	if not contacts.has(contact_id):
		return false
	var c: Dictionary = contacts[contact_id]
	if not c["recruited"] or c["combatHpMax"] <= 0:
		return false
	var cooldown_until = c["koCooldownUntilDay"]
	if cooldown_until != null and GameState.state["world"]["day"] < cooldown_until:
		return false
	return true


# The general ally-combat shape systems/combat.gd's allies array holds --
# a snapshot of the contact's current combat kit at the moment they join a
# fight. contactId round-trips back to this contact's persistent state at
# knock_out()/replenish_after_combat() below.
static func build_combat_ally(contact_id: String) -> Dictionary:
	var c: Dictionary = GameState.state["contacts"][contact_id]
	return {
		"contactId": contact_id,
		"name": display_name(contact_id),
		"hp": c["combatHp"],
		"hpMax": c["combatHpMax"],
		"attackMin": c["combatAttackMin"],
		"attackMax": c["combatAttackMax"],
		"speed": c["combatSpeed"],
		"slots": GameState.deep_copy(c.get("loadout", {}).get("slots", [])),
		"slotsUsed": [],
		"koed": false,
	}


# Called by Combat when an ally's hp hits 0 mid-fight -- removes them from
# that fight (systems/combat.gd checks the `koed` flag on the ally dict)
# and starts a cooldown before they're eligible again.
static func knock_out(contact_id: String, current_day: int) -> void:
	var contacts: Dictionary = GameState.state["contacts"]
	if not contacts.has(contact_id):
		return
	var c: Dictionary = contacts[contact_id]
	c["koCooldownUntilDay"] = current_day + c["koCooldownDays"]
	EventBus.state_changed.emit()


# Called from Combat.exit_combat() once a fight involving allies ends --
# the HP pool is within-fight stakes only, not lasting attrition. Does NOT
# clear koCooldownUntilDay -- a knocked-out ally stays unavailable for the
# cooldown regardless of this replenish.
static func replenish_after_combat(allies: Array) -> void:
	var contacts: Dictionary = GameState.state["contacts"]
	for ally in allies:
		var contact_id: String = ally.get("contactId", "")
		if not contacts.has(contact_id):
			continue
		var c: Dictionary = contacts[contact_id]
		c["combatHp"] = c["combatHpMax"]


# A raid is offensive (the player's choice), unlike defend's auto-join, so
# raidAssistThreshold is layered on top of can_join_combat()'s own
# recruited/combat-kit/cooldown gates, not a replacement for them.
static func can_assist_raid(contact_id: String) -> bool:
	var contacts: Dictionary = GameState.state["contacts"]
	if not contacts.has(contact_id):
		return false
	var c: Dictionary = contacts[contact_id]
	if c["relation"] < c["raidAssistThreshold"]:
		return false
	return can_join_combat(contact_id)


static func display_name(contact_id: String) -> String:
	match contact_id:
		"archie":
			return "Archie"
		"james":
			return "James"
		"owen":
			return "Owen"
		_:
			var key_member := KeyMembers.member(contact_id)
			if not key_member.is_empty():
				return str(key_member["name"])
			var defaults: Dictionary = GameData.CONTACTS_DEFAULTS.get(contact_id, {})
			if defaults.has("name"):
				return str(defaults["name"])
			return contact_id.capitalize()


# Unlocked contacts in Contacts-directory order (by display name).
static func directory_ids() -> Array:
	var ids: Array = []
	for contact_id in GameState.state["contacts"].keys():
		if GameState.state["contacts"][contact_id]["unlocked"]:
			ids.append(contact_id)
	ids.sort_custom(func(a, b): return display_name(a) < display_name(b))
	return ids

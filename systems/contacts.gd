class_name Contacts
extends RefCounted

# Contacts: relation, recruiting, room assignment, contact XP. Per R§3.10.
# Static funcs only.


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
	return c["unlocked"] and not c["recruited"] and c["relation"] >= c["recruitThreshold"]


static func recruit(contact_id: String) -> Dictionary:
	if not can_recruit(contact_id):
		return { "ok": false, "reason": "Cannot recruit yet." }
	var c: Dictionary = GameState.state["contacts"][contact_id]
	c["recruited"] = true
	Notify.push("%s is now working with you. Assign them to a room via Your Property." % display_name(contact_id))
	EventBus.state_changed.emit()
	return { "ok": true }


static func get_contact_in_room(room_id: String) -> Variant:
	var contacts: Dictionary = GameState.state["contacts"]
	for contact_id in contacts.keys():
		var c: Dictionary = contacts[contact_id]
		if c["recruited"] and c["assignedRoom"] == room_id:
			return contact_id
	return null


# Vacates whatever contact currently holds room_id, then assigns contact_id
# to it (pass "none" to just vacate). One contact per room; assigning
# vacates any prior occupant of that room.
static func assign_to_room(contact_id: String, room_id: String) -> void:
	var contacts: Dictionary = GameState.state["contacts"]
	for cid in contacts.keys():
		if contacts[cid]["assignedRoom"] == room_id:
			contacts[cid]["assignedRoom"] = null
	if contact_id != "none" and contacts.has(contact_id):
		contacts[contact_id]["assignedRoom"] = room_id
	EventBus.state_changed.emit()


static func award_contact_xp(contact_id: String, skill: String, amount: int) -> void:
	var contacts: Dictionary = GameState.state["contacts"]
	if not contacts.has(contact_id):
		return
	var c: Dictionary = contacts[contact_id]
	var xp_key: String = skill + "XP"
	var skill_key: String = skill + "Skill"
	var levels: Array = GameData.CRAFTING_XP_LEVELS if skill == "crafting" else GameData.CULTIVATING_XP_LEVELS
	c[xp_key] = c[xp_key] + amount
	var max_level: int = levels.size() - 1
	while c[skill_key] < max_level and c[xp_key] >= levels[c[skill_key] + 1]:
		c[skill_key] += 1
		Notify.push("%s's %s skill reached level %d." % [display_name(contact_id), skill, c[skill_key]])


static func display_name(contact_id: String) -> String:
	match contact_id:
		"archie":
			return "Archie"
		"james":
			return "James"
		_:
			return contact_id.capitalize()

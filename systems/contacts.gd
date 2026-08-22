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
	Notify.push("%s is now working with you. Assign them to a room via HQ." % display_name(contact_id), Notify.CATEGORY_SUCCESS)
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
		Notify.push("%s's %s skill reached level %d." % [display_name(contact_id), skill, c[skill_key]], Notify.CATEGORY_SUCCESS)


# 44-archie-combat-ally: recruited is the only gate -- "defending shared
# interests doesn't need much trust" per the human, so no relation check
# here (unlike can_recruit's threshold). combatHpMax > 0 excludes any
# contact whose constants.json entry never defined a combat kit (james, for
# now) from ever being offered, without hardcoding contact_id == "archie".
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
		"stash": c["combatStash"],
		"healAmount": c["combatHealAmount"],
		"koed": false,
	}


# Called by Combat when an ally's hp hits 0 mid-fight -- removes them from
# that fight (systems/combat.gd checks the `koed` flag it set on the ally
# dict itself) and starts a cooldown before they're eligible again, per the
# ticket's "real stakes without permadeath".
static func knock_out(contact_id: String, current_day: int) -> void:
	var contacts: Dictionary = GameState.state["contacts"]
	if not contacts.has(contact_id):
		return
	var c: Dictionary = contacts[contact_id]
	c["koCooldownUntilDay"] = current_day + c["koCooldownDays"]
	EventBus.state_changed.emit()


# Called from Combat.exit_combat() once a fight involving allies ends --
# "replenishes between fights" (the ticket leaves the exact trigger open;
# fight-end is the simplest one, and matches the HP pool only ever mattering
# as within-fight stakes, not lasting attrition). Does NOT clear
# koCooldownUntilDay -- a knocked-out ally stays unavailable for the
# cooldown regardless of this replenish.
static func replenish_after_combat(allies: Array) -> void:
	var contacts: Dictionary = GameState.state["contacts"]
	for ally in allies:
		var contact_id: String = ally["contactId"]
		if not contacts.has(contact_id):
			continue
		var c: Dictionary = contacts[contact_id]
		c["combatHp"] = c["combatHpMax"]
		c["combatStash"] = c["combatStashMax"]


# 45-archie-raid-assist: a raid is offensive (the player's choice, into
# someone else's vein), unlike defend's auto-join -- the ticket's higher bar
# (raidAssistThreshold, separate from can_join_combat's no-relation-check) is
# layered on top of can_join_combat()'s own recruited/combat-kit/cooldown
# gates, not a replacement for them, so a KO'd or kit-less contact still
# can't be brought along just because relation is high enough.
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
		_:
			return contact_id.capitalize()

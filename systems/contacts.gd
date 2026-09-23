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
	var levels: Array
	match skill:
		"crafting":
			levels = GameData.CRAFTING_XP_LEVELS
		"sales":
			levels = GameData.SALES_XP_LEVELS
		_:
			levels = GameData.CULTIVATING_XP_LEVELS
	c[xp_key] = c[xp_key] + amount
	var max_level: int = levels.size() - 1
	while c[skill_key] < max_level and c[xp_key] >= levels[c[skill_key] + 1]:
		c[skill_key] += 1
		Notify.push("%s's %s skill reached level %d." % [display_name(contact_id), skill, c[skill_key]], Notify.CATEGORY_SUCCESS)


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
		"stash": c["combatStash"],
		"healAmount": c["combatHealAmount"],
		"speed": c["combatSpeed"],
		"dialCharges": c.get("dialCharges", 0),
		"koed": false,
	}


# constants.json's combatDial block ({chargesPerDay, tier, complications}),
# or {} for a contact with no Dial.
static func combat_dial(contact_id: String) -> Dictionary:
	return GameData.CONTACTS_DEFAULTS.get(contact_id, {}).get("combatDial", {})


# Daily tick: every contact with a combatDial gets its day's charges back.
static func daily_dial_regen() -> void:
	var contacts: Dictionary = GameState.state["contacts"]
	for contact_id in contacts.keys():
		var dial: Dictionary = combat_dial(contact_id)
		if not dial.is_empty():
			contacts[contact_id]["dialCharges"] = int(dial["chargesPerDay"])
	EventBus.state_changed.emit()


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
		var contact_id: String = ally["contactId"]
		if not contacts.has(contact_id):
			continue
		var c: Dictionary = contacts[contact_id]
		c["combatHp"] = c["combatHpMax"]
		c["combatStash"] = c["combatStashMax"]
		# Dial charges are per day, not per fight -- spent casts carry over.
		if ally.has("dialCharges"):
			c["dialCharges"] = ally["dialCharges"]


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
		_:
			return contact_id.capitalize()

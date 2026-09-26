class_name OwenTexts
extends RefCounted

# Owen's random texts (data/owen_texts.json). From the first rollover after
# he joins, Owen texts every intervalMinDays..intervalMaxDays days while
# he's working (Payroll.is_working); the clock pauses on days he isn't.
# State: state.owenTexts { nextDay, played: { textId: playSeq }, playSeq,
# active: null | { id, vars } } -- active is the text awaiting a reply.
# Static funcs only.

const CONTACT_ID := "owen"


# Rollover step: seeds, pauses, or fires the scheduler.
static func daily_tick() -> void:
	if not GameState.state["flags"].get("bizA1OwenJoined", false):
		return
	var owen_texts: Dictionary = GameState.state["owenTexts"]
	var day: int = GameState.state["world"]["day"]
	if owen_texts["nextDay"] == null:
		# Seeded on the first rollover after he joins, so the interval
		# counts from the join day (yesterday).
		owen_texts["nextDay"] = day - 1 + _roll_interval()
		return
	if not Payroll.is_working(CONTACT_ID):
		owen_texts["nextDay"] = int(owen_texts["nextDay"]) + 1
		return
	# A due text waits while the last one is still unanswered.
	if day < int(owen_texts["nextDay"]) or owen_texts["active"] != null:
		return
	send_next()
	owen_texts["nextDay"] = day + _roll_interval()


# Picks and sends one text: never-played eligible texts first, then the
# least recently played. A text with needsVein is ineligible while Owen's
# cultivator list is empty. Returns the sent text id, or "" if none fit.
static func send_next() -> String:
	var veins := _owen_veins()
	var entry: Variant = _pick_text(not veins.is_empty())
	if entry == null:
		return ""
	var vars := {}
	if entry.get("needsVein", false):
		vars = _vein_vars(Rng.rand_from(veins))
	var owen_texts: Dictionary = GameState.state["owenTexts"]
	owen_texts["playSeq"] = int(owen_texts["playSeq"]) + 1
	owen_texts["played"][entry["id"]] = owen_texts["playSeq"]
	owen_texts["active"] = { "id": entry["id"], "vars": vars }
	Messages.append(CONTACT_ID, "them", String(entry["text"]).format(vars))
	return entry["id"]


# The pending text's reply options, templated -- empty when nothing awaits.
static func active_replies() -> Array[String]:
	var result: Array[String] = []
	var entry: Variant = _active_entry()
	if entry == null:
		return result
	var vars: Dictionary = GameState.state["owenTexts"]["active"]["vars"]
	for reply in entry["replies"]:
		result.append(String(reply["text"]).format(vars))
	return result


# Sends the player's reply and Owen's follow-up; a correct answer to a
# question grants cultivating XP (cultivatorActionXp, capped by his skill cap).
static func reply(index: int) -> Dictionary:
	var entry: Variant = _active_entry()
	var owen_texts: Dictionary = GameState.state["owenTexts"]
	if entry == null:
		owen_texts["active"] = null
		return { "ok": false, "reason": "Nothing to reply to." }
	if index < 0 or index >= entry["replies"].size():
		return { "ok": false, "reason": "No such reply." }
	var chosen: Dictionary = entry["replies"][index]
	var vars: Dictionary = owen_texts["active"]["vars"]
	owen_texts["active"] = null
	Messages.append(CONTACT_ID, "player", String(chosen["text"]).format(vars))
	Messages.append(CONTACT_ID, "them", String(chosen["response"]).format(vars))
	Messages.mark_read(CONTACT_ID)
	var correct: bool = chosen.get("correct", false)
	if correct:
		Contacts.award_contact_xp(CONTACT_ID, "cultivating", GameData.CULTIVATOR_ACTION_XP)
	EventBus.state_changed.emit()
	return { "ok": true, "correct": correct }


static func _roll_interval() -> int:
	return Rng.randi_range(int(GameData.OWEN_TEXTS["intervalMinDays"]), int(GameData.OWEN_TEXTS["intervalMaxDays"]))


static func _pick_text(has_vein: bool) -> Variant:
	var played: Dictionary = GameState.state["owenTexts"]["played"]
	var unplayed: Array = []
	var least_recent: Variant = null
	for entry in GameData.OWEN_TEXTS["texts"]:
		if entry.get("needsVein", false) and not has_vein:
			continue
		if not played.has(entry["id"]):
			unplayed.append(entry)
		elif least_recent == null or int(played[entry["id"]]) < int(played[least_recent["id"]]):
			least_recent = entry
	if not unplayed.is_empty():
		return Rng.rand_from(unplayed)
	return least_recent


static func _active_entry() -> Variant:
	var active: Variant = GameState.state["owenTexts"]["active"]
	if active == null:
		return null
	for entry in GameData.OWEN_TEXTS["texts"]:
		if entry["id"] == active["id"]:
			return entry
	return null


# Owen's cultivator-list veins that still exist in player.veins.
static func _owen_veins() -> Array:
	var veins: Array = []
	for vein_id in Rooms.cultivator_veins(CONTACT_ID):
		var vein: Variant = Cultivating.find_vein(vein_id)
		if vein != null:
			veins.append(vein)
	return veins


static func _vein_vars(vein: Dictionary) -> Dictionary:
	return {
		"street": String(vein["location"]).split(",")[0],
		"district": GameData.DISTRICTS[vein["district"]]["name"],
		"ore": vein["oreType"],
	}

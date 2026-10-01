class_name ContactTexts
extends RefCounted

# Contacts' random texts (data/contact_texts.json, keyed by contact id).
# Each contact's config sets its gate (gateFlag, requireUnlocked), cadence
# (intervalMinDays..intervalMaxDays, paused per day the contact isn't
# working when pauseWhenNotWorking), hold (holdFlag, holdWhilePending),
# vein templating source (veinSource) and reply rewards (correctReward,
# per-reply reward).
# State: state.contactTexts { contactId: { nextDay, played: { textId:
# playSeq }, playSeq, active: null | { id, vars } } } -- active is the text
# awaiting a reply. Static funcs only.

# Rollover step: runs every configured contact's scheduler in data order.
static func daily_tick() -> void:
	for contact_id in GameData.CONTACT_TEXTS:
		_tick_contact(contact_id)


# Seeds, pauses, or fires one contact's scheduler.
static func _tick_contact(contact_id: String) -> void:
	if not is_open(contact_id):
		return
	var config: Dictionary = GameData.CONTACT_TEXTS[contact_id]
	var texts := _state_for(contact_id)
	var day: int = GameState.state["world"]["day"]
	if texts["nextDay"] == null:
		# Seeded on the first rollover after the gate opens, so the
		# interval counts from the opening day (yesterday).
		texts["nextDay"] = day - 1 + _roll_interval(config)
		return
	if config.get("pauseWhenNotWorking", false) and not Payroll.is_working(contact_id):
		texts["nextDay"] = int(texts["nextDay"]) + 1
		return
	# A due text waits while the last one is still unanswered, or while the
	# contact is busy with another thread.
	if day < int(texts["nextDay"]) or texts["active"] != null or _is_held(contact_id, config):
		return
	send_next(contact_id)
	texts["nextDay"] = day + _roll_interval(config)


# True once the contact's gate is open: gateFlag set (if any) and the
# contact unlocked (if requireUnlocked).
static func is_open(contact_id: String) -> bool:
	var config: Dictionary = GameData.CONTACT_TEXTS.get(contact_id, {})
	if config.is_empty():
		return false
	var gate_flag := String(config.get("gateFlag", ""))
	if gate_flag != "" and not GameState.state["flags"].get(gate_flag, false):
		return false
	if config.get("requireUnlocked", false) \
			and not GameState.state["contacts"].get(contact_id, {}).get("unlocked", false):
		return false
	return true


# True while the contact is busy: holdFlag set, or (holdWhilePending) a
# pending message from them is still open.
static func _is_held(contact_id: String, config: Dictionary) -> bool:
	var hold_flag := String(config.get("holdFlag", ""))
	if hold_flag != "" and GameState.state["flags"].get(hold_flag, false):
		return true
	return config.get("holdWhilePending", false) and not Messages.pending_for(contact_id).is_empty()


# True while the contact's last text still awaits the player's reply.
static func is_awaiting_reply(contact_id: String) -> bool:
	var texts: Variant = GameState.state["contactTexts"].get(contact_id)
	return texts != null and texts["active"] != null


# Picks and sends one text: never-played eligible texts first, then the
# least recently played. A needsVein text is ineligible while the contact's
# vein source is empty, a requireFlag text while its flag is unset. Returns
# the sent text id, or "" if none fit.
static func send_next(contact_id: String) -> String:
	var config: Dictionary = GameData.CONTACT_TEXTS[contact_id]
	var veins := _source_veins(contact_id, config)
	var entry: Variant = _pick_text(contact_id, config, not veins.is_empty())
	if entry == null:
		return ""
	var vars := {}
	if entry.get("needsVein", false):
		vars = _vein_vars(Rng.rand_from(veins))
	var texts := _state_for(contact_id)
	texts["playSeq"] = int(texts["playSeq"]) + 1
	texts["played"][entry["id"]] = texts["playSeq"]
	texts["active"] = { "id": entry["id"], "vars": vars }
	Messages.append(contact_id, "them", String(entry["text"]).format(vars))
	# PROSE-REVIEW: contact text toast.
	Notify.push("%s texted." % Contacts.display_name(contact_id), Notify.CATEGORY_INFO, { Notify.META_CONTACT_ID: contact_id })
	return entry["id"]


# The contact's pending text's reply options, templated -- empty when
# nothing awaits.
static func active_replies(contact_id: String) -> Array[String]:
	var result: Array[String] = []
	var entry: Variant = _active_entry(contact_id)
	if entry == null:
		return result
	var vars: Dictionary = GameState.state["contactTexts"][contact_id]["active"]["vars"]
	for reply in entry["replies"]:
		result.append(String(reply["text"]).format(vars))
	return result


# Sends the player's reply and the contact's follow-up, then grants the
# reply's reward plus the contact's correctReward on a question's correct
# answer.
static func reply(contact_id: String, index: int) -> Dictionary:
	var entry: Variant = _active_entry(contact_id)
	if entry == null:
		if GameState.state["contactTexts"].has(contact_id):
			GameState.state["contactTexts"][contact_id]["active"] = null
		return { "ok": false, "reason": "Nothing to reply to." }
	if index < 0 or index >= entry["replies"].size():
		return { "ok": false, "reason": "No such reply." }
	var texts := _state_for(contact_id)
	var chosen: Dictionary = entry["replies"][index]
	var vars: Dictionary = texts["active"]["vars"]
	texts["active"] = null
	Messages.append(contact_id, "player", String(chosen["text"]).format(vars))
	Messages.append(contact_id, "them", String(chosen["response"]).format(vars))
	Messages.mark_read(contact_id)
	var correct: bool = chosen.get("correct", false)
	if correct:
		_grant(contact_id, GameData.CONTACT_TEXTS[contact_id].get("correctReward", {}))
	_grant(contact_id, chosen.get("reward", {}))
	EventBus.state_changed.emit()
	return { "ok": true, "correct": correct }


# reward: { xp?: { skill, amount }, relation?: int, cash?: int,
# item?: { id, qty } } -- every key optional.
static func _grant(contact_id: String, reward: Dictionary) -> void:
	if reward.has("xp"):
		Contacts.award_contact_xp(contact_id, String(reward["xp"]["skill"]), int(reward["xp"]["amount"]))
	if reward.has("relation"):
		Contacts.award_relation(contact_id, int(reward["relation"]))
	if reward.has("cash"):
		GameState.state["player"]["cash"] += int(reward["cash"])
	if reward.has("item"):
		# Gifted items aren't crafted at any tier -- the untiered "0" bucket.
		Crafting.inventory_add(String(reward["item"]["id"]), 0, int(reward["item"]["qty"]))


# The contact's state entry, created on first use.
static func _state_for(contact_id: String) -> Dictionary:
	var all: Dictionary = GameState.state["contactTexts"]
	if not all.has(contact_id):
		all[contact_id] = new_contact_state()
	return all[contact_id]


static func new_contact_state() -> Dictionary:
	return { "nextDay": null, "played": {}, "playSeq": 0, "active": null }


static func _roll_interval(config: Dictionary) -> int:
	return Rng.randi_range(int(config["intervalMinDays"]), int(config["intervalMaxDays"]))


static func _pick_text(contact_id: String, config: Dictionary, has_vein: bool) -> Variant:
	var played: Dictionary = _state_for(contact_id)["played"]
	var unplayed: Array = []
	var least_recent: Variant = null
	for entry in config["texts"]:
		if entry.get("needsVein", false) and not has_vein:
			continue
		var require_flag := String(entry.get("requireFlag", ""))
		if require_flag != "" and not GameState.state["flags"].get(require_flag, false):
			continue
		if not played.has(entry["id"]):
			unplayed.append(entry)
		elif least_recent == null or int(played[entry["id"]]) < int(played[least_recent["id"]]):
			least_recent = entry
	if not unplayed.is_empty():
		return Rng.rand_from(unplayed)
	return least_recent


static func _active_entry(contact_id: String) -> Variant:
	var texts: Variant = GameState.state["contactTexts"].get(contact_id)
	if texts == null or texts["active"] == null:
		return null
	for entry in GameData.CONTACT_TEXTS.get(contact_id, {}).get("texts", []):
		if entry["id"] == texts["active"]["id"]:
			return entry
	return null


# Veins a needsVein text may name: the contact's own cultivator list
# (veinSource "cultivator") or any of the player's veins ("player").
static func _source_veins(contact_id: String, config: Dictionary) -> Array:
	if config.get("veinSource", "player") == "player":
		return GameState.state["player"]["veins"].duplicate()
	var veins: Array = []
	for vein_id in Rooms.cultivator_veins(contact_id):
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

class_name KeyMembers
extends RefCounted

# Faction key members (data/factions.json keyMembers/speaker, R§3.10 "Key
# members"): the named contacts every faction move, warning, offer and gift
# goes through. Static funcs only.

const UNLOCK_FIRST_MESSAGE := "firstMessage"
const UNLOCK_QUEST := "quest"
const SEAT_SPEAKER := "speaker"
const SEAT_LIEUTENANT := "lieutenant"


static func members(faction_id: String) -> Array:
	return GameData.FACTIONS.get(faction_id, {}).get("keyMembers", [])


static func member(contact_id: String) -> Dictionary:
	for faction_id in GameData.FACTIONS.keys():
		for m in members(faction_id):
			if m["contactId"] == contact_id:
				return m
	return {}


static func faction_of(contact_id: String) -> String:
	for faction_id in GameData.FACTIONS.keys():
		for m in members(faction_id):
			if m["contactId"] == contact_id:
				return faction_id
	return ""


# The faction's initial leader (data `speaker`), or "".
static func default_leader(faction_id: String) -> String:
	return str(GameData.FACTIONS.get(faction_id, {}).get("speaker", ""))


# Key members who can lead (seat speaker or lieutenant), in data order.
static func contenders(faction_id: String) -> Array:
	return members(faction_id).filter(func(m): return m.get("seat", "") in [SEAT_SPEAKER, SEAT_LIEUTENANT])


# Hidden standing (0-100) of each contender, keyed by contact id.
static func starting_standing(faction_id: String) -> Dictionary:
	var standing := {}
	for m in contenders(faction_id):
		standing[m["contactId"]] = int(m.get("startStanding", 50))
	return standing


# The contender currently leading faction_id (state.factions[id].leader).
static func leader_of(faction_id: String) -> String:
	var faction: Dictionary = GameState.state["factions"].get(faction_id, {})
	return str(faction.get("leader", default_leader(faction_id)))


# The contact id of the key member who speaks for faction_id (its leader), or "".
static func speaker_for(faction_id: String) -> String:
	return leader_of(faction_id)


# A "quest" member speaks only once their questline has unlocked them; a
# "firstMessage" member unlocks on their first message.
static func can_speak(faction_id: String) -> bool:
	var contact_id := speaker_for(faction_id)
	var contact: Dictionary = GameState.state["contacts"].get(contact_id, {})
	if contact.is_empty():
		return false
	if contact["unlocked"]:
		return true
	return member(contact_id).get("unlock", UNLOCK_FIRST_MESSAGE) == UNLOCK_FIRST_MESSAGE


# Unlocks a locked key member and sends their intro line, if any. No-op once
# unlocked.
static func introduce(contact_id: String) -> void:
	var contact: Dictionary = GameState.state["contacts"].get(contact_id, {})
	if contact.is_empty() or contact["unlocked"]:
		return
	contact["unlocked"] = true
	var intro: String = member(contact_id).get("intro", "")
	if intro != "":
		Messages.append(contact_id, "them", intro)
	EventBus.state_changed.emit()


# Sends text from faction_id's speaker, introducing them first if needed.
# A non-empty kind queues it as an actionable pending message (Messages.
# queue_pending). Returns false, sending nothing, when the speaker can't speak.
static func send(faction_id: String, text: String, kind: String = "", payload: Dictionary = {}) -> bool:
	if not can_speak(faction_id):
		return false
	var contact_id := speaker_for(faction_id)
	introduce(contact_id)
	if kind == "":
		Messages.append(contact_id, "them", text)
	else:
		Messages.queue_pending(contact_id, kind, text, payload)
	return true


# ── Standing and succession (R§3.10 "Key members") ──────────────────────
# Each contender's hidden standing moves by data weights (faction_incidents.json
# `succession.weights`); a challenger who stays `margin` above the leader for
# `days` daily ticks takes over. state.factions[id].succession =
# { challenger, days, day, from, to } (day/from/to = the last change; day −1 = none).

const ACT_HOSTILE := "hostileAct"
const ACT_PEACE := "peaceDeal"
const OUTLOOK_HAWK := "hawk"
const OUTLOOK_DOVE := "dove"


static func new_succession() -> Dictionary:
	return { "challenger": "", "days": 0, "day": -1, "from": "", "to": "" }


static func _scfg() -> Dictionary:
	return GameData.FACTION_INCIDENTS["succession"]


static func _weight(key: String) -> int:
	return int(_scfg()["weights"][key])


static func standing_of(contact_id: String) -> int:
	return int(GameState.state["factions"].get(faction_of(contact_id), {}).get("standing", {}).get(contact_id, 0))


# Moves a contender's standing, clamped 0–100. No-op for non-contenders.
static func adjust_standing(contact_id: String, delta: int) -> void:
	var standing: Dictionary = GameState.state["factions"].get(faction_of(contact_id), {}).get("standing", {})
	if standing.has(contact_id) and delta != 0:
		standing[contact_id] = clampi(int(standing[contact_id]) + delta, 0, 100)


# A favour asked by contact_id was kept or failed.
static func note_favour(contact_id: String, kept: bool) -> void:
	adjust_standing(contact_id, _weight("favourKept" if kept else "favourFailed"))


# An objective of `questline` completed: its contender (`want`) gains.
static func note_quest_step(questline: String) -> void:
	for faction_id in GameData.FACTIONS.keys():
		for m in contenders(faction_id):
			if m.get("want", "") == questline:
				adjust_standing(m["contactId"], _weight("questStep"))


# A player act toward faction_id (ACT_HOSTILE helps its hawks, ACT_PEACE its
# doves); the opposite outlook loses the same.
static func note_player_act(faction_id: String, act: String) -> void:
	var favoured := OUTLOOK_HAWK if act == ACT_HOSTILE else OUTLOOK_DOVE
	for m in contenders(faction_id):
		var outlook: String = m.get("outlook", "")
		if outlook == favoured:
			adjust_standing(m["contactId"], _weight(act))
		elif outlook != "":
			adjust_standing(m["contactId"], -_weight(act))


# faction_id lost a war: its leader's standing drops.
static func note_war_loss(faction_id: String) -> void:
	adjust_standing(leader_of(faction_id), _weight("warLoss"))


# Daily step: advances each faction's challenge and installs a challenger whose
# lead has held long enough.
static func daily_tick() -> void:
	for faction_id in GameState.state["factions"].keys():
		_update_challenge(faction_id)


static func _update_challenge(faction_id: String) -> void:
	var faction: Dictionary = GameState.state["factions"][faction_id]
	var leader := leader_of(faction_id)
	var succession: Dictionary = faction["succession"]
	var standing: Dictionary = faction["standing"]
	var challenger := ""
	for m in contenders(faction_id):
		var id: String = m["contactId"]
		if id != leader and (challenger == "" or int(standing[id]) > int(standing[challenger])):
			challenger = id
	if challenger == "" or int(standing[challenger]) - int(standing.get(leader, 0)) < int(_scfg()["margin"]):
		succession["challenger"] = ""
		succession["days"] = 0
		return
	if succession["challenger"] == challenger:
		succession["days"] = int(succession["days"]) + 1
	else:
		succession["challenger"] = challenger
		succession["days"] = 1
	if int(succession["days"]) >= int(_scfg()["days"]):
		faction["leader"] = challenger
		faction["succession"] = { "challenger": "", "days": 0, "day": int(GameState.state["world"]["day"]), "from": leader, "to": challenger }


# FactionAI's multiplier on a faction's aggressionPersonality: the leader's
# aggressionMult relative to the initial leader's, so an unchanged faction is ×1.
static func aggression_scale(faction_id: String) -> float:
	var base := float(member(default_leader(faction_id)).get("aggressionMult", 1.0))
	var current := float(member(leader_of(faction_id)).get("aggressionMult", base))
	return current / base if base > 0.0 else 1.0


# How far the leader's relationBaseline sits from the initial leader's.
static func baseline_shift(faction_id: String) -> int:
	var base := int(member(default_leader(faction_id)).get("relationBaseline", 0))
	return int(member(leader_of(faction_id)).get("relationBaseline", base)) - base

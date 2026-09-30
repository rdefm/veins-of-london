class_name KeyMembers
extends RefCounted

# Faction key members (data/factions.json keyMembers/speaker, R§3.10 "Key
# members"): the named contacts every faction move, warning, offer and gift
# goes through. Static funcs only.

const UNLOCK_FIRST_MESSAGE := "firstMessage"
const UNLOCK_QUEST := "quest"


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


# The contact id of the key member who speaks for faction_id, or "".
static func speaker_for(faction_id: String) -> String:
	return str(GameData.FACTIONS.get(faction_id, {}).get("speaker", ""))


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

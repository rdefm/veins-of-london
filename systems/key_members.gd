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

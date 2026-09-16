class_name Messages
extends RefCounted

# Messages app's data layer. Two state trees:
#   state.messages[contactId] = [ { from: "them"|"player", text, day, read } ]
#   state.pendingMessages = [ { id, contactId, kind, payload, text } ]
#
# pendingMessages is the generic runtime-delivery road (spec §5.3): `kind` IS
# the event id start_event() is called with; resolve_pending() removes an
# entry once its action-bar button starts that event.

const CAP := 50


static func append(contact_id: String, from: String, text: String) -> void:
	var messages: Dictionary = GameState.state["messages"]
	if not messages.has(contact_id):
		messages[contact_id] = []
	var thread: Array = messages[contact_id]
	thread.append({
		"from": from,
		"text": text,
		"day": GameState.state["world"]["day"],
		# a message the player sent is trivially already "read" -- only
		# incoming ("them") messages ever carry the unread dot.
		"read": from == "player",
	})
	while thread.size() > CAP:
		thread.remove_at(0)
	EventBus.state_changed.emit()


static func mark_read(contact_id: String) -> void:
	for msg in GameState.state["messages"].get(contact_id, []):
		msg["read"] = true
	EventBus.state_changed.emit()


static func has_unread(contact_id: String) -> bool:
	for msg in GameState.state["messages"].get(contact_id, []):
		if not msg["read"]:
			return true
	return false


# PhoneNav.select_conversation() needs the actual count, not just
# has_unread()'s bool, to work out how much of the thread predates this open.
static func unread_count(contact_id: String) -> int:
	var count := 0
	for msg in GameState.state["messages"].get(contact_id, []):
		if not msg["read"]:
			count += 1
	return count


static func has_any_unread() -> bool:
	for contact_id in GameState.state["messages"].keys():
		if has_unread(contact_id):
			return true
	return false


static func queue_pending(contact_id: String, kind: String, text: String, payload: Dictionary = {}) -> void:
	append(contact_id, "them", text)
	var id := str(Time.get_ticks_usec()) + str(Rng.randi_range(1000, 999999))
	GameState.state["pendingMessages"].append({
		"id": id, "contactId": contact_id, "kind": kind, "payload": payload, "text": text,
	})
	EventBus.state_changed.emit()


static func pending_for(contact_id: String) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for entry in GameState.state["pendingMessages"]:
		if entry["contactId"] == contact_id:
			entries.append(entry)
	return entries


static func resolve_pending(id: String) -> void:
	var pending: Array = GameState.state["pendingMessages"]
	for i in range(pending.size()):
		if pending[i]["id"] == id:
			pending.remove_at(i)
			EventBus.state_changed.emit()
			return

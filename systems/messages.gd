class_name Messages
extends RefCounted

# collective1-03: the Messages app's data layer. Static funcs only, mirroring
# systems/notify.gd and systems/bank.gd's append-and-evict-from-front shape
# (see CAP). Two state trees:
#
#   state.messages[contactId] = [ { from: "them"|"player", text, day, read } ]
#   state.pendingMessages = [ { id, contactId, kind, payload } ]
#
# pendingMessages is the generic runtime-delivery road (spec §5.3): any
# system can queue_pending() to text the player something with a follow-up
# action, the same "context" road systems/raiding.gd already uses to hand a
# runtime site_id to an event — `kind` here IS the event id start_event()
# is called with, and `payload` is passed straight through as its context.
# The entry is removed (resolve_pending) once its action bar button is
# tapped and the event actually starts.

const CAP := 50

# 83-contacts-archie-james-sms-port: Archie and James used to stay on their
# own bespoke SMS screens (scenes/screens/sms_archie*.gd, deleted by this
# ticket), deliberately excluded from the new Messages app -- spec §5.2:
# "Migration gets its own ticket once the new renderer has proven itself."
# That ticket is this one: their content now flows through append()/
# queue_pending() like every other contact, so there's no exclusion list
# left to keep.


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


static func has_any_unread() -> bool:
	for contact_id in GameState.state["messages"].keys():
		if has_unread(contact_id):
			return true
	return false


static func queue_pending(contact_id: String, kind: String, text: String, payload: Dictionary = {}) -> void:
	append(contact_id, "them", text)
	var id := str(Time.get_ticks_usec()) + str(Rng.randi_range(1000, 999999))
	GameState.state["pendingMessages"].append({
		"id": id, "contactId": contact_id, "kind": kind, "payload": payload,
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


# Most-recent-activity-first list of contact ids the Messages app should
# list: every unlocked contact, Archie/James included since 83-contacts-
# archie-james-sms-port. "Contacts appear as they unlock" (spec §5.2) — a
# contact with no messages yet (unlocked but nothing sent) sorts last, in
# dictionary iteration order (data insertion order), which is deterministic.
static func conversation_contact_ids() -> Array[String]:
	var contacts: Dictionary = GameState.state["contacts"]
	var ids: Array[String] = []
	for contact_id in contacts.keys():
		if contacts[contact_id]["unlocked"]:
			ids.append(contact_id)
	ids.sort_custom(func(a, b): return _last_activity_day(a) > _last_activity_day(b))
	return ids


static func _last_activity_day(contact_id: String) -> int:
	var thread: Array = GameState.state["messages"].get(contact_id, [])
	if thread.is_empty():
		return -1
	return thread[thread.size() - 1]["day"]

class_name Notify
extends RefCounted

# Convention helpers for the notifications list in GameState.state.
# Static funcs only — never instantiated.
#
# Entries are pure data (id, text, seen, day, category) — no Timer, Node, or
# Callable ever enters this array (ticket 04). dismiss() only flips `seen`;
# it never deletes, since the log is meant to be a persistent, browsable
# history (ticket 10's Notifications app) — NotificationToast (fade timing,
# the max-2-visible queue, combat suppression) is the only thing that treats
# `seen` as "stop showing this as a toast."

const LOG_CAP := 50

# Taxonomy (bugfixes ticket 61): every push() carries one of these, used by
# NotificationToast to colour-code entries so they read apart from each
# other and from the top-bar buttons they sit near. Purely a display
# concern — push() only validates the value, never acts on its meaning.
const CATEGORY_INFO := "info"
const CATEGORY_SUCCESS := "success"
const CATEGORY_WARNING := "warning"
const CATEGORY_DANGER := "danger"
const VALID_CATEGORIES: Array[String] = [CATEGORY_INFO, CATEGORY_SUCCESS, CATEGORY_WARNING, CATEGORY_DANGER]


static func push(text: String, category: String = CATEGORY_INFO) -> Dictionary:
	if not VALID_CATEGORIES.has(category):
		category = CATEGORY_INFO
	var id := str(Time.get_ticks_usec()) + str(Rng.randi_range(1000, 999999))
	var day: int = GameState.state["world"]["day"]
	var notification := { "id": id, "text": text, "seen": false, "day": day, "category": category }
	var notifications: Array = GameState.state["notifications"]
	notifications.append(notification)
	while notifications.size() > LOG_CAP:
		notifications.remove_at(0)
	EventBus.notification_pushed.emit()
	EventBus.state_changed.emit()
	return notification


static func dismiss(id: String) -> void:
	var notifications: Array = GameState.state["notifications"]
	for notification in notifications:
		if notification.get("id") == id:
			notification["seen"] = true
			break
	EventBus.state_changed.emit()

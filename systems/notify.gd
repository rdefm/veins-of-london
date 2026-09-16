class_name Notify
extends RefCounted

# Convention helpers for the notifications list in GameState.state.
# Static funcs only — never instantiated. Entries are pure data (id, text,
# seen, day, category); dismiss() only flips `seen`, it never deletes, since
# the log is a persistent, browsable history.

const LOG_CAP := 50

# Taxonomy: every push() carries one of these. Purely a display concern —
# push() only validates the value; no current renderer reads it back.
const CATEGORY_INFO := "info"
const CATEGORY_SUCCESS := "success"
const CATEGORY_WARNING := "warning"
const CATEGORY_DANGER := "danger"
const VALID_CATEGORIES: Array[String] = [CATEGORY_INFO, CATEGORY_SUCCESS, CATEGORY_WARNING, CATEGORY_DANGER]

# Flag CombatScreen stamps on a mid-fight combat-log line; top_bar.gd's
# combat-suppression check (ui-vision.md §5) reads it for the
# hold-while-combat-active rule.
const META_COMBAT_LOG := "combatLog"


# `meta`: optional extra pure-data fields merged onto the entry, e.g.
# `{"veinId": ...}` so phone.gd can render a Defend button on that entry.
static func push(text: String, category: String = CATEGORY_INFO, meta: Dictionary = {}) -> Dictionary:
	if not VALID_CATEGORIES.has(category):
		category = CATEGORY_INFO
	var id := str(Time.get_ticks_usec()) + str(Rng.randi_range(1000, 999999))
	var day: int = GameState.state["world"]["day"]
	var notification := { "id": id, "text": text, "seen": false, "day": day, "category": category }
	for key in meta:
		notification[key] = meta[key]
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

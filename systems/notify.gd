class_name Notify
extends RefCounted

# Convention helpers for the notifications list in GameState.state.
# Static funcs only — never instantiated.
#
# Entries are pure data (id, text, seen, day, category) — no Timer, Node, or
# Callable ever enters this array (ticket 04). dismiss() only flips `seen`;
# it never deletes, since the log is meant to be a persistent, browsable
# history (ticket 10's Notifications app, which reads it back but doesn't
# render read/unread differently). Bugfixes ticket 107 retired the only
# consumer that gave `seen` display meaning (the old NotificationToast's
# fade/queue logic, which stopped showing an entry as a toast once it was
# seen) — top_bar.gd's merged board now shows the most recent entries
# regardless of `seen`, so nothing currently calls dismiss() outside tests.

const LOG_CAP := 50

# Taxonomy (bugfixes ticket 61): every push() carries one of these. Purely a
# display concern — push() only validates the value, never acts on its
# meaning; no current renderer reads it back (field-kit-chrome ticket 02's
# dot-matrix board dropped the old per-category colour-coding this taxonomy
# originally supported).
const CATEGORY_INFO := "info"
const CATEGORY_SUCCESS := "success"
const CATEGORY_WARNING := "warning"
const CATEGORY_DANGER := "danger"
const VALID_CATEGORIES: Array[String] = [CATEGORY_INFO, CATEGORY_SUCCESS, CATEGORY_WARNING, CATEGORY_DANGER]

# field-kit-chrome ticket 03: the `meta` flag CombatScreen stamps on a
# mid-fight combat-log line it pushes here -- the one thing
# top_bar.gd's combat-suppression check (ui-vision.md §5's 2026-09-11
# amendment; the check itself moved from notification_toast.gd to
# top_bar.gd's merged board in bugfixes ticket 107) reads to decide
# whether an entry bypasses the hold-while-combat-active rule. Every
# other notification source omits this key entirely (falsy via
# Dictionary.get()'s default), so they keep being filtered out of the
# board's eligible pool exactly as before.
const META_COMBAT_LOG := "combatLog"


# `meta` (75-vein-raid-defend-button): optional extra pure-data fields
# merged onto the entry -- e.g. `{"veinId": ...}` on the alarm-raid warning,
# so the Notifications app (phone.gd's _build_notification_row()) can render
# a Defend button on that specific entry without a separate lookup table.
# Every existing caller omits it and is unaffected.
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

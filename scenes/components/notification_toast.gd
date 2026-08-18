class_name NotificationToast
extends Control

# Renders up to MAX_VISIBLE unseen notifications as auto-fading toasts,
# queuing overflow and holding everything while combat is active (ticket
# 04). Tapping a toast and its fade timer expiring both just call
# Notify.dismiss(id) — that only flips the log entry's `seen` flag, so
# dismissing a toast never deletes it from the persistent log and never
# navigates anywhere. All fade/queue timing lives here, never in
# GameState — the state tree only ever holds the pure {id, text, seen,
# day} entries systems/notify.gd writes.

const MAX_VISIBLE := 2
const FADE_SECONDS := 4.0
const FADE_IN_SECONDS := 0.15
const FADE_OUT_SECONDS := 0.3

var _entries_container: VBoxContainer
var _visible_ids: Array[String] = []
var _rows: Dictionary = {}  # id:String -> Control


func _ready() -> void:
	UI.anchor_full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_entries_container = VBoxContainer.new()
	UI.anchor_top_wide(_entries_container)
	_entries_container.offset_top = UI.top_bar_clearance()  # clears the persistent top bar (incl. its notch inset)
	_entries_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_entries_container)

	EventBus.notification_pushed.connect(_refresh)
	EventBus.state_changed.connect(_refresh)
	_refresh()


# Combat suppression: while state.combat.active is true, nothing renders
# and nothing is marked seen — entries just hold in the log. The same
# _refresh() that runs on every state_changed (including combat start/end,
# since Combat always emits it around both) naturally drains the queue
# again the moment combat ends, with no dedicated signal needed.
func _refresh() -> void:
	if GameState.state["combat"]["active"]:
		_clear_all_rows()
		return

	var by_id: Dictionary = {}
	for notification in GameState.state["notifications"]:
		by_id[notification["id"]] = notification

	for i in range(_visible_ids.size() - 1, -1, -1):
		var id: String = _visible_ids[i]
		var notification = by_id.get(id)
		if notification == null or notification["seen"]:
			_remove_row(id, true)
			_visible_ids.remove_at(i)

	while _visible_ids.size() < MAX_VISIBLE:
		var next_id := _next_queued_id()
		if next_id == "":
			break
		_visible_ids.append(next_id)
		_add_row(by_id[next_id])


# Oldest unseen, not-already-visible entry — the queue drains in push order.
func _next_queued_id() -> String:
	for notification in GameState.state["notifications"]:
		if not notification["seen"] and not _visible_ids.has(notification["id"]):
			return notification["id"]
	return ""


func _add_row(notification: Dictionary) -> void:
	var id: String = notification["id"]
	var entry := Button.new()
	entry.text = notification["text"]
	entry.mouse_filter = Control.MOUSE_FILTER_STOP
	entry.pressed.connect(func(): Notify.dismiss(id))
	_entries_container.add_child(entry)
	_rows[id] = entry

	var timer := Timer.new()
	timer.wait_time = FADE_SECONDS
	timer.one_shot = true
	timer.timeout.connect(func(): Notify.dismiss(id))
	entry.add_child(timer)
	# Tests build a NotificationToast without adding it to a live scene
	# tree (same pattern as test_bag_drawer.gd/test_app_tile.gd) and
	# simulate expiry/taps by emitting signals directly — Timer.start()
	# and create_tween() both require a live tree, and would either
	# error or silently no-op there, so every tree-dependent call below
	# is guarded the same way: skip the animation, land on the resting
	# value immediately, so the logical (_visible_ids/_rows) state this
	# component's tests assert on is never contingent on a live tree.
	if entry.is_inside_tree():
		timer.start()
		entry.modulate.a = 0.0
		var fade_in := entry.create_tween()
		fade_in.tween_property(entry, "modulate:a", 1.0, FADE_IN_SECONDS)


# animate: false for combat suppression (_clear_all_rows) — combat.active
# means "do not render at all," this frame, not "fade out over the next
# 0.3s while the fight starts," so that path always removes instantly.
func _remove_row(id: String, animate: bool) -> void:
	if not _rows.has(id):
		return
	var row: Control = _rows[id]
	_rows.erase(id)
	if animate and row.is_inside_tree():
		# The queue's next entry (added by the _refresh() call this is
		# part of) already occupies its own slot beneath this one in
		# _entries_container — this row lingers, fading in place, until
		# the tween frees it, which is what reads as "queues and slides
		# in as earlier ones fade" (ticket 04).
		var fade_out := row.create_tween()
		fade_out.tween_property(row, "modulate:a", 0.0, FADE_OUT_SECONDS)
		fade_out.tween_callback(func():
			_entries_container.remove_child(row)
			row.queue_free()
		)
	else:
		_entries_container.remove_child(row)
		row.queue_free()


func _clear_all_rows() -> void:
	for id in _visible_ids.duplicate():
		_remove_row(id, false)
	_visible_ids.clear()

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

# Category taxonomy colours (bugfixes ticket 61) — same palette event.gd's
# card styling and map_canvas.gd's overlays already draw from (REFERENCE.md
# §"visual language": --amber #c8873a, --slate #4a5568, --success #3a7a52,
# --danger #9b2335). No canonical --info exists there; --slate reads as the
# neutral/informational tone elsewhere (map_canvas.gd district labels), so
# it's reused here rather than inventing a new hue.
const _CATEGORY_COLOURS := {
	"info": Color(0.290196, 0.337255, 0.407843, 1),     # --slate #4a5568
	"success": Color(0.227451, 0.478431, 0.321569, 1),  # --success #3a7a52
	"warning": Color(0.784314, 0.529412, 0.227451, 1),  # --amber #c8873a
	"danger": Color(0.607843, 0.137255, 0.207843, 1),   # --danger #9b2335
}

const MainScript := preload("res://scenes/Main.gd")

var _entries_container: VBoxContainer
var _visible_ids: Array[String] = []
var _rows: Dictionary = {}  # id:String -> Control


func _ready() -> void:
	UI.anchor_full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_entries_container = VBoxContainer.new()
	UI.anchor_top_wide(_entries_container)
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
	# Screen-aware clearance (bugfixes ticket 62): fixed UI.top_bar_clearance()
	# assumes the global 40px TopBar, which undershoots "map"'s own top row
	# once that bar is hidden there (Main.TOP_BAR_HIDDEN_SCREENS) and leaves
	# the toast's first entry overlapping it. Main.toast_top_clearance() owns
	# the per-screen answer, next to the bar-visibility rules it's derived
	# from. Re-derived every refresh, not just _ready(), so navigating
	# onto/off of "map" (state_changed fires on every Nav.go_to) keeps it
	# correct.
	_entries_container.offset_top = MainScript.toast_top_clearance(GameState.state["currentScreen"])

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
	# Button is single-line/clip by default -- a long notification string
	# would run off the visible width instead of reflowing (bugfixes
	# ticket 62) without this.
	entry.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	entry.mouse_filter = Control.MOUSE_FILTER_STOP
	entry.pressed.connect(func(): Notify.dismiss(id))
	_style_row(entry, notification.get("category", "info"))
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


# Card-style left-border stripe (event.gd's tension/craft card treatment) in
# the category's colour, plus a matching font tint, applied to every button
# state so the colour reads whether the toast is idle or mid-tap — a plain
# font_color override alone (map_controls.gd's faction-button pattern) would
# still leave every toast the same shape/background, which is exactly the
# "indistinguishable, easy to mis-tap" complaint this ticket exists to fix.
func _style_row(entry: Button, category: String) -> void:
	var colour: Color = _CATEGORY_COLOURS.get(category, _CATEGORY_COLOURS["info"])

	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.980392, 0.972549, 0.952941, 1)
	box.border_width_left = 4
	box.border_color = colour
	box.corner_radius_top_left = 6
	box.corner_radius_top_right = 6
	box.corner_radius_bottom_right = 6
	box.corner_radius_bottom_left = 6
	box.content_margin_left = 12.0
	box.content_margin_top = 10.0
	box.content_margin_right = 12.0
	box.content_margin_bottom = 10.0

	for state in ["normal", "hover", "pressed", "focus"]:
		entry.add_theme_stylebox_override(state, box)
	entry.add_theme_color_override("font_color", colour)
	entry.add_theme_color_override("font_hover_color", colour)
	entry.add_theme_color_override("font_pressed_color", colour)
	entry.add_theme_color_override("font_focus_color", colour)


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

class_name NotificationToast
extends Control

# Renders up to MAX_VISIBLE unseen notifications as auto-fading rows,
# queuing overflow and holding everything while combat is active (ticket
# 04) -- except entries stamped Notify.META_COMBAT_LOG (field-kit-chrome
# ticket 03, ui-vision.md §5's 2026-09-11 amendment: the mid-fight combat
# ticker routes into this board instead of rendering as its own component
# under the stage), which bypass that hold and render live, competing for
# the same MAX_VISIBLE slots as everything else. Tapping a row and its
# fade timer expiring both just call
# Notify.dismiss(id) — that only flips the log entry's `seen` flag, so
# dismissing a row never deletes it from the persistent log and never
# navigates anywhere. All fade/queue timing lives here, never in
# GameState — the state tree only ever holds the pure {id, text, seen,
# day} entries systems/notify.gd writes.
#
# field-kit-chrome ticket 02 (ui-vision.md §5) retires this file's old
# cream/amber card styling (_style_row()/_CATEGORY_COLOURS) in favour of the
# same electronic dot-matrix departure/platform board top_bar.gd now draws
# (DotMatrixBoard/dot_matrix_font.gd) — rows read as numbered lines on that
# board ("1st ...", "2nd ...") mounted directly beneath the status line so
# the two look like one continuous object, though this stays its own
# script/class so notifications can hide independently of the status line
# on some future screen. Per-category colour coding is dropped along with
# the card styling: a real departure board is one uniform amber, not
# colour-tagged by message type.

const MAX_VISIBLE := 2
const FADE_SECONDS := 4.0
const FADE_IN_SECONDS := 0.15
const FADE_OUT_SECONDS := 0.3

const NOTIFICATION_DOT_SIZE := 2.0
const _ORDINALS := ["1st", "2nd"]

var _entries_container: VBoxContainer
var _visible_ids: Array[String] = []
var _rows: Dictionary = {}    # id:String -> Control (the tappable Button)
var _boards: Dictionary = {}  # id:String -> DotMatrixBoard (that Button's board child)


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


# Combat suppression (narrowed, field-kit-chrome ticket 03): while
# state.combat.active is true, every notification holds in the log except
# entries stamped Notify.META_COMBAT_LOG, which render exactly as they
# would outside combat — nothing marked seen for a held entry, so the same
# _refresh() that runs on every state_changed (including combat start/end,
# since Combat always emits it around both) naturally drains the rest of
# the queue the moment combat ends, with no dedicated signal needed.
func _refresh() -> void:
	# The board is unconditionally visible on every screen this component
	# is mounted on (Main.gd's TOP_BAR_HIDDEN_SCREENS is down to just
	# title/intro, neither of which mounts NotificationToast in practice)
	# so rows always clear the one persistent TopBar, with no per-screen
	# branching needed any more.
	_entries_container.offset_top = UI.top_bar_clearance()

	var combat_active: bool = GameState.state["combat"]["active"]

	# `all_by_id` (every current notification, suppression un-applied) is
	# only consulted below to tell "gone/seen" apart from "held by combat
	# suppression this frame" for the animate decision — `by_id` (filtered)
	# still drives everything else (which entries are eligible to show).
	var all_by_id: Dictionary = {}
	var by_id: Dictionary = {}
	for notification in GameState.state["notifications"]:
		all_by_id[notification["id"]] = notification
		if combat_active and not notification.get(Notify.META_COMBAT_LOG, false):
			continue
		by_id[notification["id"]] = notification

	for i in range(_visible_ids.size() - 1, -1, -1):
		var id: String = _visible_ids[i]
		var notification = by_id.get(id)
		if notification == null or notification["seen"]:
			var raw: Dictionary = all_by_id.get(id, {})
			# combat.active means "do not render at all," this frame, not
			# "fade out over the next 0.3s while the fight starts" -- a row
			# that's actually gone/seen still fades normally (`animate`
			# true); one that's merely newly held because combat just went
			# active (still unseen in the log, just no longer eligible to
			# show) vanishes instantly instead.
			var newly_held_by_combat: bool = combat_active and not raw.is_empty() and not raw["seen"] and not raw.get(Notify.META_COMBAT_LOG, false)
			_remove_row(id, not newly_held_by_combat)
			_visible_ids.remove_at(i)

	while _visible_ids.size() < MAX_VISIBLE:
		var next_id := _next_queued_id(by_id)
		if next_id == "":
			break
		_visible_ids.append(next_id)
		_add_row(by_id[next_id])

	_refresh_row_text(by_id)


# Oldest unseen, not-already-visible, not-currently-held (per `by_id`,
# already filtered for combat suppression above) entry — the queue drains
# in push order.
func _next_queued_id(by_id: Dictionary) -> String:
	for notification in GameState.state["notifications"]:
		var id: String = notification["id"]
		if by_id.has(id) and not notification["seen"] and not _visible_ids.has(id):
			return id
	return ""


# Rank (0 = "1st", 1 = "2nd") comes from position in _visible_ids, so a row
# that shifts up when an earlier one is dismissed gets its ordinal prefix
# re-drawn here too, not just newly-added rows — DotMatrixBoard.set_lines()
# only scrambles the cells that actually changed, so an unmoved row's own
# text stays steady while a shifted one's leading digit flickers into place.
func _refresh_row_text(by_id: Dictionary) -> void:
	for i in _visible_ids.size():
		var id: String = _visible_ids[i]
		var notification: Dictionary = by_id[id]
		var board: DotMatrixBoard = _boards[id]
		board.set_lines([DotMatrixBoard.line(_row_text(i, notification["text"]), NOTIFICATION_DOT_SIZE)])
		_rows[id].custom_minimum_size = board.custom_minimum_size


func _row_text(rank: int, text: String) -> String:
	var ordinal: String = _ORDINALS[rank] if rank < _ORDINALS.size() else "%dth" % (rank + 1)
	return "%s %s" % [ordinal, text]


func _add_row(notification: Dictionary) -> void:
	var id: String = notification["id"]
	var entry := Button.new()
	entry.flat = true
	# The board draws its own full-bleed black background; without clipping,
	# a notification line longer than the board is wide would draw straight
	# past the screen edge instead of being cut off at it (this component
	# has no scroll/wrap mechanism — each notification is one board line,
	# same as a real departure board's per-message row).
	entry.clip_contents = true
	entry.mouse_filter = Control.MOUSE_FILTER_STOP
	entry.pressed.connect(func(): Notify.dismiss(id))

	var board := DotMatrixBoard.new()
	UI.anchor_full_rect(board)
	board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	entry.add_child(board)

	_entries_container.add_child(entry)
	_rows[id] = entry
	_boards[id] = board

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


# animate: false when a still-unseen entry is merely newly held by combat
# suppression starting this frame (field-kit-chrome ticket 03's own
# _refresh() comment) -- combat.active means "do not render at all," this
# frame, not "fade out over the next 0.3s while the fight starts." true
# for every other removal (dismissed, expired, or genuinely gone).
func _remove_row(id: String, animate: bool) -> void:
	if not _rows.has(id):
		return
	var row: Control = _rows[id]
	_rows.erase(id)
	_boards.erase(id)
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

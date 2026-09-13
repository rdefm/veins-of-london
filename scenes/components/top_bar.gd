class_name TopBar
extends Control

const RaidAlarmsSystem := preload("res://systems/raid_alarms.gd")

# Persistent top bar (D4): cash, day/time-blocks, the global bag button, and
# (bugfixes ticket 107) the scrolling notification log -- all on one
# electronic dot-matrix departure/platform board (amber-on-black, rendered
# via DotMatrixBoard/dot_matrix_font.gd's multi-line support). The status
# line is always the board's line 0; up to MAX_VISIBLE_NOTIFICATIONS more
# lines follow it, one per recent notification, ranked "1st"/"2nd" same as
# the retired NotificationToast used. Ticket 107 folded that separate class
# in here: it used to be its own script/Control mounted flush beneath this
# one so the two *read* as one continuous board without *being* one Control
# -- rows faded on a timer, capped at 2 visible with the rest held in a
# queue. That's gone. There is now exactly one persistent board, one
# DotMatrixBoard, and notification rows only ever leave view by being
# displaced off the top by a newer one -- never a fade, never a tap-to-
# dismiss. `seen` (systems/notify.gd) still exists for the Notifications
# app's own bookkeeping, but this board no longer reads or writes it: which
# rows show is purely "the most recent eligible entries," recomputed fresh
# on every refresh.
#
# Main.gd shows this on every in-game screen except title/intro (it was
# previously also hidden on "map" and the HQ full-bleed sub-views -- see
# Main.gd's TOP_BAR_HIDDEN_SCREENS comment) so raid/notification alerts are
# never missed and the bag button keeps working everywhere, mid-event and
# mid-combat included (D4.4).

const BAR_HEIGHT := 80.0
const STATUS_DOT_SIZE := 2.0
const NOTIFICATION_DOT_SIZE := 2.0
const MAX_VISIBLE_NOTIFICATIONS := 2
const _ORDINALS := ["1st", "2nd"]
const _SIDE_MARGIN := 4.0

var _board: DotMatrixBoard
var _bag_button: Button


func _ready() -> void:
	UI.anchor_top_wide(self)
	_apply_safe_area_offsets()

	# The board fills the whole strip (including behind the bag button) so
	# the entire row reads as one black board rather than a black board with
	# a hole cut out of it — the button is a real interactive Control drawn
	# on top, not part of the dot-matrix text itself.
	_board = DotMatrixBoard.new()
	UI.anchor_full_rect(_board)
	# Bugfixes ticket 01: keep the bag button's own footprint (icon +
	# margin on both sides) clear of status-line glyphs -- otherwise a long
	# status string draws characters directly under/beside the button,
	# camouflaging it (both are amber-on-black) and running the trailing
	# £<cash> off the screen edge past it.
	_board.reserved_right = UI.ICON_BUTTON_SIZE + _SIDE_MARGIN * 2.0
	add_child(_board)

	# Bugfixes ticket 101: passing LIT_COLOR as icon_button()'s
	# colour_override (rather than add_theme_color_override("font_color", ...)
	# on the Button, which was the previous approach) is required here --
	# the drawn glyph is a separate child _IconGlyph Control
	# (scenes/components/ui.gd), and Godot 4 theme overrides set on a node
	# don't cascade to its children, so the Button-level override never
	# reached the glyph's own get_theme_color("font_color", "Button")
	# lookup. That lookup fell through to the default theme's dark Button
	# font colour, rendering the icon as near-black against this board's
	# black background instead of the intended amber.
	_bag_button = UI.icon_button(Icons.draw_bag, func(): Bag.open(), DotMatrixBoard.LIT_COLOR)
	_bag_button.flat = true
	_bag_button.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	_bag_button.offset_left = -UI.ICON_BUTTON_SIZE - _SIDE_MARGIN
	_bag_button.offset_right = -_SIDE_MARGIN
	_bag_button.offset_top = -UI.ICON_BUTTON_SIZE / 2.0
	_bag_button.offset_bottom = UI.ICON_BUTTON_SIZE / 2.0
	add_child(_bag_button)

	EventBus.state_changed.connect(_refresh)
	_refresh()


# Read-only clock: derives every marker from the authoritative phase on refresh.
func _status_line_text() -> String:
	var world: Dictionary = GameState.state["world"]
	var phase: int = world["timeBlock"]
	return GameData.DAY_CLOCK["dayFormat"] % [GameData.DAY_CLOCK["phaseCues"][phase], world["day"], GameData.TIME_BLOCKS[phase]]


func _progress_line_text() -> String:
	var phase: int = GameState.state["world"]["timeBlock"]
	var markers := ""
	for index in GameData.TIME_BLOCKS.size():
		var kind := "completed" if index < phase else ("current" if index == phase else "remaining")
		markers += GameData.DAY_CLOCK["segments"][kind]
	return "%s £%d" % [markers, GameState.state["player"]["cash"]]


func _refresh() -> void:
	# Bugfixes ticket [pending]: this used to run once from _ready() only.
	# TopBar is built exactly once for the whole app session (Main.gd), right
	# after Main._ready()'s own DisplayServer.screen_set_orientation() call —
	# on some devices the OS-reported safe-area/display-cutout inset isn't
	# settled yet at that exact first frame (it can still be mid-transition
	# from the orientation lock) and later drifts to a different value.
	# Every other consumer of UI.safe_area_top_inset()/top_bar_clearance()
	# either re-derives it on every refresh or is rebuilt fresh per screen
	# navigation (event.gd's image slot, hq.gd, map.gd...), so a TopBar that
	# only ever computed this once at boot silently drifted out of alignment
	# with everyone else for the rest of the session: seen on-device as the
	# bar sitting noticeably lower than it should. Re-applying this every
	# refresh (already wired to EventBus.state_changed) keeps TopBar
	# self-correcting.
	_apply_safe_area_offsets()

	var lines: Array[Dictionary] = [DotMatrixBoard.line(_status_line_text(), STATUS_DOT_SIZE), DotMatrixBoard.line(_progress_line_text(), STATUS_DOT_SIZE)]
	for text in _visible_notification_lines():
		lines.append(DotMatrixBoard.line(text, NOTIFICATION_DOT_SIZE))
	_board.set_lines(lines)


# Bugfixes ticket 107: the merged board's notification rows -- the most
# recent MAX_VISIBLE_NOTIFICATIONS eligible entries from
# GameState.state["notifications"], oldest of the visible set first (so
# "1st"/"2nd" always ranks the same way top-to-bottom a real departure
# board would). Recomputed fresh every refresh from the full log rather
# than tracked as standing state -- there's no fade timer or tap-dismiss
# left to drive a separate queue, so "what's currently showing" is always
# just a pure function of the log's current contents. An entry that's
# never eligible before being displaced by newer ones simply never
# appears, same as a real departure board scrolling past a message you
# didn't catch — the persistent, ungated history lives in the phone's
# Notifications app (systems/notify.gd), not here.
#
# Combat suppression (field-kit-chrome ticket 03, narrowed by
# ui-vision.md §5's 2026-09-11 amendment, preserved unchanged by ticket
# 107): while state.combat.active is true, only entries stamped
# Notify.META_COMBAT_LOG (the mid-fight ticker, combat.gd's
# _push_revealed_log_line()) are eligible -- every other source is
# filtered out of the pool entirely until combat ends, at which point the
# next refresh naturally picks the most recent eligible entries back up.
func _visible_notification_lines() -> Array[String]:
	var combat_active: bool = GameState.state["combat"]["active"]
	var lines: Array[String] = []
	var alarm_count := RaidAlarmsSystem.count()
	if alarm_count > 0 and not combat_active:
		lines.append("RAID ALARM%s ×%d — PHONE" % ["S" if alarm_count != 1 else "", alarm_count])
	var eligible: Array[Dictionary] = []
	for notification in GameState.state["notifications"]:
		if combat_active and not notification.get(Notify.META_COMBAT_LOG, false):
			continue
		eligible.append(notification)

	var notification_capacity: int = MAX_VISIBLE_NOTIFICATIONS - lines.size()
	var start: int = maxi(0, eligible.size() - notification_capacity)
	for i in range(start, eligible.size()):
		if notification_capacity > 0:
			lines.append(_notification_row_text(i - start, eligible[i]["text"]))
	return lines


func _notification_row_text(rank: int, text: String) -> String:
	var ordinal: String = _ORDINALS[rank] if rank < _ORDINALS.size() else "%dth" % (rank + 1)
	return "%s %s" % [ordinal, text]


# Bugfixes ticket 21: flush against offset_top = 0 sits directly under the OS
# notch/front-camera cutout on some devices, hiding money/time/bag behind it.
# Shift the whole bar down by the safe-area top inset (zero on
# desktop/headless) while keeping its own height fixed at BAR_HEIGHT —
# UI.top_bar_clearance() is what every screen that clears "below the TopBar"
# now uses instead of the bare constant, so nothing ends up hidden under the
# bar's new, lower position.
func _apply_safe_area_offsets() -> void:
	offset_top = UI.safe_area_top_inset()
	offset_bottom = UI.top_bar_clearance()

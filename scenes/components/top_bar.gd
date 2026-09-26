class_name TopBar
extends Control

const RaidAlarmsSystem := preload("res://systems/raid_alarms.gd")

# The top departure board (ui-vision.md §5): a DepartureBoardCasing housing
# whose face carries the two status lines (DotMatrixBoard) and a one-message
# NotificationTicker below them. Which notifications reach the ticker, and
# when, is decided here; the ticker's queue is presentation-only. Tapping the
# board opens the Phone's Notifications app, except during combat.

const BAR_HEIGHT := 80.0
const STATUS_DOT_SIZE := 2.0
const _SIDE_MARGIN := 4.0

var _casing: DepartureBoardCasing
var _board: DotMatrixBoard
var _ticker: NotificationTicker
var _bag_button: Button

var _initialized := false
var _last_notification_id: String = ""
var _last_alarm_count := 0
var _held: Array[String] = []  # non-combat messages raised mid-fight, released when it ends


func _ready() -> void:
	UI.anchor_top_wide(self)
	_apply_safe_area_offsets()
	mouse_filter = Control.MOUSE_FILTER_STOP

	var frame := DepartureBoardCasing.FRAME_THICKNESS
	var reserved_right: float = UI.ICON_BUTTON_SIZE + _SIDE_MARGIN * 2.0

	_casing = DepartureBoardCasing.new()
	UI.anchor_full_rect(_casing)
	add_child(_casing)

	_board = DotMatrixBoard.new()
	UI.anchor_full_rect(_board)
	_board.offset_left = frame
	_board.offset_top = frame
	_board.offset_right = -frame
	_board.offset_bottom = -frame
	_board.reserved_right = reserved_right
	add_child(_board)

	_ticker = NotificationTicker.new()
	_ticker.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_ticker.offset_left = frame + DotMatrixBoard.SIDE_PADDING
	_ticker.offset_right = -(frame + reserved_right)
	_ticker.offset_top = frame + _status_lines_height()
	_ticker.offset_bottom = _ticker.offset_top + NotificationTicker.row_height()
	add_child(_ticker)

	var bezel := _BezelOverlay.new()
	UI.anchor_full_rect(bezel)
	add_child(bezel)

	_bag_button = UI.icon_button(Icons.draw_bag, func(): Bag.open(), DotMatrixBoard.LIT_COLOR)
	_bag_button.flat = true
	_bag_button.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	_bag_button.offset_left = -UI.ICON_BUTTON_SIZE - _SIDE_MARGIN - frame
	_bag_button.offset_right = -_SIDE_MARGIN - frame
	_bag_button.offset_top = -UI.ICON_BUTTON_SIZE / 2.0
	_bag_button.offset_bottom = UI.ICON_BUTTON_SIZE / 2.0
	add_child(_bag_button)

	EventBus.state_changed.connect(_refresh)
	_refresh()


# Two status lines plus the gap down to the ticker row, from the face's top.
static func _status_lines_height() -> float:
	return DotMatrixBoard.SIDE_PADDING + 2.0 * (DotMatrixFont.GLYPH_H * STATUS_DOT_SIZE + DotMatrixBoard.LINE_GAP)


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
	_apply_safe_area_offsets()
	var lines: Array[Dictionary] = [DotMatrixBoard.line(_status_line_text(), STATUS_DOT_SIZE), DotMatrixBoard.line(_progress_line_text(), STATUS_DOT_SIZE)]
	_board.set_lines(lines)
	_sync_ticker()


# Feeds the ticker every notification pushed since the last sync. During
# combat only combat-log lines go straight through (ui-vision.md §5); the
# rest are held until the fight ends. A notifications list missing the
# last one seen (boot, load, Rewind, new game) resets the board
# to the latest eligible notification with no animation.
func _sync_ticker() -> void:
	var combat_active: bool = GameState.state["combat"]["active"]
	var notifications: Array = GameState.state["notifications"]
	var start := _first_unseen_index(notifications)
	if start < 0:
		_held.clear()
		_ticker.show_immediately(_latest_eligible_text(notifications, combat_active))
	else:
		for i in range(start, notifications.size()):
			var notification: Dictionary = notifications[i]
			_route(notification["text"], notification.get(Notify.META_COMBAT_LOG, false), combat_active)
	_last_notification_id = str(notifications.back()["id"]) if not notifications.is_empty() else ""

	var alarm_count := RaidAlarmsSystem.count()
	if _initialized and alarm_count > _last_alarm_count:
		_route("RAID ALARM%s ×%d — PHONE" % ["S" if alarm_count != 1 else "", alarm_count], false, combat_active)
	_last_alarm_count = alarm_count

	if not combat_active and not _held.is_empty():
		for text in _held:
			_ticker.enqueue(text)
		_held.clear()
	_initialized = true


func _first_unseen_index(notifications: Array) -> int:
	if not _initialized:
		return -1
	if _last_notification_id.is_empty():
		return 0
	for i in range(notifications.size() - 1, -1, -1):
		if str(notifications[i].get("id")) == _last_notification_id:
			return i + 1
	return -1


func _route(text: String, is_combat_log: bool, combat_active: bool) -> void:
	if combat_active and not is_combat_log:
		_held.append(text)
	else:
		_ticker.enqueue(text)


static func _latest_eligible_text(notifications: Array, combat_active: bool) -> String:
	for i in range(notifications.size() - 1, -1, -1):
		if not combat_active or notifications[i].get(Notify.META_COMBAT_LOG, false):
			return notifications[i]["text"]
	return ""


func _gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed:
		open_notifications_log()


# Board tap routing: the Phone's Notifications app, or nothing mid-combat.
static func open_notifications_log() -> bool:
	if GameState.state["combat"]["active"]:
		return false
	Nav.go_to("phone")
	PhoneNav.open_app("notifications")
	return true


func _apply_safe_area_offsets() -> void:
	offset_top = UI.safe_area_top_inset()
	offset_bottom = UI.top_bar_clearance()


class _BezelOverlay extends Control:
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		DepartureBoardCasing.render_bezel(self, DepartureBoardCasing.face_rect(size))

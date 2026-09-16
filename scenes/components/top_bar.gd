class_name TopBar
extends Control

const RaidAlarmsSystem := preload("res://systems/raid_alarms.gd")


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

	_board = DotMatrixBoard.new()
	UI.anchor_full_rect(_board)
	_board.reserved_right = UI.ICON_BUTTON_SIZE + _SIDE_MARGIN * 2.0
	add_child(_board)

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
	for text in _visible_notification_lines():
		lines.append(DotMatrixBoard.line(text, NOTIFICATION_DOT_SIZE))
	_board.set_lines(lines)


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


func _apply_safe_area_offsets() -> void:
	offset_top = UI.safe_area_top_inset()
	offset_bottom = UI.top_bar_clearance()

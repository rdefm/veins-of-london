class_name StockBar
extends Control

# One item's bar on BizBrief's Production page, 0..max_value. The Keep handle
# hangs left of its value and the cutoff handle right of its value, so they
# sit side by side when they meet and each keeps a full grab area. A pip above
# the cutoff handle names its value. View state only: `changed` fires live
# during a drag and the commit signals fire once on release, where the screen
# calls its system. R§3.6 "Auto-sell".

signal changed(keep: int, cutoff: int)
signal keep_committed(keep: int)
signal cutoff_committed(cutoff: int)

const SELL_ALL_TEXT := "Sell all"
const SELL_NONE_TEXT := "Sell none"

const BAR_HEIGHT := 44.0
const PIP_HEIGHT := 24.0  # pip row above the bar
const PIP_GAP := 2.0
const PIP_PADDING := 6.0
const PIP_FONT_SIZE := 13
const HANDLE_WIDTH := 28.0
const HANDLE_HEIGHT := 36.0
const TRACK_HEIGHT := 12.0
const STOCK_TICK_WIDTH := 2.0
const CONTRACT_ALPHA := 0.45
const SELL_ALPHA := 0.4

enum Handle { NONE, KEEP, CUTOFF }

var max_value := 1
var keep := 0
var cutoff := 0
var held_floor := 0  # Keep plus any covered contract need
var stock := 0
var cutoff_locked := false

var _dragging: int = Handle.NONE
var _grab_offset := 0.0
var _start_keep := 0
var _start_cutoff := 0


func configure(top: int, new_keep: int, new_cutoff: int, new_held_floor: int, new_stock: int, locked: bool) -> void:
	max_value = maxi(top, 1)
	keep = clampi(new_keep, 0, max_value)
	cutoff = clampi(new_cutoff, keep, max_value)
	held_floor = new_held_floor
	stock = new_stock
	cutoff_locked = locked
	custom_minimum_size = Vector2(HANDLE_WIDTH * 4.0, PIP_HEIGHT + BAR_HEIGHT)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()


# The floor for a Keep previewed mid-drag.
func set_held_floor(new_held_floor: int) -> void:
	held_floor = new_held_floor
	queue_redraw()


# The cutoff in words at either end of the bar, else its number.
func pip_text() -> String:
	if cutoff >= max_value:
		return SELL_NONE_TEXT
	if cutoff <= 0:
		return SELL_ALL_TEXT
	return str(cutoff)


func _value_x(value: int) -> float:
	return HANDLE_WIDTH + (size.x - HANDLE_WIDTH * 2.0) * clampf(float(value) / max_value, 0.0, 1.0)


func _x_value(x: float) -> int:
	var track := maxf(size.x - HANDLE_WIDTH * 2.0, 1.0)
	return clampi(roundi((x - HANDLE_WIDTH) / track * max_value), 0, max_value)


# The handle a press grabs: whichever side of the gap between the two handles
# the finger lands on, so the pair splits cleanly even at the same value.
func _pick_handle(x: float) -> int:
	if cutoff_locked:
		return Handle.KEEP
	return Handle.KEEP if x < (_value_x(keep) + _value_x(cutoff)) / 2.0 else Handle.CUTOFF


func _handle_rect(handle: int) -> Rect2:
	var left := _value_x(keep) - HANDLE_WIDTH if handle == Handle.KEEP else _value_x(cutoff)
	return Rect2(left, 0.0, HANDLE_WIDTH, size.y)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		if event.pressed:
			_press(event.position.x)
		else:
			_release()
	elif event is InputEventMouseMotion and _dragging != Handle.NONE:
		accept_event()
		_drag_to(event.position.x)


func _press(x: float) -> void:
	_dragging = _pick_handle(x)
	_start_keep = keep
	_start_cutoff = cutoff
	var anchor := _value_x(keep if _dragging == Handle.KEEP else cutoff)
	_grab_offset = x - anchor if _handle_rect(_dragging).has_point(Vector2(x, 0.0)) else 0.0
	_drag_to(x)


func _drag_to(x: float) -> void:
	var value := _x_value(x - _grab_offset)
	var new_keep := keep
	var new_cutoff := cutoff
	if _dragging == Handle.KEEP:
		new_keep = value
		new_cutoff = maxi(_start_cutoff, value)
	else:
		new_cutoff = maxi(value, keep)
	if new_keep == keep and new_cutoff == cutoff:
		return
	keep = new_keep
	cutoff = new_cutoff
	queue_redraw()
	changed.emit(keep, cutoff)


func _release() -> void:
	var released := _dragging
	_dragging = Handle.NONE
	if released == Handle.KEEP and keep != _start_keep:
		keep_committed.emit(keep)
	elif released == Handle.CUTOFF and cutoff != _start_cutoff:
		cutoff_committed.emit(cutoff)


func _draw() -> void:
	var track_y := _bar_centre_y() - TRACK_HEIGHT / 2.0
	var keep_x := _value_x(keep)
	var floor_x := _value_x(maxi(held_floor, keep))
	var end_x := _value_x(max_value)
	var sell_x := maxf(_value_x(cutoff), floor_x)
	draw_rect(Rect2(HANDLE_WIDTH, track_y, end_x - HANDLE_WIDTH, TRACK_HEIGHT), BizBriefApp.LINE)
	draw_rect(Rect2(sell_x, track_y, end_x - sell_x, TRACK_HEIGHT), Color(BizBriefApp.SIGNAL, SELL_ALPHA))
	draw_rect(Rect2(HANDLE_WIDTH, track_y, keep_x - HANDLE_WIDTH, TRACK_HEIGHT), BizBriefApp.PAPER)
	draw_rect(Rect2(keep_x, track_y, floor_x - keep_x, TRACK_HEIGHT), Color(BizBriefApp.PAPER, CONTRACT_ALPHA))
	var stock_x := _value_x(stock)
	draw_rect(Rect2(stock_x - STOCK_TICK_WIDTH / 2.0, size.y - BAR_HEIGHT, STOCK_TICK_WIDTH, BAR_HEIGHT), BizBriefApp.MUTED)
	_draw_handle(Handle.KEEP, BizBriefApp.PAPER, BizBriefApp.NAVY)
	if cutoff_locked:
		_draw_handle(Handle.CUTOFF, BizBriefApp.LINE, BizBriefApp.MUTED)
		_draw_cutoff_pip(BizBriefApp.LINE, BizBriefApp.MUTED)
	else:
		_draw_handle(Handle.CUTOFF, BizBriefApp.SIGNAL, BizBriefApp.PAPER)
		_draw_cutoff_pip(BizBriefApp.SIGNAL, BizBriefApp.PAPER)


func _bar_centre_y() -> float:
	return size.y - BAR_HEIGHT / 2.0


# Sits over the cutoff handle, held inside the control at either end.
func _draw_cutoff_pip(fill: Color, ink: Color) -> void:
	var font := get_theme_default_font()
	var text := pip_text()
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, PIP_FONT_SIZE).x + PIP_PADDING * 2.0
	var left := clampf(_handle_rect(Handle.CUTOFF).get_center().x - width / 2.0, 0.0, maxf(size.x - width, 0.0))
	var height := PIP_HEIGHT - PIP_GAP
	draw_rect(Rect2(left, 0.0, width, height), fill)
	var baseline := (height + font.get_ascent(PIP_FONT_SIZE) - font.get_descent(PIP_FONT_SIZE)) / 2.0
	draw_string(font, Vector2(left + PIP_PADDING, baseline), text, HORIZONTAL_ALIGNMENT_LEFT, -1, PIP_FONT_SIZE, ink)


func _draw_handle(handle: int, fill: Color, grip: Color) -> void:
	var rect := _handle_rect(handle)
	var body := Rect2(rect.position.x + 1.0, _bar_centre_y() - HANDLE_HEIGHT / 2.0, rect.size.x - 2.0, HANDLE_HEIGHT)
	draw_rect(body, fill)
	var centre := body.get_center()
	for offset in [-4.0, 0.0, 4.0]:
		draw_rect(Rect2(centre.x + offset - 1.0, centre.y - 8.0, 2.0, 16.0), grip)

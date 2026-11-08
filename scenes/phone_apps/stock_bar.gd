class_name StockBar
extends Control

# One bar on BizBrief's Production page, 0..max_value. A Sell-above handle
# (red) with a pip above it naming its value, and an optional Make-to marker
# (gold): a read-only tick on a recipe card, a second draggable handle in the
# Defaults panel. A negative stock hides the stock tick. The two markers are
# independent and may cross. View state only: `changed` fires live during a
# drag and the commit signals fire once on release, where the screen calls its
# system. R§3.6 "Auto-sell".

signal changed(make_to: int, cutoff: int)
signal make_to_committed(make_to: int)
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
const MAKE_TICK_WIDTH := 3.0
const CONTRACT_ALPHA := 0.45
const SELL_ALPHA := 0.4

enum Handle { NONE, MAKE, CUTOFF }

var max_value := 1
var make_to := -1  # negative hides the Make-to marker
var make_to_editable := false
var cutoff := 0
var held_floor := 0  # Sell-above plus any covered contract need
var stock := -1
var cutoff_locked := false

var _dragging: int = Handle.NONE
var _grab_offset := 0.0
var _start_make_to := 0
var _start_cutoff := 0


func configure(top: int, new_make_to: int, new_cutoff: int, new_held_floor: int, new_stock: int, locked: bool, new_make_to_editable: bool = false) -> void:
	max_value = maxi(top, 1)
	make_to = clampi(new_make_to, 0, max_value) if new_make_to >= 0 else -1
	make_to_editable = new_make_to_editable and make_to >= 0
	cutoff = clampi(new_cutoff, 0, max_value)
	held_floor = new_held_floor
	stock = new_stock
	cutoff_locked = locked
	custom_minimum_size = Vector2(HANDLE_WIDTH * 4.0, PIP_HEIGHT + BAR_HEIGHT)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()


# The floor for a Sell-above previewed mid-drag.
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


# The handle a press grabs: the nearest draggable one; at the same value the
# side of the handles the finger lands on decides.
func _pick_handle(x: float) -> int:
	if not make_to_editable:
		return Handle.NONE if cutoff_locked else Handle.CUTOFF
	if cutoff_locked:
		return Handle.MAKE
	var make_x := _value_x(make_to)
	var cutoff_x := _value_x(cutoff)
	if is_equal_approx(make_x, cutoff_x):
		return Handle.MAKE if x < make_x else Handle.CUTOFF
	return Handle.MAKE if absf(x - make_x) < absf(x - cutoff_x) else Handle.CUTOFF


func _handle_rect(handle: int) -> Rect2:
	var centre := _value_x(make_to if handle == Handle.MAKE else cutoff)
	return Rect2(centre - HANDLE_WIDTH / 2.0, 0.0, HANDLE_WIDTH, size.y)


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
	if _dragging == Handle.NONE:
		return
	_start_make_to = make_to
	_start_cutoff = cutoff
	var anchor := _value_x(make_to if _dragging == Handle.MAKE else cutoff)
	_grab_offset = x - anchor if _handle_rect(_dragging).has_point(Vector2(x, 0.0)) else 0.0
	_drag_to(x)


func _drag_to(x: float) -> void:
	if _dragging == Handle.NONE:
		return
	var value := _x_value(x - _grab_offset)
	var new_make_to := make_to
	var new_cutoff := cutoff
	if _dragging == Handle.MAKE:
		new_make_to = value
	else:
		new_cutoff = value
	if new_make_to == make_to and new_cutoff == cutoff:
		return
	make_to = new_make_to
	cutoff = new_cutoff
	queue_redraw()
	changed.emit(make_to, cutoff)


func _release() -> void:
	var released := _dragging
	_dragging = Handle.NONE
	if released == Handle.MAKE and make_to != _start_make_to:
		make_to_committed.emit(make_to)
	elif released == Handle.CUTOFF and cutoff != _start_cutoff:
		cutoff_committed.emit(cutoff)


func _draw() -> void:
	var track_y := _bar_centre_y() - TRACK_HEIGHT / 2.0
	var cutoff_x := _value_x(cutoff)
	var floor_x := _value_x(maxi(held_floor, cutoff))
	var end_x := _value_x(max_value)
	draw_rect(Rect2(HANDLE_WIDTH, track_y, end_x - HANDLE_WIDTH, TRACK_HEIGHT), BizBriefApp.LINE)
	draw_rect(Rect2(floor_x, track_y, end_x - floor_x, TRACK_HEIGHT), Color(BizBriefApp.SIGNAL, SELL_ALPHA))
	draw_rect(Rect2(HANDLE_WIDTH, track_y, cutoff_x - HANDLE_WIDTH, TRACK_HEIGHT), BizBriefApp.PAPER)
	draw_rect(Rect2(cutoff_x, track_y, floor_x - cutoff_x, TRACK_HEIGHT), Color(BizBriefApp.PAPER, CONTRACT_ALPHA))
	if stock >= 0:
		var stock_x := _value_x(stock)
		draw_rect(Rect2(stock_x - STOCK_TICK_WIDTH / 2.0, size.y - BAR_HEIGHT, STOCK_TICK_WIDTH, BAR_HEIGHT), BizBriefApp.MUTED)
	if make_to >= 0:
		if make_to_editable:
			_draw_handle(Handle.MAKE, BizBriefApp.MASTER_MAKE_COLOUR, BizBriefApp.NAVY)
		else:
			var make_x := _value_x(make_to)
			draw_rect(Rect2(make_x - MAKE_TICK_WIDTH / 2.0, size.y - BAR_HEIGHT, MAKE_TICK_WIDTH, BAR_HEIGHT), BizBriefApp.MASTER_MAKE_COLOUR)
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

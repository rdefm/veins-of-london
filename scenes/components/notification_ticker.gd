class_name NotificationTicker
extends Control

# One-row dot-matrix notice line on the top departure board (ui-vision.md §5):
# one message at a time from a presentation-only queue (never in
# GameState.state). Each new message rolls up from below; text wider than the
# row marquee-scrolls until its end is shown; then it holds HOLD_SECONDS
# before the next queued message rolls up. With the queue empty the latest
# message stays, re-running its marquee if it overflows. Taps are the owning
# TopBar's concern; this node ignores the mouse.

const DOT_SIZE := 2.0
const ROLL_SECONDS := 0.35
const HOLD_SECONDS := 4.0
const MARQUEE_SPEED := 40.0  # px per second
const MARQUEE_LEAD_SECONDS := 0.8  # pause on the message's start before scrolling

enum Phase { IDLE, ROLLING, LEAD, SCROLLING, HOLDING }

var phase: Phase = Phase.IDLE
var current_text: String = ""
var _previous_text: String = ""
var _queue: Array[String] = []
var _phase_elapsed: float = 0.0
var _scroll_offset: float = 0.0


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size.y = row_height()
	set_process(false)


static func row_height() -> float:
	return DotMatrixFont.GLYPH_H * DOT_SIZE


func queued() -> Array[String]:
	return _queue.duplicate()


# Puts `text` straight on the board with no animation and clears the queue --
# for boot and for a wholesale state swap (load/Rewind).
func show_immediately(text: String) -> void:
	_queue.clear()
	_previous_text = ""
	current_text = text.to_upper()
	if current_text.is_empty():
		_start_phase(Phase.IDLE)
	else:
		_start_phase(Phase.LEAD if _overflow() > 0.0 else Phase.HOLDING)
	_sync_processing()


func enqueue(text: String) -> void:
	_queue.append(text.to_upper())
	if phase == Phase.IDLE:
		_roll_in_next()
	_sync_processing()


func _process(delta: float) -> void:
	advance(delta)


func advance(delta: float) -> void:
	var remaining := delta
	# A large delta can finish several phases; loop so tests (and hitches)
	# land where real frame-by-frame time would.
	while remaining > 0.0 and phase != Phase.IDLE:
		var budget := _phase_budget()
		var left := budget - _phase_elapsed
		if phase == Phase.SCROLLING:
			left = (_overflow() - _scroll_offset) / MARQUEE_SPEED
		if remaining < left:
			_phase_elapsed += remaining
			if phase == Phase.SCROLLING:
				_scroll_offset += remaining * MARQUEE_SPEED
			remaining = 0.0
		else:
			remaining -= maxf(left, 0.0)
			_finish_phase()
	_sync_processing()
	queue_redraw()


func _phase_budget() -> float:
	match phase:
		Phase.ROLLING:
			return ROLL_SECONDS
		Phase.LEAD:
			return MARQUEE_LEAD_SECONDS
		Phase.HOLDING:
			return HOLD_SECONDS
	return 0.0


func _finish_phase() -> void:
	match phase:
		Phase.ROLLING:
			_previous_text = ""
			_start_phase(Phase.LEAD if _overflow() > 0.0 else Phase.HOLDING)
		Phase.LEAD:
			_start_phase(Phase.SCROLLING)
		Phase.SCROLLING:
			_scroll_offset = _overflow()
			_start_phase(Phase.HOLDING)
		Phase.HOLDING:
			if not _queue.is_empty():
				_roll_in_next()
			elif _overflow() > 0.0:
				_start_phase(Phase.LEAD)
			else:
				_start_phase(Phase.IDLE)


func _roll_in_next() -> void:
	_previous_text = current_text
	current_text = _queue.pop_front()
	_start_phase(Phase.ROLLING)


func _start_phase(next: Phase) -> void:
	phase = next
	_phase_elapsed = 0.0
	if next == Phase.ROLLING or next == Phase.LEAD:
		_scroll_offset = 0.0


func _sync_processing() -> void:
	if is_inside_tree():
		set_process(phase != Phase.IDLE)
		queue_redraw()


func _overflow() -> float:
	return maxf(0.0, DotMatrixFont.text_width(current_text, DOT_SIZE, DotMatrixBoard.CHAR_GAP) - size.x)


func scroll_offset() -> float:
	return _scroll_offset


func _draw() -> void:
	render(self)


func render(target: Object) -> void:
	var row_h := row_height()
	var rise := 0.0
	if phase == Phase.ROLLING:
		rise = _snap(row_h * clampf(_phase_elapsed / ROLL_SECONDS, 0.0, 1.0))
		_draw_text(target, _previous_text, Vector2(0.0, -rise), 0.0)
		_draw_text(target, current_text, Vector2(0.0, row_h - rise), 0.0)
	else:
		_draw_text(target, current_text, Vector2.ZERO, _snap(_scroll_offset))


# Motion moves in whole-dot steps, the way a real LED matrix shifts.
func _snap(px: float) -> float:
	return floorf(px / DOT_SIZE) * DOT_SIZE


func _draw_text(target: Object, text: String, origin: Vector2, scroll: float) -> void:
	var char_width: float = DotMatrixFont.GLYPH_W * DOT_SIZE
	var x := origin.x - scroll
	for i in text.length():
		if x + char_width > 0.0 and x < size.x:
			DotMatrixFont.draw_char(target, Vector2(x, origin.y), text[i], DOT_SIZE, DotMatrixBoard.LIT_COLOR, DotMatrixBoard.DIM_COLOR)
		x += char_width + DotMatrixBoard.CHAR_GAP

class_name DotMatrixBoard
extends Control


const BG_COLOR := Color(0.043137, 0.043137, 0.039216, 1)  # near-black board casing
const LIT_COLOR := Color(1.0, 0.690196, 0.0, 1)
const DIM_COLOR := Color(1.0, 0.690196, 0.0, 0.14)  # unlit dot, same hue -- a real board shows its whole grid, not just lit dots

const CHAR_GAP := 2.0
const LINE_GAP := 4.0
const SIDE_PADDING := 6.0

const SCRAMBLE_DURATION := 0.28
const SCRAMBLE_STEP := 0.045

var reserved_right: float = 0.0

var _target_lines: Array[Dictionary] = []
var _target_chars: Array[Array] = []    # per line, an Array[String] -- resolved final char per cell
var _display_chars: Array[Array] = []   # per line, an Array[String] -- current on-screen char per cell (may lag during a scramble)
var _scramble_seconds_left: Array[Array] = []  # per line, an Array[float] -- remaining scramble seconds per cell (0 = settled)
var _cycle_seconds_left: Array[Array] = []     # per line, an Array[float] -- time until this cell's displayed glyph next re-randomises
var _initialized := false


static func line(text: String, dot_size: float) -> Dictionary:
	return { "text": text, "dot_size": dot_size }


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)


func _draw() -> void:
	render(self)


func render(target: Object) -> void:
	target.draw_rect(Rect2(Vector2.ZERO, size), BG_COLOR, true)

	var text_limit: float = size.x - reserved_right
	var y := SIDE_PADDING
	for line_index in _target_lines.size():
		var dot_size: float = _target_lines[line_index].get("dot_size", 3.0)
		var char_width: float = DotMatrixFont.GLYPH_W * dot_size
		var x := SIDE_PADDING
		var chars: Array = _display_chars[line_index] if line_index < _display_chars.size() else []
		for ch in chars:
			if x + char_width > text_limit:
				break
			DotMatrixFont.draw_char(target, Vector2(x, y), ch, dot_size, LIT_COLOR, DIM_COLOR)
			x += char_width + CHAR_GAP
		y += DotMatrixFont.GLYPH_H * dot_size + LINE_GAP


func set_lines(lines: Array[Dictionary]) -> void:
	var new_target_chars: Array[Array] = _chars_for(lines)

	if not _initialized:
		_target_lines = lines.duplicate(true)
		_target_chars = new_target_chars
		_display_chars = new_target_chars.duplicate(true)
		_scramble_seconds_left = _zeroed_like(new_target_chars)
		_cycle_seconds_left = _zeroed_like(new_target_chars)
		_initialized = true
	else:
		_target_lines = lines.duplicate(true)
		_begin_scramble(new_target_chars)

	custom_minimum_size = required_size()
	if is_inside_tree():
		set_process(_is_scrambling())
		queue_redraw()


func target_text(line_index: int = 0) -> String:
	return _joined(_target_chars, line_index)


func display_text(line_index: int = 0) -> String:
	return _joined(_display_chars, line_index)


func _joined(chars: Array[Array], line_index: int) -> String:
	if line_index >= chars.size():
		return ""
	var out := ""
	for ch in chars[line_index]:
		out += ch
	return out


func required_size() -> Vector2:
	if _target_lines.is_empty():
		return Vector2.ZERO

	var max_width := 0.0
	var total_height := SIDE_PADDING * 2.0
	for i in _target_lines.size():
		var line_data: Dictionary = _target_lines[i]
		var dot_size: float = line_data.get("dot_size", 3.0)
		var text: String = String(line_data.get("text", ""))
		var width := SIDE_PADDING * 2.0 + DotMatrixFont.text_width(text, dot_size, CHAR_GAP)
		max_width = maxf(max_width, width)
		total_height += DotMatrixFont.GLYPH_H * dot_size
		if i < _target_lines.size() - 1:
			total_height += LINE_GAP
	return Vector2(max_width, total_height)


func _chars_for(lines: Array[Dictionary]) -> Array[Array]:
	var out: Array[Array] = []
	for line_data in lines:
		var text: String = String(line_data.get("text", "")).to_upper()
		var chars: Array[String] = []
		for i in text.length():
			chars.append(text[i])
		out.append(chars)
	return out


func _zeroed_like(chars: Array[Array]) -> Array[Array]:
	var out: Array[Array] = []
	for line_chars in chars:
		var zeros: Array[float] = []
		zeros.resize(line_chars.size())
		zeros.fill(0.0)
		out.append(zeros)
	return out


func _begin_scramble(new_target_chars: Array[Array]) -> void:
	var new_display: Array[Array] = []
	var new_scramble: Array[Array] = []
	var new_cycle: Array[Array] = []

	for line_index in new_target_chars.size():
		var new_line: Array = new_target_chars[line_index]
		var old_line: Array = _target_chars[line_index] if line_index < _target_chars.size() else []
		var old_display: Array = _display_chars[line_index] if line_index < _display_chars.size() else []

		var display_line: Array[String] = []
		var scramble_line: Array[float] = []
		var cycle_line: Array[float] = []

		var old_scramble: Array = _scramble_seconds_left[line_index] if line_index < _scramble_seconds_left.size() else []
		var old_cycle: Array = _cycle_seconds_left[line_index] if line_index < _cycle_seconds_left.size() else []

		for char_index in new_line.size():
			var target_char: String = new_line[char_index]
			var unchanged: bool = char_index < old_line.size() and old_line[char_index] == target_char
			if unchanged:
				display_line.append(old_display[char_index] if char_index < old_display.size() else target_char)
				var still_scrambling: float = old_scramble[char_index] if char_index < old_scramble.size() else 0.0
				if still_scrambling > 0.0:
					scramble_line.append(still_scrambling)
					cycle_line.append(old_cycle[char_index] if char_index < old_cycle.size() else SCRAMBLE_STEP)
				else:
					scramble_line.append(0.0)
					cycle_line.append(0.0)
			else:
				display_line.append(DotMatrixFont.random_scramble_char())
				scramble_line.append(SCRAMBLE_DURATION)
				cycle_line.append(SCRAMBLE_STEP)

		new_display.append(display_line)
		new_scramble.append(scramble_line)
		new_cycle.append(cycle_line)

	_target_chars = new_target_chars
	_display_chars = new_display
	_scramble_seconds_left = new_scramble
	_cycle_seconds_left = new_cycle


func _is_scrambling() -> bool:
	for line_seconds in _scramble_seconds_left:
		for t in line_seconds:
			if t > 0.0:
				return true
	return false


func _process(delta: float) -> void:
	advance_scramble(delta)


func advance_scramble(delta: float) -> void:
	for line_index in _scramble_seconds_left.size():
		var scramble_line: Array = _scramble_seconds_left[line_index]
		var cycle_line: Array = _cycle_seconds_left[line_index]
		var display_line: Array = _display_chars[line_index]
		var target_line: Array = _target_chars[line_index]

		for char_index in scramble_line.size():
			var remaining: float = scramble_line[char_index]
			if remaining <= 0.0:
				continue

			remaining -= delta
			if remaining <= 0.0:
				display_line[char_index] = target_line[char_index]
				scramble_line[char_index] = 0.0
				cycle_line[char_index] = 0.0
				continue

			var cycle: float = cycle_line[char_index] - delta
			if cycle <= 0.0:
				display_line[char_index] = DotMatrixFont.random_scramble_char()
				cycle = SCRAMBLE_STEP
			scramble_line[char_index] = remaining
			cycle_line[char_index] = cycle

	if is_inside_tree():
		set_process(_is_scrambling())
		queue_redraw()

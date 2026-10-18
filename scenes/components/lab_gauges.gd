class_name LabGauges
extends RefCounted

# The Lab plate's apparatus gauges and the book's read-only band track.
# Placeholder look: a horizontal 0-100 track with the known band, or a faded
# fuzzy region for a vague step. Gauges report raw input through their own
# committed signal and score nothing themselves.


class StepGauge extends Control:
	var band_low := 0.0
	var band_high := 0.0
	var band_vague := false
	# Set before entering the tree to pulse an outline round the input zone.
	var input_colour := Color(0, 0, 0, 0)
	var pulse_msec := 1200.0
	var pulse_min_alpha := 0.35
	var pulse_max_alpha := 0.8
	var _pulse := 1.0:
		set(value):
			_pulse = value
			queue_redraw()

	func _enter_tree() -> void:
		if input_colour.a <= 0.0:
			return
		var tween := create_tween().set_loops()
		tween.tween_property(self, "_pulse", 0.0, pulse_msec / 2000.0)
		tween.tween_property(self, "_pulse", 1.0, pulse_msec / 2000.0)

	func _draw_input_zone() -> void:
		if input_colour.a <= 0.0:
			return
		var alpha := lerpf(pulse_min_alpha, pulse_max_alpha, _pulse)
		var rect := Rect2(Vector2.ZERO, size)
		draw_rect(rect, Color(input_colour, alpha * 0.15))
		draw_rect(rect.grow(-1.5), Color(input_colour, alpha), false, 3.0)

	# Shows a Lab.step_region() result; {} shows no band.
	func set_region(region: Dictionary) -> void:
		band_low = region.get("low", 0.0)
		band_high = region.get("high", 0.0)
		band_vague = region.get("vague", false)
		queue_redraw()

	func _init() -> void:
		custom_minimum_size = Vector2(0, 56)
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _pressed(event: InputEvent) -> int:
		if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
			return 0
		accept_event()
		return 1 if event.pressed else -1

	func _x(value: float) -> float:
		return size.x * value / 100.0

	func _draw_track() -> Rect2:
		var track := Rect2(Vector2(0, size.y * 0.3), Vector2(size.x, size.y * 0.4))
		draw_rect(track, MapCardStyle.line())
		if band_high <= band_low:
			return track
		var band_colour := Color(MapCardStyle.band(), 0.4) if band_vague else MapCardStyle.band()
		draw_rect(Rect2(Vector2(_x(band_low), track.position.y), Vector2(_x(band_high - band_low), track.size.y)), band_colour)
		return track

	func _draw_needle(value: float) -> void:
		draw_line(Vector2(_x(value), 0), Vector2(_x(value), size.y), MapCardStyle.ink(), 3.0)


# The step-end mark drawn over an apparatus: a tick, or a cross on a fail.
class TickMark extends Control:
	var success := true
	var colour := Color.WHITE

	func _draw() -> void:
		var r := size.x * 0.5
		var c := size * 0.5
		var points := PackedVector2Array([c + Vector2(-r * 0.55, 0), c + Vector2(-r * 0.15, r * 0.45), c + Vector2(r * 0.6, -r * 0.5)])
		if success:
			draw_polyline(points, colour, 8.0, true)
		else:
			draw_line(c + Vector2(-r * 0.5, -r * 0.5), c + Vector2(r * 0.5, r * 0.5), colour, 8.0, true)
			draw_line(c + Vector2(r * 0.5, -r * 0.5), c + Vector2(-r * 0.5, r * 0.5), colour, 8.0, true)


# The book's read-only track for a known step's band.
class BandGauge extends StepGauge:
	func _init() -> void:
		custom_minimum_size = Vector2(0, 24)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		_draw_track()


# Heat / compress: hold and the needle rises; release commits the raw
# needle value. With crack_at set, reaching it commits at once.
class HoldGauge extends StepGauge:
	signal committed(value: float)

	var rise_per_sec := 0.0
	var crack_at := -1.0
	var _value := 0.0
	var _holding := false

	func _ready() -> void:
		set_process(false)

	func _gui_input(event: InputEvent) -> void:
		var press := _pressed(event)
		if press > 0:
			_holding = true
			_value = 0.0
			set_process(true)
		elif press < 0 and _holding:
			_release()

	func _release() -> void:
		_holding = false
		set_process(false)
		committed.emit(_value)

	func _process(delta: float) -> void:
		_value = minf(100.0, _value + rise_per_sec * delta)
		queue_redraw()
		if crack_at >= 0.0 and _value >= crack_at:
			_release()

	func _draw() -> void:
		_draw_input_zone()
		var track := _draw_track()
		if crack_at >= 0.0:
			draw_line(Vector2(_x(crack_at), track.position.y), Vector2(_x(crack_at), track.end.y), MapCardStyle.action(), 3.0)
		_draw_needle(_value)


# Grind: the pestle needle swings 0-100-0 every period_sec; each tap reads
# its position as a stroke, and the last stroke commits them all.
class GrindGauge extends StepGauge:
	signal committed(readings: Array)

	var strokes := 0
	var period_sec := 1.0
	var _elapsed := 0.0
	var _readings := []

	func _position() -> float:
		var phase := fposmod(_elapsed / period_sec, 1.0)
		return 200.0 * (phase if phase < 0.5 else 1.0 - phase)

	func _gui_input(event: InputEvent) -> void:
		if _pressed(event) <= 0 or _readings.size() >= strokes:
			return
		_readings.append(_position())
		queue_redraw()
		if _readings.size() >= strokes:
			set_process(false)
			committed.emit(_readings)

	func _process(delta: float) -> void:
		_elapsed += delta
		queue_redraw()

	func _draw() -> void:
		_draw_input_zone()
		var track := _draw_track()
		for reading in _readings:
			draw_circle(Vector2(_x(reading), track.end.y + 8.0), 4.0, MapCardStyle.gold())
		_draw_needle(_position())


# Distil: after lead_in_msec, drip i falls across the track from 0 to 100
# over fall_msec, starting at i × beat_msec. Taps are reported as msec since
# drip 0 started (negative in the lead-in); the last drip's fall commits.
class DistilGauge extends StepGauge:
	signal committed(taps: Array)

	var drips := 0
	var beat_msec := 1.0
	var fall_msec := 1.0
	var lead_in_msec := 0.0
	var _elapsed_msec := 0.0
	var _taps := []

	func _clock() -> float:
		return _elapsed_msec - lead_in_msec

	func _gui_input(event: InputEvent) -> void:
		if _pressed(event) > 0:
			_taps.append(_clock())
			queue_redraw()

	func _process(delta: float) -> void:
		_elapsed_msec += delta * 1000.0
		queue_redraw()
		if _clock() > (drips - 1) * beat_msec + fall_msec:
			set_process(false)
			committed.emit(_taps)

	func _draw() -> void:
		_draw_input_zone()
		var track := _draw_track()
		var t := _clock()
		var drip := floori(t / beat_msec)
		var into := t - drip * beat_msec
		if t >= 0.0 and drip < drips and into <= fall_msec:
			draw_circle(Vector2(_x(100.0 * into / fall_msec), track.get_center().y), track.size.y * 0.4, MapCardStyle.ink())
		for i in drips:
			draw_circle(Vector2(8.0 + i * 14.0, track.end.y + 10.0), 4.0, MapCardStyle.dim() if i < drip else MapCardStyle.line())
		draw_string(get_theme_default_font(), Vector2(size.x - 60.0, track.end.y + 16.0), "taps %d" % _taps.size(), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, MapCardStyle.muted())

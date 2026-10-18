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
	# False hides the input-zone outline (distil: only while a drip can be caught).
	var zone_active := true
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
		if input_colour.a <= 0.0 or not zone_active:
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

	func _draw_track(top := -1.0, height := -1.0) -> Rect2:
		var track := Rect2(Vector2(0, size.y * 0.3 if top < 0.0 else top), Vector2(size.x, size.y * 0.4 if height < 0.0 else height))
		draw_rect(track, MapCardStyle.line())
		if band_high <= band_low:
			return track
		var band_colour := Color(MapCardStyle.band(), 0.4) if band_vague else MapCardStyle.band()
		draw_rect(Rect2(Vector2(_x(band_low), track.position.y), Vector2(_x(band_high - band_low), track.size.y)), band_colour)
		return track

	func _draw_needle(value: float, bottom := -1.0) -> void:
		draw_line(Vector2(_x(value), 0), Vector2(_x(value), size.y if bottom < 0.0 else bottom), MapCardStyle.ink(), 3.0)


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


# Compression: drag a finger round the crank; each clockwise degree moves the
# needle gain_per_rev / 360, so needle speed follows rotation speed. Anticlockwise
# turns, drags near the hub, steps under deadzone_deg and steps that don't bend
# clockwise by min_bend_deg (a straight drag) do nothing. Release commits the raw needle value;
# reaching crack_at commits at once.
class CrankGauge extends StepGauge:
	signal committed(value: float)

	const TRACK_HEIGHT := 28.0

	var gain_per_rev := 40.0
	var deadzone_deg := 2.0
	var min_radius_frac := 0.3
	var min_bend_deg := 0.5
	var crack_at := -1.0
	var _value := 0.0
	var _turning := false
	var _last := Vector2.ZERO
	var _last_step := Vector2.ZERO
	var _knob_angle := 0.0

	func _init() -> void:
		super()
		custom_minimum_size = Vector2(0, 190)

	func _centre() -> Vector2:
		return Vector2(size.x * 0.5, TRACK_HEIGHT + 8.0 + (size.y - TRACK_HEIGHT - 8.0) * 0.5)

	func _crank_radius() -> float:
		return minf(size.x * 0.5, (size.y - TRACK_HEIGHT - 8.0) * 0.5) - 6.0

	func _gui_input(event: InputEvent) -> void:
		var press := _pressed(event)
		if press > 0:
			_turning = true
			_value = 0.0
			_last = event.position
			_last_step = Vector2.ZERO
			queue_redraw()
		elif press < 0 and _turning:
			_release()
		elif _turning and event is InputEventMouseMotion:
			accept_event()
			_drag_to(event.position)

	func _release() -> void:
		_turning = false
		committed.emit(_value)

	# One pointer step: the clockwise angle swept about the hub, if it counts.
	func _drag_to(point: Vector2) -> void:
		if not _turning:
			return
		var hub := _centre()
		var from := _last - hub
		var to := point - hub
		var step := point - _last
		var bend := 0.0 if _last_step == Vector2.ZERO or step == Vector2.ZERO else angle_difference(_last_step.angle(), step.angle())
		_last = point
		if step != Vector2.ZERO:
			_last_step = step
		if from.length() < _crank_radius() * min_radius_frac or to.length() < _crank_radius() * min_radius_frac:
			return
		var swept := angle_difference(from.angle(), to.angle())
		if swept <= deg_to_rad(deadzone_deg) or bend <= deg_to_rad(min_bend_deg):
			return
		_knob_angle += swept
		_value = minf(100.0, _value + rad_to_deg(swept) / 360.0 * gain_per_rev)
		queue_redraw()
		if crack_at >= 0.0 and _value >= crack_at:
			_release()

	func _draw() -> void:
		_draw_input_zone()
		var track := _draw_track(0.0, TRACK_HEIGHT)
		if crack_at >= 0.0:
			draw_line(Vector2(_x(crack_at), track.position.y), Vector2(_x(crack_at), track.end.y), MapCardStyle.action(), 3.0)
		_draw_needle(_value, TRACK_HEIGHT)
		var hub := _centre()
		var radius := _crank_radius()
		draw_arc(hub, radius, 0.0, TAU, 48, MapCardStyle.line(), 4.0, true)
		var knob := hub + Vector2(sin(_knob_angle), -cos(_knob_angle)) * radius
		draw_line(hub, knob, MapCardStyle.ink(), 5.0, true)
		draw_circle(hub, 7.0, MapCardStyle.ink())
		draw_circle(knob, 14.0, MapCardStyle.gold())
		draw_arc(knob, 14.0, 0.0, TAU, 24, MapCardStyle.ink(), 2.0, true)


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
# Each tap and each untapped drip also reports tap_result(kind, reading) with
# kind "caught" / "stray" / "missed" (reading is the drip position, else -1).
class DistilGauge extends StepGauge:
	signal committed(taps: Array)
	signal tap_result(kind: String, reading: float)

	var drips := 0
	var beat_msec := 1.0
	var fall_msec := 1.0
	var lead_in_msec := 0.0
	var flash_msec := 350.0
	var _elapsed_msec := 0.0
	var _taps := []
	var _caught := {}
	var _missed := {}
	var _flash_kind := ""
	var _flash_text := ""
	var _flash_x := 0.0
	var _flash_at := -1.0e9

	func _clock() -> float:
		return _elapsed_msec - lead_in_msec

	func _gui_input(event: InputEvent) -> void:
		if _pressed(event) > 0:
			_tap()
			accept_event()

	func _tap() -> void:
		var t := _clock()
		_taps.append(t)
		var drip := floori(t / beat_msec)
		var into := t - drip * beat_msec
		if drip < 0 or drip >= drips or into > fall_msec or _caught.has(drip):
			_show_flash("stray", "Stray!", 50.0, -1.0)
		else:
			var reading := 100.0 * into / fall_msec
			_caught[drip] = reading
			_show_flash("caught", "Caught %d" % roundi(reading), reading, reading)
		queue_redraw()

	func _show_flash(kind: String, text: String, at_x: float, reading: float) -> void:
		_flash_kind = kind
		_flash_text = text
		_flash_x = at_x
		_flash_at = _elapsed_msec
		tap_result.emit(kind, reading)

	func _falling_drip() -> int:
		var t := _clock()
		var drip := floori(t / beat_msec)
		if t >= 0.0 and drip < drips and t - drip * beat_msec <= fall_msec:
			return drip
		return -1

	func _process(delta: float) -> void:
		_elapsed_msec += delta * 1000.0
		for i in drips:
			if not _caught.has(i) and not _missed.has(i) and _clock() > i * beat_msec + fall_msec:
				_missed[i] = true
				_show_flash("missed", "Missed", 100.0, -1.0)
		var falling := _falling_drip()
		zone_active = falling >= 0 and not _caught.has(falling)
		queue_redraw()
		if _clock() > (drips - 1) * beat_msec + fall_msec:
			set_process(false)
			committed.emit(_taps)

	func _draw() -> void:
		_draw_input_zone()
		var track := _draw_track()
		var t := _clock()
		var drip := floori(t / beat_msec)
		var falling := _falling_drip()
		var cy := track.get_center().y
		if falling >= 0:
			var x := _x(100.0 * (t - drip * beat_msec) / fall_msec)
			draw_line(Vector2(0, cy), Vector2(x, cy), Color(MapCardStyle.ink(), 0.3), 3.0)
			draw_circle(Vector2(x, cy), track.size.y * 0.5, MapCardStyle.ink())
		var font := get_theme_default_font()
		for i in drips:
			var c := Vector2(8.0 + i * 14.0, track.end.y + 10.0)
			if _caught.has(i):
				draw_circle(c, 4.0, MapCardStyle.gold())
			elif _missed.has(i):
				draw_line(c + Vector2(-3, -3), c + Vector2(3, 3), MapCardStyle.dim(), 2.0)
				draw_line(c + Vector2(3, -3), c + Vector2(-3, 3), MapCardStyle.dim(), 2.0)
			else:
				draw_circle(c, 4.0, MapCardStyle.line())
			if i == falling or (falling < 0 and i == clampi(drip + 1, 0, drips - 1) and t < (drips - 1) * beat_msec):
				draw_arc(c, 6.5, 0.0, TAU, 20, MapCardStyle.ink(), 1.5)
		var status := "Ready…" if t < 0.0 else "Drip %d/%d" % [clampi(drip + 1, 1, drips), drips]
		draw_string(font, Vector2(drips * 14.0 + 12.0, track.end.y + 16.0), status, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, MapCardStyle.muted())
		draw_string(font, Vector2(size.x - 60.0, track.end.y + 16.0), "taps %d" % _taps.size(), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, MapCardStyle.muted())
		var age := _elapsed_msec - _flash_at
		if age >= 0.0 and age < flash_msec:
			var fade := 1.0 - age / flash_msec
			var colour: Color = MapCardStyle.gold() if _flash_kind == "caught" else Color(0.85, 0.2, 0.2)
			if _flash_kind == "stray":
				draw_rect(track, Color(colour, 0.35 * fade))
			elif _flash_kind == "caught":
				draw_arc(Vector2(_x(_flash_x), cy), track.size.y * (0.5 + 0.5 * (1.0 - fade)), 0.0, TAU, 24, Color(colour, fade), 3.0)
			var tx := clampf(_x(_flash_x) - 30.0, 0.0, maxf(size.x - 70.0, 0.0))
			draw_string(font, Vector2(tx, track.position.y - 4.0), _flash_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(colour, fade))

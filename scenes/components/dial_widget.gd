class_name DialWidget
extends Control

# combat-presentation ticket 03, docs/combat-animation-vision.md §2.5: the
# Dial's in-combat casting widget -- docked right, full height, spanning the
# action-card row and the log beneath it (scenes/screens/combat.gd's
# _build_command_deck()). Replaces the per-Complication button list
# bag_drawer.gd's in-combat section used to render (removed there -- Dial
# casting only happens through this widget now; non-Dial Bag items keep
# working via the existing Bag flow).
#
# Rebuilt fresh by CombatScreen._refresh() on every EventBus.state_changed,
# same as TurnOrderStrip -- and, like TurnOrderStrip.handle_swipe(),
# handle_rotate() below never mutates this node's own _selected_index; it
# only reports the new index through the callback. CombatScreen owns the
# persisted choice (_dial_selected_index) and re-triggers a full _refresh()
# in response (_on_dial_selection_changed()), the same "nothing in
# GameState changed, so nothing would otherwise trigger it" case
# combat.gd's own non-enemy-swipe branch documents -- one source of truth,
# not two copies of the selection drifting in parallel.
#
# Placeholder art only -- plain drawn shapes (_draw()), not the pixel-art
# diegetic prop §2.5 locks in. That's the one deliberate pixel-art
# exception in the whole vision doc, deferred rather than placeholder'd
# with a flat box since this widget's functional shape (rotate/trigger/
# charge-clock) is what this ticket proves, not its final look.

# Geometry ratios shared between _draw() and the angular gesture below, so
# the hit-testing math can never drift from what's actually painted.
const CLOCK_RADIUS_RATIO := 0.42
const BEZEL_RADIUS_RATIO := 0.42
const CLOCK_TOP_MARGIN := 4.0
const BEZEL_GAP := 10.0

# §2.5: "Rotate (drag/swipe around the handle)" -- an angular gesture
# around the bezel's centre, not a linear swipe. Below this angle the
# release reads as a press (trigger) rather than a rotate; ~20 degrees.
const ROTATE_ANGLE_THRESHOLD := 0.35

var _dial: Dictionary = {}
var _selected_index: int = 0
var _on_selection_changed: Callable = Callable()
var _on_triggered: Callable = Callable()

var _drag_index := -100
var _drag_start_angle: float = 0.0


# `selected_index` is CombatScreen's persisted choice (its own instance var,
# same pattern as _strip_selected_key/TurnOrderStrip) -- clamped here to
# whatever loadedComplications looks like right now, since ticket 03's Dial
# management (bag_drawer.gd, out of combat only) can't change that list
# mid-fight but a fresh Dial/fight can hand this a stale index.
#
# combat-presentation ticket 05: `on_triggered` (optional, defaults to a
# no-op Callable so every pre-ticket-05 configure() call site/test still
# works unchanged) reports handle_trigger()'s Combat.cast_complication()
# result -- same "report through a callback, never own the follow-up"
# split on_selection_changed already uses. CombatScreen wires it to play the
# result's `beats` back through CombatDirector, same as an Attack/Run press
# (_play_round()) -- see that file's _on_dial_triggered().
func configure(dial: Dictionary, selected_index: int, on_selection_changed: Callable, on_triggered: Callable = Callable()) -> void:
	_dial = dial
	var loaded: Array = dial.get("loadedComplications", [])
	_selected_index = clampi(selected_index, 0, maxi(0, loaded.size() - 1))
	_on_selection_changed = on_selection_changed
	_on_triggered = on_triggered
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()


func current_index() -> int:
	return _selected_index


# Public so tests can drive a rotation without simulating InputEvents (same
# split TurnOrderStrip.handle_swipe() uses). direction: -1 previous / +1
# next, wrapping at either end -- a physical dial rotates continuously,
# unlike the turn-order strip's card-row swipe, which clamps at the ends.
# Reports through the callback only, same as handle_swipe() -- see this
# file's own top comment for why it doesn't also mutate _selected_index.
func handle_rotate(direction: int) -> void:
	var loaded: Array = _dial.get("loadedComplications", [])
	if loaded.size() <= 1:
		return
	var new_index: int = wrapi(_selected_index + direction, 0, loaded.size())
	if _on_selection_changed.is_valid():
		_on_selection_changed.call(new_index)


# Combat.cast_complication() (systems/combat.gd:1021) already guards charge/
# validity and appends its own log line -- this widget is a thin dispatcher,
# same shape as _build_action_bar()'s old inline UI.button() callbacks.
# combat-presentation ticket 05: the cast itself is still this synchronous
# direct call (state is fully mutated by the time this returns, same as
# every other Combat.* call site) -- only the result's `beats` gets handed
# onward, through _on_triggered, for cosmetic playback.
func handle_trigger() -> void:
	var result: Dictionary = Combat.cast_complication(_selected_index)
	if _on_triggered.is_valid():
		_on_triggered.call(result)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if _drag_index == -100:
				_drag_index = event.index
				_drag_start_angle = _angle_at(event.position)
		elif event.index == _drag_index:
			_end_drag(_angle_at(event.position))
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if _drag_index == -100:
				_drag_index = -1
				_drag_start_angle = _angle_at(event.position)
		elif _drag_index == -1:
			_end_drag(_angle_at(event.position))


func _angle_at(local_pos: Vector2) -> float:
	return (local_pos - _bezel_center()).angle()


# A short angular movement (below threshold) is the trigger press; a wider
# sweep rotates instead, toward whichever way the finger swung around the
# bezel's centre -- an increasing angle (clockwise, screen coordinates)
# rotates forward, an arbitrary but consistent convention for this
# placeholder gesture.
func _end_drag(release_angle: float) -> void:
	var delta: float = wrapf(release_angle - _drag_start_angle, -PI, PI)
	_drag_index = -100
	if absf(delta) < ROTATE_ANGLE_THRESHOLD:
		handle_trigger()
	else:
		handle_rotate(1 if delta > 0.0 else -1)


func _clock_radius() -> float:
	return size.x * CLOCK_RADIUS_RATIO


func _clock_center() -> Vector2:
	return Vector2(size.x / 2.0, _clock_radius() + CLOCK_TOP_MARGIN)


func _bezel_radius() -> float:
	return size.x * BEZEL_RADIUS_RATIO


func _bezel_center() -> Vector2:
	var clock_center := _clock_center()
	return Vector2(size.x / 2.0, clock_center.y + _clock_radius() + _bezel_radius() + BEZEL_GAP)


func _draw() -> void:
	var loaded: Array = _dial.get("loadedComplications", [])
	if loaded.is_empty():
		return

	# Charge clock-face (§2.5's "built into the top of the handle"): a
	# filled wedge sweeping clockwise from 12 o'clock, proportional to
	# dial.currentCharge/dial.maxCharge -- an analog gauge, not pips or a
	# linear meter, per the ticket's explicit call-out.
	var clock_r: float = _clock_radius()
	var clock_center := _clock_center()
	draw_circle(clock_center, clock_r, Color(0.16, 0.16, 0.20))
	draw_arc(clock_center, clock_r, 0.0, TAU, 32, Color(0, 0, 0, 0.6), 2.0)

	var max_charge: float = maxf(1.0, float(_dial.get("maxCharge", 1)))
	var current_charge: float = float(_dial.get("currentCharge", 0))
	var charge_frac: float = clampf(current_charge / max_charge, 0.0, 1.0)
	var sweep: float = TAU * charge_frac
	if sweep > 0.0:
		var points := PackedVector2Array([clock_center])
		var steps: int = maxi(1, int(sweep / 0.2))
		for i in range(steps + 1):
			var a: float = -PI / 2.0 + sweep * (float(i) / float(steps))
			points.append(clock_center + Vector2(cos(a), sin(a)) * clock_r)
		draw_colored_polygon(points, Color(0.95, 0.85, 0.35, 0.9))

	# Handle body + rotating bezel, below the clock-face: a ring of tick
	# marks, one per loaded Complication, with a raised marker on the
	# currently-selected one, plus a fixed pointer at 12 o'clock -- §2.5's
	# "distinct rotating-bezel texture band with raised notches and a fixed
	# pointer marker," rendered as plain vector shapes per this ticket's
	# placeholder-art exception. Notch count always follows
	# loaded.size(), never a fixed number (capacityMax varies by level).
	var bezel_r: float = _bezel_radius()
	var bezel_center := _bezel_center()
	draw_circle(bezel_center, bezel_r + 6.0, Color(0.22, 0.22, 0.26))
	draw_circle(bezel_center, bezel_r, Color(0.30, 0.28, 0.24))

	# Dimmed when there's no charge to spend -- a press is still accepted
	# (Combat.cast_complication() refuses it), but nothing here should look
	# pressable, matching the old bag-drawer cast button's disabled state at
	# currentCharge < 1.
	var can_trigger: bool = current_charge >= 1.0
	var selected_colour: Color = Color(1.0, 0.86, 0.35) if can_trigger else Color(0.5, 0.46, 0.32)
	var pointer_colour: Color = Color(0.9, 0.9, 0.95) if can_trigger else Color(0.5, 0.5, 0.55)

	var count: int = loaded.size()
	for i in range(count):
		var a: float = -PI / 2.0 + TAU * (float(i) / float(count))
		var notch_pos: Vector2 = bezel_center + Vector2(cos(a), sin(a)) * (bezel_r - 4.0)
		var is_selected: bool = i == _selected_index
		draw_circle(notch_pos, 4.0 if is_selected else 2.5, selected_colour if is_selected else Color(0.6, 0.6, 0.62))

	draw_line(bezel_center, bezel_center + Vector2(0, -bezel_r - 8.0), pointer_colour, 2.0)

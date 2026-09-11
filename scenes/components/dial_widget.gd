class_name DialWidget
extends Control

# combat-presentation ticket 03, docs/combat-animation-vision.md §2.5: the
# Dial's in-combat casting widget -- a large prop docked left of the command
# deck's action row (scenes/screens/combat.gd's _build_dial_and_actions_row()),
# no longer clipped to a small cropped box (ui-chrome-pass ticket 03 -- see
# that function's and this file's own WIDGET_SIZE/HANDLE_DISPLAY_SIZE
# comments). Replaces
# the per-Complication button list bag_drawer.gd's in-combat section used to
# render (removed there -- Dial casting only happens through this widget
# now; non-Dial Bag items keep working via the existing Bag flow).
#
# Rebuilt fresh by CombatScreen._refresh() on every EventBus.state_changed,
# same as TurnOrderStrip.
#
# combat-presentation ticket 18 (human direction, 2026-09-09): replaces this
# widget's placeholder vector clock/bezel _draw() AND its rotate-to-select/
# press-anywhere-to-trigger gesture with the real `assets/hq/dial/
# dial_device_base.png` umbrella-handle art (the same prop hq_dial.gd's
# loadout screen already renders) plus a direct-tap interaction: the 4 grey
# screws visible in the art are tap targets, one per loaded-Complication
# housing (index 0..3, same MAX_VISIBLE_COMPLICATION_HOUSINGS cap
# hq_dial.gd's own flanking sockets use -- a combat loadout never shows more
# than 4 at once either); the oval switch below the grip is the trigger tap
# target, overlaid with a drawn "⇄" two-arrow glyph since the source art has
# no such icon baked in (an art-independent flourish, same convention
# StageSlot's own vector overlays use). This supersedes ticket 14's "art-only
# pass, no functional/interaction change" scope -- the human asked for the
# interaction to change too, so ticket 14 is folded into this one. See
# docs/combat-animation-vision.md §2.5's amendment note for the superseded
# rotate-gesture spec text.
#
# handle_select()/handle_trigger() only ever REPORT through their callbacks,
# never mutate this node's own _selected_index -- same split the old
# handle_rotate() used and TurnOrderStrip.handle_swipe() still uses.
# CombatScreen owns the persisted choice (_dial_selected_index) and
# re-triggers a full _refresh() in response, so there is exactly one source
# of truth for the selection, not two copies drifting in parallel.
#
# Geometry below is measured by eye off the same PNG hq_dial.gd's own
# FACE_CENTER_NATIVE/NEEDLE_* consts were measured from (see that file's top
# comment for the measurement method) -- ART-REVIEW, not yet confirmed
# on-device (this agent cannot see the running UI, CLAUDE.md workflow rule
# 5). Human should eyeball dot/button alignment against the real render and
# adjust these consts if they read off-target.

# Same source art hq_dial.gd's loadout screen uses -- reused, not
# duplicated, so a future re-paint of the umbrella only has one file to
# replace.
const HANDLE_TEXTURE_PATH := "res://assets/hq/dial/dial_device_base.png"
const NEEDLE_TEXTURE_PATH := "res://assets/hq/dial/dial-needle.png"

# The widget's own fixed footprint -- unlike the old vector widget (which
# read its rotate/trigger geometry off `size.x`, tying it to whatever the
# parent HBoxContainer handed it), every geometry helper below works off
# this fixed box so hit-testing/drawing never depends on a live layout pass
# having already run (tests build/configure() this widget without adding it
# to a SceneTree at all -- see tests/test_dial_widget.gd's own top comment).
#
# ui-chrome-pass ticket 03 rework (human direction 2026-09-11): this used to
# be a much smaller VISIBLE_BOX_SIZE (130x170) that clipped the rendered
# umbrella down to a cropped headshot -- confirmed-by-screenshot bug, this
# ticket's own issue text. WIDGET_SIZE is now HANDLE_DISPLAY_SIZE plus a
# small pad on every side, so the whole rendered square shows uncropped
# (this widget now reads as the same real prop hq_dial.gd's loadout screen
# renders, just at combat scale) -- the pad only exists so the screw/switch
# overlay rings (drawn a few px past their own dot centres) don't get
# clipped by clip_contents sitting flush against the art's own edge.
const WIDGET_PADDING := 8.0

# The topmost screw (DOT_OFFSETS_NATIVE index 0, native y=13 -- almost flush
# with the art's own top edge, same fact the old TOP_INSET this replaces was
# for) needs more headroom above it than WIDGET_PADDING alone gives: at this
# file's own HANDLE_SCALE, its DOT_HIT_SIZE tap-rect's top edge would sit at
# a NEGATIVE local y (outside the widget's own bounds -- events are only
# ever delivered for positive local coordinates within the Control's rect,
# so the part of that rect past y=0 is simply unreachable, silently shrinking
# the screw's real tap target) unless the box gives it real room above.
# Verified via this file's own _dot_rect(0) math -- code-review finding,
# 2026-09-11. Asymmetric (top only), not folded into WIDGET_PADDING itself,
# so the other 3 screws/the switch (which all sit further from the edge)
# don't pay for headroom they don't need.
const TOP_PADDING := 16.0

# The umbrella is rendered at this on-screen size (native art is 500x500,
# same DEVICE_NATIVE_SIZE hq_dial.gd uses) -- the original, un-shrunk value
# ("same source art, not shrunk", this ticket's own issue text). Human
# direction on review (2026-09-11): the Dial docks left of the action deck
# (combat.gd's _build_dial_and_actions_row()), with the Complication detail
# card reflowed onto its own full-width line above rather than sharing the
# row, and the action deck itself rebuilt as a vertical stack of compact
# horizontal bars (combat.gd's _build_action_deck()) rather than a
# horizontal row of 3 cards stretched to the Dial's height -- both changes
# free enough width for the Dial to render at its full original size and
# still fit the 358px content width. Confirmed via scripts/
# debug_combat_dial_screenshot.gd's own real (non-headless) render, not just
# hand-measured -- ART-REVIEW still applies to the screw/button hit-region
# consts below, which remain unconfirmed on an actual device.
const HANDLE_DISPLAY_SIZE := 208.0
const HANDLE_NATIVE_SIZE := 500.0
const HANDLE_SCALE := HANDLE_DISPLAY_SIZE / HANDLE_NATIVE_SIZE

const WIDGET_SIZE := Vector2(HANDLE_DISPLAY_SIZE + WIDGET_PADDING * 2.0, HANDLE_DISPLAY_SIZE + WIDGET_PADDING + TOP_PADDING)

# Where the rendered umbrella sits inside WIDGET_SIZE: WIDGET_PADDING in from
# the left/right/bottom edges, TOP_PADDING down from the top (see that
# const's own comment for why the top needs more room than the other three
# sides).
const WRAP_OFFSET := Vector2(WIDGET_PADDING, TOP_PADDING)

# hq_dial.gd's own measured consts, reused verbatim (same PNG, same
# measurement) -- see that file's top comment for how these were derived.
const FACE_CENTER_NATIVE := Vector2(250.0, 101.0)
const NEEDLE_ATLAS_REGION := Rect2(3.0, 1.0, 45.0, 37.0)
const NEEDLE_HUB_NATIVE := Vector2(13.0, 26.0)
const NEEDLE_MIN_DEG := -90.0
const NEEDLE_MAX_DEG := 90.0

# The 4 screws ringing the clock face (hq_dial.gd's own comment: "~55-80
# native px apart") -- index order matches loadedComplications: 0=top,
# 1=right, 2=bottom, 3=left, going clockwise from 12 o'clock the same
# direction hq_dial.gd's flanking-socket reading order and TurnOrderStrip's
# own left-to-right convention both already use.
#
# Explicit per-dot offsets rather than one shared radius -- confirmed via
# scripts/debug_combat_dial_screenshot.gd's own render (ART-REVIEW, see this
# file's top comment) that the housing reads taller than it is wide: a
# radius that lands the top/bottom screws right on the art overshoots past
# the left/right screws into the empty background beside the housing.
const DOT_OFFSETS_NATIVE: Array[Vector2] = [
	Vector2(0.0, -88.0), Vector2(61.0, 0.0), Vector2(0.0, 88.0), Vector2(-61.0, 0.0),
]
const DOT_HIT_SIZE := Vector2(34.0, 34.0)
const MAX_DOTS := 4

# The oval switch below the ridged grip band -- ART-REVIEW, see this file's
# top comment. Sized well past the visible pill in the art (same "the tap
# target doesn't have to match the literal art pixel-for-pixel" call
# hq_dial.gd's own socket tiles already make) so it clears the 44x44
# no-overlap guidance docs/hq-diorama-vision.md §3.2 sets, and sits far
# enough below the bottom screw (index 2) that the two hit-boxes don't
# touch.
const BUTTON_CENTER_NATIVE := Vector2(250.0, 280.0)
const BUTTON_HIT_SIZE := Vector2(64.0, 36.0)

var _dial: Dictionary = {}
var _selected_index: int = 0
var _on_selection_changed: Callable = Callable()
var _on_triggered: Callable = Callable()


# `selected_index` is CombatScreen's persisted choice -- clamped here to
# whatever loadedComplications looks like right now, same as before.
func configure(dial: Dictionary, selected_index: int, on_selection_changed: Callable, on_triggered: Callable = Callable()) -> void:
	_dial = dial
	var loaded: Array = dial.get("loadedComplications", [])
	_selected_index = clampi(selected_index, 0, maxi(0, loaded.size() - 1))
	_on_selection_changed = on_selection_changed
	_on_triggered = on_triggered
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = WIDGET_SIZE
	# ui-chrome-pass ticket 03 (human direction, 2026-09-11): SHRINK_END, not
	# SHRINK_BEGIN -- when this widget sits in a taller row than its own
	# height (combat.gd's _command_dock, whose own height also has to fit
	# the action deck beside it), bottom-aligning keeps the umbrella's own
	# art flush with the row's bottom edge ("rises from the bottom of the
	# screen") instead of floating at the row's top with dead space below it.
	size_flags_vertical = Control.SIZE_SHRINK_END
	clip_contents = true

	if get_child_count() == 0:
		_build_art()
	_position_needle()
	if _overlay != null:
		_overlay.queue_redraw()


func current_index() -> int:
	return _selected_index


# Public so tests can drive selection without simulating InputEvents (same
# split TurnOrderStrip.handle_swipe() and the old handle_rotate() used).
# A no-op past the loaded list's own end -- nothing there to select, same
# "refuse quietly" convention handle_trigger()'s charge check already uses.
func handle_select(index: int) -> void:
	var loaded: Array = _dial.get("loadedComplications", [])
	if index < 0 or index >= loaded.size():
		return
	if _on_selection_changed.is_valid():
		_on_selection_changed.call(index)


# Combat.cast_complication() (systems/combat.gd:1231) already guards charge/
# validity and appends its own log line -- this widget is a thin dispatcher.
func handle_trigger() -> void:
	var result: Dictionary = Combat.cast_complication(_selected_index)
	if _on_triggered.is_valid():
		_on_triggered.call(result)


func _gui_input(event: InputEvent) -> void:
	# combat-presentation ticket 18: a plain tap dispatches immediately on
	# press (no rotate-vs-trigger angle heuristic needed any more -- each
	# region is its own discrete target, same as tapping any other button).
	if event is InputEventScreenTouch and event.pressed:
		_handle_tap_at(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_handle_tap_at(event.position)


func _handle_tap_at(pos: Vector2) -> void:
	if _button_rect().has_point(pos):
		handle_trigger()
		return
	for i in range(MAX_DOTS):
		if _dot_rect(i).has_point(pos):
			handle_select(i)
			return


func _dot_position(index: int) -> Vector2:
	return FACE_CENTER_NATIVE * HANDLE_SCALE + DOT_OFFSETS_NATIVE[index] * HANDLE_SCALE + WRAP_OFFSET


func _dot_rect(index: int) -> Rect2:
	return Rect2(_dot_position(index) - DOT_HIT_SIZE / 2.0, DOT_HIT_SIZE)


func _button_position() -> Vector2:
	return BUTTON_CENTER_NATIVE * HANDLE_SCALE + WRAP_OFFSET


func _button_rect() -> Rect2:
	return Rect2(_button_position() - BUTTON_HIT_SIZE / 2.0, BUTTON_HIT_SIZE)


# The umbrella base + charge-reserve needle -- built once per instance (a
# fresh DialWidget every _refresh(), same lifecycle StageSlot's per-fight
# nodes don't share but this per-sync widget does need re-stating each
# time), mirroring hq_dial.gd's own _build_device_art() layout math at
# HANDLE_SCALE instead of that screen's own larger DEVICE_SCALE.
var _base_rect: TextureRect
var _needle_rect: TextureRect

# A separate top Control for the ring/arrow overlay, added AFTER `wrap` --
# a Control's own _draw() paints before its children (same ordering
# StageSlot's own _overlay comment documents), so overriding self's _draw()
# directly would paint the rings/arrow UNDER the umbrella texture, invisible
# wherever the art is opaque (confirmed via scripts/
# debug_combat_dial_screenshot.gd's own render: the trigger icon disappeared
# entirely behind the switch graphic). _overlay draws on top instead.
var _overlay: Control


func _build_art() -> void:
	var wrap := Control.new()
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.position = WRAP_OFFSET
	wrap.custom_minimum_size = Vector2(HANDLE_DISPLAY_SIZE, HANDLE_DISPLAY_SIZE)
	add_child(wrap)

	_base_rect = TextureRect.new()
	_base_rect.texture = load(HANDLE_TEXTURE_PATH)
	_base_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_base_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_base_rect.size = Vector2(HANDLE_DISPLAY_SIZE, HANDLE_DISPLAY_SIZE)
	_base_rect.stretch_mode = TextureRect.STRETCH_SCALE
	wrap.add_child(_base_rect)

	_needle_rect = TextureRect.new()
	var atlas := AtlasTexture.new()
	atlas.atlas = load(NEEDLE_TEXTURE_PATH)
	atlas.region = NEEDLE_ATLAS_REGION
	_needle_rect.texture = atlas
	_needle_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_needle_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_needle_rect.stretch_mode = TextureRect.STRETCH_SCALE
	var needle_size: Vector2 = NEEDLE_ATLAS_REGION.size * HANDLE_SCALE
	_needle_rect.size = needle_size
	_needle_rect.pivot_offset = NEEDLE_HUB_NATIVE * HANDLE_SCALE
	wrap.add_child(_needle_rect)

	# An explicit fixed rect, not anchors -- this widget's own size never
	# varies (it's always exactly WIDGET_SIZE, unlike e.g. StageSlot's
	# own per-fan-position overlay, which does need to track a resizing
	# parent), so there's no reason to depend on anchor resolution timing
	# relative to when this Control gets parented/laid out.
	_overlay = Control.new()
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.position = Vector2.ZERO
	_overlay.size = WIDGET_SIZE
	_overlay.draw.connect(_draw_overlay)
	add_child(_overlay)


func _position_needle() -> void:
	if _needle_rect == null:
		return
	var hub_offset: Vector2 = NEEDLE_HUB_NATIVE * HANDLE_SCALE
	_needle_rect.position = FACE_CENTER_NATIVE * HANDLE_SCALE - hub_offset
	_needle_rect.rotation_degrees = _needle_rotation_degrees()


func _needle_rotation_degrees() -> float:
	var max_charge: float = float(_dial.get("maxCharge", 0))
	if max_charge <= 0.0:
		return NEEDLE_MIN_DEG
	var fraction: float = clampf(float(_dial.get("currentCharge", 0)) / max_charge, 0.0, 1.0)
	return lerpf(NEEDLE_MIN_DEG, NEEDLE_MAX_DEG, fraction)


# The overlay layer: a ring on the selected (loaded) screw, a dim mark on
# every screw with nothing loaded into it, and the drawn two-arrow trigger
# icon -- none of this is baked into the source art, all of it art-
# independent vector drawing, same convention StageSlot's own overlay
# effects (flash/shield-crack) use over real or placeholder art alike. Lives
# on `_overlay` (a Control drawn on top of `wrap`'s art, not this node's own
# _draw()) -- see this file's own `_overlay` var comment for why.
func _draw_overlay() -> void:
	var loaded: Array = _dial.get("loadedComplications", [])
	var can_trigger: bool = float(_dial.get("currentCharge", 0)) >= 1.0

	for i in range(MAX_DOTS):
		var pos: Vector2 = _dot_position(i)
		if i >= loaded.size():
			# A light (not dark) thin ring -- a dark fill reads invisible
			# against the umbrella's own near-black housing, loaded/empty or
			# not (confirmed via scripts/debug_combat_dial_screenshot.gd's own
			# render).
			_overlay.draw_arc(pos, 5.0, 0.0, TAU, 16, Color(0.9, 0.9, 0.92, 0.3), 1.0)
			continue
		var is_selected: bool = i == _selected_index
		var colour: Color = Color(1.0, 0.86, 0.35, 0.95) if is_selected else Color(0.85, 0.85, 0.9, 0.65)
		_overlay.draw_arc(pos, 9.0 if is_selected else 7.0, 0.0, TAU, 20, colour, 2.5 if is_selected else 1.5)

	var button_colour: Color = Color(1.0, 0.86, 0.35, 0.95) if can_trigger else Color(0.55, 0.55, 0.58, 0.7)
	_draw_two_arrow_icon(_button_position(), button_colour)


# Drawn rather than a "⇄" text glyph -- ThemeDB.fallback_font's coverage of
# that codepoint isn't guaranteed (the exact problem scenes/components/
# symbol_glyph.gd exists to work around for other symbols elsewhere in the
# project); a missing glyph would silently render nothing at all. Two
# opposing arrows, offset top/bottom so they read as a pair rather than one
# double-headed line -- shaft + a triangle head, drawn with primitives only.
# Every draw_* call below is explicitly `_overlay.draw_*`, not a bare call --
# a bare draw_arc()/draw_line()/draw_colored_polygon() inside a method that
# belongs to `self` (this whole class) draws onto `self`'s own canvas layer
# regardless of which CanvasItem's `draw` signal invoked it, same gotcha
# StageSlot's own _draw_overlay() (scenes/screens/combat.gd) already works
# around by prefixing every call with `_overlay.` -- confirmed the hard way
# via scripts/debug_combat_dial_screenshot.gd's own render (nothing painted
# at all until this was fixed).
const ARROW_ICON_HALF_LENGTH := 9.0
const ARROW_ICON_ROW_GAP := 5.0
const ARROW_ICON_HEAD_SIZE := 4.5


func _draw_two_arrow_icon(center: Vector2, colour: Color) -> void:
	_draw_single_arrow(center + Vector2(0.0, -ARROW_ICON_ROW_GAP), 1.0, colour)
	_draw_single_arrow(center + Vector2(0.0, ARROW_ICON_ROW_GAP), -1.0, colour)


# `direction` +1 points right, -1 points left.
func _draw_single_arrow(mid: Vector2, direction: float, colour: Color) -> void:
	var tail: Vector2 = mid - Vector2(ARROW_ICON_HALF_LENGTH * direction, 0.0)
	var tip: Vector2 = mid + Vector2(ARROW_ICON_HALF_LENGTH * direction, 0.0)
	_overlay.draw_line(tail, tip, colour, 2.0)
	var back: Vector2 = tip - Vector2(ARROW_ICON_HEAD_SIZE * direction, 0.0)
	var head := PackedVector2Array([
		tip,
		back + Vector2(0.0, ARROW_ICON_HEAD_SIZE * 0.7),
		back + Vector2(0.0, -ARROW_ICON_HEAD_SIZE * 0.7),
	])
	_overlay.draw_colored_polygon(head, colour)

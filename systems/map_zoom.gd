class_name MapZoom
extends RefCounted

# Pure zoom-level math for the Network diagram (MapCanvas). Factored out for
# the same reason as map_style.gd/map_hit_test.gd — unit-testable without a
# scene tree. MapCanvas is the only caller: it keeps a zoom_level float,
# resizes itself (and its Node2D layers' scale) to MIN..MAX * mapSize, drives
# zoom_level from the floating +/- zoom buttons (MapCanvas.step_zoom), and
# uses to_logical() to convert a tap's screen-space position back to the
# logical map px MapHitTest and the pin list are keyed on.

const MIN := 0.35

# Headroom above DEFAULT (0.85) to read closely-packed station clusters.
# Exact value may still get tuned on-device.
const MAX := 1.75

# Past EVENT_ZOOM, so the map opens showing closer district-level detail
# instead of the whole Network at once.
const DEFAULT := 0.85

# The zoom level a programmatic pan-to-point animates to, so a queued
# event's ripple reads clearly on a phone screen rather than at DEFAULT.
const EVENT_ZOOM := 0.8

# The fixed amount a tap on the floating +/- zoom buttons (MapZoomButtons)
# moves zoom_level, additive rather than a pinch's continuous ratio —
# MapCanvas.step_zoom() adds/subtracts this, then clamp_zoom() saturates at
# MIN/MAX. 0.2 covers the whole MIN..MAX span in ~7 taps.
# **NEEDS VISUAL SIGN-OFF** — tune on-device if the step feels too big/small.
const STEP := 0.2


static func clamp_zoom(zoom: float) -> float:
	return clampf(zoom, MIN, MAX)


# Pure target-zoom math for the floating +/- zoom buttons' step, factored
# out so it's unit-testable without a scene tree or Tween — MapCanvas.
# step_zoom() is Node/Tween-side from here on (animates to this target via
# pan_to()). `direction` is +1 (zoom in) or -1 (zoom out).
static func step_target(current_zoom: float, direction: int) -> float:
	return clamp_zoom(current_zoom + direction * STEP)


static func to_logical(screen_pos: Vector2, zoom: float) -> Vector2:
	return screen_pos / zoom


# The scroll offset (top-left of the viewport, in the same zoomed px a
# ScrollContainer's scroll_horizontal/scroll_vertical use) that places
# `point` (logical map px) at `anchor` (viewport-relative px) inside a
# `viewport_size` viewport at `zoom`, clamped so the viewport never scrolls
# past the zoomed content's edges — done here so MapCanvas.pan_to() can
# tween straight to a valid target rather than fighting the container's own
# clamp mid-animation. `content_size` is the already-zoomed content size
# (mapSize * zoom), so callers animating zoom and scroll together can pass
# the in-progress zoomed size at each step.
#
# `anchor` defaults (sentinel -1,-1) to the viewport's centre — pan_to()'s
# "centre on this point" behaviour, its only production caller. Left as a
# real parameter, not inlined, since this file's own unit tests exercise it
# directly.
static func scroll_target(point: Vector2, zoom: float, viewport_size: Vector2, content_size: Vector2, anchor: Vector2 = Vector2(-1.0, -1.0)) -> Vector2:
	var resolved_anchor := anchor if anchor.x >= 0.0 and anchor.y >= 0.0 else viewport_size / 2.0
	var positioned := point * zoom - resolved_anchor
	var max_scroll := (content_size - viewport_size).max(Vector2.ZERO)
	return positioned.clamp(Vector2.ZERO, max_scroll)

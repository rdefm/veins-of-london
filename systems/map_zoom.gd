class_name MapZoom
extends RefCounted

# Pure zoom-level math for the Network diagram (MapCanvas). Factored out for
# the same reason as map_style.gd/map_hit_test.gd — unit-testable without a
# scene tree. MapCanvas is the only caller: it keeps a zoom_level float,
# resizes itself (and its Node2D layers' scale) to MIN..MAX * mapSize, drives
# zoom_level from a two-finger pinch (see MapCanvas._update_pinch), and uses
# to_logical() to convert a tap's screen-space position back to the logical
# map px MapHitTest and the pin list are keyed on.

const MIN := 0.35
const MAX := 1.0

# Map-filters ticket 02: was 0.5 (zoomed-to-fit-everything), bumped to 0.65,
# then further per on-device feedback ("zoom in even more by default") to
# 0.85 — past EVENT_ZOOM, close to MAX — so the map opens showing much
# closer district-level detail instead of the whole Network at once.
const DEFAULT := 0.85

# Map-animations ticket 01: the zoom level a programmatic pan-to-point
# animates to, so a queued event's ripple reads clearly on a phone screen
# rather than at the zoomed-out-to-see-everything DEFAULT.
const EVENT_ZOOM := 0.8


static func clamp_zoom(zoom: float) -> float:
	return clampf(zoom, MIN, MAX)


static func to_logical(screen_pos: Vector2, zoom: float) -> Vector2:
	return screen_pos / zoom


# Map-animations ticket 01: the scroll offset (top-left of the viewport, in
# the same zoomed px a ScrollContainer's scroll_horizontal/scroll_vertical
# use) that centres `point` (logical map px) inside a `viewport_size`
# viewport at `zoom`, clamped so the viewport never scrolls past the zoomed
# content's edges — same clamping a ScrollContainer would apply natively,
# done here so MapCanvas.pan_to() can tween straight to a valid target
# rather than fighting the container's own clamp mid-animation. `content_size`
# is the already-zoomed content size (mapSize * zoom), not passed as zoom
# again, so callers animating zoom and scroll together can pass the
# in-progress zoomed size at each step.
static func scroll_target(point: Vector2, zoom: float, viewport_size: Vector2, content_size: Vector2) -> Vector2:
	var centred := point * zoom - viewport_size / 2.0
	var max_scroll := (content_size - viewport_size).max(Vector2.ZERO)
	return centred.clamp(Vector2.ZERO, max_scroll)

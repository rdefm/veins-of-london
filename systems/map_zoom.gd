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

# Bugfixes ticket 10: was 1.0, leaving almost no zoom-in headroom above
# DEFAULT (0.85) to read closely-packed station clusters. Roughly doubled;
# exact value may still get tuned on-device.
const MAX := 1.75

# Map-filters ticket 02: was 0.5 (zoomed-to-fit-everything), bumped to 0.65,
# then further per on-device feedback ("zoom in even more by default") to
# 0.85 — past EVENT_ZOOM — so the map opens showing much closer
# district-level detail instead of the whole Network at once.
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
# use) that places `point` (logical map px) at `anchor` (viewport-relative
# px) inside a `viewport_size` viewport at `zoom`, clamped so the viewport
# never scrolls past the zoomed content's edges — same clamping a
# ScrollContainer would apply natively, done here so MapCanvas.pan_to() can
# tween straight to a valid target rather than fighting the container's own
# clamp mid-animation. `content_size` is the already-zoomed content size
# (mapSize * zoom), not passed as zoom again, so callers animating zoom and
# scroll together can pass the in-progress zoomed size at each step.
#
# `anchor` defaults (sentinel -1,-1, same idiom as pan_to()'s target_zoom)
# to the viewport's centre — pan_to()'s original "centre on this point"
# behaviour, unchanged for that caller. Bugfixes ticket 23: pinch-zoom needs
# `point` to stay under the fingers, not jump to viewport centre, so
# MapCanvas._update_pinch passes the pinch midpoint's own current
# viewport-relative position as `anchor` instead.
static func scroll_target(point: Vector2, zoom: float, viewport_size: Vector2, content_size: Vector2, anchor: Vector2 = Vector2(-1.0, -1.0)) -> Vector2:
	var resolved_anchor := anchor if anchor.x >= 0.0 and anchor.y >= 0.0 else viewport_size / 2.0
	var positioned := point * zoom - resolved_anchor
	var max_scroll := (content_size - viewport_size).max(Vector2.ZERO)
	return positioned.clamp(Vector2.ZERO, max_scroll)


# 53-map-auto-focus-and-zoom-persistence: the first-ever Network map open (no
# persisted camera yet, see systems/map_view.gd) centers/zooms to frame
# `positions` (the player's own vein stop positions, MapLayout-resolved)
# instead of opening at DEFAULT/top-left like every ordinary visit. Zoom
# never exceeds DEFAULT even for a single vein or a tight cluster — this is
# "frame the veins", not "zoom in as far as possible on them" — and FIT_
# PADDING leaves a margin around the bounding box rather than pinning it
# exactly to the viewport edge. `fallback_point` (MapLayout.home_anchor(),
# in the one real caller) is used verbatim at DEFAULT zoom, no fitting,
# whenever `positions` is empty — a fresh save's very first map visit, before
# any vein exists to fit around.
const FIT_PADDING := 0.75

static func fit_view(positions: Array, viewport_size: Vector2, map_size: Vector2, fallback_point: Vector2) -> Dictionary:
	if positions.is_empty():
		var fallback_content_size := map_size * DEFAULT
		return { "zoom": DEFAULT, "scroll": scroll_target(fallback_point, DEFAULT, viewport_size, fallback_content_size) }

	var min_pos: Vector2 = positions[0]
	var max_pos: Vector2 = positions[0]
	for p in positions:
		min_pos = min_pos.min(p)
		max_pos = max_pos.max(p)
	var center := (min_pos + max_pos) / 2.0
	var bounds_size := max_pos - min_pos

	var zoom := DEFAULT
	if bounds_size.x > 0.0:
		zoom = minf(zoom, viewport_size.x / bounds_size.x * FIT_PADDING)
	if bounds_size.y > 0.0:
		zoom = minf(zoom, viewport_size.y / bounds_size.y * FIT_PADDING)
	zoom = clamp_zoom(zoom)

	var content_size := map_size * zoom
	return { "zoom": zoom, "scroll": scroll_target(center, zoom, viewport_size, content_size) }

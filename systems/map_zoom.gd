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
const DEFAULT := 0.5


static func clamp_zoom(zoom: float) -> float:
	return clampf(zoom, MIN, MAX)


static func to_logical(screen_pos: Vector2, zoom: float) -> Vector2:
	return screen_pos / zoom

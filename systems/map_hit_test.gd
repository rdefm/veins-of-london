class_name MapHitTest
extends RefCounted

# Pure tap-hit-testing math for the Network diagram.
# scenes/components/map_canvas.gd is the only caller — kept separate so the
# geometry is unit-testable without a running scene tree, same reasoning as
# systems/map_style.gd and systems/map_routing.gd. Pin hit-testing stays
# inline in map_canvas.gd (simple radius check against a small list); this
# module covers a stop/tick on the diagram and a district's label or zone.

# Grown alongside map_canvas.gd's VEIN_STOP_RADIUS/FACTION_STOP_RADIUS so
# the tap target keeps pace with the visible icon size.
const STOP_TAP_RADIUS := 26.0
const LABEL_TAP_RADIUS := 24.0


# stops: any of MapCanvas's _vein_stops/_npc_stops/_unclaimed_stops arrays
# (or their concatenation) — each a Dictionary with "position" (Vector2),
# "kind", "site", "vein", and "owner" (see MapLayout.assign_positions).
# Returns the whole tapped stop, or null: the station bubble's
# Cultivate/Harvest options dispatch on the specific vein a "vein" stop
# carries, not just its site.
static func stop_at(tap_pos: Vector2, stops: Array) -> Variant:
	for stop in stops:
		if tap_pos.distance_to(stop["position"]) <= STOP_TAP_RADIUS:
			return stop
	return null


# districts_layout: GameData.MAP_LAYOUT["districts"] shape — district_id ->
# { labelAnchor:[x,y], zonePolygon:[[x,y],...], ... }. Checks every
# district's label first (small fixed-radius target), then falls back to
# zone-polygon containment (broad area) — a label tap always wins.
static func district_at(tap_pos: Vector2, districts_layout: Dictionary) -> Variant:
	for district_id in districts_layout.keys():
		var anchor: Array = districts_layout[district_id]["labelAnchor"]
		if tap_pos.distance_to(Vector2(anchor[0], anchor[1])) <= LABEL_TAP_RADIUS:
			return district_id

	for district_id in districts_layout.keys():
		var polygon := to_vector2_array(districts_layout[district_id]["zonePolygon"])
		if Geometry2D.is_point_in_polygon(tap_pos, polygon):
			return district_id

	return null


# Shared with map_canvas.gd, which draws zone polygons with the same
# [[x,y],...] JSON shape this hit-tests against — kept public so both sides
# of that draw/hit-test pair stay in lockstep off one conversion.
static func to_vector2_array(points: Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	for p in points:
		result.append(Vector2(p[0], p[1]))
	return result

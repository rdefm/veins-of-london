class_name MapHitTest
extends RefCounted

# M1.5 ticket 15: pure tap-hit-testing math for the Network diagram.
# scenes/components/map_canvas.gd is the only caller — kept separate so the
# geometry is unit-testable without a running scene tree, same reasoning as
# systems/map_style.gd and systems/map_routing.gd. Pin hit-testing stays
# inline in map_canvas.gd (ticket 13, simple radius check against a small
# list); this module covers the two tap targets ticket 15 adds: a stop/tick
# on the diagram, and a district's label or zone.

# bugfixes ticket 02: grown alongside map_canvas.gd's VEIN_STOP_RADIUS/
# FACTION_STOP_RADIUS enlargement (see that file's own comment for the
# before/after values and the stopSlots-spacing headroom check) so the tap
# target keeps pace with the bigger visible icon.
const STOP_TAP_RADIUS := 26.0
const LABEL_TAP_RADIUS := 24.0


# stops: any of MapCanvas's _vein_stops/_npc_stops/_unclaimed_stops arrays
# (or their concatenation) — each a Dictionary with "position" (Vector2),
# "kind", "site", "vein", and "owner" (see MapLayout.assign_positions).
# Returns the whole tapped stop, or null. 10-map-interaction-model ticket 04
# replaced this function's original site-id-only return (stop_site_at) with
# the whole stop: the station bubble's Cultivate/Harvest options dispatch on
# the specific vein a "vein" stop carries, not just its site, and a site id
# alone can't recover which of its (possibly two, via a natural-vein bonus
# site) veins was actually tapped.
static func stop_at(tap_pos: Vector2, stops: Array) -> Variant:
	for stop in stops:
		if tap_pos.distance_to(stop["position"]) <= STOP_TAP_RADIUS:
			return stop
	return null


# districts_layout: GameData.MAP_LAYOUT["districts"] shape — district_id ->
# { labelAnchor:[x,y], zonePolygon:[[x,y],...], ... }. Checks every
# district's label first (small fixed-radius target, cheap and precise),
# then falls back to zone-polygon containment (broad area) — a label tap
# always wins over an underlying polygon, and every district's polygon is
# checked here regardless of whether N2's zone-fill tint is actually drawn
# for it (only districts with factionPresence get a tint; the tap target
# covers all of them).
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

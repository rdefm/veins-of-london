class_name MapRouting
extends RefCounted

# M1.5 N3: deterministic octilinear line-routing — pure geometry only, no
# GameState/GameData reads. systems/map_layout.gd resolves real stop
# positions and feeds them in; scenes/components/map_canvas.gd turns the
# output into draw calls.

const TERMINUS_STUB_LENGTH := 24.0


# The diagonal leg shared by both elbow orientations: min(|dx|,|dy|) toward
# `to`, signed per axis.
static func _diag_offset(from: Vector2, to: Vector2) -> Vector2:
	var dx := to.x - from.x
	var dy := to.y - from.y
	var diag := minf(absf(dx), absf(dy))
	return Vector2(diag * signf(dx), diag * signf(dy))


# Two-segment elbow, "diag-first": diagonal 45deg for min(|dx|,|dy|) out of
# `from`, then axis-aligned for the remainder into `to`. "diag-last" is the
# mirror orientation (axis-aligned out of `from`, diagonal into `to`) — the
# alternate N3 allows for river-crossing avoidance.
static func elbow_corner_diag_first(from: Vector2, to: Vector2) -> Vector2:
	return from + _diag_offset(from, to)


static func elbow_corner_diag_last(from: Vector2, to: Vector2) -> Vector2:
	return to - _diag_offset(from, to)


# The full two-segment path (3 points: start, corner, end). Picks whichever
# orientation avoids crossing river_path "where trivially possible" (N3);
# if both or neither cross, prefers diag-first — keeps output deterministic
# given the same inputs.
static func elbow_path(from: Vector2, to: Vector2, river_path: Array = []) -> PackedVector2Array:
	var corner_first := elbow_corner_diag_first(from, to)
	if river_path.size() < 2:
		return PackedVector2Array([from, corner_first, to])

	if not _elbow_crosses_river(from, corner_first, to, river_path):
		return PackedVector2Array([from, corner_first, to])

	var corner_last := elbow_corner_diag_last(from, to)
	if not _elbow_crosses_river(from, corner_last, to, river_path):
		return PackedVector2Array([from, corner_last, to])

	return PackedVector2Array([from, corner_first, to])


static func _elbow_crosses_river(a: Vector2, corner: Vector2, b: Vector2, river_path: Array) -> bool:
	return _segment_crosses_polyline(a, corner, river_path) or _segment_crosses_polyline(corner, b, river_path)


static func _segment_crosses_polyline(a: Vector2, b: Vector2, polyline: Array) -> bool:
	for i in range(polyline.size() - 1):
		if segments_intersect(a, b, polyline[i], polyline[i + 1]):
			return true
	return false


# Standard segment-intersection test via orientation cross products.
static func segments_intersect(p1: Vector2, p2: Vector2, p3: Vector2, p4: Vector2) -> bool:
	var d1 := _cross(p4 - p3, p1 - p3)
	var d2 := _cross(p4 - p3, p2 - p3)
	var d3 := _cross(p2 - p1, p3 - p1)
	var d4 := _cross(p2 - p1, p4 - p1)
	return ((d1 > 0) != (d2 > 0)) and ((d3 > 0) != (d4 > 0))


static func _cross(a: Vector2, b: Vector2) -> float:
	return a.x * b.y - a.y * b.x


# N3's single-stop-owner terminus: a 24px stub through `point` at 45deg.
static func terminus_stub(point: Vector2, length: float = TERMINUS_STUB_LENGTH) -> PackedVector2Array:
	var offset := Vector2(1, 1).normalized() * (length / 2.0)
	return PackedVector2Array([point - offset, point + offset])


# Nearest-neighbour ordering, deterministic regardless of `stops`' input
# order: ties on distance broken by id (ascending). `stops` is an Array of
# { "id": String, "pos": Vector2 }; returns them reordered starting from
# whichever is nearest `start`, then nearest to the previous pick, etc.
static func nearest_neighbour_order(start: Vector2, stops: Array) -> Array:
	var remaining: Array = stops.duplicate()
	var ordered: Array = []
	var current := start

	while not remaining.is_empty():
		var best_i := 0
		var best_dist: float = current.distance_squared_to(remaining[0]["pos"])
		for i in range(1, remaining.size()):
			var dist: float = current.distance_squared_to(remaining[i]["pos"])
			if dist < best_dist or (dist == best_dist and remaining[i]["id"] < remaining[best_i]["id"]):
				best_dist = dist
				best_i = i
		var picked = remaining[best_i]
		ordered.append(picked)
		remaining.remove_at(best_i)
		current = picked["pos"]

	return ordered


# Builds one owner's full line: nearest-neighbour order the stops, then
# elbow-connect each consecutive pair into one continuous polyline (ready
# for draw_polyline). A single-stop owner gets a terminus stub instead of
# an elbow (N3). Empty input -> empty output (no line drawn).
static func build_line(start: Vector2, stops: Array, river_path: Array = []) -> PackedVector2Array:
	if stops.is_empty():
		return PackedVector2Array()

	var ordered := nearest_neighbour_order(start, stops)
	if ordered.size() == 1:
		return terminus_stub(ordered[0]["pos"])

	var points := PackedVector2Array()
	for i in range(ordered.size() - 1):
		var segment := elbow_path(ordered[i]["pos"], ordered[i + 1]["pos"], river_path)
		if points.is_empty():
			points.append(segment[0])
		points.append(segment[1])
		points.append(segment[2])
	return points


# map-animations ticket 05: how many leading points two polylines share
# (exact match). nearest_neighbour_order() is a deterministic greedy walk,
# so re-running it with one extra stop added reproduces every earlier pick
# exactly until the step where the new stop first out-competes whatever
# would otherwise have been picked next — grow_segment() below uses this to
# find precisely where a new stop's line diverges from the existing one.
static func common_prefix_length(a: PackedVector2Array, b: PackedVector2Array) -> int:
	var n := mini(a.size(), b.size())
	var i := 0
	while i < n and a[i] == b[i]:
		i += 1
	return i


# map-animations ticket 05: the polyline segment that "grows in" when one
# more stop (`new_stop`) joins an owner's existing line (`old_stops`) — not
# a parallel straight-line approximation, but the actual tail of
# build_line()'s own recomputed output once the new stop is included, so a
# caller animating this segment is *guaranteed* to end in exactly the shape
# the static draw already produces at rest (never a visible shape-jump on
# hand-off). Degenerates cleanly when `old_stops` is empty (the owner's
# very first stop): common_prefix_length is then always 0, so the "grown"
# segment is simply the new line in full (e.g. N3's terminus stub) rather
# than a synthetic segment reaching back to `anchor` — build_line() never
# actually connects a single-stop owner's stub to the anchor either, so
# growing "from the anchor" here would itself have been a shape mismatch.
static func grow_segment(anchor: Vector2, old_stops: Array, new_stop: Dictionary, river_path: Array = []) -> PackedVector2Array:
	var old_line := build_line(anchor, old_stops, river_path)
	var new_stops := old_stops.duplicate()
	new_stops.append(new_stop)
	var new_line := build_line(anchor, new_stops, river_path)

	var prefix := common_prefix_length(old_line, new_line)
	var segment := PackedVector2Array()

	# build_line() special-cases a single-stop owner as a terminus stub
	# rather than a path from the anchor, so when a second stop is appended
	# after it in walk order, the old stub's points share nothing with the
	# new elbow-chain's points even though the walk itself didn't reorder --
	# common_prefix_length reads that as "no shared prefix" when it's really
	# the same 1-stop-to-2-stop topology jump the static draw itself makes.
	# Bridge it explicitly by starting the grown segment at the old stub's
	# own rendered endpoint instead of jumping straight to the new line's
	# first point. Only applies when the old stop is still walked first in
	# the new order (a genuine append) -- a reorder (the new stop sorts
	# nearer) gets no such bridge, since nothing of the old stub survives
	# into the new walk at all.
	if prefix == 0 and old_stops.size() == 1 and not old_line.is_empty():
		var new_order := nearest_neighbour_order(anchor, new_stops)
		if new_order[0]["id"] == old_stops[0]["id"]:
			segment.append(old_line[old_line.size() - 1])

	var start_index := maxi(prefix - 1, 0)
	for i in range(start_index, new_line.size()):
		segment.append(new_line[i])
	return segment

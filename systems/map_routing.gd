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
# orientation avoids crossing river_path AND obstacle_stops, AND running
# closer than line_clearance to any obstacle_lines polyline, "where
# trivially possible" (N3, extended by ticket 51 for cross-faction stop
# avoidance, and by ticket 74 for cross-faction line-to-line spacing); if
# both or neither clear everything, prefers diag-first — keeps output
# deterministic given the same inputs. obstacle_stops is an Array of
# { "pos": Vector2, "radius": float } — stops another owner's line must not
# visually overlap. obstacle_lines is an Array of PackedVector2Array — other
# owners' already-routed polylines this one should keep line_clearance away
# from where trivially possible (best-effort only, unlike the hard
# stop-crossing guarantee ticket 74 also adds — see
# MapCanvas._apply_crossing_nudges for that).
static func elbow_path(from: Vector2, to: Vector2, river_path: Array = [], obstacle_stops: Array = [], obstacle_lines: Array = [], line_clearance: float = 0.0) -> PackedVector2Array:
	var corner_first := elbow_corner_diag_first(from, to)
	if river_path.size() < 2 and obstacle_stops.is_empty() and (obstacle_lines.is_empty() or line_clearance <= 0.0):
		return PackedVector2Array([from, corner_first, to])

	if not _elbow_crosses(from, corner_first, to, river_path, obstacle_stops, obstacle_lines, line_clearance):
		return PackedVector2Array([from, corner_first, to])

	var corner_last := elbow_corner_diag_last(from, to)
	if not _elbow_crosses(from, corner_last, to, river_path, obstacle_stops, obstacle_lines, line_clearance):
		return PackedVector2Array([from, corner_last, to])

	return PackedVector2Array([from, corner_first, to])


static func _elbow_crosses(a: Vector2, corner: Vector2, b: Vector2, river_path: Array, obstacle_stops: Array, obstacle_lines: Array = [], line_clearance: float = 0.0) -> bool:
	return (
		_elbow_crosses_river(a, corner, b, river_path)
		or _elbow_crosses_stops(a, corner, b, obstacle_stops)
		or _elbow_crosses_lines(a, corner, b, obstacle_lines, line_clearance)
	)


# Ticket 74: "crosses" here means "runs closer than line_clearance to", not
# a literal geometric intersection — two different-faction lines are allowed
# to touch a shared interchange stop, but shouldn't run right alongside each
# other with no visible gap. Best-effort, folded into the same orientation
# choice as river/stop avoidance above.
static func _elbow_crosses_lines(a: Vector2, corner: Vector2, b: Vector2, obstacle_lines: Array, line_clearance: float) -> bool:
	if line_clearance <= 0.0:
		return false
	for line in obstacle_lines:
		if _leg_too_close_to_line(a, corner, line, line_clearance) or _leg_too_close_to_line(corner, b, line, line_clearance):
			return true
	return false


static func _leg_too_close_to_line(a: Vector2, b: Vector2, line: PackedVector2Array, line_clearance: float) -> bool:
	for i in range(line.size() - 1):
		if _segment_distance(a, b, line[i], line[i + 1]) < line_clearance:
			return true
	return false


# Standard segment-to-segment distance: zero if they intersect, otherwise
# the minimum distance is always realised at one segment's endpoint against
# the other segment (a standard computational-geometry result for straight
# segments), so checking all four endpoint-to-segment distances suffices.
static func _segment_distance(a1: Vector2, a2: Vector2, b1: Vector2, b2: Vector2) -> float:
	if segments_intersect(a1, a2, b1, b2):
		return 0.0
	return minf(
		minf(_point_segment_distance(a1, b1, b2), _point_segment_distance(a2, b1, b2)),
		minf(_point_segment_distance(b1, a1, a2), _point_segment_distance(b2, a1, a2))
	)


static func _elbow_crosses_river(a: Vector2, corner: Vector2, b: Vector2, river_path: Array) -> bool:
	return _segment_crosses_polyline(a, corner, river_path) or _segment_crosses_polyline(corner, b, river_path)


static func _segment_crosses_polyline(a: Vector2, b: Vector2, polyline: Array) -> bool:
	for i in range(polyline.size() - 1):
		if segments_intersect(a, b, polyline[i], polyline[i + 1]):
			return true
	return false


# Ticket 51: unlike the river (a polyline crossing is a hard line), a stop is
# a filled circle on the rendered map — "crosses" here means the leg passes
# within the stop's own drawn radius, not just an exact geometric crossing.
static func _elbow_crosses_stops(a: Vector2, corner: Vector2, b: Vector2, obstacle_stops: Array) -> bool:
	for stop in obstacle_stops:
		if _segment_crosses_stop(a, corner, stop) or _segment_crosses_stop(corner, b, stop):
			return true
	return false


static func _segment_crosses_stop(a: Vector2, b: Vector2, stop: Dictionary) -> bool:
	return _point_segment_distance(stop["pos"], a, b) <= stop.get("radius", 0.0)


# Ticket 74: which obstacle_stops a two-leg elbow (a->corner->b) actually
# crosses — used once diag-first/diag-last has already run out of
# orientations, to find exactly which stop(s) still need a position nudge
# (MapCanvas._apply_crossing_nudges) rather than a routing workaround.
static func crossed_obstacles(a: Vector2, corner: Vector2, b: Vector2, obstacle_stops: Array) -> Array:
	var result: Array = []
	for stop in obstacle_stops:
		if _segment_crosses_stop(a, corner, stop) or _segment_crosses_stop(corner, b, stop):
			result.append(stop)
	return result


# Ticket 74: pushes the obstacle clear of BOTH legs of a two-leg elbow
# (a->corner->b), not just whichever it started nearest to — an obstacle
# sitting close to the corner itself can cross both legs at once, and a
# single perpendicular-to-one-leg push doesn't guarantee the other leg is
# clear too. Iterates a handful of times (each pass pushes away from
# whichever leg is currently nearest below `margin` beyond the obstacle's
# own radius), converging in at most 2 real passes since there are only 2
# legs to satisfy — the extra iterations are cheap headroom against a push
# for one leg nudging back into the other. Total displacement is capped to
# `max_offset` (a nudge is a bounded, explicit exception to a stop's
# otherwise-stable slot position, never a full relayout). `max_offset`
# should be chosen high enough to always dominate radius + margin for every
# obstacle kind this map draws (see MapCanvas.STOP_NUDGE_MAX_OFFSET's own
# comment), so in practice this always fully clears the crossing rather
# than merely reducing it.
const _NUDGE_ITERATIONS := 4

static func nudge_position(obstacle: Dictionary, a: Vector2, corner: Vector2, b: Vector2, margin: float, max_offset: float) -> Vector2:
	var radius: float = obstacle.get("radius", 0.0)
	var target := radius + margin
	var current: Vector2 = obstacle["pos"]
	var used := 0.0

	for i in range(_NUDGE_ITERATIONS):
		var d_a := _point_segment_distance(current, a, corner)
		var d_b := _point_segment_distance(current, corner, b)
		var leg_a := a
		var leg_b := corner
		var dist := d_a
		if d_b < d_a:
			leg_a = corner
			leg_b = b
			dist = d_b

		if dist >= target or used >= max_offset:
			break

		var dir := _push_direction_away_from_leg(current, leg_a, leg_b)
		var step := clampf(target - dist, 0.0, max_offset - used)
		current += dir * step
		used += step

	return current


static func _push_direction_away_from_leg(pos: Vector2, leg_a: Vector2, leg_b: Vector2) -> Vector2:
	var ab := leg_b - leg_a
	if ab.length_squared() == 0.0:
		return Vector2.RIGHT
	var normal := Vector2(-ab.y, ab.x).normalized()
	var to_pos := pos - leg_a
	return normal if (to_pos.length_squared() == 0.0 or normal.dot(to_pos) >= 0.0) else -normal


static func _point_segment_distance(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var len_sq := ab.length_squared()
	if len_sq == 0.0:
		return p.distance_to(a)
	var t := clampf((p - a).dot(ab) / len_sq, 0.0, 1.0)
	return p.distance_to(a + ab * t)


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
static func build_line(start: Vector2, stops: Array, river_path: Array = [], obstacle_stops: Array = [], obstacle_lines: Array = [], line_clearance: float = 0.0) -> PackedVector2Array:
	if stops.is_empty():
		return PackedVector2Array()

	var ordered := nearest_neighbour_order(start, stops)
	if ordered.size() == 1:
		return terminus_stub(ordered[0]["pos"])

	var points := PackedVector2Array()
	for i in range(ordered.size() - 1):
		var segment := elbow_path(ordered[i]["pos"], ordered[i + 1]["pos"], river_path, obstacle_stops, obstacle_lines, line_clearance)
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
static func grow_segment(anchor: Vector2, old_stops: Array, new_stop: Dictionary, river_path: Array = [], obstacle_stops: Array = [], obstacle_lines: Array = [], line_clearance: float = 0.0) -> PackedVector2Array:
	var old_line := build_line(anchor, old_stops, river_path, obstacle_stops, obstacle_lines, line_clearance)
	var new_stops := old_stops.duplicate()
	new_stops.append(new_stop)
	var new_line := build_line(anchor, new_stops, river_path, obstacle_stops, obstacle_lines, line_clearance)

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

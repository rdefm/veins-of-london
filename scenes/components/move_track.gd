class_name MoveTrack
extends Control

# One move's five-stop level track (Move Book). Stops are MoveLevels.book()
# stops: circles, with the milestone levels drawn as diamonds; reached stops
# filled in ink, the next one outlined in the action red. Mini: a row of
# small stops. Full: the rail across the five equal columns, filled to the
# current level then part-way along the next gap (rail_fill, 0..1).

const MINI_RADIUS := 4.5
const MINI_GAP := 3.0
const MINI_PAD := 1.5
const FULL_HEIGHT := 28.0
const FULL_RADIUS := 9.0
const RAIL_WIDTH := 3.0

var stops: Array = []
var rail_fill := 0.0
var mini := true


static func make(book_row: Dictionary, as_mini: bool) -> MoveTrack:
	var track := MoveTrack.new()
	track.stops = book_row["stops"]
	track.rail_fill = float(book_row["railFill"])
	track.mini = as_mini
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if as_mini:
		var count := track.stops.size()
		var width := MINI_RADIUS * 2.0 * count + MINI_GAP * (count - 1) + MINI_PAD * 2.0
		track.custom_minimum_size = Vector2(width, MINI_RADIUS * 2.0 + 2.0)
		track.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	else:
		track.custom_minimum_size = Vector2(0, FULL_HEIGHT)
		track.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return track


func _draw() -> void:
	var count := stops.size()
	if count == 0:
		return
	var radius := MINI_RADIUS if mini else FULL_RADIUS
	var line_width := 1.5 if mini else 2.5
	var y := size.y * 0.5
	var xs: Array[float] = []
	for i in count:
		if mini:
			xs.append(MINI_PAD + radius + i * (radius * 2.0 + MINI_GAP))
		else:
			xs.append(size.x * (i + 0.5) / count)
	if not mini:
		var left := xs[0]
		var right := xs[count - 1]
		draw_line(Vector2(left, y), Vector2(right, y), MapCardStyle.line(), RAIL_WIDTH)
		draw_line(Vector2(left, y), Vector2(left + (right - left) * clampf(rail_fill, 0.0, 1.0), y), MapCardStyle.ink(), RAIL_WIDTH)
	for i in count:
		var stop: Dictionary = stops[i]
		var centre := Vector2(xs[i], y)
		var edge := MapCardStyle.line()
		var fill := MapCardStyle.paper()
		if stop["reached"]:
			edge = MapCardStyle.ink()
			fill = edge
		elif stop["next"]:
			edge = MapCardStyle.action()
		if stop["current"] and not mini:
			_shape(centre, radius + 4.0, stop["milestone"], Color(MapCardStyle.action(), 0.18), Color(0, 0, 0, 0), 0.0)
		_shape(centre, radius, stop["milestone"], fill, edge, line_width)


func _shape(centre: Vector2, radius: float, diamond: bool, fill: Color, edge: Color, width: float) -> void:
	if diamond:
		var reach := radius * 1.2
		var points := PackedVector2Array([
			centre + Vector2(0, -reach), centre + Vector2(reach, 0),
			centre + Vector2(0, reach), centre + Vector2(-reach, 0),
		])
		draw_colored_polygon(points, fill)
		if width > 0.0:
			points.append(points[0])
			draw_polyline(points, edge, width, true)
	else:
		draw_circle(centre, radius, fill)
		if width > 0.0:
			draw_arc(centre, radius - width * 0.5, 0.0, TAU, 24, edge, width, true)

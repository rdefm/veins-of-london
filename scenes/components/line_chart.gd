class_name LineChart
extends Control

signal point_selected(index: int)

# Line chart (BizBrief Stats, Ticker price charts): values oldest first.
# Compact mode uses a zero baseline and max label; Ticker's inspectable mode
# uses the recorded range, touch/drag point selection and counted event dots.
# Both show first/last days; optional extra series share the scale. Colours
# are data/palette.json ids or an app accent (docs/ui-vision.md §6).

const CHART_HEIGHT := 120.0
const PAD_LEFT := 4.0
const PAD_TOP := 18.0
const PAD_BOTTOM := 18.0
const PAD_RIGHT := 4.0
const LINE_WIDTH := 2.0
const POINT_RADIUS := 2.5
const FONT_SIZE := 12
const MARKER_HALF := 4.0
const DETAIL_HEIGHT := 216.0
const DETAIL_GUTTER := 52.0

const GRID_ID := "phone_divider"
const TEXT_ID := "phone_text_muted"
const FALLBACK_GRID := Color("#424246")
const FALLBACK_TEXT := Color("#999a9d")

var _values: Array[int] = []
var _days: Array[int] = []
var _colour := Color.WHITE
# Overlaid lines after the first: [{ values: Array[int], colour: Color }].
var _extra_series: Array = []
var _prefix := ""
var _markers: Array = []
var _inspectable := false
var _selected_index := -1
var _drag_selecting := false


# values and days are parallel arrays; colour_id is a palette id; prefix
# goes before the max label (e.g. "£").
func setup(values: Array[int], days: Array[int], colour_id: String, prefix: String = "") -> LineChart:
	_values = values
	_days = days
	_colour = GameData.PALETTE.get(colour_id, Color.WHITE)
	_prefix = prefix
	custom_minimum_size = Vector2(0, CHART_HEIGHT)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()
	return self


# App-owned accent when the shared palette's nearest colour is too muted.
func with_primary_colour(colour: Color) -> LineChart:
	_colour = colour
	queue_redraw()
	return self


# series: [{ values (parallel to days), colour_id }], drawn over the first
# line and sharing its scale.
func with_series(series: Array) -> LineChart:
	_extra_series = []
	for line in series:
		_extra_series.append({ "values": line["values"], "colour": GameData.PALETTE.get(line["colour_id"], Color.WHITE) })
	queue_redraw()
	return self


# markers: [{ index (into values), colour_id }].
func with_markers(markers: Array) -> LineChart:
	_markers = markers
	queue_redraw()
	return self


# Opt-in price inspection. BizBrief keeps the compact, zero-based chart.
func with_inspection() -> LineChart:
	_inspectable = true
	_selected_index = _values.size() - 1
	custom_minimum_size.y = DETAIL_HEIGHT
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()
	return self


func index_at_x(x: float) -> int:
	if _values.is_empty():
		return -1
	if _values.size() == 1:
		return 0
	var plot := _plot_rect()
	return clampi(roundi((x - plot.position.x) / maxf(1.0, plot.size.x) * float(_values.size() - 1)), 0, _values.size() - 1)


func select_index(index: int) -> void:
	if _values.is_empty():
		return
	_selected_index = clampi(index, 0, _values.size() - 1)
	queue_redraw()
	point_selected.emit(_selected_index)


func _gui_input(event: InputEvent) -> void:
	if not _inspectable:
		return
	if event is InputEventScreenTouch:
		_drag_selecting = false
		if event.pressed:
			select_index(index_at_x(event.position.x))
	elif event is InputEventScreenDrag:
		if _drag_selecting or absf(event.relative.x) > absf(event.relative.y):
			_drag_selecting = true
			select_index(index_at_x(event.position.x))
			accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		select_index(index_at_x(event.position.x))
		accept_event()
	elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		select_index(index_at_x(event.position.x))
		accept_event()


func _plot_rect() -> Rect2:
	if _inspectable:
		return Rect2(DETAIL_GUTTER, PAD_TOP, maxf(1.0, size.x - DETAIL_GUTTER - 12.0), maxf(1.0, size.y - PAD_TOP - 34.0))
	return Rect2(PAD_LEFT, PAD_TOP, maxf(1.0, size.x - PAD_LEFT - PAD_RIGHT), maxf(1.0, size.y - PAD_TOP - PAD_BOTTOM))


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var grid: Color = GameData.PALETTE.get(GRID_ID, FALLBACK_GRID)
	var text: Color = GameData.PALETTE.get(TEXT_ID, FALLBACK_TEXT)
	var plot := _plot_rect()
	var lines: Array = [{ "values": _values, "colour": _colour }]
	lines.append_array(_extra_series)
	var top_value := 0
	for line in lines:
		for value in line["values"]:
			top_value = maxi(top_value, value)
	var bottom_value := 0
	if _inspectable and not _values.is_empty():
		bottom_value = _values.min()
		if bottom_value == top_value:
			bottom_value = maxi(0, bottom_value - 1)
			top_value += 1

	if _inspectable:
		for step in range(4):
			var y := plot.position.y + plot.size.y * float(step) / 3.0
			var value := roundi(lerpf(float(top_value), float(bottom_value), float(step) / 3.0))
			draw_line(Vector2(plot.position.x, y), Vector2(plot.end.x, y), grid, 1.0)
			draw_string(font, Vector2(0.0, y + 4.0), "%s%d" % [_prefix, value], HORIZONTAL_ALIGNMENT_RIGHT, DETAIL_GUTTER - 5.0, FONT_SIZE, text)
	else:
		draw_line(plot.position, Vector2(plot.end.x, plot.position.y), grid, 1.0)
		draw_line(Vector2(plot.position.x, plot.end.y), plot.end, grid, 1.0)
		draw_string(font, Vector2(PAD_LEFT, PAD_TOP - 4.0), "%s%d" % [_prefix, top_value], HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, text)
	if not _days.is_empty():
		var label_y := size.y - 4.0
		var first_day := Calendar.format_day(_days[0])
		draw_string(font, Vector2(plot.position.x, label_y), first_day, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, text)
		if _days.size() > 1:
			var last_day := Calendar.format_day(_days[-1])
			draw_string(font, Vector2(plot.position.x, label_y), last_day, HORIZONTAL_ALIGNMENT_RIGHT, plot.size.x, FONT_SIZE, text)

	for i in range(lines.size() - 1, -1, -1):
		_draw_line(plot, lines[i]["values"], lines[i]["colour"], bottom_value, top_value)
	if _values.is_empty():
		return
	var points := _points(plot, _values, bottom_value, top_value)
	for marker in _markers:
		var index: int = marker["index"]
		if index < 0 or index >= points.size():
			continue
		var marker_colour: Color = GameData.PALETTE.get(marker["colour_id"], _colour)
		var x: float = points[index].x
		draw_dashed_line(Vector2(x, plot.position.y), points[index], marker_colour, 1.0, 3.0)
		draw_circle(Vector2(x, plot.position.y), MARKER_HALF + 1.0, marker_colour)
		if int(marker.get("count", 1)) > 1:
			draw_string(font, Vector2(x - 3.0, plot.position.y + 3.0), str(marker["count"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color.BLACK)
	if _inspectable and _selected_index >= 0 and _selected_index < points.size():
		var selected: Vector2 = points[_selected_index]
		draw_line(Vector2(selected.x, plot.position.y), Vector2(selected.x, plot.end.y), text, 1.0)
		draw_circle(selected, 6.0, _colour)
		draw_circle(selected, 3.0, Color.BLACK)


func _points(plot: Rect2, values: Array, bottom_value: int, top_value: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	var step := plot.size.x / float(maxi(1, values.size() - 1))
	for i in values.size():
		var ratio := float(values[i] - bottom_value) / float(top_value - bottom_value) if top_value > bottom_value else 0.0
		var x := plot.position.x + (plot.size.x * 0.5 if values.size() == 1 else step * i)
		points.append(Vector2(x, plot.end.y - ratio * plot.size.y))
	return points


func _draw_line(plot: Rect2, values: Array, colour: Color, bottom_value: int, top_value: int) -> void:
	var points := _points(plot, values, bottom_value, top_value)
	if points.size() > 1:
		draw_polyline(points, colour, LINE_WIDTH, true)
	for point in points:
		draw_circle(point, POINT_RADIUS, colour)

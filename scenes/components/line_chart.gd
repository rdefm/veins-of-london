class_name LineChart
extends Control

# One-series line chart for the BizBrief Stats tab: values oldest first,
# plotted against a zero baseline and the series max, with the max value at
# top left and the first/last day under the x axis. Presentation only;
# colours are data/palette.json ids (docs/ui-vision.md §6).

const CHART_HEIGHT := 120.0
const PAD_LEFT := 4.0
const PAD_TOP := 18.0
const PAD_BOTTOM := 18.0
const PAD_RIGHT := 4.0
const LINE_WIDTH := 2.0
const POINT_RADIUS := 2.5
const FONT_SIZE := 12

const GRID_ID := "phone_divider"
const TEXT_ID := "phone_text_muted"
const FALLBACK_GRID := Color("#424246")
const FALLBACK_TEXT := Color("#999a9d")

var _values: Array[int] = []
var _days: Array[int] = []
var _colour := Color.WHITE
var _prefix := ""


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


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var grid: Color = GameData.PALETTE.get(GRID_ID, FALLBACK_GRID)
	var text: Color = GameData.PALETTE.get(TEXT_ID, FALLBACK_TEXT)
	var plot := Rect2(PAD_LEFT, PAD_TOP, size.x - PAD_LEFT - PAD_RIGHT, size.y - PAD_TOP - PAD_BOTTOM)
	var top_value := 0
	for value in _values:
		top_value = maxi(top_value, value)

	draw_line(plot.position, Vector2(plot.end.x, plot.position.y), grid, 1.0)
	draw_line(Vector2(plot.position.x, plot.end.y), plot.end, grid, 1.0)
	draw_string(font, Vector2(PAD_LEFT, PAD_TOP - 4.0), "%s%d" % [_prefix, top_value], HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, text)
	if not _days.is_empty():
		var label_y := size.y - 4.0
		draw_string(font, Vector2(PAD_LEFT, label_y), "Day %d" % _days[0], HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, text)
		draw_string(font, Vector2(PAD_LEFT, label_y), "Day %d" % _days[-1], HORIZONTAL_ALIGNMENT_RIGHT, plot.size.x, FONT_SIZE, text)

	if _values.is_empty():
		return
	var points := PackedVector2Array()
	var step := plot.size.x / float(maxi(1, _values.size() - 1))
	for i in _values.size():
		var ratio := float(_values[i]) / float(top_value) if top_value > 0 else 0.0
		points.append(Vector2(plot.position.x + step * i, plot.end.y - ratio * plot.size.y))
	if points.size() > 1:
		draw_polyline(points, _colour, LINE_WIDTH, true)
	for point in points:
		draw_circle(point, POINT_RADIUS, _colour)

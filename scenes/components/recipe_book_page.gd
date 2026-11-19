class_name RecipeBookPage
extends Control

# The ring-bound recipe page (docs/hq-diorama-vision.md §5.2): the blank side-tab
# art drawn aspect-fit, with child controls placed by rects in the art's own
# 1024x1536 pixel space so they follow the page at any size. crop() shows
# just a strip of the same art. Built with RECIPE_TEXTURE instead, it is the
# recipe page: slot 0's header over plain ruled lines (spec lab-recipe-page § Art).

const PAGE_TEXTURE := "res://assets/hq/recipe-book-side-tabs-blank.png"
const RECIPE_TEXTURE := "res://assets/hq/recipe-book-recipe-page-blank.png"
# Recipe page ruled-line top edges, art y: the header's four (name, cost,
# stock, best rank), then the evenly spaced body lines below its divider.
const RECIPE_HEADER_LINES := [252.0, 300.0, 399.0, 442.0]
const RECIPE_BODY_LINES := [
	503.0, 547.0, 591.0, 635.0, 679.0, 723.0, 767.0, 811.0, 855.0, 899.0,
	943.0, 987.0, 1031.0, 1075.0, 1119.0, 1163.0, 1207.0, 1251.0, 1295.0, 1339.0,
]
const RECIPE_LINE_X := 200.0
const RECIPE_LINE_W := 628.0
const FONT_PATH := "res://assets/fonts/PixelifySans.ttf"
const ART_SIZE := Vector2(1024, 1536)
const INK := Color("#4a3320")
const INK_MUTED := Color("#7a6246")
const PENCIL := Color("#7d776e")
const LINE_LIFT := 3.0

static var _font: Font

var art_size := ART_SIZE
var texture_path: String
var _page: TextureRect
var _placed: Array = []


static func font() -> Font:
	if _font == null:
		_font = load(FONT_PATH)
	return _font


func _init(path: String = PAGE_TEXTURE) -> void:
	texture_path = path
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	custom_minimum_size = Vector2(260, 390)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	_page = TextureRect.new()
	_page.texture = load(texture_path)
	_page.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_page.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.anchor_full_rect(_page)
	add_child(_page)
	resized.connect(_layout)


# Shows only `region` of the page art; placed rects are then in that
# region's own pixel space.
func crop(region: Rect2) -> void:
	var atlas := AtlasTexture.new()
	atlas.atlas = load(texture_path)
	atlas.region = region
	_page.texture = atlas
	art_size = region.size
	custom_minimum_size = Vector2(160.0, 160.0 * region.size.y / region.size.x)
	_layout()


func art_scale() -> float:
	return minf(size.x / art_size.x, size.y / art_size.y)


func art_origin() -> Vector2:
	return (size - art_size * art_scale()) * 0.5


# Rect on screen for an art-space rect.
func to_local_rect(art_rect: Rect2) -> Rect2:
	var s := art_scale()
	return Rect2(art_origin() + art_rect.position * s, art_rect.size * s)


# Parks `node` at an art-space rect; font_size > 0 also scales its text (floored at min_font).
func place(node: Control, art_rect: Rect2, font_size: float = 0.0, min_font: int = 9) -> void:
	add_child(node)
	_placed.append({ "node": node, "rect": art_rect, "font": font_size, "min": min_font })
	_apply(_placed[-1])


# Parks a one-line `label` so its text baseline sits `LINE_LIFT` art px above
# the ruled line whose top edge is at art y `line_y`, from art x `x` across `width`.
func place_on_line(label: Label, x: float, width: float, line_y: float, font_size: float, min_font: int = 9) -> void:
	add_child(label)
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_placed.append({ "node": label, "rect": Rect2(x, line_y - LINE_LIFT, width, 0.0), "font": font_size, "min": min_font, "baseline": true })
	_apply(_placed[-1])


# place_on_line for a word-wrapped `label` over `lines` ruled lines spaced
# `pitch` art px apart, each wrapped line's baseline on its own ruled line.
func place_on_lines(label: Label, x: float, width: float, line_y: float, pitch: float, lines: int, font_size: float, min_font: int = 9) -> void:
	add_child(label)
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.max_lines_visible = lines
	_placed.append({ "node": label, "rect": Rect2(x, line_y - LINE_LIFT, width, 0.0), "font": font_size, "min": min_font, "baseline": true, "pitch": pitch, "lines": lines })
	_apply(_placed[-1])


func _layout() -> void:
	for entry in _placed:
		_apply(entry)


func _apply(entry: Dictionary) -> void:
	var node: Control = entry["node"]
	var r := to_local_rect(entry["rect"])
	if entry.get("baseline", false):
		var px := maxi(int(round(entry["font"] * art_scale())), entry["min"])
		var f: Font = node.get_theme_font("font")
		node.add_theme_font_size_override("font_size", px)
		node.position = Vector2(r.position.x, r.position.y - f.get_ascent(px))
		node.size = Vector2(r.size.x, f.get_height(px))
		if entry.has("pitch"):
			var pitch: float = entry["pitch"] * art_scale()
			node.add_theme_constant_override("line_spacing", int(round(pitch - f.get_height(px))))
			node.size.y = f.get_height(px) + pitch * (entry["lines"] - 1)
		return
	node.position = r.position
	node.size = r.size
	if entry["font"] > 0.0:
		var px := maxi(int(round(entry["font"] * art_scale())), entry["min"])
		if node is Label:
			node.add_theme_font_size_override("font_size", px)
		elif node is Button:
			node.add_theme_font_size_override("font_size", px)


# A pencilled hook from the top of its rect down and right into an arrowhead
# at its bottom-right, tying a margin note to the line above it.
class MarginArrow extends Control:
	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var tip := Vector2(size.x - 1.0, size.y * 0.75)
		var head := minf(4.0, size.x * 0.3)
		draw_polyline(PackedVector2Array([Vector2(size.x * 0.3, 0), Vector2(size.x * 0.3, tip.y), tip]), PENCIL, 1.5)
		draw_polyline(PackedVector2Array([tip + Vector2(-head, -head), tip, tip + Vector2(-head, head)]), PENCIL, 1.5)


# Largest font size (art px, floored at `floor`) at which `text` fits one line of `width`.
static func fit_font(text: String, width: float, start: float, floor_size: float) -> float:
	var size := start
	var f := font()
	while size > floor_size and f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, int(size)).x > width:
		size -= 2.0
	return size


# Lines `text` word-wraps to across `width` at `font_size` (both art px).
static func line_count(text: String, width: float, font_size: float) -> int:
	var f := font()
	var lines := 1
	var line := ""
	for word in text.split(" ", false):
		var candidate: String = word if line == "" else line + " " + word
		if line != "" and f.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1, int(font_size)).x > width:
			lines += 1
			line = word
		else:
			line = candidate
	return lines

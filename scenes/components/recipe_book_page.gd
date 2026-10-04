class_name RecipeBookPage
extends Control

# The ring-bound recipe page (docs/hq-diorama-vision.md §5.2): the blank side-tab
# art drawn aspect-fit, with child controls placed by rects in the art's own
# 1024x1536 pixel space so they follow the page at any size.

const PAGE_TEXTURE := "res://assets/hq/recipe-book-side-tabs-blank.png"
const FONT_PATH := "res://assets/fonts/PixelifySans.ttf"
const ART_SIZE := Vector2(1024, 1536)
const INK := Color("#4a3320")
const INK_MUTED := Color("#7a6246")

static var _font: Font

var _page: TextureRect
var _placed: Array = []


static func font() -> Font:
	if _font == null:
		_font = load(FONT_PATH)
	return _font


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	custom_minimum_size = Vector2(260, 390)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	_page = TextureRect.new()
	_page.texture = load(PAGE_TEXTURE)
	_page.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_page.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.anchor_full_rect(_page)
	add_child(_page)
	resized.connect(_layout)


func art_scale() -> float:
	return minf(size.x / ART_SIZE.x, size.y / ART_SIZE.y)


func art_origin() -> Vector2:
	return (size - ART_SIZE * art_scale()) * 0.5


# Rect on screen for an art-space rect.
func to_local_rect(art_rect: Rect2) -> Rect2:
	var s := art_scale()
	return Rect2(art_origin() + art_rect.position * s, art_rect.size * s)


# Parks `node` at an art-space rect; font_size > 0 also scales its text (floored at min_font).
func place(node: Control, art_rect: Rect2, font_size: float = 0.0, min_font: int = 9) -> void:
	add_child(node)
	_placed.append({ "node": node, "rect": art_rect, "font": font_size, "min": min_font })
	_apply(_placed[-1])


func _layout() -> void:
	for entry in _placed:
		_apply(entry)


func _apply(entry: Dictionary) -> void:
	var node: Control = entry["node"]
	var r := to_local_rect(entry["rect"])
	node.position = r.position
	node.size = r.size
	if entry["font"] > 0.0:
		var px := maxi(int(round(entry["font"] * art_scale())), entry["min"])
		if node is Label:
			node.add_theme_font_size_override("font_size", px)
		elif node is Button:
			node.add_theme_font_size_override("font_size", px)


# Largest font size (art px, floored at `floor`) at which `text` fits one line of `width`.
static func fit_font(text: String, width: float, start: float, floor_size: float) -> float:
	var size := start
	var f := font()
	while size > floor_size and f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, int(size)).x > width:
		size -= 2.0
	return size

class_name DepartureBoardCasing
extends Control

# Physical sign housing around the top board's dot-matrix face
# (ui-vision.md §5): dark metal frame, corner bolts, recessed bezel with an
# inner shadow. FRAME_IMAGE_PATH is an optional nine-patch bitmap slot; the
# code-drawn frame is the fallback when it isn't shipped.

const FRAME_IMAGE_PATH := "res://assets/ui/departure_board_frame.png"
const FRAME_PATCH_MARGIN := 12  # nine-patch margin in the bitmap, px per side

const FRAME_THICKNESS := 5.0
const CASING_COLOR := Color(0.16, 0.165, 0.17, 1)
const CASING_HIGHLIGHT := Color(0.34, 0.35, 0.36, 1)
const CASING_SHADOW := Color(0.06, 0.06, 0.065, 1)
const BOLT_COLOR := Color(0.42, 0.43, 0.44, 1)
const BOLT_SHADE := Color(0.09, 0.09, 0.1, 1)
const BOLT_RADIUS := 1.5
const INNER_SHADOW := Color(0, 0, 0, 0.55)
const INNER_SHADOW_DEPTH := 3

var _frame_style: StyleBoxTexture


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame_style = load_frame_style()


static func load_frame_style() -> StyleBoxTexture:
	if not ResourceLoader.exists(FRAME_IMAGE_PATH):
		return null
	var style := StyleBoxTexture.new()
	style.texture = load(FRAME_IMAGE_PATH) as Texture2D
	style.draw_center = false
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		style.set_texture_margin(side, FRAME_PATCH_MARGIN)
	return style


static func face_rect(casing_size: Vector2) -> Rect2:
	return Rect2(Vector2(FRAME_THICKNESS, FRAME_THICKNESS), casing_size - Vector2(FRAME_THICKNESS, FRAME_THICKNESS) * 2.0)


func _draw() -> void:
	if _frame_style != null:
		draw_style_box(_frame_style, Rect2(Vector2.ZERO, size))
	else:
		render_fallback(self)


# Paints only the housing; the face's bezel is render_bezel(), drawn later.
func render_fallback(target: Object) -> void:
	var full := Rect2(Vector2.ZERO, size)
	target.draw_rect(full, CASING_COLOR, true)
	target.draw_line(Vector2(0, 0.5), Vector2(size.x, 0.5), CASING_HIGHLIGHT, 1.0)
	target.draw_line(Vector2(0, size.y - 0.5), Vector2(size.x, size.y - 0.5), CASING_SHADOW, 1.0)
	var inset := FRAME_THICKNESS / 2.0
	for corner in [Vector2(inset, inset), Vector2(size.x - inset, inset), Vector2(inset, size.y - inset), Vector2(size.x - inset, size.y - inset)]:
		target.draw_circle(corner + Vector2(0.5, 0.5), BOLT_RADIUS, BOLT_SHADE)
		target.draw_circle(corner, BOLT_RADIUS, BOLT_COLOR)


# Recessed bezel: a dark rim plus a top/left inner shadow falling onto the
# face. Drawn above the face contents by TopBar's bezel overlay.
static func render_bezel(target: Object, face: Rect2) -> void:
	target.draw_rect(face.grow(0.5), CASING_SHADOW, false, 1.0)
	for i in INNER_SHADOW_DEPTH:
		var alpha: float = INNER_SHADOW.a * (1.0 - float(i) / INNER_SHADOW_DEPTH)
		var c := Color(INNER_SHADOW, alpha)
		target.draw_line(face.position + Vector2(0, i + 0.5), Vector2(face.end.x, face.position.y + i + 0.5), c, 1.0)
		target.draw_line(face.position + Vector2(i + 0.5, 0), Vector2(face.position.x + i + 0.5, face.end.y), c, 1.0)

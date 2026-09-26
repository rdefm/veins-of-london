class_name HqDiorama
extends Control


const PLACEHOLDER_FILL := Color(0.30, 0.30, 0.34, 0.85)
const PLACEHOLDER_BORDER := Color(0.85, 0.85, 0.80)
const DEBUG_OUTLINE_COLOR := Color(1.0, 0.1, 0.75)
const DEBUG_LABEL_COLOR := Color(1.0, 1.0, 1.0)
const DEBUG_LABEL_MARGIN := Vector2(3.0, 13.0)
const SELECTED_OUTLINE_PALETTE_ID := "calc_gold"
const SELECTED_OUTLINE_WIDTH := 3.0

var _plate: Dictionary = {}
var _background_texture: TextureRect
var _background_fill: ColorRect
var _region_sprites: Dictionary = {}
var _debug_overlay_enabled: bool = false
var _captions: Array[Label] = []


func _init() -> void:
	_background_fill = ColorRect.new()
	_background_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_background_fill.z_index = -1
	add_child(_background_fill)

	_background_texture = TextureRect.new()
	_background_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_background_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_background_texture.visible = false
	_background_texture.z_index = -1
	add_child(_background_texture)


func build(plate: Dictionary) -> void:
	for caption in _captions:
		caption.free()
	_captions.clear()
	for sprite in _region_sprites.values():
		sprite.queue_free()
	_region_sprites.clear()

	_plate = plate
	var plate_size := Vector2(plate.get("width", 0.0), plate.get("height", 0.0))
	custom_minimum_size = plate_size
	size = plate_size

	var image_path: String = plate.get("image", "")
	var background_texture: Texture2D = load(image_path) if not image_path.is_empty() else null
	if background_texture != null:
		_background_texture.texture = background_texture
		_background_texture.position = Vector2.ZERO
		_background_texture.size = plate_size
		_background_texture.visible = true
		_background_fill.visible = false
	else:
		_background_fill.color = GameData.PALETTE.get(plate.get("fallbackColor", ""), Color.BLACK)
		_background_fill.position = Vector2.ZERO
		_background_fill.size = plate_size
		_background_fill.visible = true
		_background_texture.visible = false

	var regions: Dictionary = plate.get("regions", {})
	for region_id in regions:
		var region: Dictionary = regions[region_id]
		var sprite_path: String = region.get("image", "")
		if sprite_path.is_empty():
			continue
		var texture: Texture2D = load(sprite_path)
		if texture == null:
			continue
		var sprite := TextureRect.new()
		sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sprite.texture = texture
		sprite.position = region_rect(region).position
		sprite.size = region_rect(region).size
		add_child(sprite)
		_region_sprites[region_id] = sprite

	for region_id in regions:
		var region: Dictionary = regions[region_id]
		if not region.has("caption"):
			continue
		var caption := UI.label(region["caption"])
		caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var band := caption_rect(region, caption.get_minimum_size().y)
		caption.position = band.position
		caption.size.x = band.size.x
		if region.has("polygon"):
			caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.add_theme_color_override("font_color", Color.WHITE)
		caption.add_theme_color_override("font_shadow_color", Color.BLACK)
		caption.add_theme_constant_override("shadow_offset_x", 1)
		caption.add_theme_constant_override("shadow_offset_y", 1)
		add_child(caption)
		_captions.append(caption)

	queue_redraw()


func set_debug_overlay_enabled(enabled: bool) -> void:
	_debug_overlay_enabled = enabled
	queue_redraw()


func is_debug_overlay_enabled() -> bool:
	return _debug_overlay_enabled


func region_rects() -> Dictionary:
	var result: Dictionary = {}
	var regions: Dictionary = _plate.get("regions", {})
	for region_id in regions:
		result[region_id] = region_rect(regions[region_id])
	return result


# The first region whose hit shape contains `point` (plate-local), or "".
func zone_at(point: Vector2) -> String:
	var hits := regions_at(_plate.get("regions", {}), point)
	return hits[0] if not hits.is_empty() else ""


# A region's hit shape is its traced polygon when it has one, else its
# x/y/width/height rect (docs/hq-diorama-vision.md §3.2).
static func region_contains(region: Dictionary, point: Vector2) -> bool:
	if region.has("polygon"):
		return Geometry2D.is_point_in_polygon(point, polygon_points(region["polygon"]))
	return region_rect(region).has_point(point)


static func regions_at(regions: Dictionary, point: Vector2) -> Array[String]:
	var hits: Array[String] = []
	for id in regions:
		if region_contains(regions[id], point):
			hits.append(id)
	return hits


static func polygon_points(points: Array) -> PackedVector2Array:
	var packed := PackedVector2Array()
	for p in points:
		packed.append(Vector2(p[0], p[1]))
	return packed


static func polygon_bounds(points: Array) -> Rect2:
	var box := Rect2(Vector2(points[0][0], points[0][1]), Vector2.ZERO)
	for p in points:
		box = box.expand(Vector2(p[0], p[1]))
	return box


static func region_rect(region: Dictionary) -> Rect2:
	return Rect2(region.get("x", 0.0), region.get("y", 0.0), region.get("width", 0.0), region.get("height", 0.0))


# Where a region's caption sits: its rect's top edge, or for a traced polygon
# a band centred vertically on the polygon's vertex mean, so it lands on the
# painted object rather than on the bounding box's empty corner.
static func caption_rect(region: Dictionary, caption_height: float) -> Rect2:
	if not region.has("polygon"):
		var rect := region_rect(region)
		return Rect2(rect.position, Vector2(rect.size.x, caption_height))
	var points := polygon_points(region["polygon"])
	var mean := Vector2.ZERO
	for p in points:
		mean += p
	mean /= points.size()
	var bounds := polygon_bounds(region["polygon"])
	return Rect2(bounds.position.x, mean.y - caption_height / 2.0, bounds.size.x, caption_height)


func _draw() -> void:
	var regions: Dictionary = _plate.get("regions", {})
	for region_id in regions:
		var region: Dictionary = regions[region_id]
		if not _should_draw_placeholder(region_id, region):
			continue
		_draw_placeholder_box(self, region_rect(region), region.get("label", region_id))

	# A region flagged "selected" gets an outline grown past its rect so it
	# still reads around a region sprite drawn on top.
	var outline_color: Color = GameData.PALETTE.get(SELECTED_OUTLINE_PALETTE_ID, Color.GOLD)
	for region_id in regions:
		if regions[region_id].get("selected", false):
			draw_rect(region_rect(regions[region_id]).grow(SELECTED_OUTLINE_WIDTH), outline_color, false, SELECTED_OUTLINE_WIDTH)

	if _debug_overlay_enabled:
		for region_id in regions:
			_draw_debug_region(self, regions[region_id], region_id)


func _should_draw_placeholder(region_id: String, region: Dictionary) -> bool:
	if _region_sprites.has(region_id):
		return false
	return region.get("placeholder", true)


func _draw_placeholder_box(target: Object, rect: Rect2, label: String) -> void:
	target.draw_rect(rect, PLACEHOLDER_FILL, true)
	target.draw_rect(rect, PLACEHOLDER_BORDER, false, 2.0)
	var font := ThemeDB.fallback_font
	var font_size := ThemeDB.fallback_font_size
	target.draw_string(font, rect.position + DEBUG_LABEL_MARGIN, label, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - DEBUG_LABEL_MARGIN.x * 2.0, font_size, PLACEHOLDER_BORDER)


# Outlines the region's hit shape: its polygon when it has one, else its rect.
func _draw_debug_region(target: Object, region: Dictionary, region_id: String) -> void:
	var rect := region_rect(region)
	if region.has("polygon"):
		var outline := polygon_points(region["polygon"])
		outline.append(outline[0])
		target.draw_polyline(outline, DEBUG_OUTLINE_COLOR, 2.0)
		rect = polygon_bounds(region["polygon"])
	else:
		target.draw_rect(rect, DEBUG_OUTLINE_COLOR, false, 2.0)
	var font := ThemeDB.fallback_font
	var font_size := ThemeDB.fallback_font_size
	target.draw_string(font, rect.position + DEBUG_LABEL_MARGIN, region_id, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x, font_size, DEBUG_LABEL_COLOR)

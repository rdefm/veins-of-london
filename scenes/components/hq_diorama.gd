class_name HqDiorama
extends Control

# hq-diorama ticket 01, docs/hq-diorama-vision.md §9: a generic renderer for
# any plate entry in data/hq_visuals.json (GameData.HQ_VISUALS's "rooms"
# table today; any future sub-view plate that follows the same {image,
# fallbackColor, width, height, regions} shape tomorrow). Reads
# plate.regions entirely generically -- it never hardcodes a zone id, so a
# new region (or a whole new plate) needs no code change here, only a
# manifest edit. Callers (ticket 02's HQ screen) build() this from a
# GameData.HQ_VISUALS["rooms"][tier] entry and read region_rects() to do
# their own tap-hit-testing; this class only renders.
#
# Rendering has two independent layers, per the ticket's own two acceptance
# checks:
#  1. Always on: the plate's background (image, or a data/palette.json
#     fallback fill -- the same two-level fallback data/combat_visuals.json's
#     backdrops use, see GameData._validate_hq_visuals()), plus a labelled
#     placeholder box in every region whose own "image" is empty. This is
#     what makes the room navigable and tappable with zero art produced.
#     hq-diorama ticket 18: a region can opt out of the placeholder box with
#     "placeholder": false even while "image" stays empty -- for a region
#     whose art is already baked into the plate's own background image (see
#     data/hq_visuals.json's "labBench" meta.labBench note on the notebook
#     regions) rather than drawn as its own sprite. The region stays fully
#     tappable either way -- region_rects() never reads this field.
#  2. Debug-only, toggled at runtime via set_debug_overlay_enabled(): every
#     region's rect drawn again on top, outlined, with its id as text --
#     "hit region + sprite rect" are the same rect in this manifest's own
#     schema (a region's art, once produced, is baked at exactly the rect
#     that is also its tap area), so one outline pass covers both.

const PLACEHOLDER_FILL := Color(0.30, 0.30, 0.34, 0.85)
const PLACEHOLDER_BORDER := Color(0.85, 0.85, 0.80)
const DEBUG_OUTLINE_COLOR := Color(1.0, 0.1, 0.75)
const DEBUG_LABEL_COLOR := Color(1.0, 1.0, 1.0)
const DEBUG_LABEL_MARGIN := Vector2(3.0, 13.0)

var _plate: Dictionary = {}
var _background_texture: TextureRect
var _background_fill: ColorRect
# region id -> TextureRect, for regions whose own "image" loaded
# successfully -- built fresh in build(), tracked so _draw() knows to skip
# the placeholder box for exactly those regions.
var _region_sprites: Dictionary = {}
var _debug_overlay_enabled: bool = false
var _captions: Array[Label] = []


func _init() -> void:
	# z_index -1 pins both background layers behind this Control's own
	# _draw() (placeholder boxes + debug overlay) -- Godot draws a Control's
	# own _draw() first and its children on top by default, and these two
	# are added as children, so without this every placeholder box (and the
	# debug overlay) would render fully hidden under a full-plate background
	# fill/texture. Region sprites (added later in build()) stay at the
	# default z_index 0, on top of both.
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


# Rebuilds this control from a data/hq_visuals.json plate entry (e.g.
# GameData.HQ_VISUALS["rooms"]["bedsit"]). Safe to call again (e.g. on a
# tier change) -- clears out the previous build's region sprites first.
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
		sprite.position = _region_rect(region).position
		sprite.size = _region_rect(region).size
		add_child(sprite)
		_region_sprites[region_id] = sprite

	# Optional action captions remain readable when the region has finished art.
	for region_id in regions:
		var region: Dictionary = regions[region_id]
		if not region.has("caption"):
			continue
		var caption := UI.label(region["caption"])
		caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
		caption.position = _region_rect(region).position
		caption.size.x = _region_rect(region).size.x
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


# region id -> Rect2 in this control's own coordinate space, for callers to
# do their own tap-hit-testing against. Built fresh from whatever
# _plate.regions currently holds, never cached, so it always matches the
# most recent build().
func region_rects() -> Dictionary:
	var result: Dictionary = {}
	var regions: Dictionary = _plate.get("regions", {})
	for region_id in regions:
		result[region_id] = _region_rect(regions[region_id])
	return result


func _region_rect(region: Dictionary) -> Rect2:
	return Rect2(region.get("x", 0.0), region.get("y", 0.0), region.get("width", 0.0), region.get("height", 0.0))


func _draw() -> void:
	var regions: Dictionary = _plate.get("regions", {})
	for region_id in regions:
		var region: Dictionary = regions[region_id]
		if not _should_draw_placeholder(region_id, region):
			continue
		_draw_placeholder_box(self, _region_rect(region), region.get("label", region_id))

	if _debug_overlay_enabled:
		for region_id in regions:
			_draw_debug_region(self, _region_rect(regions[region_id]), region_id)


# A region skips its placeholder box when either its own "image" already
# loaded a sprite (_region_sprites), or the manifest opts it out explicitly
# via "placeholder": false (ticket 18 -- a region whose art is baked into
# the plate's background rather than drawn as its own sprite). Split out as
# its own pure function, rather than inlined in _draw(), so tests can assert
# on the skip decision without a live draw context.
func _should_draw_placeholder(region_id: String, region: Dictionary) -> bool:
	if _region_sprites.has(region_id):
		return false
	return region.get("placeholder", true)


# Split out from _draw() with a `target` param (mirroring map_canvas.gd's
# own _draw_*(..., target: Object = self) convention) so tests can pass a
# DrawSpy and assert on the recorded calls without a live Viewport.
func _draw_placeholder_box(target: Object, rect: Rect2, label: String) -> void:
	target.draw_rect(rect, PLACEHOLDER_FILL, true)
	target.draw_rect(rect, PLACEHOLDER_BORDER, false, 2.0)
	var font := ThemeDB.fallback_font
	var font_size := ThemeDB.fallback_font_size
	target.draw_string(font, rect.position + DEBUG_LABEL_MARGIN, label, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - DEBUG_LABEL_MARGIN.x * 2.0, font_size, PLACEHOLDER_BORDER)


func _draw_debug_region(target: Object, rect: Rect2, region_id: String) -> void:
	target.draw_rect(rect, DEBUG_OUTLINE_COLOR, false, 2.0)
	var font := ThemeDB.fallback_font
	var font_size := ThemeDB.fallback_font_size
	target.draw_string(font, rect.position + DEBUG_LABEL_MARGIN, region_id, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x, font_size, DEBUG_LABEL_COLOR)

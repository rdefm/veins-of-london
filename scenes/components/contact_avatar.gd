class_name ContactAvatar
extends RefCounted

const DIR := "res://assets/contacts/"


static func path(contact_id: String) -> String:
	return "%s%s.png" % [DIR, contact_id]


# Headshot texture for the contact, or null when no image has been supplied.
static func texture(contact_id: String) -> Texture2D:
	var file := path(contact_id)
	if not ResourceLoader.exists(file):
		return null
	return load(file) as Texture2D


# Copy of `tex` with the corners outside `radius` (in avatar px at `size`)
# made transparent; baked into alpha so no renderer clip mode is needed.
static func _rounded(tex: Texture2D, size: float, radius: int) -> Texture2D:
	var img := tex.get_image()
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	var w := img.get_width()
	var h := img.get_height()
	var r := minf(float(radius) / size * minf(w, h), minf(w, h) / 2.0)
	for y in range(h):
		for x in range(w):
			var cx := clampf(x + 0.5, r, w - r)
			var cy := clampf(y + 0.5, r, h - r)
			if Vector2(x + 0.5 - cx, y + 0.5 - cy).length() > r:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	return ImageTexture.create_from_image(img)


# Rounded avatar: the contact's headshot (nearest-filtered, cover-cropped) or,
# without an image, `initials` on `fill`. `radius` rounds the corners; use
# size / 2 for a circle.
static func build(contact_id: String, size: float, radius: int, initials: String,
		fill: Color, ink: Color, font_size: int, font: Font = null) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.set_corner_radius_all(radius)
	panel.add_theme_stylebox_override("panel", style)
	panel.set_meta(ContactCards.OWN_STYLE_META, true)
	panel.custom_minimum_size = Vector2(size, size)
	panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var tex := texture(contact_id)
	if tex != null:
		style.bg_color = Color(0, 0, 0, 0)
		var rect := TextureRect.new()
		rect.texture = _rounded(tex, size, radius)
		rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		panel.add_child(rect)
		return panel
	var label := Label.new()
	label.text = initials
	label.add_theme_color_override("font_color", ink)
	label.add_theme_font_size_override("font_size", font_size)
	if font != null:
		label.add_theme_font_override("font", font)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(label)
	return panel

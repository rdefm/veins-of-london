class_name MapLegend
extends Control


const SWATCH_SIZE := 16.0
const PANEL_OFFSET := Vector2(8.0, 8.0)
const CARD_RADIUS := 12
const CARD_WIDTH := 152.0
const CARD_MARGIN_H := 10.0
const CARD_MARGIN_TOP := 6.0
const CARD_MARGIN_BOTTOM := 8.0
const CONTENT_SEPARATION := 8.0

var _panel: PanelContainer
var _header: Button
var _title: Label
var _chevron: Label
var _divider: ColorRect
var _rows: VBoxContainer
var _expanded: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_panel = PanelContainer.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_theme_stylebox_override("panel", _card_style())
	add_child(_panel)

	var content := UI.vbox(8)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(content)

	_header = Button.new()
	_header.tooltip_text = "Toggle faction key"
	_header.custom_minimum_size = Vector2(CARD_WIDTH, UI.ICON_BUTTON_SIZE)
	_header.size = _header.custom_minimum_size
	var ink := MapPalette.colour("ink")
	_header.add_theme_stylebox_override("normal", _header_style(Color.TRANSPARENT))
	_header.add_theme_stylebox_override("hover", _header_style(Color(ink, 0.06)))
	_header.add_theme_stylebox_override("pressed", _header_style(Color(ink, 0.12)))
	_header.add_theme_stylebox_override("focus", _header_style(Color(ink, 0.06)))
	_header.pressed.connect(_on_header_pressed)
	content.add_child(_header)

	var header_content := UI.hbox(8)
	UI.anchor_full_rect(header_content)
	header_content.offset_left = 4.0
	header_content.offset_right = -4.0
	header_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_header.add_child(header_content)

	_title = Label.new()
	_title.text = "Factions"
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.add_theme_font_size_override("font_size", 18)
	_title.add_theme_color_override("font_color", MapPalette.colour("ink"))
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header_content.add_child(_title)

	_chevron = Label.new()
	_chevron.add_theme_font_size_override("font_size", 18)
	_chevron.add_theme_color_override("font_color", MapPalette.colour("ink"))
	_chevron.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header_content.add_child(_chevron)

	_divider = ColorRect.new()
	_divider.color = MapPalette.colour("border")
	_divider.custom_minimum_size.y = 1.0
	_divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(_divider)

	_rows = UI.vbox(6)
	_rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(_rows)
	_build_rows()
	_apply_expanded_state()


func _build_rows() -> void:
	for faction_id in GameData.FACTIONS.keys():
		_rows.add_child(_build_row(GameData.FACTIONS[faction_id]))


func _build_row(faction: Dictionary) -> Control:
	var row := UI.hbox(8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var swatch := ColorRect.new()
	swatch.color = MapPalette.faction_colour(faction["id"])
	swatch.custom_minimum_size = Vector2(SWATCH_SIZE, SWATCH_SIZE)
	swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(swatch)

	var name_label := Label.new()
	name_label.text = String(faction["shortName"])
	name_label.add_theme_color_override("font_color", MapPalette.colour("ink"))
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(name_label)

	return row


func _on_header_pressed() -> void:
	_expanded = not _expanded
	_apply_expanded_state()


func _apply_expanded_state() -> void:
	_chevron.text = "▾" if _expanded else "▸"
	_divider.visible = _expanded
	_rows.visible = _expanded
	_reposition.call_deferred()
	_reposition()


func _card_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = MapPalette.colour("chromePaper")
	style.set_border_width_all(1)
	style.border_color = MapPalette.colour("border")
	style.set_corner_radius_all(CARD_RADIUS)
	style.content_margin_left = CARD_MARGIN_H
	style.content_margin_top = CARD_MARGIN_TOP
	style.content_margin_right = CARD_MARGIN_H
	style.content_margin_bottom = CARD_MARGIN_BOTTOM
	style.shadow_color = Color(MapPalette.colour("shadow"), 0.13)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0.0, 3.0)
	return style


func _header_style(fill: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.set_corner_radius_all(CARD_RADIUS - 2)
	style.content_margin_left = 2.0
	style.content_margin_top = 4.0
	style.content_margin_right = 2.0
	style.content_margin_bottom = 4.0
	return style


func _reposition() -> void:
	var rows_minimum := _rows.get_combined_minimum_size()
	var inner_width := maxf(CARD_WIDTH, rows_minimum.x)
	var inner_height := UI.ICON_BUTTON_SIZE
	if _expanded:
		inner_height += CONTENT_SEPARATION * 2.0 + _divider.custom_minimum_size.y + rows_minimum.y
	_panel.size = Vector2(
		inner_width + CARD_MARGIN_H * 2.0,
		inner_height + CARD_MARGIN_TOP + CARD_MARGIN_BOTTOM
	)
	_panel.position = PANEL_OFFSET
	size = _panel.size + PANEL_OFFSET

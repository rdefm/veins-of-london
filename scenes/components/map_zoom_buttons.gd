class_name MapZoomButtons
extends Control

# Bugfixes ticket 89: a floating +/- zoom control over the Network diagram,
# TfL/Citymapper-style — a reliable alternative to the two-finger pinch
# gesture (#88's history of drift bugs) that used to also drive zoom; bugfixes
# ticket 99 later removed that gesture entirely, so these buttons are now the
# only way to zoom. Built once by map.gd's _build_diagram_layer() (like
# _map_legend) and added as a sibling of the diagram's scroll view inside
# diagram_area, so it floats over the canvas at a fixed screen position
# rather than scrolling/zooming with the content. Placement is the diagram
# area's bottom-right corner specifically — MapLegend already owns top-left,
# and the ticket calls out this control must NOT go inside MapControls'
# hamburger drawer or the top bar.
#
# Caller sets `map_canvas` before adding this to the tree, same "assign then
# add" idiom map_controls.gd's own class comment documents (and for the same
# reason: _ready() below reads map_canvas.zoom_level immediately to seed the
# buttons' disabled state).
#
# Same "PanelContainer/Control not managed by a parent Container, so size and
# position it by hand" shape map_legend.gd's own _panel/_reposition() use —
# except anchored to the BOTTOM-right corner (grow direction begin) rather
# than sitting at a zero offset from the top-left, since this corner moves
# with the diagram area's own size while the top-left one doesn't.

const MARGIN := Vector2(8.0, 8.0)
const BUTTON_SIZE := Vector2(UI.ICON_BUTTON_SIZE, UI.ICON_BUTTON_SIZE)

var map_canvas: MapCanvas

var _box: VBoxContainer
var _zoom_in_button: Button
var _zoom_out_button: Button


func _ready() -> void:
	# Ignored so a tap anywhere in this Control's own (empty, zero-sized —
	# see class comment) rect falls through to the diagram underneath; only
	# _box's real buttons below ever claim input, same split map_legend.gd's
	# own top-level Control/_panel use.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	offset_left = 0
	offset_top = 0
	offset_right = 0
	offset_bottom = 0
	grow_horizontal = Control.GROW_DIRECTION_BEGIN
	grow_vertical = Control.GROW_DIRECTION_BEGIN

	_box = UI.vbox(6)
	add_child(_box)

	# Plain "+"/"-" text, not an Icons vector glyph — both are already
	# plain ASCII (unlike the top bar's old "☰"/"🎒", ticket 13's reason for
	# switching those to Icons.draw_*), so they render fine on-device, same
	# as the vein station row's existing "-5"/"+5" buttons (map.gd).
	#
	# Bugfixes ticket 99: UI.button() already sizes custom_minimum_size.x to
	# fit its own glyph without clipping (text_width + the Button stylebox's
	# own content margins — see its own comment). BUTTON_SIZE below is a
	# touch-target floor, not a cap, so it's applied via component-wise max()
	# rather than a flat overwrite — a flat overwrite is exactly what broke
	# "+" here: the "+" glyph (10px) plus the theme's 32px of left+right
	# content margin needs 42px to draw without clipping, but BUTTON_SIZE.x
	# is only 40px, 2px short, so clip_text (see UI.button()'s own comment)
	# silently trimmed it down to nothing under OVERRUN_TRIM_ELLIPSIS. "-"
	# (6px glyph, 38px natural width) happened to fit under the same 40px
	# override, which is why only "+" went invisible despite both buttons
	# sharing identical styling.
	_zoom_in_button = UI.button("+", func(): map_canvas.step_zoom(1))
	_zoom_in_button.custom_minimum_size = _zoom_in_button.custom_minimum_size.max(BUTTON_SIZE)
	_box.add_child(_zoom_in_button)

	_zoom_out_button = UI.button("-", func(): map_canvas.step_zoom(-1))
	_zoom_out_button.custom_minimum_size = _zoom_out_button.custom_minimum_size.max(BUTTON_SIZE)
	_box.add_child(_zoom_out_button)

	if map_canvas != null:
		# zoom_level changes continuously through step_zoom()'s own animated
		# pan_to(), so this stays correct whether the bound was reached by
		# this control's own button or not
		# — reading map_canvas.zoom_level fresh each time rather than trusting
		# the signal's own argument keeps this in sync even for whichever of
		# the two fires _ready()/this connection second (see class comment).
		map_canvas.zoom_changed.connect(_update_disabled)
	_update_disabled()
	_reposition()


func _update_disabled(_zoom: float = 0.0) -> void:
	if map_canvas == null:
		return
	_zoom_in_button.disabled = map_canvas.zoom_level >= MapZoom.MAX
	_zoom_out_button.disabled = map_canvas.zoom_level <= MapZoom.MIN


func _reposition() -> void:
	_box.size = _box.get_combined_minimum_size()
	_box.position = -_box.size - MARGIN

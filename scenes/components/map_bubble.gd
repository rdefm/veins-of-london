class_name MapBubble
extends Control

# 10-map-interaction-model ticket 02: a small popup anchored at an arbitrary
# point on the map, listing a handful of tappable options, with whatever's
# behind it (the Network diagram) staying fully visible -- the district/
# station equivalent of ModalLayer's dim+card, but positioned near a tap
# point instead of screen-centred, and sized to a short option list instead
# of a scrolling card. Tickets 03/04 wire this into the district and station
# tap flows; this ticket only delivers the standalone component, open()/
# close()'d directly and exercised in isolation (tests/test_map_bubble.gd)
# rather than from a live map tap.
#
# Same overlay shape as map_controls.gd's drawer / map.gd's own site sheet:
# a full-rect Control (added as a sibling over whatever it should float
# above) holding a transparent-but-STOP dim layer for tap-outside-to-close
# (bugfixes ticket 12's pattern, reused verbatim -- see _on_dim_gui_input)
# plus the actual popup panel. Unlike those two, _dim stays fully
# transparent: this popup must not obscure the map behind it, only the dim
# layers those use to darken a full-screen sheet/drawer.
#
# Positioning is BubbleLayout.popup_position()'s job (systems/bubble_layout.gd)
# -- pure clamping math, unit-tested on its own, same split as MapZoom/
# MapHitTest for MapCanvas.
#
# `anchor`, passed to open(), is a point in this Control's own local rect
# (screen-space, already accounting for whatever pan/zoom/scroll placed it
# there) -- not a logical map point. Converting a district/vein's logical map
# position into that local point is ticket 03/04's job at the call site, not
# this component's.

signal option_selected(option_id: String)
signal closed()

const ICON_SIZE := 20.0

var _dim: ColorRect
var _panel: PanelContainer
var _content: VBoxContainer

var _anchor: Vector2 = Vector2.ZERO
var _bounds_size: Vector2 = Vector2.ZERO


func _ready() -> void:
	UI.anchor_full_rect(self)
	visible = false
	# Ignored while closed so taps fall through to whatever this sits over --
	# only _dim/_panel (below) ever claim input, and only once open() shows
	# them. Same pattern map_controls.gd's drawer and map.gd's own
	# _sheet_layer use.
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_dim = ColorRect.new()
	_dim.color = Color(0, 0, 0, 0)  # transparent -- the diagram must stay fully visible, this only exists to catch the outside tap
	UI.anchor_full_rect(_dim)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim.visible = false
	# Ticket 02: "tapping outside the popup closes it (consistent with
	# 0-bugfixes ticket 12's tap-outside-to-close pattern)" -- without this,
	# STOP just swallows the tap silently.
	_dim.gui_input.connect(_on_dim_gui_input)
	add_child(_dim)

	_panel = PanelContainer.new()
	_panel.visible = false
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_panel)

	_content = UI.vbox(4)
	_panel.add_child(_content)


# `options`: Array of Dictionary { id: String, label: String, icon: Callable
# (optional, an Icons.draw_*-shaped (target, center, colour, scale) -> void
# static func), disabled: bool (optional), reason: String (optional, shown
# muted under the label whenever disabled is true) }.
#
# `bounds_size` is the rect this popup must stay fully inside, in the same
# local space as `anchor` -- normally this Control's own `size` (correct once
# it's actually in a live, sized tree, so that's the default), but callers
# exercising this in isolation (tests, or before a first layout pass) can
# pass it explicitly.
func open(anchor: Vector2, options: Array, bounds_size: Vector2 = Vector2.ZERO) -> void:
	_anchor = anchor
	_bounds_size = bounds_size if bounds_size != Vector2.ZERO else size
	_rebuild(options)
	visible = true
	_dim.visible = true
	_panel.visible = true
	_reposition()


func close() -> void:
	if not visible:
		return
	visible = false
	_dim.visible = false
	_panel.visible = false
	closed.emit()


func _on_dim_gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed:
		close()


func _rebuild(options: Array) -> void:
	# free(), not queue_free(): unlike ModalLayer/MapControls' own rebuilds
	# (triggered by EventBus.state_changed, which can re-enter while one of
	# the very children being torn down is mid-signal), _rebuild() only ever
	# runs from open(), called by an external caller, never from within one
	# of these rows' own pressed handlers -- so there's no re-entrancy risk
	# to defer for, and an immediate free() means back-to-back open() calls
	# (e.g. tapping a second district before this popup's first selection)
	# can't see stale rows still counted as children.
	for child in _content.get_children():
		child.free()
	for option in options:
		_content.add_child(_build_option_row(option))


func _build_option_row(option: Dictionary) -> Control:
	var id: String = option.get("id", "")
	var label_text: String = option.get("label", "")
	var icon: Variant = option.get("icon")
	var disabled: bool = option.get("disabled", false)
	var reason: String = option.get("reason", "")

	var row := UI.vbox(2)

	var b: Button
	if icon is Callable:
		b = _build_icon_label_button(label_text, icon, func(): _select(id))
	else:
		b = UI.button(label_text, func(): _select(id))
	b.disabled = disabled
	row.add_child(b)

	# Ticket 03/04's "disabled with reason, consistent with this repo's
	# existing disabled-not-hidden pattern" -- the option itself already
	# handles the not-hidden half (it's always rendered, just disabled); this
	# is the "with reason" half, a muted line under the button.
	if disabled and reason != "":
		row.add_child(UI.muted_label(reason))

	return row


# Text + a drawn Icons.draw_*-shaped glyph, side by side inside one button --
# UI.icon_button() is glyph-only (map.gd's hamburger/bag, no room for text
# alongside), and UI.button() is text-only, so neither fits an "icon and/or
# text" option on its own.
func _build_icon_label_button(label_text: String, draw_icon: Callable, callback: Callable) -> Button:
	var b := Button.new()
	b.pressed.connect(callback)
	b.clip_text = true
	b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

	var inner := UI.hbox(6)
	# IGNORE so every child below passes taps straight through to `b` itself
	# -- same reasoning UI.icon_button()'s _IconGlyph uses for its own glyph.
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var glyph := UI.icon_glyph_control(draw_icon, 1.0)
	glyph.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	inner.add_child(glyph)

	var text_label := UI.label(label_text)
	text_label.autowrap_mode = TextServer.AUTOWRAP_OFF  # a short option label, not wrapping body text
	text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(text_label)

	b.add_child(inner)
	return b


func _select(option_id: String) -> void:
	close()
	option_selected.emit(option_id)


func _reposition() -> void:
	_apply_position()
	# The panel's real minimum size (driven by the option rows just rebuilt)
	# isn't known until after a layout pass -- same chicken-and-egg
	# ModalLayer._size_card_to_content()'s own comment describes -- so this
	# runs once now (covers it immediately in the common case) and once more
	# deferred (the correction once real content sizes are in).
	_apply_position.call_deferred()


func _apply_position() -> void:
	_panel.size = _panel.get_combined_minimum_size()
	_panel.position = BubbleLayout.popup_position(_anchor, _panel.size, _bounds_size)

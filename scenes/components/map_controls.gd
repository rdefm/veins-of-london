class_name MapControls
extends Control

# M1.5 N4/N5's filter chip row + legend ("?") button, replaced by
# map-filters ticket 03 with a hamburger-triggered drawer (spec.md's
# resolved "Entry chrome": "Tapping the hamburger opens a drawer that
# replaces the filter chip row entirely"). Filter mode is UI-local state
# (N4: "not saved, not in GameState") — it lives here, not on MapCanvas or
# GameState, and is pushed into MapCanvas via set_filter() whenever a list
# row is picked. Same treatment for the pacing toggle (map-animations
# ticket 06) via set_pacing(). Whether the drawer itself is open is the same
# kind of UI-local ephemera — not worth plumbing through GameState/Nav
# system functions the way real game state changes are (R§2's one-way flow
# is about the pure, saved/rewindable state tree; this is scroll-position-
# grade UI chrome, same class of thing filter_mode/pacing_mode already are).
#
# Caller sets `map_canvas` before adding this to the tree, then calls
# open()/close()/toggle() from wherever the hamburger button lives
# (scenes/screens/map.gd). This Control is a full-rect overlay (like
# map.gd's own site/vein sheet, or BagDrawer/ModalLayer) added as a sibling
# of the diagram, not a row inside its VBoxContainer — the whole point of
# ticket 03 is MapCanvas reclaims the vertical space the old inline chip row
# used, so this can't sit in that flow the way the old row did.

const FILTER_LABELS := {
	"ownership": "Ownership",
	"type": "Type",
	"strength": "Strength",
	"charge": "Charge",
	"security": "Security",
}

const PACING_LABELS := {
	"deliberate": "Pace: Deliberate",
	"quick": "Pace: Quick",
}

const DRAWER_WIDTH := 260.0

var map_canvas: MapCanvas

var _filter_mode: String = "ownership"
var _pacing_mode: String = "deliberate"
var _is_open: bool = false

var _dim: ColorRect
var _panel: PanelContainer
var _list: VBoxContainer


func _ready() -> void:
	UI.anchor_full_rect(self)
	# Ignored while closed so taps fall through to MapCanvas underneath —
	# only the dim/panel children (added below) ever set MOUSE_FILTER_STOP,
	# and only once open() shows them. Same pattern map.gd's own
	# _sheet_layer uses for its site/vein sheet.
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_dim = ColorRect.new()
	_dim.color = Color(0, 0, 0, 0.5)
	UI.anchor_full_rect(_dim)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim.visible = false
	# Ticket 03: "dismissible (tap outside ... )" — without this, STOP just
	# swallows the tap silently, which reads as a dead/broken control rather
	# than a way to close the drawer.
	_dim.gui_input.connect(_on_dim_gui_input)
	add_child(_dim)

	_panel = PanelContainer.new()
	_panel.anchor_left = 0
	_panel.anchor_top = 0
	_panel.anchor_right = 0
	_panel.anchor_bottom = 1
	_panel.offset_left = 0
	_panel.offset_top = 0
	_panel.offset_right = DRAWER_WIDTH
	_panel.offset_bottom = 0
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.visible = false
	add_child(_panel)

	var scroll := UI.scroll_container()
	_panel.add_child(scroll)

	_list = UI.vbox(8)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)

	_rebuild()


func open() -> void:
	_set_open(true)


func close() -> void:
	_set_open(false)


func toggle() -> void:
	_set_open(not _is_open)


func _set_open(value: bool) -> void:
	_is_open = value
	_dim.visible = value
	_panel.visible = value


func _on_dim_gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed:
		close()


func _rebuild() -> void:
	for child in _list.get_children():
		child.queue_free()

	_list.add_child(UI.heading("Filters", 14))
	for mode in MapStyle.FILTER_MODES:
		var b := UI.button(FILTER_LABELS[mode], func(): _select_filter(mode))
		b.disabled = mode == _filter_mode
		_list.add_child(b)

	_list.add_child(UI.heading("Other", 14))
	_list.add_child(UI.button(PACING_LABELS[_pacing_mode], _toggle_pacing))
	_list.add_child(UI.button("? Legend", func(): _open_legend()))
	_list.add_child(UI.button("Close", close))


func _select_filter(mode: String) -> void:
	_filter_mode = mode
	if map_canvas != null:
		map_canvas.set_filter(mode)
	_rebuild()
	close()


func _toggle_pacing() -> void:
	var idx := MapCanvas.PACING_MODES.find(_pacing_mode)
	_pacing_mode = MapCanvas.PACING_MODES[(idx + 1) % MapCanvas.PACING_MODES.size()]
	if map_canvas != null:
		map_canvas.set_pacing(_pacing_mode)
	_rebuild()
	close()


func _open_legend() -> void:
	Modal.open("network_reference")
	close()

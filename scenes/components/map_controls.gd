class_name MapControls
extends Control

# M1.5 N4/N5: the filter chip row (Ownership · Type · Strength · Charge ·
# Security) + the legend ("?") button that sits above the MapCanvas
# diagram. Filter mode is UI-local state (N4: "not saved, not in
# GameState") — it lives here, not on MapCanvas or GameState, and is
# pushed into MapCanvas via set_filter() whenever a chip is pressed.
#
# Caller sets `map_canvas` before adding this to the tree. Ticket 15 is
# what actually drops this + MapCanvas into the Map tab; until then this
# Control isn't reachable from any screen (same situation ticket 12 left
# MapCanvas in).

const FILTER_LABELS := {
	"ownership": "Ownership",
	"type": "Type",
	"strength": "Strength",
	"charge": "Charge",
	"security": "Security",
}

var map_canvas: MapCanvas

var _filter_mode: String = "ownership"
var _chip_row: HBoxContainer


func _ready() -> void:
	UI.anchor_top_wide(self)
	_chip_row = UI.hbox(6)
	add_child(_chip_row)
	_rebuild()


func _rebuild() -> void:
	for child in _chip_row.get_children():
		child.queue_free()

	for mode in MapStyle.FILTER_MODES:
		var b := UI.button(FILTER_LABELS[mode], func(): _select_filter(mode))
		b.disabled = mode == _filter_mode
		_chip_row.add_child(b)

	_chip_row.add_child(UI.button("?", func(): Modal.open("network_reference")))


func _select_filter(mode: String) -> void:
	_filter_mode = mode
	if map_canvas != null:
		map_canvas.set_filter(mode)
	_rebuild()

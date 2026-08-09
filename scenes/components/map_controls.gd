class_name MapControls
extends Control

# M1.5 N4/N5: the filter chip row (Ownership · Type · Strength · Charge ·
# Security) + the legend ("?") button that sits above the MapCanvas
# diagram. Filter mode is UI-local state (N4: "not saved, not in
# GameState") — it lives here, not on MapCanvas or GameState, and is
# pushed into MapCanvas via set_filter() whenever a chip is pressed.
#
# Map-animations ticket 06: the pacing toggle (deliberate/quick map-event
# playback) is the other player-facing toggle this row hosts, same "UI-local,
# not in GameState" treatment as filter_mode, pushed into MapCanvas via
# set_pacing() whenever the chip is tapped.
#
# Caller sets `map_canvas` before adding this to the tree. Ticket 15 is
# what actually drops this + MapCanvas into the Map tab; until then this
# Control isn't reachable from any screen (same situation ticket 12 left
# MapCanvas in).
#
# _get_minimum_size() below matters because map.gd adds this Control as a
# direct child of a VBoxContainer: a plain Control (this one) never
# auto-reports its children's size to a Container parent the way another
# Container would, so without the override the VBoxContainer sizes this row
# at (width, 0) and the next sibling row lands directly on top of the chips
# (found via on-device playtest, not headless — nothing here fails a
# check-only pass or a test). It only reports HEIGHT, not _chip_row's full
# combined width: 5 filter chips + the "?" button don't fit a phone's width,
# and reporting that combined width would force this whole column to
# overflow the screen horizontally (also found via on-device playtest — the
# fix for that overflow is _scroll below, not a wider report here). Instead
# this Control takes whatever width its VBoxContainer parent offers
# (default SIZE_FILL), and _scroll — a horizontal-only TouchScrollContainer
# filling this Control's rect — lets the wider chip row scroll sideways
# within it. anchor_full_rect(_scroll) is what lets it actually fill
# whatever rect the VBoxContainer ends up giving this Control based on that
# reported height — anchors are only ignored for a Container's direct
# children, and _scroll's parent is this plain Control, not a Container.

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

var map_canvas: MapCanvas

var _filter_mode: String = "ownership"
var _pacing_mode: String = "deliberate"
var _chip_row: HBoxContainer
var _scroll: TouchScrollContainer


func _ready() -> void:
	UI.anchor_top_wide(self)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL

	_scroll = TouchScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	UI.anchor_full_rect(_scroll)
	add_child(_scroll)

	_chip_row = UI.hbox(6)
	_scroll.add_child(_chip_row)
	_rebuild()


func _get_minimum_size() -> Vector2:
	if _chip_row == null:
		return Vector2.ZERO
	return Vector2(0, _chip_row.get_combined_minimum_size().y)


func _rebuild() -> void:
	for child in _chip_row.get_children():
		child.queue_free()

	for mode in MapStyle.FILTER_MODES:
		var b := UI.button(FILTER_LABELS[mode], func(): _select_filter(mode))
		b.disabled = mode == _filter_mode
		_chip_row.add_child(b)

	_chip_row.add_child(UI.button(PACING_LABELS[_pacing_mode], _toggle_pacing))
	_chip_row.add_child(UI.button("?", func(): Modal.open("network_reference")))
	update_minimum_size()


func _select_filter(mode: String) -> void:
	_filter_mode = mode
	if map_canvas != null:
		map_canvas.set_filter(mode)
	_rebuild()


func _toggle_pacing() -> void:
	var idx := MapCanvas.PACING_MODES.find(_pacing_mode)
	_pacing_mode = MapCanvas.PACING_MODES[(idx + 1) % MapCanvas.PACING_MODES.size()]
	if map_canvas != null:
		map_canvas.set_pacing(_pacing_mode)
	_rebuild()

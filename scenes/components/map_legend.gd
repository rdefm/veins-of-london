class_name MapLegend
extends Control

# Bugfixes ticket 26: a persistent (non-modal) faction-colour key, tube-map
# line-key style, sat in the top-left corner of the Network diagram. Distinct
# from map_controls.gd's "? Legend" button (Modal.open("network_reference")),
# which explains glyph/dot/ring semantics, not which colour belongs to which
# faction -- this is the name/colour pairing itself, sourced straight from
# GameData.FACTIONS["colour"] like map_canvas.gd's own line colours and
# map_controls.gd's faction-filter picker already do.
#
# Built once by map.gd's _build_diagram_layer() (like _map_canvas) and never
# torn down/rebuilt -- faction colours are static data, nothing here reacts
# to EventBus.state_changed. Added as a sibling of the diagram's scroll view
# inside its own wrapper Control (not a row in the content VBoxContainer),
# positioned at a small fixed offset from that wrapper's top-left corner --
# which already sits just below map.gd's own top bar row, so this never has
# to duplicate that row's height to avoid overlapping the hamburger/title/bag.
#
# Same "PanelContainer not managed by a parent Container, so size it and
# position it by hand" shape map_bubble.gd's own _panel/_reposition() use --
# _panel.size = _panel.get_combined_minimum_size() is what makes it shrink-
# wrap to its rows instead of collapsing to 0x0 or expanding to fill its
# parent.

const SWATCH_SIZE := 12.0
const PANEL_OFFSET := Vector2(8.0, 8.0)

var _panel: PanelContainer
var _rows: VBoxContainer
var _expanded: bool = true


func _ready() -> void:
	# Ignored so a tap anywhere in this Control's own (empty, (0,0)-sized --
	# see class comment) rect falls through to the diagram underneath; only
	# _panel below ever claims input, same split map_controls.gd's drawer and
	# map_bubble.gd use between their own full-rect self and their real panel.
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_panel = PanelContainer.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_panel)

	# UI.collapsible_section(), not a bespoke header -- same expand/collapse
	# chevron (▾/▸) HQ's Rooms/Security sections already use (bugfixes ticket
	# 24), satisfying this ticket's "collapsible ... if it would otherwise
	# crowd small screens" without inventing a second toggle convention.
	var section := UI.collapsible_section("Factions", _expanded, _on_toggle)
	_panel.add_child(section["panel"])
	_rows = section["content"]

	_build_rows()
	_reposition()


func _build_rows() -> void:
	for faction_id in GameData.FACTIONS.keys():
		_rows.add_child(_build_row(GameData.FACTIONS[faction_id]))


# shortName (not name) -- same compact label the faction-filter sub-picker
# (map_controls.gd::_build_faction_rows()) already uses, matching this
# widget's tube-map-line-key brief of compact swatches + labels.
func _build_row(faction: Dictionary) -> Control:
	var row := UI.hbox(6)

	var swatch := ColorRect.new()
	swatch.color = Color(faction["colour"])
	swatch.custom_minimum_size = Vector2(SWATCH_SIZE, SWATCH_SIZE)
	row.add_child(swatch)

	# A bare Label, not UI.label() -- UI.label() turns on word-autowrap,
	# whose minimum-width contribution collapses to near-zero (documented
	# repeatedly elsewhere in ui.gd), which would break _panel's shrink-wrap
	# sizing below. These are short, single-line faction names; no wrap needed.
	var name_label := Label.new()
	name_label.text = String(faction["shortName"])
	row.add_child(name_label)

	return row


func _on_toggle(expanded: bool) -> void:
	_expanded = expanded
	_reposition()


func _reposition() -> void:
	_panel.size = _panel.get_combined_minimum_size()
	_panel.position = PANEL_OFFSET

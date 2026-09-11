class_name TopBar
extends Control

# Persistent top bar (D4): cash, day/time-blocks, and the global bag button.
# field-kit-chrome ticket 02 (ui-vision.md §5) merges this with
# notification_toast.gd into one electronic dot-matrix departure/platform
# board -- amber-on-black, rendered via DotMatrixBoard/dot_matrix_font.gd.
# They stay two separate scripts/classes (so notifications can hide
# independently of the status line on some future screen) but share that one
# rendering component, and notification_toast.gd mounts its own board
# directly beneath this one so the two read as a single continuous board.
#
# Main.gd now shows this on every in-game screen except title/intro (it was
# previously also hidden on "map" and the HQ full-bleed sub-views -- see
# Main.gd's TOP_BAR_HIDDEN_SCREENS comment) so raid/notification alerts are
# never missed and the bag button keeps working everywhere, mid-event and
# mid-combat included (D4.4).

const BAR_HEIGHT := 40.0
const STATUS_DOT_SIZE := 3.0
const _SIDE_MARGIN := 4.0

var _board: DotMatrixBoard
var _bag_button: Button


func _ready() -> void:
	UI.anchor_top_wide(self)
	# Bugfixes ticket 21: flush against offset_top = 0 sits directly under
	# the OS notch/front-camera cutout on some devices, hiding money/time/
	# bag behind it. Shift the whole bar down by the safe-area top inset
	# (zero on desktop/headless) while keeping its own height fixed at
	# BAR_HEIGHT — UI.top_bar_clearance() is what every screen that clears
	# "below the TopBar" now uses instead of the bare constant, so nothing
	# ends up hidden under the bar's new, lower position.
	offset_top = UI.safe_area_top_inset()
	offset_bottom = UI.top_bar_clearance()

	# The board fills the whole strip (including behind the bag button) so
	# the entire row reads as one black board rather than a black board with
	# a hole cut out of it — the button is a real interactive Control drawn
	# on top, not part of the dot-matrix text itself.
	_board = DotMatrixBoard.new()
	UI.anchor_full_rect(_board)
	# Bugfixes ticket 01: keep the bag button's own footprint (icon +
	# margin on both sides) clear of status-line glyphs -- otherwise a long
	# status string draws characters directly under/beside the button,
	# camouflaging it (both are amber-on-black) and running the trailing
	# £<cash> off the screen edge past it.
	_board.reserved_right = UI.ICON_BUTTON_SIZE + _SIDE_MARGIN * 2.0
	add_child(_board)

	_bag_button = UI.icon_button(Icons.draw_bag, func(): Bag.open())
	_bag_button.flat = true
	# The icon glyph reads its colour via get_theme_color("font_color",
	# "Button") (scenes/components/ui.gd's _IconGlyph) -- override it to the
	# board's own amber so the icon is visible against the now-black strip
	# instead of the theme's default dark font colour.
	_bag_button.add_theme_color_override("font_color", DotMatrixBoard.LIT_COLOR)
	_bag_button.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	_bag_button.offset_left = -UI.ICON_BUTTON_SIZE - _SIDE_MARGIN
	_bag_button.offset_right = -_SIDE_MARGIN
	_bag_button.offset_top = -UI.ICON_BUTTON_SIZE / 2.0
	_bag_button.offset_bottom = UI.ICON_BUTTON_SIZE / 2.0
	add_child(_bag_button)

	EventBus.state_changed.connect(_refresh)
	_refresh()


# Split out so tests can check the composed status line without reaching
# into DotMatrixBoard's internal per-cell character state.
#
# Bugfixes ticket 01: the previous "Day %d · %s (%d/%d)   £%d" format (full
# time-block name, both separators, the block-progress fraction) runs to
# ~500px at STATUS_DOT_SIZE -- wider than this board has room for even
# before reserved_right's bag-button gap, on this project's 390px viewport.
# Abbreviating the time-block name to its first 3 letters (MOR/AFT/EVE --
# still unambiguous, and the block name itself already conveys roughly
# where in the day the player is, making the dropped "(x/3)" progress
# fraction redundant for a HUD-width readout) is what buys the width back
# with headroom to spare for day/cash figures growing into 3-4 digits;
# reserved_right (top_bar.gd's _ready()) remains a defensive clip for
# truly pathological figures beyond that, not the primary fix.
# PROSE-REVIEW: new compact status-line format, drafted against
# docs/CONTENT-GUIDE.md's tone bible.
func _status_line_text() -> String:
	var world: Dictionary = GameState.state["world"]
	var player: Dictionary = GameState.state["player"]
	var block_name: String = String(GameData.TIME_BLOCKS[world["timeBlock"]])

	return "D%d %s £%d" % [
		world["day"], block_name.substr(0, 3).to_upper(),
		player["cash"],
	]


func _refresh() -> void:
	_board.set_lines([DotMatrixBoard.line(_status_line_text(), STATUS_DOT_SIZE)])

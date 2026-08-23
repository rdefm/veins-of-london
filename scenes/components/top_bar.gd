class_name TopBar
extends Control

# Persistent top bar (D4): cash, day/time-blocks, and the global bag button.
# Main.gd shows this on every screen except title/intro — unlike NavBar,
# which also hides during event/combat, this one stays up there too, so the
# bag button keeps working mid-event and mid-combat per D4.4.
#
# Restyled (phone-os-shell ticket 03) to read as subdued system chrome
# rather than a floating game HUD: thinner (was 56px), a flat edge-to-edge
# strip with a hairline bottom border instead of no background at all,
# smaller muted-grey text, and a flat icon-only bag button — same
# UI.icon_button(Icons.draw_bag, ...) helper map.gd's local top bar uses
# (bugfixes ticket 13), plus flat=true here for the subdued look — instead
# of an orange "🎒 Bag" text pill. Same data, same visibility rules, same
# actions — visual pass only, per the ticket's explicit no-behavior-change
# scope.

const BAR_HEIGHT := 40.0

# _BORDER_COLOR matches theme/main_theme.tres's StyleBoxFlat_panel border;
# _TEXT_COLOR matches UI.muted_label()'s font_color override. Restated here
# rather than shared because neither is exposed as a named constant on UI
# or the theme resource today.
const _BG_COLOR := Color(0.909804, 0.894118, 0.85098, 1)
const _BORDER_COLOR := Color(0.831373, 0.811765, 0.768627, 1)
const _TEXT_COLOR := Color(0.541176, 0.541176, 0.541176, 1)
const _FONT_SIZE := 13

var _day_label: Label
var _cash_label: Label


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

	var bg := Panel.new()
	UI.anchor_full_rect(bg)
	var style := StyleBoxFlat.new()
	style.bg_color = _BG_COLOR
	style.border_width_bottom = 1
	style.border_color = _BORDER_COLOR
	bg.add_theme_stylebox_override("panel", style)
	add_child(bg)

	var margin := MarginContainer.new()
	UI.anchor_full_rect(margin)
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	add_child(margin)

	var row := UI.hbox(8)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(row)

	# UI.label() defaults to word-wrap (AUTOWRAP_WORD_SMART), which is right
	# for body copy but wrong here: a Label's *minimum* width under autowrap
	# is just its longest unbreakable fragment, not its full text — so
	# inside an HBoxContainer (which gives non-EXPAND children exactly
	# their minimum size) these two collapsed to a couple of characters
	# wide and wrapped the rest of "Day 1 · Morning (0/3)" one letter per
	# line down the screen (seen in human QA on-device). These are compact
	# single-line status text, not paragraphs — turn wrapping off instead
	# of fighting the container over minimum size.
	#
	# UI.label() (bugfixes ticket 65) now reserves its own natural
	# single-line width by default so most callers don't need this override
	# any more, but that reservation is computed once, from the text passed
	# to UI.label() at construction time -- these two are built with "" and
	# have their real text assigned in _refresh() below on every state
	# change, so the reservation would still be sized for the empty string.
	# This explicit override stays for that reason.
	_day_label = UI.label("")
	_day_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_style_status_text(_day_label)
	row.add_child(_day_label)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)

	_cash_label = UI.label("")
	_cash_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_style_status_text(_cash_label)
	row.add_child(_cash_label)

	var bag_button := UI.icon_button(Icons.draw_bag, func(): Bag.open())
	bag_button.flat = true
	row.add_child(bag_button)

	EventBus.state_changed.connect(_refresh)
	_refresh()


# Shrinks each status label to its own text-driven minimum height (rather
# than the default FILL, which would stretch it to the row's full height
# and draw the text pinned at the top) so it sits vertically centred
# against the bag button, which fills the row at its own fixed 40px size.
func _style_status_text(l: Label) -> void:
	l.add_theme_font_size_override("font_size", _FONT_SIZE)
	l.add_theme_color_override("font_color", _TEXT_COLOR)
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER


func _refresh() -> void:
	var world: Dictionary = GameState.state["world"]
	var player: Dictionary = GameState.state["player"]

	_day_label.text = "Day %d · %s (%d/%d)" % [
		world["day"], GameData.TIME_BLOCKS[world["timeBlock"]],
		world["timeBlocksDone"].size(), TimeSystem.BLOCKS_PER_DAY,
	]
	_cash_label.text = "£%d" % player["cash"]

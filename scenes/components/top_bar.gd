class_name TopBar
extends Control

# Persistent top bar (D4): cash, day/time-blocks, and the global bag button.
# Main.gd shows this on every screen except title/intro — unlike NavBar,
# which also hides during event/combat, this one stays up there too, so the
# bag button keeps working mid-event and mid-combat per D4.4.

const BAR_HEIGHT := 56.0

var _day_label: Label
var _cash_label: Label


func _ready() -> void:
	UI.anchor_top_wide(self)
	offset_bottom = BAR_HEIGHT

	var margin := MarginContainer.new()
	UI.anchor_full_rect(margin)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	add_child(margin)

	var row := UI.hbox(12)
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
	_day_label = UI.label("")
	_day_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	row.add_child(_day_label)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)

	_cash_label = UI.label("")
	_cash_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	row.add_child(_cash_label)

	row.add_child(UI.button("🎒 Bag", func(): Bag.open()))

	EventBus.state_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	var world: Dictionary = GameState.state["world"]
	var player: Dictionary = GameState.state["player"]

	_day_label.text = "Day %d · %s (%d/%d)" % [
		world["day"], GameData.TIME_BLOCKS[world["timeBlock"]],
		world["timeBlocksDone"].size(), TimeSystem.BLOCKS_PER_DAY,
	]
	_cash_label.text = "£%d" % player["cash"]

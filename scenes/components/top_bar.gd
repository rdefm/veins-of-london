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
	margin.add_child(row)

	_day_label = UI.label("")
	row.add_child(_day_label)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)

	_cash_label = UI.label("")
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

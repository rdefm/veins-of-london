class_name CombatCommandDock
extends Panel

# The lower command region: one continuous near-white surface (this Panel)
# spanning the full screen width, holding an inner row (_row) with the Dial
# + flat command rows (Complication readout, Attack, Item, Leg it),
# docs/combat-animation-vision.md §2.5. A fixed Control anchored to the true
# bottom of the screen, outside scenes/screens/combat.gd's stage/detail-band
# flow entirely, so sharing that space with the upper region never caps the
# Dial's own size. combat.gd owns turn flow/director bridging: Attack and
# Leg-it forward through the callables passed to configure(), since both
# need to play a beat queue, which is the screen's job, not this dock's.
#
# Same off-tree-testable shape as DialWidget/TurnOrderStrip: no _ready()
# override, anchors/theme set in _init() (always runs on .new(), unlike
# _ready() which never fires in the CombatScreen.new()+_ready() harness
# tests/test_combat_screen.gd's own top comment documents).

const COMMAND_DOCK_LEFT_MARGIN := 0.0
const COMMAND_DOCK_RIGHT_MARGIN := 4.0
const COMMAND_DOCK_BOTTOM_MARGIN := 6.0
const COMMAND_DOCK_HEIGHT := DialWidget.WIDGET_SIZE.y
# Breathing room above the Dial/action row within the near-white surface,
# so it reads as a region of the screen, not a shrink-wrapped card.
const COMMAND_DOCK_SURFACE_TOP_PADDING := 12.0
const COMMAND_DOCK_SURFACE_HEIGHT := COMMAND_DOCK_HEIGHT + COMMAND_DOCK_BOTTOM_MARGIN + COMMAND_DOCK_SURFACE_TOP_PADDING

var _row: HBoxContainer
var _dial_selected_index: int = 0
var _player: Dictionary = {}
var _on_attack_callback: Callable = Callable()
var _on_run_callback: Callable = Callable()
var _on_dial_triggered_callback: Callable = Callable()


func _init() -> void:
	anchor_left = 0.0
	anchor_right = 1.0
	anchor_top = 1.0
	anchor_bottom = 1.0
	offset_left = 0.0
	offset_right = 0.0
	offset_bottom = 0.0
	offset_top = -COMMAND_DOCK_SURFACE_HEIGHT
	mouse_filter = Control.MOUSE_FILTER_PASS

	var surface_style := StyleBoxFlat.new()
	surface_style.bg_color = UI.ACTION_CARD_FILL
	add_theme_stylebox_override("panel", surface_style)

	_row = HBoxContainer.new()
	_row.anchor_left = 0.0
	_row.anchor_right = 1.0
	_row.anchor_top = 1.0
	_row.anchor_bottom = 1.0
	_row.offset_left = COMMAND_DOCK_LEFT_MARGIN
	_row.offset_right = -COMMAND_DOCK_RIGHT_MARGIN
	_row.offset_bottom = -COMMAND_DOCK_BOTTOM_MARGIN
	_row.offset_top = -(COMMAND_DOCK_BOTTOM_MARGIN + COMMAND_DOCK_HEIGHT)
	_row.add_theme_constant_override("separation", 8)
	add_child(_row)


func configure(player: Dictionary, on_attack: Callable, on_run: Callable, on_dial_triggered: Callable) -> void:
	_on_attack_callback = on_attack
	_on_run_callback = on_run
	_on_dial_triggered_callback = on_dial_triggered
	_rebuild(player)


func hide_deck() -> void:
	for child in _row.get_children():
		child.queue_free()


func _rebuild(player: Dictionary) -> void:
	_player = player
	for child in _row.get_children():
		child.queue_free()

	var dial: Variant = player["dial"]
	if dial != null:
		_row.add_child(_build_dial_widget(dial))
	_row.add_child(_build_action_deck(player))


func _build_dial_widget(dial: Dictionary) -> Control:
	var widget := DialWidget.new()
	widget.configure(dial, _dial_selected_index, _on_dial_selection_changed, _on_dial_triggered)
	return widget
func _on_dial_selection_changed(new_index: int) -> void:
	_dial_selected_index = new_index
	_rebuild(_player)
func _on_dial_triggered(result: Dictionary) -> void:
	if _on_dial_triggered_callback.is_valid():
		_on_dial_triggered_callback.call(result)


func _on_attack_pressed() -> void:
	if _on_attack_callback.is_valid():
		_on_attack_callback.call()
func _on_run_pressed() -> void:
	if _on_run_callback.is_valid():
		_on_run_callback.call()


func _build_complication_detail(dial: Variant) -> Control:
	var glyph := SymbolGlyph.new()
	glyph.font_size = 20
	glyph.glyph_radius = 12.0
	glyph.draw_fallback = SymbolGlyph.generic_fallback()
	var accent := UI.action_colour()
	glyph.color = accent

	var text := "No Dial"
	if dial != null:
		var loaded: Array = dial["loadedComplications"]
		text = "Empty"
		if not loaded.is_empty():
			var index: int = clampi(_dial_selected_index, 0, loaded.size() - 1)
			var entry: Dictionary = loaded[index]
			var recipe: Dictionary = GameData.RECIPES[entry["recipeKey"]]
			glyph.symbol = recipe["symbol"]
			text = "%s — tier %d" % [recipe["name"], entry["tier"]]

	# Read-only readout of the Dial's selection (casting is the Dial's own
	# trigger), so a plain row rather than a Button -- same height/inset.
	var row := PanelContainer.new()
	row.name = "ComplicationRow"
	row.custom_minimum_size.y = UI.COMMAND_ROW_HEIGHT
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_stylebox_override("panel", UI.command_row_style(accent, 0.0))
	row.add_child(_build_row_content(glyph, text, accent))
	return row
# Flat command rows (docs/combat-animation-vision.md §2.5, combat-refining
# amendment): Complication readout, Attack, Item, Leg it -- equal height,
# 1px rules between, no per-row panel or primary-action emphasis.
func _build_action_deck(player: Dictionary) -> Control:
	var col := UI.vbox(0)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical = Control.SIZE_SHRINK_END
	var rows: Array[Control] = [
		_build_complication_detail(player["dial"]),
		_build_action_row("attack", "Attack", _on_attack_pressed, not Combat.selection_block_reason("attack").is_empty()),
		_build_action_row("item", "Item", func(): Bag.open(), not Combat.has_usable_item(player)),
		_build_action_row("run", "Leg it", _on_run_pressed),
	]
	for i in rows.size():
		if i > 0:
			col.add_child(UI.command_row_rule())
		col.add_child(rows[i])
	return col
static func _action_icon_draw_fn(icon_kind: String) -> Callable:
	match icon_kind:
		"attack":
			return Icons.draw_attack
		"item":
			return Icons.draw_bag
		"run":
			return Icons.draw_run
		_:
			return Callable()

# The whole row is the Button (full-width hit area); icon + caption sit
# inside it with mouse ignored so taps land on the Button itself.
func _build_action_row(icon_kind: String, label_text: String, callback: Callable, disabled: bool = false) -> Control:
	var accent: Color = UI.ACTION_DISABLED_COLOUR if disabled else UI.action_colour()

	var button := Button.new()
	button.name = "ActionButton_%s" % icon_kind
	button.disabled = disabled
	button.focus_mode = Control.FOCUS_ALL
	button.custom_minimum_size.y = UI.COMMAND_ROW_HEIGHT
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UI.style_command_row(button, accent)
	button.pressed.connect(callback)

	var icon := UI.icon_glyph_control(_action_icon_draw_fn(icon_kind), UI.ICON_GLYPH_SCALE, accent)
	var content := _build_row_content(icon, label_text, accent)
	content.offset_left = UI.COMMAND_ROW_MARGIN_H
	content.offset_right = -UI.COMMAND_ROW_MARGIN_H
	button.add_child(content)
	return button
func _build_row_content(icon: Control, label_text: String, accent: Color) -> HBoxContainer:
	var row := UI.hbox(10)
	UI.anchor_full_rect(row)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE

	icon.custom_minimum_size = Vector2(UI.COMMAND_ROW_ICON_SIZE, UI.COMMAND_ROW_ICON_SIZE)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)

	var caption := UI.label(label_text)
	caption.custom_minimum_size.x = 0.0
	caption.autowrap_mode = TextServer.AUTOWRAP_OFF
	caption.clip_text = true
	caption.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caption.size_flags_vertical = Control.SIZE_FILL
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size", UI.COMMAND_ROW_FONT_SIZE)
	caption.add_theme_color_override("font_color", accent)
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(caption)
	return row

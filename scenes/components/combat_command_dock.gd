class_name CombatCommandDock
extends Panel

# The lower command region: one continuous near-white surface (this Panel)
# spanning the full screen width, anchored to the true bottom of the screen
# outside the stage's flow. By default it shows a 2×2 grid of big buttons
# (Fight, Item, Dial, Leg it); Fight and Item slide the grid off left onto
# their 1px-ruled rows (the moves, the loadout slots), Dial slides it off
# right as the Dial page (the Dial beside its Complication readout) rises
# from the bottom, and each page's Back brings the grid back. The caller
# (scenes/screens/combat_rounds.gd) builds every row and owns what each
# does; configure() lays them out. Which page shows is view state only.
#
# Same off-tree-testable shape as DialWidget/TurnOrderStrip: no _ready()
# override, anchors/theme set in _init() (always runs on .new(), unlike
# _ready() which never fires in an off-tree .new()+_ready() harness).

const COMMAND_DOCK_LEFT_MARGIN := 0.0
const COMMAND_DOCK_RIGHT_MARGIN := 4.0
const COMMAND_DOCK_BOTTOM_MARGIN := 6.0
const COMMAND_DOCK_HEIGHT := DialWidget.WIDGET_SIZE.y
# Breathing room above the pages within the near-white surface, so it reads
# as a region of the screen, not a shrink-wrapped card.
const COMMAND_DOCK_SURFACE_TOP_PADDING := 12.0
const COMMAND_DOCK_SURFACE_HEIGHT := COMMAND_DOCK_HEIGHT + COMMAND_DOCK_BOTTOM_MARGIN + COMMAND_DOCK_SURFACE_TOP_PADDING
# Diameter of a row's "?" / "!" (see _build_round_button()).
const EXPLAIN_BUTTON_SIZE := 28.0
const BLOCK_COLOUR := Color("#d8453b")
const TOOLTIP_WIDTH := 260.0
const GRID_FONT_SIZE := 24
const GRID_ICON_SIZE := 48.0
const PAGE_SLIDE_SECONDS := 0.22
# PROSE-REVIEW: the Dial grid button's reason when the player carries none.
const REASON_NO_DIAL := "No Dial."

const VIEW_GRID := "grid"
const VIEW_FIGHT := "fight"
const VIEW_ITEM := "item"
const VIEW_DIAL := "dial"

var _pages_root: Control
var _pages: Dictionary = {}
var _view: String = VIEW_GRID
var _tween: Tween = null
var _dial_selected_index: int = 0
# The Dial cast (DialWidget's on_cast).
var _on_dial_cast_callback: Callable = Callable()
var _dial: Variant = null
var _moves: Array = []
var _items: Array = []
var _leg_it: Dictionary = {}
# True while a round's beats play out: every command is dimmed and inert
# (moving between pages still works).
var _locked := false


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

	_pages_root = Control.new()
	UI.anchor_full_rect(_pages_root)
	_pages_root.offset_left = COMMAND_DOCK_LEFT_MARGIN
	_pages_root.offset_right = -COMMAND_DOCK_RIGHT_MARGIN
	_pages_root.offset_top = COMMAND_DOCK_SURFACE_TOP_PADDING
	_pages_root.offset_bottom = -COMMAND_DOCK_BOTTOM_MARGIN
	_pages_root.clip_contents = true
	_pages_root.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_pages_root)
	for view in [VIEW_GRID, VIEW_FIGHT, VIEW_ITEM, VIEW_DIAL]:
		var page := Control.new()
		page.name = "Page_%s" % view
		UI.anchor_full_rect(page)
		page.mouse_filter = Control.MOUSE_FILTER_PASS
		_pages_root.add_child(page)
		_pages[view] = page
	_place_pages()


# Each of `moves` and `items` is a row { name, iconKind, label, disabled,
# disabledReason, callback, onExplain } (iconKind as _build_row_icon() reads
# it; disabledReason becomes the row's tooltip; a row with a `tooltip` line
# gets a "?" popover; a disabled row with an onExplain callable also gets a
# red "!" calling it); `leg_it` is one such row, drawn
# as the grid's fourth button. The Dial page exists only when `dial` isn't
# null; `on_dial_cast` (index) casts in place of the widget's own.
func configure(moves: Array, items: Array, leg_it: Dictionary, dial: Variant = null, locked: bool = false, on_dial_cast: Callable = Callable()) -> void:
	_locked = locked
	_on_dial_cast_callback = on_dial_cast
	_moves = moves
	_items = items
	_leg_it = leg_it
	_dial = dial
	if _dial == null and _view == VIEW_DIAL:
		_view = VIEW_GRID
	_pages_root.visible = true
	_rebuild()
	if _tween == null:
		_place_pages()


# Surface height that fits `count` rows (and their 1px rules) on one page:
# never less than the Dial-sized default.
static func surface_height_for_rows(count: int) -> float:
	var rows_height: float = count * UI.COMMAND_ROW_HEIGHT + maxi(0, count - 1)
	return maxf(COMMAND_DOCK_SURFACE_HEIGHT, rows_height + COMMAND_DOCK_BOTTOM_MARGIN + COMMAND_DOCK_SURFACE_TOP_PADDING)


# Hides every page (the fight's over) and returns to the grid for next time.
func hide_deck() -> void:
	_kill_tween()
	_view = VIEW_GRID
	_pages_root.visible = false
	_place_pages()


func current_view() -> String:
	return _view


# Moves to page `view` (VIEW_*), sliding when on screen.
func show_view(view: String) -> void:
	if view == _view or (view == VIEW_DIAL and _dial == null):
		return
	var from := _view
	_view = view
	if not is_inside_tree():
		_place_pages()
		return
	_kill_tween()
	var sub := view if view != VIEW_GRID else from
	var grid: Control = _pages[VIEW_GRID]
	var page: Control = _pages[sub]
	grid.visible = true
	page.visible = true
	var grid_away := _away_position(VIEW_GRID, sub)
	var page_away := _away_position(sub, sub)
	var opening := view != VIEW_GRID
	grid.position = Vector2.ZERO if opening else grid_away
	page.position = page_away if opening else Vector2.ZERO
	_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(grid, "position", grid_away if opening else Vector2.ZERO, PAGE_SLIDE_SECONDS)
	_tween.tween_property(page, "position", Vector2.ZERO if opening else page_away, PAGE_SLIDE_SECONDS)
	_tween.chain().tween_callback(func():
		_tween = null
		_place_pages())


func _kill_tween() -> void:
	if _tween != null:
		_tween.kill()
		_tween = null


# Where page `view` waits off screen while `sub` is the page in play: the
# grid off left for Fight/Item and off right for the Dial; Fight/Item off
# right, the Dial below.
func _away_position(view: String, sub: String) -> Vector2:
	var area := _pages_root.size
	if view == VIEW_GRID:
		return Vector2(area.x if sub == VIEW_DIAL else -area.x, 0.0)
	if view == VIEW_DIAL:
		return Vector2(0.0, area.y)
	return Vector2(area.x, 0.0)


# Settles every page with no animation: the current one shown in place,
# the rest hidden where they wait.
func _place_pages() -> void:
	for view in _pages:
		var page: Control = _pages[view]
		page.visible = view == _view
		page.position = Vector2.ZERO if view == _view else _away_position(view, view if view != VIEW_GRID else _view)


func _rebuild() -> void:
	for page in _pages.values():
		for child in page.get_children():
			child.queue_free()
	_pages[VIEW_GRID].add_child(_build_grid())
	_pages[VIEW_FIGHT].add_child(_build_row_column(null, _moves))
	_pages[VIEW_ITEM].add_child(_build_row_column(null, _items))
	if _dial != null:
		var dial_row := UI.hbox(8)
		UI.anchor_full_rect(dial_row)
		dial_row.add_child(_build_dial_widget(_dial))
		dial_row.add_child(_build_row_column(_build_complication_detail(_dial), []))
		_pages[VIEW_DIAL].add_child(dial_row)


# Fight, Item, Dial, Leg it: the first three open their pages, Leg it acts.
func _build_grid() -> Control:
	var grid := GridContainer.new()
	grid.columns = 2
	UI.anchor_full_rect(grid)
	grid.add_theme_constant_override("h_separation", 0)
	grid.add_theme_constant_override("v_separation", 0)
	grid.add_child(_build_grid_button({ "name": "GridFight", "iconKind": "attack", "label": "Fight", "callback": show_view.bind(VIEW_FIGHT) }, false))
	grid.add_child(_build_grid_button({ "name": "GridItem", "iconKind": "", "label": "Item", "callback": show_view.bind(VIEW_ITEM) }, false))
	grid.add_child(_build_grid_button({
		"name": "GridDial", "iconKind": "", "label": "Dial", "callback": show_view.bind(VIEW_DIAL),
		"disabled": _dial == null, "disabledReason": REASON_NO_DIAL,
	}, false))
	grid.add_child(_build_grid_button(_leg_it, _locked))
	return grid


func _build_grid_button(row: Dictionary, locked: bool) -> Button:
	var disabled: bool = locked or row.get("disabled", false)
	var accent: Color = UI.ACTION_DISABLED_COLOUR if disabled else UI.action_colour()
	var button := Button.new()
	button.name = row.get("name", "GridButton")
	button.disabled = disabled
	button.tooltip_text = row.get("disabledReason", "") if disabled else ""
	button.focus_mode = Control.FOCUS_ALL
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	UI.style_command_row(button, accent)
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var style: StyleBoxFlat = button.get_theme_stylebox(state).duplicate()
		style.set_border_width_all(1)
		style.border_color = UI.COMMAND_ROW_RULE_COLOUR
		button.add_theme_stylebox_override(state, style)
	var callback: Callable = row.get("callback", Callable())
	if callback.is_valid():
		button.pressed.connect(callback)

	var content := UI.vbox(6)
	UI.anchor_full_rect(content)
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon_kind: String = row.get("iconKind", "")
	if icon_kind != "":
		var icon := _build_row_icon(icon_kind, accent)
		icon.custom_minimum_size = Vector2(GRID_ICON_SIZE, GRID_ICON_SIZE)
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(icon)
	var caption := UI.label(row.get("label", ""))
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size", GRID_FONT_SIZE)
	caption.add_theme_color_override("font_color", accent)
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(caption)
	var explain: Callable = row.get("onExplain", Callable())
	if row.get("disabled", false) and not locked and explain.is_valid():
		var help := _build_round_button("ExplainButton", "!", BLOCK_COLOUR)
		help.pressed.connect(explain)
		help.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		content.add_child(help)
	button.add_child(content)
	return button


func _build_dial_widget(dial: Dictionary) -> Control:
	var widget := DialWidget.new()
	widget.configure(dial, _dial_selected_index, _on_dial_selection_changed, _on_dial_cast_callback)
	if _locked:
		widget.mouse_filter = Control.MOUSE_FILTER_IGNORE
		widget.modulate = UI.ACTION_DISABLED_MODULATE
	return widget
func _on_dial_selection_changed(new_index: int) -> void:
	_dial_selected_index = new_index
	_rebuild()


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
			glyph.icon = ItemIcons.texture(entry["recipeKey"])
			text = "%s — tier %d" % [recipe["name"], entry["tier"]]
			var turn_bonus: int = Dial.cast_turn_bonus(entry["recipeKey"], int(dial["level"]))
			if turn_bonus > 0:
				text += " (+%d %s)" % [turn_bonus, "turn" if turn_bonus == 1 else "turns"]

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
# amendment): the header (Complication readout) if any, then each row, then
# Back -- equal height, 1px rules between, no per-row panel or emphasis.
func _build_row_column(header: Control, rows: Array) -> Control:
	var col := UI.vbox(0)
	UI.anchor_full_rect(col)
	col.alignment = BoxContainer.ALIGNMENT_END
	var controls: Array[Control] = []
	if header != null:
		controls.append(header)
	for i in rows.size():
		controls.append(_build_command_row(rows[i], "RowButton_%d" % i, _locked))
	controls.append(_build_command_row({ "name": "BackButton", "label": "Back", "callback": show_view.bind(VIEW_GRID) }, "BackButton", false))
	for i in controls.size():
		if i > 0:
			col.add_child(UI.command_row_rule())
		col.add_child(controls[i])
	return col
# iconKind: "attack"/"run" draw an Icons glyph; "recipe:<recipeKey>" draws
# that recipe's item glyph ("recipe:" alone is the empty-slot glyph).
func _build_row_icon(icon_kind: String, accent: Color) -> Control:
	if icon_kind.begins_with("recipe:"):
		var glyph := SymbolGlyph.new()
		glyph.font_size = 20
		glyph.glyph_radius = 12.0
		glyph.draw_fallback = SymbolGlyph.generic_fallback()
		glyph.color = accent
		var recipe_key: String = icon_kind.trim_prefix("recipe:")
		if GameData.RECIPES.has(recipe_key):
			glyph.symbol = GameData.RECIPES[recipe_key]["symbol"]
			glyph.icon = ItemIcons.texture(recipe_key)
		return glyph
	return UI.icon_glyph_control(_action_icon_draw_fn(icon_kind), UI.ICON_GLYPH_SCALE, accent)
static func _action_icon_draw_fn(icon_kind: String) -> Callable:
	match icon_kind:
		"attack":
			return Icons.draw_attack
		"run":
			return Icons.draw_run
		_:
			return Callable()

# The whole row is the Button (full-width hit area); icon + caption sit
# inside it with mouse ignored so taps land on the Button itself.
func _build_command_row(row: Dictionary, default_name: String, locked: bool) -> Control:
	var disabled: bool = locked or row.get("disabled", false)
	var accent: Color = UI.ACTION_DISABLED_COLOUR if disabled else UI.action_colour()

	var button := Button.new()
	button.name = row.get("name", default_name)
	button.disabled = disabled
	button.tooltip_text = row.get("disabledReason", "") if disabled else ""
	button.focus_mode = Control.FOCUS_ALL
	button.custom_minimum_size.y = UI.COMMAND_ROW_HEIGHT
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UI.style_command_row(button, accent)
	var callback: Callable = row.get("callback", Callable())
	if callback.is_valid():
		button.pressed.connect(callback)

	var content := _build_row_content(_build_row_icon(row.get("iconKind", ""), accent), row.get("label", ""), accent)
	content.offset_left = UI.COMMAND_ROW_MARGIN_H
	content.offset_right = -UI.COMMAND_ROW_MARGIN_H
	var tooltip: String = row.get("tooltip", "")
	if tooltip != "" and not locked:
		var tip_button := _build_round_button("TooltipButton", "?", accent)
		tip_button.pressed.connect(_show_tooltip.bind(tip_button, tooltip))
		content.add_child(tip_button)
	var explain: Callable = row.get("onExplain", Callable())
	if row.get("disabled", false) and not locked and explain.is_valid():
		var block_button := _build_round_button("ExplainButton", "!", BLOCK_COLOUR)
		block_button.pressed.connect(explain)
		content.add_child(block_button)
	button.add_child(content)
	return button


# A small round button; it takes its own taps, so it works though the row
# Button around it is disabled.
func _build_round_button(button_name: String, glyph: String, colour: Color) -> Button:
	var round_button := Button.new()
	round_button.name = button_name
	round_button.text = glyph
	round_button.focus_mode = Control.FOCUS_NONE
	round_button.mouse_filter = Control.MOUSE_FILTER_STOP
	round_button.custom_minimum_size = Vector2(EXPLAIN_BUTTON_SIZE, EXPLAIN_BUTTON_SIZE)
	round_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	round_button.add_theme_font_size_override("font_size", 14)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.set_border_width_all(1)
	style.border_color = colour
	style.set_corner_radius_all(int(EXPLAIN_BUTTON_SIZE / 2.0))
	for state in ["normal", "hover", "pressed", "focus"]:
		round_button.add_theme_stylebox_override(state, style)
	for font_colour in ["font_color", "font_hover_color", "font_pressed_color"]:
		round_button.add_theme_color_override(font_colour, colour)
	return round_button


# A "?" popover: one line under its button; a tap anywhere else dismisses it.
func _show_tooltip(anchor: Control, text: String) -> void:
	var popup := PopupPanel.new()
	popup.name = "TooltipPopup"
	var caption := UI.label(text)
	caption.custom_minimum_size.x = TOOLTIP_WIDTH
	popup.add_child(caption)
	popup.popup_hide.connect(popup.queue_free)
	add_child(popup)
	var below := anchor.get_screen_position() + Vector2(0.0, anchor.size.y + 4.0)
	popup.popup(Rect2i(Vector2i(below), Vector2i.ZERO))
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

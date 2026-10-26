class_name CombatCommandDock
extends Panel

# The lower command region: one continuous near-white surface (this Panel)
# spanning the full screen width, anchored to the true bottom of the screen
# outside the stage's flow. A compact menu down the right (Fight, Dial, Item,
# Leg it, each icon + text) picks which page fills the wider left: the moves,
# the Dial beside its Complication readout, or the loadout slots as 1px-ruled
# rows. Fight is open by default and the open entry shows selected; Leg it acts
# at once and opens nothing. The caller (scenes/screens/combat_rounds.gd)
# builds every row and owns what each does; configure() lays them out. Which
# page shows is view state only.
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
const PEEK_HOLD_SECONDS := 0.4
const LEVEL_BADGE_FONT_SIZE := 14
const MENU_FONT_SIZE := 18
const MENU_ICON_SIZE := 28.0
# The menu column's share of the dock width; the page area takes the rest.
const MENU_WIDTH_FRACTION := 0.33
const MENU_GAP := 6.0
const MENU_ENTRY_COUNT := 4
# PROSE-REVIEW: the Dial menu entry's reason when the player carries none.
const REASON_NO_DIAL := "No Dial."

const VIEW_FIGHT := "fight"
const VIEW_ITEM := "item"
const VIEW_DIAL := "dial"

var _pages_root: Control
var _panel_area: Control
var _menu: Control
var _pages: Dictionary = {}
var _view: String = VIEW_FIGHT
var _slide_tween: Tween
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
	_panel_area = Control.new()
	_panel_area.name = "PanelArea"
	UI.anchor_full_rect(_panel_area)
	_panel_area.anchor_right = 1.0 - MENU_WIDTH_FRACTION
	_panel_area.offset_right = -MENU_GAP
	_panel_area.mouse_filter = Control.MOUSE_FILTER_PASS
	_pages_root.add_child(_panel_area)
	_menu = Control.new()
	_menu.name = "Menu"
	UI.anchor_full_rect(_menu)
	_menu.anchor_left = 1.0 - MENU_WIDTH_FRACTION
	_menu.offset_left = 0.0
	_menu.mouse_filter = Control.MOUSE_FILTER_PASS
	_pages_root.add_child(_menu)
	for view in [VIEW_FIGHT, VIEW_ITEM, VIEW_DIAL]:
		var page := Control.new()
		page.name = "Page_%s" % view
		UI.anchor_full_rect(page)
		page.mouse_filter = Control.MOUSE_FILTER_PASS
		_panel_area.add_child(page)
		_pages[view] = page
	_place_pages()


# Each of `moves` and `items` is a row { name, iconKind, label, disabled,
# disabledReason, callback, onExplain } (iconKind as _build_row_icon() reads
# it; disabledReason becomes the row's tooltip; a `badge` string shows as a
# small level badge after the label; a row with a `tooltip` line
# gets a "?" popover; a disabled row with an onExplain callable also gets a
# red "!" calling it); `leg_it` is one such row, drawn as the menu's last
# entry. The Dial page exists only when `dial` isn't null; `on_dial_cast`
# (index) casts in place of the widget's own.
func configure(moves: Array, items: Array, leg_it: Dictionary, dial: Variant = null, locked: bool = false, on_dial_cast: Callable = Callable()) -> void:
	_locked = locked
	_on_dial_cast_callback = on_dial_cast
	_moves = moves
	_items = items
	_leg_it = leg_it
	_dial = dial
	if _dial == null and _view == VIEW_DIAL:
		_view = VIEW_FIGHT
	_pages_root.visible = true
	_rebuild()
	_place_pages()


# Surface height that fits `count` rows (and their 1px rules) on one page, and
# the four-entry menu: never less than the Dial-sized default.
static func surface_height_for_rows(count: int) -> float:
	var rows_height: float = maxi(count, MENU_ENTRY_COUNT) * UI.COMMAND_ROW_HEIGHT + maxi(0, maxi(count, MENU_ENTRY_COUNT) - 1)
	return maxf(COMMAND_DOCK_SURFACE_HEIGHT, rows_height + COMMAND_DOCK_BOTTOM_MARGIN + COMMAND_DOCK_SURFACE_TOP_PADDING)


# Hides every page (the fight's over) and returns to Fight for next time.
func hide_deck() -> void:
	_view = VIEW_FIGHT
	_pages_root.visible = false
	_place_pages()


func current_view() -> String:
	return _view


# Swaps the left panel to page `view` (VIEW_*) at once and moves the selected
# marker; the Dial page needs a Dial.
func show_view(view: String) -> void:
	if view == _view or (view == VIEW_DIAL and _dial == null):
		return
	var outgoing := _view
	_view = view
	_rebuild_menu()
	if not is_inside_tree():
		_place_pages()
		return
	_slide_pages(outgoing, view)


# Fight slides from/to the left, Item from/to the top, Dial from/to the bottom
# (pacing.menuPanel in data/combat_visuals.json sets the durations). A new
# switch first settles any slide in flight, so only the last-tapped page shows.
func _slide_pages(outgoing: String, incoming: String) -> void:
	if _slide_tween != null:
		_slide_tween.kill()
	_place_pages(outgoing)
	var timing: Dictionary = GameData.COMBAT_VISUALS.get("pacing", {}).get("menuPanel", {})
	var in_page: Control = _pages[incoming]
	var out_page: Control = _pages[outgoing]
	in_page.position = _offscreen_position(incoming)
	in_page.visible = true
	out_page.process_mode = Node.PROCESS_MODE_DISABLED
	_slide_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC)
	_slide_tween.tween_property(in_page, "position", Vector2.ZERO, float(timing.get("enterSeconds", 0.0))).set_ease(Tween.EASE_OUT)
	_slide_tween.tween_property(out_page, "position", _offscreen_position(outgoing), float(timing.get("exitSeconds", 0.0))).set_ease(Tween.EASE_IN)
	_slide_tween.chain().tween_callback(_place_pages)


func _offscreen_position(view: String) -> Vector2:
	var size_now := _panel_area.size
	match view:
		VIEW_FIGHT:
			return Vector2(-size_now.x, 0.0)
		VIEW_ITEM:
			return Vector2(0.0, -size_now.y)
	return Vector2(0.0, size_now.y)


# Shows `only` (default the current page), hides the rest at rest position and
# live to input; ends any slide.
func _place_pages(only: String = "") -> void:
	var shown := only if only != "" else _view
	for view in _pages:
		var page: Control = _pages[view]
		page.process_mode = Node.PROCESS_MODE_INHERIT
		page.position = Vector2.ZERO
		page.visible = view == shown
	_slide_tween = null


func _rebuild() -> void:
	for page in _pages.values():
		for child in page.get_children():
			child.queue_free()
	_pages[VIEW_FIGHT].add_child(_build_row_column(null, _moves))
	_pages[VIEW_ITEM].add_child(_build_row_column(null, _items))
	if _dial != null:
		var dial_row := UI.hbox(8)
		UI.anchor_full_rect(dial_row)
		dial_row.add_child(_build_dial_widget(_dial))
		dial_row.add_child(_build_row_column(_build_complication_detail(_dial), []))
		_pages[VIEW_DIAL].add_child(dial_row)
	_rebuild_menu()


func _rebuild_menu() -> void:
	for child in _menu.get_children():
		_menu.remove_child(child)
		child.queue_free()
	_menu.add_child(_build_menu())


# Fight, Dial, Item, Leg it: the first three open their pages, Leg it acts.
func _build_menu() -> Control:
	var col := UI.vbox(0)
	UI.anchor_full_rect(col)
	col.add_child(_build_menu_button({ "name": "MenuFight", "iconKind": "attack", "label": "Fight", "callback": show_view.bind(VIEW_FIGHT) }, false, _view == VIEW_FIGHT))
	col.add_child(_build_menu_button({
		"name": "MenuDial", "iconKind": "dial", "label": "Dial", "callback": show_view.bind(VIEW_DIAL),
		"disabled": _dial == null, "disabledReason": REASON_NO_DIAL,
	}, false, _view == VIEW_DIAL))
	col.add_child(_build_menu_button({ "name": "MenuItem", "iconKind": "bag", "label": "Item", "callback": show_view.bind(VIEW_ITEM) }, false, _view == VIEW_ITEM))
	col.add_child(_build_menu_button(_leg_it, _locked, false))
	return col


# `selected` draws the entry in the pressed fill so the open page reads.
func _build_menu_button(row: Dictionary, locked: bool, selected: bool) -> Button:
	var disabled: bool = locked or row.get("disabled", false)
	var accent: Color = UI.ACTION_DISABLED_COLOUR if disabled else UI.action_colour()
	var button := Button.new()
	button.name = row.get("name", "MenuButton")
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
		if selected:
			style.bg_color = Color(accent, UI.COMMAND_ROW_PRESSED_ALPHA)
		button.add_theme_stylebox_override(state, style)
	button.set_meta("selected", selected)
	_connect_press(button, row)

	var content := _build_row_content(_build_row_icon(row.get("iconKind", ""), accent), row.get("label", ""), accent)
	content.offset_left = UI.COMMAND_ROW_MARGIN_H
	content.offset_right = -UI.COMMAND_ROW_MARGIN_H
	content.add_theme_constant_override("separation", 6)
	var icon: Control = content.get_child(0)
	icon.custom_minimum_size = Vector2(MENU_ICON_SIZE, MENU_ICON_SIZE)
	(content.get_child(1) as Label).add_theme_font_size_override("font_size", MENU_FONT_SIZE)
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
# amendment): the header (Complication readout) if any, then each row --
# equal height, 1px rules between, no per-row panel or emphasis.
func _build_row_column(header: Control, rows: Array) -> Control:
	var col := UI.vbox(0)
	UI.anchor_full_rect(col)
	col.alignment = BoxContainer.ALIGNMENT_END
	var controls: Array[Control] = []
	if header != null:
		controls.append(header)
	for i in rows.size():
		controls.append(_build_command_row(rows[i], "RowButton_%d" % i, _locked))
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
		"dial":
			return Icons.draw_dial
		"bag":
			return Icons.draw_bag
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
	_connect_press(button, row)

	var content := _build_row_content(_build_row_icon(row.get("iconKind", ""), accent), row.get("label", ""), accent)
	content.offset_left = UI.COMMAND_ROW_MARGIN_H
	content.offset_right = -UI.COMMAND_ROW_MARGIN_H
	var badge: String = row.get("badge", "")
	if badge != "":
		content.add_child(_build_level_badge(badge, accent))
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


# Connects the row's callback; a row with a `peek` { title, effects, next }
# also shows it on a long press, and the release that ends a peek isn't a tap.
func _connect_press(button: Button, row: Dictionary) -> void:
	var callback: Callable = row.get("callback", Callable())
	var peek: Dictionary = row.get("peek", {})
	if not peek.is_empty():
		button.gui_input.connect(_on_peek_input.bind(button, peek))
		button.mouse_exited.connect(_hide_peek)
	if callback.is_valid():
		button.pressed.connect(func() -> void:
			if button.get_meta("peeked", false):
				button.set_meta("peeked", false)
			else:
				callback.call())


func _on_peek_input(event: InputEvent, button: Button, peek: Dictionary) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			button.set_meta("peeked", false)
			await get_tree().create_timer(PEEK_HOLD_SECONDS).timeout
			if is_instance_valid(button) and button.is_hovered() and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				button.set_meta("peeked", true)
				_show_peek(button, peek)
		else:
			_hide_peek()


# The read-only peek, a panel above `anchor`; it takes no input.
func _show_peek(anchor: Control, peek: Dictionary) -> void:
	_hide_peek()
	var panel := PanelContainer.new()
	panel.name = "MovePeek"
	panel.top_level = true
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := UI.vbox(4)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var title := UI.label(peek["title"])
	title.custom_minimum_size.x = TOOLTIP_WIDTH
	box.add_child(title)
	for effect in peek["effects"]:
		box.add_child(UI.label(str(effect)))
	box.add_child(UI.muted_label(peek["next"]))
	for child in box.get_children():
		child.mouse_filter = Control.MOUSE_FILTER_IGNORE
		child.custom_minimum_size.x = TOOLTIP_WIDTH
	panel.add_child(box)
	add_child(panel)
	panel.reset_size()
	var top := anchor.get_global_rect().position
	panel.global_position = Vector2(top.x, maxf(0.0, top.y - panel.size.y - 4.0))


func _hide_peek() -> void:
	var panel := get_node_or_null("MovePeek")
	if panel != null:
		panel.name = "MovePeekClosing"
		panel.queue_free()


# A move row's level badge ("L2"): small text in the row's accent, taps
# passing through to the row.
func _build_level_badge(text: String, colour: Color) -> Label:
	var badge := UI.label(text)
	badge.name = "LevelBadge"
	badge.custom_minimum_size.x = 0.0
	badge.autowrap_mode = TextServer.AUTOWRAP_OFF
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	badge.add_theme_font_size_override("font_size", LEVEL_BADGE_FONT_SIZE)
	badge.add_theme_color_override("font_color", colour)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return badge


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

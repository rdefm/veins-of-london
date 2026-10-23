class_name HqLabBenchScreen
extends Control

# The HQ Lab zone: the Lab plate (docs/hq-diorama-vision.md §5.1) over the
# live Lab system (.scratch/lab-port/spec.md § Screens). Jar badges show the
# player's real calc; the recipes notebook opens the recipe book of known
# recipes by ore tab (§5.2 look), and a recipe's page shows its procedure as
# known, best rank, the reserved knowledge-ladder region, batch and Craft
# manually.
#
# "Craft manually" docks the book under the Press, over the plate's lower
# edge, with the plate lifted so its jars sit just below the top bar: the
# recipe's jars tap real calc in, apparatus pop their gauge over the plate,
# the book's notebook strip shows one known step at a time, and its Finish
# -- the only way out -- shows the result and clues in place, with the
# Rewind choices. An open lesson
# (LessonSession) keeps the book docked on its recipe with no Rewind, and
# its result offers Try again until the goal is met, then Continue.

const _DOCK_MIN_HEIGHT := 160.0
const _GAUGE_WIDTH := 300.0
const _TICK_SIZE := 96.0
const _INSET := 4.0
const _BADGE_HEIGHT := 26.0
const _BADGE_FONT_SIZE := 14
const _BADGE_RADIUS := 8
const _BADGE_PADDING := 6
const _STATUS_FONT_SIZE := 15
const _STATUS_MIN_HEIGHT := 32.0
const _OVERLAY_MARGIN := 8.0

# Book page geometry, art space (1024x1536) of RecipeBookPage's
# recipe-book-side-tabs-blank.png.
const ORE_ORDER := ["time", "physics", "life", "fate", "emotion"]
const PER_PAGE := 4
const _TAB_CENTRES_Y := [262.0, 495.0, 728.0, 960.0, 1190.0]
const _TAB_X := 947.0
const _TAB_HIT := Vector2(125, 200)
const _ENTRY_TOP := 205.0
const _ENTRY_STEP := 290.0
const _ENTRY_HEIGHT := 250.0

# Docked notebook geometry: a strip of the side-tabs art holding two entry
# slots; rects are in the strip's own pixel space (art y minus 90). Slot one
# is the browsed step, slot two the run's status.
const _STEP_STRIP := Rect2(0, 90, 1024, 670)
const _STEP_HEADER := Rect2(200, 38, 640, 44)
const _STEP_BOX := Rect2(210, 115, 215, 210)
const _STEP_TEXT := Rect2(450, 150, 380, 130)
const _STEP_BAND := Rect2(450, 290, 380, 50)
const _STATUS_AREA := Rect2(215, 420, 615, 215)
const _NOTEBOOK_BUTTON_ROW := 52.0

enum Page { NONE, BOOK, RECIPE, RUN }

# View state only: which book page and ore tab are open, the picked batch
# size, and in a docked run the open gauge's apparatus, the last refusal
# notice, the browsed step (-1 follows the run's next step) and the finished
# run's result; whether the Rewind choice is open.
var _page := Page.NONE
var _rewind_open := false
var _book_ore := ""
var _book_page := 0
var _recipe_key := ""
var _craft_qty := 1
var _gauge := ""
var _notice := ""
var _step_view := -1
var _result := {}
var _debug_overlay_enabled := false
var _bench_guard_until_msec := 0

var _diorama: HqDiorama


# One live ore glyph, centred in its control.
class _TabGlyph extends Control:
	var ore_type := ""
	var colour := Color.WHITE

	func _draw() -> void:
		OreGlyphs.draw(self, size * 0.5, ore_type, colour, size.x * 0.32)


func _ready() -> void:
	UI.anchor_full_rect(self)
	EventBus.state_changed.connect(_refresh)
	resized.connect(_refresh)
	_refresh()


func _refresh() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_diorama = null
	# An open run keeps the book docked on its recipe until Finish.
	var run = Lab.active_run()
	var lesson = LessonSession.lesson()
	if lesson != null:
		_page = Page.RUN
		_recipe_key = lesson["recipe"]
	elif run != null:
		_page = Page.RUN
		_recipe_key = run["recipe"]
	elif _page == Page.RUN and _result.is_empty() and not Lab.is_known(_recipe_key):
		_page = Page.NONE
	if _page == Page.RUN:
		_build_run()
	else:
		if _page == Page.RECIPE and not Lab.is_known(_recipe_key):
			_page = Page.BOOK
		_build_plate(Rect2(Vector2.ZERO, size))
		match _page:
			Page.BOOK:
				_build_overlay(_build_book())
			Page.RECIPE:
				_build_overlay(_build_book(), _build_recipe_card())
	if _rewind_open:
		_build_rewind_choice()


func _show(page: Page) -> void:
	_page = page
	_refresh()


# ── Plate ────────────────────────────────────────────────────────────────

# §5.1: the Lab's portrait plate, width-fit in area, the space above it
# filled with the plate's wall colour and the space below with its floor
# colour. Undocked it is centred vertically with the status line, Back and
# the debug-regions chip; docked it lifts so its jars' top edge sits _INSET
# below area's top, with none of them. Returns the plate's bottom edge.
func _build_plate(area: Rect2, docked: bool = false) -> float:
	var plate: Dictionary = GameData.HQ_VISUALS["labBench"]
	var plate_size := Vector2(plate["width"], plate["height"])
	var available: Vector2 = area.size if area.size.x > 0.0 and area.size.y > 0.0 else plate_size
	var scale_factor: float = available.x / plate_size.x
	var scaled := plate_size * scale_factor
	var offset_y: float = (available.y - scaled.y) / 2.0
	if docked:
		offset_y = -maxf(_jar_top(plate["regions"]) * scale_factor - _INSET, 0.0)
	var origin: Vector2 = area.position + Vector2(0.0, offset_y)
	var full: Vector2 = size if size.x > 0.0 and size.y > 0.0 else available
	var floor_top: float = origin.y + scaled.y

	# Bands never overlap the plate: its art draws at z -1, under them.
	_add_band(plate.get("bandTopColor", ""), Rect2(0.0, 0.0, full.x, maxf(origin.y, 0.0)))
	_add_band(plate.get("bandBottomColor", ""), Rect2(0.0, floor_top, full.x, maxf(full.y - floor_top, 0.0)))

	var frame := Control.new()
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.position = origin
	frame.size = plate_size
	frame.scale = Vector2(scale_factor, scale_factor)
	add_child(frame)

	var visible_plate: Dictionary = plate.duplicate(true)
	_label_ore_regions(visible_plate["regions"], docked)
	_diorama = HqDiorama.new()
	_diorama.build(visible_plate)
	_diorama.set_debug_overlay_enabled(_debug_overlay_enabled)
	_diorama.gui_input.connect(_on_diorama_gui_input)
	frame.add_child(_diorama)

	_add_ore_badges(visible_plate["regions"], frame.position, scale_factor)
	if docked:
		return floor_top
	_add_status_line(Rect2(0.0, floor_top, full.x, maxf(full.y - floor_top, _STATUS_MIN_HEIGHT)))

	var back := UI.back_button("hq")
	back.position = Vector2(_INSET, UI.safe_area_top_inset() + _INSET)
	add_child(back)

	var debug_toggle := MapCardStyle.chip_button("Debug regions" if not _debug_overlay_enabled else "Debug regions ✓", _on_debug_toggle_pressed)
	debug_toggle.position = Vector2(back.position.x + back.custom_minimum_size.x + 8.0, back.position.y)
	add_child(debug_toggle)
	return floor_top


# The highest jar's top edge, art space.
func _jar_top(regions: Dictionary) -> float:
	var top := INF
	for region_id in regions:
		if String(region_id).begins_with(Lab.ORE_REGION_PREFIX):
			top = minf(top, float(regions[region_id]["y"]))
	return top if top < INF else 0.0


# Screen-space bottom edge of the lowest ore jar in the width-fit plate frame.
func _jar_bottom(frame: Control, regions: Dictionary) -> float:
	var bottom := 0.0
	for region_id in regions:
		if String(region_id).begins_with(Lab.ORE_REGION_PREFIX):
			bottom = maxf(bottom, float(regions[region_id]["y"]) + float(regions[region_id]["height"]))
	return frame.position.y + bottom * frame.scale.y


func _add_band(palette_id: String, rect: Rect2) -> void:
	var band := ColorRect.new()
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.color = GameData.PALETTE.get(palette_id, Color.BLACK)
	band.position = rect.position
	band.size = rect.size
	add_child(band)


func _on_debug_toggle_pressed() -> void:
	_debug_overlay_enabled = not _debug_overlay_enabled
	_refresh()


# Each jar's label carries its real calc; docked, the run recipe's own jars
# carry the selected outline cue as the only ones that tap.
func _label_ore_regions(regions: Dictionary, docked: bool) -> void:
	var recipe_ores: Dictionary = Lab.base_calc(_recipe_key) if docked else {}
	for ore_type in GameData.ORE_TYPES.keys():
		var region_id := Lab.ORE_REGION_PREFIX + String(ore_type)
		if not regions.has(region_id):
			continue
		regions[region_id]["label"] = "%s — %d" % [GameData.ORE_TYPES[ore_type]["name"], Lab.calc_available(ore_type)]
		if recipe_ores.has(ore_type):
			regions[region_id]["selected"] = true


# §5.4: a count badge of the player's calc centred on each jar's bottom
# edge, in screen space so it stays legible at any plate scale.
func _add_ore_badges(regions: Dictionary, origin: Vector2, scale_factor: float) -> void:
	for region_id in regions:
		if not String(region_id).begins_with(Lab.ORE_REGION_PREFIX):
			continue
		var ore_type := String(region_id).trim_prefix(Lab.ORE_REGION_PREFIX)
		var rect := HqDiorama.region_rect(regions[region_id])

		var box := CenterContainer.new()
		box.name = "OreBadge_%s" % ore_type
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.position = origin + Vector2(rect.position.x, rect.end.y) * scale_factor - Vector2(0.0, _BADGE_HEIGHT)
		box.size = Vector2(rect.size.x * scale_factor, _BADGE_HEIGHT)

		var panel := PanelContainer.new()
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var style := MapCardStyle.skin(MapCardStyle.paper(), _BADGE_RADIUS)
		style.content_margin_left = _BADGE_PADDING
		style.content_margin_right = _BADGE_PADDING
		panel.add_theme_stylebox_override("panel", style)
		panel.add_child(MapCardStyle.label(str(Lab.calc_available(ore_type)), _BADGE_FONT_SIZE, MapCardStyle.ink()))
		box.add_child(panel)
		add_child(box)


func _add_status_line(rect: Rect2) -> void:
	# PROSE-REVIEW: Lab status line.
	var text := "Open the recipe book." if not Lab.known_recipes().is_empty() else "No recipes known yet."
	var line := MapCardStyle.label(text, _STATUS_FONT_SIZE, MapCardStyle.paper())
	line.name = "StatusLine"
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	line.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line.position = rect.position
	line.size = rect.size
	add_child(line)


func _zone_at(pos: Vector2) -> String:
	return _diorama.zone_at(pos)


func _on_diorama_gui_input(event: InputEvent) -> void:
	# Touch-emulated mouse events twin every real touch; handle one of them.
	var is_touch_event: bool = (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT \
			and event.device != InputEvent.DEVICE_ID_EMULATION) \
		or (event is InputEventScreenTouch)
	if not is_touch_event or not event.pressed:
		return
	if Time.get_ticks_msec() < _bench_guard_until_msec:
		return
	var zone := _zone_at(event.position)
	if _page == Page.RUN:
		_on_run_zone_tapped(zone)
	elif zone == "notebookRecipes":
		_show(Page.BOOK)


# Docked run: a jar taps its calc in, an apparatus opens its gauge; a
# refusal shows as the book's notice. Taps wait while a gauge or the result
# is open.
func _on_run_zone_tapped(zone: String) -> void:
	if _gauge != "" or not _result.is_empty():
		return
	var outcome := {}
	if zone.begins_with(Lab.ORE_REGION_PREFIX):
		_notice = ""
		outcome = Lab.add_ore(_recipe_key, zone.trim_prefix(Lab.ORE_REGION_PREFIX))
	elif zone.begins_with(Lab.APPARATUS_REGION_PREFIX):
		outcome = Lab.check_apparatus()
		if outcome["ok"]:
			_notice = ""
			_gauge = zone.trim_prefix(Lab.APPARATUS_REGION_PREFIX)
			_refresh()
	if not outcome.get("ok", true):
		_notice = outcome["reason"]
		_refresh()


# ── Book overlay ─────────────────────────────────────────────────────────

# A dim backdrop (tap to step back) under the book column; card, when
# given, stacks centred above the book.
func _build_overlay(column: Control, card: Control = null) -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.5)
	UI.anchor_full_rect(dim)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(_on_dim_gui_input)
	add_child(dim)

	UI.anchor_full_rect(column)
	column.offset_left = _OVERLAY_MARGIN
	column.offset_right = -_OVERLAY_MARGIN
	column.offset_top = UI.safe_area_top_inset() + _OVERLAY_MARGIN
	column.offset_bottom = -(UI.nav_bar_clearance() + _OVERLAY_MARGIN)
	add_child(column)

	if card != null:
		var centre := CenterContainer.new()
		UI.anchor_full_rect(centre)
		centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
		centre.add_child(card)
		add_child(centre)


func _on_dim_gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed \
			and not TouchInput.is_emulated_mouse(event):
		_show(Page.BOOK if _page == Page.RECIPE else Page.NONE)


# The open ore tab: the picked one, else the first holding a known recipe.
func _selected_ore() -> String:
	if ORE_ORDER.has(_book_ore):
		return _book_ore
	for ore in ORE_ORDER:
		if not Lab.known_recipes(ore).is_empty():
			return ore
	return ORE_ORDER[0]


func _build_book() -> Control:
	var ore := _selected_ore()
	var known := Lab.known_recipes(ore)
	var pages := maxi(1, ceili(known.size() / float(PER_PAGE)))
	_book_page = clampi(_book_page, 0, pages - 1)
	var book := RecipeBookPage.new()
	_build_tabs(book, ore)
	if known.is_empty():
		# PROSE-REVIEW: empty ore tab.
		var empty := _page_label("No %s recipes known." % GameData.ORE_TYPES[ore]["name"].get_slice(" ", 0), RecipeBookPage.INK_MUTED)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		book.place(empty, Rect2(240, 560, 560, 400), 40.0, 11)
	var first := _book_page * PER_PAGE
	for slot in range(mini(PER_PAGE, known.size() - first)):
		_build_entry(book, known[first + slot], slot)

	var column := UI.vbox(6)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(book)
	var panel := PanelContainer.new()
	MapCardStyle.style_panel(panel, 12, 0.0)
	var row := UI.hbox(6)
	panel.add_child(row)
	# A page button shows only when there's a page in its direction.
	var counter := UI.label("Page %d/%d" % [_book_page + 1, pages] if pages > 1 else "")
	counter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if _book_page > 0:
		row.add_child(MapCardStyle.text_button("‹ Prev", func(): _turn_page(-1)))
	row.add_child(counter)
	if _book_page < pages - 1:
		row.add_child(MapCardStyle.text_button("Next ›", func(): _turn_page(1)))
	row.add_child(MapCardStyle.text_button("Close", func(): _show(Page.NONE)))
	column.add_child(panel)
	return column


func _turn_page(step: int) -> void:
	_book_page += step
	_refresh()


func _open_tab(ore: String) -> void:
	_book_ore = ore
	_book_page = 0
	_show(Page.BOOK)


func _build_tabs(book: RecipeBookPage, ore: String) -> void:
	for i in range(ORE_ORDER.size()):
		var tab_ore: String = ORE_ORDER[i]
		var centre_y: float = _TAB_CENTRES_Y[i]
		var selected := tab_ore == ore

		var glyph := _TabGlyph.new()
		glyph.ore_type = tab_ore
		glyph.colour = MapPalette.ore_colour_in(tab_ore, false)
		glyph.modulate.a = 1.0 if selected else 0.55
		glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
		book.place(glyph, Rect2(_TAB_X - 55, centre_y - 55, 110, 110))

		var hit := Button.new()
		hit.flat = true
		hit.focus_mode = Control.FOCUS_NONE
		hit.accessibility_name = "%s tab" % GameData.ORE_TYPES[tab_ore]["name"]
		hit.set_meta("ore", tab_ore)
		hit.set_meta("selected", selected)
		var outline := StyleBoxFlat.new()
		outline.bg_color = Color(0, 0, 0, 0)
		if selected:
			outline.set_border_width_all(4)
			outline.border_color = RecipeBookPage.INK
		outline.set_corner_radius_all(6)
		for state in ["normal", "hover", "pressed", "focus"]:
			hit.add_theme_stylebox_override(state, outline)
		hit.pressed.connect(func(): _open_tab(tab_ore))
		book.place(hit, Rect2(_TAB_X - _TAB_HIT.x * 0.5 + 6, centre_y - 72, _TAB_HIT.x - 20, 144))


func _build_entry(book: RecipeBookPage, recipe_key: String, slot: int) -> void:
	var recipe: Dictionary = GameData.RECIPES[recipe_key]
	var top: float = _ENTRY_TOP + _ENTRY_STEP * slot

	var icon := TextureRect.new()
	icon.texture = ItemIcons.texture(recipe_key)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	book.place(icon, Rect2(232, top + 20, 172, 168))

	var name_size := RecipeBookPage.fit_font(recipe["name"], 372.0, 44.0, 26.0)
	var name_label := _page_label(recipe["name"], RecipeBookPage.INK)
	name_label.clip_text = true
	book.place(name_label, Rect2(452, top + 8, 376, 56), name_size, 11)

	var cost := _page_label("Cost: %s" % _calc_text(Lab.base_calc(recipe_key)), RecipeBookPage.INK_MUTED)
	book.place(cost, Rect2(452, top + 76, 376, 40), 28.0, 10)

	var stock := _page_label("Stock: %d" % Crafting.inventory_qty(recipe_key), RecipeBookPage.INK_MUTED)
	book.place(stock, Rect2(452, top + 140, 376, 40), 28.0, 10)

	var rank := _page_label("Best rank: %s" % _rank_text(recipe_key), RecipeBookPage.INK)
	book.place(rank, Rect2(452, top + 207, 376, 36), 26.0, 10)

	var hit := Button.new()
	hit.flat = true
	hit.focus_mode = Control.FOCUS_NONE
	hit.accessibility_name = recipe["name"]
	hit.set_meta("recipeKey", recipe_key)
	var pressed_style := StyleBoxFlat.new()
	pressed_style.bg_color = Color(RecipeBookPage.INK, 0.12)
	pressed_style.set_corner_radius_all(8)
	hit.add_theme_stylebox_override("pressed", pressed_style)
	hit.pressed.connect(func(): _open_recipe(recipe_key))
	book.place(hit, Rect2(206, top, 626, _ENTRY_HEIGHT))


func _page_label(text: String, colour: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", RecipeBookPage.font())
	label.add_theme_color_override("font_color", colour)
	return label


func _rank_text(recipe_key: String) -> String:
	var best := int(GameState.state["lab"]["bestRanks"].get(recipe_key, 0))
	return str(best) if best > 0 else "—"


func _open_recipe(recipe_key: String) -> void:
	_recipe_key = recipe_key
	_craft_qty = 1
	_notice = ""
	_show(Page.RECIPE)


# ── Recipe page ──────────────────────────────────────────────────────────

func _build_recipe_card() -> Control:
	var c := MapCardStyle.card(18, 0.16)
	c["panel"].custom_minimum_size.x = 330
	var scroller := UI.scroll_container()
	scroller.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroller.custom_minimum_size.y = minf(560.0, maxf(size.y - 120.0, 240.0))
	var content := UI.vbox(6)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroller.add_child(content)
	c["content"].add_child(scroller)

	var recipe_key := _recipe_key
	var recipe: Dictionary = GameData.RECIPES[recipe_key]
	var cost := Lab.base_calc(recipe_key)
	content.add_child(UI.heading(recipe["name"], 18))
	content.add_child(UI.label("Best rank: %s" % _rank_text(recipe_key)))
	content.add_child(UI.muted_label("Cost per craft: %s" % _calc_text(cost)))
	if _notice != "":
		content.add_child(MapCardStyle.label(_notice, 13, MapCardStyle.action()))

	content.add_child(UI.heading("Procedure", 14))
	var steps := Lab.known_procedure(recipe_key)
	for i in steps.size():
		_add_known_step(content, i, steps[i])
	var ladder := UI.vbox(2)
	ladder.name = "LadderRegion"
	ladder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(ladder)
	_add_ladder(ladder, recipe_key)

	content.add_child(MapCardStyle.text_button("Craft manually", _dock))
	_add_batch_controls(content, recipe_key, cost)
	_add_rewind_controls(content)
	c["content"].add_child(MapCardStyle.footer([MapCardStyle.text_button("Back to book", func(): _show(Page.BOOK))]))
	return c["panel"]


# The knowledge ladder (recipe-acquisition spec § Recipe book): one line
# per rung, owned rungs bright, locked ones muted with their source.
func _add_ladder(ladder: VBoxContainer, recipe_key: String) -> void:
	ladder.add_child(UI.heading(str(GameData.RECIPE_KNOWLEDGE["ladder"]["heading"]), 14))
	for row in RecipeKnowledge.ladder_rows(recipe_key):
		var label := UI.muted_label(row["text"]) if row["state"] == "locked" else UI.label(row["text"])
		label.name = "Rung_%s" % row["rung"]
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ladder.add_child(label)


# Batch ×N at best rank, once performed by hand; multi-target once the best
# rank reaches the multi variant's tier.
func _add_batch_controls(content: VBoxContainer, recipe_key: String, cost: Dictionary) -> void:
	var lab: Dictionary = GameState.state["lab"]
	var most := Lab.max_batch(recipe_key)
	_craft_qty = clampi(_craft_qty, 1, maxi(most, 1))
	var picked := [_craft_qty]
	var reason := ""
	if not lab["performedOnce"].has(recipe_key):
		reason = "Craft one by hand first."
	elif most < 1:
		reason = "Not enough calc."
	var multi_cfg: Dictionary = GameData.LOADOUT["multiTarget"]
	var multi_offered: bool = multi_cfg["craftable"].has(recipe_key) and not Crafting.is_always_multi(recipe_key)
	var craft := MapCardStyle.action_button(_batch_label(_craft_qty), func(): _on_batch(recipe_key, picked[0]), reason != "", reason)
	var craft_button := craft.get_child(0) as Button
	var total := UI.label(_batch_total_text(cost, _craft_qty))
	var on_change := func(value: int) -> void:
		picked[0] = value
		total.text = _batch_total_text(cost, value)
		craft_button.text = _batch_label(value)
	content.add_child(MapCardStyle.quantity_slider("Batch", _craft_qty, maxi(most, 1), on_change, func(value: int): _craft_qty = value))
	content.add_child(total)
	if multi_offered:
		var multi := CheckBox.new()
		multi.text = "Multi-target"
		multi.button_pressed = Crafting.get_craft_multi(recipe_key)
		multi.disabled = not Crafting.multi_craft_available(recipe_key)
		multi.toggled.connect(func(on: bool): Crafting.set_craft_multi(recipe_key, on))
		content.add_child(multi)
		if multi.disabled:
			# PROSE-REVIEW: multi-target gate.
			content.add_child(UI.muted_label("Best rank %d unlocks multi-target." % int(multi_cfg["minTier"])))
	content.add_child(craft)


func _batch_label(qty: int) -> String:
	return "Batch ×%d" % qty


func _batch_total_text(cost: Dictionary, qty: int) -> String:
	var total := {}
	for ore_type in cost.keys():
		total[ore_type] = int(cost[ore_type]) * qty
	return "Total: %s" % _calc_text(total)


func _on_batch(recipe_key: String, qty: int) -> void:
	var outcome := Lab.batch(recipe_key, qty, Crafting.get_craft_multi(recipe_key))
	_notice = "" if outcome["ok"] else outcome["reason"]
	if outcome["ok"]:
		# PROSE-REVIEW: batch toast.
		Notify.push("Crafted %s ×%d at rank %d." % [GameData.RECIPES[recipe_key]["name"], outcome["items"], outcome["rank"]])
	_refresh()


# One Rewind button; it opens the choice of the two Rewinds (spec § Rewind):
# the last run or batch, or the whole time block. Each needs a Rewind item
# or a loaded Dial Rewind charge.
func _add_rewind_controls(content: VBoxContainer) -> void:
	if LessonSession.is_open():
		return
	var can_pay := Rewind.can_pay()
	var any := Lab.has_rewind_point() or Rewind.block_rewind_block_reason() == ""
	content.add_child(MapCardStyle.text_button("Rewind", _open_rewind_choice, not can_pay or not any))
	if not can_pay:
		# PROSE-REVIEW: no Rewind to spend.
		content.add_child(UI.muted_label("No Rewind to spend."))


func _open_rewind_choice() -> void:
	_rewind_open = true
	_refresh()


func _close_rewind_choice() -> void:
	_rewind_open = false
	_refresh()


# The small Rewind choice card over everything, on a dim that cancels it.
func _build_rewind_choice() -> void:
	var dim := ColorRect.new()
	dim.name = "RewindChoice"
	dim.color = Color(0, 0, 0, 0.5)
	UI.anchor_full_rect(dim)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(func(event: InputEvent):
		if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed \
				and not TouchInput.is_emulated_mouse(event):
			_close_rewind_choice())
	add_child(dim)

	var c := MapCardStyle.card(18, 0.16)
	c["panel"].custom_minimum_size.x = 260
	var content: VBoxContainer = c["content"]
	content.add_child(UI.heading("Rewind", 16))
	content.add_child(MapCardStyle.text_button("Rewind last craft", _on_rewind_craft, not Lab.can_rewind()))
	content.add_child(MapCardStyle.text_button("Rewind time block", _on_rewind_block, not Rewind.can_pay() or Rewind.block_rewind_block_reason() != ""))
	content.add_child(MapCardStyle.footer([MapCardStyle.text_button("Cancel", _close_rewind_choice)]))
	var centre := CenterContainer.new()
	UI.anchor_full_rect(centre)
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	centre.add_child(c["panel"])
	add_child(centre)


func _on_rewind_craft() -> void:
	_after_rewind(Lab.rewind())


func _on_rewind_block() -> void:
	_after_rewind(Rewind.rewind_to_block_start())


func _after_rewind(outcome: Dictionary) -> void:
	_gauge = ""
	_rewind_open = false
	if outcome["ok"]:
		_result = {}
		_notice = ""
		_page = Page.RECIPE
	else:
		_notice = outcome["reason"]
	_refresh()


func _dock() -> void:
	_gauge = ""
	_step_view = -1
	_notice = ""
	_result = {}
	_show(Page.RUN)


# Leaves the docked book for the recipe page; an open run keeps it docked.
func _undock() -> void:
	_result = {}
	_notice = ""
	_show(Page.RECIPE)


# ── Docked run ───────────────────────────────────────────────────────────

func _build_run() -> void:
	var top := UI.top_bar_clearance()
	_build_plate(Rect2(0.0, top, size.x, maxf(size.y - top, 0.0)), true)
	# §5.1 docked: the book runs from the Press region's bottom edge down to
	# the nav bar's top, so its footer (Finish / Done) is never under the
	# bar; never less than _DOCK_MIN_HEIGHT (it then rises over the press).
	var frame := _diorama.get_parent() as Control
	var press: Dictionary = GameData.HQ_VISUALS["labBench"]["regions"]["apparatus_compression"]
	var press_bottom: float = frame.position.y + (float(press["y"]) + float(press["height"])) * frame.scale.y
	var dock_bottom: float = UI.nav_bar_clearance() + _OVERLAY_MARGIN
	var dock_top: float = minf(press_bottom, size.y - dock_bottom - _DOCK_MIN_HEIGHT)
	var lesson = LessonSession.lesson()
	var in_run: bool = _result.is_empty() and not (lesson != null and lesson["met"])
	if in_run:
		# The bare notebook rises over the press for size, never over the jars.
		var wanted: float = (size.x - 2.0 * _OVERLAY_MARGIN) * _STEP_STRIP.size.y / _STEP_STRIP.size.x + _NOTEBOOK_BUTTON_ROW
		dock_top = maxf(minf(dock_top, size.y - dock_bottom - wanted), _jar_bottom(frame, GameData.HQ_VISUALS["labBench"]["regions"]))

	var book := _build_docked_book()
	book.name = "DockedBook"
	UI.anchor_full_rect(book)
	book.offset_left = _OVERLAY_MARGIN
	book.offset_right = -_OVERLAY_MARGIN
	book.offset_top = dock_top
	book.offset_bottom = -dock_bottom
	add_child(book)

	if _gauge != "":
		var centre := CenterContainer.new()
		UI.anchor_full_rect(centre)
		centre.offset_top = top
		centre.anchor_bottom = 0.0
		centre.offset_bottom = dock_top
		centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
		centre.add_child(_build_gauge_card(_gauge))
		add_child(centre)


# The docked book page: the run's status over the notebook strip of known
# steps, with Finish, or after Finish the run's result.
func _build_docked_book() -> Control:
	var lesson = LessonSession.lesson()
	if _result.is_empty() and not (lesson != null and lesson["met"]):
		return _build_notebook(lesson)
	var c := MapCardStyle.card(14, 0.16)
	var scroller := UI.scroll_container()
	scroller.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var content := UI.vbox(6)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroller.add_child(content)
	c["content"].add_child(scroller)

	content.add_child(UI.heading(GameData.RECIPES[_recipe_key]["name"], 18))
	if lesson != null:
		_add_lesson_status(content, lesson)
	if not _result.is_empty():
		_add_result(content)
		c["content"].add_child(MapCardStyle.footer([_result_exit_button(lesson)]))
		return c["panel"]
	c["content"].add_child(MapCardStyle.footer([MapCardStyle.text_button("Continue", LessonSession.resume)]))
	return c["panel"]


# The mid-run notebook on its own: the side-tabs art with the browsed step and
# the run's status written on it, over a slim row of page buttons.
func _build_notebook(lesson: Variant) -> Control:
	var run = Lab.active_run()
	var steps := Lab.known_procedure(_recipe_key)
	var shown := _shown_step(steps.size())

	var status := UI.vbox(2)
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status.add_child(_ink_label(GameData.RECIPES[_recipe_key]["name"], RecipeBookPage.INK))
	if lesson != null:
		_add_lesson_status(status, lesson)
	if run == null:
		# PROSE-REVIEW: docked book before the first jar tap.
		status.add_child(_ink_label("Tap the %s jar to start." % _jar_names(Lab.base_calc(_recipe_key)), RecipeBookPage.INK_MUTED))
	else:
		status.add_child(_ink_label("In the mixture: %s · steps done: %d" % [_calc_text(run["calcSpent"]), run["performed"].size()], RecipeBookPage.INK))
	if _notice != "":
		status.add_child(_ink_label(_notice, MapCardStyle.action()))
	_add_effect_controls(status)

	var strip := _build_step_strip(steps, shown)
	strip.place(status, _STATUS_AREA)
	status.clip_contents = true

	var column := UI.vbox(6)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(strip)
	var panel := PanelContainer.new()
	MapCardStyle.style_panel(panel, 12, 0.0)
	var row := UI.hbox(6)
	panel.add_child(row)
	# A step arrow shows only when there's a step in its direction.
	if shown > 0:
		row.add_child(MapCardStyle.text_button("‹ Prev", func(): _browse_step(shown - 1)))
	if shown < steps.size() - 1:
		row.add_child(MapCardStyle.text_button("Next ›", func(): _browse_step(shown + 1)))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	row.add_child(MapCardStyle.text_button("Finish", _on_finish, lesson != null and run == null))
	column.add_child(panel)
	return column


func _ink_label(text: String, colour: Color) -> Label:
	var label := _page_label(text, colour)
	label.add_theme_font_size_override("font_size", 14)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


# The known step the strip shows: the browsed one, else the run's next step
# (the last once every known step is done).
func _shown_step(count: int) -> int:
	if count == 0:
		return 0
	if _step_view >= 0:
		return clampi(_step_view, 0, count - 1)
	return mini(Lab.next_step_index(), count - 1)


func _browse_step(index: int) -> void:
	_step_view = index
	_refresh()


# The notebook strip (side-tabs art) with one known step in the book's hand: its number boxed, its line and band; the run's next step is marked.
func _build_step_strip(steps: Array, shown: int) -> Control:
	var strip := RecipeBookPage.new()
	strip.name = "StepStrip"
	strip.crop(_STEP_STRIP)
	if steps.is_empty():
		# PROSE-REVIEW: docked notebook with no known steps.
		var empty := _page_label("No steps known.", RecipeBookPage.INK_MUTED)
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		strip.place(empty, _STEP_TEXT, 40.0, 11)
		return strip
	var next := Lab.next_step_index()
	var active := shown == next
	var step: Dictionary = steps[shown]

	# PROSE-REVIEW: docked step header.
	var header_text := "Step %d of %d" % [shown + 1, steps.size()]
	if active:
		header_text += " · next"
	elif shown < next:
		header_text += " · done"
	var header := _page_label(header_text, MapCardStyle.action() if active else RecipeBookPage.INK_MUTED)
	header.name = "StepHeader"
	header.set_meta("active", active)
	strip.place(header, _STEP_HEADER, 36.0, 10)

	if active:
		var marker := Panel.new()
		marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var outline := StyleBoxFlat.new()
		outline.bg_color = Color(MapCardStyle.action(), 0.12)
		outline.set_border_width_all(3)
		outline.border_color = MapCardStyle.action()
		outline.set_corner_radius_all(6)
		marker.add_theme_stylebox_override("panel", outline)
		strip.place(marker, _STEP_BOX.grow(-6.0))
	var number := _page_label(str(shown + 1), RecipeBookPage.INK if active else RecipeBookPage.INK_MUTED)
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	number.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	strip.place(number, _STEP_BOX, 120.0, 16)

	var text := _step_text(step)
	if step.has("note"):
		text += "\n" + String(step["note"])
	var line := _page_label(text, RecipeBookPage.INK)
	line.name = "StepText"
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line.clip_text = true
	strip.place(line, _STEP_TEXT, 34.0, 10)

	var region := Lab.step_region(_recipe_key, step)
	if not region.is_empty():
		var band := LabGauges.BandGauge.new()
		band.custom_minimum_size = Vector2.ZERO
		band.set_region(region)
		strip.place(band, _STEP_BAND)
	return strip


# A lesson's goal and failed runs, and what escalation has shown so far.
func _add_lesson_status(content: VBoxContainer, lesson: Dictionary) -> void:
	# PROSE-REVIEW: lesson status lines.
	if lesson["met"]:
		content.add_child(MapCardStyle.label("Lesson done.", 14, MapCardStyle.action()))
		return
	content.add_child(MapCardStyle.label("Lesson: a hand run at rank %d or better." % int(lesson["goalRank"]), 14, MapCardStyle.action()))
	var fails := int(lesson["failedRuns"])
	if fails > 0:
		content.add_child(UI.muted_label("Failed runs: %d" % fails))
	if LessonSession.talk_through():
		content.add_child(UI.muted_label("Talk-through: every band you need is shown."))


# Done after an ordinary run; in a lesson, Continue once met, else Try again.
func _result_exit_button(lesson: Variant) -> Control:
	if lesson == null:
		return MapCardStyle.text_button("Done", _undock)
	if lesson["met"]:
		return MapCardStyle.text_button("Continue", LessonSession.resume)
	return MapCardStyle.text_button("Try again", _dock)


# Use item: one button per bench effect, spending a real one from the bag;
# a running effect shows its blocks left instead.
func _add_effect_controls(content: VBoxContainer) -> void:
	var row := UI.hbox()
	for item in Lab.usable_effects():
		var item_name: String = GameData.RECIPES[item]["name"]
		var effect = ActiveEffects.find(item)
		if effect != null:
			# PROSE-REVIEW: bench active-effect status.
			row.add_child(UI.muted_label("%s · %d left" % [item_name, ActiveEffects.blocks_left(effect)]))
		else:
			var qty := Crafting.inventory_qty(item)
			row.add_child(MapCardStyle.text_button("Use %s (%d)" % [item_name, qty], func(): Lab.use_effect(item), qty <= 0))
	content.add_child(row)


func _jar_names(base_calc: Dictionary) -> String:
	var names := PackedStringArray()
	for ore_type in base_calc.keys():
		names.append(String(GameData.ORE_TYPES[ore_type]["name"]))
	return " or ".join(names)


# A known step: its line (see _step_text), its band on a 0-100 track (faded
# when vague), and the hint's note saying which way to go.
func _add_known_step(content: VBoxContainer, index: int, step: Dictionary) -> void:
	content.add_child(UI.label("%d. %s" % [index + 1, _step_text(step)]))
	var region := Lab.step_region(_recipe_key, step)
	if not region.is_empty():
		var band := LabGauges.BandGauge.new()
		band.set_region(region)
		content.add_child(band)
	if step.has("note"):
		var note := UI.muted_label(step["note"])
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(note)


# A known step's line: apparatus, the calc it adds, and its band -- exact as
# "low–high", vague as "≈ low–high"; an insight as "?" with no band.
func _step_text(step: Dictionary) -> String:
	var calc: Dictionary = step.get("calc", {})
	var ores := ""
	for ore_type in calc.keys():
		ores += " · %s ×%d" % [ore_type, calc[ore_type]]
	var region := Lab.step_region(_recipe_key, step)
	if region.is_empty():
		return "%s%s · ?" % [Lab.apparatus_name(step["apparatus"]), ores]
	var band_text: String = "≈ %d–%d" if region["vague"] else "%d–%d"
	if step["knowledge"] == "revealed":
		# PROSE-REVIEW: tag on a band Prophet's Breath reveals.
		band_text += " (Breath)"
	elif step["knowledge"] == "talkThrough":
		# PROSE-REVIEW: tag on a band a lesson's talk-through shows.
		band_text += " (talk-through)"
	return "%s%s · %s" % [Lab.apparatus_name(step["apparatus"]), ores, band_text % [roundi(region["low"]), roundi(region["high"])]]


func _on_finish() -> void:
	if Lab.active_run() == null:
		_undock()
		return
	_result = Lab.finish_run()
	_refresh()


func _add_result(content: VBoxContainer) -> void:
	if _result["outcome"] == "cracked":
		content.add_child(UI.label("The vessel cracked. No item, and the calc is lost."))
		content.add_child(UI.muted_label("+%d XP" % _result["xp"]))
	else:
		if int(_result["ladyBonus"]) > 0:
			# PROSE-REVIEW: Be A Lady score line.
			content.add_child(UI.label("Score %d + %d (Lady) = %d → rank %d" % [_result["rawScore"], _result["ladyBonus"], _result["score"], _result["rank"]]))
		else:
			content.add_child(UI.label("Score %d → rank %d" % [_result["score"], _result["rank"]]))
		# PROSE-REVIEW: run result lines.
		content.add_child(UI.label("Made %s ×%d at rank %d." % [GameData.RECIPES[_result["recipe"]]["name"], _result["items"], _result["rank"]]))
		if _result["newBest"]:
			content.add_child(MapCardStyle.label("New best rank.", 14, MapCardStyle.action()))
		content.add_child(UI.muted_label("Best rank: %s · +%d XP" % [_rank_text(_result["recipe"]), _result["xp"]]))
		if _result["bonus"] != null:
			content.add_child(UI.label("Bonus: %s" % GameData.LAB["bonus"]["types"][_result["bonus"]]["label"]))
		for i in _result["clues"].size():
			var clue := UI.label("%d. %s" % [i + 1, _clue_text(_result["clues"][i])])
			clue.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			content.add_child(clue)
		if _result["steps"].is_empty():
			content.add_child(UI.muted_label("No steps performed."))
		if _result.get("insight") != null:
			var insight := MapCardStyle.label(_result["insight"]["text"], 14, MapCardStyle.action())
			insight.name = "InsightLine"
			insight.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			content.add_child(insight)
		if _result["flavour"] != null:
			var flavour := UI.muted_label(_result["flavour"])
			flavour.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			content.add_child(flavour)
	var lesson: Dictionary = _result.get("lesson", {})
	# PROSE-REVIEW: lesson escalation lines.
	if lesson.get("hintExact", false):
		content.add_child(MapCardStyle.label(LessonSession.line("hintExact", "The hint sharpens: its band is exact now."), 14, MapCardStyle.action()))
	if lesson.get("talkThrough", false):
		content.add_child(MapCardStyle.label(LessonSession.line("talkThrough", "Talk-through: the bands you still need are shown exact."), 14, MapCardStyle.action()))
	if _notice != "":
		content.add_child(MapCardStyle.label(_notice, 13, MapCardStyle.action()))
	_add_rewind_controls(content)


# A notebook clue as the result shows it: apparatus, mark, direction word
# for a near miss, then what it taught.
func _clue_text(clue: Dictionary) -> String:
	var data: Dictionary = GameData.LAB
	var words: Dictionary = data["clueText"]
	var parts := PackedStringArray([Lab.apparatus_name(clue["apparatus"]), words[clue["clue"]]])
	if clue["direction"] != null:
		parts[1] += " " + String(Lab.gauge(clue["apparatus"])["directionWords"][clue["direction"]])
	if clue.get("learned") == "vague":
		parts.append(words["learnedVague"])
	elif clue.get("learned") == "exact":
		parts.append(words["learnedExact"])
	elif clue.has("hits"):
		parts.append(words["towardExact"] % [clue["hits"], int(data["vagueToExactHits"])])
	return " · ".join(parts)


# The apparatus's gauge over the plate, showing the band of the known step
# it is about to perform (none if the book shows none); its commit performs
# the step.
func _build_gauge_card(apparatus: String) -> Control:
	var c := MapCardStyle.card(18, 0.16)
	c["panel"].custom_minimum_size.x = _GAUGE_WIDTH
	var content: VBoxContainer = c["content"]
	content.add_child(UI.heading(Lab.apparatus_name(apparatus), 16))
	var g := Lab.gauge(apparatus)
	var gauge: LabGauges.StepGauge
	match apparatus:
		"grinding":
			var grind := LabGauges.GrindGauge.new()
			grind.strokes = int(g["strokes"])
			grind.period_sec = float(g["swingPeriodSec"])
			grind.committed.connect(func(readings: Array): _perform(func(): return Lab.perform_grind(readings)))
			content.add_child(UI.muted_label("Tap %d strokes on the swing." % grind.strokes))
			gauge = grind
		"distilling":
			var distil := LabGauges.DistilGauge.new()
			distil.drips = int(g["drips"])
			distil.beat_msec = float(g["beatMsec"])
			distil.fall_msec = float(g["fallMsec"])
			distil.lead_in_msec = float(g["leadInMsec"])
			distil.committed.connect(func(taps: Array): _perform(func(): return Lab.perform_distil(taps)))
			content.add_child(UI.muted_label("Tap each drip as it falls."))
			gauge = distil
		"compression":
			var crank := LabGauges.CrankGauge.new()
			crank.gain_per_rev = float(g["crankGainPerRev"])
			crank.deadzone_deg = float(g["crankDeadzoneDeg"])
			crank.min_radius_frac = float(g["crankMinRadiusFrac"])
			crank.min_bend_deg = float(g["crankMinBendDeg"])
			crank.crack_at = float(g.get("crackAt", -1.0))
			crank.committed.connect(func(value: float): _perform(func(): return Lab.perform_step(apparatus, value)))
			content.add_child(UI.muted_label("Turn the crank clockwise, then let go."))
			gauge = crank
		_:
			var hold := LabGauges.HoldGauge.new()
			hold.rise_per_sec = float(g["risePerSec"])
			hold.crack_at = float(g.get("crackAt", -1.0))
			hold.committed.connect(func(value: float): _perform(func(): return Lab.perform_step(apparatus, value)))
			content.add_child(UI.muted_label("Hold, then release."))
			gauge = hold
	var feedback := Lab.feedback()
	var lead_ore := Lab.lead_ore(_recipe_key)
	if lead_ore != "":
		gauge.input_colour = MapPalette.ore_colour_in(lead_ore, true)
	gauge.pulse_msec = float(feedback["pulseMsec"])
	gauge.pulse_min_alpha = float(feedback["pulseMinAlpha"])
	gauge.pulse_max_alpha = float(feedback["pulseMaxAlpha"])
	if gauge is LabGauges.DistilGauge:
		gauge.flash_msec = float(feedback["tapFlashMsec"])
	var pending := Lab.pending_step(apparatus)
	if not pending.is_empty():
		gauge.set_region(Lab.step_region(_recipe_key, pending))
	content.add_child(gauge)
	content.add_child(MapCardStyle.footer([MapCardStyle.text_button("Cancel", _close_gauge)]))
	return c["panel"]


func _close_gauge() -> void:
	_gauge = ""
	_refresh()


# Closes the gauge before the step's state change rebuilds the screen; a
# crack ends the run and shows its result on the book.
func _perform(step: Callable) -> void:
	var apparatus := _gauge
	_gauge = ""
	_step_view = -1
	var outcome: Dictionary = step.call()
	var cracked: bool = outcome.get("cracked", false)
	if cracked:
		_result = outcome
	_refresh()
	_show_tick(apparatus, not cracked)


# A tick (a cross on a crack) pops over the apparatus, then fades; bench taps
# are ignored for the guard window so the finishing tap can't open the
# apparatus beneath.
func _show_tick(apparatus: String, success: bool) -> void:
	var feedback := Lab.feedback()
	var hold_msec := float(feedback["tickMsec"] if success else feedback["failHoldMsec"])
	_bench_guard_until_msec = Time.get_ticks_msec() + int(feedback["benchGuardMsec"])
	var regions: Dictionary = GameData.HQ_VISUALS["labBench"]["regions"]
	var region: Dictionary = regions.get(Lab.APPARATUS_REGION_PREFIX + apparatus, {})
	if region.is_empty() or _diorama == null:
		return
	var centre: Vector2 = _diorama.get_global_transform() * HqDiorama.region_rect(region).get_center()
	var mark := LabGauges.TickMark.new()
	mark.success = success
	mark.colour = MapCardStyle.sage() if success else MapCardStyle.action()
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mark.size = Vector2.ONE * _TICK_SIZE
	mark.pivot_offset = mark.size * 0.5
	mark.position = get_global_transform().affine_inverse() * centre - mark.size * 0.5
	mark.scale = Vector2.ZERO
	add_child(mark)
	var pop := hold_msec * 0.35 / 1000.0
	var tween := mark.create_tween()
	tween.tween_property(mark, "scale", Vector2.ONE, pop).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(hold_msec * 0.45 / 1000.0)
	tween.tween_property(mark, "modulate:a", 0.0, hold_msec * 0.2 / 1000.0)
	tween.tween_callback(mark.queue_free)


func _calc_text(calc: Dictionary) -> String:
	var parts := PackedStringArray()
	for ore_type in calc.keys():
		parts.append("%s %d" % [ore_type, calc[ore_type]])
	return ", ".join(parts)

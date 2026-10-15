class_name BenchPrototypeScreen
extends Control

# Debug-app-only sandbox screen for systems/bench_prototype.gd on the live
# Lab plate (docs/hq-diorama-vision.md §5.1): jar badges show the
# prototype's calc pool, all four apparatus show, and the recipe-notebook
# zone opens the prototype's recipe book (known recipes only, §5.2 look).
# A recipe's page shows best rank and auto-craft at best rank; the book's
# back page holds every debug control, Rewind and the ledger.
#
# "Craft manually" docks the book in the floor band under the top-aligned
# plate for a freeform run (.scratch/lab-revamp/spec.md §Slice A):
# recipe jars tap calc in, apparatus pop their gauge over the plate, and
# the book's Finish -- the only way out -- shows the result in place.

const LEDGER_ROWS := 12
const _DOCK_MIN_HEIGHT := 160.0
const _GAUGE_WIDTH := 300.0
const _INSET := 4.0
const _BADGE_HEIGHT := 26.0
const _BADGE_FONT_SIZE := 14
const _BADGE_RADIUS := 8
const _BADGE_PADDING := 6
const _STATUS_FONT_SIZE := 15
const _STATUS_MIN_HEIGHT := 32.0
const _OVERLAY_MARGIN := 8.0
# Art-space writing area of RecipeBookPage's art, left of the side tabs.
const _BACK_PAGE_RECT := Rect2(206, 190, 626, 1180)

enum Page { NONE, BOOK, RECIPE, DEBUG, RUN }

# View state only: which book page is open, the picked batch size, and in a
# docked run the open gauge's apparatus, the last refusal notice and the
# finished run's result.
var _page := Page.NONE
var _book_page := 0
var _recipe_id := ""
var _craft_qty := 1
var _debug_scroll := 0
var _gauge := ""
var _notice := ""
var _result := {}

var _diorama: HqDiorama
var _debug_scroller: ScrollContainer


func _ready() -> void:
	UI.anchor_full_rect(self)
	EventBus.state_changed.connect(_refresh)
	resized.connect(_refresh)
	_refresh()


func _refresh() -> void:
	if is_instance_valid(_debug_scroller):
		_debug_scroll = _debug_scroller.scroll_vertical
	_debug_scroller = null
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_diorama = null
	# An open run keeps the book docked on its recipe until Finish.
	var run = GameState.state["benchPrototype"]["activeRun"]
	if run != null:
		_page = Page.RUN
		_recipe_id = run["recipeId"]
	if _page == Page.RUN:
		_build_run()
		return
	_build_plate(Rect2(Vector2.ZERO, size))
	match _page:
		Page.BOOK:
			_build_overlay(_build_book())
		Page.RECIPE:
			_build_overlay(_build_book(), _build_recipe_card())
		Page.DEBUG:
			_build_overlay(_build_debug_page())


func _show(page: Page) -> void:
	_page = page
	_refresh()


# ── Plate ────────────────────────────────────────────────────────────────

# §5.1: the Lab's portrait plate, width-fit in area, the space around it
# filled with the plate's wall colour and the space below with its floor
# colour. Undocked it is centred vertically with the status line and Exit;
# docked it sits at the top of area, with neither. Returns the plate's
# bottom edge.
func _build_plate(area: Rect2, docked: bool = false) -> float:
	var plate: Dictionary = GameData.HQ_VISUALS["labBench"]
	var plate_size := Vector2(plate["width"], plate["height"])
	var available: Vector2 = area.size if area.size.x > 0.0 and area.size.y > 0.0 else plate_size
	var scale_factor: float = available.x / plate_size.x
	var scaled := plate_size * scale_factor
	var origin: Vector2 = area.position + Vector2(0.0, 0.0 if docked else (available.y - scaled.y) / 2.0)
	var full: Vector2 = size if size.x > 0.0 and size.y > 0.0 else available
	var floor_top: float = origin.y + scaled.y

	_add_band(plate.get("bandTopColor", ""), Rect2(Vector2.ZERO, full))
	_add_band(plate.get("bandBottomColor", ""), Rect2(0.0, floor_top, full.x, maxf(full.y - floor_top, 0.0)))

	var frame := Control.new()
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.position = origin
	frame.size = plate_size
	frame.scale = Vector2(scale_factor, scale_factor)
	add_child(frame)

	var visible_plate: Dictionary = plate.duplicate(true)
	_label_ore_regions(visible_plate["regions"])
	_diorama = HqDiorama.new()
	_diorama.build(visible_plate)
	_diorama.gui_input.connect(_on_diorama_gui_input)
	frame.add_child(_diorama)

	_add_ore_badges(visible_plate["regions"], frame.position, scale_factor)
	if docked:
		return floor_top
	_add_status_line(Rect2(0.0, floor_top, full.x, maxf(full.y - floor_top, _STATUS_MIN_HEIGHT)))

	var back := MapCardStyle.chip_button("‹ Exit", func(): BenchPrototype.exit())
	back.position = Vector2(_INSET, UI.safe_area_top_inset() + _INSET)
	add_child(back)
	return floor_top


func _add_band(palette_id: String, rect: Rect2) -> void:
	var band := ColorRect.new()
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.color = GameData.PALETTE.get(palette_id, Color.BLACK)
	band.position = rect.position
	band.size = rect.size
	add_child(band)


func _pool_count(ore_type: String) -> int:
	return int(GameState.state["benchPrototype"]["pool"].get(ore_type, 0))


func _label_ore_regions(regions: Dictionary) -> void:
	for ore_type in GameData.ORE_TYPES.keys():
		var region_id := LabBenchNav.ORE_REGION_PREFIX + String(ore_type)
		if regions.has(region_id):
			regions[region_id]["label"] = "%s — %d" % [GameData.ORE_TYPES[ore_type]["name"], _pool_count(ore_type)]


# §5.4: a count badge centred on each jar's bottom edge, in screen space so
# it stays legible at any plate scale -- the prototype's pool, not the
# player's orichalchum.
func _add_ore_badges(regions: Dictionary, origin: Vector2, scale_factor: float) -> void:
	for region_id in regions:
		if not String(region_id).begins_with(LabBenchNav.ORE_REGION_PREFIX):
			continue
		var ore_type := String(region_id).trim_prefix(LabBenchNav.ORE_REGION_PREFIX)
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
		panel.add_child(MapCardStyle.label(str(_pool_count(ore_type)), _BADGE_FONT_SIZE, MapCardStyle.ink()))
		box.add_child(panel)
		add_child(box)


func _add_status_line(rect: Rect2) -> void:
	var root: Dictionary = GameState.state["benchPrototype"]
	var line := MapCardStyle.label("Bench prototype · XP %d · open the recipe book" % root["xpTotal"], _STATUS_FONT_SIZE, MapCardStyle.paper())
	line.name = "StatusLine"
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	line.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line.position = rect.position
	line.size = rect.size
	add_child(line)


func _on_diorama_gui_input(event: InputEvent) -> void:
	# Touch-emulated mouse events twin every real touch; handle one of them.
	var is_touch_event: bool = (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT \
			and event.device != InputEvent.DEVICE_ID_EMULATION) \
		or (event is InputEventScreenTouch)
	if not is_touch_event or not event.pressed:
		return
	var zone := _diorama.zone_at(event.position)
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
	if zone.begins_with(LabBenchNav.ORE_REGION_PREFIX):
		_notice = ""
		outcome = BenchPrototype.add_ore(_recipe_id, zone.trim_prefix(LabBenchNav.ORE_REGION_PREFIX))
	elif zone.begins_with(LabBenchNav.APPARATUS_REGION_PREFIX):
		outcome = BenchPrototype.check_apparatus()
		if outcome["ok"]:
			_notice = ""
			_gauge = zone.trim_prefix(LabBenchNav.APPARATUS_REGION_PREFIX)
			_refresh()
	if not outcome.get("ok", true):
		_notice = outcome["reason"]
		_refresh()


# ── Book overlay ─────────────────────────────────────────────────────────

# A dim backdrop (tap to step back) under the book column; card, when
# given, stacks centred above the book like the Lab's recipe detail.
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
	column.offset_bottom = -_OVERLAY_MARGIN
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


func _book_column(page: RecipeBookPage, controls: Array) -> VBoxContainer:
	var column := UI.vbox(6)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(page)
	var panel := PanelContainer.new()
	MapCardStyle.style_panel(panel, 12, 0.0)
	var row := UI.hbox(6)
	panel.add_child(row)
	for control in controls:
		row.add_child(control)
	column.add_child(panel)
	return column


func _build_book() -> Control:
	var known := BenchPrototype.known_recipes()
	var pages := LabBenchRecipeBookModal.page_count(known.size())
	_book_page = LabBenchRecipeBookModal.clamped_page(_book_page, known.size())
	var book := RecipeBookPage.new()
	if known.is_empty():
		var empty := _page_label("No recipes known.", RecipeBookPage.INK_MUTED)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		book.place(empty, Rect2(240, 560, 560, 400), 40.0, 11)
	var first := _book_page * LabBenchRecipeBookModal.PER_PAGE
	for slot in range(mini(LabBenchRecipeBookModal.PER_PAGE, known.size() - first)):
		_build_entry(book, known[first + slot], slot)

	var counter := UI.label("Page %d/%d" % [_book_page + 1, pages])
	counter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return _book_column(book, [
		MapCardStyle.text_button("‹", func(): _turn_page(-1), _book_page <= 0),
		counter,
		MapCardStyle.text_button("›", func(): _turn_page(1), _book_page >= pages - 1),
		MapCardStyle.text_button("Debug page", func(): _show(Page.DEBUG)),
		MapCardStyle.text_button("Close", func(): _show(Page.NONE)),
	])


func _turn_page(step: int) -> void:
	_book_page += step
	_refresh()


func _build_entry(book: RecipeBookPage, recipe_id: String, slot: int) -> void:
	var recipe: Dictionary = GameData.BENCH_PROTOTYPE["recipes"][recipe_id]
	var top: float = LabBenchRecipeBookModal.ENTRY_TOP + LabBenchRecipeBookModal.ENTRY_STEP * slot

	var icon := TextureRect.new()
	icon.texture = ItemIcons.texture(recipe_id)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	book.place(icon, Rect2(232, top + 20, 172, 168))

	var name_size := RecipeBookPage.fit_font(recipe["name"], 372.0, 44.0, 26.0)
	var name_label := _page_label(recipe["name"], RecipeBookPage.INK)
	name_label.clip_text = true
	book.place(name_label, Rect2(452, top + 8, 376, 56), name_size, 11)

	var cost := _page_label("Cost: %s" % _pool_text(recipe["baseCalc"]), RecipeBookPage.INK_MUTED)
	book.place(cost, Rect2(452, top + 76, 376, 40), 28.0, 10)

	var rank := _page_label("Best rank: %s" % _rank_text(recipe_id), RecipeBookPage.INK)
	book.place(rank, Rect2(452, top + 207, 376, 36), 26.0, 10)

	var hit := Button.new()
	hit.flat = true
	hit.focus_mode = Control.FOCUS_NONE
	hit.accessibility_name = recipe["name"]
	hit.set_meta("recipeId", recipe_id)
	var pressed_style := StyleBoxFlat.new()
	pressed_style.bg_color = Color(RecipeBookPage.INK, 0.12)
	pressed_style.set_corner_radius_all(8)
	hit.add_theme_stylebox_override("pressed", pressed_style)
	hit.pressed.connect(func(): _open_recipe(recipe_id))
	book.place(hit, Rect2(206, top, 626, LabBenchRecipeBookModal.ENTRY_HEIGHT))


func _page_label(text: String, colour: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", RecipeBookPage.font())
	label.add_theme_color_override("font_color", colour)
	return label


func _rank_text(recipe_id: String) -> String:
	var best: int = GameState.state["benchPrototype"]["bestRanks"].get(recipe_id, 0)
	return str(best) if best > 0 else "—"


func _open_recipe(recipe_id: String) -> void:
	_recipe_id = recipe_id
	_craft_qty = 1
	_show(Page.RECIPE)


# ── Recipe page ──────────────────────────────────────────────────────────

func _build_recipe_card() -> Control:
	var c := MapCardStyle.card(18, 0.16)
	c["panel"].custom_minimum_size.x = 330
	var content: VBoxContainer = c["content"]
	if not BenchPrototype.is_known(_recipe_id):
		content.add_child(UI.muted_label("Nothing known here."))
		content.add_child(MapCardStyle.footer([MapCardStyle.text_button("Back to book", func(): _show(Page.BOOK))]))
		return c["panel"]

	var root: Dictionary = GameState.state["benchPrototype"]
	var recipe_id := _recipe_id
	var recipe: Dictionary = GameData.BENCH_PROTOTYPE["recipes"][recipe_id]
	var cost: Dictionary = recipe["baseCalc"]
	content.add_child(UI.heading(recipe["name"], 18))
	content.add_child(UI.label("Best rank: %s" % _rank_text(recipe_id)))
	content.add_child(UI.muted_label("Cost per craft: %s" % _pool_text(cost)))

	var most := BenchPrototype.max_batch(recipe_id)
	_craft_qty = clampi(_craft_qty, 1, maxi(most, 1))
	var picked := [_craft_qty]
	var reason := ""
	if root["bestRanks"].get(recipe_id, 0) < 1:
		reason = "No rank yet. Craft one by hand first."
	elif not BenchPrototype.can_afford(BenchPrototype.recipe_cost(recipe_id, _craft_qty)):
		reason = "Not enough calc."
	elif root["activeRun"] != null:
		reason = "A run is open."
	var craft := MapCardStyle.action_button("Auto-craft ×%d" % _craft_qty, func(): BenchPrototype.batch(recipe_id, picked[0]), reason != "", reason)
	var craft_button := craft.get_child(0) as Button
	var total := UI.label(LabBenchModalHelpers.batch_total_text(cost, _craft_qty))
	var on_change := func(value: int) -> void:
		picked[0] = value
		total.text = LabBenchModalHelpers.batch_total_text(cost, value)
		craft_button.text = "Auto-craft ×%d" % value
	content.add_child(MapCardStyle.quantity_slider("Batch", _craft_qty, most, on_change, func(value: int): _craft_qty = value))
	content.add_child(total)
	content.add_child(craft)
	content.add_child(MapCardStyle.text_button("Craft manually", _dock))
	content.add_child(MapCardStyle.footer([MapCardStyle.text_button("Back to book", func(): _show(Page.BOOK))]))
	return c["panel"]


func _dock() -> void:
	_gauge = ""
	_notice = ""
	_result = {}
	_show(Page.RUN)


# Leaves the docked book for the recipe page; an open run keeps it docked.
func _undock() -> void:
	_result = {}
	_show(Page.RECIPE)


# ── Docked run ───────────────────────────────────────────────────────────

func _build_run() -> void:
	var top := UI.safe_area_top_inset()
	var plate_bottom := _build_plate(Rect2(0.0, top, size.x, maxf(size.y - top, 0.0)), true)
	# The book takes the floor band under the plate, never less than
	# _DOCK_MIN_HEIGHT (it then overlaps the plate's bottom edge).
	var dock_top: float = minf(plate_bottom, size.y - _DOCK_MIN_HEIGHT)

	var book := _build_docked_book()
	UI.anchor_full_rect(book)
	book.offset_left = _OVERLAY_MARGIN
	book.offset_right = -_OVERLAY_MARGIN
	book.offset_top = dock_top
	book.offset_bottom = -_OVERLAY_MARGIN
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


# The docked book page: the recipe's known steps (each with its band on a
# 0-100 track) and Finish, or after Finish the run's result.
func _build_docked_book() -> Control:
	var c := MapCardStyle.card(14, 0.16)
	var scroller := UI.scroll_container()
	scroller.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var content := UI.vbox(6)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroller.add_child(content)
	c["content"].add_child(scroller)

	var recipe: Dictionary = GameData.BENCH_PROTOTYPE["recipes"][_recipe_id]
	content.add_child(UI.heading(recipe["name"], 18))
	if not _result.is_empty():
		_add_result(content)
		c["content"].add_child(MapCardStyle.footer([MapCardStyle.text_button("Done", _undock)]))
		return c["panel"]

	var run = GameState.state["benchPrototype"]["activeRun"]
	if run == null:
		content.add_child(UI.muted_label("Tap a %s jar to start." % _jar_names(recipe["baseCalc"])))
	else:
		content.add_child(UI.label("In the mixture: %s · steps done: %d" % [_pool_text(run["calcSpent"]), run["performed"].size()]))
	if _notice != "":
		content.add_child(MapCardStyle.label(_notice, 13, MapCardStyle.action()))
	var steps := BenchPrototype.known_procedure(_recipe_id)
	for i in steps.size():
		_add_known_step(content, i, steps[i])
	c["content"].add_child(MapCardStyle.footer([MapCardStyle.text_button("Finish", _on_finish)]))
	return c["panel"]


func _jar_names(base_calc: Dictionary) -> String:
	var names := PackedStringArray()
	for ore_type in base_calc.keys():
		names.append(String(ore_type))
	return " or ".join(names)


func _add_known_step(content: VBoxContainer, index: int, step: Dictionary) -> void:
	var calc: Dictionary = step.get("calc", {})
	var ores := ""
	for ore_type in calc.keys():
		ores += " · %s ×%d" % [ore_type, calc[ore_type]]
	var region := BenchPrototype.step_region(_recipe_id, step)
	var band_text: String = "≈ %d–%d" if region["vague"] else "%d–%d"
	content.add_child(UI.label("%d. %s%s · %s" % [index + 1, LabBenchNav.apparatus_name(step["apparatus"]), ores, band_text % [roundi(region["low"]), roundi(region["high"])]]))
	var band := BandGauge.new()
	band.band_low = region["low"]
	band.band_high = region["high"]
	band.band_vague = region["vague"]
	content.add_child(band)
	if step.has("note"):
		content.add_child(UI.muted_label(step["note"]))


func _on_finish() -> void:
	if GameState.state["benchPrototype"]["activeRun"] == null:
		_undock()
		return
	_result = BenchPrototype.finish_procedure_run()
	_refresh()


func _add_result(content: VBoxContainer) -> void:
	var entry: Dictionary = _result["entry"]
	if entry["kind"] == "cracked":
		content.add_child(UI.label("The vessel cracked. No item, and the calc is lost."))
	else:
		content.add_child(UI.label("Score %d → rank %d" % [entry["score"], entry["rank"]]))
		if _result.get("newBest", false):
			content.add_child(MapCardStyle.label("New best rank.", 14, MapCardStyle.action()))
		content.add_child(UI.muted_label("Best rank: %s · +%d XP" % [_rank_text(entry["recipeId"]), entry["xp"]]))
		if entry["bonus"] != null:
			content.add_child(UI.label("Bonus: %s" % GameData.BENCH_PROTOTYPE["bonus"]["types"][entry["bonus"]]["label"]))
		if entry.has("steps"):
			var steps := UI.muted_label(_steps_text(entry["steps"]) if not entry["steps"].is_empty() else "No steps performed.")
			steps.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			content.add_child(steps)
		if entry["flavour"] != null:
			var flavour := UI.muted_label(entry["flavour"])
			flavour.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			content.add_child(flavour)
	content.add_child(MapCardStyle.text_button("Rewind", _on_rewind, GameState.state["benchPrototype"]["snapshots"].is_empty()))


func _on_rewind() -> void:
	_result = {}
	_page = Page.RECIPE
	BenchPrototype.rewind()


# The apparatus's gauge over the plate; its commit performs the step.
func _build_gauge_card(apparatus: String) -> Control:
	var c := MapCardStyle.card(18, 0.16)
	c["panel"].custom_minimum_size.x = _GAUGE_WIDTH
	var content: VBoxContainer = c["content"]
	content.add_child(UI.heading(LabBenchNav.apparatus_name(apparatus), 16))
	var g := BenchPrototype.gauge(apparatus)
	var gauge: StepGauge
	match apparatus:
		"grinding":
			var grind := GrindGauge.new()
			grind.strokes = int(g["strokes"])
			grind.period_sec = float(g["swingPeriodSec"])
			grind.committed.connect(func(readings: Array): _perform(func(): return BenchPrototype.perform_grind(readings)))
			content.add_child(UI.muted_label("Tap %d strokes on the swing." % grind.strokes))
			gauge = grind
		"distilling":
			var distil := DistilGauge.new()
			distil.drips = int(g["drips"])
			distil.beat_msec = float(g["beatMsec"])
			distil.fall_msec = float(g["fallMsec"])
			distil.lead_in_msec = float(g["leadInMsec"])
			distil.committed.connect(func(taps: Array): _perform(func(): return BenchPrototype.perform_distil(taps)))
			content.add_child(UI.muted_label("Tap each drip as it falls."))
			gauge = distil
		_:
			var hold := HoldGauge.new()
			hold.rise_per_sec = float(g["risePerSec"])
			hold.crack_at = float(g.get("crackAt", -1.0))
			hold.committed.connect(func(value: float): _perform(func(): return BenchPrototype.perform_step(apparatus, value)))
			content.add_child(UI.muted_label("Hold, then release."))
			gauge = hold
	content.add_child(gauge)
	content.add_child(MapCardStyle.footer([MapCardStyle.text_button("Cancel", _close_gauge)]))
	return c["panel"]


func _close_gauge() -> void:
	_gauge = ""
	_refresh()


# Closes the gauge before the step's state change rebuilds the screen; a
# crack ends the run and shows its result on the book.
func _perform(step: Callable) -> void:
	_gauge = ""
	var outcome: Dictionary = step.call()
	if outcome.get("cracked", false):
		_result = outcome
	_refresh()


# ── Debug back page ──────────────────────────────────────────────────────

func _build_debug_page() -> Control:
	var book := RecipeBookPage.new()
	var scroller := UI.scroll_container()
	var content := UI.vbox(8)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroller.add_child(content)
	book.place(scroller, _BACK_PAGE_RECT)
	_debug_scroller = scroller
	_restore_debug_scroll.call_deferred(scroller, _debug_scroll)

	var root: Dictionary = GameState.state["benchPrototype"]
	content.add_child(UI.heading("Debug", 16))
	content.add_child(UI.label("Pool: %s · XP %d" % [_pool_text(root["pool"]), root["xpTotal"]]))
	var real_note: String = " (real)" if root["skillOverride"] == null else ""
	content.add_child(UI.muted_label("Crafting skill %d%s · tolerance ×%.2f" % [BenchPrototype.effective_skill(), real_note, BenchPrototype.skill_multiplier()]))
	content.add_child(MapCardStyle.quantity_slider("Skill", BenchPrototype.effective_skill(), GameData.BENCH_PROTOTYPE["skillMax"],
		func(_qty: int): pass,
		func(qty: int): BenchPrototype.set_skill_override(qty), 0))
	content.add_child(MapCardStyle.text_button("Use real skill", func(): BenchPrototype.clear_skill_override(), root["skillOverride"] == null))

	var types: Dictionary = GameData.BENCH_PROTOTYPE["bonus"]["types"]
	var type_ids: Array = types.keys()
	var bonus_select := UI.option_button(type_ids.map(func(t): return "Bonus: %s" % types[t]["label"]))
	bonus_select.selected = maxi(0, type_ids.find(root["bonusType"]))
	bonus_select.item_selected.connect(func(index: int): BenchPrototype.set_bonus_type(type_ids[index]))
	content.add_child(bonus_select)

	for recipe_id in GameData.BENCH_PROTOTYPE["roster"]:
		_add_recipe_toggles(content, recipe_id)

	var row := UI.hbox()
	row.add_child(MapCardStyle.text_button("Refill pool", func(): BenchPrototype.refill_pool()))
	row.add_child(MapCardStyle.text_button("Rewind", func(): BenchPrototype.rewind(), root["snapshots"].is_empty()))
	content.add_child(row)
	_add_ledger(content, root["ledger"])

	return _book_column(book, [
		MapCardStyle.text_button("‹ Recipes", func(): _show(Page.BOOK)),
		MapCardStyle.text_button("Close", func(): _show(Page.NONE)),
	])


func _restore_debug_scroll(scroller: ScrollContainer, value: int) -> void:
	if not is_instance_valid(scroller) or not is_inside_tree():
		return
	await get_tree().process_frame
	if is_instance_valid(scroller):
		scroller.scroll_vertical = value


# A recipe's known toggle and per-hint level pickers.
func _add_recipe_toggles(content: VBoxContainer, recipe_id: String) -> void:
	content.add_child(UI.heading(GameData.BENCH_PROTOTYPE["recipes"][recipe_id]["name"], 14))
	var known := CheckBox.new()
	known.text = "Known"
	known.button_pressed = BenchPrototype.is_known(recipe_id)
	known.toggled.connect(func(on: bool): BenchPrototype.set_known(recipe_id, on))
	content.add_child(known)
	var levels: Array = GameData.BENCH_PROTOTYPE["hintLevels"]
	for hint in BenchPrototype.hints(recipe_id):
		var hint_id: String = hint["id"]
		var hint_select := UI.option_button(levels.map(func(l): return "%s: %s" % [hint["label"], l]))
		hint_select.selected = maxi(0, levels.find(BenchPrototype.hint_level(recipe_id, hint_id)))
		hint_select.item_selected.connect(func(index: int): BenchPrototype.set_hint_level(recipe_id, hint_id, levels[index]))
		content.add_child(hint_select)


func _add_ledger(content: VBoxContainer, ledger: Array) -> void:
	content.add_child(UI.heading("Ledger", 14))
	if ledger.is_empty():
		content.add_child(UI.muted_label("Nothing crafted yet."))
		return
	var start := maxi(0, ledger.size() - LEDGER_ROWS)
	for i in range(ledger.size() - 1, start - 1, -1):
		var entry: Dictionary = ledger[i]
		var line := UI.label(_entry_text(entry))
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(line)
		if entry.has("steps"):
			content.add_child(UI.muted_label(_steps_text(entry["steps"])))
		if entry["flavour"] != null:
			content.add_child(UI.muted_label(entry["flavour"]))


func _entry_text(entry: Dictionary) -> String:
	var recipe_name: String = GameData.BENCH_PROTOTYPE["recipes"][entry["recipeId"]]["name"]
	match entry["kind"]:
		"batch":
			return "Batch %s ×%d at rank %d · +%d XP" % [recipe_name, entry["items"], entry["rank"], entry["xp"]]
		"cracked":
			return "Cracked the vessel on %s · %.1fs · calc lost" % [recipe_name, entry["durationMsec"] / 1000.0]
	var bonus_text := ""
	if entry["bonus"] != null:
		bonus_text = " · bonus: %s" % GameData.BENCH_PROTOTYPE["bonus"]["types"][entry["bonus"]]["label"]
	return "Run %s ×%d · score %d → rank %d · %.1fs · +%d XP%s" % [recipe_name, entry["items"], entry["score"], entry["rank"], entry["durationMsec"] / 1000.0, entry["xp"], bonus_text]


func _pool_text(pool: Dictionary) -> String:
	var parts := PackedStringArray()
	for ore_type in pool.keys():
		parts.append("%s %d" % [ore_type, pool[ore_type]])
	return ", ".join(parts)


func _steps_text(steps: Array) -> String:
	var parts := PackedStringArray()
	for step in steps:
		var accuracy: String = "extra" if step["accuracy"] == null else "%d%%" % roundi(step["accuracy"] * 100.0)
		var reading: String
		if step.get("stray", false):
			reading = "spoiled"
		elif step.has("readings"):
			reading = "/".join(PackedStringArray(step["readings"].map(func(r): return "–" if r == null else str(roundi(r)))))
		else:
			reading = str(roundi(step["value"]))
		var ores: String = "" if step.get("ores", []).is_empty() else " +" + "+".join(PackedStringArray(step["ores"]))
		parts.append("%s%s %s (%s)" % [step["apparatus"], ores, reading, accuracy])
	return " · ".join(parts)


# Placeholder gauge base: a horizontal 0-100 track with the known band, or
# a faded fuzzy region for a vague step.
# Gauges report raw input through their own committed signal and score
# nothing themselves.
class StepGauge extends Control:
	var band_low := 0.0
	var band_high := 0.0
	var band_vague := false

	func _init() -> void:
		custom_minimum_size = Vector2(0, 56)
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _pressed(event: InputEvent) -> int:
		if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
			return 0
		accept_event()
		return 1 if event.pressed else -1

	func _x(value: float) -> float:
		return size.x * value / 100.0

	func _draw_track() -> Rect2:
		var track := Rect2(Vector2(0, size.y * 0.3), Vector2(size.x, size.y * 0.4))
		draw_rect(track, MapCardStyle.line())
		var band_colour := Color(MapCardStyle.sage(), 0.35) if band_vague else MapCardStyle.sage()
		draw_rect(Rect2(Vector2(_x(band_low), track.position.y), Vector2(_x(band_high - band_low), track.size.y)), band_colour)
		return track

	func _draw_needle(value: float) -> void:
		draw_line(Vector2(_x(value), 0), Vector2(_x(value), size.y), MapCardStyle.ink(), 3.0)


# The docked book's read-only track for a known step's band.
class BandGauge extends StepGauge:
	func _init() -> void:
		custom_minimum_size = Vector2(0, 24)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		_draw_track()


# Heat / compress: hold and the needle rises; release commits the raw
# needle value. With crack_at set, reaching it commits at once.
class HoldGauge extends StepGauge:
	signal committed(value: float)

	var rise_per_sec := 0.0
	var crack_at := -1.0
	var _value := 0.0
	var _holding := false

	func _ready() -> void:
		set_process(false)

	func _gui_input(event: InputEvent) -> void:
		var press := _pressed(event)
		if press > 0:
			_holding = true
			_value = 0.0
			set_process(true)
		elif press < 0 and _holding:
			_release()

	func _release() -> void:
		_holding = false
		set_process(false)
		committed.emit(_value)

	func _process(delta: float) -> void:
		_value = minf(100.0, _value + rise_per_sec * delta)
		queue_redraw()
		if crack_at >= 0.0 and _value >= crack_at:
			_release()

	func _draw() -> void:
		var track := _draw_track()
		if crack_at >= 0.0:
			draw_line(Vector2(_x(crack_at), track.position.y), Vector2(_x(crack_at), track.end.y), MapCardStyle.action(), 3.0)
		_draw_needle(_value)


# Grind: the pestle needle swings 0-100-0 every period_sec; each tap reads
# its position as a stroke, and the last stroke commits them all.
class GrindGauge extends StepGauge:
	signal committed(readings: Array)

	var strokes := 0
	var period_sec := 1.0
	var _elapsed := 0.0
	var _readings := []

	func _position() -> float:
		var phase := fposmod(_elapsed / period_sec, 1.0)
		return 200.0 * (phase if phase < 0.5 else 1.0 - phase)

	func _gui_input(event: InputEvent) -> void:
		if _pressed(event) <= 0 or _readings.size() >= strokes:
			return
		_readings.append(_position())
		queue_redraw()
		if _readings.size() >= strokes:
			set_process(false)
			committed.emit(_readings)

	func _process(delta: float) -> void:
		_elapsed += delta
		queue_redraw()

	func _draw() -> void:
		var track := _draw_track()
		for reading in _readings:
			draw_circle(Vector2(_x(reading), track.end.y + 8.0), 4.0, MapCardStyle.gold())
		_draw_needle(_position())


# Distil: after lead_in_msec, drip i falls across the track from 0 to 100
# over fall_msec, starting at i × beat_msec. Taps are reported as msec since
# drip 0 started (negative in the lead-in); the last drip's fall commits.
class DistilGauge extends StepGauge:
	signal committed(taps: Array)

	var drips := 0
	var beat_msec := 1.0
	var fall_msec := 1.0
	var lead_in_msec := 0.0
	var _elapsed_msec := 0.0
	var _taps := []

	func _clock() -> float:
		return _elapsed_msec - lead_in_msec

	func _gui_input(event: InputEvent) -> void:
		if _pressed(event) > 0:
			_taps.append(_clock())
			queue_redraw()

	func _process(delta: float) -> void:
		_elapsed_msec += delta * 1000.0
		queue_redraw()
		if _clock() > (drips - 1) * beat_msec + fall_msec:
			set_process(false)
			committed.emit(_taps)

	func _draw() -> void:
		var track := _draw_track()
		var t := _clock()
		var drip := floori(t / beat_msec)
		var into := t - drip * beat_msec
		if t >= 0.0 and drip < drips and into <= fall_msec:
			draw_circle(Vector2(_x(100.0 * into / fall_msec), track.get_center().y), track.size.y * 0.4, MapCardStyle.ink())
		for i in drips:
			draw_circle(Vector2(8.0 + i * 14.0, track.end.y + 10.0), 4.0, MapCardStyle.dim() if i < drip else MapCardStyle.line())
		draw_string(get_theme_default_font(), Vector2(size.x - 60.0, track.end.y + 16.0), "taps %d" % _taps.size(), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, MapCardStyle.muted())

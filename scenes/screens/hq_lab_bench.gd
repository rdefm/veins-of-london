class_name HqLabBenchScreen
extends Control

const _INSET := 4.0
const _BADGE_HEIGHT := 26.0
const _BADGE_FONT_SIZE := 14
const _BADGE_RADIUS := 8
const _BADGE_PADDING := 6
const _SELECT_ORE_HINT := "Pick an ore type first."

var _diorama: HqDiorama
var _press_zone: String = ""
var _debug_overlay_enabled: bool = false

func _ready() -> void:
	UI.anchor_full_rect(self)
	EventBus.state_changed.connect(_refresh)
	resized.connect(_refresh)
	_refresh()

# Off the Map tab: light card family (MapCardStyle).
func _refresh() -> void:
	MapPalette.build_light(_build)


# §5.1: one portrait plate, width-fit and vertically centred, the bands above
# and below filled with the plate's wall/floor colours.
func _build() -> void:
	for child in get_children():
		child.queue_free()
	_diorama = null

	var plate: Dictionary = GameData.HQ_VISUALS["labBench"]
	var plate_size := Vector2(plate["width"], plate["height"])
	var available: Vector2 = size if size.x > 0.0 and size.y > 0.0 else plate_size
	var scale_factor: float = available.x / plate_size.x
	var scaled_height: float = plate_size.y * scale_factor
	var top: float = (available.y - scaled_height) / 2.0

	_add_band(plate.get("bandTopColor", ""), Rect2(0.0, 0.0, available.x, maxf(top, 0.0)))
	_add_band(plate.get("bandBottomColor", ""), Rect2(0.0, top + scaled_height, available.x, maxf(available.y - top - scaled_height, 0.0)))

	var frame := Control.new()
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.position = Vector2(0.0, top)
	frame.size = plate_size
	frame.scale = Vector2(scale_factor, scale_factor)
	add_child(frame)

	var visible_plate := _visible_plate(plate, GameState.state["labBenchNav"])
	_diorama = HqDiorama.new()
	_diorama.build(visible_plate)
	_diorama.set_debug_overlay_enabled(_debug_overlay_enabled)
	_diorama.gui_input.connect(_on_diorama_gui_input)
	frame.add_child(_diorama)

	_add_ore_badges(visible_plate["regions"], frame.position, scale_factor)

	var back := UI.back_button("hq")
	back.position = Vector2(_INSET, UI.safe_area_top_inset() + _INSET)
	add_child(back)

	var debug_toggle := MapCardStyle.chip_button("Debug regions" if not _debug_overlay_enabled else "Debug regions ✓", _on_debug_toggle_pressed)
	debug_toggle.position = Vector2(back.position.x + back.custom_minimum_size.x + 8.0, back.position.y)
	add_child(debug_toggle)


func _add_band(palette_id: String, rect: Rect2) -> void:
	var band := ColorRect.new()
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.color = GameData.PALETTE.get(palette_id, Color.BLACK)
	band.position = rect.position
	band.size = rect.size
	add_child(band)


# §5.4: a count badge of player.orichalchum[type] centred on each jar's
# bottom edge, in screen space so it stays legible at any plate scale.
func _add_ore_badges(regions: Dictionary, origin: Vector2, scale_factor: float) -> void:
	for region_id in regions:
		if not String(region_id).begins_with(LabBenchNav.ORE_REGION_PREFIX):
			continue
		var ore_type := String(region_id).trim_prefix(LabBenchNav.ORE_REGION_PREFIX)
		var rect := HqDiorama.region_rect(regions[region_id])
		var count: int = GameState.state["player"]["orichalchum"].get(ore_type, 0)

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
		panel.add_child(MapCardStyle.label(str(count), _BADGE_FONT_SIZE, MapCardStyle.ink()))
		box.add_child(panel)
		add_child(box)


func _on_debug_toggle_pressed() -> void:
	_debug_overlay_enabled = not _debug_overlay_enabled
	_refresh()


func _visible_plate(plate: Dictionary, nav: Dictionary) -> Dictionary:
	var visible_plate: Dictionary = plate.duplicate(true)
	var regions: Dictionary = visible_plate["regions"]
	_label_notebook_regions(regions, nav["mode"])
	_label_ore_regions(regions, nav)
	_filter_and_label_apparatus_regions(regions, nav)
	return visible_plate
func _label_notebook_regions(regions: Dictionary, mode: Variant) -> void:
	if regions.has("notebookRecipes"):
		regions["notebookRecipes"]["label"] = "Recipes (open)" if mode == LabBenchNav.MODE_RECIPES else "Recipes"
	if regions.has("notebookExperiments"):
		regions["notebookExperiments"]["label"] = "Experiments (open)" if mode == LabBenchNav.MODE_EXPERIMENTS else "Experiments"
func _label_ore_regions(regions: Dictionary, nav: Dictionary) -> void:
	var selected: Array = nav["selectedOre"]
	for ore_type in GameData.ORE_TYPES.keys():
		var region_id := LabBenchNav.ORE_REGION_PREFIX + String(ore_type)
		if not regions.has(region_id):
			continue
		var region: Dictionary = regions[region_id]
		var count: int = GameState.state["player"]["orichalchum"].get(ore_type, 0)
		var ore_name: String = GameData.ORE_TYPES[ore_type]["name"]
		var label := "%s — %d" % [ore_name, count]
		if selected.has(ore_type):
			region["selected"] = true
			label += " · selected"
			var cost_label := _selected_ore_cost_label(ore_type, nav)
			if cost_label != "":
				label += " · costs %s" % cost_label
		region["label"] = label

func _selected_ore_cost_label(type_id: String, nav: Dictionary) -> String:
	if nav["mode"] == LabBenchNav.MODE_RECIPES:
		var costs := _selected_ore_manual_costs(nav["selectedOre"], type_id)
		if costs.is_empty():
			return ""
		if costs.size() == 1:
			return str(costs[0])
		costs.sort()
		return "%d–%d" % [costs[0], costs[costs.size() - 1]]
	return str(Bench.ORE_COST_PER_TYPE)
func _selected_ore_manual_costs(selected: Array, type_id: String) -> Array:
	if selected.is_empty():
		return []
	var skill: int = GameState.state["player"]["craftingSkill"]
	var costs: Array = []
	for approach_id in Approaches.get_known():
		var recipe_key := Bench.find_recipe_for_cell(selected, approach_id)
		if recipe_key == "" or Bench.cell_state(selected, approach_id) != "found":
			continue
		var cost: int = Crafting.calc_cost(recipe_key, skill).get(type_id, 0)
		if cost > 0:
			costs.append(cost)
	return costs
func _filter_and_label_apparatus_regions(regions: Dictionary, nav: Dictionary) -> void:
	var selected: Array = nav["selectedOre"]
	for approach_id in GameData.APPROACHES.keys():
		var region_id := LabBenchNav.APPARATUS_REGION_PREFIX + String(approach_id)
		if not regions.has(region_id):
			continue
		if not Approaches.is_known(approach_id):
			regions.erase(region_id)
			continue

		var region: Dictionary = regions[region_id]
		var suffix := ""
		var recipe_key := ""
		if nav["mode"] == LabBenchNav.MODE_RECIPES and not selected.is_empty():
			recipe_key = Bench.find_recipe_for_cell(selected, approach_id)
			if recipe_key != "" and Bench.cell_state(selected, approach_id) != "found":
				recipe_key = ""
		if recipe_key != "":
			suffix = " — %s" % GameData.RECIPES[recipe_key]["name"]
		elif not selected.is_empty() and Bench.can_probe(selected, approach_id):
			suffix = " — ready"
		region["label"] = region.get("label", region_id) + suffix
func _on_diorama_gui_input(event: InputEvent) -> void:
	# Touch-emulated mouse events (device DEVICE_ID_EMULATION) twin every real
	# touch; handling both would toggle an ore selection on and straight off.
	var is_touch_event: bool = (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT \
			and event.device != InputEvent.DEVICE_ID_EMULATION) \
		or (event is InputEventScreenTouch)
	if not is_touch_event:
		return

	var zone_id := _zone_at(event.position)

	if event.pressed:
		_press_zone = zone_id
		if zone_id != "":
			_on_zone_tapped(zone_id)
		return

	if zone_id != "" and _press_zone != "" and zone_id != _press_zone \
			and _press_zone.begins_with(LabBenchNav.ORE_REGION_PREFIX) \
			and zone_id.begins_with(LabBenchNav.APPARATUS_REGION_PREFIX):
		_on_zone_tapped(zone_id)
	_press_zone = ""

func _zone_at(pos: Vector2) -> String:
	return _diorama.zone_at(pos)
func _on_zone_tapped(zone_id: String) -> void:
	match zone_id:
		"notebookRecipes":
			_tap_notebook_and_open_modal(LabBenchNav.MODE_RECIPES, "lab_bench_recipe_book")
		"notebookExperiments":
			_tap_notebook_and_open_modal(LabBenchNav.MODE_EXPERIMENTS, "lab_bench_notes")
		_:
			if zone_id.begins_with(LabBenchNav.ORE_REGION_PREFIX):
				LabBenchNav.select_ore(zone_id.trim_prefix(LabBenchNav.ORE_REGION_PREFIX))
			elif zone_id.begins_with(LabBenchNav.APPARATUS_REGION_PREFIX):
				_run_apparatus(zone_id.trim_prefix(LabBenchNav.APPARATUS_REGION_PREFIX))

func _tap_notebook_and_open_modal(mode_id: String, modal_type: String) -> void:
	LabBenchNav.tap_notebook(mode_id)
	Modal.open(modal_type)
# An apparatus tap probes the selected ore set unless the Recipes notebook is
# held over an already-found cell, which crafts instead. No notebook is needed
# to experiment.
func _run_apparatus(approach_id: String) -> void:
	var nav: Dictionary = GameState.state["labBenchNav"]
	var selected: Array = nav["selectedOre"]
	if selected.is_empty():
		Notify.push(_SELECT_ORE_HINT)
		return

	if nav["mode"] == LabBenchNav.MODE_RECIPES:
		var recipe_key := Bench.find_recipe_for_cell(selected, approach_id)
		if recipe_key != "" and Bench.cell_state(selected, approach_id) == "found":
			Crafting.attempt_craft(recipe_key)
			return

	var reason := Bench.probe_block_reason(selected, approach_id)
	if reason != "":
		Notify.push(reason, Notify.CATEGORY_WARNING)
		return
	var result := Bench.probe(selected, approach_id)
	Modal.open("lab_bench_probe_result", {
		"outcome": result.get("outcome", ""),
		"recipeKey": result.get("recipeKey", ""),
	})

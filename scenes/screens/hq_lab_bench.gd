class_name HqLabBenchScreen
extends Control

const _STOP_LABELS := {
	"books_ore": "Books & ore containers",
	"apparatus": "Apparatus",
}
const _PAN_DURATION := 0.4
const _ARROW_INSET := 4.0
const _ORE_PLENTY_THRESHOLD := 20
const _SELECT_ORE_HINT := "Pick an ore type first."

var _diorama: HqDiorama
var _press_zone: String = ""
var _pan_x: float = 0.0
var _pan_initialized: bool = false
var _active_pan_tween: Tween = null

func _ready() -> void:
	UI.anchor_full_rect(self)
	EventBus.state_changed.connect(_refresh)
	_refresh()

func _refresh() -> void:
	if _diorama != null:
		_pan_x = _diorama.position.x
	if _active_pan_tween != null:
		_active_pan_tween.kill()
		_active_pan_tween = null

	for child in get_children():
		child.queue_free()
	_diorama = null

	var plate: Dictionary = GameData.HQ_VISUALS["labBench"]
	var stop_width: float = plate["width"] / float(LabBenchNav.STOPS.size())
	var plate_height: float = plate["height"]
	var nav: Dictionary = GameState.state["labBenchNav"]
	var stop_index: int = LabBenchNav.STOPS.find(nav["stop"])
	var available_width: float = size.x if size.x > 0.0 else stop_width
	var scale_factor: float = available_width / stop_width
	var scaled_height: float = plate_height * scale_factor

	var frame := Control.new()
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.clip_contents = true
	frame.position = Vector2.ZERO
	frame.size = Vector2(stop_width, plate_height)
	frame.scale = Vector2(scale_factor, scale_factor)
	add_child(frame)

	_diorama = HqDiorama.new()
	_diorama.build(_visible_plate(plate, nav))
	_diorama.gui_input.connect(_on_diorama_gui_input)
	frame.add_child(_diorama)
	_pan_diorama_to(-stop_index * stop_width)

	var back := UI.back_button("hq")
	back.position = Vector2(_ARROW_INSET, UI.safe_area_top_inset() + _ARROW_INSET)
	add_child(back)

	var stop_label := UI.label(_STOP_LABELS.get(nav["stop"], ""))
	stop_label.position = Vector2(back.position.x + back.custom_minimum_size.x + 8.0, back.position.y)
	add_child(stop_label)

	var left := UI.button("‹", func(): LabBenchNav.step(-1))
	left.disabled = stop_index == 0
	left.position = Vector2(_ARROW_INSET, scaled_height / 2.0)
	add_child(left)

	var right := UI.button("›", func(): LabBenchNav.step(1))
	right.disabled = stop_index == LabBenchNav.STOPS.size() - 1
	right.position = Vector2(available_width - right.custom_minimum_size.x - _ARROW_INSET, scaled_height / 2.0)
	add_child(right)
func _pan_diorama_to(target_x: float) -> void:
	if not _pan_initialized or not is_inside_tree():
		_diorama.position = Vector2(target_x, 0.0)
		_pan_x = target_x
		_pan_initialized = true
		return

	_diorama.position = Vector2(_pan_x, 0.0)
	if not is_equal_approx(_pan_x, target_x):
		_active_pan_tween = create_tween()
		_active_pan_tween.tween_property(_diorama, "position:x", target_x, _PAN_DURATION)
	_pan_x = target_x
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
		var bucket := _ore_bucket(count)
		region["image"] = region.get("%sImage" % bucket, "")

		var ore_name: String = GameData.ORE_TYPES[ore_type]["name"]
		var label := "%s — %d (%s)" % [ore_name, count, bucket]
		if selected.has(ore_type):
			region["selected"] = true
			label += " · selected"
			var cost_label := _selected_ore_cost_label(ore_type, nav)
			if cost_label != "":
				label += " · costs %s" % cost_label
		region["label"] = label

func _ore_bucket(count: int) -> String:
	if count <= 0:
		return "empty"
	if count >= _ORE_PLENTY_THRESHOLD:
		return "plenty"
	return "some"
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
			region["caption"] = UI.block_cost_suffix(1)
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
	var rects: Dictionary = _diorama.region_rects()
	for zone_id in rects:
		if (rects[zone_id] as Rect2).has_point(pos):
			return zone_id
	return ""
func _on_zone_tapped(zone_id: String) -> void:
	match zone_id:
		"notebookRecipes":
			_tap_notebook_and_maybe_open_modal(LabBenchNav.MODE_RECIPES, "lab_bench_recipe_book")
		"notebookExperiments":
			_tap_notebook_and_maybe_open_modal(LabBenchNav.MODE_EXPERIMENTS, "lab_bench_notes")
		_:
			if zone_id.begins_with(LabBenchNav.ORE_REGION_PREFIX):
				LabBenchNav.select_ore(zone_id.trim_prefix(LabBenchNav.ORE_REGION_PREFIX))
			elif zone_id.begins_with(LabBenchNav.APPARATUS_REGION_PREFIX):
				_run_apparatus(zone_id.trim_prefix(LabBenchNav.APPARATUS_REGION_PREFIX))

func _tap_notebook_and_maybe_open_modal(mode_id: String, modal_type: String) -> void:
	if LabBenchNav.tap_notebook(mode_id) == mode_id:
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

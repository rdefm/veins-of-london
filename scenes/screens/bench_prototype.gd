class_name BenchPrototypeScreen
extends Control

# Debug-app-only sandbox screen for systems/bench_prototype.gd: slice
# switcher, debug controls (skill, bonus type, refill), per-recipe cards
# (best rank, hint level, batch), the fake-run control, Rewind and the
# slice ledger.

const LEDGER_ROWS := 12

# View state only: the fake run's picked recipe and score, kept across rebuilds.
var _recipe_index: int = 0
var _score: int = 50

var _content: VBoxContainer


func _ready() -> void:
	UI.anchor_full_rect(self)
	_content = UI.screen_body(self)
	EventBus.state_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	for child in _content.get_children():
		child.queue_free()
	MapPalette.build_light(_build)


func _build() -> void:
	var root: Dictionary = GameState.state["benchPrototype"]
	var slice_id: String = root["activeSlice"]
	var s: Dictionary = root["slices"][slice_id]

	_content.add_child(MapCardStyle.text_button("‹ Exit", func(): BenchPrototype.exit()))
	_content.add_child(UI.heading("Bench Prototype"))
	_content.add_child(_build_slice_switcher(slice_id))
	_content.add_child(UI.label("Pool: %s · XP %d" % [_pool_text(s["pool"]), s["xpTotal"]]))
	_content.add_child(_build_debug_card(root, slice_id))
	for recipe_id in GameData.BENCH_PROTOTYPE["roster"]:
		_content.add_child(_build_recipe_card(slice_id, s, recipe_id))
	if slice_id == BenchPrototype.SLICE_PROCEDURE:
		_content.add_child(_build_procedure_card(s))
	else:
		_content.add_child(_build_fake_run_card(slice_id, s))
	_content.add_child(MapCardStyle.text_button("Rewind", func(): BenchPrototype.rewind(slice_id), s["snapshots"].is_empty()))
	_content.add_child(_build_ledger_card(s["ledger"]))


func _build_slice_switcher(active: String) -> Control:
	var row := UI.hbox()
	for slice_id in BenchPrototype.SLICES:
		row.add_child(MapCardStyle.text_button(slice_id.capitalize(), func(): BenchPrototype.set_active_slice(slice_id), slice_id == active))
	return row


func _build_debug_card(root: Dictionary, slice_id: String) -> Control:
	var c := MapCardStyle.card()
	c["content"].add_child(UI.heading("Debug", 14))
	var real_note: String = " (real)" if root["skillOverride"] == null else ""
	c["content"].add_child(UI.muted_label("Crafting skill %d%s · tolerance ×%.2f" % [BenchPrototype.effective_skill(), real_note, BenchPrototype.skill_multiplier()]))
	c["content"].add_child(MapCardStyle.quantity_slider("Skill", BenchPrototype.effective_skill(), GameData.BENCH_PROTOTYPE["skillMax"],
		func(_qty: int): pass,
		func(qty: int): BenchPrototype.set_skill_override(qty), 0))
	c["content"].add_child(MapCardStyle.text_button("Use real skill", func(): BenchPrototype.clear_skill_override(), root["skillOverride"] == null))

	var types: Dictionary = GameData.BENCH_PROTOTYPE["bonus"]["types"]
	var type_ids: Array = types.keys()
	var labels: Array = type_ids.map(func(t): return "Bonus: %s" % types[t]["label"])
	var bonus_select := UI.option_button(labels)
	bonus_select.selected = maxi(0, type_ids.find(root["bonusType"]))
	bonus_select.item_selected.connect(func(index: int): BenchPrototype.set_bonus_type(type_ids[index]))
	c["content"].add_child(bonus_select)

	c["content"].add_child(MapCardStyle.text_button("Refill pool", func(): BenchPrototype.refill_pool(slice_id)))
	return c["panel"]


func _build_recipe_card(slice_id: String, s: Dictionary, recipe_id: String) -> Control:
	var c := MapCardStyle.card()
	var recipe: Dictionary = GameData.BENCH_PROTOTYPE["recipes"][recipe_id]
	var best: int = s["bestRanks"][recipe_id]
	c["content"].add_child(UI.heading("%s — best rank %s" % [recipe["name"], str(best) if best > 0 else "—"], 14))
	c["content"].add_child(UI.muted_label("Cost per item: %s" % _pool_text(recipe["baseCalc"])))

	var levels: Array = GameData.BENCH_PROTOTYPE["hintLevels"]
	var hint_select := UI.option_button(levels.map(func(l): return "Hints: %s" % l))
	hint_select.selected = maxi(0, levels.find(s["hintLevels"][recipe_id]))
	hint_select.item_selected.connect(func(index: int): BenchPrototype.set_hint_level(slice_id, recipe_id, levels[index]))
	c["content"].add_child(hint_select)

	var row := UI.hbox()
	for n in BenchPrototype.BATCH_SIZES:
		var affordable: bool = BenchPrototype.can_afford(slice_id, BenchPrototype.recipe_cost(recipe_id, n))
		row.add_child(MapCardStyle.text_button("Batch ×%d" % n, func(): BenchPrototype.batch(slice_id, recipe_id, n), best < 1 or not affordable or s["activeRun"] != null))
	c["content"].add_child(row)
	return c["panel"]


func _build_fake_run_card(slice_id: String, s: Dictionary) -> Control:
	var c := MapCardStyle.card()
	c["content"].add_child(UI.heading("Fake run", 14))
	var roster: Array = GameData.BENCH_PROTOTYPE["roster"]
	var run = s["activeRun"]
	if run == null:
		var recipe_select := UI.option_button(roster.map(func(r): return GameData.BENCH_PROTOTYPE["recipes"][r]["name"]))
		_recipe_index = clampi(_recipe_index, 0, roster.size() - 1)
		recipe_select.selected = _recipe_index
		recipe_select.item_selected.connect(func(index: int): _recipe_index = index)
		c["content"].add_child(recipe_select)
		var recipe_id: String = roster[_recipe_index]
		c["content"].add_child(MapCardStyle.text_button("Begin", func(): BenchPrototype.begin_run(slice_id, roster[_recipe_index]),
			not BenchPrototype.can_afford(slice_id, BenchPrototype.recipe_cost(recipe_id))))
		return c["panel"]

	c["content"].add_child(UI.label("Running: %s" % GameData.BENCH_PROTOTYPE["recipes"][run["recipeId"]]["name"]))
	c["content"].add_child(MapCardStyle.quantity_slider("Score", _score, 100,
		func(qty: int): _score = qty,
		func(qty: int): _score = qty, 0))
	var row := UI.hbox()
	row.add_child(MapCardStyle.text_button("Finish", func(): BenchPrototype.finish_run(slice_id, _score)))
	row.add_child(MapCardStyle.text_button("Abandon", func(): BenchPrototype.abandon_run(slice_id)))
	c["content"].add_child(row)
	return c["panel"]


func _build_procedure_card(s: Dictionary) -> Control:
	var c := MapCardStyle.card()
	c["content"].add_child(UI.heading("Procedure run", 14))
	var roster: Array = GameData.BENCH_PROTOTYPE["roster"]
	var run = s["activeRun"]
	if run == null:
		var recipe_select := UI.option_button(roster.map(func(r): return GameData.BENCH_PROTOTYPE["recipes"][r]["name"]))
		_recipe_index = clampi(_recipe_index, 0, roster.size() - 1)
		recipe_select.selected = _recipe_index
		recipe_select.item_selected.connect(func(index: int):
			_recipe_index = index
			_refresh())
		c["content"].add_child(recipe_select)
		var recipe_id: String = roster[_recipe_index]
		var steps := BenchPrototype.known_procedure(recipe_id)
		for i in steps.size():
			c["content"].add_child(UI.muted_label(_step_text(recipe_id, i, steps[i])))
		c["content"].add_child(MapCardStyle.text_button("Begin", func(): BenchPrototype.begin_procedure_run(roster[_recipe_index]),
			not BenchPrototype.can_afford(BenchPrototype.SLICE_PROCEDURE, BenchPrototype.procedure_cost(steps))))
		return c["panel"]

	var recipe_id: String = run["recipeId"]
	c["content"].add_child(UI.label("Running: %s" % GameData.BENCH_PROTOTYPE["recipes"][recipe_id]["name"]))
	var done: int = run["performed"].size()
	for i in run["procedure"].size():
		var mark: String = "✓ " if i < done else ("▸ " if i == done else "  ")
		c["content"].add_child(UI.muted_label(mark + _step_text(recipe_id, i, run["procedure"][i])))
	var step = BenchPrototype.current_step()
	if step != null and step["apparatus"] == "heat":
		var band := BenchPrototype.known_band(recipe_id, step)
		var gauge := HeatGauge.new()
		gauge.band_low = band["low"]
		gauge.band_high = band["high"]
		gauge.rise_per_sec = float(GameData.BENCH_PROTOTYPE["gauges"]["heat"]["risePerSec"])
		gauge.committed.connect(func(value: float): BenchPrototype.perform_step(value))
		c["content"].add_child(UI.muted_label("Hold to heat. Release inside the band."))
		c["content"].add_child(gauge)
	c["content"].add_child(MapCardStyle.text_button("Abandon", func(): BenchPrototype.abandon_run(BenchPrototype.SLICE_PROCEDURE)))
	return c["panel"]


func _step_text(recipe_id: String, index: int, step: Dictionary) -> String:
	var apparatus: String = GameData.APPROACHES[step["apparatus"]]["name"]
	if not BenchPrototype.INTERACTIVE_APPARATUS.has(step["apparatus"]):
		return "%d. %s → %d (auto)" % [index + 1, apparatus, step["target"]]
	var band := BenchPrototype.known_band(recipe_id, step)
	return "%d. %s → band %d–%d" % [index + 1, apparatus, roundi(band["low"]), roundi(band["high"])]


func _build_ledger_card(ledger: Array) -> Control:
	var c := MapCardStyle.card()
	c["content"].add_child(UI.heading("Ledger", 14))
	if ledger.is_empty():
		c["content"].add_child(UI.muted_label("Nothing crafted yet."))
		return c["panel"]
	var start := maxi(0, ledger.size() - LEDGER_ROWS)
	for i in range(ledger.size() - 1, start - 1, -1):
		var entry: Dictionary = ledger[i]
		c["content"].add_child(UI.label(_entry_text(entry)))
		if entry.has("steps"):
			c["content"].add_child(UI.muted_label(_steps_text(entry["steps"])))
		if entry["flavour"] != null:
			c["content"].add_child(UI.muted_label(entry["flavour"]))
	return c["panel"]


func _entry_text(entry: Dictionary) -> String:
	var recipe_name: String = GameData.BENCH_PROTOTYPE["recipes"][entry["recipeId"]]["name"]
	match entry["kind"]:
		"batch":
			return "Batch %s ×%d at rank %d · +%d XP" % [recipe_name, entry["items"], entry["rank"], entry["xp"]]
		"abandoned":
			return "Abandoned %s · %.1fs" % [recipe_name, entry["durationMsec"] / 1000.0]
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
		parts.append("%s %d (%s)" % [step["apparatus"], roundi(step["value"]), accuracy])
	return " · ".join(parts)


# Placeholder heat gauge: hold and the needle rises; release commits the
# raw needle value. Draws the known band; scores nothing itself.
class HeatGauge extends Control:
	signal committed(value: float)

	var band_low := 0.0
	var band_high := 0.0
	var rise_per_sec := 0.0
	var _value := 0.0
	var _holding := false

	func _init() -> void:
		custom_minimum_size = Vector2(0, 56)
		mouse_filter = Control.MOUSE_FILTER_STOP
		set_process(false)

	func _gui_input(event: InputEvent) -> void:
		if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
			return
		accept_event()
		if event.pressed:
			_holding = true
			_value = 0.0
			set_process(true)
		elif _holding:
			_holding = false
			set_process(false)
			committed.emit(_value)

	func _process(delta: float) -> void:
		_value = minf(100.0, _value + rise_per_sec * delta)
		queue_redraw()

	func _draw() -> void:
		var track := Rect2(Vector2(0, size.y * 0.3), Vector2(size.x, size.y * 0.4))
		draw_rect(track, MapCardStyle.line())
		var band_x := size.x * band_low / 100.0
		draw_rect(Rect2(Vector2(band_x, track.position.y), Vector2(size.x * (band_high - band_low) / 100.0, track.size.y)), MapCardStyle.sage())
		var needle_x := size.x * _value / 100.0
		draw_line(Vector2(needle_x, 0), Vector2(needle_x, size.y), MapCardStyle.ink(), 3.0)

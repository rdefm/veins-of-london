class_name BenchPrototypeScreen
extends Control

# Debug-app-only sandbox screen for systems/bench_prototype.gd: slice
# switcher, debug controls (skill, bonus type, refill), per-recipe cards
# (best rank, per-hint level toggles, batch), the procedure run with its
# plan editor and notebook or the chart run with its apparatus buttons,
# next-pour queue and pour jars, Rewind and the slice ledger.

const LEDGER_ROWS := 12

# View state only: the picked recipe and insert picks, kept across rebuilds.
var _recipe_index: int = 0
var _insert_apparatus: int = 0
var _insert_position: int = 0

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
		_content.add_child(_build_chart_card(s))
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
	for hint in BenchPrototype.hints(slice_id, recipe_id):
		var hint_id: String = hint["id"]
		var hint_select := UI.option_button(levels.map(func(l): return "%s: %s" % [hint["label"], l]))
		hint_select.selected = maxi(0, levels.find(BenchPrototype.hint_level(slice_id, recipe_id, hint_id)))
		hint_select.item_selected.connect(func(index: int): BenchPrototype.set_hint_level(slice_id, recipe_id, hint_id, levels[index]))
		c["content"].add_child(hint_select)

	var row := UI.hbox()
	for n in BenchPrototype.BATCH_SIZES:
		var affordable: bool = BenchPrototype.can_afford(slice_id, BenchPrototype.recipe_cost(recipe_id, n))
		row.add_child(MapCardStyle.text_button("Batch ×%d" % n, func(): BenchPrototype.batch(slice_id, recipe_id, n), best < 1 or not affordable or s["activeRun"] != null))
	c["content"].add_child(row)
	return c["panel"]


func _build_chart_card(s: Dictionary) -> Control:
	var c := MapCardStyle.card()
	c["content"].add_child(UI.heading("Chart run", 14))
	var roster: Array = GameData.BENCH_PROTOTYPE["roster"]
	var chart: Dictionary = GameData.BENCH_PROTOTYPE["chart"]
	var run = s["activeRun"]
	var view := ChartView.new()
	view.view_min = float(chart["viewMin"])
	view.view_max = float(chart["viewMax"])
	if run == null:
		var recipe_select := UI.option_button(roster.map(func(r): return GameData.BENCH_PROTOTYPE["recipes"][r]["name"]))
		_recipe_index = clampi(_recipe_index, 0, roster.size() - 1)
		recipe_select.selected = _recipe_index
		recipe_select.item_selected.connect(func(index: int):
			_recipe_index = index
			_refresh())
		c["content"].add_child(recipe_select)
		_add_chart_view(c["content"], view, roster[_recipe_index], [[0.0, 0.0]])
		c["content"].add_child(MapCardStyle.text_button("Begin", func(): BenchPrototype.begin_chart_run(roster[_recipe_index])))
		return c["panel"]

	var recipe_id: String = run["recipeId"]
	var spent: String = _pool_text(run["calcSpent"]) if not run["calcSpent"].is_empty() else "nothing yet"
	c["content"].add_child(UI.label("Running: %s" % GameData.BENCH_PROTOTYPE["recipes"][recipe_id]["name"]))
	c["content"].add_child(UI.muted_label("Hold a jar to pour. 1 calc per %d units. Spent this run: %s" % [roundi(float(chart["unitsPerCalc"])), spent]))
	_add_chart_view(c["content"], view, recipe_id, run["path"])
	var apparatus_row := UI.hbox()
	for pair in [["heat", "Heat ⟲"], ["grinding", "Grind ½"], ["compression", "Compress ×2"], ["distilling", "Distil ↩"]]:
		var apparatus: String = pair[0]
		apparatus_row.add_child(MapCardStyle.text_button(pair[1], func(): BenchPrototype.apply_apparatus(apparatus)))
	c["content"].add_child(apparatus_row)
	c["content"].add_child(UI.muted_label("Next pour: %s" % _queue_text(BenchPrototype.chart_queue())))
	var jars := UI.hbox()
	for ore_type in chart["directions"].keys():
		var jar := PourJar.new()
		jar.ore_type = ore_type
		jar.view = view
		jar.poured.connect(func(hold_sec: float): BenchPrototype.pour(ore_type, hold_sec))
		jars.add_child(jar)
	c["content"].add_child(jars)
	var row := UI.hbox()
	row.add_child(MapCardStyle.text_button("Bottle", func(): BenchPrototype.bottle()))
	row.add_child(MapCardStyle.text_button("Abandon", func(): BenchPrototype.abandon_run(BenchPrototype.SLICE_CHART)))
	c["content"].add_child(row)
	return c["panel"]


# Every recipe's region (the picked one highlighted; bullseyes stay hidden
# at base knowledge), the run's path, and the marker at its end.
func _add_chart_view(content: VBoxContainer, view: ChartView, recipe_id: String, path: Array) -> void:
	var chart: Dictionary = GameData.BENCH_PROTOTYPE["chart"]
	view.fog_cell = float(chart["fogCell"])
	for key in BenchPrototype.slice(BenchPrototype.SLICE_CHART)["fog"].keys():
		view.cleared[key] = true
	var knowledge := BenchPrototype.chart_knowledge(recipe_id)
	view.clouds = knowledge["clouds"]
	view.routes = knowledge["routes"]
	if knowledge["bullseye"]:
		var recipe_region: Dictionary = BenchPrototype.recipe_chart(recipe_id)
		view.bullseye = {
			"centre": Vector2(float(recipe_region["centre"][0]), float(recipe_region["centre"][1])),
			"radius": BenchPrototype.bullseye_radius(recipe_id),
		}
	for id in GameData.BENCH_PROTOTYPE["roster"]:
		if not BenchPrototype.region_found(id) and id != recipe_id:
			continue
		var region: Dictionary = BenchPrototype.recipe_chart(id)
		view.regions.append({
			"centre": Vector2(float(region["centre"][0]), float(region["centre"][1])),
			"radius": float(region["radius"]), "target": id == recipe_id,
			"name": GameData.BENCH_PROTOTYPE["recipes"][id]["name"],
		})
	for point in path:
		view.path.append(Vector2(float(point[0]), float(point[1])))
	content.add_child(view)


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
		var steps := BenchPrototype.planned_procedure(recipe_id)
		for i in steps.size():
			_add_step_rows(c["content"], "", recipe_id, i, steps[i])
			c["content"].add_child(_build_step_edit_row(recipe_id, i, steps[i]))
		c["content"].add_child(_build_insert_row(recipe_id, steps.size()))
		c["content"].add_child(MapCardStyle.text_button("Reset plan", func(): BenchPrototype.reset_plan(recipe_id),
			not s["plans"].has(recipe_id)))
		c["content"].add_child(MapCardStyle.text_button("Begin", func(): BenchPrototype.begin_procedure_run(roster[_recipe_index]),
			not BenchPrototype.can_afford(BenchPrototype.SLICE_PROCEDURE, BenchPrototype.procedure_cost(steps))))
		_add_notebook(c["content"], s["notebook"].get(recipe_id, []))
		return c["panel"]

	var recipe_id: String = run["recipeId"]
	c["content"].add_child(UI.label("Running: %s" % GameData.BENCH_PROTOTYPE["recipes"][recipe_id]["name"]))
	var done: int = run["performed"].size()
	for i in run["procedure"].size():
		var mark: String = "✓ " if i < done else ("▸ " if i == done else "  ")
		_add_step_rows(c["content"], mark, recipe_id, i, run["procedure"][i])
	var step = BenchPrototype.current_step()
	if step != null:
		_add_step_gauge(c["content"], recipe_id, step)
	c["content"].add_child(MapCardStyle.text_button("Abandon", func(): BenchPrototype.abandon_run(BenchPrototype.SLICE_PROCEDURE)))
	return c["panel"]


func _add_step_gauge(content: VBoxContainer, recipe_id: String, step: Dictionary) -> void:
	var band := BenchPrototype.step_region(recipe_id, step)
	var g := BenchPrototype.gauge(step["apparatus"])
	match step["apparatus"]:
		"heat", "compression":
			var hold := HoldGauge.new()
			hold.rise_per_sec = float(g["risePerSec"])
			hold.crack_at = float(g.get("crackAt", -1.0))
			hold.committed.connect(func(value: float): BenchPrototype.perform_step(value))
			content.add_child(UI.muted_label("Hold to heat. Release inside the band." if step["apparatus"] == "heat"
				else "Hold to build pressure. Release inside the band — past the red line it cracks."))
			_add_gauge(content, hold, band)
		"grinding":
			var grind := GrindGauge.new()
			grind.strokes = int(g["strokes"])
			grind.period_sec = float(g["swingPeriodSec"])
			grind.committed.connect(func(readings: Array): BenchPrototype.perform_grind(readings))
			content.add_child(UI.muted_label("Tap %d strokes as the pestle swings through the band." % grind.strokes))
			_add_gauge(content, grind, band)
		"distilling":
			var distil := DistilGauge.new()
			distil.drips = int(g["drips"])
			distil.beat_msec = float(g["beatMsec"])
			distil.fall_msec = float(g["fallMsec"])
			distil.lead_in_msec = float(g["leadInMsec"])
			distil.committed.connect(func(taps: Array): BenchPrototype.perform_distil(taps))
			content.add_child(UI.muted_label("Tap once as each drip crosses the band. A stray tap spoils it."))
			_add_gauge(content, distil, band)


func _add_gauge(content: VBoxContainer, gauge: StepGauge, band: Dictionary) -> void:
	gauge.band_low = band["low"]
	gauge.band_high = band["high"]
	gauge.band_vague = band["vague"]
	content.add_child(gauge)


# A known step's row, plus its hint note when a hint revealed it.
func _add_step_rows(content: VBoxContainer, mark: String, recipe_id: String, index: int, step: Dictionary) -> void:
	var apparatus: String = GameData.APPROACHES[step["apparatus"]]["name"]
	var region := BenchPrototype.step_region(recipe_id, step)
	var kind: String = "somewhere in" if region["vague"] else "band"
	var inserted: String = " (your guess)" if step.get("knowledge") == "inserted" else ""
	content.add_child(UI.muted_label("%s%d. %s%s → %s %d–%d" % [mark, index + 1, apparatus, inserted, kind, roundi(region["low"]), roundi(region["high"])]))
	if step.has("note"):
		content.add_child(UI.muted_label("      %s" % step["note"]))


# Nudge buttons for a planned step, plus remove for an inserted one.
func _build_step_edit_row(recipe_id: String, index: int, step: Dictionary) -> Control:
	var nudge := float(GameData.BENCH_PROTOTYPE["nudgeStep"])
	var row := UI.hbox()
	row.add_child(MapCardStyle.text_button("−%d" % roundi(nudge), func(): BenchPrototype.nudge_step(recipe_id, index, -nudge)))
	row.add_child(MapCardStyle.text_button("+%d" % roundi(nudge), func(): BenchPrototype.nudge_step(recipe_id, index, nudge)))
	if step.get("knowledge") == "inserted":
		row.add_child(MapCardStyle.text_button("Remove", func(): BenchPrototype.remove_step(recipe_id, index)))
	return row


# Pick an apparatus and a slot (before step 1 .. after the last), then insert.
func _build_insert_row(recipe_id: String, step_count: int) -> Control:
	var apparatus_ids: Array = GameData.BENCH_PROTOTYPE["gauges"].keys()
	var row := UI.hbox()
	var apparatus_select := UI.option_button(apparatus_ids.map(func(a): return GameData.APPROACHES[a]["name"]))
	_insert_apparatus = clampi(_insert_apparatus, 0, apparatus_ids.size() - 1)
	apparatus_select.selected = _insert_apparatus
	apparatus_select.item_selected.connect(func(index: int): _insert_apparatus = index)
	row.add_child(apparatus_select)
	var slots := []
	for i in step_count + 1:
		slots.append("as step %d" % (i + 1))
	var position_select := UI.option_button(slots)
	_insert_position = clampi(_insert_position, 0, step_count)
	position_select.selected = _insert_position
	position_select.item_selected.connect(func(index: int): _insert_position = index)
	row.add_child(position_select)
	row.add_child(MapCardStyle.text_button("Insert", func():
		BenchPrototype.insert_step(recipe_id, _insert_position, apparatus_ids[_insert_apparatus])))
	return row


# The last finished run's clue per step (BenchPrototype.notebook_clues()).
func _add_notebook(content: VBoxContainer, clues: Array) -> void:
	content.add_child(UI.heading("Notebook", 14))
	if clues.is_empty():
		content.add_child(UI.muted_label("No runs written up yet."))
		return
	var needed := int(GameData.BENCH_PROTOTYPE["vagueToExactHits"])
	for i in clues.size():
		var clue: Dictionary = clues[i]
		var apparatus: String = GameData.APPROACHES[clue["apparatus"]]["name"]
		var text: String
		match clue["clue"]:
			"hit":
				text = "✓ in band"
			"near":
				var words: Dictionary = BenchPrototype.gauge(clue["apparatus"])["directionWords"]
				text = "~ right step, try %s" % words[clue["direction"]] if clue["direction"] != null else "~ right step, not quite"
			"changed":
				text = "something changed"
			_:
				text = "✗ no effect"
		if clue.get("learned") == "vague":
			text += " · new vague hint"
		elif clue.get("learned") == "exact":
			text += " · now exact"
		elif clue.has("hits"):
			text += " · %d/%d toward exact" % [clue["hits"], needed]
		content.add_child(UI.muted_label("%d. %s: %s" % [i + 1, apparatus, text]))


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
		"cracked":
			return "Cracked the vessel on %s · %.1fs · calc lost" % [recipe_name, entry["durationMsec"] / 1000.0]
	var bonus_text := ""
	if entry["bonus"] != null:
		bonus_text = " · bonus: %s" % GameData.BENCH_PROTOTYPE["bonus"]["types"][entry["bonus"]]["label"]
	if entry.has("marker"):
		bonus_text = " · bottled at (%d, %d)%s" % [roundi(entry["marker"][0]), roundi(entry["marker"][1]), bonus_text]
	return "Run %s ×%d · score %d → rank %d · %.1fs · +%d XP%s" % [recipe_name, entry["items"], entry["score"], entry["rank"], entry["durationMsec"] / 1000.0, entry["xp"], bonus_text]


func _queue_text(queue: Dictionary) -> String:
	var parts: Array[String] = []
	var turn := roundi(float(queue["rotateDeg"])) % 360
	if turn != 0:
		parts.append("turned %d° anticlockwise" % turn)
	var speed := float(queue["speedMul"])
	if not is_equal_approx(speed, 1.0):
		parts.append("speed ×%s" % str(snappedf(speed, 0.001)))
	return ", ".join(parts) if not parts.is_empty() else "straight, normal speed"


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
		parts.append("%s %s (%s)" % [step["apparatus"], reading, accuracy])
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


# Placeholder resonance chart: square, y up, view_min..view_max on both
# axes. Draws the regions, the run's path trail and marker, plus the live
# pour preview a held PourJar feeds it. Scores and moves nothing itself.
class ChartView extends Control:
	var view_min := 0.0
	var view_max := 100.0
	var regions := []
	var path: Array[Vector2] = []
	var fog_cell := 10.0
	var cleared := {}
	var clouds := []
	var routes := []
	var bullseye := {}
	var _preview_to := Vector2.ZERO
	var _preview_text := ""
	var _previewing := false

	func _init() -> void:
		custom_minimum_size = Vector2(0, 320)

	func set_preview(to: Vector2, text: String) -> void:
		_previewing = true
		_preview_to = to
		_preview_text = text
		queue_redraw()

	func clear_preview() -> void:
		_previewing = false
		queue_redraw()

	func marker() -> Vector2:
		return path[-1] if not path.is_empty() else Vector2.ZERO

	func _side() -> float:
		return minf(size.x, size.y)

	func _scale() -> float:
		return _side() / (view_max - view_min)

	func _px(point: Vector2) -> Vector2:
		var left := (size.x - _side()) / 2.0
		return Vector2(left + (point.x - view_min) * _scale(), (view_max - point.y) * _scale())

	# Shrouds every grid cell the path hasn't cleared.
	func _draw_fog() -> void:
		var shroud := Color(MapCardStyle.line(), 0.55)
		var first := floori(view_min / fog_cell)
		var last := ceili(view_max / fog_cell)
		for cx in range(first, last):
			for cy in range(first, last):
				if cleared.has("%d,%d" % [cx, cy]):
					continue
				var corner := _px(Vector2(cx * fog_cell, (cy + 1) * fog_cell))
				draw_rect(Rect2(corner, Vector2(fog_cell, fog_cell) * _scale()), shroud)

	func _draw() -> void:
		draw_rect(Rect2(_px(Vector2(view_min, view_max)), Vector2(_side(), _side())), MapCardStyle.line(), false, 1.0)
		draw_line(_px(Vector2(view_min, 0.0)), _px(Vector2(view_max, 0.0)), MapCardStyle.dim(), 1.0)
		draw_line(_px(Vector2(0.0, view_min)), _px(Vector2(0.0, view_max)), MapCardStyle.dim(), 1.0)
		_draw_fog()
		var font := get_theme_default_font()
		for region in regions:
			var colour: Color = MapCardStyle.sage() if region["target"] else MapCardStyle.line()
			var centre := _px(region["centre"])
			var radius: float = region["radius"] * _scale()
			draw_circle(centre, radius, Color(colour, 0.25))
			draw_arc(centre, radius, 0.0, TAU, 48, colour, 2.0 if region["target"] else 1.0)
			draw_string(font, centre + Vector2(-30.0, 4.0), region["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, MapCardStyle.muted())
		for cloud in clouds:
			draw_circle(_px(cloud["centre"]), cloud["radius"] * _scale(), Color(MapCardStyle.action(), 0.18))
		for route in routes:
			for i in range(1, route.size()):
				draw_dashed_line(_px(route[i - 1]), _px(route[i]), MapCardStyle.sage(), 2.0, 6.0)
		if not bullseye.is_empty():
			draw_arc(_px(bullseye["centre"]), bullseye["radius"] * _scale(), 0.0, TAU, 32, MapCardStyle.gold(), 2.0)
		for i in range(1, path.size()):
			draw_line(_px(path[i - 1]), _px(path[i]), MapCardStyle.gold(), 2.0)
		if _previewing:
			draw_line(_px(marker()), _px(_preview_to), MapCardStyle.action(), 3.0)
			draw_circle(_px(_preview_to), 5.0, MapCardStyle.action())
			draw_string(font, Vector2(8.0, 16.0), _preview_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, MapCardStyle.ink())
		draw_circle(_px(marker()), 6.0, MapCardStyle.ink())


# A calc jar: hold to pour. While held it previews the slide (queued
# transforms included) and its cost on the chart
# (BenchPrototype.pour_preview) and lets go by itself when the pool runs
# dry; release reports the raw hold seconds through poured.
class PourJar extends Control:
	signal poured(hold_sec: float)

	var ore_type := ""
	var view: ChartView
	var _held_sec := 0.0
	var _holding := false

	func _init() -> void:
		custom_minimum_size = Vector2(120, 64)
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _ready() -> void:
		set_process(false)

	func _gui_input(event: InputEvent) -> void:
		if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
			return
		accept_event()
		if event.pressed:
			_holding = true
			_held_sec = 0.0
			set_process(true)
			queue_redraw()
		elif _holding:
			_release()

	func _release() -> void:
		_holding = false
		set_process(false)
		view.clear_preview()
		queue_redraw()
		poured.emit(_held_sec)

	func _process(delta: float) -> void:
		_held_sec += delta
		var preview := BenchPrototype.pour_preview(ore_type, _held_sec)
		var direction: Vector2 = preview["direction"]
		var to := view.marker() + direction * float(preview["distance"])
		var dry: String = " · out of calc" if preview["stopped"] else ""
		view.set_preview(to, "%s −%d calc%s" % [ore_type, preview["cost"], dry])
		if preview["stopped"]:
			_release()

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), MapCardStyle.action() if _holding else MapCardStyle.line())
		draw_string(get_theme_default_font(), Vector2(10.0, size.y / 2.0 + 5.0), "Pour %s" % ore_type, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, MapCardStyle.ink())

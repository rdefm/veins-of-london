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

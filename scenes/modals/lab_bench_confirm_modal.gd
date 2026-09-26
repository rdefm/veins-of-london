class_name LabBenchConfirmModal
extends RefCounted

# The gear-tap confirm (docs/hq-diorama-vision.md §5.3): data is
# { types, approach }. Which body renders is LabBenchNav.confirm_variant()'s
# call — probe, craft (with batch stepper), or an inert warning.

const INERT_TEXT := "Nothing here. Already confirmed."


static func build(container: VBoxContainer, data: Dictionary) -> void:
	var types: Array = data.get("types", [])
	var approach: String = data.get("approach", "")
	match LabBenchNav.confirm_variant(types, approach):
		LabBenchNav.CONFIRM_CRAFT:
			_build_craft(container, types, approach)
		LabBenchNav.CONFIRM_INERT:
			_build_inert(container, types, approach)
		_:
			_build_probe(container, types, approach)


static func _build_probe(container: VBoxContainer, types: Array, approach: String) -> void:
	container.add_child(UI.heading(LabBenchNav.apparatus_name(approach)))
	container.add_child(UI.muted_label(LabBenchNav.pairing_label(types)))
	var costs := Bench.discovery_cost(types)
	for ore_type in costs:
		container.add_child(_ore_row(ore_type, costs[ore_type]))
	var reason := Bench.probe_block_reason(types, approach)
	container.add_child(MapCardStyle.action_button("Confirm", func(): _on_probe_confirmed(types, approach), reason != "", reason))
	container.add_child(MapCardStyle.footer([MapCardStyle.text_button("Cancel", func(): Modal.close())]))


static func _on_probe_confirmed(types: Array, approach: String) -> void:
	var result := Bench.probe(types, approach)
	Modal.open("lab_bench_probe_result", {
		"outcome": result.get("outcome", ""),
		"recipeKey": result.get("recipeKey", ""),
	})


static func _build_craft(container: VBoxContainer, types: Array, approach: String) -> void:
	var recipe_key := Bench.find_recipe_for_cell(types, approach)
	var r: Dictionary = GameData.RECIPES[recipe_key]
	var costs: Dictionary = Crafting.calc_cost(recipe_key, GameState.state["player"]["craftingSkill"])
	var qty: int = Crafting.get_craft_qty(recipe_key)

	container.add_child(UI.symbol_row([{ "symbol": r["symbol"], "fallback": SymbolGlyph.generic_fallback() }, r["name"]], { "heading_size": 18 }))
	container.add_child(UI.muted_label("%s · %s" % [LabBenchNav.pairing_label(types), LabBenchNav.apparatus_name(approach)]))
	for ore_type in costs:
		container.add_child(_ore_row(ore_type, costs[ore_type]))
	container.add_child(MapCardStyle.stepper("Batch", qty, func(delta: int): Crafting.adjust_craft_qty(recipe_key, delta)))
	container.add_child(UI.label("Total: %s" % _total_label(costs, qty)))

	var reason := _craft_block_reason(recipe_key, costs, qty)
	container.add_child(MapCardStyle.action_button("Confirm ×%d" % qty, func(): Crafting.attempt_craft_batch(recipe_key, qty), reason != "", reason))
	container.add_child(MapCardStyle.footer([MapCardStyle.text_button("Cancel", func(): Modal.close())]))


# Crafting's own reason for one craft first, then the whole batch's total.
static func _craft_block_reason(recipe_key: String, costs: Dictionary, qty: int) -> String:
	var reason := Crafting.craft_block_reason(recipe_key)
	if reason != "":
		return reason
	var orichalchum: Dictionary = GameState.state["player"]["orichalchum"]
	for ore_type in costs:
		if orichalchum.get(ore_type, 0) < costs[ore_type] * qty:
			return "Not enough calc for ×%d." % qty
	return ""


static func _total_label(costs: Dictionary, qty: int) -> String:
	var parts: Array[String] = []
	for ore_type in costs:
		parts.append("%d %s" % [costs[ore_type] * qty, String(ore_type).capitalize()])
	return " · ".join(parts)


static func _build_inert(container: VBoxContainer, types: Array, approach: String) -> void:
	container.add_child(UI.heading(LabBenchModalHelpers.outcome_heading("inert")))
	container.add_child(UI.muted_label("%s · %s" % [LabBenchNav.pairing_label(types), LabBenchNav.apparatus_name(approach)]))
	container.add_child(UI.label(INERT_TEXT))
	container.add_child(MapCardStyle.footer([MapCardStyle.text_button("Close", func(): Modal.close())]))


# Ore held against what this action takes of it, same shape as the recipe
# book's ingredient rows.
static func _ore_row(ore_type: String, cost: int) -> Control:
	var have: int = GameState.state["player"]["orichalchum"].get(ore_type, 0)
	var ore: Dictionary = GameData.ORE_TYPES[ore_type]
	return UI.symbol_row([{ "symbol": ore["symbol"], "fallback": SymbolGlyph.ore_fallback(ore_type) }, " %s — %d held · costs %d" % [ore["name"], have, cost]])

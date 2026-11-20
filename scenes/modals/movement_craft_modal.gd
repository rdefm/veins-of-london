class_name MovementCraftModal
extends RefCounted


static func build(container: VBoxContainer, data: Dictionary) -> void:
	var archetype: String = data.get("archetype", "")
	var m: Dictionary = GameData.DIAL_MOVEMENTS[archetype]
	var player: Dictionary = GameState.state["player"]
	var skill: int = player["craftingSkill"]
	var cost: int = Dial.movement_calc_cost_per_ore(archetype, skill)
	var chance_pct: int = int(round(Dial.movement_craft_chance(archetype, skill) * 100))

	container.add_child(UI.symbol_row([{ "symbol": m["symbol"], "fallback": SymbolGlyph.generic_fallback() }, m["name"]], { "heading_size": 20 }))
	container.add_child(UI.muted_label(m.get("description", "")))
	var cost_parts: Array = ["Costs"]
	for ore_type in GameData.ORE_TYPES.keys():
		cost_parts.append(" %d " % cost)
		cost_parts.append({ "symbol": GameData.ORE_TYPES[ore_type]["symbol"], "fallback": SymbolGlyph.ore_fallback(ore_type) })
	container.add_child(UI.symbol_row(cost_parts))
	var captured_archetype: String = archetype
	container.add_child(MapCardStyle.text_button("Craft — chance %d%%" % chance_pct, func(): _on_craft_pressed(captured_archetype), not Dial.can_craft_movement(archetype)))
	container.add_child(MapCardStyle.footer([MapCardStyle.text_button("Cancel", func(): Modal.close())]))


static func _on_craft_pressed(archetype: String) -> void:
	var result := Dial.attempt_craft_movement(archetype)
	Modal.close()
	if not result["ok"]:
		Notify.push(result["reason"], Notify.CATEGORY_WARNING)
	elif result["success"]:
		var m: Dictionary = GameData.DIAL_MOVEMENTS[archetype]
		Notify.push("Movement crafted: %s (tier %d)." % [m["name"], result["tier"]], Notify.CATEGORY_SUCCESS)
	else:
		Notify.push("Movement-crafting failed — calc spent, no Movement gained.", Notify.CATEGORY_DANGER)

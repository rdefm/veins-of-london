class_name MovementCraftModal
extends RefCounted


static func build(container: VBoxContainer, data: Dictionary) -> void:
	var archetype: String = data.get("archetype", "")
	var m: Dictionary = GameData.DIAL_MOVEMENTS[archetype]
	var player: Dictionary = GameState.state["player"]
	var skill: int = player["craftingSkill"]
	var cost: int = Dial.movement_calc_cost(archetype, skill)
	var chance_pct: int = int(round(Dial.movement_craft_chance(archetype, skill) * 100))

	container.add_child(UI.symbol_row([{ "symbol": m["symbol"], "fallback": SymbolGlyph.generic_fallback() }, m["name"]], { "heading_size": 20 }))
	container.add_child(UI.muted_label(m.get("description", "")))
	for ore_type in GameData.ORE_TYPES.keys():
		var ore: Dictionary = GameData.ORE_TYPES[ore_type]
		var have: int = player["orichalchum"].get(ore_type, 0)
		var captured_archetype: String = archetype
		var captured_ore: String = ore_type
		var b := UI.symbol_button([{ "symbol": ore["symbol"], "fallback": SymbolGlyph.ore_fallback(ore_type) }, "%s — %d calc, chance %d%%" % [ore["name"], cost, chance_pct]], func(): _on_craft_pressed(captured_archetype, captured_ore))
		b.disabled = have < cost
		container.add_child(b)
	container.add_child(UI.button("Cancel", func(): Modal.close()))


static func _on_craft_pressed(archetype: String, ore_type: String) -> void:
	var result := Dial.attempt_craft_movement(archetype, ore_type)
	Modal.close()
	if not result["ok"]:
		Notify.push(result["reason"], Notify.CATEGORY_WARNING)
	elif result["success"]:
		var m: Dictionary = GameData.DIAL_MOVEMENTS[archetype]
		Notify.push("Movement crafted: %s (tier %d)." % [m["name"], result["tier"]], Notify.CATEGORY_SUCCESS)
	else:
		Notify.push("Movement-crafting failed — calc spent, no Movement gained.", Notify.CATEGORY_DANGER)

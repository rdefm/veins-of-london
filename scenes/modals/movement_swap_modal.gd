class_name MovementSwapModal
extends RefCounted


static func build(container: VBoxContainer, data: Dictionary) -> void:
	var owner_id: String = data.get("owner", "")
	container.add_child(UI.heading("Swap Movement"))
	var player: Dictionary = GameState.state["player"]
	var inventory: Array = player["movementInventory"]
	for i in range(inventory.size()):
		var inv_movement: Dictionary = inventory[i]
		var md: Dictionary = GameData.DIAL_MOVEMENTS[inv_movement["archetype"]]
		var captured_index: int = i
		container.add_child(MapCardStyle.symbol_option_row([{ "symbol": md["symbol"], "fallback": SymbolGlyph.generic_fallback() }, "%s — attuned %s, tier %d" % [md["name"], inv_movement["oreType"], inv_movement["tier"]]], func():
			Dial.seat_movement(captured_index, owner_id)
			Modal.close()
		))
	container.add_child(MapCardStyle.footer([MapCardStyle.text_button("Cancel", func(): Modal.close())]))

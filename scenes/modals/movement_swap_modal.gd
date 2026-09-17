class_name MovementSwapModal
extends RefCounted


static func build(container: VBoxContainer, _data: Dictionary) -> void:
	container.add_child(UI.heading("Swap Movement"))
	var player: Dictionary = GameState.state["player"]
	var inventory: Array = player["movementInventory"]
	for i in range(inventory.size()):
		var inv_movement: Dictionary = inventory[i]
		var md: Dictionary = GameData.DIAL_MOVEMENTS[inv_movement["archetype"]]
		var captured_index: int = i
		container.add_child(UI.symbol_button([{ "symbol": md["symbol"], "fallback": SymbolGlyph.generic_fallback() }, "%s — attuned %s, tier %d" % [md["name"], inv_movement["oreType"], inv_movement["tier"]]], func():
			Dial.seat_movement(captured_index)
			Modal.close()
		))
	container.add_child(UI.button("Cancel", func(): Modal.close()))

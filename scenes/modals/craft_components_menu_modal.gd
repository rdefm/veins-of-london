class_name CraftComponentsMenuModal
extends RefCounted


static func build(container: VBoxContainer, data: Dictionary) -> void:
	container.add_child(UI.heading("Craft Components"))
	for archetype in GameData.CANONICAL_MOVEMENT_ARCHETYPES:
		var m: Dictionary = GameData.DIAL_MOVEMENTS[archetype]
		var block := UI.vbox(4)
		block.add_child(UI.symbol_row([{ "symbol": m["symbol"], "fallback": SymbolGlyph.generic_fallback() }, m["name"]]))
		block.add_child(UI.muted_label(m.get("description", "")))
		var captured_archetype: String = archetype
		block.add_child(MapCardStyle.footer([MapCardStyle.text_button("Craft", func(): Modal.open("movement_craft", { "archetype": captured_archetype }))]))
		container.add_child(block)
	container.add_child(MapCardStyle.footer([MapCardStyle.text_button("Close", func(): Modal.close())]))

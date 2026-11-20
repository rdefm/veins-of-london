class_name CraftComponentsMenuModal
extends RefCounted
## Dial component crafting, tabbed Movement | Lens (data.tab). Movement rows
## hand off to movement_craft; Lens rows craft directly via Dial.attempt_craft_lens.


static func build(container: VBoxContainer, data: Dictionary) -> void:
	var tab: String = data.get("tab", "movement")
	container.add_child(UI.heading("Craft Components"))
	var tabs := UI.hbox(4)
	for t in [["movement", "Movement"], ["lens", "Lens"]]:
		var captured_tab: String = t[0]
		var b := MapCardStyle.option_row(t[1], func(): Modal.set_data("tab", captured_tab), tab == captured_tab)
		b.name = "Tab_%s" % captured_tab
		tabs.add_child(b)
	container.add_child(tabs)
	if tab == "lens":
		_build_lens_tab(container)
	else:
		_build_movement_tab(container)
	container.add_child(MapCardStyle.footer([MapCardStyle.text_button("Close", func(): Modal.close())]))


static func _build_movement_tab(container: VBoxContainer) -> void:
	for archetype in GameData.CANONICAL_MOVEMENT_ARCHETYPES:
		var m: Dictionary = GameData.DIAL_MOVEMENTS[archetype]
		var block := UI.vbox(4)
		block.add_child(UI.symbol_row([{ "symbol": m["symbol"], "fallback": SymbolGlyph.generic_fallback() }, m["name"]]))
		block.add_child(UI.muted_label(m.get("description", "")))
		var captured_archetype: String = archetype
		block.add_child(MapCardStyle.footer([MapCardStyle.text_button("Craft", func(): Modal.open("movement_craft", { "archetype": captured_archetype }))]))
		container.add_child(block)


static func _build_lens_tab(container: VBoxContainer) -> void:
	var player: Dictionary = GameState.state["player"]
	var skill: int = player["craftingSkill"]
	var cost: int = Dial.lens_calc_cost(skill)
	var chance_pct: int = int(round(Dial.lens_craft_chance(skill) * 100))
	for ore in GameData.ORE_TYPES.keys():
		var block := UI.vbox(4)
		block.add_child(UI.symbol_row([DialLoadoutMenu.ore_glyph(ore), "%s Lens" % ore.capitalize()]))
		block.add_child(UI.muted_label(Lenses.one_line(ore)))
		block.add_child(UI.symbol_row(["Costs %d " % cost, DialLoadoutMenu.ore_glyph(ore), " · chance %d%%" % chance_pct], { "muted": true }))
		var captured_ore: String = ore
		var craft := MapCardStyle.text_button("Craft", func(): _on_craft_lens(captured_ore), player["orichalchum"].get(ore, 0) < cost)
		craft.name = "CraftLens_%s" % ore
		block.add_child(MapCardStyle.footer([craft]))
		container.add_child(block)


static func _on_craft_lens(ore: String) -> void:
	var result := Dial.attempt_craft_lens(ore)
	if not result["ok"]:
		Notify.push(result["reason"], Notify.CATEGORY_WARNING)
	elif result["success"]:
		Notify.push("Lens crafted: %s Lens (tier %d)." % [ore.capitalize(), result["tier"]], Notify.CATEGORY_SUCCESS)
	else:
		Notify.push("Lens-crafting failed — calc spent, no Lens gained.", Notify.CATEGORY_DANGER)

class_name ProfileApp
extends PhoneApp


func build(content: VBoxContainer) -> void:
	content.add_child(back_button())
	content.add_child(UI.heading("Profile"))

	content.add_child(_build_stats_card())
	content.add_child(_build_skills_card())
	content.add_child(_build_equipment_card())
	content.add_child(_build_loadout_card())


func _build_stats_card() -> Control:
	var player: Dictionary = GameState.state["player"]
	var atk := Combat.get_attack_range()

	var c := UI.card()
	c["content"].add_child(UI.label("HP: %d / %d" % [player["hp"], player["hpMax"]]))
	c["content"].add_child(UI.bar(player["hp"], player["hpMax"]))
	c["content"].add_child(UI.label("Attack: %d–%d" % [atk["min"], atk["max"]]))
	return c["panel"]


func _build_skills_card() -> Control:
	var player: Dictionary = GameState.state["player"]
	var c := UI.card()
	c["content"].add_child(UI.heading("Skills", 14))
	_add_skill_row(c["content"], "Crafting", player["craftingSkill"], player["craftingXP"], GameData.CRAFTING_XP_LEVELS)
	_add_skill_row(c["content"], "Cultivating", player["cultivatingSkill"], player["cultivatingXP"], GameData.CULTIVATING_XP_LEVELS)
	_add_skill_row(c["content"], "Stealth", player["stealthSkill"], player["stealthXP"], GameData.STEALTH_XP_LEVELS)
	_add_skill_row(c["content"], "Combat", player["combatSkill"], player["combatXP"], GameData.COMBAT_XP_LEVELS)
	return c["panel"]


func _add_skill_row(content: Node, label: String, level: int, xp: int, levels: Array) -> void:
	content.add_child(UI.label("%s: Lv%d (%d XP)" % [label, level, xp]))
	var max_level: int = levels.size() - 1
	if level >= max_level:
		content.add_child(UI.bar(1, 1))
	else:
		var this_threshold: int = levels[level]
		var next_threshold: int = levels[level + 1]
		content.add_child(UI.bar(xp - this_threshold, next_threshold - this_threshold))


func _build_equipment_card() -> Control:
	var player: Dictionary = GameState.state["player"]
	var c := UI.card()
	c["content"].add_child(UI.heading("Equipment", 14))
	c["content"].add_child(_dial_summary_label(player))
	return c["panel"]


func _build_loadout_card() -> Control:
	var c := UI.card()
	c["content"].add_child(UI.heading("Loadout", 14))
	var stock := Loadout.equippable_stock()
	for index in Loadout.slot_count():
		var unit: Variant = Loadout.slot(index)
		if unit == null:
			c["content"].add_child(UI.muted_label("Slot %d: empty" % (index + 1)))
			for entry in stock:
				c["content"].add_child(UI.button("Equip %s T%d (×%d)" % [GameData.RECIPES[entry["recipe"]]["name"], entry["tier"], entry["qty"]], _on_equip.bind(index, entry["recipe"], entry["tier"])))
		else:
			c["content"].add_child(UI.label("Slot %d: %s T%d" % [index + 1, GameData.RECIPES[unit["recipe"]]["name"], int(unit["tier"])]))
			c["content"].add_child(UI.button("Unequip slot %d" % (index + 1), _on_unequip.bind(index)))
	return c["panel"]


func _on_equip(index: int, recipe_key: String, tier: int) -> void:
	Loadout.equip(index, recipe_key, tier)


func _on_unequip(index: int) -> void:
	Loadout.unequip(index)


func _dial_summary_label(player: Dictionary) -> Control:
	var dial: Variant = player["dial"]
	if dial == null:
		return UI.muted_label("Dial: none")
	var movement: Variant = dial["movement"]
	if movement == null:
		return UI.label("Dial: Lv%d — no Movement seated (inert)" % dial["level"])
	var m: Dictionary = GameData.DIAL_MOVEMENTS[movement["archetype"]]
	return UI.symbol_row(["Dial: Lv%d — " % dial["level"], { "symbol": m["symbol"], "fallback": SymbolGlyph.generic_fallback() }, " %s, charge %d/%d" % [m["name"], int(dial["currentCharge"]), dial["maxCharge"]]])

class_name ProfileApp
extends PhoneApp


func build(content: VBoxContainer) -> void:
	if CombatPrep.is_editing_loadout():
		_build_prep_focus(content)
		return
	content.add_child(back_button())
	content.add_child(UI.heading("Profile"))

	content.add_child(_build_stats_card())
	content.add_child(_build_skills_card())
	content.add_child(_build_equipment_card())
	content.add_child(_build_loadout_card())
	var dial_card: Variant = MapPalette.build_light(func(): return DialLoadoutMenu.build())
	if dial_card != null:
		content.add_child(dial_card)
	for contact_id in DialLoadoutMenu.contact_owner_ids():
		var ally_dial_card: Variant = MapPalette.build_light(func(): return DialLoadoutMenu.build(contact_id))
		if ally_dial_card != null:
			content.add_child(ally_dial_card)
	for contact_id in Loadout.recruit_ids():
		content.add_child(_build_loadout_card(contact_id))


# Preparation's Change loadout route: only the participants' personal items and
# Dials; Back returns to the pending encounter.
func _build_prep_focus(content: VBoxContainer) -> void:
	content.add_child(UI.button("‹ Back", func(): CombatPrep.finish_loadout_edit()))
	content.add_child(UI.heading("Loadout"))
	for owner_id in CombatPrep.loadout_owner_ids(CombatPrep.pending()):
		content.add_child(_build_loadout_card(owner_id))
		var dial_card: Variant = MapPalette.build_light(func(): return DialLoadoutMenu.build(owner_id))
		if dial_card != null:
			content.add_child(dial_card)


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


func _build_loadout_card(contact_id: String = "") -> Control:
	var c := UI.card()
	c["content"].add_child(UI.heading("Loadout" if contact_id == "" else "%s — Loadout" % Contacts.display_name(contact_id), 14))
	var stock := Loadout.equippable_stock(contact_id)
	for index in Loadout.slot_count():
		var unit: Variant = Loadout.slot(index, contact_id)
		if unit == null:
			c["content"].add_child(UI.muted_label("Slot %d: empty" % (index + 1)))
			for entry in stock:
				c["content"].add_child(UI.button("Equip %s T%d%s (×%d)" % [GameData.RECIPES[entry["recipe"]]["name"], entry["tier"], " multi" if entry["multi"] else "", entry["qty"]], _on_equip.bind(index, entry["recipe"], entry["tier"], contact_id, entry["multi"])))
		else:
			c["content"].add_child(UI.label("Slot %d: %s T%d%s" % [index + 1, GameData.RECIPES[unit["recipe"]]["name"], int(unit["tier"]), " multi" if unit.get("multi", false) else ""]))
			c["content"].add_child(UI.button("Unequip slot %d" % (index + 1), _on_unequip.bind(index, contact_id)))
	return c["panel"]


func _on_equip(index: int, recipe_key: String, tier: int, contact_id: String, multi: bool) -> void:
	Loadout.equip(index, recipe_key, tier, contact_id, multi)


func _on_unequip(index: int, contact_id: String) -> void:
	Loadout.unequip(index, contact_id)


func _dial_summary_label(player: Dictionary) -> Control:
	var dial: Variant = player["dial"]
	if dial == null:
		return UI.muted_label("Dial: none")
	var movement: Variant = dial["movement"]
	if movement == null:
		return UI.label("Dial: Lv%d — no Movement seated (inert)" % dial["level"])
	var m: Dictionary = GameData.DIAL_MOVEMENTS[movement["archetype"]]
	return UI.symbol_row(["Dial: Lv%d — " % dial["level"], { "symbol": m["symbol"], "fallback": SymbolGlyph.generic_fallback() }, " %s, charge %d/%d" % [m["name"], int(dial["currentCharge"]), dial["maxCharge"]]])

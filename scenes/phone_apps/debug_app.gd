# Debug app (present only on a Debug Start save): cash/calc/site spawners,
# combat launchers, safe-area dump, contact and faction relation adjusters.
class_name DebugApp
extends PhoneApp


func build(content: VBoxContainer) -> void:
	content.add_child(back_button())
	content.add_child(UI.heading("Debug"))
	content.add_child(_build_add_money_card())
	content.add_child(_build_add_calc_card())
	content.add_child(_build_spawn_site_card())
	content.add_child(_build_combat_card())
	content.add_child(_build_combat_prototype_card())
	content.add_child(_build_safe_area_card())
	content.add_child(UI.heading("Contact relations", 14))
	for contact_id in GameData.CONTACTS_DEFAULTS.keys():
		content.add_child(_build_contact_relation_card(contact_id))
	content.add_child(UI.heading("Faction relations", 14))
	for faction_id in GameData.FACTIONS.keys():
		content.add_child(_build_faction_relation_card(faction_id))


func _build_add_money_card() -> Control:
	var c := UI.card()
	c["content"].add_child(UI.heading("Add money", 14))

	var amount_field := LineEdit.new()
	amount_field.placeholder_text = "Amount"
	c["content"].add_child(amount_field)

	c["content"].add_child(UI.button("Add", func():
		DebugTools.add_cash(amount_field.text.to_int())
	))

	return c["panel"]


func _build_add_calc_card() -> Control:
	var c := UI.card()
	c["content"].add_child(UI.heading("Add calc", 14))

	var ore_select := UI.option_button(GameData.ORE_TYPES.keys())
	c["content"].add_child(ore_select)

	var amount_field := LineEdit.new()
	amount_field.placeholder_text = "Amount"
	c["content"].add_child(amount_field)

	c["content"].add_child(UI.button("Add", func():
		var ore_type: String = ore_select.get_item_text(ore_select.selected)
		DebugTools.add_calc(ore_type, amount_field.text.to_int())
	))

	return c["panel"]


func _build_spawn_site_card() -> Control:
	var c := UI.card()
	c["content"].add_child(UI.heading("Spawn site", 14))

	var district_select := UI.option_button(GameData.DISTRICTS.keys())
	c["content"].add_child(district_select)

	var ore_select := UI.option_button(GameData.ORE_TYPES.keys())
	c["content"].add_child(ore_select)

	var terroir_select := UI.option_button(GameData.VEIN_GROWTH["terroirYieldMult"].keys())
	c["content"].add_child(terroir_select)

	c["content"].add_child(UI.button("Spawn", func():
		var district_id: String = district_select.get_item_text(district_select.selected)
		var ore_type: String = ore_select.get_item_text(ore_select.selected)
		var tier: String = terroir_select.get_item_text(terroir_select.selected)
		Sites.spawn_unclaimed_site(district_id, tier, ore_type)
	))

	return c["panel"]


func _build_combat_card() -> Control:
	var c := UI.card()
	c["content"].add_child(UI.heading("Combat", 14))
	c["content"].add_child(UI.button("Open", func(): Modal.open("combat_setup")))
	return c["panel"]


func _build_combat_prototype_card() -> Control:
	var c := UI.card()
	c["content"].add_child(UI.heading("Solo Combat Prototype", 14))
	c["content"].add_child(UI.muted_label("Bounded experiment (tickets 14/15) — not production combat."))
	c["content"].add_child(UI.button("Start Teaching Sequence", func():
		var order: Array = GameData.COMBAT_PROTOTYPE.get("encounterOrder", [])
		if not order.is_empty():
			CombatPrototype.start_encounter(order[0])
	))
	var encounters: Dictionary = GameData.COMBAT_PROTOTYPE.get("encounters", {})
	for encounter_id in CombatPrototype.list_launchable_encounters():
		c["content"].add_child(_build_combat_prototype_launch_button(encounter_id, encounters[encounter_id].get("name", encounter_id)))
	return c["panel"]


func _build_combat_prototype_launch_button(encounter_id: String, label: String) -> Control:
	return UI.button("Start: %s" % label, func(): CombatPrototype.start_encounter(encounter_id))


func _build_safe_area_card() -> Control:
	var c := UI.card()
	c["content"].add_child(UI.heading("Safe area", 14))

	var dump := UI.label(UI.safe_area_debug_text())
	dump.autowrap_mode = TextServer.AUTOWRAP_OFF
	c["content"].add_child(dump)

	c["content"].add_child(UI.button("Refresh", func():
		dump.text = UI.safe_area_debug_text()
	))

	return c["panel"]


func _build_contact_relation_card(contact_id: String) -> Control:
	var c := UI.card()
	var relation: int = GameState.state["contacts"][contact_id]["relation"]
	c["content"].add_child(UI.heading("%s (relation %d)" % [Contacts.display_name(contact_id), relation], 14))

	var delta_field := LineEdit.new()
	delta_field.placeholder_text = "Delta"
	c["content"].add_child(delta_field)

	c["content"].add_child(UI.button("Adjust", func():
		Contacts.award_relation(contact_id, delta_field.text.to_int())
	))

	return c["panel"]


func _build_faction_relation_card(faction_id: String) -> Control:
	var c := UI.card()
	var relation: int = GameState.state["factions"][faction_id]["relation"]
	var faction_name: String = GameData.FACTIONS[faction_id]["name"]
	c["content"].add_child(UI.heading("%s (relation %d)" % [faction_name, relation], 14))

	var delta_field := LineEdit.new()
	delta_field.placeholder_text = "Delta"
	c["content"].add_child(delta_field)

	c["content"].add_child(UI.button("Adjust", func():
		Factions.adjust_player_relation(faction_id, delta_field.text.to_int())
	))

	return c["panel"]

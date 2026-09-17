class_name CombatSetupModal
extends RefCounted


static func build(container: VBoxContainer, _data: Dictionary) -> void:
	container.add_child(UI.heading("Combat setup"))

	var template_options: Array = ["Random"]
	template_options.append_array(GameData.ENEMY_RAID_GUARDS.keys())
	container.add_child(UI.label("Enemy type"))
	var template_select := UI.option_button(template_options)
	container.add_child(template_select)

	var count_options: Array = []
	for i in range(1, Combat.SQUAD_MAX + 1):
		count_options.append(str(i))
	container.add_child(UI.label("Number of enemies"))
	var count_select := UI.option_button(count_options)
	container.add_child(count_select)

	var tier_options: Array = []
	for i in range(1, 7):
		tier_options.append(str(i))
	container.add_child(UI.label("Value tier"))
	var tier_select := UI.option_button(tier_options)
	container.add_child(tier_select)

	container.add_child(UI.label("Allies"))
	var selected_allies: Array = []
	var eligible_allies := false
	for contact_id in GameState.state["contacts"].keys():
		if not Contacts.can_join_combat(contact_id):
			continue
		eligible_allies = true
		container.add_child(_ally_row(contact_id, selected_allies))
	if not eligible_allies:
		container.add_child(UI.muted_label("No recruited contact is fit for a fight right now."))

	container.add_child(UI.button("Fight", func():
		var template_key: String = template_select.get_item_text(template_select.selected)
		if template_key == "Random":
			template_key = ""
		var count: int = count_select.get_item_text(count_select.selected).to_int()
		var value_tier: int = tier_select.get_item_text(tier_select.selected).to_int()
		Modal.close()
		Combat.start_raid("debug_combat_setup", value_tier, count, template_key, Combat.CONTEXT_RAID, selected_allies)
	))
	container.add_child(UI.button("Cancel", func(): Modal.close()))


static func _ally_row(contact_id: String, selected_allies: Array) -> Control:
	var row := UI.hbox(6)
	var toggle_btn: Button
	toggle_btn = UI.button("☐", func():
		if contact_id in selected_allies:
			selected_allies.erase(contact_id)
			toggle_btn.text = "☐"
		else:
			selected_allies.append(contact_id)
			toggle_btn.text = "☑"
	)
	row.add_child(toggle_btn)
	row.add_child(UI.label(Contacts.display_name(contact_id)))
	return row

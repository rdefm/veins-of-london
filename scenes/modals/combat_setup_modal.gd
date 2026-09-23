class_name CombatSetupModal
extends RefCounted

const LOCATION_AUTO := "Auto"


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

	var context_options: Array = []
	context_options.append_array(Combat.DEBUG_SETUP_CONTEXTS)
	container.add_child(UI.label("Fight type"))
	var context_select := UI.option_button(context_options)
	container.add_child(context_select)

	# "Auto" derives locationKey the normal way (R§2); anything else overrides
	# it so each backdrop tier can be previewed.
	var location_options: Array = [LOCATION_AUTO, Combat.HOME_LOCATION_KEY]
	location_options.append_array(GameData.DISTRICTS.keys())
	container.add_child(UI.label("Location (backdrop)"))
	var location_select := UI.option_button(location_options)
	container.add_child(location_select)

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
		var context: String = context_select.get_item_text(context_select.selected)
		var location_key: String = location_select.get_item_text(location_select.selected)
		if location_key == LOCATION_AUTO:
			location_key = ""
		Combat.start_debug_combat(context, location_key, value_tier, count, template_key, selected_allies)
	))
	container.add_child(UI.button("Cancel", func(): Modal.close()))


static func _ally_row(contact_id: String, selected_allies: Array) -> Control:
	var row := UI.hbox(6)
	# Connected after creation: a lambda captures locals by value, so one
	# built inside UI.button()'s own call would see toggle_btn as null.
	var toggle_btn := UI.button("☐", func(): pass)
	toggle_btn.pressed.connect(func():
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

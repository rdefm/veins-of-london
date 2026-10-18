class_name CombatSetupModal
extends RefCounted

const LOCATION_AUTO := "Auto"
const RANDOM := "Random"
# The player's own Combat Skill, and a template's own archetype.
const OWN := "Own"
# A loadout slot left as it is (the player's) or empty (a debug ally's).
const SLOT_KEEP := "keep"
const SLOT_EMPTY := "empty"


static func build(container: VBoxContainer, _data: Dictionary) -> void:
	container.add_child(UI.heading("Combat setup"))

	var context_options: Array = []
	context_options.append_array(Combat.DEBUG_SETUP_CONTEXTS)
	container.add_child(UI.label("Fight type"))
	var context_select := UI.option_button(context_options)
	container.add_child(context_select)

	container.add_child(UI.label("Location (backdrop)"))
	var location_select := UI.option_button(location_options())
	container.add_child(location_select)

	container.add_child(UI.label("Your Combat Skill"))
	var player_level_select := UI.option_button(["%s (%d)" % [OWN, int(GameState.state["player"]["combatSkill"])]] + _levels())
	container.add_child(player_level_select)

	container.add_child(UI.label("Your loadout"))
	var player_slots: Array = []
	for slot in range(Loadout.slot_count()):
		var row := _slot_row(slot, SLOT_KEEP, _item_ids(false))
		player_slots.append(row)
		container.add_child(row["row"])

	var count_options: Array = []
	for i in range(1, Combat.SQUAD_MAX + 1):
		count_options.append(str(i))
	container.add_child(UI.label("Number of enemies"))
	var count_select := UI.option_button(count_options)
	container.add_child(count_select)

	container.add_child(UI.label("Enemy level"))
	var enemy_level_select := UI.option_button(_levels())
	container.add_child(enemy_level_select)

	var templates: Array = Combat.debug_enemy_templates()
	var archetypes: Array = GameData.COMBAT_ROUNDS["archetypes"].keys()
	var enemy_rows: Array = []
	for i in range(Combat.SQUAD_MAX):
		var row := UI.hbox(6)
		var template_select := UI.option_button([RANDOM] + templates)
		var archetype_select := UI.option_button([OWN] + archetypes)
		row.add_child(template_select)
		row.add_child(archetype_select)
		row.visible = i == 0
		enemy_rows.append({ "row": row, "template": template_select, "archetype": archetype_select })
		container.add_child(row)
	count_select.item_selected.connect(func(index: int):
		for i in range(enemy_rows.size()):
			enemy_rows[i]["row"].visible = i <= index
	)

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

	var ally_counts: Array = []
	for n in range(CombatRounds.MAX_ALLIES + 1):
		ally_counts.append("%d debug all%s" % [n, "y" if n == 1 else "ies"])
	var ally_count_select := UI.option_button(ally_counts)
	container.add_child(ally_count_select)
	container.add_child(UI.label("Debug ally level"))
	var ally_level_select := UI.option_button(_levels())
	container.add_child(ally_level_select)
	var ally_boxes: Array = []
	var ally_slots: Array = []
	for i in range(CombatRounds.MAX_ALLIES):
		var box := UI.vbox(4)
		box.add_child(UI.muted_label("Debug ally %s loadout" % char(65 + i)))
		var slots: Array = []
		for slot in range(Loadout.slot_count()):
			var row := _slot_row(slot, SLOT_EMPTY, _item_ids(true))
			slots.append(row)
			box.add_child(row["row"])
		box.visible = false
		ally_boxes.append(box)
		ally_slots.append(slots)
		container.add_child(box)
	ally_count_select.item_selected.connect(func(index: int):
		for i in range(ally_boxes.size()):
			ally_boxes[i].visible = i < index
	)

	var fight := MapCardStyle.text_button("Fight", func():
		var enemy_level: int = enemy_level_select.selected + 1
		var enemies: Array = []
		for i in range(count_select.selected + 1):
			var row: Dictionary = enemy_rows[i]
			enemies.append({
				"template": "" if row["template"].selected == 0 else str(templates[row["template"].selected - 1]),
				"archetype": "" if row["archetype"].selected == 0 else str(archetypes[row["archetype"].selected - 1]),
				"level": enemy_level,
			})
		var allies: Array = []
		for i in range(ally_count_select.selected):
			var units: Array = ally_slots[i].map(func(r): return _picked_unit(r)).filter(func(u): return u != null)
			allies.append({ "level": ally_level_select.selected + 1, "slots": units })
		var location_key: String = location_select.get_item_text(location_select.selected)
		if location_key == LOCATION_AUTO:
			location_key = ""
		Modal.close()
		Loadout.debug_grant(player_slots.map(func(r): return _picked_unit(r)))
		CombatPrep.request(CombatPrep.KIND_DEBUG, {
			"context": context_select.get_item_text(context_select.selected), "locationKey": location_key,
			"playerLevel": player_level_select.selected, "enemies": enemies,
			"allyIds": selected_allies, "allies": allies,
		})
	)
	container.add_child(MapCardStyle.footer([MapCardStyle.text_button("Cancel", func(): Modal.close()), fight]))


# "Auto" derives locationKey the normal way (R§2); anything else overrides
# it so each backdrop tier can be previewed.
static func location_options() -> Array:
	var options: Array = [LOCATION_AUTO, Combat.HOME_LOCATION_KEY]
	options.append_array(GameData.DISTRICTS.keys())
	return options


static func _levels() -> Array:
	var levels: Array = []
	for level in range(1, CombatRounds.level_max() + 1):
		levels.append(str(level))
	return levels


# Round-fight items a slot can carry (an ally's less loadout.allyExcluded).
static func _item_ids(ally: bool) -> Array:
	return CombatRounds.item_ids().filter(func(id): return Loadout.is_equippable(id) and not (ally and GameData.LOADOUT["allyExcluded"].has(id)))


# Item and tier pickers for one slot: { row, item, tier, ids }; the tier
# list follows the picked item's effectPower curve. Item 0 is `none_text`.
static func _slot_row(slot: int, none_text: String, item_ids: Array) -> Dictionary:
	var row := UI.hbox(6)
	var names: Array = ["Slot %d: %s" % [slot + 1, none_text]]
	for id in item_ids:
		names.append("Slot %d: %s" % [slot + 1, CombatRounds.move(id)["name"]])
	var item_select := UI.option_button(names)
	var tier_select := UI.option_button([])
	tier_select.visible = false
	item_select.item_selected.connect(func(index: int):
		tier_select.clear()
		tier_select.visible = index > 0
		if index > 0:
			for tier in range(1, CombatRounds.item_tier_max(item_ids[index - 1]) + 1):
				tier_select.add_item("Tier %d" % tier)
	)
	row.add_child(item_select)
	row.add_child(tier_select)
	return { "row": row, "item": item_select, "tier": tier_select, "ids": item_ids }


# A slot row's pick as a { recipe, tier } unit, or null for keep/empty.
static func _picked_unit(slot_row: Dictionary) -> Variant:
	var index: int = slot_row["item"].selected
	if index <= 0:
		return null
	return { "recipe": str(slot_row["ids"][index - 1]), "tier": maxi(1, slot_row["tier"].selected + 1) }


static func _ally_row(contact_id: String, selected_allies: Array) -> Control:
	var row := UI.hbox(6)
	# Connected after creation: a lambda captures locals by value, so one
	# built inside text_button()'s own call would see toggle_btn as null.
	var toggle_btn := MapCardStyle.text_button("☐", func(): pass)
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

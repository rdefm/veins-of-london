# Debug app (present only on a Debug Start save): cash/calc/site spawners,
# combat launchers, safe-area dump, one relation adjuster over every contact
# and faction, and an any-event trigger.
class_name DebugApp
extends PhoneApp

# View state only: the relation and event dropdowns' selections, kept across rebuilds.
var _relation_target_index: int = 0
var _event_index: int = 0


func build(content: VBoxContainer) -> void:
	content.add_child(back_button())
	content.add_child(UI.heading("Debug"))
	content.add_child(_build_add_money_card())
	content.add_child(_build_add_calc_card())
	content.add_child(_build_spawn_site_card())
	content.add_child(_build_combat_card())
	content.add_child(_build_combat_prototype_card())
	content.add_child(_build_safe_area_card())
	content.add_child(_build_relation_card())
	content.add_child(_build_trigger_event_card())


func _build_trigger_event_card() -> Control:
	var c := UI.card()
	c["content"].add_child(UI.heading("Trigger event", 14))

	var event_ids := DebugTools.event_ids()
	var event_select := UI.option_button(event_ids)
	_event_index = clampi(_event_index, 0, event_ids.size() - 1)
	event_select.selected = _event_index
	event_select.item_selected.connect(func(index: int): _event_index = index)
	c["content"].add_child(event_select)

	c["content"].add_child(UI.button("Fire", func():
		_event_index = event_select.selected
		DebugTools.fire_event(event_ids[_event_index])
	))

	return c["panel"]


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


# Every contact then every faction, as {kind, id, label}; the dropdown's item
# index is the index into this list.
static func relation_targets() -> Array:
	var targets: Array = []
	for contact_id in GameData.CONTACTS_DEFAULTS.keys():
		targets.append({"kind": "contact", "id": contact_id,
			"label": "Contact: %s" % Contacts.display_name(contact_id)})
	for faction_id in GameData.FACTIONS.keys():
		targets.append({"kind": "faction", "id": faction_id,
			"label": "Faction: %s" % GameData.FACTIONS[faction_id]["name"]})
	return targets


static func _relation_of(target: Dictionary) -> int:
	var bucket: String = "contacts" if target["kind"] == "contact" else "factions"
	return GameState.state[bucket][target["id"]]["relation"]


func _build_relation_card() -> Control:
	var c := UI.card()
	c["content"].add_child(UI.heading("Relations", 14))

	var targets := relation_targets()
	var labels: Array = []
	for t in targets:
		labels.append(t["label"])
	var target_select := UI.option_button(labels)
	_relation_target_index = clampi(_relation_target_index, 0, targets.size() - 1)
	target_select.selected = _relation_target_index
	c["content"].add_child(target_select)

	var current := UI.label("Relation: %d" % _relation_of(targets[_relation_target_index]))
	c["content"].add_child(current)

	target_select.item_selected.connect(func(index: int):
		_relation_target_index = index
		current.text = "Relation: %d" % _relation_of(targets[index])
	)

	var delta_field := LineEdit.new()
	delta_field.placeholder_text = "Delta"
	c["content"].add_child(delta_field)

	c["content"].add_child(UI.button("Adjust", func():
		_relation_target_index = target_select.selected
		var target: Dictionary = targets[_relation_target_index]
		var delta := delta_field.text.to_int()
		if target["kind"] == "contact":
			Contacts.award_relation(target["id"], delta)
		else:
			Factions.adjust_player_relation(target["id"], delta)
		current.text = "Relation: %d" % _relation_of(target)
	))

	return c["panel"]

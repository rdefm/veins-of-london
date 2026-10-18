# Debug app (present only on a Debug Start save): cash/calc/site spawners,
# combat launchers, a Lab page (skill override, recipe/hint grants, best
# ranks, calc refill), safe-area dump, one relation adjuster over every
# contact and faction, and an any-event trigger.
class_name DebugApp
extends PhoneApp

const LAB_PAGE := "lab"

# View state only: the open sub-page ("" = the main page) and the relation
# and event dropdowns' selections, kept across rebuilds.
var _page: String = ""
var _relation_target_index: int = 0
var _event_index: int = 0


func card_chrome() -> bool:
	return true


func build(content: VBoxContainer) -> void:
	if _page == LAB_PAGE:
		_build_lab_page(content)
		return
	content.add_child(back_button())
	content.add_child(UI.heading("Debug"))
	content.add_child(_build_add_money_card())
	content.add_child(_build_add_calc_card())
	content.add_child(_build_spawn_site_card())
	content.add_child(_build_combat_card())
	content.add_child(_build_lab_card())
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


func _build_lab_card() -> Control:
	var c := UI.card()
	c["content"].add_child(UI.heading("Lab", 14))
	c["content"].add_child(UI.muted_label("Skill override, recipes, hints, best ranks, calc."))
	c["content"].add_child(UI.button("Open", func(): _open_page(LAB_PAGE)))
	return c["panel"]


func _open_page(page: String) -> void:
	_page = page
	refresh()


func _build_lab_page(content: VBoxContainer) -> void:
	content.add_child(UI.button("‹ Debug", func(): _open_page("")))
	content.add_child(UI.heading("Lab"))
	content.add_child(_build_lab_tools_card())
	for recipe_key in GameData.RECIPES.keys():
		if not Lab.procedure_def(recipe_key).is_empty():
			content.add_child(_build_lab_recipe_card(recipe_key))


# Skill override picker (entry 0 = the player's real skill, entry n + 1 =
# override n) and the calc refill.
func _build_lab_tools_card() -> Control:
	var c := UI.card()
	var real_skill := int(GameState.state["player"]["craftingSkill"])
	var items: Array = ["Skill: real (%d)" % real_skill]
	for skill in int(GameData.LAB["debug"]["skillMax"]) + 1:
		items.append("Skill: %d" % skill)
	var skill_select := UI.option_button(items)
	var override = GameState.state["lab"].get("skillOverride")
	skill_select.selected = 0 if override == null else int(override) + 1
	skill_select.item_selected.connect(func(index: int):
		if index == 0:
			Lab.clear_skill_override()
		else:
			Lab.set_skill_override(index - 1)
	)
	c["content"].add_child(skill_select)
	c["content"].add_child(UI.button("Refill calc", func(): Lab.refill_calc()))
	return c["panel"]


# One recipe: known toggle (grant/revoke), best-rank picker, and each hidden
# step's specificity with Vague/Exact grant buttons.
func _build_lab_recipe_card(recipe_key: String) -> Control:
	var c := UI.card()
	c["content"].add_child(UI.heading(String(GameData.RECIPES[recipe_key].get("name", recipe_key)), 14))

	var known := CheckBox.new()
	known.text = "Known"
	known.button_pressed = Lab.is_known(recipe_key)
	known.toggled.connect(func(on: bool):
		if on:
			Lab.grant_recipe(recipe_key)
		elif not Lab.revoke_recipe(recipe_key)["ok"]:
			refresh()
	)
	c["content"].add_child(known)

	var ranks: Array = ["Best rank: none"]
	for rank in range(1, GameData.LAB["rankThresholds"].size() + 1):
		ranks.append("Best rank: %d" % rank)
	var rank_select := UI.option_button(ranks)
	rank_select.selected = int(GameState.state["lab"]["bestRanks"].get(recipe_key, 0))
	rank_select.item_selected.connect(func(index: int): Lab.set_best_rank(recipe_key, index))
	c["content"].add_child(rank_select)

	if not Lab.is_known(recipe_key):
		return c["panel"]
	var order: Array = GameData.LAB["specificities"]
	for hint in Lab.procedure_def(recipe_key).get("hints", []):
		var step := int(hint["step"])
		var current := Lab.step_specificity(recipe_key, step)
		var row := UI.hbox()
		var text := UI.label("%s (%s): %s" % [hint["label"], hint["rung"], current if not current.is_empty() else "unknown"])
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(text)
		for specificity in order:
			var grant := UI.button(String(specificity).capitalize(), func(): Lab.grant_steps(recipe_key, [step], specificity))
			grant.disabled = order.find(current) >= order.find(specificity)
			row.add_child(grant)
		c["content"].add_child(row)
	return c["panel"]


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

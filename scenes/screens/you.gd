class_name YouScreen
extends Control

# M1-LONDON.md D4's You tab: "HP, skills & XP, equipment summary,
# save/load/export/settings." Merges the old M0 `stats` screen (HP,
# attack, skills, ops summary — previously unreachable from any nav path)
# and `save` screen (slots, export/import, new game) into one screen,
# plus a small read-only equipment summary D4 asks for that neither old
# screen had (equip/unequip itself stays on Bag, per D4: "Bag — full
# inventory management ... equipment (equip/unequip)").
# (reputation M2, affinities M3, Fieldcraft M2 land here later.)

var _content: VBoxContainer
var _export_box: TextEdit
var _import_box: TextEdit


func _ready() -> void:
	UI.anchor_full_rect(self)
	_content = UI.screen_body(self)
	EventBus.state_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	for child in _content.get_children():
		child.queue_free()

	_content.add_child(UI.back_button("home"))
	_content.add_child(UI.heading("You"))

	_content.add_child(_build_stats_card())
	_content.add_child(_build_skills_card())
	_content.add_child(_build_equipment_card())
	_content.add_child(_build_ops_card())

	_content.add_child(UI.heading("Save & Load", 16))
	for slot in range(1, 4):
		_content.add_child(_build_slot_row(slot))
	_content.add_child(_build_export_card())
	_content.add_child(_build_import_card())
	_content.add_child(UI.button("New Game", _on_new_game_pressed))


# ── stats / skills / equipment / ops ─────────────────────────────────

func _build_stats_card() -> Control:
	var player: Dictionary = GameState.state["player"]
	var atk := Combat.get_attack_range()

	var c := UI.card()
	c["content"].add_child(UI.label("HP: %d / %d" % [player["hp"], player["hpMax"]]))
	c["content"].add_child(UI.bar(player["hp"], player["hpMax"]))
	c["content"].add_child(UI.label("Attack: %d–%d" % [atk["min"], atk["max"]]))
	c["content"].add_child(UI.label("Cash: £%d" % player["cash"]))
	c["content"].add_child(UI.label("Day: %d" % GameState.state["world"]["day"]))
	return c["panel"]


func _build_skills_card() -> Control:
	var player: Dictionary = GameState.state["player"]
	var c := UI.card()
	c["content"].add_child(UI.heading("Skills", 14))
	c["content"].add_child(UI.label("Crafting: Lv%d (%d XP)" % [player["craftingSkill"], player["craftingXP"]]))
	c["content"].add_child(UI.label("Cultivating: Lv%d (%d XP)" % [player["cultivatingSkill"], player["cultivatingXP"]]))
	c["content"].add_child(UI.label("Stealth: Lv%d (%d XP)" % [player["stealthSkill"], player["stealthXP"]]))
	return c["panel"]


func _build_equipment_card() -> Control:
	var player: Dictionary = GameState.state["player"]
	var c := UI.card()
	c["content"].add_child(UI.heading("Equipment", 14))
	c["content"].add_child(_equipped_weapon_label(player))
	c["content"].add_child(_equipped_device_label(player))
	return c["panel"]


func _equipped_weapon_label(player: Dictionary) -> Control:
	var weapon_id = player["equipment"]["weapon"]
	for item in player["items"]:
		if item["id"] == weapon_id:
			var def: Dictionary = GameData.ITEMS.get(item["type"], {})
			return UI.label("%s %s (equipped)" % [def.get("symbol", ""), def.get("name", "")])
	return UI.muted_label("Weapon: none equipped")


func _equipped_device_label(player: Dictionary) -> Control:
	var device_id = player["equipment"]["device"]
	for device in player["devicesCompleted"]:
		if device["id"] == device_id:
			var dt: Dictionary = GameData.DEVICES[device["type"]]
			var charges_left: int = device["chargesPerDay"] - device["chargesUsedToday"]
			return UI.label("%s %s (equipped) — %d/%d charges" % [dt["symbol"], dt["name"], charges_left, device["chargesPerDay"]])
	return UI.muted_label("Device: none equipped")


func _build_ops_card() -> Control:
	var player: Dictionary = GameState.state["player"]
	var c := UI.card()
	c["content"].add_child(UI.heading("Operations", 14))
	c["content"].add_child(UI.label("Veins held: %d" % player["veins"].size()))
	for ore_type in GameData.ORE_TYPES.keys():
		var qty: int = player["orichalchum"].get(ore_type, 0)
		if qty > 0:
			c["content"].add_child(UI.label("%s %s: %d" % [GameData.ORE_TYPES[ore_type]["symbol"], ore_type.capitalize(), qty]))
	return c["panel"]


# ── save / load / export / import ────────────────────────────────────

func _build_slot_row(slot: int) -> Control:
	var summary := SaveManager.slot_summary(slot)
	var filled: bool = not summary.is_empty()

	var summary_text: String
	if filled:
		summary_text = "Day %d · £%d" % [summary["day"], summary["cash"]]
	else:
		summary_text = "Empty"

	var c := UI.card()
	c["content"].add_child(UI.heading("Slot %d" % slot, 14))
	c["content"].add_child(UI.muted_label(summary_text))

	var actions := UI.hbox()
	actions.add_child(UI.button("Save", _on_save_pressed.bind(slot)))
	if filled:
		actions.add_child(UI.button("Load", func(): SaveManager.load_from_slot(slot)))
		actions.add_child(UI.button("Delete", _on_delete_pressed.bind(slot)))
	c["content"].add_child(actions)

	return c["panel"]


# save_to_slot/delete_slot don't touch GameState.state, so they don't emit
# state_changed the way load_from_slot does — refresh explicitly so the
# slot list reflects what just happened.
func _on_save_pressed(slot: int) -> void:
	SaveManager.save_to_slot(slot)
	_refresh()


func _on_delete_pressed(slot: int) -> void:
	SaveManager.delete_slot(slot)
	_refresh()


func _build_export_card() -> Control:
	var c := UI.card()
	c["content"].add_child(UI.heading("Export", 14))
	_export_box = TextEdit.new()
	_export_box.custom_minimum_size = Vector2(0, 100)
	c["content"].add_child(_export_box)
	c["content"].add_child(UI.button("Generate export string", _on_export_pressed))
	return c["panel"]


func _on_export_pressed() -> void:
	_export_box.text = SaveManager.export_string()


func _build_import_card() -> Control:
	var c := UI.card()
	c["content"].add_child(UI.heading("Import", 14))
	_import_box = TextEdit.new()
	_import_box.custom_minimum_size = Vector2(0, 100)
	c["content"].add_child(_import_box)
	c["content"].add_child(UI.button("Import", _on_import_pressed))
	return c["panel"]


func _on_import_pressed() -> void:
	SaveManager.import_string(_import_box.text)


func _on_new_game_pressed() -> void:
	GameState.reset()
	Factions.seed_day_one_veins()
	Nav.go_to("intro")

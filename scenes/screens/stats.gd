class_name StatsScreen
extends Control

var _content: VBoxContainer


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_content = UI.screen_body(self)
	EventBus.state_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	for child in _content.get_children():
		child.queue_free()

	_content.add_child(UI.back_button("home"))
	_content.add_child(UI.heading("Stats"))

	var player: Dictionary = GameState.state["player"]
	var atk := Combat.get_attack_range()

	var main_card := UI.card()
	main_card["content"].add_child(UI.label("HP: %d / %d" % [player["hp"], player["hpMax"]]))
	main_card["content"].add_child(UI.bar(player["hp"], player["hpMax"]))
	main_card["content"].add_child(UI.label("Attack: %d–%d" % [atk["min"], atk["max"]]))
	main_card["content"].add_child(UI.label("Cash: £%d" % player["cash"]))
	main_card["content"].add_child(UI.label("Day: %d" % GameState.state["world"]["day"]))
	_content.add_child(main_card["panel"])

	var skills_card := UI.card()
	skills_card["content"].add_child(UI.heading("Skills", 14))
	skills_card["content"].add_child(UI.label("Crafting: Lv%d (%d XP)" % [player["craftingSkill"], player["craftingXP"]]))
	skills_card["content"].add_child(UI.label("Cultivating: Lv%d (%d XP)" % [player["cultivatingSkill"], player["cultivatingXP"]]))
	_content.add_child(skills_card["panel"])

	var ops_card := UI.card()
	ops_card["content"].add_child(UI.heading("Operations", 14))
	ops_card["content"].add_child(UI.label("Veins held: %d" % player["veins"].size()))
	for ore_type in GameData.ORE_TYPES.keys():
		var qty: int = player["orichalchum"].get(ore_type, 0)
		if qty > 0:
			ops_card["content"].add_child(UI.label("%s %s: %d" % [GameData.ORE_TYPES[ore_type]["symbol"], ore_type.capitalize(), qty]))
	_content.add_child(ops_card["panel"])

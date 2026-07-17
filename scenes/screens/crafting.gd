class_name CraftingScreen
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
	_content.add_child(UI.heading("Crafting"))

	_content.add_child(UI.heading("Recipes", 14))
	for recipe_key in GameData.RECIPES.keys():
		_content.add_child(_build_recipe_card(recipe_key))

	_content.add_child(UI.heading("Devices in progress", 14))
	var player: Dictionary = GameState.state["player"]
	if player["devicesInProgress"].is_empty():
		_content.add_child(UI.muted_label("No devices in progress."))
	else:
		for device in player["devicesInProgress"]:
			_content.add_child(_build_device_progress_card(device))

	_content.add_child(UI.heading("Start a new device", 14))
	var any_unlocked := false
	for device_key in GameData.DEVICES.keys():
		var dt: Dictionary = GameData.DEVICES[device_key]
		if not GameState.state["flags"].get(dt["unlockFlag"], false):
			continue
		any_unlocked = true
		_content.add_child(_build_device_start_row(device_key))
	if not any_unlocked:
		_content.add_child(UI.muted_label("No device types unlocked yet."))


func _build_recipe_card(recipe_key: String) -> Control:
	var player: Dictionary = GameState.state["player"]
	var skill: int = player["craftingSkill"]
	var r: Dictionary = GameData.RECIPES[recipe_key]
	var cost: int = Crafting.calc_cost(recipe_key, skill)
	var chance: float = Crafting.craft_chance(recipe_key, skill)
	var power = Crafting.effect_power(recipe_key, skill)
	var can_make: bool = Crafting.can_craft(recipe_key)
	var stock: int = player["inventory"].get(recipe_key, 0)
	var ingredient: String = r["ingredient"]
	var have: int = player["orichalchum"].get(ingredient, 0)
	var ore: Dictionary = GameData.ORE_TYPES[ingredient]

	var c := UI.card()
	c["content"].add_child(UI.heading("%s %s" % [r["symbol"], r["name"]], 15))
	c["content"].add_child(UI.label("Can craft" if can_make else "Missing calc"))
	c["content"].add_child(UI.muted_label(r["description"]))
	c["content"].add_child(UI.label("Ingredient: %s %s — %d/%d" % [ore["symbol"], ore["name"], have, cost]))
	c["content"].add_child(UI.label("Success: %d%%   Effect: %s   Stock: %d" % [int(round(chance * 100)), str(power), stock]))

	var b := UI.button("Craft one", func(): Crafting.attempt_craft(recipe_key))
	b.disabled = not can_make
	c["content"].add_child(b)

	return c["panel"]


func _build_device_progress_card(device: Dictionary) -> Control:
	var dt: Dictionary = GameData.DEVICES[device["type"]]
	var skill: int = GameState.state["player"]["craftingSkill"]
	var cost: int = Devices.get_device_calc_cost(device["type"], skill)
	var have: int = GameState.state["player"]["orichalchum"].get(dt["calcType"], 0)
	var can_attempt: bool = have >= cost
	var pct: int = int(round(device["progress"]))
	var device_id: String = device["id"]

	var c := UI.card()
	c["content"].add_child(UI.heading("%s %s — %d%%" % [dt["symbol"], dt["name"], pct], 15))
	c["content"].add_child(UI.bar(device["progress"], 100.0))
	c["content"].add_child(UI.label("Cost per attempt: %d %s   You have: %d" % [cost, GameData.ORE_TYPES[dt["calcType"]]["symbol"], have]))

	var actions := UI.hbox()
	var attempt_button := UI.button("Attempt", func(): Devices.attempt_device_build(device_id))
	attempt_button.disabled = not can_attempt
	actions.add_child(attempt_button)
	actions.add_child(UI.button("Abandon", func(): Devices.abandon_device(device_id)))
	c["content"].add_child(actions)

	return c["panel"]


func _build_device_start_row(device_key: String) -> Control:
	var dt: Dictionary = GameData.DEVICES[device_key]
	var skill: int = GameState.state["player"]["craftingSkill"]
	var cost: int = Devices.get_device_calc_cost(device_key, skill)
	var have: int = GameState.state["player"]["orichalchum"].get(dt["calcType"], 0)

	var c := UI.card()
	c["content"].add_child(UI.label("%s %s" % [dt["symbol"], dt["name"]]))
	c["content"].add_child(UI.muted_label("%d %s per attempt · have %d" % [cost, GameData.ORE_TYPES[dt["calcType"]]["name"], have]))
	var b := UI.button("Begin", func(): Devices.start_device(device_key))
	b.disabled = have < cost
	c["content"].add_child(b)

	return c["panel"]

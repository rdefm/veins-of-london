class_name InventoryScreen
extends Control

var _content: VBoxContainer


func _ready() -> void:
	UI.anchor_full_rect(self)
	_content = UI.screen_body(self)
	EventBus.state_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	for child in _content.get_children():
		child.queue_free()

	_content.add_child(UI.back_button("home"))
	_content.add_child(UI.heading("Inventory"))

	var tabs := UI.hbox()
	var current_tab: String = GameState.state["inventoryTab"]
	for tab_id in ["ore", "consumables", "equipment"]:
		var captured_tab: String = tab_id
		var b := UI.button(tab_id.capitalize(), func(): _set_tab(captured_tab))
		b.disabled = tab_id == current_tab
		tabs.add_child(b)
	_content.add_child(tabs)

	match current_tab:
		"consumables":
			_build_consumables_tab()
		"equipment":
			_build_equipment_tab()
		_:
			_build_ore_tab()


func _set_tab(tab_id: String) -> void:
	GameState.state["inventoryTab"] = tab_id
	EventBus.state_changed.emit()


func _build_ore_tab() -> void:
	var player: Dictionary = GameState.state["player"]
	var any_ore := false
	for ore_type in GameData.ORE_TYPES.keys():
		var qty: int = player["orichalchum"].get(ore_type, 0)
		if qty <= 0:
			continue
		any_ore = true
		var ore: Dictionary = GameData.ORE_TYPES[ore_type]
		var c := UI.card()
		c["content"].add_child(UI.label("%s %s — %d" % [ore["symbol"], ore["name"], qty]))
		c["content"].add_child(UI.muted_label(ore["flavorText"]))
		_content.add_child(c["panel"])
	if not any_ore:
		_content.add_child(UI.muted_label("No orichalchum in stock. Get searching."))


func _build_consumables_tab() -> void:
	var inventory: Dictionary = GameState.state["player"]["inventory"]
	var skill: int = GameState.state["player"]["craftingSkill"]
	var any_item := false
	for recipe_key in ["timePearl", "enhancementPowder", "rewind"]:
		var qty: int = inventory.get(recipe_key, 0)
		if qty <= 0:
			continue
		any_item = true
		var recipe: Dictionary = GameData.RECIPES[recipe_key]
		var power = Crafting.effect_power(recipe_key, skill)
		var c := UI.card()
		c["content"].add_child(UI.label("%s %s ×%d" % [recipe["symbol"], recipe["name"], qty]))
		c["content"].add_child(UI.muted_label(recipe["description"]))
		c["content"].add_child(UI.muted_label("Effect power at Lv%d: %s" % [skill, str(power)]))
		_content.add_child(c["panel"])
	if not any_item:
		_content.add_child(UI.muted_label("No consumables. Craft some to get started."))


func _build_equipment_tab() -> void:
	var player: Dictionary = GameState.state["player"]

	_content.add_child(UI.heading("Weapon", 14))
	if player["items"].is_empty():
		_content.add_child(UI.muted_label("No weapons yet."))
	else:
		for item in player["items"]:
			var def: Dictionary = GameData.ITEMS.get(item["type"], {})
			if def.is_empty():
				continue
			var is_equipped: bool = player["equipment"]["weapon"] == item["id"]
			var item_id: String = item["id"]
			var c := UI.card()
			c["content"].add_child(UI.label("%s %s%s" % [def["symbol"], def["name"], " (equipped)" if is_equipped else ""]))
			c["content"].add_child(UI.muted_label(def["description"]))
			c["content"].add_child(UI.muted_label("+%d–%d attack" % [def["attackBonus"]["min"], def["attackBonus"]["max"]]))
			if is_equipped:
				c["content"].add_child(UI.button("Unequip", func(): Equipment.unequip_weapon()))
			else:
				c["content"].add_child(UI.button("Equip", func(): Equipment.equip_weapon(item_id)))
			_content.add_child(c["panel"])

	_content.add_child(UI.heading("Device", 14))
	var equipped_device_id = player["equipment"]["device"]
	var equipped_device = null
	for d in player["devicesCompleted"]:
		if d["id"] == equipped_device_id:
			equipped_device = d
			break

	if equipped_device != null:
		var dt: Dictionary = GameData.DEVICES[equipped_device["type"]]
		var c := UI.card()
		c["content"].add_child(UI.label("%s %s (equipped) — Lv%d" % [dt["symbol"], dt["name"], equipped_device["level"]]))
		c["content"].add_child(UI.muted_label("%d/%d charges today" % [equipped_device["chargesPerDay"] - equipped_device["chargesUsedToday"], equipped_device["chargesPerDay"]]))
		c["content"].add_child(UI.button("Unequip", func(): Devices.unequip_device()))
		_content.add_child(c["panel"])
	else:
		_content.add_child(UI.muted_label("No device equipped."))

	for d in player["devicesCompleted"]:
		if d["id"] == equipped_device_id:
			continue
		var dt: Dictionary = GameData.DEVICES[d["type"]]
		var device_id: String = d["id"]
		var c := UI.card()
		c["content"].add_child(UI.label("%s %s — Lv%d" % [dt["symbol"], dt["name"], d["level"]]))
		c["content"].add_child(UI.button("Equip", func(): Devices.equip_device(device_id)))
		_content.add_child(c["panel"])

	if not player["devicesInProgress"].is_empty():
		_content.add_child(UI.heading("Devices in progress", 14))
		for d in player["devicesInProgress"]:
			var dt: Dictionary = GameData.DEVICES[d["type"]]
			var device_id: String = d["id"]
			var c := UI.card()
			c["content"].add_child(UI.label("%s %s — %d%%" % [dt["symbol"], dt["name"], int(d["progress"])]))
			c["content"].add_child(UI.bar(d["progress"], 100.0))
			var actions := UI.hbox()
			actions.add_child(UI.button("Build attempt", func(): Devices.attempt_device_build(device_id)))
			actions.add_child(UI.button("Abandon", func(): Devices.abandon_device(device_id)))
			c["content"].add_child(actions)
			_content.add_child(c["panel"])

	_content.add_child(UI.heading("Start a new device", 14))
	var start_row := UI.hbox()
	for device_key in GameData.DEVICES.keys():
		var dt: Dictionary = GameData.DEVICES[device_key]
		var captured_key: String = device_key
		start_row.add_child(UI.button("%s %s" % [dt["symbol"], dt["name"]], func(): Devices.start_device(captured_key)))
	_content.add_child(start_row)

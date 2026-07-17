class_name PropertyScreen
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

	_content.add_child(UI.back_button("world"))

	if not GameState.state["flags"]["homeUnlocked"]:
		_content.add_child(UI.heading("Locked"))
		_content.add_child(UI.muted_label("Property upgrades unlock as you progress. Keep sourcing. Keep your head down."))
		return

	var home: Dictionary = GameState.state["home"]
	var tier: Dictionary = GameData.HOME_TIERS[home["tier"]]
	var raid_pct: int = int(round(Home.get_home_raid_chance() * 100))

	_content.add_child(UI.heading(tier["name"]))
	_content.add_child(UI.muted_label("Raid risk: %d%% · %d/%d security slots · %d/%d room slots" % [raid_pct, home["security"].size(), tier["maxSecuritySlots"], home["rooms"].size(), tier["maxRooms"]]))
	_content.add_child(UI.label(tier["description"]))
	_content.add_child(UI.muted_label("Daily cost: £%d · Tier %d/6" % [tier["dailyCost"], tier["tier"]]))

	_content.add_child(_build_upgrade_card())
	_content.add_child(UI.heading("Security (%d/%d)" % [home["security"].size(), tier["maxSecuritySlots"]], 14))
	for security_id in GameData.HOME_SECURITY.keys():
		_content.add_child(_build_security_row(security_id))
	_content.add_child(UI.heading("Rooms (%d/%d)" % [home["rooms"].size(), tier["maxRooms"]], 14))
	for room_id in GameData.HOME_ROOMS.keys():
		_content.add_child(_build_room_row(room_id))


func _build_upgrade_card() -> Control:
	var home: Dictionary = GameState.state["home"]
	var order: Array = GameData.HOME_TIER_ORDER
	var current_index: int = order.find(home["tier"])

	var c := UI.card()
	if current_index >= order.size() - 1:
		c["content"].add_child(UI.muted_label("Maximum tier reached."))
		return c["panel"]

	var next_id: String = order[current_index + 1]
	var next_tier: Dictionary = GameData.HOME_TIERS[next_id]
	c["content"].add_child(UI.heading("Upgrade → %s" % next_tier["name"], 14))
	c["content"].add_child(UI.muted_label(next_tier["description"]))
	var b := UI.button("£%d" % next_tier["upgradeCost"], func(): Home.upgrade_tier())
	b.disabled = GameState.state["player"]["cash"] < next_tier["upgradeCost"]
	c["content"].add_child(b)
	return c["panel"]


func _build_security_row(security_id: String) -> Control:
	var home: Dictionary = GameState.state["home"]
	var tier: Dictionary = GameData.HOME_TIERS[home["tier"]]
	var sec: Dictionary = GameData.HOME_SECURITY[security_id]
	var installed: bool = home["security"].has(security_id)
	var full: bool = home["security"].size() >= tier["maxSecuritySlots"] and not installed

	var discount: float = 0.7 if GameState.state["flags"]["securityContactUnlocked"] else 1.0
	var adj_cost: int = GameState.round_epsilon(sec["cost"] * discount)

	var c := UI.card()
	c["content"].add_child(UI.label(("✅ " if installed else "") + sec["name"]))
	c["content"].add_child(UI.muted_label(sec["description"]))

	if installed:
		c["content"].add_child(UI.muted_label("Installed"))
	elif full:
		c["content"].add_child(UI.muted_label("Slots full"))
	else:
		var b := UI.button("£%d" % adj_cost, func(): Home.add_security(security_id))
		b.disabled = GameState.state["player"]["cash"] < adj_cost
		c["content"].add_child(b)

	return c["panel"]


func _build_room_row(room_id: String) -> Control:
	var home: Dictionary = GameState.state["home"]
	var tier: Dictionary = GameData.HOME_TIERS[home["tier"]]
	var room: Dictionary = GameData.HOME_ROOMS[room_id]
	var installed: bool = home["rooms"].has(room_id)
	var order: Array = GameData.HOME_TIER_ORDER
	var available: bool = order.find(home["tier"]) >= order.find(room["minTier"])
	var full: bool = home["rooms"].size() >= tier["maxRooms"] and not installed

	var c := UI.card()
	var prefix := "✅ " if installed else ("🔒 " if not available else "")
	c["content"].add_child(UI.label(prefix + room["name"]))
	var desc: String = room["description"]
	if not available:
		desc += " Requires %s." % GameData.HOME_TIERS[room["minTier"]]["name"]
	c["content"].add_child(UI.muted_label(desc))

	if installed:
		c["content"].add_child(UI.muted_label("Installed"))
	elif not available:
		c["content"].add_child(UI.muted_label("Locked"))
	elif full:
		c["content"].add_child(UI.muted_label("No room"))
	else:
		var b := UI.button("£%d" % room["cost"], func(): Home.add_room(room_id))
		b.disabled = GameState.state["player"]["cash"] < room["cost"]
		c["content"].add_child(b)

	return c["panel"]

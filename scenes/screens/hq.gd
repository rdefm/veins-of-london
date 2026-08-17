class_name HqScreen
extends Control

# M1-LONDON D4's HQ tab: "the property AS the interface." Merges the old
# M0 property screen (tier/security/rooms/stored ore) and crafting screen
# (recipes/devices, now called the workbench) into one screen, plus new
# assigned-contact UI for the lab/veinStation rooms that never had any UI
# before (systems/contacts.gd's assign_to_room was previously unreachable).

const WORKBENCH_ROOMS := ["workshop", "library", "lab"]
const ASSIGNABLE_ROOMS := ["lab", "veinStation"]

var _content: VBoxContainer


func _ready() -> void:
	UI.anchor_full_rect(self)

	# 11-phone-os-shell-06: mirrors home.gd's _ready() check — checked once
	# per visit, before building the normal HQ UI or connecting _refresh,
	# since starting the event navigates away and this node is about to be
	# freed by Main.gd's screen swap.
	var flags: Dictionary = GameState.state["flags"]
	if flags["homeRaidEventPending"] and not flags["homeRaidEventSeen"]:
		Events.start_event("home_raid_intro")
		return

	_content = UI.screen_body(self)
	EventBus.state_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	for child in _content.get_children():
		child.queue_free()

	_content.add_child(UI.back_to_home_button())
	_content.add_child(_build_actions_card())

	if not GameState.state["flags"]["homeUnlocked"]:
		_content.add_child(UI.heading("Locked"))
		_content.add_child(UI.muted_label("HQ unlocks as you progress. Keep sourcing. Keep your head down."))
		return

	var home: Dictionary = GameState.state["home"]
	var tier: Dictionary = GameData.HOME_TIERS[home["tier"]]
	var raid_pct: int = int(round(Home.get_home_raid_chance() * 100))

	_content.add_child(UI.heading(tier["name"]))
	_content.add_child(UI.muted_label("Raid risk: %d%% · %d/%d security installed · %d/%d room slots" % [raid_pct, home["security"].size(), GameData.HOME_SECURITY.size(), home["rooms"].size(), tier["maxRooms"]]))
	_content.add_child(UI.label(tier["description"]))
	_content.add_child(UI.muted_label("Daily cost: £%d · Tier %d/6" % [tier["dailyCost"], tier["tier"]]))

	_content.add_child(_build_upgrade_card())
	_content.add_child(_build_stored_ore_card())

	_content.add_child(UI.heading("Security (%d/%d)" % [home["security"].size(), GameData.HOME_SECURITY.size()], 14))
	for security_id in GameData.HOME_SECURITY.keys():
		_content.add_child(_build_security_row(security_id))

	_content.add_child(UI.heading("Rooms (%d/%d)" % [home["rooms"].size(), tier["maxRooms"]], 14))
	for room_id in GameData.HOME_ROOMS.keys():
		_content.add_child(_build_room_row(room_id))

	_content.add_child(_build_gym_card())
	_content.add_child(_build_lab_card())

	_content.add_child(_build_workbench_card())
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


# Rendered even while HQ is otherwise locked (see _refresh() below) — Rest
# must always be reachable here, never gated behind homeUnlocked.
func _build_actions_card() -> Control:
	var c := UI.card()
	c["content"].add_child(UI.heading("Actions", 14))
	c["content"].add_child(UI.button("Rest", _on_rest_pressed))
	return c["panel"]


func _on_rest_pressed() -> void:
	TimeSystem.do_rest()


# ── property: tier upgrade / stored ore / security / rooms ──────────

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


# M1-LONDON-T06: home.storedOre was merged into player.orichalchum (see
# systems/home.gd) — carried ore is what a raid actually risks, so this
# card shows the same ore the Bag tab shows, framed as what's at stake.
func _build_stored_ore_card() -> Control:
	var player: Dictionary = GameState.state["player"]
	var c := UI.card()
	c["content"].add_child(UI.heading("Stored ore", 14))
	var any_ore := false
	for ore_type in GameData.ORE_TYPES.keys():
		var qty: int = player["orichalchum"].get(ore_type, 0)
		if qty <= 0:
			continue
		any_ore = true
		var ore: Dictionary = GameData.ORE_TYPES[ore_type]
		c["content"].add_child(UI.label("%s %s — %d" % [ore["symbol"], ore["name"], qty]))
	if not any_ore:
		c["content"].add_child(UI.muted_label("None in stock."))
	# PROSE-REVIEW: new flavour text, tone bible per docs/CONTENT-GUIDE.md.
	c["content"].add_child(UI.muted_label("Ore kept at the flat is what a raid takes — carry less, lose less."))
	return c["panel"]


func _build_security_row(security_id: String) -> Control:
	var home: Dictionary = GameState.state["home"]
	var sec: Dictionary = GameData.HOME_SECURITY[security_id]
	var installed: bool = home["security"].has(security_id)
	var order: Array = GameData.HOME_TIER_ORDER
	var available: bool = order.find(home["tier"]) >= order.find(sec["minTier"])

	var discount: float = 0.7 if GameState.state["flags"]["securityContactUnlocked"] else 1.0
	var adj_cost: int = GameState.round_epsilon(sec["cost"] * discount)

	var c := UI.card()
	var prefix := "✅ " if installed else ("🔒 " if not available else "")
	c["content"].add_child(UI.label(prefix + sec["name"]))
	var desc: String = sec["description"]
	if not available:
		desc += " Requires %s." % GameData.HOME_TIERS[sec["minTier"]]["name"]
	c["content"].add_child(UI.muted_label(desc))

	if installed:
		c["content"].add_child(UI.muted_label("Installed"))
	elif not available:
		c["content"].add_child(UI.muted_label("Locked"))
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
		if ASSIGNABLE_ROOMS.has(room_id):
			c["content"].add_child(_build_room_contact_row(room_id))
	elif not available:
		c["content"].add_child(UI.muted_label("Locked"))
	elif full:
		c["content"].add_child(UI.muted_label("No room"))
	else:
		var b := UI.button("£%d" % room["cost"], func(): Home.add_room(room_id))
		b.disabled = GameState.state["player"]["cash"] < room["cost"]
		c["content"].add_child(b)

	return c["panel"]


# R§3.10: lab/veinStation each run daily processing for whichever recruited
# contact is assigned to them (Contacts.assign_to_room). One contact per
# room; assigning a contact elsewhere vacates their old room automatically.
func _build_room_contact_row(room_id: String) -> Control:
	var contacts: Dictionary = GameState.state["contacts"]
	var assigned_id: Variant = Contacts.get_contact_in_room(room_id)

	var box := UI.vbox(4)
	var assigned_text: String = "Assigned: %s" % Contacts.display_name(assigned_id) if assigned_id != null else "Assigned: no one"
	box.add_child(UI.muted_label(assigned_text))

	var row := UI.hbox()
	for contact_id in contacts.keys():
		var c: Dictionary = contacts[contact_id]
		if not c["recruited"] or c["assignedRoom"] == room_id:
			continue
		var captured_id: String = contact_id
		row.add_child(UI.button("Assign %s" % Contacts.display_name(contact_id), func(): Contacts.assign_to_room(captured_id, room_id)))
	if assigned_id != null:
		row.add_child(UI.button("Unassign", func(): Contacts.assign_to_room("none", room_id)))
	if row.get_child_count() > 0:
		box.add_child(row)

	return box


# ── workbench / gym ───────────────────────────────────────────────────

func _build_workbench_card() -> Control:
	var home: Dictionary = GameState.state["home"]
	var installed: Array[String] = []
	for room_id in WORKBENCH_ROOMS:
		if home["rooms"].has(room_id):
			installed.append(GameData.HOME_ROOMS[room_id]["name"])

	var c := UI.card()
	c["content"].add_child(UI.heading("Workbench", 16))
	c["content"].add_child(UI.muted_label(_workbench_flavor_text(installed.size())))
	if not installed.is_empty():
		c["content"].add_child(UI.muted_label("Fitted with: %s" % ", ".join(installed)))
	var bonus: float = Home.get_workshop_bonus()
	c["content"].add_child(UI.label("Crafting success bonus: +%d%%" % int(round(bonus * 100))))
	return c["panel"]


# PROSE-REVIEW: new flavour text, tone bible per docs/CONTENT-GUIDE.md.
func _workbench_flavor_text(room_count: int) -> String:
	match room_count:
		0:
			return "A table, a vice, and whatever's left over from last time. It works. Barely."
		1:
			return "Proper tools now. Recipes go smoother."
		2:
			return "Workshop and library both stocked — clean space, sharper results."
		_:
			return "A professional setup, top to bottom. This is as good as crafting gets."


# PROSE-REVIEW: new flavour text, tone bible per docs/CONTENT-GUIDE.md.
func _build_gym_card() -> Control:
	var home: Dictionary = GameState.state["home"]
	var c := UI.card()
	c["content"].add_child(UI.heading("Gym", 14))
	if home["rooms"].has("homeGym"):
		c["content"].add_child(UI.muted_label("Home Gym built. Training programmes arrive in a future update."))
	else:
		c["content"].add_child(UI.muted_label("Build a Home Gym to claim this space. Training programmes arrive in a future update."))
	return c["panel"]


# PROSE-REVIEW: new flavour text, tone bible per docs/CONTENT-GUIDE.md.
# calc-discovery ticket 06: third HQ card, in-fiction-named "The Lab",
# alongside the workbench and gym cards above. Opens the dedicated "lab"
# screen (state.benchNav-driven, scenes/screens/lab.gd) via BenchNav.go_home()
# + Nav.go_to("lab") so the Lab always opens on its home view, regardless
# of whatever sub-view the player last left it on.
func _build_lab_card() -> Control:
	var c := UI.card()
	c["content"].add_child(UI.heading("The Lab", 14))
	c["content"].add_child(UI.muted_label("Combine calc and technique, see what's underneath. Ore's spent either way."))
	c["content"].add_child(UI.button("Open", func():
		BenchNav.go_home()
		Nav.go_to("lab")
	))
	return c["panel"]


# ── crafting: recipes / devices ──────────────────────────────────────

func _build_recipe_card(recipe_key: String) -> Control:
	var player: Dictionary = GameState.state["player"]
	var skill: int = player["craftingSkill"]
	var r: Dictionary = GameData.RECIPES[recipe_key]
	var costs: Dictionary = Crafting.calc_cost(recipe_key, skill)
	var chance: float = Crafting.craft_chance(recipe_key, skill)
	var power = Crafting.effect_power(recipe_key, skill)
	var can_make: bool = Crafting.can_craft(recipe_key)
	var stock: int = player["inventory"].get(recipe_key, 0)

	var c := UI.card()
	c["content"].add_child(UI.heading("%s %s" % [r["symbol"], r["name"]], 15))
	c["content"].add_child(UI.label("Can craft" if can_make else "Missing calc"))
	c["content"].add_child(UI.muted_label(r["description"]))
	for ingredient in costs:
		var have: int = player["orichalchum"].get(ingredient, 0)
		var ore: Dictionary = GameData.ORE_TYPES[ingredient]
		c["content"].add_child(UI.label("Ingredient: %s %s — %d/%d" % [ore["symbol"], ore["name"], have, costs[ingredient]]))
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

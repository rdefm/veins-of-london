class_name HqScreen
extends Control

# M1-LONDON D4's HQ tab: "the property AS the interface." Merges the old
# M0 property screen (tier/security/rooms/stored ore) and crafting screen
# (devices only — bugfixes ticket 25 moved recipes/workbench out to the
# Lab screen's Crafting section) into one screen, plus new assigned-contact
# UI for the lab/veinStation rooms that never had any UI before
# (systems/contacts.gd's assign_to_room was previously unreachable).

const ASSIGNABLE_ROOMS := ["lab", "veinStation"]

var _content: VBoxContainer

# Bugfixes ticket 24: Rooms/Security are collapsible now (UI.collapsible_section),
# collapsed by default so they don't compete with the actionable cards above
# them. _refresh() rebuilds _content from scratch on every EventBus.state_changed,
# so the section nodes themselves can't remember their own expand state --
# these instance vars are what actually persists it across a refresh.
var _security_expanded: bool = false
var _rooms_expanded: bool = false


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

	# Actionable first — bugfixes ticket 24: Lab/workbench/recipes/devices
	# are what a player actually taps on a normal visit; the passive
	# property lists (Security/Rooms) below used to sit above them and push
	# them off-screen. Bugfixes ticket 25: Workbench/Recipes moved out to
	# the Lab screen's own Crafting section — the Lab card below is now the
	# only entry point for both crafting and experimenting.
	_content.add_child(_build_lab_card())

	_content.add_child(UI.heading("The Dial", 14))
	_content.add_child(_build_dial_card())

	# Property — passive reference info, collapsible and pushed below the
	# actionable cards above.
	_content.add_child(_build_upgrade_card())
	_content.add_child(_build_stored_ore_card())
	_content.add_child(_build_security_section())
	_content.add_child(_build_rooms_section())
	_content.add_child(_build_gym_card())


# Rendered even while HQ is otherwise locked (see _refresh() below) — Rest
# must always be reachable here, never gated behind homeUnlocked.
func _build_actions_card() -> Control:
	var c := UI.card()
	c["content"].add_child(UI.heading("Actions", 14))
	c["content"].add_child(UI.button("Rest", _on_rest_pressed))
	# 106-hq-raid-alarm-defend-flow: the HQ-screen equivalent of the
	# raid-warning notification's own Defend button (phone.gd's
	# _build_notification_row()) -- same trigger_defend() call, just reached
	# from wherever the player already is instead of the Notifications app.
	if Home.has_pending_raid():
		c["content"].add_child(UI.button("Defend", func(): Home.trigger_defend()))
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


# Bugfixes ticket 24: Rooms/Security were bare UI.heading() + flat row loops
# straight into _content; both now go through this shared collapsible-list
# shape (UI.collapsible_section() + one row per id) so the passive,
# reference-only lists don't compete for screen space with the actionable
# cards above them. `expanded`/`on_toggle` are what let a caller's own
# instance var (_security_expanded / _rooms_expanded, declared up top)
# survive the _refresh() rebuild, since the section node itself can't.
func _build_collapsible_list_section(title_prefix: String, count: int, total: int, expanded: bool, on_toggle: Callable, ids: Array, row_builder: Callable) -> Control:
	var title := "%s (%d/%d)" % [title_prefix, count, total]
	var section := UI.collapsible_section(title, expanded, on_toggle)
	for id in ids:
		section["content"].add_child(row_builder.call(id))
	return section["panel"]


func _build_security_section() -> Control:
	var home: Dictionary = GameState.state["home"]
	return _build_collapsible_list_section("Security", home["security"].size(), GameData.HOME_SECURITY.size(), _security_expanded, func(v): _security_expanded = v, GameData.HOME_SECURITY.keys(), _build_security_row)


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


func _build_rooms_section() -> Control:
	var home: Dictionary = GameState.state["home"]
	var tier: Dictionary = GameData.HOME_TIERS[home["tier"]]
	return _build_collapsible_list_section("Rooms", home["rooms"].size(), tier["maxRooms"], _rooms_expanded, func(v): _rooms_expanded = v, GameData.HOME_ROOMS.keys(), _build_room_row)


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
		if room_id == "veinStation":
			c["content"].add_child(_build_vein_station_list_row())
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


# vein-growth-state ticket 09 (spec §6.2): HQ's own entry point into the vein
# list, unfiltered -- the district bubble's "List view" (systems/
# district_bubble.gd's LIST_ID) is the other. VeinListNav.open_all() sets
# state.veinListNav.originScreen to "hq" so the list's Back button returns
# here rather than the Map tab.
func _build_vein_station_list_row() -> Control:
	return UI.button("View all veins", func():
		VeinListNav.open_all()
		Nav.go_to("vein_list")
	)


# ── gym ─────────────────────────────────────────────────────────────

# PROSE-REVIEW: new flavour text, tone bible per docs/CONTENT-GUIDE.md.
# squad-combat ticket 05: Train is the Home Gym's repeatable action --
# unrelated to (and doesn't replace) the room's own one-time +10 hpMax build
# bonus (Home.add_room()), which fires the moment the room is bought.
func _build_gym_card() -> Control:
	var player: Dictionary = GameState.state["player"]
	var c := UI.card()
	c["content"].add_child(UI.heading("Gym", 14))
	if Combat.can_train():
		c["content"].add_child(UI.label("Combat Skill: Lv%d (%d XP)" % [player["combatSkill"], player["combatXP"]]))
		var b := UI.button("Train", func(): Combat.train())
		b.disabled = TimeSystem.is_time_exhausted()
		c["content"].add_child(b)
	else:
		c["content"].add_child(UI.muted_label("Build a Home Gym to claim this space and unlock Train."))
	return c["panel"]


# PROSE-REVIEW: new flavour text, tone bible per docs/CONTENT-GUIDE.md.
# calc-discovery ticket 06: third HQ card, in-fiction-named "The Lab",
# alongside the gym card above. Bugfixes ticket 25: this is now the single
# entry point for both crafting (moved out of HQ) and experimenting — opens
# the dedicated "lab" screen (state.benchNav-driven, scenes/screens/lab.gd)
# via BenchNav.go_home() + Nav.go_to("lab"), unchanged from before ticket 25:
# the Lab still always opens on Experimenting's home view (its longstanding
# default); Crafting is one tap away via the new section tab.
func _build_lab_card() -> Control:
	var c := UI.card()
	c["content"].add_child(UI.heading("The Lab", 14))
	c["content"].add_child(UI.muted_label("Craft what you know, or combine calc and technique to see what's underneath. Ore's spent either way."))
	c["content"].add_child(UI.button("Open", func():
		BenchNav.go_home()
		Nav.go_to("lab")
	))
	return c["panel"]


# ── the Dial (dial-device ticket 07 — replaces the old devices section) ──
#
# Seeding and Movement-crafting live here, HQ's "build" role for the old
# devices section; seating/unseating a Movement, loading/unloading
# Complications, and winding are equip-style actions and live in
# bag_drawer.gd's management mode instead, matching how weapon equip has
# always lived there rather than in HQ.

func _build_dial_card() -> Control:
	var player: Dictionary = GameState.state["player"]
	var dial: Variant = player["dial"]
	var c := UI.card()

	if dial == null:
		# PROSE-REVIEW: new Dial-seeding copy below, drafted against
		# CONTENT-GUIDE.md's tone bible -- undrafted-by-a-human, same status
		# as the haft display names (§1.4).
		if GameState.state["flags"].get("dialGiftGranted", false):
			c["content"].add_child(UI.label("You've been given something rare. It wants a name."))
			c["content"].add_child(UI.muted_label(UI.format_cost_label(GameData.DIAL_SEED_COST, player["orichalchum"])))
			for haft_id in GameData.DIAL_HAFTS.keys():
				var haft: Dictionary = GameData.DIAL_HAFTS[haft_id]
				var captured_haft_id: String = haft_id
				c["content"].add_child(UI.button("Seed as \"%s\"" % haft["name"], func(): _on_seed_pressed(captured_haft_id)))
		else:
			c["content"].add_child(UI.muted_label("No Dial. Nothing's offered you the gift yet."))
		return c["panel"]

	var haft_name: String = Dial.haft_name(dial)
	c["content"].add_child(UI.heading("Level %d Dial — %s" % [dial["level"], haft_name], 15))
	c["content"].add_child(UI.label("Charge: %d/%d (regen %s/day)" % [int(dial["currentCharge"]), dial["maxCharge"], str(dial["rechargeRate"])]))
	c["content"].add_child(UI.bar(dial["currentCharge"], maxf(1.0, dial["maxCharge"])))
	c["content"].add_child(UI.label("Capacity: %d/%d" % [Dial.capacity_used(dial), dial["capacityMax"]]))

	_build_movement_crafting_section(c["content"], player)

	return c["panel"]


# bugfixes ticket 97: attempt_seed()'s three outcomes (refuse/fail/succeed)
# were previously discarded here, so a tap looked like nothing happened.
# PROSE-REVIEW: notification text below is new copy, drafted against
# CONTENT-GUIDE.md §3's tone bible -- flag for human review.
func _on_seed_pressed(haft_id: String) -> void:
	var haft: Dictionary = GameData.DIAL_HAFTS[haft_id]
	var result := Dial.attempt_seed(haft_id)
	if not result["ok"]:
		Notify.push(result["reason"], Notify.CATEGORY_WARNING)
	elif result["success"]:
		Notify.push("Dial seeded as \"%s\"." % haft["name"], Notify.CATEGORY_SUCCESS)
	else:
		Notify.push("Seeding failed — calc spent, no Dial gained.", Notify.CATEGORY_DANGER)


func _build_movement_crafting_section(content: VBoxContainer, player: Dictionary) -> void:
	content.add_child(UI.heading("Craft a Movement", 13))
	var skill: int = player["craftingSkill"]
	for archetype in GameData.CANONICAL_MOVEMENT_ARCHETYPES:
		var m: Dictionary = GameData.DIAL_MOVEMENTS[archetype]
		var cost: int = Dial.movement_calc_cost(archetype, skill)
		content.add_child(UI.muted_label("%s %s — %d calc, chance %d%%" % [m["symbol"], m["name"], cost, int(round(Dial.movement_craft_chance(archetype, skill) * 100))]))
		var row := UI.hbox()
		for ore_type in GameData.ORE_TYPES.keys():
			var have: int = player["orichalchum"].get(ore_type, 0)
			var captured_archetype: String = archetype
			var captured_ore: String = ore_type
			var b := UI.button("%s" % GameData.ORE_TYPES[ore_type]["symbol"], func(): _on_movement_craft_pressed(captured_archetype, captured_ore))
			b.disabled = have < cost
			row.add_child(b)
		content.add_child(row)


# bugfixes ticket 97: attempt_craft_movement()'s three outcomes were
# previously discarded here, same silent-tap problem as _on_seed_pressed().
# PROSE-REVIEW: notification text below is new copy, drafted against
# CONTENT-GUIDE.md §3's tone bible -- flag for human review.
func _on_movement_craft_pressed(archetype: String, ore_type: String) -> void:
	var result := Dial.attempt_craft_movement(archetype, ore_type)
	if not result["ok"]:
		Notify.push(result["reason"], Notify.CATEGORY_WARNING)
	elif result["success"]:
		var m: Dictionary = GameData.DIAL_MOVEMENTS[archetype]
		Notify.push("Movement crafted: %s (tier %d)." % [m["name"], result["tier"]], Notify.CATEGORY_SUCCESS)
	else:
		Notify.push("Movement-crafting failed — calc spent, no Movement gained.", Notify.CATEGORY_DANGER)

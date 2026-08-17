class_name PhoneScreen
extends Control

# M1-LONDON.md D4's Phone tab: a phone UI — contact list, SMS threads
# (existing sms_archie/sms_archie_2 screens, launched the same way the old
# `contacts` screen launched them), James job offers, the to-do list as a
# "Notes" app (Todo.get_items(), shared with the tutorial-era `home`
# screen), a faction directory, and D4.5's Ticker (the barometer as a news
# app). state.phoneNav drives which app is open, same pattern as
# state.mapNav for the Map tab.

const SECTION_LABELS := { "economic": "Economic", "social": "Social", "political": "Political" }

var _content: VBoxContainer
var _export_box: TextEdit
var _import_box: TextEdit


func _ready() -> void:
	UI.anchor_full_rect(self)
	_content = UI.screen_body(self)
	Barometer.ensure_progress()
	EventBus.state_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	for child in _content.get_children():
		child.queue_free()

	var nav: Dictionary = GameState.state["phoneNav"]
	match nav["app"]:
		"messages":
			_build_messages()
		"notes":
			_build_notes()
		"factions":
			_build_factions()
		"ticker":
			if nav.get("selectedAxis") == null:
				_build_ticker()
			else:
				_build_axis_detail(nav["selectedAxis"])
		"profile":
			_build_profile()
		"saveload":
			_build_save_load()
		_:
			_build_home()


func _phone_back_button() -> Control:
	return UI.button("‹ Back", func(): PhoneNav.go_home())


# ── home launcher (11-phone-os-shell ticket 07: the app grid) ────────
# Reskin of the old flat card list (ticket 02's AppTile + ticket 07's
# PhoneApps registry replace the emoji-titled cards this used to be --
# emoji render as blank tofu on the exported build, spec Problem
# Statement). Grid slots come straight from PhoneApps.apps(), in that
# fixed order, so a tile never reflows when it unlocks (spec story 8).

const GRID_COLUMNS := 3

func _build_home() -> void:
	_content.add_child(UI.heading("Phone"))
	_content.add_child(_build_app_grid(PhoneApps.apps()))


# Split out from _build_home() so tests can drive it with a synthetic
# roster (a locked entry, a lock-state flip) without needing PhoneApps'
# real, currently all-unlocked roster to contain one -- same "component
# testable against injected data" split PhoneApps.build_tile_configs()
# itself uses.
func _build_app_grid(apps_list: Array[Dictionary]) -> Control:
	var grid := GridContainer.new()
	grid.columns = GRID_COLUMNS
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)

	for config in PhoneApps.build_tile_configs(apps_list, _badge_for):
		var tile := AppTile.new()
		grid.add_child(tile)
		tile.configure(config)
		tile.tile_pressed.connect(_on_app_tile_pressed)

	return grid


func _on_app_tile_pressed(app_id: String) -> void:
	PhoneNav.open_app(app_id)


func _badge_for(app_id: String) -> bool:
	match app_id:
		"messages":
			return _has_pending_messages()
		"ticker":
			return _has_ticker_rumblings()
		_:
			return false


func _has_pending_messages() -> bool:
	var f: Dictionary = GameState.state["flags"]
	var world: Dictionary = GameState.state["world"]
	if f["archieMotionPending"] and not f["archieMotionEventSeen"]:
		return true
	if f["tutorialStage"] == "archie_craft_chat" and not f["archieCraftChatSeen"]:
		return true
	if f["tutorialStage"] == "buyer_event" and not f["buyerEventSeen"] and world["day"] >= 2:
		return true
	if f["tutorialStage"] == "sms_archie":
		return true
	if f["jamesMotionEventSeen"] and f["jamesJobActive"]:
		return true
	return false


func _has_ticker_rumblings() -> bool:
	for section in Barometer.SECTIONS:
		if Barometer.trend_hint_state(section) != null:
			return true
	return false


# ── messages (contact list + SMS threads + James jobs) ──────────────
# Reskin of the old M0 `contacts` screen's content (same flag-gated
# tutorial triggers, same system calls) under the Phone shell.

func _build_messages() -> void:
	_content.add_child(_phone_back_button())
	_content.add_child(UI.heading("Messages"))

	_content.add_child(ContactCards.build_archie_card())
	if GameState.state["contacts"]["james"]["unlocked"]:
		_content.add_child(ContactCards.build_james_card())


# ── notes (to-do list) ────────────────────────────────────────────────

func _build_notes() -> void:
	_content.add_child(_phone_back_button())
	_content.add_child(UI.heading("Notes"))

	var c := UI.card()
	var items := Todo.get_items()
	if items.is_empty():
		c["content"].add_child(UI.muted_label("Nothing pressing."))
	for item in items:
		c["content"].add_child(UI.checklist_row(item["text"], item["done"]))
	_content.add_child(c["panel"])


# ── factions (directory) ─────────────────────────────────────────────
# Reskin of the old M0 `factions` screen's content under the Phone shell —
# D4: "faction panels open from the district panel and from the Phone
# directory."

func _build_factions() -> void:
	_content.add_child(_phone_back_button())
	_content.add_child(UI.heading("Factions"))
	_content.add_child(UI.muted_label("Build relations. Join. Use rooms."))

	for faction_id in GameData.FACTIONS.keys():
		_content.add_child(ContactCards.build_faction_card(faction_id))


# ── The Ticker (D4.5) ────────────────────────────────────────────────

func _build_ticker() -> void:
	_content.add_child(_phone_back_button())
	_content.add_child(UI.heading("The Ticker"))
	_content.add_child(UI.muted_label("Push/pull costs £2000, once per state+direction per day."))

	for section in Barometer.SECTIONS:
		_content.add_child(_build_headline_card(section))


# PROSE-REVIEW: headline strings drafted per CONTENT-GUIDE.md tone bible,
# data/barometer.json's per-state `headlines` array (2 variants each).
# Card always shows variant 0 — a stable pick, not re-rolled on every
# unrelated state_changed refresh; the breaking-news notification
# (systems/barometer.gd's _resolve_section) is what actually randomises
# across variants, once per state shift.
func _build_headline_card(section: String) -> Control:
	var barometer: Dictionary = GameState.state["barometer"]
	var active_state: String = barometer[section]
	var state_data: Dictionary = GameData.BAROMETER_STATES[section][active_state]
	var headline: String = state_data["headlines"][0]

	var c := UI.card()
	c["content"].add_child(UI.muted_label(SECTION_LABELS[section].to_upper()))
	# Headline strings are full sentences, not short titles — UI.heading()
	# never wraps (by design, for titles like "Phone"/"The Ticker"), so an
	# unwrapped sentence there overflowed the card and, since the screen's
	# ScrollContainer has no clipping/horizontal scroll, blew out the whole
	# page's layout width (seen in human QA on-device: text ran off past
	# the visible window on every card, not just this one). A plain
	# UI.label() wraps and still reads as the card's headline visually via
	# the font-size override.
	var headline_label := UI.label(headline)
	headline_label.add_theme_font_size_override("font_size", 16)
	c["content"].add_child(headline_label)
	c["content"].add_child(UI.muted_label(state_data["description"]))

	var hint_state = Barometer.trend_hint_state(section)
	if hint_state != null:
		var hint_label: String = GameData.BAROMETER_STATES[section][hint_state]["label"]
		c["content"].add_child(UI.muted_label("Rumblings: %s building." % hint_label))

	c["content"].add_child(UI.button("Open →", func(): PhoneNav.select_axis(section)))
	return c["panel"]


func _build_axis_detail(section: String) -> void:
	_content.add_child(UI.button("‹ Back to Ticker", func(): PhoneNav.back_to_ticker()))
	_content.add_child(UI.heading(SECTION_LABELS[section]))

	var barometer: Dictionary = GameState.state["barometer"]
	var active_state: String = barometer[section]
	var state_data: Dictionary = GameData.BAROMETER_STATES[section][active_state]

	var summary := UI.card()
	summary["content"].add_child(UI.heading(state_data["label"], 14))
	summary["content"].add_child(UI.muted_label(state_data["description"]))
	for key in state_data["effects"].keys():
		var v = state_data["effects"][key]
		var sign := "+" if v > 0 else ""
		summary["content"].add_child(UI.muted_label("%s %s%s" % [key, sign, str(v)]))
	_content.add_child(summary["panel"])

	_content.add_child(UI.heading("All states", 14))
	for state_id in GameData.BAROMETER_STATES[section].keys():
		_content.add_child(_build_state_row(section, state_id, active_state))

	_content.add_child(_build_influence_actions_card(section))


func _build_state_row(section: String, state_id: String, active_state: String) -> Control:
	var barometer: Dictionary = GameState.state["barometer"]
	var other_state: Dictionary = GameData.BAROMETER_STATES[section][state_id]
	var progress: int = barometer["progress"].get(section, {}).get(state_id, 0)

	var c := UI.card()
	c["content"].add_child(UI.label("%s — %d%%" % [other_state["label"], progress]))
	c["content"].add_child(UI.bar(progress, 100.0))

	if state_id != active_state:
		var holdings := { "cash": GameState.state["player"]["cash"] }
		var row := UI.hbox()
		var push_button := UI.button(UI.format_cost_label({ "label": "Push", "resource": "cash", "amount": Barometer.MANUAL_ACTION_COST }, holdings), func(): Barometer.manual_push(section, state_id))
		push_button.disabled = not Barometer.can_push_pull(section, state_id, "push") or GameState.state["player"]["cash"] < Barometer.MANUAL_ACTION_COST
		row.add_child(push_button)
		var pull_button := UI.button(UI.format_cost_label({ "label": "Pull", "resource": "cash", "amount": Barometer.MANUAL_ACTION_COST }, holdings), func(): Barometer.manual_pull(section, state_id))
		pull_button.disabled = not Barometer.can_push_pull(section, state_id, "pull") or GameState.state["player"]["cash"] < Barometer.MANUAL_ACTION_COST
		row.add_child(pull_button)
		c["content"].add_child(row)

	return c["panel"]


# D4.5: "the M4 influence actions listed greyed with full costs shown."
func _build_influence_actions_card(section: String) -> Control:
	var c := UI.card()
	c["content"].add_child(UI.heading("Influence actions", 14))
	c["content"].add_child(UI.muted_label("Data only until M4 — shown greyed with their costs."))

	var any_action := false
	for action in GameData.BAROMETER_ACTIONS:
		if action["section"] != section:
			continue
		any_action = true
		var cost_parts: Array[String] = []
		var cost: Dictionary = action["cost"]
		for key in cost.keys():
			cost_parts.append("%s %s" % [str(cost[key]), key])
		c["content"].add_child(UI.label(action["label"]))
		c["content"].add_child(UI.muted_label(action["description"]))
		c["content"].add_child(UI.muted_label("Cost: %s" % ", ".join(cost_parts)))
		var b := UI.button(action["label"], func(): pass)
		b.disabled = true
		c["content"].add_child(b)

	if not any_action:
		c["content"].add_child(UI.muted_label("None for this axis yet."))

	return c["panel"]


# ── Profile (11-phone-os-shell ticket 08) ────────────────────────────
# Absorbs the You tab's genuinely homeless content -- HP/bar, attack
# range, the three skills + XP, and a read-only equipped weapon/device
# summary (spec story 15) -- copied over from you.gd's
# _build_stats_card/_build_skills_card/_build_equipment_card and its
# _equipped_weapon_label/_equipped_device_label helpers. Deliberately
# excludes cash/day (status bar already shows them, story 16) and the old
# Ops card's veins-held/ore-in-stock summary (bag drawer + HQ's
# stored-ore view already cover it, story 17). This is You's designated
# future landing spot for reputation (M2), affinities (M3), and Fieldcraft
# (M2) content per the spec's Implementation Decisions.

func _build_profile() -> void:
	_content.add_child(_phone_back_button())
	_content.add_child(UI.heading("Profile"))

	_content.add_child(_build_profile_stats_card())
	_content.add_child(_build_profile_skills_card())
	_content.add_child(_build_profile_equipment_card())


func _build_profile_stats_card() -> Control:
	var player: Dictionary = GameState.state["player"]
	var atk := Combat.get_attack_range()

	var c := UI.card()
	c["content"].add_child(UI.label("HP: %d / %d" % [player["hp"], player["hpMax"]]))
	c["content"].add_child(UI.bar(player["hp"], player["hpMax"]))
	c["content"].add_child(UI.label("Attack: %d–%d" % [atk["min"], atk["max"]]))
	return c["panel"]


func _build_profile_skills_card() -> Control:
	var player: Dictionary = GameState.state["player"]
	var c := UI.card()
	c["content"].add_child(UI.heading("Skills", 14))
	c["content"].add_child(UI.label("Crafting: Lv%d (%d XP)" % [player["craftingSkill"], player["craftingXP"]]))
	c["content"].add_child(UI.label("Cultivating: Lv%d (%d XP)" % [player["cultivatingSkill"], player["cultivatingXP"]]))
	c["content"].add_child(UI.label("Stealth: Lv%d (%d XP)" % [player["stealthSkill"], player["stealthXP"]]))
	return c["panel"]


func _build_profile_equipment_card() -> Control:
	var player: Dictionary = GameState.state["player"]
	var c := UI.card()
	c["content"].add_child(UI.heading("Equipment", 14))
	c["content"].add_child(_equipped_weapon_label(player))
	c["content"].add_child(_equipped_device_label(player))
	return c["panel"]


func _equipped_weapon_label(player: Dictionary) -> Control:
	var weapon_id: Variant = player["equipment"]["weapon"]
	for item in player["items"]:
		if item["id"] == weapon_id:
			var def: Dictionary = GameData.ITEMS.get(item["type"], {})
			return UI.label("%s %s (equipped)" % [def.get("symbol", ""), def.get("name", "")])
	return UI.muted_label("Weapon: none equipped")


func _equipped_device_label(player: Dictionary) -> Control:
	var device_id: Variant = player["equipment"]["device"]
	for device in player["devicesCompleted"]:
		if device["id"] == device_id:
			var dt: Dictionary = GameData.DEVICES[device["type"]]
			var charges_left: int = device["chargesPerDay"] - device["chargesUsedToday"]
			return UI.label("%s %s (equipped) — %d/%d charges" % [dt["symbol"], dt["name"], charges_left, device["chargesPerDay"]])
	return UI.muted_label("Device: none equipped")


# ── Save/Load (11-phone-os-shell ticket 09) ──────────────────────────
# Absorbs the You tab's save/load/export/import/new-game content --
# copied over from you.gd's slot/export/import building blocks, plus a
# confirm-gate ahead of New Game that you.gd never had (spec: "no
# destructive action in this app commits on a single tap").

func _build_save_load() -> void:
	_content.add_child(_phone_back_button())
	_content.add_child(UI.heading("Save/Load"))

	for slot in range(1, SaveManager.SLOT_COUNT + 1):
		_content.add_child(_build_save_slot_row(slot))
	_content.add_child(_build_export_card())
	_content.add_child(_build_import_card())
	_content.add_child(_build_new_game_card())


func _build_save_slot_row(slot: int) -> Control:
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
	actions.add_child(UI.button("Save", _on_save_slot_pressed.bind(slot)))
	if filled:
		actions.add_child(UI.button("Load", func(): SaveManager.load_from_slot(slot)))
		actions.add_child(UI.button("Delete", _on_delete_slot_pressed.bind(slot)))
	c["content"].add_child(actions)

	return c["panel"]


# save_to_slot/delete_slot don't touch GameState.state, so they don't emit
# state_changed the way load_from_slot does -- refresh explicitly so the
# slot list reflects what just happened.
func _on_save_slot_pressed(slot: int) -> void:
	SaveManager.save_to_slot(slot)
	_refresh()


func _on_delete_slot_pressed(slot: int) -> void:
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


# Two-step gate: a plain New Game button that only arms the confirm state
# (PhoneNav.arm_new_game_confirm), then, once armed, a Confirm/Cancel pair
# in its place -- so a single tap can never commit the reset.
func _build_new_game_card() -> Control:
	var c := UI.card()
	c["content"].add_child(UI.heading("New Game", 14))

	var nav: Dictionary = GameState.state["phoneNav"]
	if nav.get("confirmingNewGame", false):
		c["content"].add_child(UI.muted_label("This will erase all progress. Are you sure?"))
		var actions := UI.hbox()
		actions.add_child(UI.button("Confirm", _on_confirm_new_game_pressed))
		actions.add_child(UI.button("Cancel", func(): PhoneNav.cancel_new_game_confirm()))
		c["content"].add_child(actions)
	else:
		c["content"].add_child(UI.button("New Game", func(): PhoneNav.arm_new_game_confirm()))

	return c["panel"]


func _on_confirm_new_game_pressed() -> void:
	GameState.reset()
	Factions.seed_day_one_veins()
	Nav.go_to("intro")

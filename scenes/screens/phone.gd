class_name PhoneScreen
extends Control

const SECTION_LABELS := { "economic": "Economic", "social": "Social", "political": "Political" }
const MorningAccountsSystem := preload("res://systems/morning_accounts.gd")
const RaidAlarmsSystem := preload("res://systems/raid_alarms.gd")
const OffersSystem := preload("res://systems/offers.gd")
const ContractsSystem := preload("res://systems/contracts.gd")
const ContractCard := preload("res://scenes/components/contract_card.gd")

var _content: VBoxContainer
var _export_box: TextEdit
var _import_box: TextEdit
var _leave_undefended_situation_id := ""
const BIZBRIEF_BRIEF_TAB := "brief"
const BIZBRIEF_MANAGE_TAB := "manage"
var _bizbrief_tab := BIZBRIEF_BRIEF_TAB
var _background: Panel
var _background_style: StyleBoxFlat
var _reveal_from_index: Dictionary = {}
var _conversation_root: Control = null

func _ready() -> void:
	UI.anchor_full_rect(self)
	_paint_family2_background()
	_content = UI.screen_body(self)
	Barometer.ensure_progress()
	EventBus.state_changed.connect(_refresh)
	_refresh()
func _paint_family2_background() -> void:
	_background = Panel.new()
	UI.anchor_full_rect(_background)
	_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_background_style = StyleBoxFlat.new()
	_background.add_theme_stylebox_override("panel", _background_style)
	add_child(_background)

func _refresh() -> void:
	for child in _content.get_children():
		_content.remove_child(child)
		child.queue_free()
	if _conversation_root != null:
		_conversation_root.queue_free()
		_conversation_root = null
	_content.get_parent().visible = true

	var nav: Dictionary = GameState.state["phoneNav"]
	if nav["app"] == "home":
		_background_style.bg_color = GameData.PALETTE.get("phone_bg_home", Color("#1b1b1d"))
	else:
		_background_style.bg_color = GameData.PALETTE.get("phone_bg_content", Color("#252528"))

	match nav["app"]:
		"alarms":
			_build_alarms()
		"bizbrief":
			_build_bizbrief()
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
		"notifications":
			_build_notifications()
		"bank":
			_build_bank()
		"property":
			_build_property()
		"debug":
			_build_debug()
		_:
			_build_home()
	ContactCards.apply_phone_os_chrome(_content)

func _phone_back_button() -> Control:
	return UI.button("‹ Back", func(): PhoneNav.go_home())

const GRID_COLUMNS := 3

func _build_home() -> void:
	_content.add_child(UI.heading("Phone"))
	_content.add_child(_build_app_grid(PhoneApps.apps()))
func _build_app_grid(apps_list: Array[Dictionary]) -> Control:
	var grid := GridContainer.new()
	grid.columns = GRID_COLUMNS
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)

	for config in PhoneApps.build_tile_configs(apps_list, _badge_for):
		var tile := AppTile.new(true)
		grid.add_child(tile)
		tile.configure(config)
		tile.tile_pressed.connect(_on_app_tile_pressed)
	var wrapper := CenterContainer.new()
	wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrapper.add_child(grid)
	return wrapper
func _on_app_tile_pressed(app_id: String) -> void:
	if app_id == "vfl":
		if _vfl_locked():
			Notify.push(NavBar.LOCKED_MAP_LABEL)
		else:
			Nav.go_to("map")
		return
	if app_id == "contacts":
		Nav.go_to("contacts")
		return
	PhoneNav.open_app(app_id)

func _vfl_locked() -> bool:
	return not GameState.state["flags"]["archiePartnerSeen"]

func _badge_for(app_id: String) -> bool:
	match app_id:
		"alarms":
			return RaidAlarmsSystem.has_unresolved()
		"ticker":
			return _has_ticker_rumblings()
		_:
			return false

func _has_ticker_rumblings() -> bool:
	for section in Barometer.SECTIONS:
		if Barometer.trend_hint_state(section) != null:
			return true
	return false

func _build_alarms() -> void:
	_content.add_child(_phone_back_button())
	_content.add_child(UI.heading("Alarms"))
	var rows := RaidAlarmsSystem.summary_rows()
	if rows.is_empty():
		_content.add_child(UI.muted_label("No active alarms."))
		return
	_content.add_child(UI.muted_label("%d unresolved" % rows.size()))
	for row in rows:
		_content.add_child(_build_alarm_row(row))

func _build_alarm_row(row: Dictionary) -> Control:
	var c := UI.card()
	c["content"].add_child(UI.heading(row["title"], 14))
	c["content"].add_child(UI.label("District: %s" % row["district"]))
	c["content"].add_child(UI.label("Deadline: %s" % row["deadline"]))
	c["content"].add_child(UI.muted_label(row["consequence"]))
	var actions := UI.hbox()
	actions.add_child(UI.button("Go and defend", func():
		if not RaidAlarmsSystem.defend(row["id"]):
			_refresh()
	))
	if row["kind"] == "vein":
		if _leave_undefended_situation_id == row["id"]:
			c["content"].add_child(UI.muted_label("Leave this vein undefended? The raid resolves immediately."))
			c["content"].add_child(UI.label(row["consequence"]))
			actions.add_child(UI.button("Confirm leave undefended", func():
				_leave_undefended_situation_id = ""
				RaidAlarmsSystem.leave_undefended(row["id"])
				_refresh()
			))
			actions.add_child(UI.button("Cancel", func():
				_leave_undefended_situation_id = ""
				_refresh()
			))
		else:
			actions.add_child(UI.button("Leave undefended", func():
				_leave_undefended_situation_id = row["id"]
				_refresh()
			))
	actions.add_child(UI.button("Decide later", func(): PhoneNav.go_home()))
	c["content"].add_child(actions)
	return c["panel"]

func _build_messages() -> void:
	var contact_id: String = GameState.state["phoneNav"]["selectedContactId"]
	if not _reveal_from_index.has(contact_id):
		var reveal_from_index = GameState.state["phoneNav"].get("revealFromIndex")
		_reveal_from_index[contact_id] = reveal_from_index if reveal_from_index != null else 0
	_build_conversation(contact_id)

func _build_conversation(contact_id: String) -> void:
	_content.get_parent().visible = false

	_conversation_root = UI.vbox(0)
	UI.anchor_below_bars(_conversation_root)
	add_child(_conversation_root)

	var header := UI.hbox()
	header.add_child(_phone_back_button())
	header.add_child(UI.heading(Contacts.display_name(contact_id)))
	_conversation_root.add_child(header)

	var scroll := UI.scroll_container()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_conversation_root.add_child(scroll)

	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	scroll.add_child(margin)

	var box := UI.vbox(8)
	margin.add_child(box)

	var thread: Array = GameState.state["messages"].get(contact_id, [])
	var reveal_from: int = mini(_reveal_from_index.get(contact_id, thread.size()), thread.size())
	for i in range(reveal_from):
		box.add_child(UI.message_bubble(thread[i]["text"], thread[i]["from"] == "player"))

	_conversation_root.add_child(_build_action_bar(contact_id))
	ContactCards.apply_phone_os_chrome(_conversation_root)

	if reveal_from < thread.size():
		_reveal_from_index[contact_id] = thread.size()
		_reveal_remaining(box, thread, reveal_from)
func _reveal_remaining(box: VBoxContainer, thread: Array, start_index: int) -> void:
	for i in range(start_index, thread.size()):
		if not is_instance_valid(box):
			return
		var bubble := UI.message_bubble(thread[i]["text"], thread[i]["from"] == "player")
		box.add_child(bubble)
		ContactCards.apply_phone_os_chrome(bubble)
		var delay: float = 0.9 if (i - start_index) % 2 == 0 else 0.6
		await get_tree().create_timer(delay).timeout
func _build_action_bar(contact_id: String) -> Control:
	var bar := UI.vbox(8)
	for shortcut in ContactCards.build_pin_shortcut_actions(contact_id):
		bar.add_child(shortcut)
	if contact_id == "archie":
		var pry_action := ContactCards.build_archie_pry_action()
		if pry_action != null:
			bar.add_child(pry_action)
	if contact_id == "des":
		var report_action := ContactCards.build_des_report_action()
		if report_action != null:
			bar.add_child(report_action)
		var ask_joining_action := ContactCards.build_ask_des_joining_action()
		if ask_joining_action != null:
			bar.add_child(ask_joining_action)
	if contact_id == "nadia":
		var meet_action := ContactCards.build_nadia_meet_action()
		if meet_action != null:
			bar.add_child(meet_action)
		var vein_ask_action := ContactCards.build_nadia_vein_ask_action()
		if vein_ask_action != null:
			bar.add_child(vein_ask_action)
		var supply_action := ContactCards.build_nadia_supply_action()
		if supply_action != null:
			bar.add_child(supply_action)
	if contact_id == "hakim":
		var hakim_done_action := ContactCards.build_hakim_done_action()
		if hakim_done_action != null:
			bar.add_child(hakim_done_action)
	for entry in Messages.pending_for(contact_id):
		bar.add_child(UI.button("Continue →", _on_pending_action_pressed.bind(entry)))
	if contact_id == "archie":
		bar.add_child(ContactCards.build_sell_action())
	elif contact_id != "james":
		bar.add_child(ContactCards.build_trade_action(contact_id))
	return bar

func _on_pending_action_pressed(entry: Dictionary) -> void:
	Messages.resolve_pending(entry["id"])
	Events.start_event(entry["kind"], entry["payload"])

func _build_notes() -> void:
	_content.add_child(_phone_back_button())
	_content.add_child(UI.heading("Notes"))
	var sections := Todo.get_active_questlines()
	if sections.is_empty():
		var empty_card := UI.card()
		empty_card["content"].add_child(UI.muted_label("Nothing pressing."))
		_content.add_child(empty_card["panel"])

	for section in sections:
		_content.add_child(UI.heading(section["label"], 14))
		var c := UI.card()
		for item in section["items"]:
			var text: String = item["title"] if item["detail"] == "" else "%s — %s" % [item["title"], item["detail"]]
			c["content"].add_child(UI.checklist_row(text, item["done"]))
		_content.add_child(c["panel"])

func _build_factions() -> void:
	_content.add_child(_phone_back_button())
	_content.add_child(UI.heading("Factions"))
	_content.add_child(UI.muted_label("Build relations. Join. Use rooms."))

	for faction_id in GameData.FACTIONS.keys():
		_content.add_child(ContactCards.build_faction_card(faction_id))

func _build_ticker() -> void:
	_content.add_child(_phone_back_button())
	_content.add_child(UI.heading("The Ticker"))
	_content.add_child(UI.muted_label("Push/pull costs £2000, once per state+direction per day."))

	for section in Barometer.SECTIONS:
		_content.add_child(_build_headline_card(section))
func _build_headline_card(section: String) -> Control:
	var barometer: Dictionary = GameState.state["barometer"]
	var active_state: String = barometer[section]
	var state_data: Dictionary = GameData.BAROMETER_STATES[section][active_state]
	var headline: String = state_data["headlines"][0]

	var c := UI.card()
	c["content"].add_child(UI.muted_label(SECTION_LABELS[section].to_upper()))
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

func _build_profile() -> void:
	_content.add_child(_phone_back_button())
	_content.add_child(UI.heading("Profile"))

	_content.add_child(_build_profile_stats_card())
	_content.add_child(_build_profile_skills_card())
	_content.add_child(_build_profile_equipment_card())
	var motion := CheckButton.new()
	motion.text = GameData.DAILY_CYCLE["reducedMotionLabel"]
	motion.button_pressed = GameState.state["meta"].get("reducedMotion", false)
	motion.toggled.connect(preload("res://systems/preferences.gd").set_reduced_motion)
	_content.add_child(motion)
	var vibrate := CheckButton.new()
	vibrate.text = "Vibrate for alarms"
	vibrate.button_pressed = GameState.state["meta"].get("vibrationEnabled", true)
	vibrate.toggled.connect(preload("res://systems/preferences.gd").set_vibration_enabled)
	_content.add_child(vibrate)

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
	_add_skill_row(c["content"], "Crafting", player["craftingSkill"], player["craftingXP"], GameData.CRAFTING_XP_LEVELS)
	_add_skill_row(c["content"], "Cultivating", player["cultivatingSkill"], player["cultivatingXP"], GameData.CULTIVATING_XP_LEVELS)
	_add_skill_row(c["content"], "Stealth", player["stealthSkill"], player["stealthXP"], GameData.STEALTH_XP_LEVELS)
	_add_skill_row(c["content"], "Combat", player["combatSkill"], player["combatXP"], GameData.COMBAT_XP_LEVELS)
	return c["panel"]
func _add_skill_row(content: Node, label: String, level: int, xp: int, levels: Array) -> void:
	content.add_child(UI.label("%s: Lv%d (%d XP)" % [label, level, xp]))
	var max_level: int = levels.size() - 1
	if level >= max_level:
		content.add_child(UI.bar(1, 1))
	else:
		var this_threshold: int = levels[level]
		var next_threshold: int = levels[level + 1]
		content.add_child(UI.bar(xp - this_threshold, next_threshold - this_threshold))

func _build_profile_equipment_card() -> Control:
	var player: Dictionary = GameState.state["player"]
	var c := UI.card()
	c["content"].add_child(UI.heading("Equipment", 14))
	c["content"].add_child(_equipped_weapon_label(player))
	c["content"].add_child(_dial_summary_label(player))
	return c["panel"]

func _equipped_weapon_label(player: Dictionary) -> Control:
	var weapon_id: Variant = player["equipment"]["weapon"]
	for item in player["items"]:
		if item["id"] == weapon_id:
			var def: Dictionary = GameData.ITEMS.get(item["type"], {})
			return UI.label("%s %s (equipped)" % [def.get("symbol", ""), def.get("name", "")])
	return UI.muted_label("Weapon: none equipped")
func _dial_summary_label(player: Dictionary) -> Control:
	var dial: Variant = player["dial"]
	if dial == null:
		return UI.muted_label("Dial: none")
	var movement: Variant = dial["movement"]
	if movement == null:
		return UI.label("Dial: Lv%d — no Movement seated (inert)" % dial["level"])
	var m: Dictionary = GameData.DIAL_MOVEMENTS[movement["archetype"]]
	return UI.symbol_row(["Dial: Lv%d — " % dial["level"], { "symbol": m["symbol"], "fallback": SymbolGlyph.generic_fallback() }, " %s, charge %d/%d" % [m["name"], int(dial["currentCharge"]), dial["maxCharge"]]])

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

func _build_notifications() -> void:
	_content.add_child(_phone_back_button())
	_content.add_child(UI.heading("Notifications"))

	var notifications: Array = GameState.state["notifications"]
	if notifications.is_empty():
		_content.add_child(UI.muted_label("Nothing yet."))
	else:
		for i in range(notifications.size() - 1, -1, -1):
			_content.add_child(_build_notification_row(notifications[i]))

func _build_notification_row(notification: Dictionary) -> Control:
	var c := UI.card()
	c["content"].add_child(UI.label(notification["text"]))
	c["content"].add_child(UI.muted_label("Day %d" % notification["day"]))

	var vein_id: Variant = notification.get("veinId")
	if vein_id != null and Raiding.is_defend_notification_pending(notification["id"]):
		c["content"].add_child(UI.button("Defend", func(): Raiding.trigger_defend(vein_id)))
	elif notification.get("homeRaid") == true and Home.is_pending_raid_notification(notification["id"]):
		c["content"].add_child(UI.button("Defend", func(): Home.trigger_defend()))

	return c["panel"]

func _build_bizbrief() -> void:
	_content.add_child(_phone_back_button())
	_content.add_child(UI.heading("BizBrief"))
	_content.add_child(_build_bizbrief_tabs())
	if _bizbrief_tab == BIZBRIEF_MANAGE_TAB:
		_build_bizbrief_manage()
		return
	_build_bizbrief_brief()

func _build_bizbrief_tabs() -> Control:
	var tabs := UI.hbox()
	var brief := UI.button("Brief", func(): _set_bizbrief_tab(BIZBRIEF_BRIEF_TAB))
	brief.disabled = _bizbrief_tab == BIZBRIEF_BRIEF_TAB
	tabs.add_child(UI.expand_fill(brief))
	var manage := UI.button("Manage", func(): _set_bizbrief_tab(BIZBRIEF_MANAGE_TAB))
	manage.disabled = _bizbrief_tab == BIZBRIEF_MANAGE_TAB
	tabs.add_child(UI.expand_fill(manage))
	return tabs

func _set_bizbrief_tab(tab: String) -> void:
	if tab == _bizbrief_tab:
		return
	_bizbrief_tab = tab
	_refresh()

func _build_bizbrief_brief() -> void:
	_content.add_child(UI.heading("Morning Brief", 16))
	var account = MorningAccountsSystem.latest()
	if account == null:
		_content.add_child(UI.muted_label("No morning account yet."))
		return
	_content.add_child(UI.muted_label("Day %d · overnight changes" % account["day"]))
	_content.add_child(_build_bizbrief_bank(account))
	if MorningAccountsSystem.has_operations(account):
		_content.add_child(_build_bizbrief_operations(account))
	var attention := MorningAccountsSystem.attention_items()
	if not attention.is_empty():
		_content.add_child(_build_bizbrief_attention(attention))

func _build_bizbrief_manage() -> void:
	_content.add_child(UI.heading("Manage", 16))
	_content.add_child(_build_bizbrief_sales())
	_content.add_child(_build_bizbrief_production())
	_content.add_child(_build_bizbrief_procurement())
func _build_bizbrief_production() -> Control:
	var c := UI.card()
	c["content"].add_child(UI.heading("Production", 14))

	if not GameState.state["home"]["rooms"].has("lab"):
		c["content"].add_child(UI.muted_label("Requires the Improved Lab."))
		return c["panel"]

	var flags: Dictionary = GameState.state["flags"]
	var any_unlocked := false
	for recipe_key in Rooms.RECIPE_UNLOCK_FLAGS.keys():
		var unlock_flag: String = Rooms.RECIPE_UNLOCK_FLAGS[recipe_key]
		if unlock_flag != "" and not flags.get(unlock_flag, false):
			continue
		any_unlocked = true
		c["content"].add_child(_build_production_recipe_row(recipe_key))
	if not any_unlocked:
		c["content"].add_child(UI.muted_label("No craftable recipes unlocked yet."))
	return c["panel"]

func _build_production_recipe_row(recipe_key: String) -> Control:
	var recipe: Dictionary = GameData.RECIPES[recipe_key]
	var target: int = GameState.state["labThresholds"].get(recipe_key, 0)
	var covering: bool = Rooms.lab_covers_contracts(recipe_key)

	var box := UI.vbox(4)
	box.add_child(UI.label(recipe["name"]))

	var target_text := "Personal target: %d" % target
	if covering:
		var need: int = Rooms.contract_need(recipe_key)
		target_text += " · contract need: %d · crafting to: %d" % [need, Rooms.effective_lab_target(recipe_key)]
	box.add_child(UI.muted_label(target_text))

	var target_row := UI.hbox()
	target_row.add_child(UI.button("-5", func(): Rooms.adjust_lab_threshold(recipe_key, -5)))
	target_row.add_child(UI.button("+5", func(): Rooms.adjust_lab_threshold(recipe_key, 5)))
	target_row.add_child(UI.button("Stop covering contracts" if covering else "Cover contract needs", func(): Rooms.set_lab_cover_contracts(recipe_key, not covering)))
	box.add_child(target_row)

	return box
func _build_bizbrief_procurement() -> Control:
	var c := UI.card()
	c["content"].add_child(UI.heading("Procurement", 14))

	if not GameState.state["home"]["rooms"].has("veinStation"):
		c["content"].add_child(UI.muted_label("Requires the Vein Cultivation Station room."))
		return c["panel"]

	var veins: Array = VeinList.veins(null, null)
	if veins.is_empty():
		c["content"].add_child(UI.muted_label("No veins yet."))
		return c["panel"]

	for vein in veins:
		c["content"].add_child(_build_procurement_vein_row(vein))
	return c["panel"]

func _build_procurement_vein_row(vein: Dictionary) -> Control:
	var vein_id: String = vein["id"]
	var ore: Dictionary = GameData.ORE_TYPES[vein["oreType"]]
	var district: Dictionary = GameData.DISTRICTS[vein["district"]]

	var box := UI.vbox(4)
	box.add_child(UI.label("%s — %s" % [district["name"], ore["name"]]))

	var station_text: Variant = Rooms.vein_station_target_text(vein_id)
	if station_text == null:
		box.add_child(UI.button("Assign to Vein Station", func(): Rooms.toggle_vein_station_vein(vein_id)))
		return box

	var target: int = GameState.state["veinStationTargets"].get(vein_id, Rooms.VEIN_STATION_DEFAULT_TARGET)
	box.add_child(UI.muted_label(String(station_text)))

	var row := UI.hbox()
	row.add_child(UI.button("-5", func(): Rooms.set_vein_station_target(vein_id, target - 5)))
	row.add_child(UI.button("+5", func(): Rooms.set_vein_station_target(vein_id, target + 5)))
	row.add_child(UI.button("Unassign", func(): Rooms.toggle_vein_station_vein(vein_id)))
	box.add_child(row)

	return box
func _request_type_name(kind: String, item_type: String) -> String:
	return GameData.ORE_TYPES[item_type]["name"] if kind == "ore" else GameData.RECIPES[item_type]["name"]

func _request_summary(request: Dictionary) -> String:
	var parts: Array = []
	for line in ContractsSystem.request_lines(request):
		parts.append("%d %s" % [line["qty"], _request_type_name(line["kind"], line["type"])])
	return " + ".join(parts)

func _contract_progress_summary(contract: Dictionary) -> String:
	var parts: Array = []
	for line in ContractsSystem.request_lines(contract["request"]):
		parts.append("%d/%d %s" % [ContractsSystem.delivered_qty(contract, line["type"]), line["qty"], _request_type_name(line["kind"], line["type"])])
	return ", ".join(parts)

func _build_bizbrief_sales() -> Control:
	var c := UI.card()
	c["content"].add_child(UI.heading("Sales", 14))
	var offers: Array = OffersSystem.pending_offers()
	if offers.is_empty():
		c["content"].add_child(UI.muted_label("No pending offers."))
	for offer in offers:
		var request: Dictionary = offer["request"]
		c["content"].add_child(UI.label("%s · £%d · expires day %d" % [_request_summary(request), offer["quote"]["payment"], offer["expiresDay"]]))
		c["content"].add_child(UI.button("Accept", func(): OffersSystem.accept_offer(offer["id"])))
	var contracts: Array = ContractsSystem.active_contracts()
	if not contracts.is_empty():
		c["content"].add_child(UI.heading("Active contracts", 14))
		c["content"].add_child(UI.muted_label("Drag cards to set delivery priority."))
		for index in contracts.size():
			var contract: Dictionary = contracts[index]
			var card := ContractCard.new()
			card.configure(contract["id"], index)
			var box := VBoxContainer.new()
			card.add_child(box)
			box.add_child(UI.label("%d. %s: %s · due day %d · £%d" % [index + 1, contract["id"], _contract_progress_summary(contract), contract["dueDay"], contract["quote"]["payment"]]))
			box.add_child(UI.button("Remove Sales delegation" if contract.get("delegated", false) else "Delegate to Sales", func(): ContractsSystem.set_delegated(contract["id"], not contract.get("delegated", false))))
			if not contract.get("delegated", false):
				var row := UI.hbox()
				row.add_child(UI.button("Deliver 1", func(): ContractsSystem.deliver(contract["id"], 1)))
				row.add_child(UI.button("Deliver all", func(): ContractsSystem.deliver(contract["id"], ContractsSystem.remaining_qty(contract))))
				box.add_child(row)
			c["content"].add_child(card)
	var history: Array = GameState.state["sales"].get("contractHistory", [])
	if not history.is_empty():
		c["content"].add_child(UI.heading("History", 14))
		for entry in history:
			var settled: Dictionary = entry["settlement"]
			c["content"].add_child(UI.muted_label("%s · %s · £%d" % [settled["id"], "complete" if settled["complete"] else "partial", settled["payment"]]))
	return c["panel"]

func _build_bizbrief_bank(account: Dictionary) -> Control:
	var c := UI.card()
	c["content"].add_child(UI.heading("Reynard's", 14))
	c["content"].add_child(UI.label("Opening £%d · Closing £%d" % [account["openingBalance"], account["closingBalance"]]))
	c["content"].add_child(UI.label("Income +£%d · Expenses −£%d" % [account["income"], account["expenses"]]))
	c["content"].add_child(UI.button("Transaction history →", func(): MorningAccountsSystem.open_bank()))
	return c["panel"]

func _build_bizbrief_operations(account: Dictionary) -> Control:
	var c := UI.card()
	c["content"].add_child(UI.heading("Operations", 14))
	for ore_type in account["oreMovement"]:
		var change: int = account["oreMovement"][ore_type]
		c["content"].add_child(UI.symbol_row([{ "symbol": GameData.ORE_TYPES[ore_type]["symbol"], "fallback": SymbolGlyph.ore_fallback(ore_type) }, "%s stock %s" % [GameData.ORE_TYPES[ore_type]["name"], _signed_amount(change)]]))
	for ore_type in account["production"]["ore"]:
		c["content"].add_child(UI.muted_label("Produced %d %s" % [account["production"]["ore"][ore_type], GameData.ORE_TYPES[ore_type]["name"]]))
	for recipe_key in account["production"]["items"]:
		c["content"].add_child(UI.symbol_row([{ "symbol": GameData.RECIPES[recipe_key]["symbol"], "fallback": SymbolGlyph.generic_fallback() }, "Produced %d %s" % [account["production"]["items"][recipe_key], GameData.RECIPES[recipe_key]["name"]]]))
	for sale_key in account["sales"]:
		c["content"].add_child(UI.label("Sold %s: %d" % [sale_key, account["sales"][sale_key]]))
	for ore_type in account["losses"]["ore"]:
		c["content"].add_child(UI.symbol_row([{ "symbol": GameData.ORE_TYPES[ore_type]["symbol"], "fallback": SymbolGlyph.ore_fallback(ore_type) }, "Lost %d %s" % [account["losses"]["ore"][ore_type], GameData.ORE_TYPES[ore_type]["name"]]], { "muted": true }))
	if account["losses"]["veins"] > 0:
		c["content"].add_child(UI.muted_label("Lost %d vein%s" % [account["losses"]["veins"], "" if account["losses"]["veins"] == 1 else "s"]))
	for exception in account["exceptions"]:
		match exception["kind"]:
			"missedJob":
				c["content"].add_child(UI.muted_label("Exception: James's order expired."))
			"productionShortfall":
				var recipe: Dictionary = GameData.RECIPES[exception["recipeKey"]]
				c["content"].add_child(UI.muted_label("Exception: %s stock %d/%d." % [recipe["name"], exception["actual"], exception["target"]]))
	return c["panel"]

func _build_bizbrief_attention(items: Array[Dictionary]) -> Control:
	var c := UI.card()
	c["content"].add_child(UI.heading("Attention", 14))
	c["content"].add_child(UI.muted_label("Still unresolved"))
	for item in items:
		var captured: Dictionary = item
		var glyph: Callable = Icons.draw_phone if item["kind"] == "message" else Icons.draw_attack
		var row := UI.hbox()
		var icon := UI.icon_glyph_control(glyph, 0.7)
		icon.custom_minimum_size = Vector2(24, 24)
		row.add_child(icon)
		row.add_child(UI.expand_fill(UI.button(MorningAccountsSystem.attention_label(item), func(): MorningAccountsSystem.open_attention(captured))))
		c["content"].add_child(row)
	return c["panel"]

func _signed_amount(amount: int) -> String:
	return "+%d" % amount if amount > 0 else str(amount)

func _build_bank() -> void:
	_content.add_child(_phone_back_button())
	_content.add_child(UI.heading("Reynard's"))
	_content.add_child(_build_balance_card())

	var log: Array = GameState.state["bankLog"]
	if log.is_empty():
		_content.add_child(UI.muted_label("No transactions yet."))
	else:
		for i in range(log.size() - 1, -1, -1):
			_content.add_child(_build_bank_transaction_row(log[i]))

func _build_balance_card() -> Control:
	var c := UI.card()
	c["content"].add_child(UI.muted_label("BALANCE"))
	c["content"].add_child(UI.tinted_label("£%d" % GameState.state["player"]["cash"], _calc_gold()))
	return c["panel"]

func _build_bank_transaction_row(entry: Dictionary) -> Control:
	var c := UI.card()
	var amount: int = entry["amount"]
	var amount_text: String = "+£%d" % amount if amount >= 0 else "-£%d" % -amount
	var row := UI.hbox()
	row.add_child(UI.expand_fill(UI.label(entry["label"])))
	row.add_child(UI.tinted_label(amount_text, _calc_gold()))
	c["content"].add_child(row)
	c["content"].add_child(UI.muted_label("Day %d" % entry["day"]))
	return c["panel"]
func _calc_gold() -> Color:
	return GameData.PALETTE.get("calc_gold", Color("#d4af52"))

func _build_property() -> void:
	_content.add_child(_phone_back_button())
	_content.add_child(UI.heading("Harrow's"))
	_content.add_child(_build_property_current_card())
	_content.add_child(_build_property_next_card())

func _build_property_current_card() -> Control:
	var home: Dictionary = GameState.state["home"]
	var tier: Dictionary = GameData.HOME_TIERS[home["tier"]]
	var raid_pct: int = int(round(Home.get_home_raid_chance() * 100))

	var c := UI.card()
	c["content"].add_child(UI.muted_label("YOUR PLACE"))
	c["content"].add_child(UI.heading(tier["name"], 14))
	c["content"].add_child(UI.muted_label(tier["description"]))
	c["content"].add_child(UI.label("Daily cost: £%d · Raid risk: %d%% · Rooms %d/%d" % [tier["dailyCost"], raid_pct, home["rooms"].size(), tier["maxRooms"]]))
	return c["panel"]

func _build_property_next_card() -> Control:
	var home: Dictionary = GameState.state["home"]
	var next_id: String = Home.get_next_tier_id(home["tier"])

	var c := UI.card()
	c["content"].add_child(UI.muted_label("NEXT UP"))

	if next_id == "":
		c["content"].add_child(UI.muted_label("Top of the ladder. Nowhere further to move."))
		return c["panel"]

	var next_tier: Dictionary = GameData.HOME_TIERS[next_id]
	var raid_pct: int = int(round(Home.get_raid_chance_for_tier(next_id) * 100))
	var cost: int = next_tier["upgradeCost"]

	c["content"].add_child(UI.heading(next_tier["name"], 14))
	c["content"].add_child(UI.muted_label(next_tier["description"]))
	c["content"].add_child(UI.label("Daily cost: £%d · Raid risk: %d%% · Rooms %d" % [next_tier["dailyCost"], raid_pct, next_tier["maxRooms"]]))

	var b := UI.button("Move for £%d" % cost, func(): Home.upgrade_tier())
	b.disabled = GameState.state["player"]["cash"] < cost
	c["content"].add_child(b)
	if b.disabled:
		c["content"].add_child(UI.muted_label("Not enough cash."))

	return c["panel"]

func _build_debug() -> void:
	_content.add_child(_phone_back_button())
	_content.add_child(UI.heading("Debug"))
	_content.add_child(_build_debug_add_money_card())
	_content.add_child(_build_debug_add_calc_card())
	_content.add_child(_build_debug_spawn_site_card())
	_content.add_child(_build_debug_combat_card())
	_content.add_child(_build_debug_combat_prototype_card())
	_content.add_child(_build_debug_safe_area_card())
	_content.add_child(UI.heading("Contact relations", 14))
	for contact_id in GameData.CONTACTS_DEFAULTS.keys():
		_content.add_child(_build_debug_contact_relation_card(contact_id))
	_content.add_child(UI.heading("Faction relations", 14))
	for faction_id in GameData.FACTIONS.keys():
		_content.add_child(_build_debug_faction_relation_card(faction_id))

func _build_debug_add_money_card() -> Control:
	var c := UI.card()
	c["content"].add_child(UI.heading("Add money", 14))

	var amount_field := LineEdit.new()
	amount_field.placeholder_text = "Amount"
	c["content"].add_child(amount_field)

	c["content"].add_child(UI.button("Add", func():
		DebugTools.add_cash(amount_field.text.to_int())
	))

	return c["panel"]

func _build_debug_add_calc_card() -> Control:
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
func _build_debug_spawn_site_card() -> Control:
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
func _build_debug_combat_card() -> Control:
	var c := UI.card()
	c["content"].add_child(UI.heading("Combat", 14))
	c["content"].add_child(UI.button("Open", func(): Modal.open("combat_setup")))
	return c["panel"]
func _build_debug_combat_prototype_card() -> Control:
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
		c["content"].add_child(_build_debug_combat_prototype_launch_button(encounter_id, encounters[encounter_id].get("name", encounter_id)))
	return c["panel"]
func _build_debug_combat_prototype_launch_button(encounter_id: String, label: String) -> Control:
	return UI.button("Start: %s" % label, func(): CombatPrototype.start_encounter(encounter_id))
func _build_debug_safe_area_card() -> Control:
	var c := UI.card()
	c["content"].add_child(UI.heading("Safe area", 14))

	var dump := UI.label(UI.safe_area_debug_text())
	dump.autowrap_mode = TextServer.AUTOWRAP_OFF
	c["content"].add_child(dump)

	c["content"].add_child(UI.button("Refresh", func():
		dump.text = UI.safe_area_debug_text()
	))

	return c["panel"]
func _build_debug_contact_relation_card(contact_id: String) -> Control:
	var c := UI.card()
	var relation: int = GameState.state["contacts"][contact_id]["relation"]
	c["content"].add_child(UI.heading("%s (relation %d)" % [Contacts.display_name(contact_id), relation], 14))

	var delta_field := LineEdit.new()
	delta_field.placeholder_text = "Delta"
	c["content"].add_child(delta_field)

	c["content"].add_child(UI.button("Adjust", func():
		Contacts.award_relation(contact_id, delta_field.text.to_int())
	))

	return c["panel"]
func _build_debug_faction_relation_card(faction_id: String) -> Control:
	var c := UI.card()
	var relation: int = GameState.state["factions"][faction_id]["relation"]
	var faction_name: String = GameData.FACTIONS[faction_id]["name"]
	c["content"].add_child(UI.heading("%s (relation %d)" % [faction_name, relation], 14))

	var delta_field := LineEdit.new()
	delta_field.placeholder_text = "Delta"
	c["content"].add_child(delta_field)

	c["content"].add_child(UI.button("Adjust", func():
		Factions.adjust_player_relation(faction_id, delta_field.text.to_int())
	))

	return c["panel"]

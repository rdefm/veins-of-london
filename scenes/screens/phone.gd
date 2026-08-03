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
		_:
			_build_home()


func _phone_back_button() -> Control:
	return UI.button("‹ Back", func(): PhoneNav.go_home())


# ── home launcher ────────────────────────────────────────────────────

func _build_home() -> void:
	_content.add_child(UI.back_button("home"))
	_content.add_child(UI.heading("Phone"))

	_content.add_child(_build_app_tile("💬 Messages", "Archie, James, and whatever they want this time.", "messages", _has_pending_messages()))
	_content.add_child(_build_app_tile("🗒 Notes", "Things to do.", "notes", false))
	_content.add_child(_build_app_tile("🤝 Factions", "Who's who, and what they think of you.", "factions", false))
	_content.add_child(_build_app_tile("📰 The Ticker", "London, in three headlines.", "ticker", _has_ticker_rumblings()))


func _build_app_tile(title: String, subtitle: String, app_id: String, has_badge: bool) -> Control:
	var c := UI.card()
	c["content"].add_child(UI.heading(title + (" •" if has_badge else ""), 15))
	c["content"].add_child(UI.muted_label(subtitle))
	c["content"].add_child(UI.button("Open", func(): PhoneNav.open_app(app_id)))
	return c["panel"]


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
		var row := UI.hbox(6)
		row.add_child(UI.label("☑" if item["done"] else "☐"))
		var text := UI.label(item["text"])
		if item["done"]:
			text.add_theme_color_override("font_color", Color(0.541176, 0.541176, 0.541176, 1))
		row.add_child(text)
		c["content"].add_child(row)
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
	c["content"].add_child(UI.heading(headline, 16))
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

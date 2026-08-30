class_name PhoneScreen
extends Control

# M1-LONDON.md D4's Phone tab: a phone UI — contact list, SMS threads
# (83-contacts-archie-james-sms-port: including Archie's and James's, ported
# off their old bespoke sms_archie/sms_archie_2 screens), James job offers,
# a "Notes" app (Todo.get_active_questlines() — one section per active
# questline, ticket 79), a faction directory, and D4.5's Ticker (the
# barometer as a news app). state.phoneNav drives which app is open, same
# pattern as state.mapNav for the Map tab.

const SECTION_LABELS := { "economic": "Economic", "social": "Social", "political": "Political" }

var _content: VBoxContainer
var _export_box: TextEdit
var _import_box: TextEdit

# collective1-03: screen-local presentation cache for the Messages app's
# staged reveal -- contactId -> "already rendered instantly up to this
# index." Not game state (same "reveal counter is screen-local
# presentation state" reasoning the old sms_archie.gd's own _revealed used,
# before 83-contacts-archie-james-sms-port ported it here), so a save/load
# or an unrelated state_changed refresh never needs to touch it.
# 84-contacts-retire-messages-tile: the actual "how many were already read
# before this open" computation now happens in PhoneNav.select_conversation()
# itself (state.phoneNav.revealFromIndex) rather than here, since that's the
# only place left a conversation is ever opened from and it can run before a
# phone screen even exists (ContactCards.build_messages_button() opens a
# conversation from the Contacts screen). _build_messages() imports that
# value into this dict the first time it sees a given contactId, then this
# is bumped to the thread's full length the first time _build_conversation()
# consumes it -- so a stray _refresh() mid-reveal (some unrelated
# state_changed firing while the player is reading) just renders the rest
# instantly instead of restarting the animation, same as before.
var _reveal_from_index: Dictionary = {}

# collective1-03: a single conversation needs a genuinely pinned-at-bottom
# action bar (spec §5.2), which UI.screen_body()'s single-scroll skeleton
# (every other app's _content lives inside one ScrollContainer) can't give
# it -- see UI.anchor_below_bars()'s own doc comment: "a screen with its
# own bespoke layout (scroll region + a separately pinned action bar) where
# UI.screen_body()'s single-scroll skeleton doesn't fit." Built fresh as a
# sibling of _content's scroll container (same bespoke-layout shape the old
# sms_archie.gd screen used) only while a conversation is open; _content's
# own scroll container is hidden underneath it for that one view so it
# can't still catch touch/drag input behind the pinned action bar.
var _conversation_root: Control = null


func _ready() -> void:
	UI.anchor_full_rect(self)
	_content = UI.screen_body(self)
	Barometer.ensure_progress()
	EventBus.state_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	for child in _content.get_children():
		child.queue_free()
	if _conversation_root != null:
		_conversation_root.queue_free()
		_conversation_root = null
	_content.get_parent().visible = true

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
		"notifications":
			_build_notifications()
		"bank":
			_build_bank()
		"debug":
			_build_debug()
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
		var tile := AppTile.new(true)
		grid.add_child(tile)
		tile.configure(config)
		tile.tile_pressed.connect(_on_app_tile_pressed)

	# bugfixes-60: a bare GridContainer defaults to SIZE_FILL, so
	# screen_body()'s full-width VBoxContainer stretches it to the screen
	# width -- but GridContainer has no alignment property of its own, so it
	# just packs its columns against the left edge of that stretched rect,
	# leaving the unused width sitting on the right. A CenterContainer
	# wrapper takes the FILL instead and centers the grid (which sizes to
	# its own minimum, unaffected) within it. Holds at any tile count since
	# GRID_COLUMNS is fixed -- the grid's width never depends on how many
	# rows of tiles (locked or not) it's holding.
	var wrapper := CenterContainer.new()
	wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrapper.add_child(grid)
	return wrapper


# bugfixes-39: "vfl" is a cosmetic rebrand of the dock's own Map entry
# point, not a real PhoneNav app -- it never opens within the phone shell,
# it jumps straight to the Map screen (or shows the dock's own lock toast
# and stays put), same special case NavBar._on_tile_pressed() already
# makes for its own Map slot.
func _on_app_tile_pressed(app_id: String) -> void:
	if app_id == "vfl":
		if _vfl_locked():
			Notify.push(NavBar.LOCKED_MAP_LABEL)
		else:
			Nav.go_to("map")
		return
	# bugfixes-78: contacts.gd is a standalone SCREEN_SCRIPTS entry (Main.gd),
	# not a phoneNav.app -- it doesn't fit the PhoneNav.open_app() path every
	# other tile uses, same reasoning "vfl" above jumps straight to Nav.go_to
	# instead.
	if app_id == "contacts":
		Nav.go_to("contacts")
		return
	PhoneNav.open_app(app_id)


func _vfl_locked() -> bool:
	return not GameState.state["flags"]["archiePartnerSeen"]


func _badge_for(app_id: String) -> bool:
	match app_id:
		"ticker":
			return _has_ticker_rumblings()
		_:
			return false


func _has_ticker_rumblings() -> bool:
	for section in Barometer.SECTIONS:
		if Barometer.trend_hint_state(section) != null:
			return true
	return false


# ── messages (collective1-03: real Messages app) ─────────────────────
# Per-contact conversation screen with a pinned action bar, per spec §5.2.
# 83-contacts-archie-james-sms-port: Archie and James are full members of
# this app now -- their old bespoke SMS screens are gone, and their
# content flows through Messages.append()/queue_pending() like everyone
# else's. 84-contacts-retire-messages-tile: the conversation-list view
# that used to live here (and its own "open a conversation" step) is
# gone -- this app is now reached exclusively via PhoneNav.select_
# conversation(), always with a contact already chosen (ContactCards.
# build_messages_button() on the contact's own Contacts card), so
# selectedContactId is always set by the time this renders.

func _build_messages() -> void:
	var contact_id: String = GameState.state["phoneNav"]["selectedContactId"]
	# Import PhoneNav.select_conversation()'s staged-reveal handoff into the
	# screen-local cache the first time this contact's conversation renders
	# on this screen instance -- once, same as the old _open_conversation()
	# capture (see _reveal_from_index's own comment above).
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
	# 84-contacts-retire-messages-tile: back from a conversation goes to the
	# phone home grid, same as every other app's back button (PhoneNav.
	# back_to_messages()'s "return to the conversation list" behaviour has
	# nowhere left to return to, since that list is gone).
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

	if reveal_from < thread.size():
		_reveal_from_index[contact_id] = thread.size()
		_reveal_remaining(box, thread, reveal_from)


# Staged reveal for newly-arrived messages only -- same 0.6/0.9s
# alternating-delay presentation the old sms_archie.gd screen's
# _reveal_next() used. Guards
# against the box having been freed by a stray _refresh() (some unrelated
# state_changed firing while the player is mid-reveal) rather than
# assuming this is the only thing that can happen between awaits.
func _reveal_remaining(box: VBoxContainer, thread: Array, start_index: int) -> void:
	for i in range(start_index, thread.size()):
		if not is_instance_valid(box):
			return
		box.add_child(UI.message_bubble(thread[i]["text"], thread[i]["from"] == "player"))
		var delay: float = 0.9 if (i - start_index) % 2 == 0 else 0.6
		await get_tree().create_timer(delay).timeout


# Trade stays a modal (spec §5.2: "one trade UI in the game, not two") --
# ContactCards.build_trade_action() opens sell_menu routed through the
# Collective faction lane with the right locked/enabled state (collective1-07,
# spec §7.2), so every conversation's action bar reuses it rather than
# building a second entry point. 83-contacts-archie-james-sms-port: Archie
# and James now reach this function too (their own conversation is a real
# thread, not a bespoke screen), but neither is a Collective door -- Archie
# gets his own build_sell_action() below instead, mirroring his Contacts
# card; James gets neither (his job-offer flow stays card-only, out of this
# ticket's scope). pendingMessages entries for this contact each surface as
# their own button; tapping one resolves the entry and hands its payload to
# Events.start_event() as context, the same road systems/raiding.gd uses for
# a raid's runtime site_id.
func _build_action_bar(contact_id: String) -> Control:
	var bar := UI.vbox(8)
	# 103-phone-shortcut-for-pin-gated-quests: contact_id-agnostic on purpose
	# -- MapPins.active_phone_shortcuts_for() just returns [] for a contact
	# with no active pin-gated event, so a future pin-gated contact needs no
	# new branch here (unlike every per-contact story action below).
	for shortcut in ContactCards.build_pin_shortcut_actions(contact_id):
		bar.add_child(shortcut)
	# collective1-10, spec §7.2: "Story actions (conditional)" are listed
	# ahead of "Standing actions" in the contact action-bar order -- Des's
	# own flag-gated "Tell Des about the ground" button and the generic
	# pendingMessages continues (S4's delivery road) are both story actions,
	# so both come before Trade below.
	if contact_id == "archie":
		var pry_action := ContactCards.build_archie_pry_action()
		if pry_action != null:
			bar.add_child(pry_action)
	if contact_id == "des":
		var report_action := ContactCards.build_des_report_action()
		if report_action != null:
			bar.add_child(report_action)
		# collective1-16, spec §6.15/§7.2: the deferred-join follow-up --
		# permanent once colA1DeferredJoin is set, same slot the report
		# button above occupies.
		var ask_joining_action := ContactCards.build_ask_des_joining_action()
		if ask_joining_action != null:
			bar.add_child(ask_joining_action)
	# collective1-11, spec §6.8/§7.2: Nadia's own "Go and see Nadia" story
	# action, same slot Des's report button occupies above.
	if contact_id == "nadia":
		var meet_action := ContactCards.build_nadia_meet_action()
		if meet_action != null:
			bar.add_child(meet_action)
		# collective1-12, spec §6.9/§7.2: Nadia's "ask" story action, same slot.
		var vein_ask_action := ContactCards.build_nadia_vein_ask_action()
		if vein_ask_action != null:
			bar.add_child(vein_ask_action)
	# collective1-14, spec §6.12/§7.2: Hakim's thread-resolution story action,
	# same slot Des's report button and Nadia's two occupy above.
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


# ── notes (to-do list) ────────────────────────────────────────────────

func _build_notes() -> void:
	_content.add_child(_phone_back_button())
	_content.add_child(UI.heading("Notes"))

	# ticket 79: one section per active questline (tutorial, Collective, any
	# future one) off a single loop -- Todo.get_active_questlines() already
	# grouped and capped the items; this just renders whatever it returns.
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
	_add_skill_row(c["content"], "Crafting", player["craftingSkill"], player["craftingXP"], GameData.CRAFTING_XP_LEVELS)
	_add_skill_row(c["content"], "Cultivating", player["cultivatingSkill"], player["cultivatingXP"], GameData.CULTIVATING_XP_LEVELS)
	_add_skill_row(c["content"], "Stealth", player["stealthSkill"], player["stealthXP"], GameData.STEALTH_XP_LEVELS)
	_add_skill_row(c["content"], "Combat", player["combatSkill"], player["combatXP"], GameData.COMBAT_XP_LEVELS)
	return c["panel"]


# `levels` is indexed by skill level (level 1's threshold at levels[1], per
# Progression.award_xp), so the bar fills from this level's threshold toward
# the next one rather than from 0 -- a level 3 skill sitting just above its
# levels[3] floor should read as an empty bar, not a nearly-full one against
# the 0..levels[max] range. Max level has no next threshold to aim for, so it
# just shows full/capped.
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


# dial-device ticket 07: replaces _equipped_device_label -- the Dial is
# lifetime-owned, not equipped/unequipped, so this is a read-only summary
# rather than an "(equipped)" tag (same shape as bag_drawer.gd's own
# duplicate of this label, ported the same way _equipped_weapon_label was).
func _dial_summary_label(player: Dictionary) -> Control:
	var dial: Variant = player["dial"]
	if dial == null:
		return UI.muted_label("Dial: none")
	var movement: Variant = dial["movement"]
	if movement == null:
		return UI.label("Dial: Lv%d — no Movement seated (inert)" % dial["level"])
	var m: Dictionary = GameData.DIAL_MOVEMENTS[movement["archetype"]]
	return UI.label("Dial: Lv%d — %s %s, charge %d/%d" % [dial["level"], m["symbol"], m["name"], int(dial["currentCharge"]), dial["maxCharge"]])


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


# ── Notifications (11-phone-os-shell ticket 10) ──────────────────────
# Browses the full persistent log ticket 04's Notify.push()/dismiss() built
# (GameState.state["notifications"], capped at Notify.LOG_CAP). Mostly
# read-only -- no dismiss control here; `seen` only ever gets flipped by
# tapping a live toast (notification_toast.gd), never from this app. Rendered
# newest first, which for an append-only, cap-evicting-from-the-front array
# just means walking it back to front.
#
# 75-vein-raid-defend-button: the one exception is a pending alarm-raid
# warning (Raiding._queue_defend_raid()'s push carries a `veinId`) -- its row
# gets its own Defend button, the notification-side twin of the vein's own
# Defend button on the site sheet (map.gd's _build_vein_action_card()), so
# the player can jump straight into the fight from here too, no travel
# required. Raiding.is_defend_notification_pending() gates it off again once
# the raid resolves or expires -- scoped to this exact notification, not just
# the vein, so an old already-resolved warning for the same vein (the log is
# capped, not cleared) doesn't reactivate its button once that vein is raided
# again later.

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

	return c["panel"]


# ── Reynard's (bugfixes-38) ──────────────────────────────────────────
# Display-only: a balance readout plus the full transaction log
# systems/bank.gd's Bank.record() builds (GameState.state["bankLog"],
# capped at Bank.LOG_CAP). Read-only, newest first -- same layout
# convention _build_notifications() above uses for its own log. No new
# banking mechanics (interest, loans, transfers) per the ticket.

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
	c["content"].add_child(UI.label("£%d" % GameState.state["player"]["cash"]))
	return c["panel"]


func _build_bank_transaction_row(entry: Dictionary) -> Control:
	var c := UI.card()
	var amount: int = entry["amount"]
	var amount_text: String = "+£%d" % amount if amount >= 0 else "-£%d" % -amount
	c["content"].add_child(UI.label("%s — %s" % [entry["label"], amount_text]))
	c["content"].add_child(UI.muted_label("Day %d" % entry["day"]))
	return c["panel"]


# ── Debug (01-debug-app) ──────────────────────────────────────────────
# Only reachable at all when flags.debugStartUsed is true (PhoneApps.apps()
# leaves the tile out of the grid entirely otherwise) -- this screen itself
# doesn't re-check the flag, same trust-the-grid convention every other app
# case in _refresh()'s match above already follows (e.g. "vfl"'s own lock
# check lives in PhoneApps, not re-derived here). Two simple adjusters land
# in this ticket; tickets 02/03 add more to the same screen.

func _build_debug() -> void:
	_content.add_child(_phone_back_button())
	_content.add_child(UI.heading("Debug"))
	_content.add_child(_build_debug_add_money_card())
	_content.add_child(_build_debug_add_calc_card())
	_content.add_child(_build_debug_spawn_site_card())
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


# 03-debug-app-spawn-unclaimed-site: district/ore/terroir all player-picked
# (Sites.spawn_unclaimed_site() does the actual state append, bypassing
# siteCap entirely) -- terroir options come from GameData.VEIN_GROWTH[
# "terroirYieldMult"]'s keys (poor/fair/rich/saturated), not SITE_TIER_ORDER,
# since barren isn't a seedable terroir and this tool only ever spawns
# seedable, unclaimed sites.
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


# 02-debug-app-relation-adjusters: one card per contact, listed regardless of
# unlocked/recruited state -- a debug tool exists to raise an unmet contact's
# relation past its own recruitThreshold to test recruiting gates, so hiding
# locked contacts here would defeat the purpose. Calls Contacts.award_relation()
# directly (that's the system's existing generic adjuster; no DebugTools
# wrapper needed since, unlike add_cash/add_calc in this same ticket's
# predecessor, there's no raw-field-write gap to fill here).
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


# Same shape as the contact card above, for state.factions instead --
# calls Factions.adjust_player_relation() directly, the system's existing
# player<->faction adjuster (see that function's own comment for why it's
# generic rather than debug-only).
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

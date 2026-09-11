class_name ContactCards
extends RefCounted

# Shared Archie/James/faction card builders — same pattern as UI.gd (static
# funcs building Controls, no node/self dependency). Used by both the
# tutorial-era `contacts`/`factions` screens (still wired into the M0 home
# flow, retirement deferred to ticket 10) and Phone's Messages/Factions
# apps (M1-LONDON.md D4), so the flag-gated logic lives in exactly one
# place instead of drifting between two copies.


static func build_archie_card() -> Control:
	var archie: Dictionary = GameState.state["contacts"]["archie"]

	var c := UI.card()
	c["content"].add_child(UI.heading("Archie — Relation %d" % archie["relation"], 15))
	c["content"].add_child(UI.muted_label("Trader · Whitechapel"))

	for shortcut in build_pin_shortcut_actions("archie"):
		c["content"].add_child(shortcut)

	var pry_action := build_archie_pry_action()
	if pry_action != null:
		c["content"].add_child(pry_action)

	# 83-contacts-archie-james-sms-port: every Archie trigger that used to be
	# a flag-gated card button or a bespoke sms_archie*.gd screen now arrives
	# as a real pendingMessages entry (Economy.execute_sale for archie_motion,
	# TimeSystem's day-tick for the ARCHIE_SMS_2 buyer beat, buyer.json/
	# james_meeting.json's own on_complete for ARCHIE_SMS_1 and the
	# archie_craft_chat beat) -- so one generic "Continue →" loop, same as
	# build_des_card()/build_nadia_card()/build_hakim_card(), covers all of
	# them instead of four bespoke branches.
	for entry in Messages.pending_for("archie"):
		# bugfixes-95: a tag-along deal offer needs its own accept/decline
		# pair, not the generic "Continue →" (which resolves straight into
		# Events.start_event -- this pending kind has no event to start).
		if entry["kind"] == ArchieDeals.PENDING_KIND:
			c["content"].add_child(UI.label(entry["text"]))
			c["content"].add_child(UI.button("Accept", _on_archie_deal_accept.bind(entry)))
			c["content"].add_child(UI.button("Decline", _on_archie_deal_decline.bind(entry)))
		else:
			c["content"].add_child(UI.button("Continue →", _on_pending_action_pressed.bind(entry)))

	c["content"].add_child(build_messages_button("archie"))
	c["content"].add_child(build_sell_action())
	var recruit_row := build_recruit_row("archie")
	if recruit_row != null:
		c["content"].add_child(recruit_row)

	return c["panel"]


# collective1-15, spec §6.13/§7.2: S13, the Archie/Des decoy -- "not a text,
# the player has to go looking", so it surfaces as a plain button on
# Archie's own card rather than through pendingMessages like the row above.
# Available from colA1ArchiePryAvailable (set by S4, col_a1_hub) and
# vanishes once colA1AskedAboutDebt is true (the explanation only needs
# giving once) or colA1Complete (missable — gone once Act 1 ends). Choosing
# "Leave it" leaves both flags false, so the button stays put for a later
# visit -- same "vanish, don't disable" shape build_des_report_action() uses,
# just gated on two flags instead of one.
static func build_archie_pry_action() -> Control:
	var flags: Dictionary = GameState.state["flags"]
	if not flags.get("colA1ArchiePryAvailable", false):
		return null
	if flags.get("colA1AskedAboutDebt", false) or flags.get("colA1Complete", false):
		return null
	return UI.button("Ask about Des", func(): Events.start_event("col_a1_archie_pry"))


static func build_sell_action() -> Control:
	var flags: Dictionary = GameState.state["flags"]
	var player: Dictionary = GameState.state["player"]

	if not flags["buyerEventSeen"]:
		var locked := UI.button("💰 Find a buyer (not unlocked yet)", func(): pass)
		locked.disabled = true
		return locked

	var has_ore := false
	for qty in player["orichalchum"].values():
		if qty > 0:
			has_ore = true
			break
	var has_consumables: bool = flags["canSellConsumables"] and (Crafting.inventory_qty("timePearl") > 0 or Crafting.inventory_qty("enhancementPowder") > 0)
	var has_sellable: bool = has_ore or has_consumables

	var b := UI.button("💰 Find a buyer" if has_sellable else "💰 Find a buyer (nothing to sell)", func(): Modal.open("sell_menu"))
	b.disabled = not has_sellable
	return b


# collective1-07, spec §5.5/§7.2: the cosmetic trade door Des, Nadia and
# Hakim each offer in their action bar -- identical terms and relation award
# regardless of which of the three opens it, since all three route through
# the same faction lane (Economy.execute_faction_sale("collective", ...))
# and the same bark pool draw (systems/collective.gd). Locked (shown-
# disabled, same pattern as build_sell_action() above) until S1 sets
# flags.collectiveLaneUnlocked -- unlike the recruit row, the lane itself is
# fine to show locked rather than suppressed; the player knows it's coming.
static func build_trade_action(contact_id: String) -> Control:
	if not GameState.state["flags"].get("collectiveLaneUnlocked", false):
		var locked := UI.button("🤝 Trade (not unlocked yet)", func(): pass)
		locked.disabled = true
		return locked

	return UI.button("🤝 Trade", func(): Modal.open("sell_menu", { "factionId": "collective", "contactId": contact_id }))


# 103-phone-shortcut-for-pin-gated-quests: a general phone-tab shortcut for
# any quest-giver whose next event is currently gated purely on a map pin
# (systems/map_pins.gd) -- one button per active pin this contact declares
# via "contact"/"phoneLabel" on the event's own pin block, so a future
# pin-gated contact picks this up for free by declaring that data, with no
# new UI code beyond the one call already wired into every build_X_card()
# and phone.gd's _build_action_bar() below. Tapping starts the event
# directly (Events.start_event, same as MapCanvas._activate_pin() does for
# the map-pin tap) -- no travel required -- and the map pin itself is left
# entirely alone, so it keeps working as the alternate path.
static func build_pin_shortcut_actions(contact_id: String) -> Array:
	var actions: Array = []
	for pin in MapPins.active_phone_shortcuts_for(contact_id):
		actions.append(UI.button("📍 %s" % pin["phoneLabel"], func(): Events.start_event(pin["eventId"])))
	return actions


# des-dialogue-turn-in-flow ticket 02: Des's own conditional action bar
# button -- distinct from the generic pendingMessages "Continue →" loop
# (phone.gd's _build_action_bar) because a qualifying site flips silently
# off the objectives engine (Objectives.refresh(), called at Sites.prospect())
# rather than an authored text arriving, so there's no pendingMessages entry
# to hang a button off. Shown the moment ANY required ore type
# (col_a1_des_sites' requireEachOreType) has a currently-qualifying,
# not-yet-reported site -- not gated on colA1DesSitesFound any more, since
# that flag only flips once BOTH are reported (Collective.report_des_site()
# reports one at a time, per des-sites-partial-turnin ticket 01). Returns
# null once colA1DesThreadDone is set, same "vanish, don't disable" shape
# build_recruit_row() uses below.
static func build_des_report_action() -> Control:
	var flags: Dictionary = GameState.state["flags"]
	if flags.get("colA1DesThreadDone", false):
		return null
	var ore_type := Collective.next_reportable_des_ore_type()
	if ore_type == "":
		return null
	return UI.button("Tell Des about the ground", func(): _on_des_report_pressed(ore_type))


# Reports the site (converting it to a Collective vein and awarding relation
# immediately, per Collective.report_des_site()) THEN plays a scene reacting
# to it -- the first-report scene naming whichever ore type is still needed
# if this was only one of the two, or the reworked col_a1_des_report closer
# if this report just completed the objective. Relation is never awarded
# twice: report_des_site() is the only thing that awards it, both here and
# for the closing report, so col_a1_des_report's own on_complete doesn't.
static func _on_des_report_pressed(ore_type: String) -> void:
	var result := Collective.report_des_site(ore_type)
	if not result.get("ok", false):
		return

	if GameState.state["objectives"]["col_a1_des_sites"]["complete"]:
		Events.start_event("col_a1_des_report")
	else:
		Events.start_event("col_a1_des_report_first_%s" % ore_type)


# collective1-11, spec §6.8/§7.2: Nadia's own conditional action bar button
# -- same "vanish once played" shape build_des_report_action() above uses,
# but gated on colA1NadiaMet itself (the event's own on_complete flag)
# rather than a separate objective-completion flag, since S8 has no
# prerequisite objective of its own to wait on -- it's reachable the moment
# Nadia unlocks (S4, col_a1_hub). colA1NadiaMet doubles as col_a1_nadia_
# supply's activateFlag (data/objectives.json), the same one-flag-does-both
# shape colA1DesThreadActive/colA1HubReached already use for the other two
# S4 objectives.
static func build_nadia_meet_action() -> Control:
	if GameState.state["flags"].get("colA1NadiaMet", false):
		return null
	return UI.button("Go and see Nadia", func(): Events.start_event("col_a1_nadia_meet"))


# collective1-12, spec §6.9/§7.2: Nadia's "ask" story action -- same
# "vanish, don't disable" shape build_des_report_action()/build_nadia_meet_
# action() above use, but gated on colA1NadiaSupplied (col_a1_nadia_supply's
# completeFlag) rather than a static unlock, and vanishes once colA1Nadia
# AskSeen (this event's own on_complete flag) is set rather than a separate
# thread-done flag -- S10 (col_a1_nadia_done) is what actually closes the
# thread, and it fires automatically off the qualifying sale, not from here.
static func build_nadia_vein_ask_action() -> Control:
	var flags: Dictionary = GameState.state["flags"]
	if not flags.get("colA1NadiaSupplied", false) or flags.get("colA1NadiaAskSeen", false):
		return null
	return UI.button("Nadia has an idea", func(): Events.start_event("col_a1_nadia_vein"))


# collective1-14, spec §6.12/§7.2: Hakim's thread-resolution story action --
# same "vanish, don't disable" shape build_des_report_action() above uses,
# gated on colA1HakimRescued (col_a1_hakim_rescue's completeFlag, spec
# §6.12's delivery) rather than a separate objective-completion flag, and
# vanishing once colA1HakimThreadDone (this event's own on_complete flag)
# is set, same as the other two thread-resolution actions.
static func build_hakim_done_action() -> Control:
	var flags: Dictionary = GameState.state["flags"]
	if not flags.get("colA1HakimRescued", false) or flags.get("colA1HakimThreadDone", false):
		return null
	return UI.button("Hand Hakim's vein back", func(): Events.start_event("col_a1_hakim_done"))


# collective1-16, spec §6.15/§7.2/§8.6: the deferred-join follow-up -- S14's
# "Not yet" leaves this a permanent action on Des's card (not "vanish, don't
# disable" like the other story actions above; declining is not a failure
# state and the offer explicitly doesn't expire) until colA1Joined lands via
# the short col_a1_deferred_join event.
static func build_ask_des_joining_action() -> Control:
	var flags: Dictionary = GameState.state["flags"]
	if not flags.get("colA1DeferredJoin", false) or flags.get("colA1Joined", false):
		return null
	return UI.button("Ask Des about joining", func(): Events.start_event("col_a1_deferred_join"))


# 82-contacts-des-nadia-hakim-cards: opens the contact's existing conversation
# thread -- the same generic renderer phone.gd's _build_conversation already
# builds (Messages app), reused rather than rebuilt. This is Nav.go_to +
# PhoneNav.select_conversation, the same two-step every conversation opens
# with now (84-contacts-retire-messages-tile: including the staged-reveal
# handoff, since select_conversation() itself computes and stashes that --
# see its own comment -- rather than the phone screen capturing it, so this
# works even though the phone screen isn't mounted yet when this runs).
static func build_messages_button(contact_id: String) -> Control:
	var text := "💬 Messages"
	if Messages.has_unread(contact_id):
		text += " ●"
	return UI.button(text, func():
		Nav.go_to("phone")
		PhoneNav.select_conversation(contact_id)
	)


# 82-contacts-des-nadia-hakim-cards: the generic pendingMessages continue --
# same "story action" phone.gd's own _build_action_bar() comment classes
# pendingMessages continues as (grouped with the flag-driven story actions,
# ahead of Trade), and the same shape build_archie_card()'s own pending loop
# above uses, just with the generic "Continue →" label phone.gd's action bar
# uses instead of one-off flavour text -- Des/Nadia/Hakim's pendingMessages
# entries vary in kind (col_a1_hub, col_a1_closer, col_hakim_intel, ...)
# unlike Archie's single hardcoded S1 case, so there's no one flavour line to
# hardcode here.
static func _on_pending_action_pressed(entry: Dictionary) -> void:
	Messages.resolve_pending(entry["id"])
	Events.start_event(entry["kind"], entry["payload"])


# bugfixes-95: accept/decline for Archie's tag-along deal offer, the two
# button handlers build_archie_card()'s pending-message loop above binds.
static func _on_archie_deal_accept(entry: Dictionary) -> void:
	ArchieDeals.accept_deal(entry["id"])


static func _on_archie_deal_decline(entry: Dictionary) -> void:
	ArchieDeals.decline_deal(entry["id"])


static func build_recruit_row(contact_id: String) -> Control:
	var c: Dictionary = GameState.state["contacts"][contact_id]
	var display_name: String = Contacts.display_name(contact_id)

	# collective1-07, spec §7.1: Des/Nadia/Hakim's recruit row must not be
	# shown at all -- not shown-disabled -- so callers get null back and are
	# expected to skip adding it, rather than a locked/disabled button.
	if not c.get("recruitable", true):
		return null

	if c["recruited"]:
		var done_button := UI.button("✅ %s recruited" % display_name, func(): pass)
		done_button.disabled = true
		return done_button

	if Contacts.can_recruit(contact_id):
		return UI.button("⭐ Recruit %s" % display_name, func(): Contacts.recruit(contact_id))

	var needed: int = c["recruitThreshold"] - c["relation"]
	var locked := UI.button("⭐ Recruit %s (%d relation needed)" % [display_name, needed], func(): pass)
	locked.disabled = true
	return locked


static func build_james_card() -> Control:
	var flags: Dictionary = GameState.state["flags"]
	var james: Dictionary = GameState.state["contacts"]["james"]

	var c := UI.card()
	c["content"].add_child(UI.heading("James — Relation %d" % james["relation"], 15))
	c["content"].add_child(UI.muted_label("Craftsman · Bermondsey"))

	for shortcut in build_pin_shortcut_actions("james"):
		c["content"].add_child(shortcut)

	# 83-contacts-archie-james-sms-port: the "visit James" trigger used to be
	# a flag-gated card button (archieMotionEventSeen && !jamesMotionEventSeen);
	# it now arrives as a real pendingMessages entry (archie_motion.json's
	# on_complete queues it), so the generic Continue loop covers it -- same
	# shape build_archie_card()'s own loop uses. James's job-offer flow below
	# (📋/💷/📦) is a separate mechanic, not SMS content, and is untouched.
	for entry in Messages.pending_for("james"):
		c["content"].add_child(UI.button("Continue →", _on_pending_action_pressed.bind(entry)))

	c["content"].add_child(build_messages_button("james"))

	if flags["jamesMotionEventSeen"]:
		var job_active: bool = flags["jamesJobActive"] and GameState.state["jamesJob"] != null
		if job_active:
			var job: Dictionary = GameState.state["jamesJob"]
			if not flags["jamesJobAccepted"]:
				c["content"].add_child(UI.button("📋 James has work for you", func(): Modal.open("james_job_offer", { "job": job })))
			elif job["type"] == "flatPay":
				c["content"].add_child(UI.button("💷 Do the job (£%d)" % job["pay"], func(): Jobs.fulfil_job()))
			else:
				c["content"].add_child(UI.symbol_button(["📦 Deliver job: %d× " % job["qty"], { "symbol": job["symbol"], "fallback": SymbolGlyph.generic_fallback() }, " %s" % job["recipeName"]], func(): Jobs.fulfil_job()))

	var recruit_row := build_recruit_row("james")
	if recruit_row != null:
		c["content"].add_child(recruit_row)

	return c["panel"]


# 82-contacts-des-nadia-hakim-cards: gives Des, Nadia and Hakim their own
# Contacts card, same recruit-row/standing-action/story-action pattern
# build_archie_card()/build_james_card() above use -- step one of
# consolidating messaging onto Contacts (spec: doesn't touch Archie/James's
# bespoke SMS screens or remove the top-level Messages tile). Story actions
# reuse the exact builders phone.gd's own _build_action_bar() already calls
# for each contact's conversation-thread action bar, so the two surfaces
# never drift. Card-line strings ("Prospector · Crystal Palace" etc.) are
# collective-act1/spec.md §3.1-3.3's canonical "Card line" text.
static func build_des_card() -> Control:
	var des: Dictionary = GameState.state["contacts"]["des"]

	var c := UI.card()
	c["content"].add_child(UI.heading("Des — Relation %d" % des["relation"], 15))
	c["content"].add_child(UI.muted_label("Prospector · Crystal Palace"))

	for shortcut in build_pin_shortcut_actions("des"):
		c["content"].add_child(shortcut)

	var report_action := build_des_report_action()
	if report_action != null:
		c["content"].add_child(report_action)
	var ask_joining_action := build_ask_des_joining_action()
	if ask_joining_action != null:
		c["content"].add_child(ask_joining_action)
	for entry in Messages.pending_for("des"):
		c["content"].add_child(UI.button("Continue →", _on_pending_action_pressed.bind(entry)))

	c["content"].add_child(build_messages_button("des"))
	c["content"].add_child(build_trade_action("des"))
	var recruit_row := build_recruit_row("des")
	if recruit_row != null:
		c["content"].add_child(recruit_row)

	return c["panel"]


static func build_nadia_card() -> Control:
	var nadia: Dictionary = GameState.state["contacts"]["nadia"]

	var c := UI.card()
	c["content"].add_child(UI.heading("Nadia — Relation %d" % nadia["relation"], 15))
	c["content"].add_child(UI.muted_label("Fixer · Hackney"))

	for shortcut in build_pin_shortcut_actions("nadia"):
		c["content"].add_child(shortcut)

	var meet_action := build_nadia_meet_action()
	if meet_action != null:
		c["content"].add_child(meet_action)
	var vein_ask_action := build_nadia_vein_ask_action()
	if vein_ask_action != null:
		c["content"].add_child(vein_ask_action)
	for entry in Messages.pending_for("nadia"):
		c["content"].add_child(UI.button("Continue →", _on_pending_action_pressed.bind(entry)))

	c["content"].add_child(build_messages_button("nadia"))
	c["content"].add_child(build_trade_action("nadia"))
	var recruit_row := build_recruit_row("nadia")
	if recruit_row != null:
		c["content"].add_child(recruit_row)

	return c["panel"]


static func build_hakim_card() -> Control:
	var hakim: Dictionary = GameState.state["contacts"]["hakim"]

	var c := UI.card()
	c["content"].add_child(UI.heading("Hakim — Relation %d" % hakim["relation"], 15))
	c["content"].add_child(UI.muted_label("Newsagent · Whitechapel"))

	for shortcut in build_pin_shortcut_actions("hakim"):
		c["content"].add_child(shortcut)

	var done_action := build_hakim_done_action()
	if done_action != null:
		c["content"].add_child(done_action)
	for entry in Messages.pending_for("hakim"):
		c["content"].add_child(UI.button("Continue →", _on_pending_action_pressed.bind(entry)))

	c["content"].add_child(build_messages_button("hakim"))
	c["content"].add_child(build_trade_action("hakim"))
	var recruit_row := build_recruit_row("hakim")
	if recruit_row != null:
		c["content"].add_child(recruit_row)

	return c["panel"]


# 08-family-2-chrome-contacts, ui-vision.md §10: repaints an already-built
# Contacts subtree (contacts.gd's own back/heading row plus every card this
# file builds) into Family 2's dark "device shell" chrome, in one recursive
# pass over the finished node tree rather than threading colour choices
# through each build_*_card()/build_*_action() call site above -- those stay
# untouched, so the only change here is paint. `root` is typically
# ContactsScreen's own `_content` VBoxContainer, called once after every
# card for the current refresh has been added.
#
# 09-family-2-chrome-phone-apps: also the one recolour pass scenes/screens/
# phone.gd's own _refresh()/_build_conversation() run over every app it
# builds (Notes, Factions, Ticker, Profile, Save/Load, Notifications,
# Reynard's, Harrow's, Messages) -- ContactCards is where ticket 08 already
# put this "generic Family 2 repaint" utility (its own doc comment already
# framed it that way), so extending it here rather than forking a second
# copy into phone.gd keeps the paint rules in one place. The three additions
# this ticket needs on top of ticket 08's version: ProgressBar fill/track
# colouring (every Family 2 meter is ink, never ui_action_red -- §10's
# generalised "accent marks actionable elements only" rule), a smarter Label
# heuristic that can tell a deliberately-tinted label (UI.tinted_label(),
# e.g. a calc_gold £ figure) apart from a plain UI.muted_label() instead of
# treating "has any colour override at all" as proof of the latter, and a
# message-bubble special case for the PanelContainer branch (Contacts' own
# subtree never reaches UI.message_bubble()'s output, phone.gd's Messages
# app does).
#
# Deliberately NOT wired into build_faction_card() below -- that builder
# still serves the (untouched, cream) Factions screen this ticket doesn't
# cover, and PanelContainer/Label/Button here would repaint it too if this
# walk ever reached it. (phone.gd's own _build_factions() reaches the same
# builder through a different, Family-2-painted screen -- see that file's
# own comment; the two call sites build two separate node trees, so this
# doesn't leak between them.)
const _PHONE_BG_HOME := "phone_bg_home"
const _PHONE_BG_CONTENT := "phone_bg_content"
const _PHONE_DIVIDER := "phone_divider"
const _PHONE_TEXT_PRIMARY := "phone_text_primary"
const _PHONE_TEXT_MUTED := "phone_text_muted"
const _PHONE_BUBBLE_INCOMING := "phone_bubble_incoming"

# Fallbacks mirror nav_bar.gd's own GameData.PALETTE.get(id, fallback)
# pattern -- only exercised if data/palette.json is somehow missing an id.
const _FALLBACK_BG_HOME := Color("#1b1b1d")
const _FALLBACK_BG_CONTENT := Color("#252528")
const _FALLBACK_DIVIDER := Color("#424246")
const _FALLBACK_TEXT_PRIMARY := Color("#ededee")
const _FALLBACK_TEXT_MUTED := Color("#999a9d")
const _FALLBACK_ACTION := Color("#c8102e")
const _FALLBACK_BUBBLE_INCOMING := Color("#333336")

# UI.muted_label()'s own hardcoded grey (ui.gd), the one signal this walk
# uses to tell "a plain muted_label()" apart from "a deliberately tinted
# label" below -- kept as a value comparison (is_equal_approx), not identity,
# since ui.gd bakes this exact Color literal at construction time rather
# than pulling it from GameData.PALETTE itself.
const _GLOBAL_MUTED_GREY := Color(0.541176, 0.541176, 0.541176, 1)


static func _palette(id: String, fallback: Color) -> Color:
	return GameData.PALETTE.get(id, fallback)


static func apply_phone_os_chrome(root: Node) -> void:
	_style_subtree(root, false)


# `inside_button`: once the walk enters a Button, that button's own
# _style_button() call below has already repainted every Label/SymbolGlyph
# under it directly (so symbol_button()'s inner glyph+text row, not just the
# Button's own text, gets the right colour) -- the generic Label branch is
# skipped for the rest of that subtree so it can't clobber that choice with
# the plain-label primary/muted heuristic.
static func _style_subtree(node: Node, inside_button: bool) -> void:
	var next_inside_button := inside_button
	if node is PanelContainer:
		_style_panel(node as PanelContainer)
	elif node is Button:
		_style_button(node as Button)
		next_inside_button = true
	elif node is Label and not inside_button:
		_style_label(node as Label)
	elif node is ProgressBar:
		_style_progress_bar(node as ProgressBar)

	for child in node.get_children():
		_style_subtree(child, next_inside_button)


# 09-family-2-chrome-phone-apps: a PanelContainer whose direct parent is an
# HBoxContainer is, on every reachable path this walk ever sees, UI.
# message_bubble()'s own `row -> card()["panel"]` structure -- no other
# builder either file calls wraps a card() panel in an hbox row. Outgoing
# (from_player) sets the row's alignment to ALIGNMENT_END (ui.gd); an
# ordinary card (added straight into a VBoxContainer, the overwhelming
# common case) has no HBoxContainer parent at all, so it still falls through
# to the plain content-panel treatment below.
static func _style_panel(panel: PanelContainer) -> void:
	var parent := panel.get_parent()
	if parent is HBoxContainer:
		_style_bubble_panel(panel, (parent as HBoxContainer).alignment == BoxContainer.ALIGNMENT_END)
	else:
		_style_card_panel(panel)


static func _style_card_panel(panel: PanelContainer) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = _palette(_PHONE_BG_CONTENT, _FALLBACK_BG_CONTENT)
	style.border_color = _palette(_PHONE_DIVIDER, _FALLBACK_DIVIDER)
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.content_margin_left = 16
	style.content_margin_top = 16
	style.content_margin_right = 16
	style.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", style)


# §10: "outgoing bubble filled ui_action_red (light text), incoming bubble
# flat dark-grey fill... light text -- ordinary two-party messaging
# convention, no new accent needed." Bubble text itself needs no special
# case here -- it's a plain UI.label() with no pre-existing override, so
# _style_label()'s own "no override -> primary ink" branch already paints it
# light, correct against either fill.
static func _style_bubble_panel(panel: PanelContainer, outgoing: bool) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = _palette("ui_action_red", _FALLBACK_ACTION) if outgoing else _palette(_PHONE_BUBBLE_INCOMING, _FALLBACK_BUBBLE_INCOMING)
	style.set_corner_radius_all(14)
	style.content_margin_left = 14
	style.content_margin_top = 10
	style.content_margin_right = 14
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)


# §10: "ui_action_red marks actionable elements only, never a passive data
# readout" -- generalised to every meter this family renders (Factions'
# reputation bar, the Ticker's per-state progress bars, Profile's HP/skill
# bars): the fill is always ink, never the action accent.
static func _style_progress_bar(bar: ProgressBar) -> void:
	var fill := StyleBoxFlat.new()
	fill.bg_color = _palette(_PHONE_TEXT_PRIMARY, _FALLBACK_TEXT_PRIMARY)
	fill.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("fill", fill)

	var track := StyleBoxFlat.new()
	track.bg_color = _palette(_PHONE_DIVIDER, _FALLBACK_DIVIDER)
	track.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("background", track)


# UI.muted_label() is the only helper above that pre-applies its own
# font_color override using this exact grey; heading()/label() never do.
# 09-family-2-chrome-phone-apps: phone.gd's apps also reach UI.tinted_label()
# (calc_gold £ figures -- Reynard's balance/log, faction swatch colours on
# build_faction_card() were already excluded above) with a DIFFERENT
# pre-existing override, which must survive this pass untouched rather than
# being reclassified as "muted" the way a blind has_theme_color_override()
# check would -- comparing the actual colour value against the known global
# muted grey is what tells the two apart.
static func _style_label(l: Label) -> void:
	if l.has_theme_color_override("font_color"):
		if l.get_theme_color("font_color").is_equal_approx(_GLOBAL_MUTED_GREY):
			l.add_theme_color_override("font_color", _palette(_PHONE_TEXT_MUTED, _FALLBACK_TEXT_MUTED))
		# else: a deliberate tint (calc_gold, a faction swatch) -- leave it
		# exactly as authored; this walk only ever replaces the two shared
		# "ink"/"muted" defaults, never a colour a builder chose on purpose.
	else:
		l.add_theme_color_override("font_color", _palette(_PHONE_TEXT_PRIMARY, _FALLBACK_TEXT_PRIMARY))


static func _style_button(b: Button) -> void:
	if b.disabled:
		_style_outline_button(b)
	else:
		_style_filled_button(b)


# §10: "ui_action_red marks actionable elements only" -- every enabled
# button on this screen (Continue, Messages, Trade, Recruit, story actions,
# pin shortcuts, Accept/Decline) is exactly that, so one filled treatment
# covers all of them.
static func _style_filled_button(b: Button) -> void:
	var accent := _palette("ui_action_red", _FALLBACK_ACTION)
	var text_colour := _palette(_PHONE_TEXT_PRIMARY, _FALLBACK_TEXT_PRIMARY)
	b.add_theme_stylebox_override("normal", _button_fill_style(accent))
	b.add_theme_stylebox_override("hover", _button_fill_style(accent.lightened(0.12)))
	b.add_theme_stylebox_override("pressed", _button_fill_style(accent.darkened(0.15)))
	b.add_theme_color_override("font_color", text_colour)
	b.add_theme_color_override("font_hover_color", text_colour)
	b.add_theme_color_override("font_pressed_color", text_colour)
	_recolor_button_content(b, text_colour)


# Applies §10's Save/Load precedent ("de-emphasis via weight, not colour")
# to every disabled button here (locked, e.g. "not unlocked yet", or
# already-done, e.g. "✅ Archie recruited"), not just the enabled-but-
# destructive case that precedent was written for -- a disabled button gets
# a hairline outline instead of a second accent, never a filled
# ui_action_red, on the same "don't invent a second accent for de-emphasis"
# principle.
static func _style_outline_button(b: Button) -> void:
	var muted := _palette(_PHONE_TEXT_MUTED, _FALLBACK_TEXT_MUTED)
	var style := _button_fill_style(Color(0, 0, 0, 0))
	style.border_color = _palette(_PHONE_DIVIDER, _FALLBACK_DIVIDER)
	style.set_border_width_all(1)
	b.add_theme_stylebox_override("disabled", style)
	b.add_theme_color_override("font_disabled_color", muted)
	_recolor_button_content(b, muted)


static func _button_fill_style(fill: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.content_margin_left = 16
	style.content_margin_top = 10
	style.content_margin_right = 16
	style.content_margin_bottom = 10
	style.set_corner_radius_all(8)
	return style


# UI.symbol_button() (James's delivery-job button) bakes its own font_color
# override straight onto the Label/SymbolGlyph parts inside its inner row at
# construction time (ui.gd's own _symbol_part()), rather than relying on the
# Button's theme colours the way a plain UI.button() text label does -- so
# repainting the Button's own font_color overrides above isn't enough to
# keep that row legible against the new fill; its own children need the
# same colour applied directly.
static func _recolor_button_content(b: Button, colour: Color) -> void:
	for l in b.find_children("", "Label", true, false):
		(l as Label).add_theme_color_override("font_color", colour)
	for g in b.find_children("", "SymbolGlyph", true, false):
		(g as SymbolGlyph).color = colour


static func build_faction_card(faction_id: String) -> Control:
	var f: Dictionary = GameData.FACTIONS[faction_id]
	var state: Dictionary = GameState.state["factions"][faction_id]
	var rel: int = state["relation"]

	var c := UI.card()
	c["content"].add_child(UI.heading(f["name"] + (" — Member" if state["joined"] else ""), 15))
	c["content"].add_child(UI.muted_label(f["tagline"]))
	c["content"].add_child(UI.label(f["description"]))
	c["content"].add_child(UI.label("Relation: %d / %d" % [rel, f["joinRelation"]]))
	c["content"].add_child(UI.bar(rel, f["joinRelation"]))

	# bugfixes-29: always shown, not just for members -- the marketplace
	# screen itself is what shows the locked state for non-members, so a
	# non-member can still find and tap into it rather than the button
	# simply not existing.
	if faction_id == "guild":
		c["content"].add_child(UI.button("Guild Marketplace", func(): Nav.go_to("guild_marketplace")))

	# collective1-16, spec §8.6: the Collective has no generic Join
	# affordance at all -- membership is granted only by S14's choice card
	# (col_a1_closer) or its deferred-join follow-up (ContactCards.
	# build_ask_des_joining_action()), never by a button on this card. The
	# other four factions keep the button until their own storylines land.
	if state["joined"]:
		var member_label := UI.button("✅ Member", func(): pass)
		member_label.disabled = true
		c["content"].add_child(member_label)
	elif faction_id == "collective":
		pass
	elif Factions.can_join(faction_id):
		c["content"].add_child(UI.button("Join %s" % f["name"], func(): Factions.join(faction_id)))
	else:
		var locked := UI.button("Need %d more relation" % (f["joinRelation"] - rel), func(): pass)
		locked.disabled = true
		c["content"].add_child(locked)

	return c["panel"]

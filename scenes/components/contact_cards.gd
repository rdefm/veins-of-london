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


# collective1-10, spec §6.7/§7.2: Des's own conditional action bar button --
# distinct from the generic pendingMessages "Continue →" loop
# (phone.gd's _build_action_bar) because colA1DesSitesFound flips silently
# off the objectives engine (Objectives.refresh(), called at Sites.prospect())
# rather than an authored text arriving, so there's no pendingMessages entry
# to hang a button off. Returns null once colA1DesThreadDone is set, same
# "vanish, don't disable" shape build_recruit_row() uses below.
static func build_des_report_action() -> Control:
	var flags: Dictionary = GameState.state["flags"]
	if not flags.get("colA1DesSitesFound", false) or flags.get("colA1DesThreadDone", false):
		return null
	return UI.button("Tell Des about the ground", func(): Events.start_event("col_a1_des_report"))


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
				c["content"].add_child(UI.button("📦 Deliver job: %d× %s %s" % [job["qty"], job["symbol"], job["recipeName"]], func(): Jobs.fulfil_job()))

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

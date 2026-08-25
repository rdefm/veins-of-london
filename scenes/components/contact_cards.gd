class_name ContactCards
extends RefCounted

# Shared Archie/James/faction card builders — same pattern as UI.gd (static
# funcs building Controls, no node/self dependency). Used by both the
# tutorial-era `contacts`/`factions` screens (still wired into the M0 home
# flow, retirement deferred to ticket 10) and Phone's Messages/Factions
# apps (M1-LONDON.md D4), so the flag-gated logic lives in exactly one
# place instead of drifting between two copies.


static func build_archie_card() -> Control:
	var flags: Dictionary = GameState.state["flags"]
	var world: Dictionary = GameState.state["world"]
	var archie: Dictionary = GameState.state["contacts"]["archie"]

	var c := UI.card()
	c["content"].add_child(UI.heading("Archie — Relation %d" % archie["relation"], 15))
	c["content"].add_child(UI.muted_label("Trader · Whitechapel"))

	if flags["archieMotionPending"] and not flags["archieMotionEventSeen"]:
		c["content"].add_child(UI.button("💬 Archie texted — diversify", func(): Events.start_event("archie_motion")))

	if flags["tutorialStage"] == "archie_craft_chat" and not flags["archieCraftChatSeen"]:
		c["content"].add_child(UI.button("💬 Archie wants to meet", func(): Events.start_event("archie_craft_chat")))

	if flags["tutorialStage"] == "buyer_event" and not flags["buyerEventSeen"] and world["day"] >= 2:
		c["content"].add_child(UI.button("💬 Archie texted — buyer tonight", func(): Nav.go_to("sms_archie_2")))

	if flags["tutorialStage"] == "sms_archie":
		c["content"].add_child(UI.button("💬 Message Archie — set up James meeting", func(): Nav.go_to("sms_archie")))

	# collective1-08, spec §6.1: S1 (col_a1_intro) is delivered as an Archie
	# text via the real pendingMessages road (Messages.queue_pending, from
	# archie_cultivation.json's on_complete) so the Messages app still badges
	# per spec §5.3 -- but Archie himself stays off the new Messages app
	# (§5.2), so the action this pending entry unlocks has to surface here,
	# on his existing Contacts card, mirroring the flag-driven buttons above.
	for entry in Messages.pending_for("archie"):
		c["content"].add_child(UI.button("💬 Archie texted — come to the lock-up", _on_archie_pending_pressed.bind(entry)))

	var pry_action := build_archie_pry_action()
	if pry_action != null:
		c["content"].add_child(pry_action)

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


static func _on_archie_pending_pressed(entry: Dictionary) -> void:
	Messages.resolve_pending(entry["id"])
	Events.start_event(entry["kind"], entry["payload"])


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

	if flags["archieMotionEventSeen"] and not flags["jamesMotionEventSeen"]:
		c["content"].add_child(UI.button("💬 Visit James — ask about new recipes", func(): Events.start_event("james_motion")))

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

	if state["joined"]:
		var member_label := UI.button("✅ Member", func(): pass)
		member_label.disabled = true
		c["content"].add_child(member_label)
	elif Factions.can_join(faction_id):
		c["content"].add_child(UI.button("Join %s" % f["name"], func(): Factions.join(faction_id)))
	else:
		var locked := UI.button("Need %d more relation" % (f["joinRelation"] - rel), func(): pass)
		locked.disabled = true
		c["content"].add_child(locked)

	return c["panel"]

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

	c["content"].add_child(build_sell_action())
	c["content"].add_child(build_recruit_row("archie"))

	return c["panel"]


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
	var has_consumables: bool = flags["canSellConsumables"] and (player["inventory"]["timePearl"] > 0 or player["inventory"]["enhancementPowder"] > 0)
	var has_sellable: bool = has_ore or has_consumables

	var b := UI.button("💰 Find a buyer" if has_sellable else "💰 Find a buyer (nothing to sell)", func(): Modal.open("sell_menu"))
	b.disabled = not has_sellable
	return b


static func build_recruit_row(contact_id: String) -> Control:
	var c: Dictionary = GameState.state["contacts"][contact_id]
	var display_name: String = Contacts.display_name(contact_id)

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

	c["content"].add_child(build_recruit_row("james"))

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

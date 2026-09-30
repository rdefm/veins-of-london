# Peace talks with one faction (R§3.1 "Negotiation"): the faction's
# standing terms with an accept button, then the player's draft — truce
# days, one-off and weekly cash each way, veins each way — and Propose.
# Every change goes through FactionAI; closing leaves the talks open.
class_name NegotiationModal
extends RefCounted


static func build(container: VBoxContainer, _data: Dictionary) -> void:
	var talks := FactionAI.negotiation()
	if talks.is_empty():
		Modal.close()
		return
	var faction_id: String = talks["factionId"]
	var cfg: Dictionary = GameData.FACTION_WAR["negotiation"]
	container.add_child(UI.heading("Talks with %s" % GameData.FACTIONS[faction_id]["shortName"]))
	if talks["final"]:
		container.add_child(UI.muted_label("Their last word. Sign it."))
	else:
		container.add_child(UI.muted_label("Round %d of %d." % [int(talks["round"]), int(cfg["maxRounds"])]))
	if talks["binding"]:
		container.add_child(UI.muted_label("You can't walk away from this one."))

	var counter: Dictionary = talks["counter"]
	if not counter.is_empty():
		if int(talks["round"]) > 1 or talks["final"]:
			container.add_child(UI.label(cfg["lines"]["countered"]))
		container.add_child(UI.heading("Their terms", 15))
		for line in _summary(faction_id, counter):
			container.add_child(UI.label(line))
		container.add_child(MapCardStyle.text_button("Accept their terms", func(): _report(FactionAI.accept_counter())))

	if not talks["final"]:
		_build_draft(container, faction_id, talks["draft"], cfg)

	var footer: Array = [MapCardStyle.text_button("Close", func(): Modal.close())]
	if not talks["binding"]:
		footer.append(MapCardStyle.text_button("Walk away", func(): _report(FactionAI.abandon_talks())))
	if not talks["final"]:
		footer.append(MapCardStyle.text_button("Propose", func(): _report(FactionAI.propose_terms())))
	container.add_child(MapCardStyle.footer(footer))


static func _build_draft(container: VBoxContainer, faction_id: String, draft: Dictionary, cfg: Dictionary) -> void:
	container.add_child(UI.heading("Your terms", 15))
	var days_step := int(cfg["truceDays"]["step"])
	container.add_child(_stepper("Truce: %d days" % int(draft[FactionAI.TERM_TRUCE_DAYS]), FactionAI.TERM_TRUCE_DAYS, int(draft[FactionAI.TERM_TRUCE_DAYS]), days_step))
	var cash_step := int(cfg["cashStep"])
	var weekly_step := int(cfg["weeklyStep"])
	container.add_child(_stepper("You pay now: £%d" % int(draft[FactionAI.TERM_CASH_TO_FACTION]), FactionAI.TERM_CASH_TO_FACTION, int(draft[FactionAI.TERM_CASH_TO_FACTION]), cash_step))
	container.add_child(_stepper("They pay now: £%d" % int(draft[FactionAI.TERM_CASH_TO_PLAYER]), FactionAI.TERM_CASH_TO_PLAYER, int(draft[FactionAI.TERM_CASH_TO_PLAYER]), cash_step))
	container.add_child(_stepper("You pay weekly: £%d" % int(draft[FactionAI.TERM_WEEKLY_TO_FACTION]), FactionAI.TERM_WEEKLY_TO_FACTION, int(draft[FactionAI.TERM_WEEKLY_TO_FACTION]), weekly_step))
	container.add_child(_stepper("They pay weekly: £%d" % int(draft[FactionAI.TERM_WEEKLY_TO_PLAYER]), FactionAI.TERM_WEEKLY_TO_PLAYER, int(draft[FactionAI.TERM_WEEKLY_TO_PLAYER]), weekly_step))
	_vein_toggles(container, "Veins you hand over", FactionAI.player_tradeable_veins(), draft[FactionAI.TERM_VEINS_TO_FACTION], FactionAI.TERM_VEINS_TO_FACTION)
	_vein_toggles(container, "Veins they hand over", FactionAI.faction_tradeable_veins(faction_id), draft[FactionAI.TERM_VEINS_TO_PLAYER], FactionAI.TERM_VEINS_TO_PLAYER)


static func _stepper(text: String, key: String, value: int, step: int) -> Control:
	var row := UI.hbox(4)
	row.add_child(UI.expand_fill(UI.label(text)))
	row.add_child(UI.button("−", func(): FactionAI.set_draft_term(key, value - step)))
	row.add_child(UI.button("+", func(): FactionAI.set_draft_term(key, value + step)))
	return row


static func _vein_toggles(container: VBoxContainer, title: String, veins: Array, chosen: Array, key: String) -> void:
	if veins.is_empty():
		return
	container.add_child(UI.muted_label(title))
	for vein in veins:
		var vein_id: String = vein["id"]
		var mark := "☑" if chosen.has(vein_id) else "☐"
		container.add_child(UI.button("%s %s" % [mark, _vein_name(vein)], func(): FactionAI.toggle_draft_vein(key, vein_id)))


static func _vein_name(vein: Dictionary) -> String:
	return "%s · %s" % [GameData.ORE_TYPES[vein["oreType"]]["name"], GameData.DISTRICTS[vein["district"]]["name"]]


# One line per non-empty term.
static func _summary(faction_id: String, terms: Dictionary) -> Array:
	var lines := ["Truce: %d days" % int(terms[FactionAI.TERM_TRUCE_DAYS])]
	var money := [[FactionAI.TERM_CASH_TO_FACTION, "You pay now: £%d"], [FactionAI.TERM_CASH_TO_PLAYER, "They pay now: £%d"],
		[FactionAI.TERM_WEEKLY_TO_FACTION, "You pay weekly: £%d"], [FactionAI.TERM_WEEKLY_TO_PLAYER, "They pay weekly: £%d"]]
	for entry in money:
		if int(terms[entry[0]]) > 0:
			lines.append(entry[1] % int(terms[entry[0]]))
	var by_id := {}
	for vein in FactionAI.player_tradeable_veins() + FactionAI.faction_tradeable_veins(faction_id):
		by_id[vein["id"]] = vein
	for vein_id in terms[FactionAI.TERM_VEINS_TO_FACTION]:
		if by_id.has(vein_id):
			lines.append("You hand over: %s" % _vein_name(by_id[vein_id]))
	for vein_id in terms[FactionAI.TERM_VEINS_TO_PLAYER]:
		if by_id.has(vein_id):
			lines.append("They hand over: %s" % _vein_name(by_id[vein_id]))
	return lines


static func _report(result: Dictionary) -> void:
	if not result.get("ok", false):
		Notify.push(result.get("reason", ""), Notify.CATEGORY_WARNING)

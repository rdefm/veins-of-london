class_name Collective
extends RefCounted

# collective1-07, spec §5.5/§7.2/§9.5: Des, Nadia and Hakim are three
# cosmetic doors onto one lane -- identical price and identical relation
# award, because both are already generic per-faction (systems/economy.gd's
# execute_faction_sale, systems/relation_accrual.gd's accrue_faction), driven
# here with faction_id "collective" regardless of which contact's Trade
# button opened the sell_menu. The only thing that varies by vendor is a
# flavour line appended to their own conversation on completing a trade
# (data/collective_barks.json), drawn without repeats until each vendor's
# pool is exhausted.


static func complete_trade(contact_id: String) -> Dictionary:
	var result := Economy.sell_to_faction_from_sell_state("collective")
	if result.get("ok", false) and result.get("earned", 0) > 0:
		Messages.append(contact_id, "them", _next_bark(contact_id))
		Modal.open("sale_result", { "earned": result["earned"], "gross": result["earned"], "mugged": false })
	return result


# Sequential cursor over data/collective_barks.json's array for this
# contact -- every line is shown once before any repeats, then wraps.
# Deterministic (no Rng) since draw order carries no meaning here, only
# non-repetition does.
static func _next_bark(contact_id: String) -> String:
	var lines: Array = GameData.COLLECTIVE_BARKS.get(contact_id, [])
	if lines.is_empty():
		return ""
	var cursors: Dictionary = GameState.state["collective"]["barkCursors"]
	var index: int = cursors.get(contact_id, 0)
	if index >= lines.size():
		index = 0
	cursors[contact_id] = index + 1
	return lines[index]


# collective1-09, spec §6.5/§6.6/§10.4: Des's two location-agnostic "Firm as
# weather" beats. Called from Sites.prospect() in place of
# DistrictDeck.maybe_trigger() -- checked first, and this whole function is
# Rng-free (a pure flags/site check), so when it fires the deck's own
# seeded roll is never touched at all that action: a genuine early return,
# not a discarded draw (§10.4's "must be asserted by a test").
#
# `new_site` is the site this same Sites.prospect() call just created (null
# on an at-cap reroll with nothing eligible) -- "qualifying" means it
# individually satisfies col_a1_des_sites' per-site criteria (ore type,
# tier, unclaimed; see Objectives.site_matches_discovery_params()), not
# that the objective as a whole is complete. colA1SkirmishSeen/
# colA1IntimidationSeen double as the "how many qualifying completions have
# we had" counter: neither seen yet -> this one fires S5; S5 already seen,
# S6 not yet -> this one fires S6; both seen -> no more weather beats.
static func maybe_trigger_weather_beat(new_site: Variant) -> bool:
	if not GameState.state["flags"].get("colA1DesThreadActive", false):
		return false
	if new_site == null:
		return false

	var params: Dictionary = GameData.OBJECTIVES["col_a1_des_sites"]["params"]
	var ore_type: String = new_site["oreType"]
	if not params.get("requireEachOreType", []).has(ore_type):
		return false
	if not Objectives.site_matches_discovery_params(new_site, ore_type, params):
		return false

	if not GameState.state["flags"].get("colA1SkirmishSeen", false):
		Events.start_event("col_a1_firm_skirmish")
		return true

	if not GameState.state["flags"].get("colA1IntimidationSeen", false):
		Events.start_event("col_a1_firm_intimidation")
		return true

	return false


# collective1-12, spec §6.10: S10 (col_a1_nadia_done) fires automatically the
# moment col_a1_nadia_vein's qualifying sale completes, not from an action
# bar -- called from VeinTrade.sell_to_faction() after Objectives.refresh(),
# same self-contained flags/objective inspection shape
# maybe_trigger_weather_beat() above uses (the generic caller hands over no
# state of its own to check). colA1NadiaThreadDone -- this event's own
# on_complete flag -- is what stops it firing again on a later, unrelated
# sale once col_a1_nadia_vein is complete: starting the event immediately
# navigates off whatever screen could call sell_to_faction() again, so in
# practice this can't re-enter before the player has played it through (or
# abandoned it), and once they have, this guard is permanent.
static func maybe_trigger_nadia_vein_done() -> bool:
	if GameState.state["flags"].get("colA1NadiaThreadDone", false):
		return false
	var objective: Dictionary = GameState.state["objectives"].get("col_a1_nadia_vein", {})
	if not objective.get("complete", false):
		return false

	Events.start_event("col_a1_nadia_done")
	return true


# collective1-16, spec §6.15/§10.4: S14's delivery condition -- all three
# thread-done flags plus the relation-25 gate, stated explicitly even though
# the gate is guaranteed by the +27 favour total the three threads award
# between them (spec §8.5), so the spine's "gate at 25" contract holds for
# the other four factions that inherit this engine. Called from Events.
# advance() right after any event's on_complete runs (see its own comment) --
# the one code path all three thread-resolution events' on_complete
# effects actually flow through. Guarded against re-queueing a duplicate
# text: colA1Complete (this event's own on_complete flag) blocks it once
# S14 has actually been played, and checking Hakim's existing pending
# entries blocks it from double-queueing between the moment all three flags
# land and the player actually opening the text.
static func maybe_trigger_closer() -> bool:
	var flags: Dictionary = GameState.state["flags"]
	if not flags.get("colA1DesThreadDone", false):
		return false
	if not flags.get("colA1NadiaThreadDone", false):
		return false
	if not flags.get("colA1HakimThreadDone", false):
		return false
	if flags.get("colA1Complete", false):
		return false
	if GameState.state["factions"]["collective"]["relation"] < 25:
		return false
	for entry in Messages.pending_for("hakim"):
		if entry["kind"] == "col_a1_closer":
			return false

	Messages.queue_pending("hakim", "col_a1_closer", "Are you about? Nothing's wrong. Come to the shop.")
	return true

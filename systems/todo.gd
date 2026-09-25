class_name Todo
extends RefCounted

# The Phone "ToDo" app's checklist (R§3.11, M1-LONDON.md D4). The
# tutorial's flag chain and the Collective's Act 1 threads are both
# ordinary data/objectives.json entries (systems/objectives.gd),
# distinguished only by their "questline" field -- ToDo renders one
# collapsible section per questline off a single loop. Static funcs only --
# pure read over GameState.state; never calls Objectives.refresh() itself
# (that stays at GameState.reset() and Events.apply_effects()).

const MAX_ITEMS_PER_SECTION := 4

# Per-questline presentation, in display order: label, and the flag that
# marks the whole questline done -- a distinct, later "epic complete" flag,
# not any one objective's own completeFlag, so the last objective renders
# checked before the section collapses. A questline with an emptyText is
# listed as a placeholder showing that text until its first objective
# activates; one without is omitted until then.
const QUESTLINES := {
	"tutorial": { "label": "Tutorial", "doneFlag": "cultivationTutorialSeen" },
	"collective": { "label": "Collective", "doneFlag": "colA1Complete" },
	"business_empire": { "label": "Business Empire", "doneFlag": "bizA1Complete", "emptyText": "Nothing on the books yet." },
}


# Returns one entry per started questline (at least one active objective, or
# a live Collective ledger) plus every unstarted one with an emptyText: { "questline", "label",
# "status": "active"|"done"|"placeholder", "defaultExpanded": bool,
# "items": [{ "title", "detail", "done" }], "ledger": Array, "emptyText" },
# in QUESTLINES' order, items capped to the most recent MAX_ITEMS_PER_SECTION.
static func get_questline_sections() -> Array[Dictionary]:
	var flags: Dictionary = GameState.state["flags"]
	var runtime: Dictionary = GameState.state["objectives"]
	var items_by_questline: Dictionary = {}

	for id in GameData.OBJECTIVES.keys():
		var def: Dictionary = GameData.OBJECTIVES[id]
		if not runtime.get(id, {}).get("active", false):
			continue
		var questline: String = def["questline"]
		var text := _display_text(def)
		var items: Array = items_by_questline.get(questline, [])
		items.append({
			"title": text["title"],
			"detail": text["detail"],
			"done": runtime[id].get("complete", false),
		})
		items_by_questline[questline] = items

	var sections: Array[Dictionary] = []
	for questline in QUESTLINES.keys():
		var config: Dictionary = QUESTLINES[questline]
		var items: Array = items_by_questline.get(questline, [])
		var ledger: Array[Dictionary] = []
		if questline == "collective":
			ledger = get_collective_ledger()
		var status := "active"
		if items.is_empty() and ledger.is_empty():
			if not config.has("emptyText"):
				continue
			status = "placeholder"
		elif flags.get(config.get("doneFlag"), false) and ledger.is_empty():
			status = "done"
		if items.size() > MAX_ITEMS_PER_SECTION:
			items = items.slice(items.size() - MAX_ITEMS_PER_SECTION, items.size())
		sections.append({
			"questline": questline,
			"label": config["label"],
			"status": status,
			"defaultExpanded": status != "done",
			"items": items,
			"ledger": ledger,
			"emptyText": config.get("emptyText", ""),
		})
	return sections


# Act 2's "the Collective starts keeping records" (spec §5.2): every site
# currently held as a Collective faction vein, unlocked once colA2Stage
# reaches "hardening". Pure read over state.world.sites -- no objective/
# questline plumbing, since there's no checklist here, just a live list
# that grows and shrinks as veins change hands.
static func get_collective_ledger() -> Array[Dictionary]:
	if GameState.state["flags"].get("colA2Stage") != "hardening":
		return []
	var rows: Array[Dictionary] = []
	for site in GameState.state["world"]["sites"]:
		var vein: Variant = site["factionVein"]
		if vein == null or vein["factionId"] != "collective":
			continue
		rows.append({
			"district": GameData.DISTRICTS[vein["district"]]["name"],
			"oreType": GameData.ORE_TYPES[vein["oreType"]]["name"],
			"security": Cultivating.security_label(vein),
		})
	return rows


# Some checkpoints' wording depends on more than their own flag (e.g.
# before day 2, Archie's text hasn't arrived, so its title doesn't apply
# yet). Generic (not id-keyed) so any objective can opt into a day-gated
# title via these two data fields.
# Count-style objectives (Objectives.count_progress) show "n of N" as their
# detail.
static func _display_text(def: Dictionary) -> Dictionary:
	if def.has("earlyTitle") and GameState.state["world"]["day"] < def["earlyTitleBeforeDay"]:
		return { "title": def["earlyTitle"], "detail": "" }
	var progress := Objectives.count_progress(def)
	if not progress.is_empty():
		return { "title": def["title"], "detail": "%d of %d" % [progress["current"], progress["target"]] }
	return { "title": def["title"], "detail": def.get("detail", "") }

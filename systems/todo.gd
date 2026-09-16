class_name Todo
extends RefCounted

# The Phone "Notes" app's checklist (R§3.11, M1-LONDON.md D4). The
# tutorial's flag chain and the Collective's Act 1 threads are both
# ordinary data/objectives.json entries (systems/objectives.gd),
# distinguished only by their "questline" field -- Notes renders one
# section per active questline off a single loop. Static funcs only --
# pure read over GameState.state; never calls Objectives.refresh() itself
# (that stays at GameState.reset() and Events.apply_effects()).

const MAX_ITEMS_PER_SECTION := 4

# Per-questline presentation: display label, and the flag that hides the
# whole section once true -- a distinct, later "epic complete" flag, not
# any one objective's own completeFlag, so completed objectives get a real
# visible window before the section vanishes.
const QUESTLINES := {
	"tutorial": { "label": "Tutorial", "hideFlag": "cultivationTutorialSeen" },
	"collective": { "label": "Collective", "hideFlag": "colA1Complete" },
}


# Returns one entry per questline with at least one active, unhidden
# objective: { "questline": String, "label": String, "items": [{ "title",
# "detail", "done" }] }, ordered by QUESTLINES' declaration order and
# capped to the most recent MAX_ITEMS_PER_SECTION.
static func get_active_questlines() -> Array[Dictionary]:
	var flags: Dictionary = GameState.state["flags"]
	var runtime: Dictionary = GameState.state["objectives"]
	var items_by_questline: Dictionary = {}

	for id in GameData.OBJECTIVES.keys():
		var def: Dictionary = GameData.OBJECTIVES[id]
		var questline: String = def["questline"]
		var config: Dictionary = QUESTLINES.get(questline, {})
		if flags.get(config.get("hideFlag"), false):
			continue
		if not runtime.get(id, {}).get("active", false):
			continue
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
		var items: Array = items_by_questline.get(questline, [])
		if items.is_empty():
			continue
		if items.size() > MAX_ITEMS_PER_SECTION:
			items = items.slice(items.size() - MAX_ITEMS_PER_SECTION, items.size())
		sections.append({ "questline": questline, "label": QUESTLINES[questline]["label"], "items": items })
	return sections


# Some checkpoints' wording depends on more than their own flag (e.g.
# before day 2, Archie's text hasn't arrived, so its title doesn't apply
# yet). Generic (not id-keyed) so any objective can opt into a day-gated
# title via these two data fields.
static func _display_text(def: Dictionary) -> Dictionary:
	if def.has("earlyTitle") and GameState.state["world"]["day"] < def["earlyTitleBeforeDay"]:
		return { "title": def["earlyTitle"], "detail": "" }
	return { "title": def["title"], "detail": def.get("detail", "") }

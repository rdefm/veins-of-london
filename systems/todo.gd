class_name Todo
extends RefCounted

# The Phone "Notes" app's checklist (R§3.11, M1-LONDON.md D4). Ticket 79:
# both the tutorial's flag chain and the Collective's Act 1 threads are now
# ordinary data/objectives.json entries (systems/objectives.gd), distinguished
# only by their "questline" field -- Notes renders one section per active
# questline off a single loop, rather than one hardcoded flag chain plus one
# objective-backed card builder. Static funcs only -- pure read over
# GameState.state; never calls Objectives.refresh() itself (that stays at
# GameState.reset() and Events.apply_effects(), the boundaries that can
# actually change a flag_true objective's state -- see objectives.gd's
# refresh() doc), so this file has no state-mutating side effects for a
# screen to trip over.

const MAX_ITEMS_PER_SECTION := 4

# Per-questline presentation: display label, and the flag that hides the
# whole section once true -- Collective's colA1Complete precedent (a
# distinct, later "epic complete" flag, not any one objective's own
# completeFlag, so completed objectives get a real visible window before
# the section vanishes). For the tutorial, archiePartnerSeen itself is
# tut_archie_partner's completeFlag (there's no further tutorial-specific
# milestone past it), so hiding on that same flag would make the section
# vanish the instant its last item completes -- it would never render
# checked. cultivationTutorialSeen is the next flag downstream (the
# post-raid cultivation walkthrough, unmissable: it gates Prospect itself
# -- see map.gd/district_bubble.gd), giving tut_archie_partner a real
# window as a checked item before the section disappears, same shape as
# Collective's closer-gated disappearance.
const QUESTLINES := {
	"tutorial": { "label": "Tutorial", "hideFlag": "cultivationTutorialSeen" },
	"collective": { "label": "Collective", "hideFlag": "colA1Complete" },
}


# Returns one entry per questline with at least one active, unhidden
# objective: { "questline": String, "label": String, "items": [{ "title",
# "detail", "done" }] }, ordered by QUESTLINES' declaration order, each
# section's items ordered as data/objectives.json declares them (its chain
# order, for the tutorial) and capped to the most recent MAX_ITEMS_PER_SECTION.
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


# tut_buyer_event is the one tutorial checkpoint whose wording depends on
# more than its own flag: before day 2, Archie's text hasn't arrived yet,
# so its authored title doesn't apply yet either (ported from the original
# getTodoItems() chain). Generic (not id-keyed) so any future objective can
# opt into the same day-gated-title shape via these two data fields.
static func _display_text(def: Dictionary) -> Dictionary:
	if def.has("earlyTitle") and GameState.state["world"]["day"] < def["earlyTitleBeforeDay"]:
		return { "title": def["earlyTitle"], "detail": "" }
	return { "title": def["title"], "detail": def.get("detail", "") }

class_name Todo
extends RefCounted

# The Phone "ToDo" app's checklist (R§3.11, M1-LONDON.md D4). The
# tutorial's flag chain and the Collective's Act 1 threads are both
# ordinary data/objectives.json entries (systems/objectives.gd),
# distinguished only by their "questline" field -- ToDo renders one
# collapsible section per questline off a single loop. Static funcs only --
# pure read over GameState.state; never calls Objectives.refresh() itself
# (that stays at GameState.reset() and Events.apply_effects()).

# Per-questline presentation (label, subtitle, accent, doneFlag, emptyText)
# lives in data/todo.json (GameData.TODO_PAGES). A questline with an emptyText
# is listed as a placeholder until its first objective activates; one without
# is omitted until then.

# Returns one entry per started questline (at least one active objective, or
# a live Collective ledger) plus every unstarted one with an emptyText: { "questline", "label",
# "status": "active"|"done"|"placeholder", "defaultExpanded": bool,
# "items": [{ "id", "title", "detail", "done", "checks" }], "ledger": Array, "emptyText" },
# where "checks" is an undone all_of objective's live checklist (Objectives.checklist()).
# in TODO_PAGES' questline order, then the Board section (get_board_section()) when a board goal is active.
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
		var done: bool = runtime[id].get("complete", false)
		items.append({
			"id": id,
			"title": text["title"],
			"detail": text["detail"],
			"done": done,
			"checks": [] if done else Objectives.checklist(def),
		})
		items_by_questline[questline] = items

	var sections: Array[Dictionary] = []
	for questline in GameData.TODO_PAGES["questlines"].keys():
		var config: Dictionary = GameData.TODO_PAGES["questlines"][questline]
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
		sections.append({
			"questline": questline,
			"label": config["label"],
			"status": status,
			"defaultExpanded": status != "done",
			"items": items,
			"ledger": ledger,
			"emptyText": config.get("emptyText", ""),
		})
	var act2 := get_act2_section()
	if not act2.is_empty():
		sections.append(act2)
	var board := get_board_section()
	if not board.is_empty():
		sections.append(board)
	return sections


# --- Page projection (ToDo carousel) ---

const GROUP_ORDER := { "active": 0, "placeholder": 1, "board": 2, "done": 3 }


# Saved marks: "clock" ticks on each page change; "changed"/"seen" map a page
# id to the clock value at its last change / last view; "sig" is the page's
# last-seen content signature (see refresh_marks()).
static func new_state() -> Dictionary:
	return { "changed": {}, "clock": 0, "seen": {}, "sig": {} }


# One page per questline plus Act 2 and Board, ordered started first, then
# unstarted placeholders, then the Board, then finished. Data order breaks
# ties. Page: { "id", "label", "subtitle", "accent", "status", "pip": bool,
# "active": goals, "done": goals, "ledger", "emptyText", "steps" } -- goals
# keep the get_questline_sections() item shape; "steps" is the Board ladder
# ([{ "tier", "name", "reached", "target" }]), empty elsewhere.
static func get_pages() -> Array[Dictionary]:
	var marks: Dictionary = GameState.state.get("todo", new_state())
	var pages: Array[Dictionary] = []
	for section in get_questline_sections():
		var id: String = section["questline"]
		var style := _page_style(id)
		var active: Array = []
		var done: Array = []
		for item in section["items"]:
			(done if item["done"] else active).append(item)
		var group: String = "board" if id == "board" else str(section["status"])
		pages.append({
			"id": id,
			"label": section["label"],
			"subtitle": style.get("subtitle", ""),
			"accent": style.get("accent", ""),
			"status": section["status"],
			"pip": marks["changed"].get(id, 0) > marks["seen"].get(id, 0),
			"active": active,
			"done": done,
			"ledger": section["ledger"],
			"emptyText": section["emptyText"],
			"steps": _board_steps() if id == "board" else [],
			"_group": group,
		})
	var ordered: Array[Dictionary] = []
	for group in ["active", "placeholder", "board", "done"]:
		for page in pages:
			if page["_group"] == group:
				ordered.append(page)
	for page in ordered:
		page.erase("_group")
	return ordered


static func _page_style(id: String) -> Dictionary:
	var pages: Dictionary = GameData.TODO_PAGES
	if pages["questlines"].has(id):
		return pages["questlines"][id]
	return pages.get(id, {})


# Index (into get_pages()) of the page to open on: the most recently changed
# one, else the first.
static func default_page_index() -> int:
	var marks: Dictionary = GameState.state.get("todo", new_state())
	var best := 0
	var best_mark := -1
	var pages := get_pages()
	for i in pages.size():
		var mark: int = marks["changed"].get(pages[i]["id"], 0)
		if mark > best_mark:
			best = i
			best_mark = mark
	return best


# Base/target/stretch rungs of the active board goal: reached once the
# current tier is at or past it; target = the tier's threshold in display
# units ("" when the goal type has no measure).
static func _board_steps() -> Array[Dictionary]:
	var steps: Array[Dictionary] = []
	var board: Dictionary = GameState.state.get("boardMeetings", {})
	var active: Variant = board.get("active")
	if active == null:
		return steps
	var goal: Dictionary = active["goal"]
	var measured := Objectives.measure(goal, active["progress"])
	var current := Objectives.TIER_ORDER.find(BoardMeetings.current_tier())
	for i in Objectives.TIER_ORDER.size():
		var tier: String = Objectives.TIER_ORDER[i]
		var target := ""
		if not measured.is_empty():
			var raw: Variant = goal["tiers"].get(tier, {}).get(measured["param"])
			if raw != null:
				target = _num(float(raw) * float(measured.get("scale", 1.0)))
		steps.append({
			"tier": tier,
			"name": GameData.BOARD_TODO["tierNames"].get(tier, tier),
			"reached": i <= current,
			"target": target,
		})
	return steps


# Content signature of a page: ids of its goals with done state, plus the
# Board tier reached. Changes when a goal appears, completes or a tier lands.
static func _signature(page: Dictionary) -> String:
	var parts: PackedStringArray = []
	for item in page["active"]:
		parts.append(str(item["id"]))
	for item in page["done"]:
		parts.append("%s+" % item["id"])
	if page["id"] == "board":
		parts.append(BoardMeetings.current_tier())
	return ",".join(parts)


# Records which pages changed since the last call (bumps the clock and the
# page's changed mark). Called after objectives refresh.
static func refresh_marks() -> void:
	if not GameState.state.has("todo"):
		GameState.state["todo"] = new_state()
	var marks: Dictionary = GameState.state["todo"]
	for page in get_pages():
		var id: String = page["id"]
		var sig := _signature(page)
		if marks["sig"].get(id, "") == sig:
			continue
		marks["sig"][id] = sig
		if sig == "":
			continue
		marks["clock"] += 1
		marks["changed"][id] = marks["clock"]


# The player has looked at a page: clears its new-goal pip.
static func mark_seen(page_id: String) -> void:
	var marks: Dictionary = GameState.state["todo"]
	marks["seen"][page_id] = marks["changed"].get(page_id, 0)
	EventBus.state_changed.emit()


# The Act 2 spine as a questline-shaped section (BOARD_SPINE beats in order):
# done beats tick, a beat whose `requires` isn't done reads as locked.
# status "done" once every beat is. {} while meetings are off.
static func get_act2_section() -> Dictionary:
	var board: Dictionary = GameState.state.get("boardMeetings", {})
	if not board.get("enabled", false) or GameData.BOARD_SPINE.is_empty():
		return {}
	var items: Array = []
	var all_done := true
	for beat in GameData.BOARD_SPINE["beats"]:
		var done := BoardMeetings.spine_done(beat["id"])
		all_done = all_done and done
		items.append({
			"id": "spine_%s" % beat["id"],
			"title": beat["title"],
			"detail": "" if done or BoardMeetings.spine_unlocked(beat["id"]) else GameData.BOARD_SPINE["lockedText"],
			"done": done,
			"checks": [],
		})
	var status := "done" if all_done else "active"
	return {
		"questline": "act2",
		"label": GameData.BOARD_SPINE["label"],
		"status": status,
		"defaultExpanded": status != "done",
		"items": items,
		"ledger": [],
		"emptyText": "",
	}


# The Board section (spec §"Modules" → Todo): the active board goal as one
# item -- label, tier reached so far, progress to the next tier. Listed after
# every questline, so another questline's undone step outranks it in
# current_objective(). {} when meetings are off or no goal is active.
static func get_board_section() -> Dictionary:
	var board: Dictionary = GameState.state.get("boardMeetings", {})
	var active: Variant = board.get("active")
	if not board.get("enabled", false) or active == null:
		return {}
	return {
		"questline": "board",
		"label": GameData.BOARD_TODO["label"],
		"status": "active",
		"defaultExpanded": true,
		"items": [{
			"id": active["goal"]["id"],
			"title": BoardMeetings.card_label(active),
			"detail": _board_detail(active),
			"done": false,
			"checks": [],
		}],
		"ledger": [],
		"emptyText": "",
	}


# "<tier> reached · <current> of <target> ... to <next tier>"; the progress
# half is dropped once stretch is reached or the goal type has no measure.
static func _board_detail(active: Dictionary) -> String:
	var copy: Dictionary = GameData.BOARD_TODO
	var tier := BoardMeetings.current_tier()
	var parts: PackedStringArray = []
	if tier == Objectives.TIER_NONE:
		parts.append(copy["noTier"])
	else:
		parts.append(copy["reached"].format({ "tier": copy["tierNames"][tier] }))
	var next_index := Objectives.TIER_ORDER.find(tier) + 1
	var goal: Dictionary = active["goal"]
	var measured := Objectives.measure(goal, active["progress"])
	if next_index < Objectives.TIER_ORDER.size() and not measured.is_empty() and copy["progress"].has(goal["type"]):
		var next_tier: String = Objectives.TIER_ORDER[next_index]
		var target: Variant = goal["tiers"].get(next_tier, {}).get(measured["param"])
		if target != null:
			parts.append(copy["progress"][goal["type"]].format({
				"current": _num(measured["value"]),
				"target": _num(float(target) * float(measured.get("scale", 1.0))),
				"tier": copy["tierNames"][next_tier],
				"ore": str(GameData.ORE_TYPES.get(goal["params"].get("oreType", ""), {}).get("name", "")),
			}))
	return copy["separator"].join(parts)


# Whole numbers without a decimal, otherwise one place, floored so an unmet
# threshold never displays as reached.
static func _num(value: float) -> String:
	var tenths := floorf(value * 10.0 + 0.0001) / 10.0
	return "%d" % int(tenths) if is_equal_approx(tenths, roundf(tenths)) else "%.1f" % tenths


# The first undone item across the active sections, in section order: what
# BizBrief's Story row shows (the Act 2 overview is skipped: it is read-only). Empty when nothing is pending ("nothing
# pressing"). Same item shape as get_questline_sections().
static func current_objective() -> Dictionary:
	for section in get_questline_sections():
		if section["status"] != "active" or section["questline"] == "act2":
			continue
		for item in section["items"]:
			if not item["done"]:
				return item
	return {}


# The checklist row's one-line wording, shared by ToDo and the Story row.
static func item_text(item: Dictionary) -> String:
	return item["title"] if item["detail"] == "" else "%s — %s" % [item["title"], item["detail"]]


# True while the objective shows its day-gated waiting wording.
static func is_early(def: Dictionary) -> bool:
	return def.has("earlyTitle") and GameState.state["world"]["day"] < def["earlyTitleBeforeDay"]


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
	if is_early(def):
		return { "title": def["earlyTitle"], "detail": "" }
	var progress := Objectives.count_progress(def)
	if not progress.is_empty():
		return { "title": def["title"], "detail": "%d of %d" % [progress["current"], progress["target"]] }
	return { "title": def["title"], "detail": def.get("detail", "") }

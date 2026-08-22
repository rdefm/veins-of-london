class_name Objectives
extends RefCounted

# collective1-02, spec.md §5.1: objectives as data. A small typed evaluator
# engine over data/objectives.json (GameData.OBJECTIVES) -- exactly four
# evaluator types, evaluated explicitly at known action boundaries rather
# than on every state_changed signal. Static funcs only, pure read/write over
# GameState.state.objectives -- never touches cash/relation/inventory/etc.
# Awards live in authored event content (on_complete), never here; this
# system only ever flips complete/completeFlag.

const TYPE_SITES_DISCOVERED_MATCHING := "sites_discovered_matching"
const TYPE_TRADED_WITH_FACTION := "traded_with_faction"
const TYPE_VEIN_SOLD_TO_FACTION := "vein_sold_to_faction"
const TYPE_VEIN_GROWTH_ABOVE := "vein_growth_above"


# The only entry point. Called explicitly (never via signal) at exactly 5
# action boundaries per spec §5.1: Sites.prospect(), Economy sale completion
# (both the Archie lane and the faction lane), VeinTrade.sell_to_faction(),
# Cultivating.cultivate()/prune(), and TimeSystem.daily_tick(). Idempotent —
# calling it twice in a row with no intervening state change produces the
# same state.objectives result, since a complete objective is never
# re-evaluated and an inactive one's progress is untouched until its
# activateFlag flips true. Must never call anything that itself calls
# refresh() (recursion guard, per spec).
static func refresh() -> void:
	for id in GameData.OBJECTIVES.keys():
		_refresh_one(id, GameData.OBJECTIVES[id])


static func _refresh_one(id: String, def: Dictionary) -> void:
	var objectives: Dictionary = GameState.state["objectives"]
	var runtime: Dictionary = objectives.get(id, { "active": false, "complete": false, "progress": {} })

	var was_active: bool = runtime["active"]
	var now_active: bool = GameState.state["flags"].get(def["activateFlag"], false)
	runtime["active"] = now_active
	if now_active and not was_active:
		_mark_activated(def, runtime["progress"])

	if not runtime["complete"] and now_active and _evaluate(def, runtime["progress"]):
		runtime["complete"] = true
		GameState.state["flags"][def["completeFlag"]] = true

	objectives[id] = runtime


# Stamps the objective's activation moment into its progress bag, so
# window-scoped evaluators (traded_with_faction, vein_sold_to_faction) count
# only what happens from here on, not history from before the thread that
# owns this objective ever started.
static func _mark_activated(def: Dictionary, progress: Dictionary) -> void:
	progress["activatedDay"] = GameState.state["world"]["day"]
	if def["type"] == TYPE_TRADED_WITH_FACTION:
		var params: Dictionary = def["params"]
		var current: Dictionary = _ore_sold_entry(params["factionId"], params["oreType"])
		progress["baseline"] = { "units": current["units"], "transactions": current["transactions"] }


static func _evaluate(def: Dictionary, progress: Dictionary) -> bool:
	var params: Dictionary = def.get("params", {})
	match def["type"]:
		TYPE_SITES_DISCOVERED_MATCHING:
			return _eval_sites_discovered_matching(params)
		TYPE_TRADED_WITH_FACTION:
			return _eval_traded_with_faction(params, progress)
		TYPE_VEIN_SOLD_TO_FACTION:
			return _eval_vein_sold_to_faction(params, progress)
		TYPE_VEIN_GROWTH_ABOVE:
			return _eval_vein_growth_above(params)
		_:
			return false


# requireEachOreType: [String], minTier: String, unclaimed: bool -- for each
# named ore type, at least one site in state.world.sites at or above minTier
# (sites.json's tierOrder), and, if unclaimed, neither player-claimed nor
# faction-owned.
static func _eval_sites_discovered_matching(params: Dictionary) -> bool:
	var require_each: Array = params.get("requireEachOreType", [])
	var tier_order: Array = GameData.SITE_TIER_ORDER
	var min_index: int = tier_order.find(params.get("minTier"))
	var require_unclaimed: bool = params.get("unclaimed", false)

	for ore_type in require_each:
		var found := false
		for site in GameState.state["world"]["sites"]:
			if site["oreType"] != ore_type:
				continue
			if tier_order.find(site["tier"]) < min_index:
				continue
			if require_unclaimed and (site["claimed"] or site["factionVein"] != null):
				continue
			found = true
			break
		if not found:
			return false
	return true


# factionId, oreType, qty: int, minTransactions: int -- cumulative units of
# oreType sold to factionId, and a distinct count of sale transactions
# containing it, both counted only since this objective activated (see
# _mark_activated's baseline snapshot).
static func _eval_traded_with_faction(params: Dictionary, progress: Dictionary) -> bool:
	var current: Dictionary = _ore_sold_entry(params["factionId"], params["oreType"])
	var baseline: Dictionary = progress.get("baseline", { "units": 0, "transactions": 0 })
	var units_since: int = current["units"] - baseline["units"]
	var transactions_since: int = current["transactions"] - baseline["transactions"]
	return units_since >= params["qty"] and transactions_since >= params["minTransactions"]


static func _ore_sold_entry(faction_id: String, ore_type: String) -> Dictionary:
	var faction: Dictionary = GameState.state["factions"].get(faction_id, {})
	var ore_sold: Dictionary = faction.get("oreSold", {})
	return ore_sold.get(ore_type, { "units": 0, "transactions": 0 })


# factionId, oreType -- true once a vein of oreType has been sold to
# factionId since this objective activated. Reads the "soldByPlayer" marker
# VeinTrade.sell_to_faction() (spec §5.6, ticket 05) stamps onto the
# site.factionVein it creates -- a natural-expansion or rivalry-captured
# faction vein of the same faction/oreType never carries that marker, so it
# can't false-positive this objective.
static func _eval_vein_sold_to_faction(params: Dictionary, progress: Dictionary) -> bool:
	var activated_day: int = progress.get("activatedDay", 0)
	for site in GameState.state["world"]["sites"]:
		var vein: Variant = site["factionVein"]
		if vein == null:
			continue
		if vein["factionId"] != params["factionId"] or vein["oreType"] != params["oreType"]:
			continue
		if not vein.get("soldByPlayer", false):
			continue
		if vein["claimedOnDay"] < activated_day:
			continue
		return true
	return false


# veinIdStatePath: String, threshold: int -- the vein whose id is stored at
# that state path (GameState.read_path) has growth >= threshold. Looked up
# via Cultivating.find_vein, which only searches state.player.veins -- every
# vein this evaluator is used for in Act 1 (Hakim's yard vein) lives there.
static func _eval_vein_growth_above(params: Dictionary) -> bool:
	var vein_id: Variant = GameState.read_path(params["veinIdStatePath"])
	if vein_id == null:
		return false
	var vein: Variant = Cultivating.find_vein(vein_id)
	if vein == null:
		return false
	return vein["growth"] >= params["threshold"]

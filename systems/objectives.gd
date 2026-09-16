class_name Objectives
extends RefCounted

# A small typed evaluator engine over data/objectives.json (GameData.
# OBJECTIVES) -- evaluated explicitly at known action boundaries, not on
# every state_changed signal. Static funcs only, pure read/write over
# GameState.state.objectives. Awards live in authored event content
# (on_complete), never here -- this only flips complete/completeFlag.

const TYPE_SITES_DISCOVERED_MATCHING := "sites_discovered_matching"
const TYPE_TRADED_WITH_FACTION := "traded_with_faction"
const TYPE_SUPPLIED_TO_CONTACT := "supplied_to_contact"
const TYPE_VEIN_SOLD_TO_FACTION := "vein_sold_to_faction"
const TYPE_VEIN_GROWTH_ABOVE := "vein_growth_above"
const TYPE_FLAG_TRUE := "flag_true"


# The only entry point, called explicitly (never via signal) at action
# boundaries across Sites/Economy/VeinTrade/Cultivating/TimeSystem/
# GameState.reset()/Events.apply_effects(). Idempotent -- a complete
# objective is never re-evaluated. Must never call anything that itself
# calls refresh() (recursion guard).
static func refresh() -> void:
	for id in GameData.OBJECTIVES.keys():
		_refresh_one(id, GameData.OBJECTIVES[id])


static func _refresh_one(id: String, def: Dictionary) -> void:
	var objectives: Dictionary = GameState.state["objectives"]
	var runtime: Dictionary = objectives.get(id, { "active": false, "complete": false, "progress": {} })

	var was_active: bool = runtime["active"]
	# activateFlag == null means "active from the start" -- no gating flag.
	var activate_flag: Variant = def["activateFlag"]
	var now_active: bool = true if activate_flag == null else GameState.state["flags"].get(activate_flag, false)
	runtime["active"] = now_active
	if now_active and not was_active:
		_mark_activated(def, runtime["progress"])

	if not runtime["complete"] and now_active and _evaluate(def, runtime["progress"]):
		runtime["complete"] = true
		GameState.state["flags"][def["completeFlag"]] = true

	objectives[id] = runtime


# Stamps the activation moment into progress, so window-scoped evaluators
# count only what happens from here on, not history from before.
static func _mark_activated(def: Dictionary, progress: Dictionary) -> void:
	progress["activatedDay"] = GameState.state["world"]["day"]
	if def["type"] == TYPE_TRADED_WITH_FACTION:
		var params: Dictionary = def["params"]
		var current: Dictionary = _ore_sold_entry(params["factionId"], params["oreType"])
		progress["baseline"] = { "units": current["units"], "transactions": current["transactions"] }
	elif def["type"] == TYPE_SUPPLIED_TO_CONTACT:
		progress["delivered"] = 0


static func _evaluate(def: Dictionary, progress: Dictionary) -> bool:
	var params: Dictionary = def.get("params", {})
	match def["type"]:
		TYPE_SITES_DISCOVERED_MATCHING:
			return _eval_sites_discovered_matching(params, progress)
		TYPE_TRADED_WITH_FACTION:
			return _eval_traded_with_faction(params, progress)
		TYPE_SUPPLIED_TO_CONTACT:
			return int(progress.get("delivered", 0)) >= int(params["qty"])
		TYPE_VEIN_SOLD_TO_FACTION:
			return _eval_vein_sold_to_faction(params, progress)
		TYPE_VEIN_GROWTH_ABOVE:
			return _eval_vein_growth_above(params)
		TYPE_FLAG_TRUE:
			return _eval_flag_true(def)
		_:
			return false


# requireEachOreType: [String]. Collective.report_des_site() stamps a
# qualifying site into progress["reportedSiteIds"][ore_type] as it's found;
# complete once every required ore type has been reported, any order.
static func _eval_sites_discovered_matching(params: Dictionary, progress: Dictionary) -> bool:
	var require_each: Array = params.get("requireEachOreType", [])
	var reported: Dictionary = progress.get("reportedSiteIds", {})

	for ore_type in require_each:
		if not reported.has(ore_type):
			return false
	return true


# The tier/unclaimed half of sites_discovered_matching's per-site check,
# split out so collective.gd's weather-beat trigger can test one freshly-
# prospected site without duplicating the loop above. `ore_type` is passed
# explicitly so both the per-required-type loop and a single-site caller
# use the same check.
static func site_matches_discovery_params(site: Dictionary, ore_type: String, params: Dictionary) -> bool:
	if site["oreType"] != ore_type:
		return false
	var tier_order: Array = GameData.SITE_TIER_ORDER
	var min_index: int = tier_order.find(params.get("minTier"))
	if tier_order.find(site["tier"]) < min_index:
		return false
	if params.get("unclaimed", false) and (site["claimed"] or site["factionVein"] != null):
		return false
	return true


# factionId, oreType, qty, minTransactions -- cumulative units sold and a
# distinct transaction count, both counted only since this objective
# activated (see _mark_activated's baseline snapshot).
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
# factionId since activation. Reads the "soldByPlayer" marker VeinTrade.
# sell_to_faction() stamps on the site.factionVein it creates, so a
# naturally-expanded or rivalry-captured vein never false-positives this.
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


# veinIdStatePath, threshold -- the vein at that state path (GameState.
# read_path) has growth >= threshold. Looked up via Cultivating.find_vein,
# which only searches state.player.veins.
static func _eval_vein_growth_above(params: Dictionary) -> bool:
	var vein_id: Variant = GameState.read_path(params["veinIdStatePath"])
	if vein_id == null:
		return false
	var vein: Variant = Cultivating.find_vein(vein_id)
	if vein == null:
		return false
	return vein["growth"] >= params["threshold"]


# No params -- true once the objective's own completeFlag is true. Used by
# the tutorial chain, where each checkpoint's flag is set directly by an
# event's set_flag op rather than derived from other state.
static func _eval_flag_true(def: Dictionary) -> bool:
	return GameState.state["flags"].get(def["completeFlag"], false)

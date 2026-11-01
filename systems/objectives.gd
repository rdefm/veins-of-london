class_name Objectives
extends RefCounted

# A small typed evaluator engine over data/objectives.json (GameData.
# OBJECTIVES), evaluated explicitly at known action boundaries, not on
# every state_changed. Static funcs only, pure read/write over
# GameState.state.objectives. Awards live in authored event content
# (on_complete) — this only flips complete/completeFlag.

const TYPE_SITES_DISCOVERED_MATCHING := "sites_discovered_matching"
const TYPE_TRADED_WITH_FACTION := "traded_with_faction"
const TYPE_SUPPLIED_TO_CONTACT := "supplied_to_contact"
const TYPE_VEIN_SOLD_TO_FACTION := "vein_sold_to_faction"
const TYPE_VEIN_GROWTH_ABOVE := "vein_growth_above"
const TYPE_FLAG_TRUE := "flag_true"
const TYPE_ALARM_DEFEND_WINS := "alarm_defend_wins"
const TYPE_FACTION_VEIN_SEEDED_COUNT := "faction_vein_seeded_count"
const TYPE_ITEMS_CRAFTED_SET := "items_crafted_set"
const TYPE_CONTRACTS_COMPLETED := "contracts_completed"
const TYPE_ALL_OF := "all_of"
const TYPE_RECURRING_PROOF := "recurring_proof"
const TYPE_TEMPLATE_PERIODS_COMPLETED := "template_periods_completed"
const TYPE_RECIPE_KNOWN := "recipe_known"
const TYPE_RESERVE_WEEKS_AT_LEAST := "reserve_weeks_at_least"
const TYPE_ORE_SHARE_AT_LEAST := "ore_share_at_least"
const TYPE_CRAFTING_SHARE_AT_LEAST := "crafting_share_at_least"

const TYPE_YIELD_MULTIPLE_AT_LEAST := "yield_multiple_at_least"
const TYPE_NEW_VEINS_ONLINE_AT_LEAST := "new_veins_online_at_least"
const TYPE_VEIN_HEALTH_STREAK_AT_LEAST := "vein_health_streak_at_least"
const TYPE_ORE_TYPES_ONLINE_AT_LEAST := "ore_types_online_at_least"

# Days of harvest the yield baseline averages, and the goal week it is
# compared against (spec §"Modules" → Objectives).
const YIELD_BASELINE_DAYS := 10
const GOAL_WEEK_DAYS := 7

const TIER_NONE := "none"
const TIER_ORDER: Array[String] = ["base", "target", "stretch"]


# The only entry point, called explicitly at action boundaries across
# Sites/Economy/VeinTrade/Cultivating/TimeSystem/GameState.reset()/
# Events.apply_effects(). Idempotent — a complete objective is never
# re-evaluated, and must never call anything that itself calls refresh()
# (recursion guard).
static func refresh() -> void:
	for id in GameData.OBJECTIVES.keys():
		_refresh_one(id, GameData.OBJECTIVES[id])
	BoardMeetings.note_progress()


static func _refresh_one(id: String, def: Dictionary) -> void:
	var objectives: Dictionary = GameState.state["objectives"]
	var runtime: Dictionary = objectives.get(id, { "active": false, "complete": false, "progress": {} })

	var was_active: bool = runtime["active"]
	# activateFlag == null means no gating flag; an optional activateIf
	# condition must also hold.
	var activate_flag: Variant = def["activateFlag"]
	var now_active: bool = true if activate_flag == null else GameState.state["flags"].get(activate_flag, false)
	if now_active and def.has("activateIf"):
		now_active = condition_met(def["activateIf"])
	runtime["active"] = now_active
	if now_active and not was_active:
		_mark_activated(def, runtime["progress"])

	if not runtime["complete"] and now_active and _evaluate(def, runtime["progress"]):
		runtime["complete"] = true
		GameState.state["flags"][def["completeFlag"]] = true
		KeyMembers.note_quest_step(str(def.get("questline", "")))

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
	elif def["type"] == TYPE_ITEMS_CRAFTED_SET:
		progress["craftedBaseline"] = GameState.deep_copy(GameState.state["player"]["craftedCounts"])


# Evaluates any definition through the same engine as data objectives —
# including a generated one a caller holds (a board goal), not present in
# GameData.OBJECTIVES. Reads only; never writes objectives state.
static func evaluate(def: Dictionary, progress: Dictionary = {}) -> bool:
	return _evaluate(def, progress)


# def["tiers"]: { "base"|"target"|"stretch": { param overrides } } — three
# thresholds of one condition, each merged over def["params"]. Returns the
# highest tier met now, or TIER_NONE (spec §"Modules" → Objectives).
static func tier_met(def: Dictionary, progress: Dictionary = {}) -> String:
	var tiers: Dictionary = def.get("tiers", {})
	var base_params: Dictionary = def.get("params", {})
	for i in range(TIER_ORDER.size() - 1, -1, -1):
		var tier: String = TIER_ORDER[i]
		if not tiers.has(tier):
			continue
		var tier_def: Dictionary = def.duplicate()
		tier_def["params"] = base_params.merged(tiers[tier], true)
		if _evaluate(tier_def, progress):
			return tier
	return TIER_NONE


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
		TYPE_ALARM_DEFEND_WINS:
			return int(progress.get("defendWinCount", 0)) >= int(params["minCount"])
		TYPE_FACTION_VEIN_SEEDED_COUNT:
			return _eval_faction_vein_seeded_count(params, progress)
		TYPE_ITEMS_CRAFTED_SET:
			return _eval_items_crafted_set(params, progress)
		TYPE_CONTRACTS_COMPLETED:
			return completed_contract_count() >= int(params["minCount"])
		TYPE_ALL_OF:
			for condition in params["conditions"]:
				if not condition_met(condition):
					return false
			return true
		TYPE_RECURRING_PROOF:
			var proof := recurring_proof()
			return proof["contracts"] >= int(params["minContracts"]) and proof["crafted"] >= int(params["minCrafted"])
		TYPE_TEMPLATE_PERIODS_COMPLETED:
			return completed_period_count(params["templateId"]) >= int(params["minCount"])
		TYPE_RECIPE_KNOWN:
			return Lab.is_known(params["recipe"])
		TYPE_RESERVE_WEEKS_AT_LEAST:
			return reserve_weeks_met(float(params["minWeeks"]))
		TYPE_ORE_SHARE_AT_LEAST:
			return ore_share_met(params)
		TYPE_CRAFTING_SHARE_AT_LEAST:
			return ore_share_met(params, "craft")
		TYPE_YIELD_MULTIPLE_AT_LEAST:
			return _eval_yield_multiple(params, progress)
		TYPE_NEW_VEINS_ONLINE_AT_LEAST:
			return _eval_new_veins_online(params, progress)
		TYPE_VEIN_HEALTH_STREAK_AT_LEAST:
			return _max_development_streak() >= int(params["minDays"])
		TYPE_ORE_TYPES_ONLINE_AT_LEAST:
			return _online_ore_types(int(params["minGrowth"])) >= int(params["minTypes"])
		_:
			return false


# Progress a generated goal needs captured at the moment it is chosen: the
# start day for goal-week types, plus the prior-10-day average daily yield
# for yield_multiple_at_least. Plain data.
static func initial_progress(goal_type: String) -> Dictionary:
	var day: int = GameState.state["world"]["day"]
	var progress := { "sinceDay": day }
	if goal_type == TYPE_YIELD_MULTIPLE_AT_LEAST:
		progress["yieldBaseline"] = yield_baseline()
	return progress


# Average daily player harvest (all ores) over the YIELD_BASELINE_DAYS days
# before today.
static func yield_baseline() -> float:
	var day: int = GameState.state["world"]["day"]
	var total := 0
	for amount in Shares.ore_between(Shares.PLAYER, day - YIELD_BASELINE_DAYS, day - 1).values():
		total += int(amount)
	return float(total) / YIELD_BASELINE_DAYS


# Player harvest (all ores) from progress.sinceDay through the goal week;
# false (unmet) until a goal has captured a baseline, or on no baseline yield.
static func _eval_yield_multiple(params: Dictionary, progress: Dictionary) -> bool:
	var baseline := float(progress.get("yieldBaseline", 0.0))
	if baseline <= 0.0 or not progress.has("sinceDay"):
		return false
	var since := int(progress["sinceDay"])
	var harvest := 0
	for amount in Shares.ore_between(Shares.PLAYER, since, since + GOAL_WEEK_DAYS - 1).values():
		harvest += int(amount)
	return float(harvest) + 0.000001 >= float(params["multiple"]) * baseline * GOAL_WEEK_DAYS


# Player veins claimed since progress.sinceDay whose growth is at least
# params.minGrowth number params.minCount. Unmet without a captured start.
static func _eval_new_veins_online(params: Dictionary, progress: Dictionary) -> bool:
	if not progress.has("sinceDay"):
		return false
	var count := 0
	for vein in GameState.state["player"]["veins"]:
		if int(vein["claimedOnDay"]) >= int(progress["sinceDay"]) and int(vein["growth"]) >= int(params["minGrowth"]):
			count += 1
	return count >= int(params["minCount"])


static func _max_development_streak() -> int:
	var best := 0
	for vein in GameState.state["player"]["veins"]:
		best = maxi(best, int(vein.get("developmentStreak", 0)))
	return best


# Distinct ore types among player veins with growth >= min_growth.
static func _online_ore_types(min_growth: int) -> int:
	var types := {}
	for vein in GameState.state["player"]["veins"]:
		if int(vein["growth"]) >= min_growth:
			types[vein["oreType"]] = true
	return types.size()


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
# prospected site without duplicating the loop above.
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


# factionId, oreType, qty, minTransactions: cumulative units sold and
# transaction count, both counted only since activation (_mark_activated's
# baseline snapshot).
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


# factionId, oreType: true once a vein of oreType has sold to factionId
# since activation. Reads the "soldByPlayer" marker VeinTrade.
# sell_to_faction() stamps, so a naturally-expanded or rivalry-captured
# vein never false-positives this.
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


# veinIdStatePath, threshold: the vein at that state path (GameState.
# read_path) has growth >= threshold, via Cultivating.find_vein.
static func _eval_vein_growth_above(params: Dictionary) -> bool:
	var vein_id: Variant = GameState.read_path(params["veinIdStatePath"])
	if vein_id == null:
		return false
	var vein: Variant = Cultivating.find_vein(vein_id)
	if vein == null:
		return false
	return vein["growth"] >= params["threshold"]


# No params: true once completeFlag is already true — the tutorial chain's
# checkpoints, set directly by an event's set_flag op.
static func _eval_flag_true(def: Dictionary) -> bool:
	return GameState.state["flags"].get(def["completeFlag"], false)


# Called from Raiding.resolve_defend_outcome() on every win, not just for
# objective ids that exist -- generic over any active alarm_defend_wins
# objective, same "loop the type" shape _refresh_one() itself uses. The
# type's contract (col_a2_nadia_ledger, spec §5.1) is scoped to one named
# vein rather than any Collective vein, so this reads state.collective.
# nadiaDefendVeinId directly instead of taking a param -- the type has
# exactly one consumer today and .get() degrades safely (no match, no
# count) whenever that field is absent from state.
static func record_alarm_defend_win(vein_id: String) -> void:
	var target: Variant = GameState.state["collective"].get("nadiaDefendVeinId")
	if vein_id != target:
		return
	var objectives: Dictionary = GameState.state["objectives"]
	for id in GameData.OBJECTIVES.keys():
		var def: Dictionary = GameData.OBJECTIVES[id]
		if def["type"] != TYPE_ALARM_DEFEND_WINS:
			continue
		var runtime: Dictionary = objectives.get(id, {})
		if not runtime.get("active", false) or runtime.get("complete", false):
			continue
		var progress: Dictionary = runtime["progress"]
		progress["defendWinCount"] = int(progress.get("defendWinCount", 0)) + 1
		runtime["progress"] = progress
		objectives[id] = runtime


# factionId, minCount: sites whose factionVein belongs to factionId and was
# claimed on/after activation -- same claimedOnDay-vs-activatedDay shape as
# _eval_vein_sold_to_faction, generalised to a count. No soldByPlayer filter
# (unlike vein_sold_to_faction): any new vein of that faction counts, player
# sale or NPC claim alike, matching the type's literal contract.
static func _eval_faction_vein_seeded_count(params: Dictionary, progress: Dictionary) -> bool:
	var activated_day: int = progress.get("activatedDay", 0)
	var count := 0
	for site in GameState.state["world"]["sites"]:
		var vein: Variant = site["factionVein"]
		if vein == null:
			continue
		if vein["factionId"] != params["factionId"]:
			continue
		if vein["claimedOnDay"] < activated_day:
			continue
		count += 1
	return count >= int(params["minCount"])


# recipeKeys, minEach: at least minEach successful crafts of every named
# recipe since activation. Diffs state.player.craftedCounts (Crafting.
# file_crafted()) against the baseline _mark_activated
# snapshot, so crafts from before this objective activated never
# retroactively satisfy it.
static func _eval_items_crafted_set(params: Dictionary, progress: Dictionary) -> bool:
	var baseline: Dictionary = progress.get("craftedBaseline", {})
	var current: Dictionary = GameState.state["player"]["craftedCounts"]
	var min_each: int = int(params["minEach"])
	for recipe_key in params["recipeKeys"]:
		var since: int = int(current.get(recipe_key, 0)) - int(baseline.get(recipe_key, 0))
		if since < min_each:
			return false
	return true


# Fully completed BizBrief settlements (settlement.complete), read live from
# sales.contractHistory so completions from before activation count. Each
# settled recurring period is its own history entry, so counts as one; a
# cancelled contract's entry has no settlement, so never counts.
static func completed_contract_count() -> int:
	var count := 0
	for entry in GameState.state["sales"]["contractHistory"]:
		if entry.get("settlement", {}).get("complete", false):
			count += 1
	return count


# Fully completed settlements of contracts made from templateId, read live
# from sales.contractHistory; each recurring period counts as one.
static func completed_period_count(template_id: String) -> int:
	var count := 0
	for entry in GameState.state["sales"]["contractHistory"]:
		if entry.get("settlement", {}).get("complete", false) and entry["contract"].get("templateId", "") == template_id:
			count += 1
	return count


# { "current", "target" } for count-style objectives the ToDo app shows
# progress on, else {}. current is capped at target.
static func count_progress(def: Dictionary) -> Dictionary:
	var params: Dictionary = def.get("params", {})
	var target: int = int(params.get("minCount", 0))
	if def["type"] == TYPE_CONTRACTS_COMPLETED:
		return { "current": mini(completed_contract_count(), target), "target": target }
	if def["type"] == TYPE_TEMPLATE_PERIODS_COMPLETED:
		return { "current": mini(completed_period_count(params["templateId"]), target), "target": target }
	return {}


# { "value": float, "param": String } for tiered condition types: the live
# measured quantity and the tier param it's compared against, so ToDo can
# show progress toward a tier. {} for types without a measure.
static func measure(def: Dictionary) -> Dictionary:
	if def["type"] == TYPE_RESERVE_WEEKS_AT_LEAST:
		var expenses := BusinessStats.weekly_expenses()
		var weeks := 0.0 if expenses <= 0 else float(GameState.state["business"]["float"]) / float(expenses)
		return { "value": weeks, "param": "minWeeks" }
	if def["type"] == TYPE_ORE_SHARE_AT_LEAST:
		return { "value": Shares.ore_share(Shares.PLAYER, str(def["params"].get("oreType", ""))) * 100.0, "param": "minPercent" }
	if def["type"] == TYPE_CRAFTING_SHARE_AT_LEAST:
		return { "value": Shares.crafting_share(Shares.PLAYER, str(def["params"].get("oreType", ""))) * 100.0, "param": "minPercent" }
	return {}


# One all_of condition, read from live state (not a counter), so losing it
# un-meets it until the objective completes.
static func condition_met(condition: Dictionary) -> bool:
	match condition["kind"]:
		"contact_skill":
			return _contact_skill_level(condition) >= int(condition["minLevel"])
		"home_room":
			return GameState.state["home"]["rooms"].has(condition["roomId"])
		"recipe_known":
			return Lab.is_known(condition["recipe"])
		"weekly_expenses_above":
			return BusinessStats.weekly_expenses() > int(condition["amount"])
		"crafting_active":
			for ore_type in market_ores("craft"):
				if Shares.crafting_share(Shares.PLAYER, ore_type) > 0.0:
					return true
			return false
		"ore_market_active":
			return not market_ores().is_empty()
		"yield_baseline_above":
			return yield_baseline() > float(condition["amount"])
		"player_veins_at_least":
			return GameState.state["player"]["veins"].size() >= int(condition["minCount"])
		"ore_types_owned_between":
			var owned := _online_ore_types(0)
			return owned >= int(condition["minTypes"]) and owned < int(condition["maxTypes"])
		"ore_share_any_at_least":
			for ore_type in market_ores():
				if Shares.ore_share(Shares.PLAYER, ore_type) * 100.0 >= float(condition["minPercent"]):
					return true
			return false
	return false


# Ore types with production in the Shares 7-day window: the ones whose
# share means something. Canonical order.
static func market_ores(tally: String = "ore") -> Array[String]:
	var totals := Shares.window_totals(tally)
	var ores: Array[String] = []
	for ore_type in GameData.CANONICAL_ORE_TYPES:
		for by_type in totals.values():
			if int(by_type.get(ore_type, 0)) > 0:
				ores.append(ore_type)
				break
	return ores


# The player's share of params.oreType over the Shares 7-day window is at
# least params.minPercent; with params.lead, also the largest of any producer.
static func ore_share_met(params: Dictionary, tally: String = "ore") -> bool:
	var ore_type := str(params.get("oreType", ""))
	if ore_type == "" or not GameData.CANONICAL_ORE_TYPES.has(ore_type):
		return false
	if Shares.share(tally, Shares.PLAYER, ore_type) * 100.0 < float(params["minPercent"]):
		return false
	return not bool(params.get("lead", false)) or Shares.is_leader(tally, Shares.PLAYER, ore_type)


# R§3.15: the business float covers min_weeks of the business's real weekly
# expenses. No expenses yet means nothing to cover, so never met.
static func reserve_weeks_met(min_weeks: float) -> bool:
	var expenses := BusinessStats.weekly_expenses()
	if expenses <= 0:
		return false
	return float(GameState.state["business"]["float"]) >= min_weeks * float(expenses)


static func _contact_skill_level(condition: Dictionary) -> int:
	var contact: Dictionary = GameState.state["contacts"].get(condition["contactId"], {})
	return int(contact.get(condition["skill"] + "Skill", 0))


# biz-act1 spec §"Unattended proof": distinct contract ids with at least
# one qualified settlement, read live from sales.contractHistory, and how
# many of those request a crafted item. { "contracts": int, "crafted": int }
static func recurring_proof() -> Dictionary:
	var contract_ids := {}
	var crafted := {}
	for entry in GameState.state["sales"]["contractHistory"]:
		if not entry.get("settlement", {}).get("qualified", false):
			continue
		var contract: Dictionary = entry["contract"]
		contract_ids[contract["id"]] = true
		if requests_crafted(contract["request"]):
			crafted[contract["id"]] = true
	return { "contracts": contract_ids.size(), "crafted": crafted.size() }


static func requests_crafted(request: Dictionary) -> bool:
	for line in Contracts.request_lines(request):
		if line["kind"] != "ore":
			return true
	return false


# ToDo checklist rows for an all_of or recurring_proof objective:
# [{ "label", "detail", "done" }] (contact_skill shows "level n of N" as its
# detail), else [].
static func checklist(def: Dictionary) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	if def["type"] == TYPE_RECURRING_PROOF:
		return _recurring_proof_checklist(def["params"])
	if def["type"] != TYPE_ALL_OF:
		return rows
	for condition in def["params"]["conditions"]:
		var detail := ""
		if condition["kind"] == "contact_skill":
			var target: int = int(condition["minLevel"])
			detail = "level %d of %d" % [mini(_contact_skill_level(condition), target), target]
		rows.append({ "label": condition["label"], "detail": detail, "done": condition_met(condition) })
	return rows


# PROSE-REVIEW: Beat 7 ToDo checklist labels.
static func _recurring_proof_checklist(params: Dictionary) -> Array[Dictionary]:
	var proof := recurring_proof()
	var target: int = int(params["minContracts"])
	var crafted_target: int = int(params["minCrafted"])
	var rows: Array[Dictionary] = []
	rows.append({ "label": "Recurring orders that ran a full week without you", "detail": "%d of %d" % [mini(proof["contracts"], target), target], "done": proof["contracts"] >= target })
	rows.append({ "label": "One of them an order for something crafted", "detail": "", "done": proof["crafted"] >= crafted_target })
	return rows

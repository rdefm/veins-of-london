class_name Factions
extends RefCounted

# Faction joining/leaving, player-faction and faction-faction relation,
# faction vein ownership (claims, day-1 roster, security rolls), passive
# daily income, inter-faction rivalry, and economic-identity read helpers
# (R§1.8).


static func can_join(faction_id: String) -> bool:
	var f: Dictionary = GameState.state["factions"].get(faction_id, {})
	if f.is_empty() or f.get("joined", false):
		return false
	var join_relation: int = GameData.FACTIONS[faction_id]["joinRelation"]
	return f["relation"] >= join_relation


static func join(faction_id: String) -> Dictionary:
	if not can_join(faction_id):
		return { "ok": false, "reason": "Not eligible yet." }
	GameState.state["factions"][faction_id]["joined"] = true
	EventBus.state_changed.emit()
	return { "ok": true }


# Player-toward-faction relation (state.factions[id].relation), distinct
# from the faction-to-faction matrix below (state.factionRelations).
# Clamped to FactionAI's relation range.
static func adjust_player_relation(faction_id: String, delta: int) -> void:
	var f: Dictionary = GameState.state["factions"][faction_id]
	f["relation"] = FactionAI.clamp_relation(int(f["relation"]) + delta)
	EventBus.state_changed.emit()


# ── Economic identity (R§1.8) ───────────────────────────────────────────

# Factions whose primaryOre or secondaryOre is ore_type, in data order.
static func factions_crafting_with_ore(ore_type: String) -> Array[String]:
	var result: Array[String] = []
	for faction_id in GameData.FACTIONS:
		var f: Dictionary = GameData.FACTIONS[faction_id]
		if f["primaryOre"] == ore_type or f["secondaryOre"] == ore_type:
			result.append(faction_id)
	return result


# Factions whose `consumes` lists recipe_key, in data order.
static func factions_consuming(recipe_key: String) -> Array[String]:
	var result: Array[String] = []
	for faction_id in GameData.FACTIONS:
		if GameData.FACTIONS[faction_id]["consumes"].has(recipe_key):
			result.append(faction_id)
	return result


# ── Faction vein ownership ──────────────────────────────────────────────
# The daily NPC-claim roll (systems/sites.gd) seeds a canonical faction a real vein via create_faction_vein().

# roll_security_tier()'s base distribution before any faction/value/resource tilt.
const SECURITY_BASE_WEIGHTS: Dictionary = { "none": 40.0, "basic": 30.0, "warded": 20.0, "guarded": 10.0 }


# A faction's weight in a site's claim roll (R§1.8 claimWeights): base, plus
# presence if it's the district's factionPresence, plus primaryOre/secondaryOre
# if that ore matches the site's.
static func claim_weight(faction_id: String, district_id: String, ore_type: String) -> float:
	var faction: Dictionary = GameData.FACTIONS[faction_id]
	var w: Dictionary = faction["claimWeights"]
	var weight: float = w["base"]
	if GameData.DISTRICTS.get(district_id, {}).get("factionPresence", "") == faction_id:
		weight += w["presence"]
	if faction["primaryOre"] == ore_type:
		weight += w["primaryOre"]
	elif faction["secondaryOre"] == ore_type:
		weight += w["secondaryOre"]
	return weight


# Weighted claimant pick for a site's claim roll across all 5 factions (claim_weight()).
static func pick_claimant(district_id: String, ore_type: String) -> String:
	var ids: Array = GameData.FACTIONS.keys()
	var total := 0.0
	for faction_id in ids:
		total += claim_weight(faction_id, district_id, ore_type)
	var roll := Rng.randf() * total
	for faction_id in ids:
		roll -= claim_weight(faction_id, district_id, ore_type)
		if roll < 0.0:
			return faction_id
	return ids[-1]


# Instant vein for a claiming faction: oreType/district/hospitability come from the
# site, growth is the caller's choice, security is rolled fresh (roll_security_tier()).
static func create_faction_vein(faction_id: String, site: Dictionary, growth: int) -> Dictionary:
	var hospitability := { "tier": site["tier"], "bonuses": site["bonuses"] }
	var vein := Cultivating.make_vein(site["oreType"], growth, site["district"], site["id"], hospitability)
	vein["factionId"] = faction_id
	vein["security"] = roll_security_tier(faction_id, site["oreType"])
	vein["kit"] = {}
	return vein


# Security-tier roll from three signed tilts on SECURITY_BASE_WEIGHTS -- faction
# flavour bias, vein value (basePrice), faction resource balance -- toward warded/guarded.
static func roll_security_tier(faction_id: String, ore_type: String) -> String:
	var weights: Dictionary = SECURITY_BASE_WEIGHTS.duplicate()
	var opulence := _security_opulence(faction_id, ore_type)

	weights["guarded"] = maxf(0.0, weights["guarded"] + opulence * 4.0)
	weights["warded"] = maxf(0.0, weights["warded"] + opulence * 2.0)
	weights["basic"] = maxf(0.0, weights["basic"] - opulence * 2.0)
	weights["none"] = maxf(0.0, weights["none"] - opulence * 4.0)

	return _weighted_security_roll(weights)


# ore basePrice (R§1.1, per 10-unit lot) centres on the roster's ~90 midpoint, so an average-value
# ore contributes ~0 tilt; ORE_VALUE_SPREAD is a basePrice step worth 1 tilt. Resource input is the faction's real dynamic balance
# (state.factions[id].resources), not a static placeholder, so a faction that's
# spent itself poor on security rolls toward cheaper tiers next time.
# RESOURCE_OPULENCE_BASELINE is the 5 factions' mean starting resources;
# RESOURCE_OPULENCE_DIVISOR scales the 200-1200 starting spread to value_tilt's range.
const RESOURCE_OPULENCE_BASELINE := 660.0
const RESOURCE_OPULENCE_DIVISOR := 360.0
const ORE_VALUE_MIDPOINT := 90.0
const ORE_VALUE_SPREAD := 18.75


static func _security_opulence(faction_id: String, ore_type: String) -> float:
	var faction: Dictionary = GameData.FACTIONS[faction_id]
	var flavour_bias: float = faction.get("securityBias", 0.0)
	var balance: float = GameState.state["factions"][faction_id]["resources"]
	var resource_tilt: float = (balance - RESOURCE_OPULENCE_BASELINE) / RESOURCE_OPULENCE_DIVISOR
	var ore_value: float = GameData.ORE_TYPES.get(ore_type, {}).get("basePrice", ORE_VALUE_MIDPOINT)
	var value_tilt: float = (ore_value - ORE_VALUE_MIDPOINT) / ORE_VALUE_SPREAD
	return flavour_bias + value_tilt + resource_tilt


static func _weighted_security_roll(weights: Dictionary) -> String:
	var order: Array = Cultivating.VEIN_SECURITY_ORDER
	var weight_list: Array[float] = []
	for tier in order:
		weight_list.append(weights[tier])
	return order[weighted_pick_index(weight_list)]


# Shared cumulative-weighted-roll: index i chosen with probability
# weights[i] / sum(weights). Used by the security-tier roll above, the
# rivalry target-vein pick below, and Raiding._pick_worst_relation_faction().
static func weighted_pick_index(weights: Array[float]) -> int:
	var total: float = 0.0
	for w in weights:
		total += w

	var roll: float = Rng.randf() * total
	var cumulative: float = 0.0
	for i in range(weights.size()):
		cumulative += weights[i]
		if roll < cumulative:
			return i
	return weights.size() - 1


# ── Daily passive industry income ───────────────────────────────────────
# Non-calc income: each faction's factions.json `industryIncome` £/day, every
# daily tick regardless of vein count (spec §Faction cash).
static func apply_passive_income() -> void:
	for faction_id in GameState.state["factions"].keys():
		GameState.state["factions"][faction_id]["resources"] += int(GameData.FACTIONS[faction_id].get("industryIncome", 0))


# ── Daily security-upgrade spend ─────────────────────────────────────────
# A faction with spare resources (£, after today's trading and Monday wages) quietly hardens one held vein
# each tick (spec §Faction guard upkeep, Hiring). First the tier ladder up to "guarded" (lock and ward
# rune at table price; "guarded" costs the guard hire advance), highest vein_value()
# vein first. Only once no vein below "guarded" is eligible and affordable does it hire an extra guard,
# highest-value vein first, up to maxExtraGuardsPerVein. Any guard hire also needs the wage reserve
# (GuardUpkeep.faction_can_hire). Frozen veins are skipped; nothing eligible is a no-op.
static func apply_security_upgrades() -> void:
	for faction_id in GameState.state["factions"].keys():
		var veins: Array = []
		for site in GameState.state["world"]["sites"]:
			var vein: Variant = site["factionVein"]
			if vein != null and vein["factionId"] == faction_id and not NetworkHandler.is_security_frozen(site["id"]):
				veins.append(vein)
		if not _apply_tier_upgrade(faction_id, veins):
			_hire_extra_guard(faction_id, veins)


# The highest-value vein below "guarded" whose next tier the faction can pay for; true if one was upgraded.
static func _apply_tier_upgrade(faction_id: String, veins: Array) -> bool:
	var faction_state: Dictionary = GameState.state["factions"][faction_id]
	var can_hire := GuardUpkeep.faction_can_hire(faction_id)
	var eligible: Array = veins.filter(func(vein: Dictionary) -> bool:
		var next_id: Variant = Cultivating.next_security_tier_id(vein["security"])
		if next_id == null:
			return false
		if next_id == Cultivating.GUARDED_TIER_ID:
			return can_hire
		return faction_state["resources"] >= Cultivating.security_tier_cost(next_id))
	var vein: Variant = _most_valuable(eligible)
	if vein == null:
		return false
	var next_id: String = Cultivating.next_security_tier_id(vein["security"])
	faction_state["resources"] -= Cultivating.security_tier_cost(next_id)
	vein["security"] = next_id
	return true


# One extra guard on the highest-value "guarded" vein under the per-vein cap, if the wage reserve allows.
static func _hire_extra_guard(faction_id: String, veins: Array) -> void:
	if not GuardUpkeep.faction_can_hire(faction_id):
		return
	var cap := GuardUpkeep.faction_max_extra_guards()
	var vein: Variant = _most_valuable(veins.filter(func(v: Dictionary) -> bool:
		return v["security"] == Cultivating.GUARDED_TIER_ID and int(v.get("extraGuards", 0)) < cap))
	if vein == null:
		return
	GameState.state["factions"][faction_id]["resources"] -= GuardUpkeep.hire_advance()
	vein["extraGuards"] = int(vein.get("extraGuards", 0)) + 1


# A vein's worth in faction AI scoring: its ore's London quote (R§3.13) times combined_magnitude.
static func vein_value(vein: Dictionary) -> float:
	return float(Market.quote("ore", vein["oreType"])) * Cultivating.combined_magnitude(vein)


# Highest vein_value() vein, first in list order on a tie; null for an empty list.
static func _most_valuable(veins: Array) -> Variant:
	var best: Variant = null
	var best_value := -1.0
	for vein in veins:
		var value := vein_value(vein)
		if value > best_value:
			best_value = value
			best = vein
	return best


# ── Faction-to-faction relation matrix ──────────────────────────────────
# state.factionRelations holds one shared relation per pair, stored in both
# directions ([a][b] == [b][a]) -- distinct from the player-facing
# state.factions[id].relation the join logic above uses.

# self-vs-self is a documented no-op / always-0 read, not an error.
static func get_relation(faction_a: String, faction_b: String) -> int:
	if faction_a == faction_b:
		return 0
	return GameState.state["factionRelations"][faction_a][faction_b]


static func adjust_relation(faction_a: String, faction_b: String, delta: int) -> void:
	if faction_a == faction_b:
		return
	var relations: Dictionary = GameState.state["factionRelations"]
	var value := FactionAI.clamp_relation(int(relations[faction_a][faction_b]) + delta)
	relations[faction_a][faction_b] = value
	relations[faction_b][faction_a] = value


# ── Rivalry initiation roll ─────────────────────────────────────────────
# Decides who throws a punch and at what; whether it lands is rivalry_success_chance()'s job.

# Reuses the `industries` field rather than a separate aggression stat -- "raiding"
# dominates, the other four get a small trickle so any faction can occasionally initiate.
const INDUSTRY_AGGRESSION: Dictionary = {
	"raiding": 0.35,
	"influence": 0.05,
	"crafting": 0.03,
	"trading": 0.02,
	"sourcing": 0.02,
}

# Floor under INDUSTRY_AGGRESSION's trickle so every faction has some baseline chance to initiate.
const BASE_INITIATION_CHANCE := 0.05


# One roll per faction per tick; a faction with zero rival-held veins is never eligible.
static func roll_rivalry_attempts() -> Array:
	var attempts := []
	for faction_id in GameData.FACTIONS.keys():
		var candidates: Array = _eligible_rival_veins(faction_id)
		if candidates.is_empty():
			continue
		if not Rng.chance(_initiation_chance(faction_id)):
			continue
		var target: Dictionary = _pick_target_vein(faction_id, candidates)
		attempts.append({
			"attackerId": faction_id,
			"defenderId": target["vein"]["factionId"],
			"veinSiteId": target["site"]["id"],
		})
	return attempts


static func _initiation_chance(faction_id: String) -> float:
	var industries: Array = GameData.FACTIONS[faction_id].get("industries", [])
	var aggression := 0.0
	for industry in industries:
		aggression += INDUSTRY_AGGRESSION.get(industry, 0.0)
	return BASE_INITIATION_CHANCE + aggression


# Every {site, vein} pair held by a different faction than faction_id.
static func _eligible_rival_veins(faction_id: String) -> Array:
	var candidates := []
	for site in GameState.state["world"]["sites"]:
		var vein: Variant = site.get("factionVein")
		if vein == null or vein["factionId"] == faction_id or Collective.is_quest_locked_vein(vein["id"]):
			continue
		candidates.append({ "site": site, "vein": vein })
	return candidates


# Weighted by vein_value() -- attackers favour a rival's crown jewel over scraps.
# Collective.firm_target_multiplier() scales that while the Firm is provoked (spec §6.7).
static func _pick_target_vein(attacker_id: String, candidates: Array) -> Dictionary:
	var weight_list: Array[float] = []
	for candidate in candidates:
		var vein: Dictionary = candidate["vein"]
		weight_list.append(vein_value(vein) * Collective.firm_target_multiplier(attacker_id, vein["factionId"]))
	return candidates[weighted_pick_index(weight_list)]


# ── Rivalry odds ─────────────────────────────────────────────────────────
# Scores one attempt and rolls success; no state mutation -- ownership transfer
# and relation writes are resolve_rivalry_outcome()'s job.

# Coin-flip baseline; the three tilts below push it up or down.
const RIVALRY_BASE_CHANCE := 0.5

# Normalises attacker-defender resource gap against the tens-of-thousands spread
# faction calc sales build within a couple of months (scripts/sim_faction_economy.gd),
# so the tilt stays roughly +/-1 before WEIGHT scales it rather than saturating.
const RIVALRY_RESOURCE_DIVISOR := 50000.0
const RIVALRY_RESOURCE_WEIGHT := 0.25

# Normalises against "guarded" raidResist (55, R§1.6) so the base tilt stays within
# [0, 1] before WEIGHT scales it. Not a hard ceiling -- stacked extraGuards can push
# raidResist past 55, pushing the tilt further negative (clamped by clampf below).
const RIVALRY_RAID_RESIST_DIVISOR := 55.0
const RIVALRY_RAID_RESIST_WEIGHT := 0.25

# Relation drift is unbounded over a long save unlike the other two inputs -- 100 is
# picked so a handful of grudge writes move the odds without one bad tick maxing it.
const RIVALRY_RELATION_DIVISOR := 100.0
const RIVALRY_RELATION_WEIGHT := 0.25


# Success chance for one attempt: higher attacker resources / lower defender
# resources, lower raidResist, and a worse defender-toward-attacker relation all
# push it up, clamped to [0, 1]. A vein already claimed this tick reads as chance 0.
static func rivalry_success_chance(attempt: Dictionary) -> float:
	var attacker_resources: int = GameState.state["factions"][attempt["attackerId"]]["resources"]
	var defender_resources: int = GameState.state["factions"][attempt["defenderId"]]["resources"]
	var resource_tilt: float = float(attacker_resources - defender_resources) / RIVALRY_RESOURCE_DIVISOR * RIVALRY_RESOURCE_WEIGHT

	var site: Variant = Sites.find_site(attempt["veinSiteId"])
	if site == null:
		return 0.0
	var raid_resist: int = Cultivating.vein_raid_resist(site["factionVein"])
	var security_tilt: float = -(float(raid_resist) / RIVALRY_RAID_RESIST_DIVISOR) * RIVALRY_RAID_RESIST_WEIGHT

	var relation: int = get_relation(attempt["defenderId"], attempt["attackerId"])
	var relation_tilt: float = -(float(relation) / RIVALRY_RELATION_DIVISOR) * RIVALRY_RELATION_WEIGHT

	# Network Targets intel is the Collective's own (spec §5.3), so it only tilts Collective attacks.
	var intel_bonus: float = NetworkHandler.claim_bonus(attempt["veinSiteId"]) if attempt["attackerId"] == "collective" else 0.0

	var chance: float = RIVALRY_BASE_CHANCE + resource_tilt + security_tilt + relation_tilt + intel_bonus
	return clampf(chance, 0.0, 1.0)


# Rolls the chance above; returns the attempt annotated with its resolved "success" outcome (still pure, no mutation).
# A success then faces the defender vein's guard repel roll (Raiding.guards_repel,
# spec §Faction guard upkeep → faction vein guard repel): a repel flips it to a
# failure marked "repelled". Only rolled while the vein is still the defender's.
static func roll_rivalry_odds(attempt: Dictionary) -> Dictionary:
	var outcome: Dictionary = attempt.duplicate()
	outcome["success"] = Rng.chance(rivalry_success_chance(attempt))
	outcome["repelled"] = false
	if outcome["success"]:
		var site: Variant = Sites.find_site(attempt["veinSiteId"])
		var vein: Variant = site["factionVein"] if site != null else null
		if vein != null and vein["factionId"] == attempt["defenderId"] and Raiding.guards_repel(vein):
			outcome["success"] = false
			outcome["repelled"] = true
	return outcome


# ── Rivalry resolution ──────────────────────────────────────────────────
# Daily-tick hook, run right after NPC claims (before FactionSim, so it reads
# end-of-yesterday resources and its kit burns land in today's consume): rolls
# this tick's batch of attempts through the odds above and applies
# resolve_rivalry_outcome() to each result. Does nothing while constants.json
# factionRivalry is false.

# Relation-feedback magnitude on success -- big enough that repeated losses to the
# same rival compound, small enough that one loss alone doesn't saturate the divisor.
const RIVALRY_RELATION_PENALTY := -15


static func apply_rivalry_resolution() -> void:
	if not GameData.FACTION_RIVALRY:
		return
	for attempt in roll_rivalry_attempts():
		# Every attempt, won or lost, burns both sides' raid kits (spec §Consumption).
		FactionSim.log_kit_burn(attempt["attackerId"], "attack", "rivalry")
		FactionSim.log_kit_burn(attempt["defenderId"], "defend", "rivalry")
		resolve_rivalry_outcome(roll_rivalry_odds(attempt))


# Applies one already-rolled outcome; a failed attempt is a no-op. On success:
# reassigns factionId (other fields unchanged), worsens the defender's relation
# toward the attacker, and queues a seed_claim map event (MapCanvas reads factionId
# live, so this plays whether the vein is new or just changed hands). Re-checks the
# site's current factionId against the outcome's recorded defenderId, since two
# attempts in the same batch can target the same vein -- already-flipped veins are
# silently skipped rather than transferred twice. No Notify/Ticker push either way.
static func resolve_rivalry_outcome(outcome: Dictionary) -> void:
	if not outcome["success"]:
		return

	var site: Variant = Sites.find_site(outcome["veinSiteId"])
	if site == null:
		return
	var vein: Variant = site["factionVein"]
	if vein == null or vein["factionId"] != outcome["defenderId"]:
		return

	vein["factionId"] = outcome["attackerId"]
	adjust_relation(outcome["defenderId"], outcome["attackerId"], RIVALRY_RELATION_PENALTY)
	MapEvents.queue_seed_claim(site["district"], vein["id"], outcome["attackerId"])


# ── Day-1 starting veins ─────────────────────────────────────────────────
# New-game-only seeding so the other 5 factions don't feel absent while the daily
# NPC-claim tick slowly builds up. Reuses the site+vein mechanism but fabricates a
# brand-new site per starting vein. Each roster entry is one vein's fixed ore type
# (~2/3 the faction's primaryOre, the rest its secondaryOre). vein_growth.json sets
# the rest (R§1.8 "Day-one roster"): every vein starts at dayOneFactionGrowth, its
# district-rolled terroir tier is raised dayOneFactionTierBump steps, and the first
# dayOneFactionMaxLevelShare of each faction's roster starts at its tier's level
# cap, the rest one level below. District counts match data/districts.json's
# siteCap bump -- each district below appears in exactly that many starting veins.
const DAY_ONE_ROSTER: Dictionary = {
	"collective": [
		{ "district": "shoreditch", "ores": ["life", "life", "emotion", "life"] },
		{ "district": "whitechapel", "ores": ["life", "emotion", "life", "emotion"] },
	],
	"firm": [
		{ "district": "camden", "ores": ["physics", "physics", "time", "physics", "time"] },
		{ "district": "battersea", "ores": ["physics", "life", "physics", "time"] },
	],
	"guild": [
		{ "district": "greenwich", "ores": ["time", "time", "physics", "time", "time", "physics", "time", "physics", "time"] },
	],
	"network": [
		{ "district": "kingscross", "ores": ["emotion", "emotion", "fate", "emotion", "emotion"] },
	],
	"conclave": [
		{ "district": "city", "ores": ["fate", "fate", "time", "fate", "time", "fate", "time", "fate", "life", "fate", "time"] },
	],
}


# Called once by New Game, always right after GameState.reset() -- never folded into
# reset() itself, since tests expect reset() to produce a bare state with empty sites.
static func seed_day_one_veins() -> void:
	var share: float = GameData.VEIN_GROWTH["dayOneFactionMaxLevelShare"]
	for faction_id in DAY_ONE_ROSTER.keys():
		var total := 0
		for group in DAY_ONE_ROSTER[faction_id]:
			total += group["ores"].size()
		var at_cap: int = roundi(total * share)
		var placed := 0
		for group in DAY_ONE_ROSTER[faction_id]:
			for ore_type in group["ores"]:
				_seed_day_one_vein(faction_id, group["district"], ore_type, placed < at_cap)
				placed += 1
	EventBus.state_changed.emit()


# Site/security roll exactly as a normal NPC claim, with the roster's ore type,
# growth, tier bump and level. No MapEvents queueing or Notify/XP -- these veins
# exist from game start, nothing to animate.
static func _seed_day_one_vein(faction_id: String, district_id: String, ore_type: String, at_cap: bool) -> void:
	var vg: Dictionary = GameData.VEIN_GROWTH
	var order: Array = GameData.SITE_TIER_ORDER
	var rolled := Sites.roll_tier(district_id)
	var tier: String = order[mini(order.find(rolled) + int(vg["dayOneFactionTierBump"]), order.size() - 1)]
	var site := Sites.roll_new_site(district_id, tier)
	site["oreType"] = ore_type

	var vein := create_faction_vein(faction_id, site, int(vg["dayOneFactionGrowth"]))
	var cap: int = Cultivating.level_cap(vein)
	vein["level"] = cap if at_cap else maxi(1, cap - 1)
	site["factionVein"] = vein

	GameState.state["world"]["sites"].append(site)

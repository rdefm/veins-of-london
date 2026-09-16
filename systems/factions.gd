class_name Factions
extends RefCounted

# Faction joining/leaving, player-faction and faction-faction relation,
# faction vein ownership (claims, day-1 roster, security rolls), passive
# daily income, and inter-faction rivalry (R§1.8).


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
static func adjust_player_relation(faction_id: String, delta: int) -> void:
	GameState.state["factions"][faction_id]["relation"] += delta
	EventBus.state_changed.emit()


# ── Collective ore stock + restocking ───────────────────────────────────
# An independently-scarce buy-lane cap, unrelated to relation (relation
# narrows price via get_faction_buy/sell_spread; this caps quantity).
# Schema-present on every faction but only "collective" is rolled/read.
const ORE_STOCK_RESTOCK_CHANCE := 0.30
const ORE_STOCK_QTY_MIN := 5
const ORE_STOCK_QTY_MAX := 20


# Rerolls all 5 ore types together, replacing rather than adding. Silent
# by design -- no Notify/Ticker push.
static func restock_ore(faction_id: String) -> void:
	var stock: Dictionary = GameState.state["factions"][faction_id]["oreStock"]
	for ore_type in GameData.CANONICAL_ORE_TYPES:
		stock[ore_type] = Rng.randi_range(ORE_STOCK_QTY_MIN, ORE_STOCK_QTY_MAX)


# Called from TimeSystem.daily_tick(). Collective-only; other factions'
# oreStock stays schema-present but untouched.
static func maybe_restock_ore() -> void:
	if Rng.chance(ORE_STOCK_RESTOCK_CHANCE):
		restock_ore("collective")


# ── Faction vein ownership ──────────────────────────────────────────────
# The daily NPC-claim roll (systems/sites.gd) seeds one of the 5 canonical
# factions a real vein via create_faction_vein().

# A district's presence faction usually wins its own claim roll; this is
# the chance a rival muscles in instead.
const RIVAL_ENCROACH_CHANCE := 0.15

# roll_security_tier()'s base distribution before any faction/value/
# resource tilt is applied.
const SECURITY_BASE_WEIGHTS: Dictionary = { "none": 40.0, "basic": 30.0, "warded": 20.0, "guarded": 10.0 }


# Weighted claimant pick for a district's daily claim roll. Favours the
# district's factionPresence; falls back to a uniform pick across all 5
# factions when there's no presence (or the rival-encroach roll hits).
static func pick_claimant(district_id: String) -> String:
	var canonical: Array = GameData.FACTIONS.keys()
	var presence: String = GameData.DISTRICTS.get(district_id, {}).get("factionPresence", "")

	if presence == "" or not GameData.FACTIONS.has(presence):
		return Rng.rand_from(canonical)

	if Rng.chance(RIVAL_ENCROACH_CHANCE):
		var rivals: Array = canonical.filter(func(f): return f != presence)
		return Rng.rand_from(rivals)

	return presence


# Instant vein for a claiming faction: oreType/district/hospitability come
# from the site; growth is the caller's choice. Security is rolled fresh
# (see roll_security_tier()).
static func create_faction_vein(faction_id: String, site: Dictionary, growth: int) -> Dictionary:
	var hospitability := { "tier": site["tier"], "bonuses": site["bonuses"] }
	var vein := Cultivating.make_vein(site["oreType"], growth, site["district"], site["id"], hospitability)
	vein["factionId"] = faction_id
	vein["security"] = roll_security_tier(faction_id, site["oreType"])
	return vein


# Security-tier roll from three signed tilts on SECURITY_BASE_WEIGHTS:
# faction flavour bias, vein value (ore basePrice), and faction resource
# balance -- positive tilts weight toward warded/guarded.
static func roll_security_tier(faction_id: String, ore_type: String) -> String:
	var weights: Dictionary = SECURITY_BASE_WEIGHTS.duplicate()
	var opulence := _security_opulence(faction_id, ore_type)

	weights["guarded"] = maxf(0.0, weights["guarded"] + opulence * 4.0)
	weights["warded"] = maxf(0.0, weights["warded"] + opulence * 2.0)
	weights["basic"] = maxf(0.0, weights["basic"] - opulence * 2.0)
	weights["none"] = maxf(0.0, weights["none"] - opulence * 4.0)

	return _weighted_security_roll(weights)


# ore basePrice (R§1.1) centres on the roster's ~72 midpoint so an
# average-value ore contributes ~0 tilt.
#
# Resource input is the faction's real dynamic balance (state.factions[id]
# .resources), not a static placeholder -- a faction that's spent itself
# poor on security upgrades rolls toward cheaper tiers next time.
# RESOURCE_OPULENCE_BASELINE is the mean of the 5 factions' starting
# resources; RESOURCE_OPULENCE_DIVISOR scales the 200-1200 starting spread
# to a tilt comparable to value_tilt's.
const RESOURCE_OPULENCE_BASELINE := 660.0
const RESOURCE_OPULENCE_DIVISOR := 360.0


static func _security_opulence(faction_id: String, ore_type: String) -> float:
	var faction: Dictionary = GameData.FACTIONS[faction_id]
	var flavour_bias: float = faction.get("securityBias", 0.0)
	var balance: float = GameState.state["factions"][faction_id]["resources"]
	var resource_tilt: float = (balance - RESOURCE_OPULENCE_BASELINE) / RESOURCE_OPULENCE_DIVISOR
	var ore_value: float = GameData.ORE_TYPES.get(ore_type, {}).get("basePrice", 72.0)
	var value_tilt: float = (ore_value - 72.0) / 15.0
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
# Fixed £/day per industry, independent of vein count. Tiered so grunt-work
# industries (trading/sourcing) sit lowest and influence/crafting highest,
# matching each faction's flavour text.
const INDUSTRY_INCOME: Dictionary = {
	"sourcing": 6,
	"trading": 8,
	"raiding": 10,
	"influence": 16,
	"crafting": 18,
}


# Runs every daily tick for every faction regardless of vein count.
static func apply_passive_income() -> void:
	for faction_id in GameState.state["factions"].keys():
		var industries: Array = GameData.FACTIONS[faction_id].get("industries", [])
		var income := 0
		for industry in industries:
			income += INDUSTRY_INCOME.get(industry, 0)
		GameState.state["factions"][faction_id]["resources"] += income


# ── Daily vein-derived income ────────────────────────────────────────────
# Same ore-value-to-cash conversion as the player's sell loop
# (Economy.execute_sale), but automated -- no mugging or district price
# mod. VEIN_INCOME_DIVISOR is tuned so a fresh tier-1 vein of a mid-range
# ore nets ~£5/day, and a tier-5 fate vein ~£30/day.
const VEIN_INCOME_DIVISOR := 15.0


# Called from TimeSystem.daily_tick() after passive income. Skips a vein
# claimed this same tick so it doesn't earn income before a full day has
# passed (mirrors the same exemption growth uses).
static func apply_vein_income() -> void:
	var day: int = GameState.state["world"]["day"]
	for site in GameState.state["world"]["sites"]:
		var vein: Variant = site["factionVein"]
		if vein == null or vein["claimedOnDay"] >= day:
			continue
		var base_price: int = GameData.ORE_TYPES[vein["oreType"]]["basePrice"]
		var income: int = GameState.round_epsilon(base_price * Cultivating.value_tier(vein) / VEIN_INCOME_DIVISOR)
		GameState.state["factions"][vein["factionId"]]["resources"] += income


# ── Daily security-upgrade spend ─────────────────────────────────────────
# A faction with money to spare quietly hardens its highest-value held
# vein each tick (same ladder/cost table as the player's own
# upgrade_vein_security()), funded from its own resources.
#
# One upgrade per faction per tick, targeting the vein with the highest
# basePrice * value_tier among veins both below max security and
# affordable. No eligible/affordable vein is a no-op.
static func apply_security_upgrades() -> void:
	for faction_id in GameState.state["factions"].keys():
		var faction_state: Dictionary = GameState.state["factions"][faction_id]
		var best_vein: Variant = null
		var best_next_id: String = ""
		var best_cost: int = 0
		var best_value: float = -1.0

		for site in GameState.state["world"]["sites"]:
			var vein: Variant = site["factionVein"]
			if vein == null or vein["factionId"] != faction_id:
				continue
			var next_id: Variant = Cultivating.next_security_tier_id(vein["security"])
			if next_id == null:
				continue
			var cost: int = GameData.VEIN_SECURITY[next_id]["cost"]
			if faction_state["resources"] < cost:
				continue
			var value: float = GameData.ORE_TYPES[vein["oreType"]]["basePrice"] * Cultivating.value_tier(vein)
			if value > best_value:
				best_value = value
				best_vein = vein
				best_next_id = next_id
				best_cost = cost

		if best_vein == null:
			continue
		faction_state["resources"] -= best_cost
		best_vein["security"] = best_next_id


# ── Faction-to-faction relation matrix ──────────────────────────────────
# state.factionRelations: a's relation *toward* b, distinct from the
# player-facing state.factions[id].relation the join logic above uses.

# self-vs-self is a documented no-op / always-0 read, not an error.
static func get_relation(faction_a: String, faction_b: String) -> int:
	if faction_a == faction_b:
		return 0
	return GameState.state["factionRelations"][faction_a][faction_b]


static func adjust_relation(faction_a: String, faction_b: String, delta: int) -> void:
	if faction_a == faction_b:
		return
	GameState.state["factionRelations"][faction_a][faction_b] += delta


# ── Rivalry initiation roll ─────────────────────────────────────────────
# Decides who throws a punch and at what. Whether it lands is
# rivalry_success_chance()'s job below.

# Reuses the `industries` field rather than a separate aggression stat.
# "raiding" dominates; the other four get a small trickle so a faction can
# still occasionally initiate without a raiding-flavoured industry.
const INDUSTRY_AGGRESSION: Dictionary = {
	"raiding": 0.35,
	"influence": 0.05,
	"crafting": 0.03,
	"trading": 0.02,
	"sourcing": 0.02,
}

# Floor under INDUSTRY_AGGRESSION's trickle so every faction has some
# baseline chance to initiate.
const BASE_INITIATION_CHANCE := 0.05


# One roll per faction per tick. A faction with zero rival-held veins is
# never eligible.
static func roll_rivalry_attempts() -> Array:
	var attempts := []
	for faction_id in GameData.FACTIONS.keys():
		var candidates: Array = _eligible_rival_veins(faction_id)
		if candidates.is_empty():
			continue
		if not Rng.chance(_initiation_chance(faction_id)):
			continue
		var target: Dictionary = _pick_target_vein(candidates)
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
		if vein == null or vein["factionId"] == faction_id:
			continue
		candidates.append({ "site": site, "vein": vein })
	return candidates


# Weighted by vein value (basePrice * value_tier) -- an attacker is more
# likely to go after a rival's crown jewel than its scraps.
static func _pick_target_vein(candidates: Array) -> Dictionary:
	var weight_list: Array[float] = []
	for candidate in candidates:
		var vein: Dictionary = candidate["vein"]
		weight_list.append(GameData.ORE_TYPES[vein["oreType"]]["basePrice"] * Cultivating.value_tier(vein))
	return candidates[weighted_pick_index(weight_list)]


# ── Rivalry odds ─────────────────────────────────────────────────────────
# Scores one attempt record and rolls whether it succeeds. No state
# mutation -- ownership transfer and relation writes are
# resolve_rivalry_outcome()'s job.

# Coin-flip baseline; the three tilts below push it up or down.
const RIVALRY_BASE_CHANCE := 0.5

# Normalises attacker-defender resource gap against the roster's starting
# spread (200-1200) so a realistic early-game disparity's tilt stays
# within roughly +/-1 before WEIGHT scales it down.
const RIVALRY_RESOURCE_DIVISOR := 1000.0
const RIVALRY_RESOURCE_WEIGHT := 0.25

# Normalises against "guarded" raidResist (55, R§1.6) so the base tier
# ladder stays within [0, 1] before WEIGHT scales it down. Not a hard
# ceiling: stacked extraGuards can push raidResist past 55, which just
# keeps pushing the tilt further negative (clamped by this function's own
# clampf below).
const RIVALRY_RAID_RESIST_DIVISOR := 55.0
const RIVALRY_RAID_RESIST_WEIGHT := 0.25

# Relation drift is unbounded over a long save, unlike the other two
# inputs -- 100 is picked so a handful of grudge writes meaningfully move
# the odds without one bad tick maxing out the tilt.
const RIVALRY_RELATION_DIVISOR := 100.0
const RIVALRY_RELATION_WEIGHT := 0.25


# Success chance for one attempt. Higher attacker resources / lower
# defender resources, lower raidResist, and a worse defender-toward-
# attacker relation all push the chance up; clamped to [0, 1]. A target
# vein already claimed by another same-tick attempt reads as chance 0.
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

	var chance: float = RIVALRY_BASE_CHANCE + resource_tilt + security_tilt + relation_tilt
	return clampf(chance, 0.0, 1.0)


# Rolls the chance above and returns the attempt annotated with its
# resolved "success" outcome. Still pure -- no state mutation.
static func roll_rivalry_odds(attempt: Dictionary) -> Dictionary:
	var outcome: Dictionary = attempt.duplicate()
	outcome["success"] = Rng.chance(rivalry_success_chance(attempt))
	return outcome


# ── Rivalry resolution ──────────────────────────────────────────────────
# Called from TimeSystem.daily_tick() after security upgrades. Rolls this
# tick's batch of attempts through the odds above and applies
# resolve_rivalry_outcome() to each result.

# Relation-feedback magnitude on a successful attempt -- large enough that
# repeated losses to the same rival compound meaningfully, small enough
# that one loss alone doesn't saturate RIVALRY_RELATION_DIVISOR.
const RIVALRY_RELATION_PENALTY := -15


static func apply_rivalry_resolution() -> void:
	for attempt in roll_rivalry_attempts():
		resolve_rivalry_outcome(roll_rivalry_odds(attempt))


# Applies one already-rolled outcome. A failed attempt is a no-op.
# On success: reassigns factionId (other fields carry over unchanged),
# worsens the defender's relation toward the attacker, and queues a
# seed_claim map event (MapCanvas reads the vein's current factionId live,
# so this plays whether the vein is new or just changed hands).
#
# Re-checks the site's current factionId against this outcome's recorded
# defenderId, since two attempts in the same tick's batch can target the
# same vein -- a vein that already changed hands this tick is silently
# skipped rather than transferred twice. Silent throughout: no Notify/
# Ticker push on either outcome.
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
# New-game-only seeding so the other 5 factions don't feel absent while
# the daily NPC-claim tick above slowly builds up. Reuses the same
# site+vein mechanism, but fabricates a brand-new site per starting vein
# and passes a fixed roster growth instead of seedGrowth.
#
# Per-faction growth lists are fixed constants, not re-rolled per game.
# Each was rolled once within the roster's 1-5 level range, then mapped to
# growth via growth = 20n - 10 (Lv1->10 ... Lv5->90).
#
# District counts here match data/districts.json's siteCap bump for each
# district -- every district below appears in exactly that many starting
# veins.
const DAY_ONE_ROSTER: Dictionary = {
	"collective": [
		{ "district": "shoreditch", "growths": [50, 10, 50, 50] },
		{ "district": "whitechapel", "growths": [10, 30, 10, 50] },
	],
	"firm": [
		{ "district": "camden", "growths": [50, 50] },
		{ "district": "battersea", "growths": [50, 30] },
	],
	"guild": [
		{ "district": "greenwich", "growths": [30, 30, 50, 50, 30, 70, 70] },
	],
	"network": [
		{ "district": "kingscross", "growths": [70, 70, 50, 70] },
	],
	"conclave": [
		{ "district": "city", "growths": [50, 50, 30, 70, 90, 90, 90] },
	],
}


# Called once by a real New Game flow, always right after GameState.reset()
# -- never folded into reset() itself, since tests expect reset() to
# produce a bare state with empty world.sites.
static func seed_day_one_veins() -> void:
	for faction_id in DAY_ONE_ROSTER.keys():
		for group in DAY_ONE_ROSTER[faction_id]:
			var district_id: String = group["district"]
			for growth in group["growths"]:
				_seed_day_one_vein(faction_id, district_id, growth)
	EventBus.state_changed.emit()


# Site/security roll exactly as a normal NPC claim; only growth is fixed.
# No MapEvents queueing or Notify/XP -- these veins exist from game start,
# so there's nothing to animate or award XP for.
static func _seed_day_one_vein(faction_id: String, district_id: String, growth: int) -> void:
	var tier := Sites.roll_tier(district_id)
	var site := Sites.roll_new_site(district_id, tier)

	var vein := create_faction_vein(faction_id, site, growth)
	site["factionVein"] = vein

	GameState.state["world"]["sites"].append(site)

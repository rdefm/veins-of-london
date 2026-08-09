class_name Factions
extends RefCounted

# Faction joining. Like Equipment (T12 1/4) and Modal (T12 2/4), this is
# a small gap: R§3 never gives a "join faction" formula, and no earlier
# task claims it, but the factions screen needs a system function to call
# rather than mutating state.factions directly.


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


# ── faction vein ownership (faction-vein-ownership T01) ────────────────
# Reuses systems/sites.gd's existing daily-tick claim roll: instead of
# flipping an anonymous npcClaimed flag, that roll now names one of the 5
# canonical factions via pick_claimant() and instantly seeds it a real vein
# via create_faction_vein() — one atomic event, same as today.

# Presence factions win the district most of the time; a small chance a
# rival muscles in instead. Exact split left to the implementer per the
# PRD — 15% reads as "usually the local faction, sometimes contested".
const RIVAL_ENCROACH_CHANCE := 0.15

# roll_security_tier()'s distribution before any faction/value/resource
# tilt is applied — skewed toward cheap by default (most veins are
# lightly secured; the tilt below is what makes some factions/ores/pockets
# more fortified than others).
const SECURITY_BASE_WEIGHTS: Dictionary = { "none": 40.0, "basic": 30.0, "warded": 20.0, "guarded": 10.0 }


# Weighted claimant pick for a district's daily-tick claim roll (systems/
# sites.gd). Heavily favours the district's factionPresence; a district
# with none (e.g. Hampstead) — and the small rival-encroachment roll for
# districts that DO have a presence faction — both fall back to a uniform
# pick across all 5 canonical factions, per the ticket's explicit "sane
# default... rather than... always picking a fixed faction".
static func pick_claimant(district_id: String) -> String:
	var canonical: Array = GameData.FACTIONS.keys()
	var presence: String = GameData.DISTRICTS.get(district_id, {}).get("factionPresence", "")

	if presence == "" or not GameData.FACTIONS.has(presence):
		return Rng.rand_from(canonical)

	if Rng.chance(RIVAL_ENCROACH_CHANCE):
		var rivals: Array = canonical.filter(func(f): return f != presence)
		return Rng.rand_from(rivals)

	return presence


# Instant Lv1 vein for a claiming faction (D2-equivalent "claim = instant
# vein", no unseeded intermediate state): oreType/district/hospitability
# inherited from the site, devBar per the same skill-floor-1 convention
# ticket 02's daily virtual-cultivate rolls use (factions have no skill
# stat). Security is rolled fresh — see roll_security_tier().
static func create_faction_vein(faction_id: String, site: Dictionary) -> Dictionary:
	var hospitability := { "tier": site["tier"], "bonuses": site["bonuses"] }
	var vein := Cultivating.make_vein(site["oreType"], Cultivating.get_bar_gain(1), site["district"], site["id"], hospitability)
	vein["factionId"] = faction_id
	vein["security"] = roll_security_tier(faction_id, site["oreType"])
	return vein


# Security-tier distribution consulting the 3 inputs the PRD calls out:
# faction flavour bias, vein value (ore basePrice), and faction resource
# balance. All three collapse into one signed "opulence" tilt applied to
# SECURITY_BASE_WEIGHTS — positive shifts weight toward warded/guarded,
# negative toward none/basic. Exact table left to the implementer.
static func roll_security_tier(faction_id: String, ore_type: String) -> String:
	var weights: Dictionary = SECURITY_BASE_WEIGHTS.duplicate()
	var opulence := _security_opulence(faction_id, ore_type)

	weights["guarded"] = maxf(0.0, weights["guarded"] + opulence * 4.0)
	weights["warded"] = maxf(0.0, weights["warded"] + opulence * 2.0)
	weights["basic"] = maxf(0.0, weights["basic"] - opulence * 2.0)
	weights["none"] = maxf(0.0, weights["none"] - opulence * 4.0)

	return _weighted_security_roll(weights)


# ore basePrice (R§1.1) ranges ~55-90; centred on the roster's ~72
# midpoint so an average-value ore contributes ~0 tilt either way.
#
# Resource input is the faction's real dynamic balance (state.factions[id]
# .resources, faction-resource-economy T01) rather than the static
# resourceLevel placeholder — a faction that's spent itself poor on
# security upgrades (see apply_security_upgrades() below) now genuinely
# rolls toward cheaper tiers on its next claim, and a faction sitting on a
# fat balance rolls toward pricier ones. RESOURCE_OPULENCE_BASELINE is the
# mean of the 5 factions' startingResources (data/factions.json:
# (200+500+900+500+1200)/5 = 660), so an average-balance faction
# contributes ~0 tilt, mirroring value_tilt's centring above.
# RESOURCE_OPULENCE_DIVISOR is tuned so the starting-balance spread
# (200-1200) produces a tilt magnitude comparable to value_tilt's.
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
	var total: float = 0.0
	for tier in order:
		total += weights[tier]

	var roll: float = Rng.randf() * total
	var cumulative: float = 0.0
	for tier in order:
		cumulative += weights[tier]
		if roll < cumulative:
			return tier
	return order[-1]


# ── faction-resource-economy T02: daily passive/industry income ───────
# Fixed £/day value per industry (data/factions.json's `industries` lists),
# independent of vein count — this is what distinguishes it from T03's
# vein-derived income. Values are the implementer's call (ticket leaves the
# exact formula open); tiered so summing a faction's industries reproduces
# T01's baseline tiering (Collective scrappiest, Guild/Conclave richest)
# without just copying startingResources: "trading"/"sourcing" (universal
# grunt work) sit at the bottom, "raiding" (Firm) mid, "influence"
# (Network/Conclave's institutional leverage) and "crafting" (Guild's
# high-end contracts, per its flavour text) sit at the top.
const INDUSTRY_INCOME: Dictionary = {
	"sourcing": 6,
	"trading": 8,
	"raiding": 10,
	"influence": 16,
	"crafting": 18,
}


# Runs every daily tick for every faction, regardless of vein count (a
# faction holding zero veins still earns this). See time_system.gd's
# daily_tick() for step ordering.
static func apply_passive_income() -> void:
	for faction_id in GameState.state["factions"].keys():
		var industries: Array = GameData.FACTIONS[faction_id].get("industries", [])
		var income := 0
		for industry in industries:
			income += INDUSTRY_INCOME.get(industry, 0)
		GameState.state["factions"][faction_id]["resources"] += income


# ── faction-resource-economy T03: daily vein-derived income ────────────
# Same shape as the player's cultivate-then-sell loop (Economy.execute_sale):
# ore value (basePrice) converts into resources, just automated and without
# the player's mugging/district-price-mod mechanics (player-facing friction
# that doesn't apply to a faction's internal books). Faction veins have no
# charge/harvest cycle of their own (out of scope per the ticket), so this
# is a periodic trickle rather than a discrete harvest: every surviving
# faction vein converts a slice of its value into resources each daily
# tick, scaling with ore basePrice and vein level (higher level / pricier
# ore -> more income). VEIN_INCOME_DIVISOR is tuned so a fresh Lv1 vein of
# a mid-range ore (basePrice ~72, the roster's 55-90 range midpoint --
# same reference point _security_opulence() uses above) nets ~£5/day --
# modest next to a single INDUSTRY_INCOME entry -- while a Lv5 vein of the priciest ore
# (fate, basePrice 90) nets ~£30/day, a clear differentiator visible over
# a few days of play.
const VEIN_INCOME_DIVISOR := 15.0


# Called from time_system.gd's daily_tick, step ⑤f (runs immediately after
# ⑤e passive income). Ordering: running after ⑤c (abandonment) means a
# vein abandoned this same tick is already gone from state.world.sites and
# never earns income the tick it's lost. Reuses ⑤d's claimedOnDay >= day
# skip so a vein claimed this same tick doesn't earn income before it's
# had a full day to produce -- one consistent "brand-new today" exemption
# shared with growth, not a second bespoke rule.
static func apply_vein_income() -> void:
	var day: int = GameState.state["world"]["day"]
	for site in GameState.state["world"]["sites"]:
		var vein: Variant = site["factionVein"]
		if vein == null or vein["claimedOnDay"] >= day:
			continue
		var base_price: int = GameData.ORE_TYPES[vein["oreType"]]["basePrice"]
		var income: int = GameState.round_epsilon(base_price * vein["level"] / VEIN_INCOME_DIVISOR)
		GameState.state["factions"][vein["factionId"]]["resources"] += income


# ── faction-resource-economy T04: daily security-upgrade spend ─────────
# The only spend category in this PRD's near-term scope: a faction with
# money to spare quietly hardens one of its held veins each tick, reusing
# Cultivating.next_security_tier_id() / GameData.VEIN_SECURITY's cost
# table — same ladder and prices the player's own upgrade_vein_security()
# uses, just funded from the faction's ledger instead of player cash.
#
# Priority rule (left open by the PRD): one upgrade per faction per tick,
# targeting its highest-value held vein (basePrice * level -- the same
# value metric apply_vein_income() scales income on) among veins that are
# both below max security and affordable this tick. A faction protects
# its crown jewel first rather than spreading upgrades thin across many
# veins at once. A faction with no eligible vein, or that can't afford
# its cheapest eligible upgrade, is a no-op, not an error.
#
# Called from time_system.gd's daily_tick, step ⑤g (runs immediately
# after ⑤f vein income), so a tick's vein income is already banked and
# spendable the same day it's earned.
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
			var value: float = GameData.ORE_TYPES[vein["oreType"]]["basePrice"] * vein["level"]
			if value > best_value:
				best_value = value
				best_vein = vein
				best_next_id = next_id
				best_cost = cost

		if best_vein == null:
			continue
		faction_state["resources"] -= best_cost
		best_vein["security"] = best_next_id


# ── faction-territory-rivalry T01: faction-to-faction relation matrix ──
# Directional get/adjust over state.factionRelations (GameState._new_
# faction_relations_state()) -- a's relation *toward* b, distinct from the
# player-facing state.factions[id].relation this file's join logic above
# uses. Nothing reads or writes this matrix yet; tickets 03/04 (rivalry odds
# + resolution) are the first consumers.

# self-vs-self is a documented no-op / always-0 read rather than an error --
# callers (ticket 03's odds calc) can pass matching attacker/defender ids
# without a special case of their own.
static func get_relation(faction_a: String, faction_b: String) -> int:
	if faction_a == faction_b:
		return 0
	return GameState.state["factionRelations"][faction_a][faction_b]


static func adjust_relation(faction_a: String, faction_b: String, delta: int) -> void:
	if faction_a == faction_b:
		return
	GameState.state["factionRelations"][faction_a][faction_b] += delta

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


# vein-raiding ticket 02: the player-facing counterpart to
# faction-territory-rivalry T01's adjust_relation(a, b) above -- that one is
# faction-toward-faction (state.factionRelations), this one is player-toward-
# faction (state.factions[id].relation), the same field can_join() reads.
# Previously only hand-mutated directly (systems/debug_start.gd) or via the
# contact-only "relation" event op (Contacts.award_relation) -- this is the
# first generic adjuster for it, used by Raiding's claim/loot relation hits.
static func adjust_player_relation(faction_id: String, delta: int) -> void:
	GameState.state["factions"][faction_id]["relation"] += delta
	EventBus.state_changed.emit()


# ── collective-ore-stock T01: Collective ore stock + restocking ────────
# A limited, independently-scarce stock the Collective's buy lane draws
# against -- schema-present on every faction (state.factions[id].oreStock)
# but only "collective" is ever rolled or read in this milestone, same
# "present everywhere, only one faction moves it" pattern tradeProgress
# already uses. Entirely independent of relation: relation only narrows
# get_faction_buy_spread/get_faction_sell_spread's *price*, never this
# *quantity* ceiling.
const ORE_STOCK_RESTOCK_CHANCE := 0.30
const ORE_STOCK_QTY_MIN := 5
const ORE_STOCK_QTY_MAX := 20


# All 5 canonical ore types reroll together as one event, replacing
# whatever stock remained rather than adding to it. Silent per spec: no
# Notify/Ticker push of any kind, ever -- callers include both the
# unlock-moment pre-roll (events.gd's set_flag op) and the daily chance
# below.
static func restock_ore(faction_id: String) -> void:
	var stock: Dictionary = GameState.state["factions"][faction_id]["oreStock"]
	for ore_type in GameData.CANONICAL_ORE_TYPES:
		stock[ore_type] = Rng.randi_range(ORE_STOCK_QTY_MIN, ORE_STOCK_QTY_MAX)


# Called from time_system.gd's daily_tick, step ⑤j: an unpredictable daily
# chance of a restock firing (not a fixed interval). Collective-only for
# this milestone -- the other 4 factions' oreStock stays schema-present but
# untouched until a later milestone reads it.
static func maybe_restock_ore() -> void:
	if Rng.chance(ORE_STOCK_RESTOCK_CHANCE):
		restock_ore("collective")


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


# Instant vein for a claiming faction (D2-equivalent "claim = instant
# vein", no unseeded intermediate state): oreType/district/hospitability
# inherited from the site; growth is the caller's call — a fresh NPC claim
# passes GameData.VEIN_GROWTH["seedGrowth"] (Sites' claim rolls), while
# day-one roster seeding (below) passes its own fixed starting growth.
# Security is rolled fresh — see roll_security_tier().
static func create_faction_vein(faction_id: String, site: Dictionary, growth: int) -> Dictionary:
	var hospitability := { "tier": site["tier"], "bonuses": site["bonuses"] }
	var vein := Cultivating.make_vein(site["oreType"], growth, site["district"], site["id"], hospitability)
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
	var weight_list: Array[float] = []
	for tier in order:
		weight_list.append(weights[tier])
	return order[weighted_pick_index(weight_list)]


# Shared cumulative-weighted-roll: index i is chosen with probability
# weights[i] / sum(weights). Used by the security-tier roll above, the
# rivalry target-vein pick below, and (vein-raiding ticket 06)
# Raiding._pick_worst_relation_faction()'s Direction-B attacker fallback --
# same algorithm, three different callers each mapping the returned index
# back to their own domain object. Public (no leading underscore) for that
# cross-file reuse.
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
# tick, scaling with ore basePrice and vein value_tier (higher tier / pricier
# ore -> more income). VEIN_INCOME_DIVISOR is tuned so a fresh tier-1 vein of
# a mid-range ore (basePrice ~72, the roster's 55-90 range midpoint --
# same reference point _security_opulence() uses above) nets ~£5/day --
# modest next to a single INDUSTRY_INCOME entry -- while a tier-5 vein of the
# priciest ore (fate, basePrice 90) nets ~£30/day, a clear differentiator
# visible over a few days of play.
const VEIN_INCOME_DIVISOR := 15.0


# Called from time_system.gd's daily_tick, step ⑤e (runs immediately after
# ⑤d passive income). Reuses ⑤c's claimedOnDay >= day skip so a vein
# claimed this same tick doesn't earn income before it's had a full day to
# produce -- one consistent "brand-new today" exemption shared with
# growth, not a second bespoke rule. (Pre-bugfixes-40 this comment also
# noted running after the old ⑤c NPC-abandonment step so an abandoned vein
# wouldn't earn income the tick it was lost -- that step no longer exists;
# a faction vein now only leaves state.world.sites via collapse_vein() at
# step ④, well before this step runs.)
static func apply_vein_income() -> void:
	var day: int = GameState.state["world"]["day"]
	for site in GameState.state["world"]["sites"]:
		var vein: Variant = site["factionVein"]
		if vein == null or vein["claimedOnDay"] >= day:
			continue
		var base_price: int = GameData.ORE_TYPES[vein["oreType"]]["basePrice"]
		var income: int = GameState.round_epsilon(base_price * Cultivating.value_tier(vein) / VEIN_INCOME_DIVISOR)
		GameState.state["factions"][vein["factionId"]]["resources"] += income


# ── faction-resource-economy T04: daily security-upgrade spend ─────────
# The only spend category in this PRD's near-term scope: a faction with
# money to spare quietly hardens one of its held veins each tick, reusing
# Cultivating.next_security_tier_id() / GameData.VEIN_SECURITY's cost
# table — same ladder and prices the player's own upgrade_vein_security()
# uses, just funded from the faction's ledger instead of player cash.
#
# Priority rule (left open by the PRD): one upgrade per faction per tick,
# targeting its highest-value held vein (basePrice * value_tier -- the same
# value metric apply_vein_income() scales income on) among veins that are
# both below max security and affordable this tick. A faction protects
# its crown jewel first rather than spreading upgrades thin across many
# veins at once. A faction with no eligible vein, or that can't afford
# its cheapest eligible upgrade, is a no-op, not an error.
#
# Called from time_system.gd's daily_tick, step ⑤f (runs immediately
# after ⑤e vein income), so a tick's vein income is already banked and
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


# ── faction-territory-rivalry T02: rivalry initiation roll ─────────────
# Pure computation, called by nobody yet (ticket 04 wires it into
# daily_tick()) -- returns this tick's list of {attackerId, defenderId,
# veinSiteId} attempt records. Odds of an attempt *succeeding* (relation
# matrix, resource/security disparity) are ticket 03's job; this ticket
# only decides who throws a punch and at what, not whether it lands.

# A distinct aggression-weighting table from INDUSTRY_INCOME above --
# reuses the same `industries` field per the PRD's "no new per-faction
# aggression stat" constraint, but income-per-industry and
# fight-initiation-per-industry are different axes, so this is its own
# const rather than derived from INDUSTRY_INCOME. "raiding" (the Firm's
# flavour industry) dominates by a wide margin; the other four industries
# get a small non-zero trickle so a faction can still occasionally throw
# a punch even without a raiding-flavoured industry, per the PRD's "mostly
# get targeted rather than targeting others" (mostly, not never).
const INDUSTRY_AGGRESSION: Dictionary = {
	"raiding": 0.35,
	"influence": 0.05,
	"crafting": 0.03,
	"trading": 0.02,
	"sourcing": 0.02,
}

# Every faction has some baseline chance of throwing a punch even on pure
# industry-trickle alone (see above) -- this is the floor under that,
# small enough that INDUSTRY_AGGRESSION's spread still dominates who
# initiates markedly more often.
const BASE_INITIATION_CHANCE := 0.05


# One roll per faction per tick: does this faction attempt a rivalry move
# today, and if so, against whom? A faction with zero rival-held veins is
# never eligible regardless of its aggression weight -- there's nothing to
# throw a punch at.
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


# Every {site, vein} pair currently held by a *different* faction than
# faction_id -- the pool a faction's attempt this tick could possibly
# target.
static func _eligible_rival_veins(faction_id: String) -> Array:
	var candidates := []
	for site in GameState.state["world"]["sites"]:
		var vein: Variant = site.get("factionVein")
		if vein == null or vein["factionId"] == faction_id:
			continue
		candidates.append({ "site": site, "vein": vein })
	return candidates


# Target-vein heuristic (implementer's call per the ticket): weighted by
# vein value (basePrice * value_tier), the same value metric
# apply_security_upgrades() already uses above -- an attacker is more
# likely to go after a rival's crown jewel than its scraps, not a uniform
# pick among however many rival veins happen to exist.
static func _pick_target_vein(candidates: Array) -> Dictionary:
	var weight_list: Array[float] = []
	for candidate in candidates:
		var vein: Dictionary = candidate["vein"]
		weight_list.append(GameData.ORE_TYPES[vein["oreType"]]["basePrice"] * Cultivating.value_tier(vein))
	return candidates[weighted_pick_index(weight_list)]


# ── faction-territory-rivalry T03: rivalry odds calculation ────────────
# Pure computation, called by nobody yet (ticket 04 wires it into the
# same daily-tick step that calls roll_rivalry_attempts()) -- scores one
# T02 attempt record and rolls whether it succeeds. No state mutation:
# ownership transfer and the relation-feedback write both belong to
# ticket 04.

# Base chance before any tilt -- a coin-flip baseline that the three
# inputs below push up or down. Exact formula is the PRD's explicit open
# question; this collapses all three into one additive tilt around 0.5,
# the same "signed tilt on a baseline" shape _security_opulence() already
# uses above, just applied to a probability instead of tier weights.
const RIVALRY_BASE_CHANCE := 0.5

# attacker_resources - defender_resources normalises against the roster's
# startingResources spread (200-1200, faction-resource-economy T01 / the
# same 660-centre RESOURCE_OPULENCE_BASELINE above draws from) -- the
# largest plausible starting gap is ~1000, so dividing by 1000 keeps a
# realistic early-game disparity's tilt within roughly +/-1 before the
# weight below scales it down further.
const RIVALRY_RESOURCE_DIVISOR := 1000.0
const RIVALRY_RESOURCE_WEIGHT := 0.25

# raidResist's normalisation anchor is "guarded" (55, data/vein_security.
# json) -- dividing by that anchor keeps the base tier ladder within [0, 1]
# before the weight scales it down, so "guarded" alone can't single-handedly
# swing the whole probability range. Not a hard ceiling: 72-stackable-
# guards-vein-defense lets Cultivating.vein_raid_resist() run past 55 via
# extraGuards, and the divide-then-clamp shape already scales correctly past
# that point -- more guards keeps pushing the tilt further negative, clamped
# at the chance floor of 0.0 by this function's own clampf below.
const RIVALRY_RAID_RESIST_DIVISOR := 55.0
const RIVALRY_RAID_RESIST_WEIGHT := 0.25

# Relation drift (ticket 04's feedback write) is unbounded over a long
# save, unlike the other two inputs' natural ceilings -- 100 is picked so
# a handful of ticket-04 grudge writes meaningfully move the odds without
# a single bad tick alone maxing out the tilt.
const RIVALRY_RELATION_DIVISOR := 100.0
const RIVALRY_RELATION_WEIGHT := 0.25


# Success chance for one T02 attempt record. Direction of each input
# (documented per the ticket's explicit requirement):
# - attacker_resources - defender_resources: higher attacker / lower
#   defender resources -> higher chance (richer attacker, poorer defender).
# - raidResist: higher -> lower chance (better-secured vein resists more).
# - relation: this reads the *defender's* relation toward the *attacker*
#   (get_relation(defenderId, attackerId), not the reverse) -- ticket 04's
#   resolution worsens exactly this direction when the defender loses, so
#   a defender that already has a bad relation toward this attacker is
#   more exposed to them again, compounding the grudge as the PRD
#   describes rather than reading a direction ticket 04 never writes to.
#   Worse (more negative) relation -> higher chance.
# Clamped to [0, 1] regardless of how extreme the three inputs are. If the
# target vein has already vanished since the attempt was recorded (e.g. a
# same-tick rivalry resolution elsewhere already claimed it -- ticket 04's
# concern, not this function's), find_site() returns null per its own
# documented Variant contract; that attempt is unwinnable, so this reads
# as chance 0 rather than indexing into a null site.
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


# Rolls the chance above and returns the attempt record annotated with its
# resolved "success" outcome. Still pure computation -- ownership transfer
# and the relation-feedback write are ticket 04's job, not this function's.
static func roll_rivalry_odds(attempt: Dictionary) -> Dictionary:
	var outcome: Dictionary = attempt.duplicate()
	outcome["success"] = Rng.chance(rivalry_success_chance(attempt))
	return outcome


# ── faction-territory-rivalry T04: rivalry resolution + daily-tick wiring ──
# Called from time_system.gd's daily_tick, step ⑤g (runs immediately after
# ⑤f security upgrades -- the last step of the faction-economy chain, so a
# rivalry's ownership change this tick sees the day's income/spend already
# settled). Runs T02's roll_rivalry_attempts() to get this tick's batch of
# attempts, scores + rolls each one through T03's roll_rivalry_odds(), and
# applies resolve_rivalry_outcome() below to each result.

# Relation-feedback magnitude on a successful attempt (the PRD leaves the
# exact number open) -- comparable in scale to the deliberate ticket-03 test
# grudge (-80) without being so large a single loss saturates
# RIVALRY_RELATION_DIVISOR's normalisation on its own; it takes a handful of
# repeated losses to the same rival to meaningfully compound the odds,
# matching the PRD's "grudges compound" framing rather than a one-shot
# swing.
const RIVALRY_RELATION_PENALTY := -15


static func apply_rivalry_resolution() -> void:
	for attempt in roll_rivalry_attempts():
		resolve_rivalry_outcome(roll_rivalry_odds(attempt))


# Applies one already-rolled T03 outcome. A failed attempt is a documented
# no-op -- no ownership change, no relation write. A successful attempt:
#   - reassigns the target vein's factionId from defender to attacker;
#     oreType/growth/security carry over unchanged (not reset), matching
#     Chunk 1's existing claim/growth code, which never resets those fields
#     on an ownership change either.
#   - worsens the defender's relation *toward the attacker* (get_relation's
#     directional a-toward-b sense) by RIVALRY_RELATION_PENALTY -- the same
#     direction T03's rivalry_success_chance() reads, so a defender that
#     keeps losing to the same rival keeps getting more exposed to them,
#     compounding as the PRD describes.
#   - queues a map-animations-ticket-02-shaped "seed_claim" event (map-
#     visibility-for-rivalry-ownership-changes T05) referencing the vein's
#     district/id and the attacker as owner -- MapCanvas's existing ring-
#     draw-in playback (built for a brand-new vein appearing) doesn't care
#     whether the vein is new or just changed hands, since it reads the
#     vein's *current* factionId live via MapLayout at playback time; this
#     is the only place a rivalry-driven ownership change becomes visible
#     to the player at all (see the Silent note below).
# Same-tick double-processing guard: roll_rivalry_attempts() snapshots the
# board once per tick, so two attempts in the same batch can name the same
# target vein (e.g. two different attackers happened to roll the same
# rival's crown jewel). Re-checking the site's *current* factionId against
# this outcome's recorded defenderId -- rather than trusting the batch's
# stale copy -- means a vein that already changed hands earlier this same
# tick no longer matches its outcome's defenderId, so this silently skips
# it instead of transferring it a second time, crediting the wrong
# defender's relation hit, or queuing a second map event for a vein whose
# first transfer this tick is still waiting to play back.
# Silent per the PRD: no Notify/Ticker push on either outcome -- the player
# only discovers changes by looking at the map (this ticket's queued event).
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


# ── faction day-1 starting veins (faction-starting-veins T01) ─────────
# New-game-only seeding so the other 5 factions don't feel absent for the
# first stretch of a fresh game while the daily NPC-claim tick (above)
# slowly climbs from zero. Reuses that exact same site+vein mechanism
# (Sites' tier/ore/bonus rolls, create_faction_vein()'s security roll) —
# the only thing day-1 does differently is fabricate a brand-new site from
# scratch per starting vein (there's nothing in state.world.sites yet to
# attach an NPC claim to) and pass create_faction_vein() a fixed roster
# growth instead of the fresh-claim seedGrowth default.
#
# Per-faction growth lists are fixed constants, not re-rolled per game
# (spec.md's explicit "every new game gets the same level distribution"
# decision) — each entry below was rolled once, uniformly at random within
# the roster's stated 1-5 level range, then re-expressed as a starting
# `growth` via vein-growth-state spec §5's `growth = 20n - 10` mapping
# (Lv1->10, Lv2->30, Lv3->50, Lv4->70, Lv5->90), preserving the rosters'
# intended relative strength now that levels are gone. Guild's and
# Conclave's ranged sub-groups (levels 2-3 and 2-4 respectively) got the
# same one-time-roll treatment as Collective/Firm/Network's fully-open
# ranges; only their extra fixed-level veins (Guild's 2 @ Lv4, Conclave's
# 3 @ Lv5) needed no roll at all.
#
# District counts here are exactly what data/districts.json's siteCap bump
# (spec.md's "siteCap is bumped, not spent") accounts for: shoreditch +4,
# whitechapel +4, camden +2, battersea +2, greenwich +7, kingscross +4,
# city +7 — every district below appears in exactly that many starting
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


# Called once by a real "New Game" flow (scenes/screens/title.gd,
# scenes/screens/you.gd), always right after GameState.reset() — never
# folded into reset() itself, since 37 test files call GameState.reset()
# expecting the bare pure-state constructor with an empty world.sites, not
# a game's worth of pre-placed faction veins. debug_start.gd's own
# GameState.reset() call is likewise left alone; it overwrites
# state.world.sites wholesale immediately after with its own hand-built
# debug set, so day-1 seeding there would just be discarded anyway.
static func seed_day_one_veins() -> void:
	for faction_id in DAY_ONE_ROSTER.keys():
		for group in DAY_ONE_ROSTER[faction_id]:
			var district_id: String = group["district"]
			for growth in group["growths"]:
				_seed_day_one_vein(faction_id, district_id, growth)
	EventBus.state_changed.emit()


# Everything about the site (tier, oreType, bonuses) and the vein's
# security tier is rolled exactly as a normal NPC claim would produce
# ("everything else stays procedural" per spec.md) — only the vein's growth
# is the roster's fixed starting value. No MapEvents queueing and no
# Notify/XP: these veins exist from the moment the game starts, so there is
# nothing to animate or award XP for (the daily-tick NPC-claim path's
# queue_seed_claim/Notify calls are for a claim happening *during* play,
# which this isn't).
static func _seed_day_one_vein(faction_id: String, district_id: String, growth: int) -> void:
	var tier := Sites.roll_tier(district_id)
	var site := Sites.roll_new_site(district_id, tier)

	var vein := create_faction_vein(faction_id, site, growth)
	site["factionVein"] = vein

	GameState.state["world"]["sites"].append(site)

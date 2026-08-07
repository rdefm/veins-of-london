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
# level. All three collapse into one signed "opulence" tilt applied to
# SECURITY_BASE_WEIGHTS — positive shifts weight toward warded/guarded,
# negative toward none/basic. Exact table left to the implementer.
#
# resourceLevel (data/factions.json) is an explicit PLACEHOLDER per the
# ticket: the real dynamic faction-resource stat is Chunk 1b
# (faction-resource-economy), not built yet.
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
static func _security_opulence(faction_id: String, ore_type: String) -> float:
	var faction: Dictionary = GameData.FACTIONS[faction_id]
	var flavour_bias: float = faction.get("securityBias", 0.0)
	var resource_level: float = faction.get("resourceLevel", 1.0)
	var ore_value: float = GameData.ORE_TYPES.get(ore_type, {}).get("basePrice", 72.0)
	var value_tilt: float = (ore_value - 72.0) / 15.0
	return flavour_bias + value_tilt + (resource_level - 1.0)


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

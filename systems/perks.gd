class_name Perks
extends RefCounted

# Faction perk queries (R§3.10 "Perks"), data in faction_perks.json. Tier from
# the player's standing with a faction: sworn = joined, partner = Partner
# stance, friendly = relation at or above friendlyAtOrAbove. Tiers are
# cumulative. Turf-scoped perks apply in districts where the faction has
# Control (scale 1) or Foothold (scale footholdFactor). Effect hooks read these
# queries; nothing here applies an effect. Static funcs only.

const TIER_NONE := "none"


static func _cfg() -> Dictionary:
	return GameData.FACTION_PERKS


static func tier_order() -> Array:
	return _cfg()["tierOrder"]


static func tier_label(tier: String) -> String:
	return _cfg()["tierLabels"].get(tier, tier)


# Player's perk tier with a faction: "none" | "friendly" | "partner" | "sworn".
static func player_tier(faction_id: String) -> String:
	var f: Dictionary = GameState.state["factions"][faction_id]
	if f.get("joined", false):
		return "sworn"
	if FactionAI.player_stance(faction_id) == FactionAI.PARTNER:
		return "partner"
	if int(f["relation"]) >= int(_cfg()["friendlyAtOrAbove"]):
		return "friendly"
	return TIER_NONE


# Tier rank: 0 for none, 1.. along tierOrder.
static func tier_rank(tier: String) -> int:
	return tier_order().find(tier) + 1


# Every perk at every tier for a faction: [{ tier, unlocked, perk }], lowest tier first.
static func preview(faction_id: String) -> Array:
	var rank := tier_rank(player_tier(faction_id))
	var rows := []
	for tier in tier_order():
		for perk in _cfg()["factions"][faction_id].get(tier, []):
			rows.append({ "tier": tier, "unlocked": tier_rank(tier) <= rank, "perk": perk })
	return rows


# Perks the player has unlocked with a faction, filtered by scope ("" = both).
static func _unlocked(faction_id: String, scope: String) -> Array:
	var perks := []
	for row in preview(faction_id):
		if row["unlocked"] and (scope == "" or row["perk"]["scope"] == scope):
			perks.append(row)
	return perks


# Active global perks: [{ faction, tier, perk }].
static func active_global() -> Array:
	var result := []
	for faction_id in GameData.FACTIONS.keys():
		for row in _unlocked(faction_id, "global"):
			result.append({ "faction": faction_id, "tier": row["tier"], "perk": row["perk"] })
	return result


# Active turf perks for a district: [{ faction, tier, perk, scale }]. Only factions
# holding Control (1.0) or Foothold (footholdFactor) there contribute.
static func active_turf(district_id: String) -> Array:
	var result := []
	for faction_id in GameData.FACTIONS.keys():
		var scale := turf_scale(district_id, faction_id)
		if scale <= 0.0:
			continue
		for row in _unlocked(faction_id, "turf"):
			result.append({ "faction": faction_id, "tier": row["tier"], "perk": row["perk"], "scale": scale })
	return result


# Turf perks for a player site/vein record (its district).
static func active_turf_for_site(site: Dictionary) -> Array:
	return active_turf(String(site.get("district", "")))


static func turf_scale(district_id: String, faction_id: String) -> float:
	match Turf.tier(district_id, faction_id):
		Turf.TIER_CONTROL:
			return 1.0
		Turf.TIER_FOOTHOLD:
			return float(GameData.TURF["footholdFactor"])
	return 0.0


# True if the player has the perk id active (global: unlocked; turf: with district, scale > 0).
static func has_perk(perk_id: String, district_id: String = "") -> bool:
	for entry in active_global():
		if entry["perk"]["id"] == perk_id:
			return true
	if district_id != "":
		for entry in active_turf(district_id):
			if entry["perk"]["id"] == perk_id:
				return true
	return false

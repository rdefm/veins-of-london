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


# ── effect hooks ──────────────────────────────────────────────────────────

# Summed raidOddsAdj of active turf perks in a district, scaled by Control/Foothold.
static func raid_odds_adj(district_id: String) -> float:
	var total := 0.0
	for entry in active_turf(district_id):
		if entry["perk"]["effect"] == "raidOddsAdj":
			total += float(entry["perk"]["params"]["value"]) * float(entry["scale"])
	return total


# Records that the player tended (cultivated or pruned) a vein today.
static func note_player_tended(vein_id: String) -> void:
	GameState.state["perks"]["tended"][vein_id] = int(GameState.state["world"]["day"])


# ⑤d2b: in each district with a dailyTend perk, up to veinsPerDay of the
# player's veins they did not tend on the day just ended get tended by members
# through FactionSim's tend step (Foothold scale does not shrink the count).
static func daily_tend() -> void:
	var perks_state: Dictionary = GameState.state["perks"]
	var ended_day: int = int(GameState.state["world"]["day"]) - 1
	var skill: int = GameState.state["player"]["cultivatingSkill"]
	var used := {}
	var live := {}
	for vein in GameState.state["player"]["veins"]:
		var vein_id: String = vein["id"]
		var tended_day: int = int(perks_state["tended"].get(vein_id, -1))
		if tended_day >= 0:
			live[vein_id] = tended_day
		if tended_day == ended_day:
			continue
		var district: String = vein["district"]
		if int(used.get(district, 0)) >= _tend_budget(district):
			continue
		FactionSim._tend(vein, skill)
		used[district] = int(used.get(district, 0)) + 1
	perks_state["tended"] = live


# veinsPerDay of the dailyTend perks active in a district (0 when none).
static func _tend_budget(district_id: String) -> int:
	var total := 0
	for entry in active_turf(district_id):
		if entry["perk"]["effect"] == "dailyTend":
			total += int(entry["perk"]["params"]["veinsPerDay"])
	return total


# Sworn Collective whip-round: before a forced home downgrade, once per game,
# the arrears are cleared instead. Returns true if it fired.
static func try_whip_round() -> bool:
	var perks_state: Dictionary = GameState.state["perks"]
	if perks_state["whipRoundUsed"] or not _has_global_effect("homeBailout"):
		return false
	var home: Dictionary = GameState.state["home"]
	var cleared: int = home["arrears"]
	perks_state["whipRoundUsed"] = true
	home["arrears"] = 0
	home["arrearsWeeks"] = 0
	Notify.push("The Collective passes the hat. £%d of arrears gone, and you keep your home. Once." % cleared, Notify.CATEGORY_INFO)
	return true


static func _has_global_effect(effect: String) -> bool:
	for entry in active_global():
		if entry["perk"]["effect"] == effect:
			return true
	return false

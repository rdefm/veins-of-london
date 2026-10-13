class_name Turf
extends RefCounted

# District control (R§3.1 "Turf"). Contenders are the five factions plus
# PLAYER; a contender's count is its veins in the district. The top contender
# controls when its count >= second place + controlMargin; otherwise the
# district is contested (when anything is claimed there). Any other contender
# whose share of the district's claimed veins >= footholdShare has a foothold.
# state.turf[districtId] = { controller, shares, tiers } is rewritten once per
# daily tick by recompute(); readers get a value that is stable within a day.

const PLAYER := "player"
const TIER_CONTROL := "control"
const TIER_FOOTHOLD := "foothold"
const TIER_NONE := "none"


# Vein count per contender in one district, read from a state tree.
static func counts(state: Dictionary, district_id: String) -> Dictionary:
	var result := {}
	for site in state["world"]["sites"]:
		var vein: Variant = site["factionVein"]
		if site["district"] == district_id and vein != null:
			result[vein["factionId"]] = int(result.get(vein["factionId"], 0)) + 1
	for vein in state["player"].get("veins", []):
		if vein["district"] == district_id:
			result[PLAYER] = int(result.get(PLAYER, 0)) + 1
	return result


# Contender -> share of the district's claimed veins (0..1); empty when nothing is claimed.
static func shares_of(counts_by_contender: Dictionary) -> Dictionary:
	var total := 0
	for n in counts_by_contender.values():
		total += int(n)
	var result := {}
	if total == 0:
		return result
	for contender in counts_by_contender:
		result[contender] = float(counts_by_contender[contender]) / total
	return result


# Controller id, or "" when the top two are within controlMargin (or nothing is claimed).
static func controller_of(counts_by_contender: Dictionary) -> String:
	var top := ""
	var top_n := 0
	var second_n := 0
	for contender in counts_by_contender:
		var n: int = int(counts_by_contender[contender])
		if n > top_n:
			second_n = top_n
			top_n = n
			top = contender
		elif n > second_n:
			second_n = n
	if top_n > 0 and top_n >= second_n + int(GameData.TURF["controlMargin"]):
		return top
	return ""


static func district_entry(state: Dictionary, district_id: String) -> Dictionary:
	var by_contender := counts(state, district_id)
	var contender_shares := shares_of(by_contender)
	var winner := controller_of(by_contender)
	var tiers := {}
	for contender in contender_shares:
		if contender == winner:
			tiers[contender] = TIER_CONTROL
		elif float(contender_shares[contender]) >= float(GameData.TURF["footholdShare"]):
			tiers[contender] = TIER_FOOTHOLD
	return { "controller": winner, "shares": contender_shares, "tiers": tiers }


# Full turf table for a state tree (used by recompute() and the save backfill).
static func compute(state: Dictionary) -> Dictionary:
	var result := {}
	for district_id in GameData.DISTRICTS:
		result[district_id] = district_entry(state, district_id)
	return result


# New-game turf: heritage factionPresence controls its district. "seeded"
# marks the entry so the first recompute replaces it without a flip headline.
static func seed_state() -> Dictionary:
	var result := {}
	for district_id in GameData.DISTRICTS:
		var presence: String = GameData.DISTRICTS[district_id].get("factionPresence", "")
		var entry := { "controller": presence, "shares": {}, "tiers": {}, "seeded": true }
		if presence != "":
			entry["tiers"][presence] = TIER_CONTROL
		result[district_id] = entry
	return result


# ⑤d3: rewrites state.turf and reports each flip against the stored value.
static func recompute() -> void:
	var old: Dictionary = GameState.state.get("turf", {})
	var fresh := compute(GameState.state)
	for district_id in fresh:
		var before: Dictionary = old.get(district_id, {})
		if before.get("seeded", false):
			continue
		var from_id: String = before.get("controller", "")
		var to_id: String = fresh[district_id]["controller"]
		if from_id != to_id:
			_report_flip(district_id, from_id, to_id)
	GameState.state["turf"] = fresh
	EventBus.state_changed.emit()


static func _report_flip(district_id: String, from_id: String, to_id: String) -> void:
	var headlines: Dictionary = GameData.TURF["headlines"]
	var district_name: String = GameData.DISTRICTS[district_id]["name"]
	var text: String
	if to_id == "":
		text = headlines["contested"] % district_name
	elif to_id == PLAYER:
		text = headlines["flipPlayer"] % district_name
	else:
		text = headlines["flip"] % [GameData.FACTIONS[to_id]["shortName"], district_name]
	Barometer.push_headline(text, "turfFlip", { "district": district_id, "from": from_id, "to": to_id })
	MapEvents.queue_turf_flip(district_id, from_id, to_id)


# --- Pure queries over the stored (daily) value ---

static func controller(district_id: String) -> String:
	return GameState.state["turf"].get(district_id, {}).get("controller", "")


static func tier(district_id: String, contender: String) -> String:
	return GameState.state["turf"].get(district_id, {}).get("tiers", {}).get(contender, TIER_NONE)


static func shares(district_id: String) -> Dictionary:
	return GameState.state["turf"].get(district_id, {}).get("shares", {})


static func is_contested(district_id: String) -> bool:
	var entry: Dictionary = GameState.state["turf"].get(district_id, {})
	return entry.get("controller", "") == "" and not entry.get("shares", {}).is_empty()


# --- Effective district modifiers (R§3.1a "Turf modifiers") ---

# Relation-band adjustment (key: "dangerAdj" | "priceAdj") for a player-toward-faction relation.
static func _band_adj(relation: int, key: String) -> float:
	for band in GameData.TURF["relationBands"]:
		if relation >= int(band["min"]):
			return float(band[key])
	return 0.0


# Sum over the district's controller (full) and foothold factions (footholdFactor) of the band adjustment.
static func _relation_adj(district_id: String, key: String) -> float:
	var total := 0.0
	var tiers: Dictionary = GameState.state["turf"].get(district_id, {}).get("tiers", {})
	for contender in tiers:
		if contender == PLAYER:
			continue
		var adj := _band_adj(int(GameState.state["factions"][contender]["relation"]), key)
		if tiers[contender] == TIER_FOOTHOLD:
			adj *= float(GameData.TURF["footholdFactor"])
		total += adj
	return total


# Danger modifier: district base + controller-relation shift + player-control relief.
static func danger_mod(district_id: String) -> float:
	var base: float = GameData.DISTRICTS.get(district_id, {}).get("dangerMod", 0.0)
	var mod := base + _relation_adj(district_id, "dangerAdj")
	if controller(district_id) == PLAYER:
		mod += float(GameData.TURF["playerControl"]["dangerAdj"])
	return mod


# Price modifier: district base + controller-relation shift.
static func price_mod(district_id: String) -> float:
	var base: float = GameData.DISTRICTS.get(district_id, {}).get("priceMod", 0.0)
	return base + _relation_adj(district_id, "priceAdj")


# Raid-success shift against a player vein in this district (<= 0 under player control).
static func raid_odds_adj(district_id: String) -> float:
	if controller(district_id) == PLAYER:
		return float(GameData.TURF["playerControl"]["raidOddsAdj"])
	return 0.0


static func player_controlled_count() -> int:
	var n := 0
	for district_id in GameState.state["turf"]:
		if controller(district_id) == PLAYER:
			n += 1
	return n

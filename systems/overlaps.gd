class_name Overlaps
extends RefCounted

# Overlap detector: where the player's business meets a faction's. Four kinds
# (data/constants.json "overlap"): district (both hold veins in one district),
# crafting (player crafts the faction's ore), producing (player mines an ore
# in a recipe the faction consumes), provocation (player ore share nearing the
# level that provokes the faction). Feeds the Partner ladder and, later,
# Defuse. Also the Act 2 spine beats that fire here: the rival's first move
# (a Monday meeting prose beat) and reaching Partner. Static funcs only; reads state.

const KIND_DISTRICT := "district"
const KIND_CRAFTING := "crafting"
const KIND_PRODUCING := "producing"
const KIND_PROVOCATION := "provocation"


static func _cfg() -> Dictionary:
	return GameData.OVERLAP


static func _faction_ores(faction_id: String) -> Array:
	var f: Dictionary = GameData.FACTIONS[faction_id]
	return [f["primaryOre"], f["secondaryOre"]]


# Every overlap as { faction, kind, ore, district } (ore / district "" when the
# kind has none), in faction data order then kind order.
static func detect() -> Array:
	var found: Array = []
	for faction_id in GameData.FACTIONS:
		found.append_array(detect_for(faction_id))
	return found


static func detect_for(faction_id: String, clash_only: bool = false) -> Array:
	var found: Array = _detect_all(faction_id)
	if clash_only:
		found = found.filter(func(entry: Dictionary) -> bool: return _cfg()["clashKinds"].has(entry["kind"]))
	return found


static func _detect_all(faction_id: String) -> Array:
	var found: Array = []
	var min_share := float(_cfg()["minShare"])
	var district := _shared_district(faction_id)
	if district != "":
		found.append(_entry(faction_id, KIND_DISTRICT, "", district))
	for ore_type in _faction_ores(faction_id):
		if Shares.crafting_share(Shares.PLAYER, ore_type) >= min_share:
			found.append(_entry(faction_id, KIND_CRAFTING, ore_type, ""))
	for ore_type in _consumed_ores(faction_id):
		if Shares.ore_share(Shares.PLAYER, ore_type) >= min_share:
			found.append(_entry(faction_id, KIND_PRODUCING, ore_type, ""))
	var near := float(_cfg()["provocationShare"]) - float(_cfg()["provocationMargin"])
	for ore_type in _faction_ores(faction_id):
		if Shares.ore_share(Shares.PLAYER, ore_type) >= near:
			found.append(_entry(faction_id, KIND_PROVOCATION, ore_type, ""))
	return found


static func _entry(faction_id: String, kind: String, ore_type: String, district: String) -> Dictionary:
	return { "faction": faction_id, "kind": kind, "ore": ore_type, "district": district }


# A district where the player has at least minDistrictVeins veins and the
# faction holds a vein, else "".
static func _shared_district(faction_id: String) -> String:
	var mine := {}
	for vein in GameState.state["player"]["veins"]:
		mine[vein["district"]] = int(mine.get(vein["district"], 0)) + 1
	for site in GameState.state["world"]["sites"]:
		var vein: Variant = site["factionVein"]
		if vein != null and vein["factionId"] == faction_id \
				and int(mine.get(site["district"], 0)) >= int(_cfg()["minDistrictVeins"]):
			return str(site["district"])
	return ""


# Ores in the ingredients of the recipes a faction consumes, canonical order.
static func _consumed_ores(faction_id: String) -> Array:
	var ores := {}
	var consumed: Array = GameData.FACTIONS[faction_id]["consumes"].keys()
	if FactionSim.root_feed_want(faction_id) > 0 and not consumed.has(Cultivating.ROOT_FEED):
		consumed.append(Cultivating.ROOT_FEED)
	for recipe_key in consumed:
		for ore_type in GameData.RECIPES.get(recipe_key, {}).get("ingredients", {}):
			ores[ore_type] = true
	var result: Array = []
	for ore_type in GameData.CANONICAL_ORE_TYPES:
		if ores.has(ore_type):
			result.append(ore_type)
	return result


# Factions with at least one overlap, most distinct kinds first, data order
# breaking ties. A faction already Partner is left out unless include_partners.
# clash_only counts just the clashKinds (the Defuse framing).
static func factions(include_partners: bool = false, clash_only: bool = false) -> Array[String]:
	var ranked: Array = []
	var order := 0
	for faction_id in GameData.FACTIONS:
		order += 1
		if not include_partners and FactionAI.player_stance(faction_id) == FactionAI.PARTNER:
			continue
		var kinds := {}
		for entry in detect_for(faction_id, clash_only):
			kinds[entry["kind"]] = true
		if not kinds.is_empty():
			ranked.append({ "id": faction_id, "kinds": kinds.size(), "order": order })
	ranked.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a["kinds"] > b["kinds"] or (a["kinds"] == b["kinds"] and a["order"] < b["order"]))
	var ids: Array[String] = []
	for row in ranked:
		ids.append(row["id"])
	return ids


static func exists(include_partners: bool = false, clash_only: bool = false) -> bool:
	return not factions(include_partners, clash_only).is_empty()


# Resolves a goal's "$overlap" / "$clash" faction placeholder: the faction a
# prior rung of the ladder already used, else the top overlapped faction
# ("$clash": top by clash kinds only). "" when none.
static func resolve_faction(placeholder: String, ladder_id: String) -> String:
	if not placeholder.begins_with("$"):
		return placeholder
	for entry in GameState.state["boardMeetings"]["rungs"].get(ladder_id, {}).values():
		if entry.has("faction"):
			return str(entry["faction"])
	var ranked := factions(false, placeholder == "$clash")
	return "" if ranked.is_empty() else ranked[0]


# Completes the unordered spine beats whose condition now holds: the rival's
# first move (queued for the next meeting once the share target is done),
# Partner stance with anyone, weathering or softening the rival's move, and
# the closing debrief (queued for the next meeting once every other beat is).
static func update_spine() -> void:
	_update_weather_or_soften()
	_queue_debrief()
	if not BoardMeetings.spine_done("partner"):
		for faction_id in GameData.FACTIONS:
			if FactionAI.player_stance(faction_id) == FactionAI.PARTNER:
				BoardMeetings.mark_spine_done("partner")
				break
	if BoardMeetings.spine_done("share_target") and not BoardMeetings.spine_done("rival_move"):
		_queue_rival_move()


# The ore the share_target beat was cleared on, "" if unknown.
static func _share_ore() -> String:
	for entry in GameState.state["boardMeetings"]["rungs"].get("market_share", {}).values():
		if entry.has("ore"):
			return str(entry["ore"])
	return ""


# The faction producing the most of an ore besides the player.
static func rival_for(ore_type: String) -> String:
	var best := ""
	var best_share := -1.0
	for faction_id in Factions.factions_crafting_with_ore(ore_type):
		var share := Shares.ore_share(faction_id, ore_type)
		if share > best_share:
			best = faction_id
			best_share = share
	return best


# Queues the rival's first move for the next Monday meeting (its `_rival`
# prose pack); BoardMeetings.meeting_context() plays it and marks the beat.
static func _queue_rival_move() -> void:
	var board: Dictionary = GameState.state["boardMeetings"]
	if board.get("rivalMove") != null:
		return
	var ore_type := _share_ore()
	var rival := rival_for(ore_type) if ore_type != "" else ""
	if rival == "":
		return
	board["rivalMove"] = { "faction": rival, "ore": ore_type }


# Stamps the day and the rival relation when the rival's move plays, the
# baseline weather / soften are judged against.
static func start_rival_watch() -> void:
	var rival: Variant = GameState.state["boardMeetings"].get("rivalMove")
	if rival == null:
		return
	rival["startDay"] = int(GameState.state["world"]["day"])
	rival["startRelation"] = Objectives.faction_relation(str(rival["faction"]))


# Weather: weatherDays since the move with no vein lost and no guard walked
# off. Soften: the rival's relation up softenRelation since the move.
static func _update_weather_or_soften() -> void:
	if BoardMeetings.spine_done("weather_or_soften") or not BoardMeetings.spine_done("rival_move"):
		return
	var rival: Variant = GameState.state["boardMeetings"].get("rivalMove")
	if rival == null or not rival.has("startDay"):
		return
	var start := int(rival["startDay"])
	var day := int(GameState.state["world"]["day"])
	var weathered := day - start >= int(_cfg()["weatherDays"]) \
		and int(GameState.state["factionEscalation"].get("lastVeinLostDay", -1)) < start \
		and int(GameState.state["guardUpkeep"].get("lastWalkDay", -1)) < start
	var softened := Objectives.faction_relation(str(rival["faction"])) - int(rival["startRelation"]) >= int(_cfg()["softenRelation"])
	if weathered or softened:
		BoardMeetings.mark_spine_done("weather_or_soften")


static func _queue_debrief() -> void:
	var board: Dictionary = GameState.state["boardMeetings"]
	if BoardMeetings.spine_done("debrief") or board.get("debriefPending", false):
		return
	for beat in GameData.BOARD_SPINE.get("beats", []):
		if beat["id"] != "debrief" and not BoardMeetings.spine_done(beat["id"]):
			return
	board["debriefPending"] = true

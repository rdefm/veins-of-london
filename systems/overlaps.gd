class_name Overlaps
extends RefCounted

# Overlap detector: where the player's business meets a faction's. Four kinds
# (data/constants.json "overlap"): district (both hold veins in one district),
# crafting (player crafts the faction's ore), producing (player mines an ore
# in a recipe the faction consumes), provocation (player ore share nearing the
# level that provokes the faction). Feeds the Partner ladder and, later,
# Defuse. Also the Act 2 spine beats that fire here: the rival's first move
# (a live text) and reaching Partner. Static funcs only; reads state.

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


static func detect_for(faction_id: String) -> Array:
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
	for recipe_key in GameData.FACTIONS[faction_id]["consumes"]:
		for ore_type in GameData.RECIPES.get(recipe_key, {}).get("ingredients", {}):
			ores[ore_type] = true
	var result: Array = []
	for ore_type in GameData.CANONICAL_ORE_TYPES:
		if ores.has(ore_type):
			result.append(ore_type)
	return result


# Factions with at least one overlap, most distinct kinds first, data order
# breaking ties. A faction already Partner is left out unless include_partners.
static func factions(include_partners: bool = false) -> Array[String]:
	var ranked: Array = []
	var order := 0
	for faction_id in GameData.FACTIONS:
		order += 1
		if not include_partners and FactionAI.player_stance(faction_id) == FactionAI.PARTNER:
			continue
		var kinds := {}
		for entry in detect_for(faction_id):
			kinds[entry["kind"]] = true
		if not kinds.is_empty():
			ranked.append({ "id": faction_id, "kinds": kinds.size(), "order": order })
	ranked.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a["kinds"] > b["kinds"] or (a["kinds"] == b["kinds"] and a["order"] < b["order"]))
	var ids: Array[String] = []
	for row in ranked:
		ids.append(row["id"])
	return ids


static func exists(include_partners: bool = false) -> bool:
	return not factions(include_partners).is_empty()


# Resolves a goal's "$overlap" faction placeholder: the faction a prior rung of
# the ladder already used, else the top overlapped faction. "" when none.
static func resolve_faction(placeholder: String, ladder_id: String) -> String:
	if not placeholder.begins_with("$"):
		return placeholder
	for entry in GameState.state["boardMeetings"]["rungs"].get(ladder_id, {}).values():
		if entry.has("faction"):
			return str(entry["faction"])
	var ranked := factions()
	return "" if ranked.is_empty() else ranked[0]


# Completes the unordered spine beats whose condition now holds: the rival's
# first move (once the share target is done) and Partner stance with anyone.
static func update_spine() -> void:
	if not BoardMeetings.spine_done("partner"):
		for faction_id in GameData.FACTIONS:
			if FactionAI.player_stance(faction_id) == FactionAI.PARTNER:
				BoardMeetings.mark_spine_done("partner")
				break
	if BoardMeetings.spine_done("share_target") and not BoardMeetings.spine_done("rival_move"):
		_fire_rival_move()


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


# Sends the one-off live text explaining relation levers and marks the beat.
static func _fire_rival_move() -> void:
	var ore_type := _share_ore()
	var rival := rival_for(ore_type) if ore_type != "" else ""
	if rival == "":
		return
	var copy: Dictionary = GameData.BOARD_SPINE["rivalMove"]
	var text := str(copy["text"]).format({
		"faction": GameData.FACTIONS[rival]["name"],
		"ore": GameData.ORE_TYPES[ore_type]["name"],
	})
	Messages.append(str(copy["contact"]), "them", text)
	BoardMeetings.mark_spine_done("rival_move")

class_name FactionAI
extends RefCounted

# Faction politics (R§3.1 "Stances"): the relation clamp, the stored stance
# for every faction pair and for the player with each faction, the daily
# hysteresis stance update, and each faction's bounded activity log. Data
# in constants.json factionStances. Static funcs only.

const PARTNER := "partner"
const NEUTRAL := "neutral"
const BUSINESS_RIVAL := "businessRival"
const HOSTILE := "hostile"


static func _cfg() -> Dictionary:
	return GameData.FACTION_STANCES


static func clamp_relation(value: int) -> int:
	return clampi(value, int(_cfg()["relationMin"]), int(_cfg()["relationMax"]))


# Symmetric key for a faction pair: the two ids in data order, ":"-joined.
static func pair_key(faction_a: String, faction_b: String) -> String:
	var ids: Array = GameData.FACTIONS.keys()
	if ids.find(faction_a) > ids.find(faction_b):
		return "%s:%s" % [faction_b, faction_a]
	return "%s:%s" % [faction_a, faction_b]


static func _pairs() -> Array:
	var pairs := []
	var ids: Array = GameData.FACTIONS.keys()
	for i in ids.size():
		for j in range(i + 1, ids.size()):
			pairs.append([ids[i], ids[j]])
	return pairs


static func starting_pair_stance(faction_a: String, faction_b: String) -> String:
	for entry in _cfg()["startingPairs"]:
		if pair_key(entry["a"], entry["b"]) == pair_key(faction_a, faction_b):
			return entry["stance"]
	return NEUTRAL


static func starting_pair_relation(faction_a: String, faction_b: String) -> int:
	return int(_cfg()["startingRelation"][starting_pair_stance(faction_a, faction_b)])


static func _entry(stance: String) -> Dictionary:
	return { "stance": stance, "pending": "", "pendingDays": 0 }


# state.factionStances: { pairs: { pairKey: entry }, player: { factionId:
# entry } }, entry = { stance, pending, pendingDays }.
static func new_state() -> Dictionary:
	var pairs := {}
	for pair in _pairs():
		pairs[pair_key(pair[0], pair[1])] = _entry(starting_pair_stance(pair[0], pair[1]))
	var player := {}
	for faction_id in GameData.FACTIONS.keys():
		player[faction_id] = _entry(NEUTRAL)
	return { "pairs": pairs, "player": player }


static func pair_stance(faction_a: String, faction_b: String) -> String:
	return GameState.state["factionStances"]["pairs"][pair_key(faction_a, faction_b)]["stance"]


static func player_stance(faction_id: String) -> String:
	return GameState.state["factionStances"]["player"][faction_id]["stance"]


static func stance_name(stance: String) -> String:
	return _cfg()["names"].get(stance, stance)


# Band read: Partner and Hostile by relation alone; Business rival needs the
# overlap too, else Neutral.
static func band_stance(relation: int, overlap: bool) -> String:
	if relation >= int(_cfg()["partnerAtOrAbove"]):
		return PARTNER
	if relation <= int(_cfg()["hostileAtOrBelow"]):
		return HOSTILE
	if overlap and relation <= int(_cfg()["rivalAtOrBelow"]):
		return BUSINESS_RIVAL
	return NEUTRAL


static func _faction_ores(faction_id: String) -> Array:
	var f: Dictionary = GameData.FACTIONS[faction_id]
	return [f["primaryOre"], f["secondaryOre"]]


# A shared primary/secondary ore, or a crafted item in common.
static func pairs_overlap(faction_a: String, faction_b: String) -> bool:
	for ore_type in _faction_ores(faction_a):
		if _faction_ores(faction_b).has(ore_type):
			return true
	for recipe_key in GameData.FACTIONS[faction_a]["crafts"]:
		if GameData.FACTIONS[faction_b]["crafts"].has(recipe_key):
			return true
	return false


# The player holds at least playerOverlapShare of the ore or crafting tally
# in one of the faction's ores.
static func player_overlaps(faction_id: String) -> bool:
	var threshold: float = float(_cfg()["playerOverlapShare"])
	for ore_type in _faction_ores(faction_id):
		if Shares.ore_share(Shares.PLAYER, ore_type) >= threshold or Shares.crafting_share(Shares.PLAYER, ore_type) >= threshold:
			return true
	return false


# The Collective's player stance holds at Neutral until its questline ends.
static func _player_band(faction_id: String, relation: int, overlap: bool, flags: Dictionary) -> String:
	if faction_id == "collective" and not flags.get("colA2Complete", false):
		return NEUTRAL
	return band_stance(relation, overlap)


# Advances one stored entry toward target; true when the stance flips.
static func _step(entry: Dictionary, target: String) -> bool:
	if target == entry["stance"]:
		entry["pending"] = ""
		entry["pendingDays"] = 0
		return false
	if target == entry["pending"]:
		entry["pendingDays"] = int(entry["pendingDays"]) + 1
	else:
		entry["pending"] = target
		entry["pendingDays"] = 1
	if int(entry["pendingDays"]) < int(_cfg()["hysteresisDays"]):
		return false
	entry["stance"] = target
	entry["pending"] = ""
	entry["pendingDays"] = 0
	return true


# Rollover step: every pair and player stance moves one day toward its band;
# a stance flips once its new band has held hysteresisDays updates.
static func update_stances() -> void:
	var stances: Dictionary = GameState.state["factionStances"]
	for pair in _pairs():
		var entry: Dictionary = stances["pairs"][pair_key(pair[0], pair[1])]
		var target := band_stance(Factions.get_relation(pair[0], pair[1]), pairs_overlap(pair[0], pair[1]))
		if _step(entry, target):
			_log_pair_flip(pair[0], pair[1], entry["stance"])
	for faction_id in GameData.FACTIONS.keys():
		var entry: Dictionary = stances["player"][faction_id]
		var relation: int = GameState.state["factions"][faction_id]["relation"]
		var target := _player_band(faction_id, relation, player_overlaps(faction_id), GameState.state["flags"])
		if _step(entry, target):
			_announce_player_flip(faction_id, entry["stance"])
	EventBus.state_changed.emit()


static func _log_pair_flip(faction_a: String, faction_b: String, stance: String) -> void:
	log_activity(faction_a, _cfg()["logPair"] % [stance_name(stance), GameData.FACTIONS[faction_b]["shortName"]])
	log_activity(faction_b, _cfg()["logPair"] % [stance_name(stance), GameData.FACTIONS[faction_a]["shortName"]])


static func _announce_player_flip(faction_id: String, stance: String) -> void:
	var line: String = _cfg()["lines"].get(faction_id, {}).get(stance, "")
	if line != "":
		KeyMembers.send(faction_id, line)
	log_activity(faction_id, _cfg()["logPlayer"] % stance_name(stance))


# Appends { day, text } to the faction's activity log, dropping the oldest
# past activityLogCap.
static func log_activity(faction_id: String, text: String) -> void:
	var entries: Array = GameState.state["factions"][faction_id]["activityLog"]
	entries.append({ "day": GameState.state["world"]["day"], "text": text })
	var cap: int = int(_cfg()["activityLogCap"])
	while entries.size() > cap:
		entries.pop_front()


static func activity_log(faction_id: String) -> Array:
	return GameState.state["factions"][faction_id].get("activityLog", [])


# Load fix-up on a save dict: relations clamped, the pair matrix made
# symmetric (the two directions averaged), and missing activity logs added.
# A save without factionStances (had_stances false) gets the starting pair
# stances, pair relations moved into their stance's band where outside it,
# and player stances read straight from relation (no overlap, no hysteresis).
static func migrate_save(save: Dictionary, had_stances: bool) -> void:
	var factions: Dictionary = save.get("factions", {})
	for faction_id in factions:
		var faction: Dictionary = factions[faction_id]
		faction["relation"] = clamp_relation(int(faction.get("relation", 0)))
		if not faction.has("activityLog"):
			faction["activityLog"] = []
	var relations: Dictionary = save.get("factionRelations", {})
	for pair in _pairs():
		var a: String = pair[0]
		var b: String = pair[1]
		if not relations.has(a) or not relations.has(b):
			continue
		var value := clamp_relation(roundi((int(relations[a].get(b, 0)) + int(relations[b].get(a, 0))) / 2.0))
		if not had_stances:
			var stance := starting_pair_stance(a, b)
			if band_stance(value, pairs_overlap(a, b)) != stance:
				value = starting_pair_relation(a, b)
		relations[a][b] = value
		relations[b][a] = value
	if had_stances:
		return
	var player: Dictionary = save["factionStances"]["player"]
	for faction_id in player:
		var relation: int = int(factions.get(faction_id, {}).get("relation", 0))
		player[faction_id] = _entry(_player_band(faction_id, relation, false, save.get("flags", {})))

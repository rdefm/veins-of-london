class_name FactionAI
extends RefCounted

# Faction politics (R§3.1 "Stances"): the relation clamp, the stored stance
# for every faction pair and for the player with each faction, the daily
# hysteresis stance update, each faction's bounded activity log, and the
# daily threat/dependence pressure drift (R§3.1 "Pressure"). Data in
# constants.json factionStances and factionPressure. Static funcs only.

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


# ── Pressure ────────────────────────────────────────────────────────────
# R§3.1 "Pressure": each faction weighs every other actor's threat against
# its dependence on them, and relation drifts by the capped difference.
# Data in constants.json factionPressure; personality per faction in
# factions.json aggressionPersonality.

const SNAPSHOT_SCALE := 1000.0


static func _pcfg() -> Dictionary:
	return GameData.FACTION_PRESSURE


static func _weight(key: String) -> float:
	return float(_pcfg()["weights"][key])


# state.factionPressure: { snapshots: { observerId: { targetId: { threat,
# dependence, delta } } }, collectiveFirmJoined }. targetId "player" or a
# faction id; delta is the unrounded directional drift.
static func new_pressure_state() -> Dictionary:
	return { "snapshots": {}, "collectiveFirmJoined": false }


static func personality(faction_id: String) -> float:
	return float(GameData.FACTIONS[faction_id].get("aggressionPersonality", 1.0))


static func _collective_complete() -> bool:
	return GameState.state["flags"].get("colA2Complete", false)


# The Collective–Firm pair while the Collective questline is incomplete.
static func is_held_pair(faction_a: String, faction_b: String) -> bool:
	return pair_key(faction_a, faction_b) == pair_key("collective", "firm") and not _collective_complete()


# The Collective's player relation, held with its player stance.
static func _is_held_player(faction_id: String) -> bool:
	return faction_id == "collective" and not _collective_complete()


static func _is_held(observer: String, target: String) -> bool:
	if target == Shares.PLAYER:
		return _is_held_player(observer)
	return is_held_pair(observer, target)


# Threat(observer → target), never below 0. target is "player" or a faction.
static func threat(observer: String, target: String) -> float:
	var f: Dictionary = GameData.FACTIONS[observer]
	var value := _weight("primaryOre") * Shares.ore_share(target, f["primaryOre"])
	value += _weight("secondaryOre") * Shares.ore_share(target, f["secondaryOre"])
	value += _weight("crafting") * _crafting_share_in_items(observer, target)
	value += _weight("homeVeins") * home_vein_share(observer, target)
	value += _weight("size") * size_share(target)
	value += _jealousy(observer, target)
	value -= _weight("partnerShield") * _shared_partners(observer, target)
	return maxf(value, 0.0)


# Dependence(observer → target): only the player supplies a faction or
# holds contracts with it, so a faction target scores 0.
static func dependence(observer: String, target: String) -> float:
	if target != Shares.PLAYER:
		return 0.0
	var contracts := 0
	for contract in Contracts.active_contracts():
		if String(contract.get("counterparty", "")) == observer:
			contracts += 1
	return _weight("supplierShare") * Shares.intake_share(observer) + _weight("perContract") * contracts


# clamp(personality × (dependence − threat), ±dailyCap); 0 while held.
static func drift(observer: String, target: String) -> float:
	if _is_held(observer, target):
		return 0.0
	var cap := float(_pcfg()["dailyCap"])
	return clampf(personality(observer) * (dependence(observer, target) - threat(observer, target)), -cap, cap)


# The target's highest crafting share among the ore types in the
# observer's crafted items' recipes.
static func _crafting_share_in_items(observer: String, target: String) -> float:
	var best := 0.0
	for recipe_key in GameData.FACTIONS[observer]["crafts"]:
		for ore_type in GameData.RECIPES[recipe_key]["ingredients"]:
			best = maxf(best, Shares.crafting_share(target, ore_type))
	return best


# Target's fraction of every vein (player and faction) in the observer's
# home districts; 0 when there are none.
static func home_vein_share(observer: String, target: String) -> float:
	var homes := FactionSim.home_districts(observer)
	var total := 0
	var owned := 0
	for vein in GameState.state["player"]["veins"]:
		if homes.has(vein["district"]):
			total += 1
			if target == Shares.PLAYER:
				owned += 1
	for site in GameState.state["world"]["sites"]:
		var vein: Variant = site["factionVein"]
		if vein != null and homes.has(site["district"]):
			total += 1
			if vein["factionId"] == target:
				owned += 1
	if total == 0:
		return 0.0
	return float(owned) / float(total)


# Target's fraction of all ore harvested in London over the share window.
static func size_share(target: String) -> float:
	var totals := Shares.window_totals("ore")
	var total := 0
	var owned := 0
	for producer in totals:
		for amount in totals[producer].values():
			total += int(amount)
			if producer == target:
				owned += int(amount)
	if total == 0:
		return 0.0
	return float(owned) / float(total)


# The player's supplier share to each of the observer's Hostile enemies
# (strong) and Business rivals (weak). Factions supply nobody directly.
static func _jealousy(observer: String, target: String) -> float:
	if target != Shares.PLAYER:
		return 0.0
	var value := 0.0
	for other in GameData.FACTIONS.keys():
		if other == observer:
			continue
		match pair_stance(observer, other):
			HOSTILE:
				value += _weight("jealousyHostile") * Shares.intake_share(other)
			BUSINESS_RIVAL:
				value += _weight("jealousyRival") * Shares.intake_share(other)
	return value


# Factions that are Partner with both the observer and the target.
static func _shared_partners(observer: String, target: String) -> int:
	var count := 0
	for other in GameData.FACTIONS.keys():
		if other == observer or other == target or pair_stance(observer, other) != PARTNER:
			continue
		var target_stance := player_stance(other) if target == Shares.PLAYER else pair_stance(target, other)
		if target_stance == PARTNER:
			count += 1
	return count


# Rollover step: snapshots every observer → target, then drifts each
# player relation by its rounded delta and each pair's shared relation by
# the rounded mean of its two directions. Held pairs don't move.
static func apply_pressure() -> void:
	var pressure: Dictionary = GameState.state["factionPressure"]
	_join_collective_firm_if_due(pressure)
	var ids: Array = GameData.FACTIONS.keys()
	var snapshots := {}
	for observer in ids:
		var row := {}
		for target in [Shares.PLAYER] + ids:
			if target == observer:
				continue
			row[target] = {
				"threat": _snap(threat(observer, target)),
				"dependence": _snap(dependence(observer, target)),
				"delta": _snap(drift(observer, target)),
			}
		snapshots[observer] = row
	pressure["snapshots"] = snapshots
	for faction_id in ids:
		if not _is_held_player(faction_id):
			Factions.adjust_player_relation(faction_id, roundi(snapshots[faction_id][Shares.PLAYER]["delta"]))
	for pair in _pairs():
		if is_held_pair(pair[0], pair[1]):
			continue
		var mean: float = (float(snapshots[pair[0]][pair[1]]["delta"]) + float(snapshots[pair[1]][pair[0]]["delta"])) / 2.0
		Factions.adjust_relation(pair[0], pair[1], roundi(mean))
	EventBus.state_changed.emit()


# Three decimals, as the nearest double, so a save's JSON round-trip reads
# back the same float.
static func _snap(value: float) -> float:
	return roundf(value * SNAPSHOT_SCALE) / SNAPSHOT_SCALE


# Once the Collective questline completes, the pair joins the AI at Hostile:
# relation no higher than the Hostile starting relation, stance Hostile.
static func _join_collective_firm_if_due(pressure: Dictionary) -> void:
	if pressure.get("collectiveFirmJoined", false) or not _collective_complete():
		return
	pressure["collectiveFirmJoined"] = true
	var hostile_relation := int(_cfg()["startingRelation"][HOSTILE])
	var relation := Factions.get_relation("collective", "firm")
	if relation > hostile_relation:
		Factions.adjust_relation("collective", "firm", hostile_relation - relation)
	var entry: Dictionary = GameState.state["factionStances"]["pairs"][pair_key("collective", "firm")]
	entry["stance"] = HOSTILE
	entry["pending"] = ""
	entry["pendingDays"] = 0


# The faction's last drift toward the player; 0 before the first snapshot.
static func player_delta(faction_id: String) -> float:
	var row: Dictionary = GameState.state["factionPressure"]["snapshots"].get(faction_id, {})
	return float(row.get(Shares.PLAYER, {}).get("delta", 0.0))


# Calm / Watching / Annoyed / Moving against you, read from the faction's
# player relation and its last rounded drift.
static func pressure_label(faction_id: String) -> String:
	var labels: Dictionary = _pcfg()["labels"]
	var relation: int = GameState.state["factions"][faction_id]["relation"]
	if relation < int(_pcfg()["movingAgainstBelow"]):
		return labels["movingAgainst"]
	if roundi(player_delta(faction_id)) >= 0:
		return labels["calm"]
	if relation < int(_pcfg()["annoyedBelow"]):
		return labels["annoyed"]
	return labels["watching"]

class_name FactionAI
extends RefCounted

# Faction politics (R§3.1 "Stances"): the relation clamp, the stored stance
# for every faction pair and for the player with each faction, the daily
# hysteresis stance update, each faction's bounded activity log, the
# daily threat/dependence pressure drift (R§3.1 "Pressure") and the
# escalation menus (R§3.1 "Escalation"). Data in constants.json
# factionStances, factionPressure and factionEscalation. Static funcs only.

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


# Appends { day, text } plus any extra fields (a move against the player
# carries { target: "player", move }) to the faction's activity log,
# dropping the oldest past activityLogCap.
static func log_activity(faction_id: String, text: String, extra: Dictionary = {}) -> void:
	var entries: Array = GameState.state["factions"][faction_id]["activityLog"]
	var entry := { "day": GameState.state["world"]["day"], "text": text }
	entry.merge(extra)
	entries.append(entry)
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


# ── Escalation ──────────────────────────────────────────────────────────
# R§3.1 "Escalation": each faction acts on its pressure through its
# archetype's menu, gated by relation band. Data in constants.json
# factionEscalation.

const BAND_NONE := ""
const BAND_WARNING := "warning"
const BAND_MARKET := "market"
const BAND_RAID := "raid"
const BAND_ORDER: Array[String] = [BAND_NONE, BAND_WARNING, BAND_MARKET, BAND_RAID]
const MOVE_VEIN_RAID := "veinRaid"
const MOVE_FLOOD := "flood"
const MOVE_WITHHOLD := "withhold"
const MOVE_OUTBID := "outbid"
const MOVE_POACH := "poach"
const MOVE_WITHHOLD_ITEMS := "withholdItems"
const MOVE_LOWBALL := "lowballBuyout"
const MOVE_UNDERCUT := "undercut"
const MOVE_DENY := "denyGoods"
const LOWBALL_KIND := "faction_lowball_buyout"


static func _ecfg() -> Dictionary:
	return GameData.FACTION_ESCALATION


# state.factionEscalation: { targets: { observerId: { targetId: {
# warnedBand, lastMoveDay } } }, queuedRaids: [ { attackerId, targetId,
# veinId, siteId } ], explained: [moveId], withholds: [ { factionId,
# targetId, kind, good, untilDay } ], lastVeinLostDay }. lastMoveDay and
# lastVeinLostDay -1 = never.
static func new_escalation_state() -> Dictionary:
	return { "targets": {}, "queuedRaids": [], "explained": [], "withholds": [], "lastVeinLostDay": -1 }


# Stamps today as the day the player last lost a vein (lowball trigger).
static func note_player_vein_lost() -> void:
	GameState.state["factionEscalation"]["lastVeinLostDay"] = int(GameState.state["world"]["day"])


static func _withholds() -> Array:
	var escalation: Dictionary = GameState.state["factionEscalation"]
	if not escalation.has("withholds"):
		escalation["withholds"] = []
	return escalation["withholds"]


# True while faction_id is withholding the good: through untilDay inclusive.
static func is_withholding(faction_id: String, kind: String, good_type: String) -> bool:
	var day: int = GameState.state["world"]["day"]
	for entry in GameState.state["factionEscalation"].get("withholds", []):
		if entry["factionId"] == faction_id and entry["kind"] == kind and entry["good"] == good_type and day <= int(entry["untilDay"]):
			return true
	return false


static func _drop_lapsed_withholds() -> void:
	var day: int = GameState.state["world"]["day"]
	GameState.state["factionEscalation"]["withholds"] = _withholds().filter(func(e: Dictionary) -> bool: return day <= int(e["untilDay"]))


static func _relation_to(observer: String, target: String) -> int:
	if target == Shares.PLAYER:
		return int(GameState.state["factions"][observer]["relation"])
	return Factions.get_relation(observer, target)


static func _stance_to(observer: String, target: String) -> String:
	return player_stance(observer) if target == Shares.PLAYER else pair_stance(observer, target)


# The deepest band open to observer against target: raid when Hostile or
# below the observer's raidThreshold, else market, else warning, else none.
static func band(observer: String, target: String) -> String:
	var relation := _relation_to(observer, target)
	if _stance_to(observer, target) == HOSTILE or relation < int(GameData.FACTIONS[observer]["raidThreshold"]):
		return BAND_RAID
	if relation < int(_ecfg()["marketBelow"]):
		return BAND_MARKET
	if relation < int(_ecfg()["warningBelow"]):
		return BAND_WARNING
	return BAND_NONE


static func _depth(band_id: String) -> int:
	return BAND_ORDER.find(band_id)


# The observer's last drift toward the target (player or faction).
static func _delta_to(observer: String, target: String) -> float:
	var row: Dictionary = GameState.state["factionPressure"]["snapshots"].get(observer, {})
	return float(row.get(target, {}).get("delta", 0.0))


# Truce hook: no truces exist yet.
static func in_truce(_party_a: String, _party_b: String) -> bool:
	return false


static func moves_blocked(observer: String, target: String) -> bool:
	if in_truce(observer, target):
		return true
	return target != Shares.PLAYER and is_held_pair(observer, target)


static func _target_entry(observer: String, target: String) -> Dictionary:
	var targets: Dictionary = GameState.state["factionEscalation"]["targets"]
	if not targets.has(observer):
		targets[observer] = {}
	var row: Dictionary = targets[observer]
	if not row.has(target):
		row[target] = { "warnedBand": BAND_NONE, "lastMoveDay": -1 }
	return row[target]


static func _cooling(entry: Dictionary, day: int) -> bool:
	var last := int(entry["lastMoveDay"])
	return last >= 0 and day - last < int(_ecfg()["cooldownDays"])


# Rollover step: every faction weighs every target (the player, then each
# other faction). Below the raid band it acts only while its drift toward
# the target is negative. Off cooldown, a band deeper than the one last
# warned about gets a warning; otherwise the best affordable move is made.
static func apply_escalation() -> void:
	_drop_lapsed_withholds()
	_drop_lapsed_lowballs()
	var ids: Array = GameData.FACTIONS.keys()
	for observer in ids:
		for target in [Shares.PLAYER] + ids:
			if target != observer and not moves_blocked(observer, target):
				_escalate(observer, target)
	EventBus.state_changed.emit()


static func _escalate(observer: String, target: String) -> void:
	var current := band(observer, target)
	var entry := _target_entry(observer, target)
	if _depth(current) < _depth(entry["warnedBand"]):
		entry["warnedBand"] = current
	if current == BAND_NONE:
		return
	if current != BAND_RAID and _delta_to(observer, target) >= 0.0:
		return
	var day: int = GameState.state["world"]["day"]
	if _cooling(entry, day):
		return
	if entry["warnedBand"] != current:
		entry["warnedBand"] = current
		entry["lastMoveDay"] = day
		_warn(observer, target, current)
		return
	var move := _best_move(observer, target, current)
	if move.is_empty():
		return
	entry["lastMoveDay"] = day
	GameState.state["factions"][observer]["resources"] -= int(move["cost"])
	_make_move(observer, target, move)


static func _warn(observer: String, target: String, band_id: String) -> void:
	var log_cfg: Dictionary = _ecfg()["log"]
	if target == Shares.PLAYER:
		var archetype: String = GameData.FACTIONS[observer]["archetype"]
		KeyMembers.send(observer, _ecfg()["warnings"][archetype][band_id])
		log_activity(observer, log_cfg["warningPlayer"])
	else:
		log_activity(observer, log_cfg["warningPair"] % GameData.FACTIONS[target]["shortName"])


# Move ids open in band_id: the archetype's market moves and every
# faction's sharedMarket moves from the market band, plus its raid moves in
# the raid band.
static func _open_moves(observer: String, band_id: String) -> Array:
	var menu: Dictionary = _ecfg()["menus"][GameData.FACTIONS[observer]["archetype"]]
	var moves := []
	if _depth(band_id) >= _depth(BAND_MARKET):
		moves.append_array(menu["market"])
		for move_id in _ecfg().get("sharedMarket", []):
			if not moves.has(move_id):
				moves.append(move_id)
	if band_id == BAND_RAID:
		moves.append_array(menu["raid"])
	return moves


# The affordable open move with the highest expected damage, or {}.
static func _best_move(observer: String, target: String, band_id: String) -> Dictionary:
	var resources := int(GameState.state["factions"][observer]["resources"])
	var best := {}
	for move_id in _open_moves(observer, band_id):
		var candidate := _move_candidate(observer, target, move_id)
		if candidate.is_empty() or int(candidate["cost"]) > resources:
			continue
		if best.is_empty() or float(candidate["damage"]) > float(best["damage"]):
			best = candidate
	return best


static func _move_cost(move_id: String) -> int:
	return int(_ecfg()["moveCosts"].get(move_id, 0))


# { move, damage, cost, ... } for one move against target, or {} when the
# move isn't available (not built yet, or nothing to hit).
static func _move_candidate(observer: String, target: String, move_id: String) -> Dictionary:
	match move_id:
		MOVE_VEIN_RAID:
			return _vein_raid_candidate(observer, target)
		MOVE_FLOOD:
			return _flood_candidate(observer, target)
		MOVE_WITHHOLD:
			return _withhold_candidate(observer, target)
		MOVE_OUTBID:
			return _outbid_candidate(observer, target)
		MOVE_POACH:
			return _poach_candidate(observer, target)
		MOVE_WITHHOLD_ITEMS:
			return _withhold_items_candidate(observer, target)
		MOVE_LOWBALL:
			return _lowball_candidate(observer, target)
		MOVE_UNDERCUT:
			return _undercut_candidate(observer, target)
		MOVE_DENY:
			return _deny_candidate(observer, target)
	return {}


# Flood: up to flood.qty of the ore the observer holds that the target has
# the largest ore share in. Damage = that share × the lot's value at the
# quote. No cash cost: the cost is the flood.priceMult discount on the sale.
# Needs the Market sim running, so the flood moves the price.
static func _flood_candidate(observer: String, target: String) -> Dictionary:
	var best := {}
	if not Market.is_running():
		return best
	for ore_type in GameData.CANONICAL_ORE_TYPES:
		var qty: int = mini(int(_ecfg()["flood"]["qty"]), FactionSim.ore_held(observer, ore_type))
		if qty <= 0:
			continue
		var damage := Shares.ore_share(target, ore_type) * Market.line_total("ore", Market.quote("ore", ore_type), qty)
		if damage > 0.0 and (best.is_empty() or damage > float(best["damage"])):
			best = { "move": MOVE_FLOOD, "damage": damage, "cost": 0, "good": ore_type, "qty": qty }
	return best


# Withhold: stop selling the ore the target has the largest crafting share
# in, among ores the observer has for sale and isn't already withholding.
# Damage = that share × the stock's value at the quote.
static func _withhold_candidate(observer: String, target: String) -> Dictionary:
	var best := {}
	for ore_type in GameData.CANONICAL_ORE_TYPES:
		var qty: int = FactionSim.for_sale(observer, "ore", ore_type)
		if qty <= 0 or is_withholding(observer, "ore", ore_type):
			continue
		var damage := Shares.crafting_share(target, ore_type) * Market.line_total("ore", Market.quote("ore", ore_type), qty)
		if damage > 0.0 and (best.is_empty() or damage > float(best["damage"])):
			best = { "move": MOVE_WITHHOLD, "damage": damage, "cost": _move_cost(MOVE_WITHHOLD), "good": ore_type }
	return best


# Undercut (no cash cost; the cost is the undercut.priceMult discount): sell
# up to undercut.qty[kind] of the good the target sold most of over the past
# week (Market.sold_this_week, by qty; ties by kind:type key), skipping goods
# the observer has none of for sale. Damage = the lot's value at the quote,
# capped at the target's week of sales. Needs the Market sim running.
static func _undercut_candidate(observer: String, target: String) -> Dictionary:
	if not Market.is_running():
		return {}
	var sold := Market.sold_this_week(target)
	var keys: Array = sold.keys()
	keys.sort_custom(func(a: String, b: String) -> bool: return int(sold[a]) > int(sold[b]) or (int(sold[a]) == int(sold[b]) and a < b))
	for key in keys:
		var parts: PackedStringArray = key.split(":")
		var kind: String = parts[0]
		var good_type: String = parts[1]
		var qty: int = mini(int(_ecfg()["undercut"]["qty"][kind]), FactionSim.for_sale(observer, kind, good_type))
		if qty <= 0:
			continue
		var damage := float(Market.line_total(kind, Market.quote(kind, good_type), mini(qty, int(sold[key]))))
		return { "move": MOVE_UNDERCUT, "damage": damage, "cost": 0, "kind": kind, "good": good_type, "qty": qty }
	return {}


# Deny (no cash cost; the cost is the buy): buy up to deny.qty[kind] of a
# good the target needs -- an ore it crafts with (damage = its crafting
# share × the lot's value) or an item it needs (_needs_item; damage = the
# lot's value) -- that the observer isn't already withholding. Capped by
# resources. Needs the Market sim running.
static func _deny_candidate(observer: String, target: String) -> Dictionary:
	var best := {}
	if not Market.is_running():
		return best
	var resources := int(GameState.state["factions"][observer]["resources"])
	for kind in Market.KINDS:
		for good_type in GameData.MARKET["goods"][kind]:
			if is_withholding(observer, kind, good_type):
				continue
			var weight := Shares.crafting_share(target, good_type) if kind == "ore" else (1.0 if _needs_item(target, good_type) else 0.0)
			var price := Market.quote(kind, good_type)
			if weight <= 0.0 or price <= 0:
				continue
			var qty: int = mini(int(_ecfg()["deny"]["qty"][kind]), Market.affordable_qty(kind, price, resources))
			if qty <= 0:
				continue
			var damage := weight * Market.line_total(kind, price, qty)
			if damage > 0.0 and (best.is_empty() or damage > float(best["damage"])):
				best = { "move": MOVE_DENY, "damage": damage, "cost": 0, "kind": kind, "good": good_type, "qty": qty }
	return best


# Outbid (player only): claim the unclaimed site the player has found with
# the highest ore quote × tier rank (sites.json tierOrder; barren is 0).
static func _outbid_candidate(_observer: String, target: String) -> Dictionary:
	var best := {}
	if target != Shares.PLAYER:
		return best
	for site in GameState.state["world"]["sites"]:
		if site["claimed"] or site["factionVein"] != null:
			continue
		var damage := float(Market.quote("ore", site["oreType"]) * GameData.SITE_TIER_ORDER.find(site["tier"]))
		if damage > 0.0 and (best.is_empty() or damage > float(best["damage"])):
			best = { "move": MOVE_OUTBID, "damage": damage, "cost": _move_cost(MOVE_OUTBID), "siteId": site["id"] }
	return best


# Poach (player only; faction contracts don't exist): undercut the pending
# renewal with the highest payment whose buyer isn't the observer and that
# isn't already poached. Damage = that payment.
static func _poach_candidate(observer: String, target: String) -> Dictionary:
	var best := {}
	if target != Shares.PLAYER:
		return best
	for offer in Offers.pending_offers():
		if offer.get("source", "") != "renewal" or offer.has("poach") or offer.get("counterparty", "") == observer or Offers.is_expired(offer):
			continue
		var damage := float(offer["quote"]["payment"])
		if damage > 0.0 and (best.is_empty() or damage > float(best["damage"])):
			best = { "move": MOVE_POACH, "damage": damage, "cost": _move_cost(MOVE_POACH), "offerId": offer["id"] }
	return best


# Withhold items: stop selling the item the target needs most, among items
# the observer has for sale and isn't already withholding. Damage = the
# stock's value at the quote, for an item the target needs.
static func _withhold_items_candidate(observer: String, target: String) -> Dictionary:
	var best := {}
	for recipe_key in GameData.RECIPES:
		var qty: int = FactionSim.for_sale(observer, "consumable", recipe_key)
		if qty <= 0 or not _needs_item(target, recipe_key):
			continue
		var damage := float(Market.line_total("consumable", Market.quote("consumable", recipe_key), qty))
		if damage > 0.0 and (best.is_empty() or damage > float(best["damage"])):
			best = { "move": MOVE_WITHHOLD_ITEMS, "damage": damage, "cost": _move_cost(MOVE_WITHHOLD_ITEMS), "good": recipe_key }
	return best


# The player needs an item still owed on an active contract; a faction needs
# an item it consumes.
static func _needs_item(target: String, recipe_key: String) -> bool:
	if target != Shares.PLAYER:
		return int(GameData.FACTIONS[target].get("consumes", {}).get(recipe_key, 0)) > 0
	for contract in Contracts.active_contracts():
		for line in Contracts.request_lines(contract["request"]):
			if line["kind"] == "consumable" and line["type"] == recipe_key and Contracts.remaining_qty(contract, recipe_key) > 0:
				return true
	return false


# Lowball buyout (player only, while the player is squeezed: cash under
# lowball.cashBelow or a vein lost within lowball.lostVeinDays): offer
# lowball.priceMult × VeinTrade.quote for the player's highest-quoted
# vein not quest-locked, under raid or already offered. The observer must
# afford the price and have a key member who can speak. Damage = the
# discount on Factions.vein_value() (the raid scale) × lowball.damageMult
# (the player may say no).
static func _lowball_candidate(observer: String, target: String) -> Dictionary:
	var best := {}
	if target != Shares.PLAYER or not _player_squeezed() or not KeyMembers.can_speak(observer) or not _ecfg()["moveLines"].get(observer, {}).has(MOVE_LOWBALL):
		return best
	var resources := int(GameState.state["factions"][observer]["resources"])
	for vein in GameState.state["player"]["veins"]:
		var site_id: Variant = vein.get("siteId")
		if site_id == null or Sites.find_site(site_id) == null or Collective.is_quest_locked_vein(vein["id"]):
			continue
		if _raid_queued(vein["id"]) or Raiding.has_pending_defend(vein["id"]) or _lowball_pending(vein["id"]):
			continue
		var quote := VeinTrade.quote(vein)
		var price := GameState.round_epsilon(quote * float(_ecfg()["lowball"]["priceMult"]))
		var damage := Factions.vein_value(vein) * (1.0 - float(_ecfg()["lowball"]["priceMult"])) * float(_ecfg()["lowball"]["damageMult"])
		if price <= 0 or price > resources or damage <= 0.0:
			continue
		if best.is_empty() or damage > float(best["damage"]):
			best = { "move": MOVE_LOWBALL, "damage": damage, "cost": 0, "veinId": vein["id"], "price": price }
	return best


static func _player_squeezed() -> bool:
	var cfg: Dictionary = _ecfg()["lowball"]
	if int(GameState.state["player"]["cash"]) < int(cfg["cashBelow"]):
		return true
	var lost := int(GameState.state["factionEscalation"].get("lastVeinLostDay", -1))
	return lost >= 0 and int(GameState.state["world"]["day"]) - lost <= int(cfg["lostVeinDays"])


static func _lowball_pending(vein_id: String) -> bool:
	for entry in GameState.state["pendingMessages"]:
		if entry["kind"] == LOWBALL_KIND and entry["payload"].get("veinId", "") == vein_id:
			return true
	return false


# Pending lowball offers whose expiresDay has passed are withdrawn.
static func _drop_lapsed_lowballs() -> void:
	var day: int = GameState.state["world"]["day"]
	GameState.state["pendingMessages"] = GameState.state["pendingMessages"].filter(func(e: Dictionary) -> bool:
		return e["kind"] != LOWBALL_KIND or day <= int(e["payload"].get("expiresDay", 0)))


# The pending lowball entry with this id, or {}.
static func _find_lowball(pending_id: String) -> Dictionary:
	for entry in GameState.state["pendingMessages"]:
		if entry["id"] == pending_id and entry["kind"] == LOWBALL_KIND:
			return entry
	return {}


# Accepts a lowball buyout: the vein goes to the faction through VeinTrade's
# sell-to-faction path at the offered price, paid from the faction's cash.
static func accept_lowball(pending_id: String) -> Dictionary:
	var entry := _find_lowball(pending_id)
	if entry.is_empty():
		return { "ok": false, "reason": "Offer not found." }
	Messages.resolve_pending(pending_id)
	var payload: Dictionary = entry["payload"]
	var faction_id: String = payload["factionId"]
	var price := int(payload["price"])
	if int(GameState.state["world"]["day"]) > int(payload["expiresDay"]):
		return { "ok": false, "reason": "Offer expired." }
	if int(GameState.state["factions"][faction_id]["resources"]) < price:
		return { "ok": false, "reason": "They can't afford it now." }
	var result := VeinTrade.sell_at_price(payload["veinId"], faction_id, price)
	if result.get("ok", false):
		GameState.state["factions"][faction_id]["resources"] -= price
		EventBus.state_changed.emit()
	return result


static func decline_lowball(pending_id: String) -> void:
	Messages.resolve_pending(pending_id)


# A poached renewal the player let go: the buyer goes with the rival.
static func poach_lapsed(offer: Dictionary) -> void:
	var poach: Dictionary = offer["poach"]
	var buyer: String = GameData.FACTIONS.get(offer.get("counterparty", ""), {}).get("shortName", "the buyer")
	log_activity(poach["factionId"], _ecfg()["log"][MOVE_POACH]["lapsed"] % buyer, { "target": Shares.PLAYER, "move": MOVE_POACH })


# The target vein with the highest success chance × Factions.vein_value().
static func _vein_raid_candidate(observer: String, target: String) -> Dictionary:
	var best := {}
	for option in _raidable_veins(observer, target):
		var damage := float(option["chance"]) * Factions.vein_value(option["vein"])
		if best.is_empty() or damage > float(best["damage"]):
			best = { "move": MOVE_VEIN_RAID, "damage": damage, "cost": _move_cost(MOVE_VEIN_RAID), "veinId": option["vein"]["id"], "siteId": option["siteId"] }
	return best


# { vein, siteId, chance } per vein observer could raid. Faction targets
# need constants.json factionRivalry on.
static func _raidable_veins(observer: String, target: String) -> Array:
	var options := []
	if target == Shares.PLAYER:
		for vein in GameState.state["player"]["veins"]:
			var site_id: Variant = vein.get("siteId")
			if site_id == null or Sites.find_site(site_id) == null or Collective.is_quest_locked_vein(vein["id"]):
				continue
			if _raid_queued(vein["id"]) or Raiding.has_pending_defend(vein["id"]):
				continue
			options.append({ "vein": vein, "siteId": site_id, "chance": Raiding.raid_success_chance(observer, vein) })
		return options
	if not GameData.FACTION_RIVALRY:
		return options
	for site in GameState.state["world"]["sites"]:
		var vein: Variant = site.get("factionVein")
		if vein == null or vein["factionId"] != target or Collective.is_quest_locked_vein(vein["id"]) or _raid_queued(vein["id"]):
			continue
		var attempt := { "attackerId": observer, "defenderId": target, "veinSiteId": site["id"] }
		var chance := Factions.rivalry_success_chance(attempt) * Collective.firm_target_multiplier(observer, target)
		options.append({ "vein": vein, "siteId": site["id"], "chance": chance })
	return options


static func _raid_queued(vein_id: String) -> bool:
	for entry in GameState.state["factionEscalation"]["queuedRaids"]:
		if entry["veinId"] == vein_id:
			return true
	return false


# A raid is queued for the next rollover's raid resolution (Factions ⑤c
# for a faction target, Raiding ⑤d for the player). Market moves land now
# and are reported now: today's reprice (⑥.6) prices a flood in.
static func _make_move(observer: String, target: String, move: Dictionary) -> void:
	match move["move"]:
		MOVE_VEIN_RAID:
			GameState.state["factionEscalation"]["queuedRaids"].append({
				"attackerId": observer, "targetId": target, "veinId": move["veinId"], "siteId": move["siteId"],
			})
		MOVE_FLOOD:
			FactionSim.flood(observer, move["good"], int(move["qty"]), float(_ecfg()["flood"]["priceMult"]))
			_report_market_move(observer, target, MOVE_FLOOD, move["good"])
		MOVE_WITHHOLD:
			_withholds().append({
				"factionId": observer, "targetId": target, "kind": "ore", "good": move["good"],
				"untilDay": int(GameState.state["world"]["day"]) + int(_ecfg()["withhold"]["days"]),
			})
			_report_market_move(observer, target, MOVE_WITHHOLD, move["good"])
		MOVE_OUTBID:
			var site: Dictionary = Sites.find_site(move["siteId"])
			Sites.seed_faction_vein(site, observer)
			var district_name: String = GameData.DISTRICTS[site["district"]]["name"]
			_report_player(observer, MOVE_OUTBID, district_name, district_name)
		MOVE_POACH:
			var offer := _pending_offer(move["offerId"])
			var price := GameState.round_epsilon(float(offer["quote"]["payment"]) * float(_ecfg()["poach"]["priceMult"]))
			offer["poach"] = { "factionId": observer, "payment": price }
			var buyer: String = GameData.FACTIONS.get(offer.get("counterparty", ""), {}).get("shortName", "Your buyer")
			_report_player(observer, MOVE_POACH, buyer, buyer)
		MOVE_WITHHOLD_ITEMS:
			_withholds().append({
				"factionId": observer, "targetId": target, "kind": "consumable", "good": move["good"],
				"untilDay": int(GameState.state["world"]["day"]) + int(_ecfg()["withhold"]["days"]),
			})
			var item_name: String = GameData.RECIPES[move["good"]]["name"]
			if target == Shares.PLAYER:
				_report_player(observer, MOVE_WITHHOLD_ITEMS, item_name, item_name)
			else:
				_report_pair_goods_move(observer, target, MOVE_WITHHOLD_ITEMS, item_name)
		MOVE_LOWBALL:
			_offer_lowball(observer, move)
		MOVE_UNDERCUT:
			FactionSim.undercut(observer, move["kind"], move["good"], int(move["qty"]), float(_ecfg()["undercut"]["priceMult"]))
			_report_goods_move(observer, target, MOVE_UNDERCUT, move["kind"], move["good"])
		MOVE_DENY:
			FactionSim.deny(observer, move["kind"], move["good"], int(move["qty"]))
			_withholds().append({
				"factionId": observer, "targetId": target, "kind": move["kind"], "good": move["good"],
				"untilDay": int(GameState.state["world"]["day"]) + int(_ecfg()["deny"]["days"]),
			})
			_report_goods_move(observer, target, MOVE_DENY, move["kind"], move["good"])


# A flood or withhold of ore_type. Against the player: key member line
# (with the ore id) and tagged log. Between factions: both sides' logs, and
# a flood is a Ticker headline.
static func _report_market_move(observer: String, target: String, move_id: String, ore_type: String) -> void:
	var ore_name: String = GameData.ORE_TYPES[ore_type]["name"]
	if target == Shares.PLAYER:
		_report_player(observer, move_id, ore_type, ore_name)
		return
	if move_id != MOVE_FLOOD:
		_report_pair_goods_move(observer, target, move_id, ore_name)
		return
	var log_cfg: Dictionary = _ecfg()["log"][move_id]
	var observer_name: String = GameData.FACTIONS[observer]["shortName"]
	var target_name: String = GameData.FACTIONS[target]["shortName"]
	log_activity(observer, log_cfg["attacker"] % [target_name, ore_name])
	Barometer.push_headline(_ecfg()["headlines"]["flood"] % [observer_name, ore_name, target_name])
	log_activity(target, log_cfg["defender"] % [observer_name, ore_name])


# A move on good_name between factions, logged on both sides.
static func _report_pair_goods_move(observer: String, target: String, move_id: String, good_name: String) -> void:
	var log_cfg: Dictionary = _ecfg()["log"][move_id]
	log_activity(observer, log_cfg["attacker"] % [good_name, GameData.FACTIONS[target]["shortName"]])
	log_activity(target, log_cfg["defender"] % [GameData.FACTIONS[observer]["shortName"], good_name])


# An undercut or deny of an ore or item: the key member's line (good name)
# against the player, else both sides' logs.
static func _report_goods_move(observer: String, target: String, move_id: String, kind: String, good_type: String) -> void:
	var good_name: String = GameData.ORE_TYPES[good_type]["name"] if kind == "ore" else GameData.RECIPES[good_type]["name"]
	if target == Shares.PLAYER:
		_report_player(observer, move_id, good_name, good_name)
	else:
		_report_pair_goods_move(observer, target, move_id, good_name)


static func _pending_offer(offer_id: String) -> Dictionary:
	for offer in Offers.pending_offers():
		if offer["id"] == offer_id:
			return offer
	return {}


# Sends the lowball as an actionable key-member message (LOWBALL_KIND,
# payload { factionId, veinId, price, expiresDay }), logged for BizBrief.
static func _offer_lowball(observer: String, move: Dictionary) -> void:
	var vein: Variant = Cultivating.find_vein(move["veinId"])
	var district_name: String = GameData.DISTRICTS[vein["district"]]["name"]
	var price := int(move["price"])
	var payload := {
		"factionId": observer, "veinId": move["veinId"], "price": price,
		"expiresDay": int(GameState.state["world"]["day"]) + int(_ecfg()["lowball"]["expiryDays"]),
	}
	var line: String = _ecfg()["moveLines"][observer][MOVE_LOWBALL]
	KeyMembers.send(observer, line % [district_name, price], LOWBALL_KIND, payload)
	log_activity(observer, _ecfg()["log"][MOVE_LOWBALL]["player"] % district_name, { "target": Shares.PLAYER, "move": MOVE_LOWBALL })
	_explain_once(MOVE_LOWBALL)


# A market move against the player: the key member's moveLines line
# (line_arg), log[move].player (log_arg) tagged for BizBrief, and Archie's
# explainer the first time.
static func _report_player(faction_id: String, move_id: String, line_arg: String, log_arg: String) -> void:
	var line: String = _ecfg()["moveLines"].get(faction_id, {}).get(move_id, "")
	if line != "":
		KeyMembers.send(faction_id, line % line_arg)
	log_activity(faction_id, _ecfg()["log"][move_id]["player"] % log_arg, { "target": Shares.PLAYER, "move": move_id })
	_explain_once(move_id)


static func _explain_once(move_id: String) -> void:
	var explained: Array = GameState.state["factionEscalation"]["explained"]
	if not explained.has(move_id):
		explained.append(move_id)
		Messages.append("archie", "them", _ecfg()["explainers"][move_id])


# Removes and returns the queued raids against the player (for_player) or
# against factions.
static func take_queued_raids(for_player: bool) -> Array:
	var escalation: Dictionary = GameState.state["factionEscalation"]
	var taken := []
	var kept := []
	for entry in escalation["queuedRaids"]:
		if (entry["targetId"] == Shares.PLAYER) == for_player:
			taken.append(entry)
		else:
			kept.append(entry)
	escalation["queuedRaids"] = kept
	return taken


# A resolved move against the player: the key member's line, an activity-log
# entry tagged for BizBrief, and Archie's explainer the first time.
static func report_player_move(faction_id: String, move_id: String, district_id: String, landed: bool) -> void:
	var district_name: String = GameData.DISTRICTS[district_id]["name"]
	var line: String = _ecfg()["moveLines"].get(faction_id, {}).get(move_id, {}).get("hit" if landed else "miss", "")
	if line != "":
		KeyMembers.send(faction_id, line % district_name)
	var log_text: String = _ecfg()["log"][move_id]["playerHit" if landed else "playerMiss"]
	log_activity(faction_id, log_text % district_name, { "target": Shares.PLAYER, "move": move_id })
	_explain_once(move_id)


# A resolved faction-vs-faction move, logged on both sides.
static func report_pair_move(attacker_id: String, defender_id: String, move_id: String, district_id: String, landed: bool) -> void:
	var district_name: String = GameData.DISTRICTS[district_id]["name"]
	var log_cfg: Dictionary = _ecfg()["log"][move_id]
	var attacker_name: String = GameData.FACTIONS[attacker_id]["shortName"]
	var defender_name: String = GameData.FACTIONS[defender_id]["shortName"]
	log_activity(attacker_id, log_cfg["attackerHit" if landed else "attackerMiss"] % [defender_name, district_name])
	log_activity(defender_id, log_cfg["defenderHit" if landed else "defenderMiss"] % [attacker_name, district_name])


# Every activity-log entry tagged as a move against the player, newest
# first, each with its factionId.
static func moves_against_player() -> Array:
	var moves := []
	for faction_id in GameData.FACTIONS.keys():
		for entry in activity_log(faction_id):
			if entry.get("target", "") == Shares.PLAYER:
				var move: Dictionary = entry.duplicate()
				move["factionId"] = faction_id
				moves.append(move)
	moves.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["day"]) > int(b["day"]))
	return moves

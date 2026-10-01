class_name FactionAI
extends RefCounted

# Faction politics (R§3.1 "Stances"): the relation clamp, the stored stance
# for every faction pair and for the player with each faction, the daily
# hysteresis stance update, each faction's bounded activity log, the
# daily threat/dependence pressure drift (R§3.1 "Pressure") and the
# escalation menus (R§3.1 "Escalation") and the Conclave stabiliser, war
# squeeze and positions (R§3.1 "Conclave ..."). Data in constants.json factionStances,
# factionPressure, factionEscalation, factionWar and factionConclave.
# Static funcs only.

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


# London's stance matrix as rows, the player with each faction then every
# faction pair: { a, b, stance, war, truceEndDay } (truceEndDay -1 without a truce).
static func stance_matrix() -> Array:
	var pairs := []
	for faction_id in GameData.FACTIONS.keys():
		pairs.append([Shares.PLAYER, faction_id])
	pairs.append_array(_pairs())
	var rows := []
	for pair in pairs:
		var truce := find_truce(pair[0], pair[1])
		rows.append({
			"a": pair[0],
			"b": pair[1],
			"stance": player_stance(pair[1]) if pair[0] == Shares.PLAYER else pair_stance(pair[0], pair[1]),
			"war": at_war(pair[0], pair[1]),
			"truceEndDay": int(truce["endDay"]) if not truce.is_empty() else -1,
		})
	return rows


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
	if _cfg()["headlines"].has(stance):
		Barometer.push_headline(_cfg()["headlines"][stance] % [GameData.FACTIONS[faction_a]["shortName"], GameData.FACTIONS[faction_b]["shortName"]])


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
# the rounded mean of its two directions plus pair_recovery. Held pairs
# don't move.
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
		Factions.adjust_relation(pair[0], pair[1], roundi(mean + pair_recovery(pair[0], pair[1])))
	EventBus.state_changed.emit()


# The pair relation's daily pull back toward its starting relation:
# pairRecoveryRate × (starting − current).
static func pair_recovery(faction_a: String, faction_b: String) -> float:
	var gap := starting_pair_relation(faction_a, faction_b) - Factions.get_relation(faction_a, faction_b)
	return float(_pcfg()["pairRecoveryRate"]) * gap


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
# player relation and its last rounded drift: Moving against you below its
# market line, Annoyed below its warning line.
static func pressure_label(faction_id: String) -> String:
	var labels: Dictionary = _pcfg()["labels"]
	var relation: int = GameState.state["factions"][faction_id]["relation"]
	if relation < market_line(faction_id):
		return labels["movingAgainst"]
	if roundi(player_delta(faction_id)) >= 0:
		return labels["calm"]
	if relation < warning_line(faction_id):
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
const MOVE_STOCKPILE_RAID := "stockpileRaid"
const MOVE_FLOOD := "flood"
const MOVE_WITHHOLD := "withhold"
const MOVE_OUTBID := "outbid"
const MOVE_POACH := "poach"
const MOVE_WITHHOLD_ITEMS := "withholdItems"
const MOVE_LOWBALL := "lowballBuyout"
const MOVE_UNDERCUT := "undercut"
const MOVE_DENY := "denyGoods"
const MOVE_TICKER_PUSH := "tickerPush"
const MOVE_SELL_INTEL := "sellIntel"
const MOVE_PRICE_GOUGE := "priceGouge"
const MOVE_DISINFORMATION := "disinformation"
const MOVE_SHORTFALL_STEAL := "shortfallSteal"
const LOWBALL_KIND := "faction_lowball_buyout"
# A planned_moves() entry for a warning, which isn't a menu move.
const PLAN_WARNING := "warning"


static func _ecfg() -> Dictionary:
	return GameData.FACTION_ESCALATION


# state.factionEscalation: { targets: { observerId: { targetId: {
# warnedBand, lastMoveDay } } }, queuedRaids: [ { attackerId, targetId,
# veinId, siteId, move? } (move absent = veinRaid, or "shortfallSteal") or
# { attackerId, targetId, move: "stockpileRaid" } ], explained: [moveId],
# withholds: [ { factionId, targetId, kind, good, untilDay } ],
# lastVeinLostDay, shortfallDays: { factionId: { oreType: days } } }.
# lastMoveDay and lastVeinLostDay -1 = never.
static func new_escalation_state() -> Dictionary:
	return { "targets": {}, "queuedRaids": [], "explained": [], "withholds": [], "lastVeinLostDay": -1, "shortfallDays": {} }


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


# The faction's market and warning lines: its raidThreshold plus
# marketAboveRaid / warningAboveRaid, so every faction's bands run
# warning > market > raid.
static func market_line(faction_id: String) -> int:
	return int(GameData.FACTIONS[faction_id]["raidThreshold"]) + int(_ecfg()["marketAboveRaid"])


static func warning_line(faction_id: String) -> int:
	return int(GameData.FACTIONS[faction_id]["raidThreshold"]) + int(_ecfg()["warningAboveRaid"])


# The deepest band open to observer against target: raid when Hostile or
# below the observer's raidThreshold, else market below its market line,
# else warning below its warning line, else none.
static func band(observer: String, target: String) -> String:
	var relation := _relation_to(observer, target)
	if _stance_to(observer, target) == HOSTILE or relation < int(GameData.FACTIONS[observer]["raidThreshold"]):
		return BAND_RAID
	if relation < market_line(observer):
		return BAND_MARKET
	if relation < warning_line(observer):
		return BAND_WARNING
	return BAND_NONE


static func _depth(band_id: String) -> int:
	return BAND_ORDER.find(band_id)


static func band_depth_of(band_id: String) -> int:
	return _depth(band_id)


# How deep observer's band against target sits in BAND_ORDER.
static func band_depth(observer: String, target: String) -> int:
	return _depth(band(observer, target))


# observer's relation toward target (player or faction).
static func relation_toward(observer: String, target: String) -> int:
	return _relation_to(observer, target)


# The observer's last drift toward the target (player or faction).
static func _delta_to(observer: String, target: String) -> float:
	var row: Dictionary = GameState.state["factionPressure"]["snapshots"].get(observer, {})
	return float(row.get(target, {}).get("delta", 0.0))


static func in_truce(party_a: String, party_b: String) -> bool:
	return not find_truce(party_a, party_b).is_empty()


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
	_drop_lapsed_gouges()
	_drop_lapsed_lowballs()
	var ids: Array = GameData.FACTIONS.keys()
	for observer in ids:
		for target in [Shares.PLAYER] + ids:
			if target != observer and not moves_blocked(observer, target):
				_escalate(observer, target)
	_apply_shortfall_steals()
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
		MOVE_STOCKPILE_RAID:
			return _stockpile_raid_candidate(observer, target)
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
		MOVE_TICKER_PUSH:
			return _ticker_push_candidate(observer, target)
		MOVE_SELL_INTEL:
			return _sell_intel_candidate(observer, target)
		MOVE_PRICE_GOUGE:
			return _price_gouge_candidate(observer, target)
		MOVE_DISINFORMATION:
			return _disinformation_candidate(observer, target)
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


# The target vein with the highest success chance × Factions.vein_value(),
# as the observer's intel sees them (Intel.score_raid_options), × raidBias
# on veins of the observer's primary/secondary ore.
static func _vein_raid_candidate(observer: String, target: String) -> Dictionary:
	var best := {}
	for option in _scored_raid_options(observer, target):
		var damage := float(option["score"]) * raid_bias(observer, option["vein"]["oreType"])
		if best.is_empty() or damage > float(best["damage"]):
			best = { "move": MOVE_VEIN_RAID, "damage": damage, "cost": _move_cost(MOVE_VEIN_RAID), "veinId": option["vein"]["id"], "siteId": option["siteId"] }
	return best


# _raidable_veins with each option's value and intel score filled in.
static func _scored_raid_options(observer: String, target: String) -> Array:
	var options := _raidable_veins(observer, target)
	for option in options:
		option["value"] = Factions.vein_value(option["vein"])
	Intel.score_raid_options(observer, target, options)
	return options


# raidBias.primaryOre / secondaryOre for a vein of the attacker's own ore,
# else 1.
static func raid_bias(attacker: String, ore_type: String) -> float:
	var bias: Dictionary = _ecfg()["raidBias"]
	var data: Dictionary = GameData.FACTIONS[attacker]
	if ore_type == data["primaryOre"]:
		return float(bias["primaryOre"])
	if ore_type == data["secondaryOre"]:
		return float(bias["secondaryOre"])
	return 1.0


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
		if entry.get("veinId", "") == vein_id:
			return true
	return false


# A faction target's stockpile, once observer's intel reaches its location
# (never the player, who has no stockpile) and no raid on it is queued.
# Needs constants.json factionRivalry on.
# Damage = the rivalry odds against its guards × the London value of the
# share observer would take (Raiding.faction_stockpile_loot_share).
static func _stockpile_raid_candidate(observer: String, target: String) -> Dictionary:
	if target == Shares.PLAYER or not GameData.FACTION_RIVALRY or _stockpile_raid_queued(target) or not Raiding.faction_can_raid_stockpile(observer, target):
		return {}
	var value := Raiding.stockpile_value(target, Raiding.faction_stockpile_loot_share(observer, target))
	var damage := Factions.stockpile_rivalry_chance(observer, target) * value
	if damage <= 0.0:
		return {}
	return { "move": MOVE_STOCKPILE_RAID, "damage": damage, "cost": _move_cost(MOVE_STOCKPILE_RAID) }


static func _stockpile_raid_queued(target: String) -> bool:
	for entry in GameState.state["factionEscalation"]["queuedRaids"]:
		if entry.get("move", "") == MOVE_STOCKPILE_RAID and entry["targetId"] == target:
			return true
	return false


# ── Shortfall steal ─────────────────────────────────────────────────────
# R§3.1 "Shortfall steal": a shortfallSteal.factions faction short of an
# ore it consumes (held < FactionSim.ore_reserve > 0) for shortfallSteal.days
# straight rollovers queues a raid on a vein of that ore, outside the band
# ladder: any target but a Partner, not moves-blocked, not cooling.

static func _shortfall_days() -> Dictionary:
	var escalation: Dictionary = GameState.state["factionEscalation"]
	if not escalation.has("shortfallDays"):
		escalation["shortfallDays"] = {}
	return escalation["shortfallDays"]


# Days in a row faction_id has been short of ore_type.
static func shortfall_days(faction_id: String, ore_type: String) -> int:
	return int(_shortfall_days().get(faction_id, {}).get(ore_type, 0))


# Rollover step after the per-target escalation: counts each stealing
# faction's shortfall runs, then for the run-out ore with the largest gap
# that has a target vein, queues the steal (paying moveCosts.shortfallSteal)
# and restarts that ore's run.
static func _apply_shortfall_steals() -> void:
	var cfg: Dictionary = _ecfg()["shortfallSteal"]
	for faction_id in cfg["factions"]:
		var runs: Dictionary = _count_shortfalls(faction_id)
		var due: Array = runs.keys().filter(func(o: String) -> bool: return int(runs[o]) >= int(cfg["days"]))
		due.sort_custom(func(a: String, b: String) -> bool: return _ore_gap(faction_id, a) > _ore_gap(faction_id, b))
		for ore_type in due:
			var move := _shortfall_steal_candidate(faction_id, ore_type)
			if move.is_empty():
				continue
			if int(move["cost"]) > int(GameState.state["factions"][faction_id]["resources"]):
				break
			GameState.state["factions"][faction_id]["resources"] -= int(move["cost"])
			_target_entry(faction_id, move["targetId"])["lastMoveDay"] = int(GameState.state["world"]["day"])
			_queue_shortfall_steal(faction_id, move)
			runs.erase(ore_type)
			break


# Advances faction_id's run per ore it consumes: +1 while held < reserve,
# dropped once it isn't. Returns the faction's run table.
static func _count_shortfalls(faction_id: String) -> Dictionary:
	var all_runs := _shortfall_days()
	if not all_runs.has(faction_id):
		all_runs[faction_id] = {}
	var runs: Dictionary = all_runs[faction_id]
	for ore_type in GameData.ORE_TYPES.keys():
		if _ore_gap(faction_id, ore_type) > 0:
			runs[ore_type] = int(runs.get(ore_type, 0)) + 1
		else:
			runs.erase(ore_type)
	return runs


static func _ore_gap(faction_id: String, ore_type: String) -> int:
	return FactionSim.ore_reserve(faction_id, ore_type) - FactionSim.ore_held(faction_id, ore_type)


# The best-scoring vein of ore_type over every target observer may steal
# from, as { move, damage, cost, targetId, veinId, siteId, good }, or {}.
static func _shortfall_steal_candidate(observer: String, ore_type: String) -> Dictionary:
	var day: int = GameState.state["world"]["day"]
	var best := {}
	for target in [Shares.PLAYER] + GameData.FACTIONS.keys():
		if target == observer or moves_blocked(observer, target) or _stance_to(observer, target) == PARTNER or _cooling(_target_entry(observer, target), day):
			continue
		for option in _scored_raid_options(observer, target):
			if option["vein"]["oreType"] != ore_type:
				continue
			var damage := float(option["score"])
			if damage > 0.0 and (best.is_empty() or damage > float(best["damage"])):
				best = {
					"move": MOVE_SHORTFALL_STEAL, "damage": damage, "cost": _move_cost(MOVE_SHORTFALL_STEAL),
					"targetId": target, "veinId": option["vein"]["id"], "siteId": option["siteId"], "good": ore_type,
				}
	return best


static func _queue_shortfall_steal(observer: String, move: Dictionary) -> void:
	var target: String = move["targetId"]
	GameState.state["factionEscalation"]["queuedRaids"].append({
		"attackerId": observer, "targetId": target, "veinId": move["veinId"], "siteId": move["siteId"], "move": MOVE_SHORTFALL_STEAL,
	})
	if target == Shares.PLAYER:
		NetworkHandler.warn_of_raid(observer, move["siteId"])


# ── Network moves ───────────────────────────────────────────────────────
# R§3.1 "Network moves": the information broker's market rung. sellIntel
# sells intel on the target to its enemies, priceGouge raises the Network's
# prices to the target, disinformation leaves the target misreading its
# worst enemy.

static func _gouges() -> Array:
	var escalation: Dictionary = GameState.state["factionEscalation"]
	if not escalation.has("gouges"):
		escalation["gouges"] = []
	return escalation["gouges"]


static func _drop_lapsed_gouges() -> void:
	var day: int = GameState.state["world"]["day"]
	GameState.state["factionEscalation"]["gouges"] = _gouges().filter(func(e: Dictionary) -> bool: return day <= int(e["untilDay"]))


static func _gouging(observer: String, target: String) -> bool:
	var day: int = GameState.state["world"]["day"]
	for entry in GameState.state["factionEscalation"].get("gouges", []):
		if entry["factionId"] == observer and entry["targetId"] == target and day <= int(entry["untilDay"]):
			return true
	return false


# The Network's price multiplier to target: the highest active gouge on
# it, else 1.0.
static func gouge_mult(target: String) -> float:
	var day: int = GameState.state["world"]["day"]
	var mult := 1.0
	for entry in GameState.state["factionEscalation"].get("gouges", []):
		if entry["targetId"] == target and day <= int(entry["untilDay"]):
			mult = maxf(mult, float(entry["priceMult"]))
	return mult


# Factions other than observer and target, below their own market line with
# target, not in truce with it.
static func _enemies_of(observer: String, target: String) -> Array:
	var enemies := []
	for id in GameData.FACTIONS.keys():
		if id != observer and id != target and not in_truce(id, target) and _relation_to(id, target) < market_line(id):
			enemies.append(id)
	return enemies


# Enemies of target that can pay sellIntel.price and still have room on
# their meter. Damage = points they'd gain × damagePerPoint. None while
# target has privacy.
static func _sell_intel_candidate(observer: String, target: String) -> Dictionary:
	if Intel.privacy_active(target):
		return {}
	var cfg: Dictionary = _ecfg()["sellIntel"]
	var max_meter := int(GameData.INTEL["max"])
	var buyers := []
	var points := 0
	for enemy in _enemies_of(observer, target):
		var room := max_meter - Intel.meter(enemy, target)
		if room <= 0 or int(GameState.state["factions"][enemy]["resources"]) < int(cfg["price"]):
			continue
		buyers.append(enemy)
		points += mini(int(cfg["amount"]), room)
	if buyers.is_empty():
		return {}
	return { "move": MOVE_SELL_INTEL, "damage": float(points) * float(cfg["damagePerPoint"]), "cost": _move_cost(MOVE_SELL_INTEL), "buyers": buyers }


static func _price_gouge_candidate(observer: String, target: String) -> Dictionary:
	if _gouging(observer, target):
		return {}
	var cfg: Dictionary = _ecfg()["priceGouge"]
	return { "move": MOVE_PRICE_GOUGE, "damage": (float(cfg["priceMult"]) - 1.0) * float(cfg["damageBasis"]), "cost": _move_cost(MOVE_PRICE_GOUGE) }


# Target's worst enemy (lowest relation). A faction target must not already
# be misreading it; the player must know something about it to lose.
static func _disinformation_candidate(observer: String, target: String) -> Dictionary:
	var enemy := ""
	for id in _enemies_of(observer, target):
		if enemy == "" or _relation_to(id, target) < _relation_to(enemy, target):
			enemy = id
	if enemy == "":
		return {}
	if target == Shares.PLAYER:
		if Intel.meter(Shares.PLAYER, enemy) <= 0:
			return {}
	elif Intel.disinformation(target, enemy) != "":
		return {}
	return { "move": MOVE_DISINFORMATION, "damage": float(_ecfg()["disinformation"]["damage"]), "cost": _move_cost(MOVE_DISINFORMATION), "enemyId": enemy }


# Each buyer still able to pay sellIntel.price pays it to the observer and gains
# sellIntel.amount on target.
static func _sell_intel(observer: String, target: String, buyers: Array) -> void:
	var cfg: Dictionary = _ecfg()["sellIntel"]
	var price := int(cfg["price"])
	var sold := []
	for buyer in buyers:
		var wallet: Dictionary = GameState.state["factions"][buyer]
		if int(wallet["resources"]) < price:
			continue
		wallet["resources"] -= price
		GameState.state["factions"][observer]["resources"] += price
		Intel.raise(buyer, target, int(cfg["amount"]))
		sold.append(buyer)
	if sold.is_empty():
		return
	var short_names := _join_names(sold, "shortName")
	if target == Shares.PLAYER:
		_report_player(observer, MOVE_SELL_INTEL, _join_names(sold, "name"), short_names)
	else:
		_report_pair_intel_move(observer, target, MOVE_SELL_INTEL, [GameData.FACTIONS[target]["shortName"], short_names], [GameData.FACTIONS[observer]["shortName"], short_names])


# A faction target misreads enemy (inverted disinformation); the player
# loses disinformation.amount of its meter on enemy.
static func _leak_disinformation(observer: String, target: String, enemy: String) -> void:
	var cfg: Dictionary = _ecfg()["disinformation"]
	var enemy_short: String = GameData.FACTIONS[enemy]["shortName"]
	if target == Shares.PLAYER:
		Intel.raise(Shares.PLAYER, enemy, -int(cfg["amount"]))
		_report_player(observer, MOVE_DISINFORMATION, GameData.FACTIONS[enemy]["name"], enemy_short)
		return
	Intel.set_disinformation(target, enemy, Intel.DISINFO_INVERTED, int(cfg["days"]))
	_report_pair_intel_move(observer, target, MOVE_DISINFORMATION, [GameData.FACTIONS[target]["shortName"], enemy_short], [GameData.FACTIONS[observer]["shortName"], enemy_short])


static func _report_pair_intel_move(observer: String, target: String, move_id: String, attacker_args: Array, defender_args: Array) -> void:
	var log_cfg: Dictionary = _ecfg()["log"][move_id]
	log_activity(observer, log_cfg["attacker"] % attacker_args)
	log_activity(target, log_cfg["defender"] % defender_args)


# "A", "A and B", "A, B and C" from faction ids' `key` names.
static func _join_names(ids: Array, key: String) -> String:
	var names: Array = ids.map(func(id: String) -> String: return GameData.FACTIONS[id][key])
	if names.size() == 1:
		return names[0]
	return ", ".join(PackedStringArray(names.slice(0, -1))) + " and " + names.back()


# A raid is queued for the next rollover's raid resolution (Factions ⑤c
# for a faction target, Raiding ⑤d for the player). Market moves land now
# and are reported now: today's reprice (⑥.6) prices a flood in.
static func _make_move(observer: String, target: String, move: Dictionary) -> void:
	match move["move"]:
		MOVE_VEIN_RAID:
			GameState.state["factionEscalation"]["queuedRaids"].append({
				"attackerId": observer, "targetId": target, "veinId": move["veinId"], "siteId": move["siteId"],
			})
			if target == Shares.PLAYER:
				NetworkHandler.warn_of_raid(observer, move["siteId"])
		MOVE_STOCKPILE_RAID:
			GameState.state["factionEscalation"]["queuedRaids"].append({
				"attackerId": observer, "targetId": target, "move": MOVE_STOCKPILE_RAID,
			})
		MOVE_FLOOD:
			var value := Market.line_total("ore", Market.quote("ore", move["good"]), int(move["qty"]))
			var taken := FactionSim.flood(observer, move["good"], int(move["qty"]), float(_ecfg()["flood"]["priceMult"]))
			note_hostile_act(observer, target)
			note_spend(observer, float(value - taken))
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
		MOVE_TICKER_PUSH:
			_push_ticker(observer, move["section"], move["state"], int(_poscfg()["pushStrength"]))
			var state_name: String = GameData.BAROMETER_STATES[move["section"]][move["state"]]["label"]
			if target == Shares.PLAYER:
				_report_player(observer, MOVE_TICKER_PUSH, state_name, state_name)
			else:
				_report_pair_goods_move(observer, target, MOVE_TICKER_PUSH, state_name)
		MOVE_SELL_INTEL:
			_sell_intel(observer, target, move["buyers"])
		MOVE_PRICE_GOUGE:
			var gouge: Dictionary = _ecfg()["priceGouge"]
			_gouges().append({
				"factionId": observer, "targetId": target, "priceMult": float(gouge["priceMult"]),
				"untilDay": int(GameState.state["world"]["day"]) + int(gouge["days"]),
			})
			if target == Shares.PLAYER:
				_report_player(observer, MOVE_PRICE_GOUGE, str(gouge["days"]), str(gouge["days"]))
			else:
				_report_pair_intel_move(observer, target, MOVE_PRICE_GOUGE, [GameData.FACTIONS[target]["shortName"]], [GameData.FACTIONS[observer]["shortName"]])
		MOVE_DISINFORMATION:
			_leak_disinformation(observer, target, move["enemyId"])


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
# entry tagged for BizBrief, and Archie's explainer the first time. It
# restarts the pair's war clock.
static func report_player_move(faction_id: String, move_id: String, district_id: String, landed: bool) -> void:
	note_hostile_act(faction_id, Shares.PLAYER)
	var district_name: String = GameData.DISTRICTS[district_id]["name"]
	var line: String = _ecfg()["moveLines"].get(faction_id, {}).get(move_id, {}).get("hit" if landed else "miss", "")
	if line != "":
		KeyMembers.send(faction_id, line % district_name)
	var log_text: String = _ecfg()["log"][move_id]["playerHit" if landed else "playerMiss"]
	log_activity(faction_id, log_text % district_name, { "target": Shares.PLAYER, "move": move_id })
	_explain_once(move_id)


# A resolved faction-vs-faction move, logged on both sides. It restarts the
# pair's war clock.
static func report_pair_move(attacker_id: String, defender_id: String, move_id: String, district_id: String, landed: bool) -> void:
	note_hostile_act(attacker_id, defender_id)
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


# Every move a faction plans within horizon_days, soonest first, as
# { factionId, targetId, move, day } plus the move's own keys (good, kind,
# veinId, siteId, ...). Read off today's state: a queued raid lands at the
# next rollover; otherwise an acting faction moves at its first escalation
# off cooldown, with a warning first when the band is new (as _escalate).
static func planned_moves(horizon_days: int) -> Array:
	var day: int = GameState.state["world"]["day"]
	var plans := []
	for entry in GameState.state["factionEscalation"]["queuedRaids"]:
		var queued: Dictionary = entry.duplicate()
		queued["factionId"] = entry["attackerId"]
		queued["move"] = entry.get("move", MOVE_VEIN_RAID)
		queued["day"] = day + 1
		plans.append(queued)
	var ids: Array = GameData.FACTIONS.keys()
	for observer in ids:
		for target in [Shares.PLAYER] + ids:
			if target == observer or moves_blocked(observer, target):
				continue
			var plan := _planned_move(observer, target, day)
			if not plan.is_empty() and int(plan["day"]) - day <= horizon_days:
				plans.append(plan)
	plans.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["day"]) < int(b["day"]))
	return plans


static func _planned_move(observer: String, target: String, day: int) -> Dictionary:
	var current := band(observer, target)
	if current == BAND_NONE or (current != BAND_RAID and _delta_to(observer, target) >= 0.0):
		return {}
	var entry: Dictionary = GameState.state["factionEscalation"]["targets"].get(observer, {}).get(target, { "warnedBand": BAND_NONE, "lastMoveDay": -1 })
	var last := int(entry["lastMoveDay"])
	var due := day + 1 if last < 0 else maxi(day + 1, last + int(_ecfg()["cooldownDays"]))
	var warned: String = entry["warnedBand"]
	if _depth(current) < _depth(warned):
		warned = current
	var plan := { "move": PLAN_WARNING }
	if warned == current:
		plan = _best_move(observer, target, current).duplicate()
		if plan.is_empty():
			return {}
	plan["factionId"] = observer
	plan["targetId"] = target
	plan["day"] = due
	return plan


# ── War and weariness ───────────────────────────────────────────────────
# R§3.1 "War and weariness": two parties (factions, or the player and a
# faction) are at war while their stance is Hostile and a hostile act
# passed between them within windowDays. Each side of a war builds
# weariness from losses, cash drain above its peacetime spend, extra fronts
# and days at war; out of war it decays. Data in constants.json factionWar;
# per faction thresholds in factions.json weariness.

static func _wcfg() -> Dictionary:
	return GameData.FACTION_WAR


# state.factionWar: { wars: [ { parties: [a, b], startDay, lastHostileDay,
# weariness: { party: float } } ], lastHostile: { warKey: day }, hits:
# { party: { enemy: weariness points } }, spend: { party: £ today },
# peaceSpend: { party: £/day baseline }, weariness: { party: float },
# nagLevel, explained, truces: [ { parties: [a, b], startDay, endDay,
# dailyBonus, weekly: [ { from, to, amount } ] } ], negotiation: {} or the
# player's talks in progress (see new_negotiation), peaceCooldown:
# { factionId: day talks may reopen } }.
static func new_war_state() -> Dictionary:
	return { "wars": [], "lastHostile": {}, "hits": {}, "spend": {}, "peaceSpend": {}, "weariness": {}, "nagLevel": 0, "explained": false, "truces": [], "negotiation": {}, "peaceCooldown": {} }


static func _war() -> Dictionary:
	return GameState.state["factionWar"]


# Symmetric key for any two parties: pair_key for factions, "player:<id>"
# with the player.
static func war_key(party_a: String, party_b: String) -> String:
	if party_a == Shares.PLAYER:
		return "%s:%s" % [Shares.PLAYER, party_b]
	if party_b == Shares.PLAYER:
		return "%s:%s" % [Shares.PLAYER, party_a]
	return pair_key(party_a, party_b)


# Every pair that can go to war: faction pairs, then the player with each.
static func _war_pairs() -> Array:
	var pairs := _pairs()
	for faction_id in GameData.FACTIONS.keys():
		pairs.append([Shares.PLAYER, faction_id])
	return pairs


static func _pair_hostile(party_a: String, party_b: String) -> bool:
	if party_a == Shares.PLAYER:
		return player_stance(party_b) == HOSTILE
	return pair_stance(party_a, party_b) == HOSTILE


# A raid, flood, stockpile raid or shortfall steal by party_a against
# party_b: breaks any truce between them and restarts the war clock.
static func note_hostile_act(party_a: String, party_b: String) -> void:
	if party_a == party_b:
		return
	if in_truce(party_a, party_b):
		break_truce(party_a, party_b)
	_war()["lastHostile"][war_key(party_a, party_b)] = int(GameState.state["world"]["day"])
	if party_a == Shares.PLAYER:
		Diplomacy.note_player_hostile(party_b)


static func _add_hit(party: String, enemy: String, points: float) -> void:
	var hits: Dictionary = _war()["hits"]
	if not hits.has(party):
		hits[party] = {}
	hits[party][enemy] = float(hits[party].get(enemy, 0.0)) + points


# party lost value_gbp (a vein at its value, stolen stock, guards) to enemy.
static func note_loss(party: String, enemy: String, value_gbp: float) -> void:
	if value_gbp > 0.0:
		_add_hit(party, enemy, value_gbp / 100.0 * float(_wcfg()["weights"]["lossPer100"]))


# party lost a fight (a failed or repelled raid, a lost defence) to enemy.
static func note_fight_lost(party: String, enemy: String) -> void:
	_add_hit(party, enemy, float(_wcfg()["weights"]["fightLost"]))


# Discretionary security or war spend today: guard hires, security
# upgrades, a flood's discount.
static func note_spend(party: String, amount: float) -> void:
	if amount > 0.0:
		var spend: Dictionary = _war()["spend"]
		spend[party] = float(spend.get(party, 0.0)) + amount


static func _find_war(key: String) -> Dictionary:
	for war in _war()["wars"]:
		if war_key(war["parties"][0], war["parties"][1]) == key:
			return war
	return {}


static func wars() -> Array:
	return _war()["wars"]


static func wars_of(party: String) -> Array:
	return wars().filter(func(w: Dictionary) -> bool: return w["parties"].has(party))


static func at_war(party_a: String, party_b: String) -> bool:
	return not _find_war(war_key(party_a, party_b)).is_empty()


# The party's weariness: its highest across its wars, or its decaying
# weariness out of war.
static func weariness(party: String) -> float:
	return float(_war()["weariness"].get(party, 0.0))


static func war_enemy(war: Dictionary, party: String) -> String:
	return war["parties"][1] if war["parties"][0] == party else war["parties"][0]


static func accept_peace_at(faction_id: String) -> int:
	return int(GameData.FACTIONS[faction_id]["weariness"]["acceptPeace"])


static func offer_peace_at(faction_id: String) -> int:
	return int(GameData.FACTIONS[faction_id]["weariness"]["offerPeace"])


static func _war_live(party_a: String, party_b: String, day: int) -> bool:
	if in_truce(party_a, party_b) or not _pair_hostile(party_a, party_b):
		return false
	if party_a != Shares.PLAYER and is_held_pair(party_a, party_b):
		return false
	var last: Variant = _war()["lastHostile"].get(war_key(party_a, party_b))
	return last != null and day - int(last) <= int(_wcfg()["windowDays"])


# Rollover step: wars start and end, each side of a war gains weariness,
# everyone else's decays, and the player's nag level is checked.
static func update_wars() -> void:
	var state := _war()
	var day: int = GameState.state["world"]["day"]
	_update_truces(day)
	for pair in _war_pairs():
		var key := war_key(pair[0], pair[1])
		var war := _find_war(key)
		var live := _war_live(pair[0], pair[1], day)
		if war.is_empty() and live:
			_start_war(pair[0], pair[1], day)
		elif not war.is_empty() and not live:
			_end_war(war)
		elif not war.is_empty():
			war["lastHostileDay"] = int(state["lastHostile"][key])
	_gain_weariness()
	state["hits"] = {}
	state["spend"] = {}
	_make_faction_peace()
	_offer_player_peace()
	_check_nags()
	EventBus.state_changed.emit()


static func _start_war(party_a: String, party_b: String, day: int) -> void:
	var state := _war()
	state["wars"].append({
		"parties": [party_a, party_b], "startDay": day,
		"lastHostileDay": int(state["lastHostile"][war_key(party_a, party_b)]),
		"weariness": { party_a: weariness(party_a), party_b: weariness(party_b) },
	})
	var log_cfg: Dictionary = _wcfg()["log"]
	if party_a == Shares.PLAYER:
		log_activity(party_b, log_cfg["startedPlayer"])
		if not state["explained"]:
			state["explained"] = true
			Messages.append("archie", "them", _wcfg()["explainer"] % int(_wcfg()["windowDays"]))
		return
	var name_a: String = GameData.FACTIONS[party_a]["shortName"]
	var name_b: String = GameData.FACTIONS[party_b]["shortName"]
	log_activity(party_a, log_cfg["startedPair"] % name_b)
	log_activity(party_b, log_cfg["startedPair"] % name_a)
	Barometer.push_headline(_wcfg()["headlines"]["warDeclared"] % [name_a, name_b])


static func _end_war(war: Dictionary) -> void:
	_war()["wars"].erase(war)
	var a: String = war["parties"][0]
	var b: String = war["parties"][1]
	var log_cfg: Dictionary = _wcfg()["log"]
	if a == Shares.PLAYER:
		log_activity(b, log_cfg["endedPlayer"])
	else:
		log_activity(a, log_cfg["endedPair"] % GameData.FACTIONS[b]["shortName"])
		log_activity(b, log_cfg["endedPair"] % GameData.FACTIONS[a]["shortName"])


# Per side of each war: (hits from that enemy + its share of today's drain
# above its peacetime spend + dayAtWar) × (1 + extraFront per other war),
# capped at 100. A party out of war updates its peacetime spend and decays.
static func _gain_weariness() -> void:
	var state := _war()
	var weights: Dictionary = _wcfg()["weights"]
	for party in [Shares.PLAYER] + GameData.FACTIONS.keys():
		var fronts := wars_of(party)
		var spent := float(state["spend"].get(party, 0.0))
		var baseline := float(state["peaceSpend"].get(party, 0.0))
		if fronts.is_empty():
			state["peaceSpend"][party] = _snap(baseline + float(_wcfg()["peaceSpendRate"]) * (spent - baseline))
			state["weariness"][party] = _snap(maxf(0.0, weariness(party) - float(_wcfg()["decayPerDay"])))
			continue
		var drain_points := maxf(0.0, spent - baseline) / 100.0 * float(weights["drainPer100"]) / fronts.size()
		var mult := 1.0 + float(weights["extraFront"]) * (fronts.size() - 1)
		var highest := 0.0
		for war in fronts:
			var hit := float(state["hits"].get(party, {}).get(war_enemy(war, party), 0.0))
			var gain := (hit + drain_points + float(weights["dayAtWar"])) * mult
			var value := _snap(minf(100.0, float(war["weariness"].get(party, 0.0)) + gain))
			war["weariness"][party] = value
			highest = maxf(highest, value)
		state["weariness"][party] = highest


# Nag level = how many player.nagAt thresholds the player's weariness
# reaches, or one past them at player.extreme. A rise sends that level's
# line (James falls back to Archie until unlocked); a fall rearms it.
static func _check_nags() -> void:
	var state := _war()
	var level := nag_level_for(weariness(Shares.PLAYER))
	if level > int(state["nagLevel"]):
		var nags: Array = _wcfg()["nags"]
		var nag: Dictionary = nags[level - 1] if level <= nags.size() else _wcfg()["extremeNag"]
		var contact_id: String = nag["contactId"]
		if not GameState.state["contacts"].get(contact_id, {}).get("unlocked", false):
			contact_id = "archie"
		Messages.append(contact_id, "them", nag["text"])
	state["nagLevel"] = level


static func nag_level_for(value: float) -> int:
	var cfg: Dictionary = _wcfg()["player"]
	if value >= float(cfg["extreme"]):
		return cfg["nagAt"].size() + 1
	var level := 0
	for threshold in cfg["nagAt"]:
		if value >= float(threshold):
			level += 1
	return level


static func player_extreme() -> bool:
	return weariness(Shares.PLAYER) >= float(_wcfg()["player"]["extreme"])


# ── Truce and peace ─────────────────────────────────────────────────────
# R§3.1 "Truce and peace": a truce stops all moves between its parties
# until endDay. Signing sets their relation just above the Hostile band and
# ends their war; each day of it adds dailyBonus on top of drift. A hostile
# act against a truce partner breaks it and costs the breaker breakPenalty
# with every faction. Data in constants.json factionWar.truce and
# factionWar.negotiation.

static func _tcfg() -> Dictionary:
	return _wcfg()["truce"]


static func _ncfg() -> Dictionary:
	return _wcfg()["negotiation"]


static func truces() -> Array:
	return _war()["truces"]


static func find_truce(party_a: String, party_b: String) -> Dictionary:
	var key := war_key(party_a, party_b)
	for truce in truces():
		if war_key(truce["parties"][0], truce["parties"][1]) == key:
			return truce
	return {}


static func _relation_between(party_a: String, party_b: String) -> int:
	if party_a == Shares.PLAYER:
		return int(GameState.state["factions"][party_b]["relation"])
	if party_b == Shares.PLAYER:
		return int(GameState.state["factions"][party_a]["relation"])
	return Factions.get_relation(party_a, party_b)


static func _adjust_between(party_a: String, party_b: String, delta: int) -> void:
	if party_a == Shares.PLAYER:
		Factions.adjust_player_relation(party_b, delta)
	elif party_b == Shares.PLAYER:
		Factions.adjust_player_relation(party_a, delta)
	else:
		Factions.adjust_relation(party_a, party_b, delta)


static func _party_name(party: String) -> String:
	return GameData.FACTIONS[party]["shortName"] if party != Shares.PLAYER else ""


static func _log_truce(party_a: String, party_b: String, pair_line: String, player_line: String) -> void:
	var log_cfg: Dictionary = _tcfg()["log"]
	if party_a == Shares.PLAYER or party_b == Shares.PLAYER:
		log_activity(party_b if party_a == Shares.PLAYER else party_a, log_cfg[player_line])
		return
	log_activity(party_a, log_cfg[pair_line] % _party_name(party_b))
	log_activity(party_b, log_cfg[pair_line] % _party_name(party_a))


# Signs a truce on terms { truceDays, weekly: [ { from, to, amount } ] }:
# relation set to just above the Hostile band, their war ended, queued
# raids and withholds between them dropped, logged on both sides and,
# between factions, a Ticker headline.
static func sign_truce(party_a: String, party_b: String, terms: Dictionary) -> void:
	var day: int = GameState.state["world"]["day"]
	truces().append({
		"parties": [party_a, party_b], "startDay": day,
		"endDay": day + int(terms.get("truceDays", _tcfg()["defaultDays"])),
		"dailyBonus": int(_tcfg()["dailyBonus"]),
		"weekly": GameState.deep_copy(terms.get("weekly", [])),
	})
	var target := int(_cfg()["hostileAtOrBelow"]) + int(_tcfg()["relationAboveHostile"])
	_adjust_between(party_a, party_b, target - _relation_between(party_a, party_b))
	var war := _find_war(war_key(party_a, party_b))
	if not war.is_empty():
		_war()["wars"].erase(war)
	var key := war_key(party_a, party_b)
	var escalation: Dictionary = GameState.state["factionEscalation"]
	escalation["queuedRaids"] = escalation["queuedRaids"].filter(func(r: Dictionary) -> bool:
		return war_key(r["attackerId"], r["targetId"]) != key)
	escalation["withholds"] = _withholds().filter(func(w: Dictionary) -> bool:
		return war_key(w["factionId"], w["targetId"]) != key)
	_log_truce(party_a, party_b, "signedPair", "signedPlayer")
	if party_a != Shares.PLAYER and party_b != Shares.PLAYER:
		Barometer.push_headline(_tcfg()["headlines"]["signed"] % [_party_name(party_a), _party_name(party_b)])
	EventBus.state_changed.emit()


# breaker moved against its truce partner: the truce ends and every faction
# thinks less of the breaker.
static func break_truce(breaker: String, victim: String) -> void:
	truces().erase(find_truce(breaker, victim))
	var penalty := -int(_tcfg()["breakPenalty"])
	var log_cfg: Dictionary = _tcfg()["log"]
	if breaker == Shares.PLAYER:
		for faction_id in GameData.FACTIONS.keys():
			Factions.adjust_player_relation(faction_id, penalty)
		log_activity(victim, log_cfg["brokenByPlayer"])
	else:
		for faction_id in GameData.FACTIONS.keys():
			Factions.adjust_relation(breaker, faction_id, penalty)
		if victim == Shares.PLAYER:
			log_activity(breaker, log_cfg["brokeWithPlayer"])
		else:
			log_activity(breaker, log_cfg["brokePair"] % _party_name(victim))
			log_activity(victim, log_cfg["brokenByPair"] % _party_name(breaker))
	EventBus.state_changed.emit()


# Truces past their endDay lapse; the rest add their daily bonus.
static func _update_truces(day: int) -> void:
	for truce in truces().duplicate():
		var a: String = truce["parties"][0]
		var b: String = truce["parties"][1]
		if day >= int(truce["endDay"]):
			truces().erase(truce)
			_log_truce(a, b, "endedPair", "endedPlayer")
		else:
			_adjust_between(a, b, int(truce["dailyBonus"]))


# The £ value of a proposal to party: truce days at truceDayValue scaled by
# its weariness, plus cash and veins in minus cash and veins out (weekly
# cash over the truce's weeks, veins at Factions.vein_value). A proposal is
# { truceDays, cash: [ { from, to, amount } ], weekly: [ { from, to,
# amount } ], veins: [ { from, to, vein or veinId } ] }.
static func score_proposal(party: String, proposal: Dictionary, party_weariness: float) -> float:
	var days := int(proposal.get("truceDays", _tcfg()["defaultDays"]))
	var score := float(days) * float(_ncfg()["truceDayValue"]) * party_weariness / 100.0
	var weeks := ceili(days / 7.0)
	for line in proposal.get("cash", []):
		score += _signed(party, line) * float(line["amount"])
	for line in proposal.get("weekly", []):
		score += _signed(party, line) * float(line["amount"]) * weeks
	for line in proposal.get("veins", []):
		var vein: Variant = line["vein"] if line.has("vein") else _vein_by_id(line["veinId"])
		if vein != null:
			score += _signed(party, line) * Factions.vein_value(vein)
	return score


# A player vein or a faction's site vein by id, or null.
static func _vein_by_id(vein_id: String) -> Variant:
	var vein: Variant = Cultivating.find_vein(vein_id)
	if vein != null:
		return vein
	for site in GameState.state["world"]["sites"]:
		var faction_vein: Variant = site.get("factionVein")
		if faction_vein != null and faction_vein["id"] == vein_id:
			return faction_vein
	return null


static func _signed(party: String, line: Dictionary) -> float:
	if line["to"] == party:
		return 1.0
	return -1.0 if line["from"] == party else 0.0


# The £ a proposal must score to be accepted: barMax at no weariness,
# falling linearly to 0 at 100.
static func acceptance_bar(party_weariness: float) -> float:
	return float(_ncfg()["barMax"]) * (1.0 - clampf(party_weariness, 0.0, 100.0) / 100.0)


static func accepts(party: String, proposal: Dictionary, party_weariness: float) -> bool:
	return score_proposal(party, proposal, party_weariness) >= acceptance_bar(party_weariness)


# Faction–faction peace: in each faction war, a side at its offerPeace
# (the wearier first) offers the other, once at its acceptPeace, a truce of
# defaultDays plus the one-off cash (up to maxPayShare of its resources)
# that lifts the offer to the other's bar. Both sides must accept.
static func _make_faction_peace() -> void:
	for war in wars().duplicate():
		var a: String = war["parties"][0]
		var b: String = war["parties"][1]
		if a == Shares.PLAYER or b == Shares.PLAYER:
			continue
		var sides := [a, b] if float(war["weariness"].get(a, 0.0)) >= float(war["weariness"].get(b, 0.0)) else [b, a]
		for i in 2:
			if _offer_peace(war, sides[i], sides[1 - i]):
				break


static func _offer_peace(war: Dictionary, offerer: String, other: String) -> bool:
	var w_offer := float(war["weariness"].get(offerer, 0.0))
	var w_other := float(war["weariness"].get(other, 0.0))
	if w_offer < offer_peace_at(offerer) or w_other < accept_peace_at(other):
		return false
	var terms := _auto_terms(offerer, other, w_other)
	if terms.is_empty() or not accepts(offerer, terms, w_offer):
		return false
	for line in terms["cash"]:
		GameState.state["factions"][line["from"]]["resources"] -= int(line["amount"])
		GameState.state["factions"][line["to"]]["resources"] += int(line["amount"])
	sign_truce(offerer, other, terms)
	return true


# Default truce days, plus a one-off payment from offerer when the bare
# truce falls short of the other side's bar; {} when offerer can't cover it.
static func _auto_terms(offerer: String, other: String, w_other: float) -> Dictionary:
	var terms := { "truceDays": int(_tcfg()["defaultDays"]), "cash": [], "weekly": [], "veins": [] }
	var short := ceili(acceptance_bar(w_other) - score_proposal(other, terms, w_other))
	if short <= 0:
		return terms
	var budget := floori(float(GameState.state["factions"][offerer]["resources"]) * float(_ncfg()["maxPayShare"]))
	if short > budget:
		return {}
	terms["cash"].append({ "from": offerer, "to": other, "amount": short })
	return terms


# ── Player negotiation ──────────────────────────────────────────────────
# R§3.1 "Negotiation": the player talks peace with one faction at a time.
# A faction at its offerPeace sends an actionable peace offer; the player
# can also open talks with any enemy. Each round the player proposes terms
# and the faction accepts or counters with the nearest acceptable tweak,
# for at most maxRounds. Failed or abandoned talks cost failRelation and
# close talks with that faction for cooldownDays. Talks that open from an
# offer while the player is at extreme weariness bind: no walking away.
# Data in constants.json factionWar.negotiation.

const PEACE_OFFER_KIND := "faction_peace_offer"
const TERM_TRUCE_DAYS := "truceDays"
const TERM_CASH_TO_FACTION := "cashToFaction"
const TERM_CASH_TO_PLAYER := "cashToPlayer"
const TERM_WEEKLY_TO_FACTION := "weeklyToFaction"
const TERM_WEEKLY_TO_PLAYER := "weeklyToPlayer"
const TERM_VEINS_TO_FACTION := "veinsToFaction"
const TERM_VEINS_TO_PLAYER := "veinsToPlayer"


# The talks in progress: {} or { factionId, round, binding, final, draft:
# terms, counter: terms or {} }. final: a binding talk past its last round,
# where only the faction's counter can be signed.
static func negotiation() -> Dictionary:
	return _war()["negotiation"]


# Terms: { truceDays, cashToFaction, cashToPlayer, weeklyToFaction,
# weeklyToPlayer, veinsToFaction: [veinId], veinsToPlayer: [veinId] }.
static func default_terms() -> Dictionary:
	return {
		TERM_TRUCE_DAYS: int(_tcfg()["defaultDays"]),
		TERM_CASH_TO_FACTION: 0, TERM_CASH_TO_PLAYER: 0,
		TERM_WEEKLY_TO_FACTION: 0, TERM_WEEKLY_TO_PLAYER: 0,
		TERM_VEINS_TO_FACTION: [], TERM_VEINS_TO_PLAYER: [],
	}


static func _day() -> int:
	return int(GameState.state["world"]["day"])


static func peace_cooling(faction_id: String) -> bool:
	return _day() < int(_war()["peaceCooldown"].get(faction_id, 0))


# The faction's weariness in its war with the player, else its own.
static func _talks_weariness(faction_id: String) -> float:
	var war := _find_war(war_key(Shares.PLAYER, faction_id))
	if not war.is_empty():
		return float(war["weariness"].get(faction_id, 0.0))
	return weariness(faction_id)


# Terms in score_proposal's shape, between the player and faction_id.
static func _proposal(faction_id: String, terms: Dictionary) -> Dictionary:
	var proposal := { "truceDays": int(terms[TERM_TRUCE_DAYS]), "cash": [], "weekly": [], "veins": [] }
	var sides := [[TERM_CASH_TO_FACTION, "cash", Shares.PLAYER, faction_id], [TERM_CASH_TO_PLAYER, "cash", faction_id, Shares.PLAYER],
		[TERM_WEEKLY_TO_FACTION, "weekly", Shares.PLAYER, faction_id], [TERM_WEEKLY_TO_PLAYER, "weekly", faction_id, Shares.PLAYER]]
	for side in sides:
		if int(terms[side[0]]) > 0:
			proposal[side[1]].append({ "from": side[2], "to": side[3], "amount": int(terms[side[0]]) })
	for vein_id in terms[TERM_VEINS_TO_FACTION]:
		proposal["veins"].append({ "from": Shares.PLAYER, "to": faction_id, "veinId": vein_id })
	for vein_id in terms[TERM_VEINS_TO_PLAYER]:
		proposal["veins"].append({ "from": faction_id, "to": Shares.PLAYER, "veinId": vein_id })
	return proposal


# Player veins that can change hands in a truce: on a site, not quest-
# locked, not under a queued raid or awaiting a defend.
static func player_tradeable_veins() -> Array:
	return GameState.state["player"]["veins"].filter(func(v: Dictionary) -> bool:
		return v.get("siteId") != null and not Collective.is_quest_locked_vein(v["id"]) and not _raid_queued(v["id"]) and not Raiding.has_pending_defend(v["id"]))


# faction_id's site veins that can change hands in a truce.
static func faction_tradeable_veins(faction_id: String) -> Array:
	var veins := []
	for site in Sites.sites_with_faction_vein(faction_id):
		if not Collective.is_quest_locked_vein(site["factionVein"]["id"]) and not _raid_queued(site["factionVein"]["id"]):
			veins.append(site["factionVein"])
	return veins


static func _ids(veins: Array) -> Array:
	return veins.map(func(v: Dictionary) -> String: return v["id"])


# { ok } when both sides can pay the one-off cash and still hold the veins.
static func _terms_payable(faction_id: String, terms: Dictionary) -> Dictionary:
	if int(GameState.state["player"]["cash"]) < int(terms[TERM_CASH_TO_FACTION]):
		return { "ok": false, "reason": "You can't cover £%d." % int(terms[TERM_CASH_TO_FACTION]) }
	if int(GameState.state["factions"][faction_id]["resources"]) < int(terms[TERM_CASH_TO_PLAYER]):
		return { "ok": false, "reason": "They can't pay that much." }
	var mine := _ids(player_tradeable_veins())
	for vein_id in terms[TERM_VEINS_TO_FACTION]:
		if not mine.has(vein_id):
			return { "ok": false, "reason": "That vein isn't yours to give." }
	var theirs := _ids(faction_tradeable_veins(faction_id))
	for vein_id in terms[TERM_VEINS_TO_PLAYER]:
		if not theirs.has(vein_id):
			return { "ok": false, "reason": "That vein isn't theirs to give." }
	return { "ok": true }


# The nearest terms to these that faction_id accepts and both sides can
# pay: veins not tradeable now drop, one-off cash is capped at what each
# side holds, then any shortfall comes off cash to the player, then weekly
# cash to the player, then goes on as one-off cash from the player (up to
# the player's cash), and the rest as weekly cash from the player.
static func _counter_terms(faction_id: String, terms: Dictionary, faction_weariness: float) -> Dictionary:
	var counter: Dictionary = GameState.deep_copy(terms)
	var mine := _ids(player_tradeable_veins())
	var theirs := _ids(faction_tradeable_veins(faction_id))
	counter[TERM_VEINS_TO_FACTION] = counter[TERM_VEINS_TO_FACTION].filter(func(id: String) -> bool: return mine.has(id))
	counter[TERM_VEINS_TO_PLAYER] = counter[TERM_VEINS_TO_PLAYER].filter(func(id: String) -> bool: return theirs.has(id))
	var cash := int(GameState.state["player"]["cash"])
	counter[TERM_CASH_TO_FACTION] = mini(int(counter[TERM_CASH_TO_FACTION]), cash)
	counter[TERM_CASH_TO_PLAYER] = mini(int(counter[TERM_CASH_TO_PLAYER]), int(GameState.state["factions"][faction_id]["resources"]))
	var short := ceili(acceptance_bar(faction_weariness) - score_proposal(faction_id, _proposal(faction_id, counter), faction_weariness))
	if short <= 0:
		return counter
	var weeks := ceili(int(counter[TERM_TRUCE_DAYS]) / 7.0)
	var cut := mini(short, int(counter[TERM_CASH_TO_PLAYER]))
	counter[TERM_CASH_TO_PLAYER] -= cut
	short -= cut
	if short > 0:
		var cut_weekly := mini(ceili(float(short) / weeks), int(counter[TERM_WEEKLY_TO_PLAYER]))
		counter[TERM_WEEKLY_TO_PLAYER] -= cut_weekly
		short -= cut_weekly * weeks
	if short > 0:
		var add := mini(short, maxi(0, cash - int(counter[TERM_CASH_TO_FACTION])))
		counter[TERM_CASH_TO_FACTION] += add
		short -= add
	if short > 0:
		counter[TERM_WEEKLY_TO_FACTION] += ceili(float(short) / weeks)
	return counter


static func _new_talks(faction_id: String, binding: bool, draft: Dictionary, counter: Dictionary) -> void:
	_war()["negotiation"] = {
		"factionId": faction_id, "round": 1, "binding": binding, "final": false,
		"draft": draft, "counter": counter,
	}
	EventBus.state_changed.emit()


# { ok } when the player may open talks with faction_id now.
static func can_open_talks(faction_id: String) -> Dictionary:
	if not negotiation().is_empty():
		return { "ok": false, "reason": "Finish the talks you're in first." }
	if not at_war(Shares.PLAYER, faction_id):
		return { "ok": false, "reason": "You're not at war with them." }
	if peace_cooling(faction_id):
		return { "ok": false, "reason": "They won't talk again yet." }
	return { "ok": true }


# The player opens talks through the key member. A pending peace offer
# from the same faction is taken up instead, so a binding one still binds.
static func open_talks(faction_id: String) -> Dictionary:
	var offer := _peace_offer_from(faction_id)
	if not offer.is_empty():
		return answer_peace_offer(offer["id"], true)
	var check := can_open_talks(faction_id)
	if check["ok"]:
		_new_talks(faction_id, false, default_terms(), {})
	return check


static func _peace_offer_from(faction_id: String) -> Dictionary:
	for entry in GameState.state["pendingMessages"]:
		if entry["kind"] == PEACE_OFFER_KIND and entry["payload"].get("factionId", "") == faction_id:
			return entry
	return {}


static func _find_peace_offer(pending_id: String) -> Dictionary:
	for entry in GameState.state["pendingMessages"]:
		if entry["id"] == pending_id and entry["kind"] == PEACE_OFFER_KIND:
			return entry
	return {}


# An offer binds if it was sent, or is answered, while the player is at
# extreme weariness.
static func peace_offer_binding(entry: Dictionary) -> bool:
	return bool(entry["payload"].get("binding", false)) or player_extreme()


# Accepting opens talks on the faction's opening terms (a truce of
# defaultDays, plus whatever it needs to reach its bar). Declining counts
# as walking away, and a binding offer can't be declined.
static func answer_peace_offer(pending_id: String, accept: bool) -> Dictionary:
	var entry := _find_peace_offer(pending_id)
	if entry.is_empty():
		return { "ok": false, "reason": "Offer not found." }
	var faction_id: String = entry["payload"]["factionId"]
	var binding := peace_offer_binding(entry)
	if not accept:
		if binding:
			return { "ok": false, "reason": "You can't walk away from this one." }
		Messages.resolve_pending(pending_id)
		_fail_talks(faction_id, "abandoned")
		return { "ok": true }
	if not negotiation().is_empty():
		return { "ok": false, "reason": "Finish the talks you're in first." }
	Messages.resolve_pending(pending_id)
	var opening := _counter_terms(faction_id, default_terms(), _talks_weariness(faction_id))
	_new_talks(faction_id, binding, GameState.deep_copy(opening), opening)
	return { "ok": true }


# Sets one draft term: truce days clamp to the allowed range, cash terms
# floor at 0.
static func set_draft_term(key: String, value: int) -> void:
	var talks := negotiation()
	if talks.is_empty() or talks["final"]:
		return
	if key == TERM_TRUCE_DAYS:
		var days: Dictionary = _ncfg()["truceDays"]
		value = clampi(value, int(days["min"]), int(days["max"]))
	else:
		value = maxi(0, value)
	talks["draft"][key] = value
	EventBus.state_changed.emit()


# Adds the vein to (or takes it off) the draft's veinsToFaction or
# veinsToPlayer list.
static func toggle_draft_vein(key: String, vein_id: String) -> void:
	var talks := negotiation()
	if talks.is_empty() or talks["final"]:
		return
	var ids: Array = talks["draft"][key]
	if ids.has(vein_id):
		ids.erase(vein_id)
	else:
		ids.append(vein_id)
	EventBus.state_changed.emit()


# The player puts the draft to the faction. Returns { ok, result } with
# result accepted (signed), countered, final (a binding talk's last
# counter), refused (the faction is under its acceptPeace) or failed (out
# of rounds); { ok: false, reason } when the draft can't be paid.
static func propose_terms() -> Dictionary:
	var talks := negotiation()
	if talks.is_empty():
		return { "ok": false, "reason": "No talks open." }
	if talks["final"]:
		return { "ok": false, "reason": "That was their last word." }
	var faction_id: String = talks["factionId"]
	var draft: Dictionary = talks["draft"]
	var check := _terms_payable(faction_id, draft)
	if not check["ok"]:
		return check
	var w := _talks_weariness(faction_id)
	if not talks["binding"] and w < accept_peace_at(faction_id):
		_fail_talks(faction_id, "refused")
		return { "ok": true, "result": "refused" }
	if accepts(faction_id, _proposal(faction_id, draft), w):
		_sign_talks(faction_id, draft)
		return { "ok": true, "result": "accepted" }
	talks["counter"] = _counter_terms(faction_id, draft, w)
	if int(talks["round"]) < int(_ncfg()["maxRounds"]):
		talks["round"] = int(talks["round"]) + 1
		EventBus.state_changed.emit()
		return { "ok": true, "result": "countered" }
	if talks["binding"]:
		talks["final"] = true
		EventBus.state_changed.emit()
		return { "ok": true, "result": "final" }
	_fail_talks(faction_id, "failed")
	return { "ok": true, "result": "failed" }


# The player signs the faction's standing counter. If it can't be paid
# now or falls short of the faction's bar, the faction revises it.
static func accept_counter() -> Dictionary:
	var talks := negotiation()
	if talks.is_empty() or talks["counter"].is_empty():
		return { "ok": false, "reason": "Nothing to accept." }
	var faction_id: String = talks["factionId"]
	var counter: Dictionary = talks["counter"]
	var w := _talks_weariness(faction_id)
	if not _terms_payable(faction_id, counter)["ok"] or not accepts(faction_id, _proposal(faction_id, counter), w):
		talks["counter"] = _counter_terms(faction_id, counter, w)
		EventBus.state_changed.emit()
		return { "ok": false, "reason": "Things have changed. They've revised their terms." }
	_sign_talks(faction_id, counter)
	return { "ok": true }


static func abandon_talks() -> Dictionary:
	var talks := negotiation()
	if talks.is_empty():
		return { "ok": false, "reason": "No talks open." }
	if talks["binding"]:
		return { "ok": false, "reason": "You can't walk away from this one." }
	_fail_talks(talks["factionId"], "abandoned")
	return { "ok": true }


# Talks end without a deal: a little relation lost, talks closed for
# cooldownDays, the key member's line for why.
static func _fail_talks(faction_id: String, line_key: String) -> void:
	var cfg := _ncfg()
	if negotiation().get("factionId", "") == faction_id:
		_war()["negotiation"] = {}
	_war()["peaceCooldown"][faction_id] = _day() + int(cfg["cooldownDays"])
	Factions.adjust_player_relation(faction_id, -int(cfg["failRelation"]))
	log_activity(faction_id, cfg["log"]["failed"])
	KeyMembers.send(faction_id, cfg["lines"][line_key])
	EventBus.state_changed.emit()


# One-off cash and veins change hands now, then the truce is signed with
# the weekly cash as its terms.
static func _sign_talks(faction_id: String, terms: Dictionary) -> void:
	var faction: Dictionary = GameState.state["factions"][faction_id]
	var player: Dictionary = GameState.state["player"]
	var faction_name := _party_name(faction_id)
	var paid := int(terms[TERM_CASH_TO_FACTION])
	var received := int(terms[TERM_CASH_TO_PLAYER])
	if paid > 0:
		player["cash"] -= paid
		faction["resources"] += paid
		Bank.record(-paid, "Truce terms: %s" % faction_name)
	if received > 0:
		faction["resources"] -= received
		player["cash"] += received
		Bank.record(received, "Truce terms: %s" % faction_name)
	for vein_id in terms[TERM_VEINS_TO_FACTION]:
		VeinTrade.transfer_to_faction(vein_id, faction_id, 0, false)
	for vein_id in terms[TERM_VEINS_TO_PLAYER]:
		VeinTrade.transfer_from_faction(vein_id, faction_id)
	_war()["negotiation"] = {}
	var proposal := _proposal(faction_id, terms)
	sign_truce(Shares.PLAYER, faction_id, { "truceDays": proposal["truceDays"], "weekly": proposal["weekly"] })
	KeyMembers.send(faction_id, _ncfg()["lines"]["accepted"])


# Rollover (after faction–faction peace): a faction at its offerPeace in
# its war with the player sends a peace offer, unless one is pending, talks
# are open or cooling with it, or it has no offer line. Offers from
# factions not at war with the player are withdrawn.
static func _offer_player_peace() -> void:
	GameState.state["pendingMessages"] = GameState.state["pendingMessages"].filter(func(e: Dictionary) -> bool:
		return e["kind"] != PEACE_OFFER_KIND or at_war(Shares.PLAYER, e["payload"].get("factionId", "")))
	var lines: Dictionary = _ncfg()["offerLines"]
	for war in wars_of(Shares.PLAYER):
		var faction_id := war_enemy(war, Shares.PLAYER)
		if float(war["weariness"].get(faction_id, 0.0)) < offer_peace_at(faction_id) or not lines.has(faction_id):
			continue
		if negotiation().get("factionId", "") == faction_id or not _peace_offer_from(faction_id).is_empty() or peace_cooling(faction_id):
			continue
		KeyMembers.send(faction_id, lines[faction_id], PEACE_OFFER_KIND, { "factionId": faction_id, "binding": player_extreme() })


# Monday rollover: every truce's weekly cash is paid, each payer paying
# what it can. The player is told what went out and came in.
static func settle_truce_payments() -> void:
	if not Calendar.is_monday(_day()):
		return
	for truce in truces():
		for line in truce["weekly"]:
			_pay_weekly(line["from"], line["to"], int(line["amount"]))


static func _pay_weekly(from: String, to: String, amount: int) -> void:
	var cfg: Dictionary = _ncfg()["paymentNotify"]
	if from == Shares.PLAYER:
		var paid := mini(amount, int(GameState.state["player"]["cash"]))
		GameState.state["player"]["cash"] -= paid
		GameState.state["factions"][to]["resources"] += paid
		if paid > 0:
			Bank.record(-paid, "Truce payment: %s" % _party_name(to))
		if paid < amount:
			Notify.push(cfg["short"] % [_party_name(to), paid, amount], Notify.CATEGORY_WARNING)
		else:
			Notify.push(cfg["paid"] % [_party_name(to), paid])
		return
	var faction: Dictionary = GameState.state["factions"][from]
	var sent := mini(amount, int(faction["resources"]))
	faction["resources"] -= sent
	if to == Shares.PLAYER:
		GameState.state["player"]["cash"] += sent
		if sent > 0:
			Bank.record(sent, "Truce payment: %s" % _party_name(from))
			Notify.push(cfg["received"] % [_party_name(from), sent], Notify.CATEGORY_SUCCESS)
	else:
		GameState.state["factions"][to]["resources"] += sent


# ── Conclave stabiliser ─────────────────────────────────────────────────
# R§3.1 "Conclave stabiliser": a good quoted beyond ±bandPct of its base
# price for runDays straight rollovers gets a Conclave counter-trade at a
# loss -- selling into the spike from its stockpile, buying the crash into
# it -- and its run restarts. A daily top-up then buys each good quoted at
# or under maxPriceMult × base toward its stockpile target.
# Data in constants.json factionConclave.stabiliser.

static func _scfg() -> Dictionary:
	return GameData.FACTION_CONCLAVE["stabiliser"]


# state.factionConclave: { runs: { "kind:type": days }, stockpile:
# { "kind:type": units }, squeezed: { party: day last war-squeezed },
# positions: [{ section, state, ore, units, openedDay, pushed }],
# lastPushDay: day of the last Ticker push (-1 for none) }.
# Run days signed: +n for n straight days above the band, -n below; a good
# inside it has no key. Stockpile and position units sit in the Conclave's
# holdings, kept off sale (FactionSim.for_sale); a good with none has no key.
static func new_conclave_state() -> Dictionary:
	return { "runs": {}, "stockpile": {}, "squeezed": {}, "positions": [], "lastPushDay": -1 }


static func stabiliser_run(kind: String, good_type: String) -> int:
	return int(GameState.state["factionConclave"]["runs"].get(kind + ":" + good_type, 0))


# The stabiliser faction's stockpile of a good, never more than it holds
# (holdings spent elsewhere shrink it); 0 for any other faction.
static func stockpile_held(faction_id: String, kind: String, good_type: String) -> int:
	if faction_id != _scfg()["factionId"]:
		return 0
	var units: int = int(GameState.state["factionConclave"]["stockpile"].get(kind + ":" + good_type, 0))
	return mini(units, FactionSim.held(faction_id, kind, good_type))


static func _set_stockpile(kind: String, good_type: String, units: int) -> void:
	var stockpile: Dictionary = GameState.state["factionConclave"]["stockpile"]
	if units > 0:
		stockpile[kind + ":" + good_type] = units
	else:
		stockpile.erase(kind + ":" + good_type)


# Adds delta units (negative to take) to a good's stockpile.
static func _shift_stockpile(conclave_id: String, kind: String, good_type: String, delta: int) -> void:
	_set_stockpile(kind, good_type, stockpile_held(conclave_id, kind, good_type) + delta)


static func stabilise() -> void:
	if not Market.is_running():
		return
	var cfg := _scfg()
	var conclave_id: String = cfg["factionId"]
	var band_pct: float = float(cfg["bandPct"])
	var run_days: int = int(cfg["runDays"])
	var runs: Dictionary = GameState.state["factionConclave"]["runs"]
	for kind in Market.KINDS:
		for good_type in GameData.MARKET["goods"][kind]:
			var key: String = kind + ":" + good_type
			var base: int = Market.base_price(kind, good_type)
			var price: int = Market.quote(kind, good_type)
			var side := 0
			if base > 0 and price > base * (1.0 + band_pct):
				side = 1
			elif base > 0 and price < base * (1.0 - band_pct):
				side = -1
			if side == 0:
				runs.erase(key)
				continue
			var run: int = int(runs.get(key, 0))
			run = run + side if signi(run) == side else side
			if absi(run) < run_days:
				runs[key] = run
				continue
			runs.erase(key)
			var qty: int = int(cfg["qty"][kind])
			if side > 0:
				qty = mini(qty, stockpile_held(conclave_id, kind, good_type))
				_shift_stockpile(conclave_id, kind, good_type, -FactionSim.stabilise_sell(conclave_id, kind, good_type, qty, float(cfg["sellMult"])))
			else:
				_shift_stockpile(conclave_id, kind, good_type, FactionSim.stabilise_buy(conclave_id, kind, good_type, qty, float(cfg["buyMult"])))
	_top_up_stockpile()


# Per good quoted at or under topUp.maxPriceMult × base: buys toward its
# stockpile target, at most topUp.dailyCap[kind] a day, spending only cash
# above topUp.cashFloor.
static func _top_up_stockpile() -> void:
	var cfg: Dictionary = _scfg()["stockpile"]
	var top_up: Dictionary = cfg["topUp"]
	var conclave_id: String = _scfg()["factionId"]
	var faction: Dictionary = GameState.state["factions"][conclave_id]
	for kind in Market.KINDS:
		for good_type in GameData.MARKET["goods"][kind]:
			var base: int = Market.base_price(kind, good_type)
			var price: int = Market.quote(kind, good_type)
			if base <= 0 or price <= 0 or price > base * float(top_up["maxPriceMult"]):
				continue
			var want: int = mini(int(cfg["target"][kind]) - stockpile_held(conclave_id, kind, good_type), int(top_up["dailyCap"][kind]))
			if want <= 0:
				continue
			var budget: int = int(faction["resources"]) - int(top_up["cashFloor"])
			_shift_stockpile(conclave_id, kind, good_type, FactionSim.stock_up(conclave_id, kind, good_type, want, budget))


# ── Conclave war squeeze ────────────────────────────────────────────────
# R§3.1 "Conclave war squeeze": once a war is minWarDays old, the Conclave
# denies each side goods it needs and undercuts its sales, at qty × the
# side's intensity. Intensity = its war weariness / 100, except when one
# side is at wearyAt or more and the other sits gap or more below it: the
# fresher side is squeezed at the weary side's weariness × dominantMult and
# the weary side at × weakMult, so the squeeze never helps finish it off.
# The squeeze never brokers peace between the sides. Data in
# constants.json factionConclave.squeeze.

static func _sqcfg() -> Dictionary:
	return GameData.FACTION_CONCLAVE["squeeze"]


# Each party's squeeze intensity in one war: { party: float }.
static func squeeze_intensity(war: Dictionary) -> Dictionary:
	var cfg: Dictionary = _sqcfg()["dominance"]
	var a: String = war["parties"][0]
	var b: String = war["parties"][1]
	var w_a := float(war["weariness"].get(a, 0.0))
	var w_b := float(war["weariness"].get(b, 0.0))
	var weary_at := float(cfg["wearyAt"])
	var gap := float(cfg["gap"])
	if w_a >= weary_at and w_b <= w_a - gap:
		return { a: w_a / 100.0 * float(cfg["weakMult"]), b: w_a / 100.0 * float(cfg["dominantMult"]) }
	if w_b >= weary_at and w_a <= w_b - gap:
		return { a: w_b / 100.0 * float(cfg["dominantMult"]), b: w_b / 100.0 * float(cfg["weakMult"]) }
	return { a: w_a / 100.0, b: w_b / 100.0 }


# Rollover step: per party at war, its highest intensity across wars that
# have run minWarDays and that the Conclave isn't fighting; off cooldown and
# not in truce with the Conclave, it gets a scaled deny then undercut.
static func squeeze_wars() -> void:
	if not Market.is_running():
		return
	var conclave_id: String = _scfg()["factionId"]
	var day: int = GameState.state["world"]["day"]
	var intensity := {}
	for war in wars():
		if war["parties"].has(conclave_id) or day - int(war["startDay"]) < int(_sqcfg()["minWarDays"]):
			continue
		var by_party := squeeze_intensity(war)
		for party in by_party:
			intensity[party] = maxf(float(intensity.get(party, 0.0)), float(by_party[party]))
	var squeezed: Dictionary = GameState.state["factionConclave"]["squeezed"]
	for party in intensity:
		var last: int = int(squeezed.get(party, -1))
		if float(intensity[party]) <= 0.0 or moves_blocked(conclave_id, party):
			continue
		if last >= 0 and day - last < int(_sqcfg()["cooldownDays"]):
			continue
		squeezed[party] = day
		_squeeze(conclave_id, party, float(intensity[party]))
	EventBus.state_changed.emit()


static func _squeeze(conclave_id: String, party: String, intensity: float) -> void:
	var deny := _deny_candidate(conclave_id, party)
	if not deny.is_empty():
		var resources := int(GameState.state["factions"][conclave_id]["resources"])
		var price := Market.quote(deny["kind"], deny["good"])
		deny["qty"] = mini(roundi(float(_ecfg()["deny"]["qty"][deny["kind"]]) * intensity), Market.affordable_qty(deny["kind"], price, resources))
		if int(deny["qty"]) > 0:
			_make_move(conclave_id, party, deny)
	var undercut := _undercut_candidate(conclave_id, party)
	if not undercut.is_empty():
		undercut["qty"] = mini(roundi(float(_ecfg()["undercut"]["qty"][undercut["kind"]]) * intensity), FactionSim.for_sale(conclave_id, undercut["kind"], undercut["good"]))
		if int(undercut["qty"]) > 0:
			_make_move(conclave_id, party, undercut)


# ── Conclave positions and Ticker push ──────────────────────────────────
# R§3.1 "Conclave positions": with fewer than maxOpen positions, the Conclave
# picks the non-active Ticker state with the highest progress whose
# itemDemand boosts items, and buys qty of the ore those items use most
# (itemDemand fraction × recipe qty), spending only cash above cashFloor; a
# lot of hintQty or more is a hint headline. While open, each push (one per
# pushCooldownDays, shared with the tickerPush move) queues pushStrength on
# the state via Barometer.queue_push, pushCap in all per position. A
# position closes, selling at the quote, when its state goes active or after
# maxDays. Data in constants.json factionConclave.positions.

static func _poscfg() -> Dictionary:
	return GameData.FACTION_CONCLAVE["positions"]


static func positions() -> Array:
	return GameState.state["factionConclave"]["positions"]


# Units of an ore the Conclave holds in open positions, never more than it
# holds; 0 for any other faction or kind.
static func position_held(faction_id: String, kind: String, good_type: String) -> int:
	if faction_id != _scfg()["factionId"] or kind != "ore":
		return 0
	var units := 0
	for position in positions():
		if position["ore"] == good_type:
			units += int(position["units"])
	return mini(units, FactionSim.ore_held(faction_id, good_type))


static func push_cooling() -> bool:
	var last := int(GameState.state["factionConclave"]["lastPushDay"])
	return last >= 0 and int(GameState.state["world"]["day"]) - last < int(_poscfg()["pushCooldownDays"])


static func _push_ticker(faction_id: String, section: String, state_id: String, strength: int) -> void:
	Barometer.queue_push(faction_id, section, state_id, "push", strength)
	GameState.state["factionConclave"]["lastPushDay"] = int(GameState.state["world"]["day"])


# Rollover step: close, open, then push.
static func run_positions() -> void:
	if not Market.is_running():
		return
	Barometer.ensure_progress()
	_close_positions()
	_open_positions()
	if not push_cooling():
		var cap := int(_poscfg()["pushCap"])
		for position in positions():
			if int(position["pushed"]) < cap:
				var strength := mini(int(_poscfg()["pushStrength"]), cap - int(position["pushed"]))
				position["pushed"] = int(position["pushed"]) + strength
				_push_ticker(_scfg()["factionId"], position["section"], position["state"], strength)
				break
	EventBus.state_changed.emit()


static func _close_positions() -> void:
	var conclave_id: String = _scfg()["factionId"]
	var day := int(GameState.state["world"]["day"])
	var kept := []
	for position in positions():
		var paid: bool = GameState.state["barometer"][position["section"]] == position["state"]
		if paid or day - int(position["openedDay"]) >= int(_poscfg()["maxDays"]):
			FactionSim.position_sell(conclave_id, position["ore"], int(position["units"]))
		else:
			kept.append(position)
	GameState.state["factionConclave"]["positions"] = kept


static func _open_positions() -> void:
	var cfg := _poscfg()
	var conclave_id: String = _scfg()["factionId"]
	while positions().size() < int(cfg["maxOpen"]):
		var pick := _position_pick()
		if pick.is_empty():
			return
		var budget := int(GameState.state["factions"][conclave_id]["resources"]) - int(cfg["cashFloor"])
		var bought := FactionSim.position_buy(conclave_id, pick["ore"], int(cfg["qty"]), budget)
		if bought <= 0:
			return
		pick["units"] = bought
		pick["openedDay"] = int(GameState.state["world"]["day"])
		pick["pushed"] = 0
		positions().append(pick)
		if bought >= int(cfg["hintQty"]):
			Barometer.push_headline(GameData.FACTION_CONCLAVE["headlines"]["position"] % GameData.ORE_TYPES[pick["ore"]]["name"])


# { section, state, ore } for the next position, or {} when no non-active
# state without a position boosts any ore's items.
static func _position_pick() -> Dictionary:
	var barometer: Dictionary = GameState.state["barometer"]
	var best := {}
	var best_progress := -1
	for section in Barometer.SECTIONS:
		for state_id in GameData.BAROMETER_STATES[section]:
			if state_id == barometer[section] or _has_position(section, state_id):
				continue
			var ore := _paying_ore(GameData.BAROMETER_STATES[section][state_id]["effects"])
			var progress := int(barometer["progress"][section].get(state_id, 0))
			if ore != "" and progress > best_progress:
				best = { "section": section, "state": state_id, "ore": ore }
				best_progress = progress
	return best


static func _has_position(section: String, state_id: String) -> bool:
	for position in positions():
		if position["section"] == section and position["state"] == state_id:
			return true
	return false


# The ore the effects' positive itemDemand leans on most, or "".
static func _paying_ore(effects: Dictionary) -> String:
	var weights := {}
	var item_demand: Dictionary = effects.get("itemDemand", {})
	for recipe_key in item_demand:
		var fraction := float(item_demand[recipe_key])
		if fraction <= 0.0:
			continue
		var ingredients: Dictionary = GameData.RECIPES[recipe_key]["ingredients"]
		for ore_type in ingredients:
			weights[ore_type] = float(weights.get(ore_type, 0.0)) + fraction * float(ingredients[ore_type])
	var best := ""
	for ore_type in GameData.CANONICAL_ORE_TYPES:
		if float(weights.get(ore_type, 0.0)) > float(weights.get(best, 0.0)):
			best = ore_type
	return best


# Ticker push (no cash beyond moveCosts.tickerPush; off while pushes cool):
# the non-active Ticker state that most cuts demand for the consumables the
# target sold over the past week. Damage = Σ that lot's value at the quote ×
# the cut, × pushStrength / 100 (one push's share of a flip).
static func _ticker_push_candidate(_observer: String, target: String) -> Dictionary:
	if not Market.is_running() or push_cooling():
		return {}
	var sold := Market.sold_this_week(target)
	var best := {}
	for section in Barometer.SECTIONS:
		for state_id in GameData.BAROMETER_STATES[section]:
			if state_id == GameState.state["barometer"][section]:
				continue
			var effects: Dictionary = GameData.BAROMETER_STATES[section][state_id]["effects"]
			var damage := 0.0
			for key in sold:
				var parts: PackedStringArray = key.split(":")
				if parts[0] != "consumable":
					continue
				var cut := 1.0 - (1.0 + float(effects.get("demandAll", 0.0))) * (1.0 + float(effects.get("itemDemand", {}).get(parts[1], 0.0)))
				if cut > 0.0:
					damage += cut * Market.line_total("consumable", Market.quote("consumable", parts[1]), int(sold[key]))
			damage *= float(_poscfg()["pushStrength"]) / 100.0
			if damage > 0.0 and (best.is_empty() or damage > float(best["damage"])):
				best = { "move": MOVE_TICKER_PUSH, "damage": damage, "cost": _move_cost(MOVE_TICKER_PUSH), "section": section, "state": state_id }
	return best

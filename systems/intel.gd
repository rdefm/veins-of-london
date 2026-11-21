class_name Intel
extends RefCounted

# Intel meters (R§3.1 "Intel"): what each actor knows about each other actor,
# 0..max per observer -> target pair, the player (Shares.PLAYER) and every
# faction on both sides. Levels unlock in constants.json `intel.levels`
# order as the meter reaches each `at`. Scouting and raiding a target raise
# the meter; it decays daily; a stockpile relocation drops every observer
# below the stockpile-location level.

const VEIN_SECURITY := "veinSecurity"
const HOLDINGS := "holdings"
const STOCKPILE_LOCATION := "stockpileLocation"
const STOCKPILE_SECURITY := "stockpileSecurity"
const STASH := "stash"

# Vein security fact ids (security_facts / security_read).
const FACT_ALARMS := "alarms"
const FACT_GUARD_COUNT := "guardCount"
const FACT_GUARD_STRENGTH := "guardStrength"
const FACT_GUARD_KIT := "guardKit"
const FACT_WARD := "ward"
const SECURITY_FACTS: Array[String] = [FACT_ALARMS, FACT_GUARD_COUNT, FACT_GUARD_STRENGTH, FACT_GUARD_KIT, FACT_WARD]

const SOURCE_SCOUT := "scout"
const SOURCE_RAID := "raid"
const SOURCE_FAVOUR := "favour"


static func _cfg() -> Dictionary:
	return GameData.INTEL


static func actors() -> Array:
	var ids: Array = [Shares.PLAYER]
	ids.append_array(GameData.FACTIONS.keys())
	return ids


# state.intel: { observer: { target: int } }, every actor on every other, at 0.
static func new_state() -> Dictionary:
	var meters := {}
	for observer in actors():
		var row := {}
		for target in actors():
			if target != observer:
				row[target] = 0
		meters[observer] = row
	return meters


static func meter(observer: String, target: String) -> int:
	return int(GameState.state["intel"].get(observer, {}).get(target, 0))


static func _set_meter(observer: String, target: String, value: int) -> void:
	var row: Dictionary = GameState.state["intel"].get(observer, {})
	if not row.has(target):
		return
	row[target] = clampi(value, 0, int(_cfg()["max"]))


static func raise(observer: String, target: String, amount: int) -> void:
	_set_meter(observer, target, meter(observer, target) + amount)


# Raises observer's meter on target by the constants.json gain for source
# (SOURCE_SCOUT / SOURCE_RAID).
static func gain(observer: String, target: String, source: String) -> void:
	raise(observer, target, int(_cfg()["gain"][source]))


# The meter a level id unlocks at.
static func level_at(level_id: String) -> int:
	for level in _cfg()["levels"]:
		if level["id"] == level_id:
			return int(level["at"])
	return int(_cfg()["max"]) + 1


static func knows(observer: String, target: String, level_id: String) -> bool:
	return meter(observer, target) >= level_at(level_id) or (level_id == VEIN_SECURITY and physics_read(observer))


# Physics Lens security read (R§1.4 Lenses): the player with a loaded Physics
# Lens at Sense >= senseGates.world reads one intel level higher on the
# vein-security track only, so knows every faction's vein security from meter
# 0. The stored meter is unchanged.
static func physics_read(observer: String) -> bool:
	return observer == Shares.PLAYER and Lenses.has("physics") and Lenses.sense_unlocked("world")


# The highest level observer has reached on target ({ id, at, name }), or {}
# below the first; at least vein security under physics_read().
static func level(observer: String, target: String) -> Dictionary:
	var reached := {}
	var value := meter(observer, target)
	for entry in _cfg()["levels"]:
		if value >= int(entry["at"]) or (entry["id"] == VEIN_SECURITY and physics_read(observer)):
			reached = entry
	return reached


# Rollover step: every meter drops by dailyDecay, floored at 0.
static func decay() -> void:
	var drop := int(_cfg()["dailyDecay"])
	for row in GameState.state["intel"].values():
		for target in row.keys():
			row[target] = maxi(0, int(row[target]) - drop)


# Moves faction_id's stockpile to a fresh pick, its guards going with it, and
# drops every observer's meter on it below the stockpile-location level.
static func relocate_stockpile(faction_id: String) -> void:
	var guards: Array = Muscle.faction_guards_at(GameState.state["factions"][faction_id]["stockpile"])
	GameState.state["factions"][faction_id]["stockpile"] = FactionSim.pick_stockpile(faction_id)
	GameState.state["factions"][faction_id]["stockpile"]["guards"] = guards
	var cap := level_at(STOCKPILE_LOCATION) - 1
	for observer in GameState.state["intel"].keys():
		if meter(observer, faction_id) > cap:
			_set_meter(observer, faction_id, cap)
	EventBus.mark_changed()


# ── Timers ──────────────────────────────────────────────────────────────
# R§3.1 "Network intel menu": privacy (the Network won't sell on the
# actor), raid warnings (the handler texts when a raid is queued on the
# actor) and disinformation (observer misreads target). Each is active
# through its untilDay inclusive.

const DISINFO_INVERTED := "inverted"
const DISINFO_OVERESTIMATE := "overestimate"


# state.intelTimers: { privacy: { actor: untilDay }, raidWarnings: { actor:
# untilDay }, disinformation: [ { observerId, targetId, mode, untilDay } ] }.
static func new_timers() -> Dictionary:
	return { "privacy": {}, "raidWarnings": {}, "disinformation": [] }


static func _timers() -> Dictionary:
	return GameState.state["intelTimers"]


static func _day() -> int:
	return int(GameState.state["world"]["day"])


# Extends a running timer by days, or starts one from today.
static func _extend(until_day: int, days: int) -> int:
	return maxi(until_day, _day()) + days


static func privacy_until(actor: String) -> int:
	return int(_timers()["privacy"].get(actor, -1))


static func privacy_active(actor: String) -> bool:
	return _day() <= privacy_until(actor)


static func set_privacy(actor: String, days: int) -> void:
	_timers()["privacy"][actor] = _extend(privacy_until(actor), days)


static func raid_warnings_until(actor: String) -> int:
	return int(_timers()["raidWarnings"].get(actor, -1))


static func raid_warnings_active(actor: String) -> bool:
	return _day() <= raid_warnings_until(actor)


static func set_raid_warnings(actor: String, days: int) -> void:
	_timers()["raidWarnings"][actor] = _extend(raid_warnings_until(actor), days)


static func _disinfo_entry(observer: String, target: String) -> Dictionary:
	for entry in _timers()["disinformation"]:
		if entry["observerId"] == observer and entry["targetId"] == target:
			return entry
	return {}


# The disinformation mode observer is under about target, or "" when none
# is active.
static func disinformation(observer: String, target: String) -> String:
	var entry := _disinfo_entry(observer, target)
	if entry.is_empty() or _day() > int(entry["untilDay"]):
		return ""
	return entry["mode"]


static func disinformation_until(observer: String, target: String) -> int:
	return int(_disinfo_entry(observer, target).get("untilDay", -1))


# Feeds observer disinformation about target for days. The same mode
# extends a running entry; a different mode replaces it from today.
static func set_disinformation(observer: String, target: String, mode: String, days: int) -> void:
	var entry := _disinfo_entry(observer, target)
	if entry.is_empty():
		entry = { "observerId": observer, "targetId": target, "mode": mode, "untilDay": -1 }
		_timers()["disinformation"].append(entry)
	var running := int(entry["untilDay"]) if entry["mode"] == mode else -1
	entry["mode"] = mode
	entry["untilDay"] = _extend(running, days)


# Rollover step: drops lapsed timers.
static func expire_timers() -> void:
	var day := _day()
	for key in ["privacy", "raidWarnings"]:
		var row: Dictionary = _timers()[key]
		for actor in row.keys():
			if int(row[actor]) < day:
				row.erase(actor)
	_timers()["disinformation"] = _timers()["disinformation"].filter(func(e: Dictionary) -> bool: return int(e["untilDay"]) >= day)


# ── Intel on raids ──────────────────────────────────────────────────────
# R§3.1 "Intel on raids": an attacker's meter on the defender adds to its
# raid odds and sharpens its target pick; disinformation distorts both.

# Flat shift to observer's raid odds on target: raid.oddsBonus × meter/max,
# or −raid.overestimatePenalty while observer overestimates target.
static func raid_odds_shift(observer: String, target: String) -> float:
	var raid: Dictionary = _cfg()["raid"]
	if disinformation(observer, target) == DISINFO_OVERESTIMATE:
		return -float(raid["overestimatePenalty"])
	return float(raid["oddsBonus"]) * float(meter(observer, target)) / float(_cfg()["max"])


# Scores options ({ chance, value, ... }) as observer sees them, writing
# "score" onto each: perceived chance × perceived value. Value blends from
# the options' mean toward the true value as the meter rises; under
# inverted disinformation the chances are mirrored, so the best-defended
# vein looks softest.
static func score_raid_options(observer: String, target: String, options: Array) -> void:
	if options.is_empty():
		return
	var sight := float(meter(observer, target)) / float(_cfg()["max"])
	var inverted := disinformation(observer, target) == DISINFO_INVERTED
	var mean := 0.0
	var low := INF
	var high := -INF
	for option in options:
		mean += float(option["value"])
		low = minf(low, float(option["chance"]))
		high = maxf(high, float(option["chance"]))
	mean /= float(options.size())
	for option in options:
		var chance := float(option["chance"])
		if inverted:
			chance = low + high - chance
		option["score"] = chance * lerpf(mean, float(option["value"]), sight)


# Raid site sheet security read for a faction vein: the rows of
# security_read() over all of the vein's security_facts() at the player's
# vein-security level, else over its fresh scouted facts.
static func vein_security_read(vein: Dictionary) -> Array:
	var known := knows(Shares.PLAYER, String(vein.get("factionId", "")), VEIN_SECURITY)
	return security_read(security_facts(vein) if known else fresh_scouted_facts(String(vein["id"])))


# ── Scouted security ────────────────────────────────────────────────────
# R§3.1 "Scouting a faction vein": the player's snapshots of a faction
# vein's security facts. state.scoutedSecurity: { veinId: { factId:
# { value, day } } }, value as security_facts() gave it on the day found.

static func new_scouted() -> Dictionary:
	return {}


static func _scout_cfg() -> Dictionary:
	return _cfg()["scout"]


# vein_id's scouted facts still fresh today (found within freshDays), keyed
# by fact id to the snapshot value.
static func fresh_scouted_facts(vein_id: String) -> Dictionary:
	var out := {}
	var fresh_days := int(_scout_cfg()["freshDays"])
	var scouted: Dictionary = GameState.state["scoutedSecurity"].get(vein_id, {})
	for fact in scouted:
		if _day() < int(scouted[fact]["day"]) + fresh_days:
			out[fact] = scouted[fact]["value"]
	return out


# One stable roll per security fact for a scout opening on day/block: the
# fact ids that hit, in SECURITY_FACTS order. Keyed off rollSeed, so a
# Rewound scout replays the same hits.
static func scout_rolls(vein_id: String, day: int, block: int) -> Array[String]:
	var chances: Dictionary = _scout_cfg()["chances"]
	var key := "%d|%s|%d|%d|scout" % [int(GameState.state["world"]["rollSeed"]), vein_id, day, block]
	var hits: Array[String] = []
	for fact in SECURITY_FACTS:
		if Rng.stable_unit("%s|%s" % [key, fact]) < float(chances[fact]):
			hits.append(fact)
	return hits


# Scout action on a faction vein: travels there and spends 1 block, then
# rolls each fact; a hit stores (or refreshes) its current value and today.
# Raises the player's intel on the faction by gain.scout and pushes one
# notification. { ok, hits } or { ok: false, reason }.
static func scout(vein: Dictionary) -> Dictionary:
	var travel := Travel.ensure_district(String(vein["district"]))
	if not travel["ok"]:
		return travel
	var world: Dictionary = GameState.state["world"]
	var day := int(world["day"])
	var block := int(world["timeBlock"])
	TimeSystem.advance_time_block()
	var vein_id := String(vein["id"])
	var faction_id := String(vein["factionId"])
	var hits := scout_rolls(vein_id, day, block)
	var facts := security_facts(vein)
	var store: Dictionary = GameState.state["scoutedSecurity"]
	if not hits.is_empty() and not store.has(vein_id):
		store[vein_id] = {}
	var names: Array[String] = []
	for fact in hits:
		var value: Variant = facts[fact]
		if value is Dictionary:
			value = (value as Dictionary).duplicate(true)
		store[vein_id][fact] = { "value": value, "day": day }
		names.append(String(_scout_cfg()["factNames"][fact]))
	gain(Shares.PLAYER, faction_id, SOURCE_SCOUT)
	var faction_name := String(GameData.FACTIONS[faction_id]["name"])
	var district_name := String(GameData.DISTRICTS[String(vein["district"])]["name"])
	if names.is_empty():
		Notify.push(String(_scout_cfg()["nothing"]) % [faction_name, district_name])
	else:
		Notify.push(String(_scout_cfg()["found"]) % [faction_name, district_name, ", ".join(names)], Notify.CATEGORY_SUCCESS)
	return { "ok": true, "hits": hits }


# Every security fact about a faction vein, keyed by SECURITY_FACTS id:
# alarms { alarm, cameras } and ward type from Raiding.security_profile(),
# guard count, guard strength word, and guard kit (recipe key → units: the
# vein's kit allocation capped by the faction's held units, as
# Combat.event_fight_kit).
static func security_facts(vein: Dictionary) -> Dictionary:
	var profile := Raiding.security_profile(vein)
	var kit := {}
	var allocation: Dictionary = vein.get("kit", {})
	var stock: Dictionary = GameState.state["factions"][String(vein["factionId"])]["holdings"]["items"]
	for recipe_key in allocation:
		var units := mini(int(allocation[recipe_key]), GuardKit.unit_count({ recipe_key: stock.get(recipe_key, {}) }))
		if units > 0 and GameData.RECIPES.has(recipe_key):
			kit[String(recipe_key)] = units
	return {
		FACT_ALARMS: { "alarm": bool(profile["alarm"]), "cameras": int(profile["cameras"]) },
		FACT_GUARD_COUNT: int(profile["guards"]),
		FACT_GUARD_STRENGTH: String(profile["strength"]),
		FACT_GUARD_KIT: kit,
		FACT_WARD: String(profile["wardType"]),
	}


# Alarms, Ward and Guards rows ({ label, text }) from a subset of
# security_facts(): a fact absent from `facts` is unknown and reads as the
# unknown mark.
static func security_read(facts: Dictionary) -> Array:
	var words: Dictionary = _cfg()["securityRead"]
	var unknown := String(words["unknown"])
	var alarms_text := unknown
	if facts.has(FACT_ALARMS):
		var alarms: Array[String] = []
		if bool(facts[FACT_ALARMS]["alarm"]):
			alarms.append(String(words["alarm"]))
		var cameras := int(facts[FACT_ALARMS]["cameras"])
		if cameras > 0:
			alarms.append(String(words["camera" if cameras == 1 else "cameras"]) % cameras)
		alarms_text = ", ".join(alarms) if not alarms.is_empty() else String(words["none"])
	var ward_text := unknown
	if facts.has(FACT_WARD):
		var ward_type := String(facts[FACT_WARD])
		ward_text = String(GameData.WARDS["types"][ward_type]["name"]) if GameData.WARDS["types"].has(ward_type) else String(words["none"])
	return [
		{ "label": String(words["alarms"]), "text": alarms_text },
		{ "label": String(words["ward"]), "text": ward_text },
		{ "label": String(words["guards"]), "text": _guards_text(facts, words) },
	]


# Guards row: None when the count is known and 0; the unknown mark when count,
# strength and kit are all unknown; else count · strength · kit, each unknown
# part as its unknown form.
static func _guards_text(facts: Dictionary, words: Dictionary) -> String:
	var unknown := String(words["unknown"])
	var has_count := facts.has(FACT_GUARD_COUNT)
	if has_count and int(facts[FACT_GUARD_COUNT]) <= 0:
		return String(words["none"])
	if not has_count and not facts.has(FACT_GUARD_STRENGTH) and not facts.has(FACT_GUARD_KIT):
		return unknown
	var parts: Array[String] = []
	if has_count:
		var count := int(facts[FACT_GUARD_COUNT])
		parts.append(String(words["guardCount" if count == 1 else "guardsCount"]) % count)
	else:
		parts.append(String(words["guardsUnknown"]))
	if not facts.has(FACT_GUARD_STRENGTH):
		parts.append(unknown)
	elif String(facts[FACT_GUARD_STRENGTH]) != "":
		parts.append(String(facts[FACT_GUARD_STRENGTH]))
	if not facts.has(FACT_GUARD_KIT):
		parts.append(String(words["kit"]) % unknown)
	elif not (facts[FACT_GUARD_KIT] as Dictionary).is_empty():
		var kit: Array[String] = []
		for recipe_key in facts[FACT_GUARD_KIT]:
			kit.append("%s ×%d" % [GameData.RECIPES[recipe_key]["name"], int(facts[FACT_GUARD_KIT][recipe_key])])
		parts.append(String(words["kit"]) % ", ".join(kit))
	return " · ".join(parts)


# faction_id's site veins counted per security label, e.g. { "Hired Guard": 2 }.
static func vein_security_counts(faction_id: String) -> Dictionary:
	var counts := {}
	for site in Sites.sites_with_faction_vein(faction_id):
		var label := Cultivating.security_label(site["factionVein"])
		counts[label] = int(counts.get(label, 0)) + 1
	return counts

class_name Intel
extends RefCounted

# Intel meters (R§3.1 "Intel"): what each actor knows about each other actor,
# 0..max per observer -> target pair, the player (Shares.PLAYER) and every
# faction on both sides. Levels unlock in constants.json `intel.levels`
# order as the meter reaches each `at`. Scouting and raiding a target raise
# the meter; it decays daily; a stockpile relocation drops every observer
# below the stockpile-location level.

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
	return meter(observer, target) >= level_at(level_id)


# The highest level observer has reached on target ({ id, at, name }), or {}
# below the first.
static func level(observer: String, target: String) -> Dictionary:
	var reached := {}
	var value := meter(observer, target)
	for entry in _cfg()["levels"]:
		if value >= int(entry["at"]):
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
# security_read() over its fresh scouted facts only (R§3.1 "Scouting a
# faction vein"); intel level never reveals vein security.
static func vein_security_read(vein: Dictionary) -> Array:
	return security_read(fresh_scouted_facts(String(vein["id"])))


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


# The player's chance to find `fact` on a scout: chances[fact] plus the
# Physics Lens scout bonus (R§1.4 Lenses), capped at 1.0.
static func scout_chance(fact: String) -> float:
	return minf(1.0, float(_scout_cfg()["chances"][fact]) + Lenses.physics_scout_bonus())


# One stable roll per security fact for a scout opening on day/block: the
# fact ids that hit, in SECURITY_FACTS order. Keyed off rollSeed and tag, so
# a Rewound scout replays the same hits.
static func scout_rolls(vein_id: String, day: int, block: int, tag: String = SOURCE_SCOUT) -> Array[String]:
	var key := "%d|%s|%d|%d|%s" % [int(GameState.state["world"]["rollSeed"]), vein_id, day, block, tag]
	var hits: Array[String] = []
	for fact in SECURITY_FACTS:
		if Rng.stable_unit("%s|%s" % [key, fact]) < scout_chance(fact):
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
	var faction_id := String(vein["factionId"])
	var hits := scout_rolls(String(vein["id"]), day, block)
	var names := _record_hits(vein, hits, day)
	gain(Shares.PLAYER, faction_id, SOURCE_SCOUT)
	var faction_name := String(GameData.FACTIONS[faction_id]["name"])
	var district_name := String(GameData.DISTRICTS[String(vein["district"])]["name"])
	if names.is_empty():
		Notify.push(String(_scout_cfg()["nothing"]) % [faction_name, district_name])
	else:
		Notify.push(String(_scout_cfg()["found"]) % [faction_name, district_name, ", ".join(names)], Notify.CATEGORY_SUCCESS)
	return { "ok": true, "hits": hits }


# Stores each hit fact's current security_facts value and day in
# state.scoutedSecurity, replacing earlier entries; returns the hits'
# factNames in order.
static func _record_hits(vein: Dictionary, hits: Array[String], day: int) -> Array[String]:
	var names: Array[String] = []
	if hits.is_empty():
		return names
	var vein_id := String(vein["id"])
	var facts := security_facts(vein)
	var store: Dictionary = GameState.state["scoutedSecurity"]
	if not store.has(vein_id):
		store[vein_id] = {}
	for fact in hits:
		var value: Variant = facts[fact]
		if value is Dictionary:
			value = (value as Dictionary).duplicate(true)
		store[vein_id][fact] = { "value": value, "day": day }
		names.append(String(_scout_cfg()["factNames"][fact]))
	return names


# Rollover step ⑥.5h3, Mondays only (R§3.1 "Weekly scouting"): per faction,
# floor(player intel ÷ weekly.pointsPerScout) free scouts, each on a random
# vein of that faction (repeats allowed), rolled and stored as a manual
# scout but with no block spent and no intel gain. Target picks and rolls
# are keyed off rollSeed, so Rewind replays them. One notification sums up
# the finds per faction; none when nothing was found. Returns { factionId:
# [veinId per scout] }, {} off Mondays.
static func weekly_scouts() -> Dictionary:
	var targets := {}
	var day := _day()
	if not Calendar.is_monday(day):
		return targets
	var weekly: Dictionary = _scout_cfg()["weekly"]
	var per_scout := int(weekly["pointsPerScout"])
	var roll_seed := int(GameState.state["world"]["rollSeed"])
	var faction_lines: Array[String] = []
	for faction_id in GameData.FACTIONS:
		var count := meter(Shares.PLAYER, faction_id) / per_scout
		var sites := Sites.sites_with_faction_vein(faction_id)
		if count <= 0 or sites.is_empty():
			continue
		targets[faction_id] = []
		# veinId -> { district, names }, names unique in first-found order.
		var found := {}
		var order: Array[String] = []
		for i in range(count):
			var pick := Rng.stable_unit("%d|%s|%d|%d|weeklyTarget" % [roll_seed, faction_id, day, i])
			var vein: Dictionary = sites[mini(int(pick * sites.size()), sites.size() - 1)]["factionVein"]
			var vein_id := String(vein["id"])
			targets[faction_id].append(vein_id)
			var names := _record_hits(vein, scout_rolls(vein_id, day, i, "weekly"), day)
			if names.is_empty():
				continue
			if not found.has(vein_id):
				found[vein_id] = { "district": String(vein["district"]), "names": [] }
				order.append(vein_id)
			for fact_name in names:
				if not found[vein_id]["names"].has(fact_name):
					found[vein_id]["names"].append(fact_name)
		if order.is_empty():
			continue
		var vein_parts: Array[String] = []
		for vein_id in order:
			var district_name := String(GameData.DISTRICTS[found[vein_id]["district"]]["name"])
			vein_parts.append(String(weekly["vein"]) % [district_name, ", ".join(found[vein_id]["names"])])
		faction_lines.append(String(weekly["faction"]) % [String(GameData.FACTIONS[faction_id]["name"]), "; ".join(vein_parts)])
	if not faction_lines.is_empty():
		Notify.push(String(weekly["found"]) % ". ".join(faction_lines), Notify.CATEGORY_SUCCESS)
	return targets


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


# True when the player holds at least one fresh scouted fact on vein_id.
static func has_fresh_scout(vein_id: String) -> bool:
	return not fresh_scouted_facts(vein_id).is_empty()


# faction_id's site veins: { scouted, total }, scouted counting those with at
# least one fresh scouted fact.
static func scouted_vein_counts(faction_id: String) -> Dictionary:
	var sites := Sites.sites_with_faction_vein(faction_id)
	var scouted := 0
	for site in sites:
		if has_fresh_scout(String(site["factionVein"]["id"])):
			scouted += 1
	return { "scouted": scouted, "total": sites.size() }

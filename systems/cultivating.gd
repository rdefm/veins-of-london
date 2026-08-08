class_name Cultivating
extends RefCounted

# Seed/cultivate/harvest per R§3.4. Static funcs only.

const LEVEL_CAP := 5

# data/vein_security.json's upgrade ladder (R§1.6). The file's key order
# already matches this, but that's an implicit JSON-insertion-order
# guarantee — spelled out explicitly here the same way GameData.
# SITE_TIER_ORDER/HOME_TIER_ORDER pin down their own tables' orderings.
const VEIN_SECURITY_ORDER: Array[String] = ["none", "basic", "warded", "guarded"]

# Verbatim from HTML generateLocationName(). Kept as the fallback/default
# array (also used for whitechapel, M1-LONDON.md D2's per-district
# extension below) so pre-M1 no-arg callers are unaffected.
const LOCATION_STREETS: Array[String] = [
	"Brick Lane", "Bethnal Green Rd", "Commercial St", "Whitechapel High St",
	"Mile End Rd", "Roman Rd", "Hackney Rd", "Cambridge Heath Rd", "Vallance Rd",
]
const LOCATION_SUFFIXES: Array[String] = [
	"near the off-licence", "behind the Tesco Metro", "under the railway arch",
	"in the car park", "by the bus stop", "beside the bookies",
]

# M1-LONDON.md D2: "location generated with district-appropriate street
# names (extend the generator: per-district street array, 4-6 real street
# names each)". Draft, real street names — no PROSE-REVIEW needed. soho
# has no sites (siteCap 0, no prospecting/veins) so it's omitted.
const DISTRICT_STREETS: Dictionary = {
	"shoreditch": ["Old St", "Redchurch St", "Rivington St", "Curtain Rd", "Kingsland Rd", "Shoreditch High St"],
	"city": ["Cheapside", "Cornhill", "Threadneedle St", "Leadenhall St", "Fenchurch St", "Bishopsgate"],
	"greenwich": ["Greenwich High Rd", "Nelson Rd", "Royal Hill", "Trafalgar Rd", "Blackheath Rd", "Creek Rd"],
	"camden": ["Camden High St", "Chalk Farm Rd", "Parkway", "Inverness St", "Kentish Town Rd", "Arlington Rd"],
	"kingscross": ["York Way", "Pentonville Rd", "Caledonian Rd", "Euston Rd", "Grays Inn Rd", "Goods Way"],
	"battersea": ["Battersea Park Rd", "Lavender Hill", "Northcote Rd", "Falcon Rd", "Queenstown Rd", "York Rd"],
	"hampstead": ["Heath St", "Flask Walk", "Rosslyn Hill", "Fitzjohn's Ave", "Well Walk", "South End Rd"],
	"whitechapel": LOCATION_STREETS,
}


static func generate_location_name(district: String = "") -> String:
	var streets: Array = DISTRICT_STREETS.get(district, LOCATION_STREETS)
	return "%s, %s" % [Rng.rand_from(streets), Rng.rand_from(LOCATION_SUFFIXES)]


static func get_cult_chance(skill: int) -> float:
	return min(0.90, 0.30 + (skill - 1) * 0.12)


static func get_bar_gain(skill: int) -> int:
	return 1 + skill


# M1 hospitability bonuses (M1-LONDON.md D2), read from vein.hospitability.
# M0 veins default to { tier: "fair", bonuses: [] } — no bonus, no change
# in behaviour.
static func get_level_cap(vein: Dictionary) -> int:
	var bonuses: Array = vein.get("hospitability", {}).get("bonuses", [])
	return 6 if bonuses.has("maxLevel") else LEVEL_CAP


# "recharge" hospitability bonus: -1 (min 1), stacks with the King's
# Cross district special (also -1, min 1 overall).
static func get_effective_recharge_blocks(vein: Dictionary) -> int:
	var level_data: Dictionary = GameData.VEIN_LEVELS[str(vein["level"])]
	var blocks: int = level_data["rechargeBlocks"]
	var bonuses: Array = vein.get("hospitability", {}).get("bonuses", [])
	if bonuses.has("recharge"):
		blocks -= 1
	if vein.get("district") == "kingscross":
		blocks -= 1
	return maxi(1, blocks)


# "yield" hospitability bonus applies to the ROLLED result, not the level
# table's range: finalYield = max(rolled+1, round(rolled*1.15)) — guarantees
# +1 over the base roll even where 1.15x a small integer would round away.
static func apply_yield_bonus(vein: Dictionary, rolled: int) -> int:
	var bonuses: Array = vein.get("hospitability", {}).get("bonuses", [])
	if not bonuses.has("yield"):
		return rolled
	return maxi(rolled + 1, GameState.round_epsilon(rolled * 1.15))


# Shared vein-dict constructor for every place that creates a fresh Lv1
# vein (M0's free-floating seed() below, and systems/sites.gd's
# attempt_seed()). site_id is null for M0-style seeding, which isn't
# tied to a state.world.sites entry. hospitability is deep-copied — a
# site's seeded vein and its natural-vein bonus (D2) both derive their
# hospitability from the same site dict, and state purity requires every
# vein to own an independent copy, never share an Array/Dictionary
# reference with the site or with each other.
static func make_vein(ore_type: String, dev_bar: int, district: String, site_id: Variant, hospitability: Dictionary) -> Dictionary:
	return {
		"id": make_vein_id(),
		"oreType": ore_type,
		"level": 1,
		"levelLabel": GameData.VEIN_LEVELS["1"]["label"],
		"devBar": dev_bar,
		"charged": false,
		"chargeBlocks": 0,
		"security": "none",
		"location": generate_location_name(district),
		"claimedOnDay": GameState.state["world"]["day"],
		"district": district,
		"siteId": site_id,
		"hospitability": GameState.deep_copy(hospitability),
	}


static func award_xp(amount: int) -> void:
	var player: Dictionary = GameState.state["player"]
	player["cultivatingXP"] = player["cultivatingXP"] + amount
	var max_level: int = GameData.CULTIVATING_XP_LEVELS.size() - 1
	while player["cultivatingSkill"] < max_level and player["cultivatingXP"] >= GameData.CULTIVATING_XP_LEVELS[player["cultivatingSkill"] + 1]:
		player["cultivatingSkill"] += 1
		Notify.push("Cultivating skill up — now level %d." % player["cultivatingSkill"])


static func seed(ore_type: String) -> Dictionary:
	var player: Dictionary = GameState.state["player"]
	var have: int = player["orichalchum"].get(ore_type, 0)
	if have < GameData.SEED_ORE_COST or TimeSystem.is_time_exhausted():
		return { "ok": false, "reason": "Not enough calc, or no blocks left today." }

	TimeSystem.advance_time_block()
	player["orichalchum"][ore_type] = have - GameData.SEED_ORE_COST

	var skill: int = player["cultivatingSkill"]
	var success: bool = Rng.chance(get_cult_chance(skill))

	if success:
		var district: String = GameState.state["world"]["currentDistrict"]
		var vein := make_vein(ore_type, get_bar_gain(skill), district, null, { "tier": "fair", "bonuses": [] })
		player["veins"].append(vein)
		award_xp(30)
		Modal.open("seed_result", { "success": true, "oreType": ore_type })
		return { "ok": true, "success": true, "oreType": ore_type, "veinId": vein["id"] }
	else:
		award_xp(5)
		Modal.open("seed_result", { "success": false, "oreType": ore_type })
		return { "ok": true, "success": false, "oreType": ore_type }


static func cultivate(vein_id: String) -> Dictionary:
	var vein = find_vein(vein_id)
	if vein == null:
		return { "ok": false, "reason": "Vein not found." }

	var travel := Travel.ensure_district(vein["district"])
	if not travel["ok"]:
		return travel

	TimeSystem.advance_time_block()

	var player: Dictionary = GameState.state["player"]
	var skill: int = player["cultivatingSkill"]
	var success: bool = Rng.chance(get_cult_chance(skill))

	if success:
		var gain: int = get_bar_gain(skill)
		var level_data: Dictionary = GameData.VEIN_LEVELS[str(vein["level"])]
		vein["devBar"] = vein["devBar"] + gain
		award_xp(20)
		var levelled_up: bool = vein["level"] < get_level_cap(vein) and vein["devBar"] >= level_data["devBarMax"]
		if levelled_up:
			level_up_vein(vein)
		Modal.open("cultivate_result", { "success": true, "gain": gain, "veinId": vein_id, "levelledUp": levelled_up, "newLevel": vein["level"], "newLabel": vein["levelLabel"] })
		return { "ok": true, "success": true, "gain": gain, "veinId": vein_id, "levelledUp": levelled_up, "newLevel": vein["level"], "newLabel": vein["levelLabel"] }
	else:
		award_xp(8)
		Modal.open("cultivate_result", { "success": false, "veinId": vein_id })
		return { "ok": true, "success": false, "veinId": vein_id }


static func harvest_cautious(vein_id: String) -> Dictionary:
	var vein = find_vein(vein_id)
	if vein == null or not vein["charged"]:
		return { "ok": false, "reason": "Vein isn't charged." }

	var travel := Travel.ensure_district(vein["district"])
	if not travel["ok"]:
		return travel

	TimeSystem.advance_time_block()

	var level_data: Dictionary = GameData.VEIN_LEVELS[str(vein["level"])]
	var yield_range: Array = level_data["yieldCautious"]
	var amount: int = apply_yield_bonus(vein, Rng.randi_range(yield_range[0], yield_range[1]))

	var player: Dictionary = GameState.state["player"]
	var ore_type: String = vein["oreType"]
	player["orichalchum"][ore_type] = player["orichalchum"].get(ore_type, 0) + amount

	vein["charged"] = false
	vein["chargeBlocks"] = 0
	# map-animations ticket 04: the entry guard above already requires
	# vein["charged"] == true to reach this point, so setting it false here
	# is always the true -> false transition -- no was_charged flag needed,
	# unlike recharge_veins() which loops every vein every tick.
	MapEvents.queue_drain(vein["district"], vein["id"])

	EventBus.state_changed.emit()
	return { "ok": true, "amount": amount, "oreType": ore_type, "veinId": vein_id }


static func harvest_full(vein_id: String) -> Dictionary:
	var vein = find_vein(vein_id)
	if vein == null or not vein["charged"]:
		return { "ok": false, "reason": "Vein isn't charged." }

	var travel := Travel.ensure_district(vein["district"])
	if not travel["ok"]:
		return travel

	TimeSystem.advance_time_block()

	var level_data: Dictionary = GameData.VEIN_LEVELS[str(vein["level"])]
	var yield_range: Array = level_data["yieldFull"]
	var amount: int = apply_yield_bonus(vein, Rng.randi_range(yield_range[0], yield_range[1]))

	var player: Dictionary = GameState.state["player"]
	var ore_type: String = vein["oreType"]
	player["orichalchum"][ore_type] = player["orichalchum"].get(ore_type, 0) + amount

	vein["charged"] = false
	vein["chargeBlocks"] = 0
	vein["devBar"] = vein["devBar"] - level_data["devBarHarvestCost"]
	# map-animations ticket 04: see harvest_cautious's own comment -- the
	# entry guard above guarantees this is always the true -> false
	# transition. Queued before the possible level-down/deletion below so
	# district/id are read from the still-live vein dict.
	MapEvents.queue_drain(vein["district"], vein["id"])

	var levelled_down := false
	if vein["devBar"] <= 0:
		levelled_down = true
		_level_down_vein(vein)

	EventBus.state_changed.emit()
	return { "ok": true, "amount": amount, "oreType": ore_type, "veinId": vein_id, "levelledDown": levelled_down }


# Called from time_system.gd's daily_tick, step ④. map-animations ticket 03:
# queues a "charge" map event on the false -> true transition only — a vein
# that was already charged coming into this tick (chargeBlocks already at or
# past its threshold, so the block below is a no-op for it) must not requeue
# every subsequent day it just sits there charged.
static func recharge_veins() -> void:
	for vein in GameState.state["player"]["veins"]:
		var recharge_blocks: int = get_effective_recharge_blocks(vein)
		var was_charged: bool = vein["charged"]
		if vein["chargeBlocks"] < recharge_blocks:
			vein["chargeBlocks"] += 1
		if vein["chargeBlocks"] >= recharge_blocks:
			vein["charged"] = true
		if vein["charged"] and not was_charged:
			MapEvents.queue_charge(vein["district"], vein["id"])
	EventBus.state_changed.emit()


static func level_up_vein(vein: Dictionary) -> void:
	if vein["level"] >= get_level_cap(vein):
		return
	vein["level"] += 1
	vein["levelLabel"] = GameData.VEIN_LEVELS[str(vein["level"])]["label"]
	vein["devBar"] = 0


static func _level_down_vein(vein: Dictionary) -> void:
	var location_street: String = String(vein["location"]).split(",")[0]
	if vein["level"] <= 1:
		var player: Dictionary = GameState.state["player"]
		var ore_name: String = GameData.ORE_TYPES[vein["oreType"]]["name"]
		var vein_id: String = vein["id"]
		player["veins"] = player["veins"].filter(func(v): return v["id"] != vein_id)
		Notify.push("Your %s vein on %s collapsed and disappeared." % [ore_name, location_street])
	else:
		vein["level"] -= 1
		vein["levelLabel"] = GameData.VEIN_LEVELS[str(vein["level"])]["label"]
		var new_level_data: Dictionary = GameData.VEIN_LEVELS[str(vein["level"])]
		vein["devBar"] = int(floor(new_level_data["devBarMax"] * 0.8))
		Notify.push("A vein on %s dropped to level %d." % [location_street, vein["level"]])


static func find_vein(vein_id: String) -> Variant:
	for vein in GameState.state["player"]["veins"]:
		if vein["id"] == vein_id:
			return vein
	return null


static func make_vein_id() -> String:
	return "v" + str(Time.get_ticks_usec()) + str(Rng.randi_range(1000, 999999))


# ── vein security (M1-LONDON.md D4: site/vein sheet's "Upgrade security") ──

# Null once at "guarded" — the top of the ladder.
static func next_security_tier_id(current: String) -> Variant:
	var idx: int = VEIN_SECURITY_ORDER.find(current)
	if idx == -1 or idx >= VEIN_SECURITY_ORDER.size() - 1:
		return null
	return VEIN_SECURITY_ORDER[idx + 1]


# Cash-only, no block: D3's travel rule enumerates exactly five districted
# actions (prospect, seed, cultivate, harvest, sell) and security upgrades
# aren't one of them — same reasoning as Home.add_security, which this
# mirrors.
static func upgrade_vein_security(vein_id: String) -> Dictionary:
	var vein = find_vein(vein_id)
	if vein == null:
		return { "ok": false, "reason": "Vein not found." }

	var next_id = next_security_tier_id(vein["security"])
	if next_id == null:
		return { "ok": false, "reason": "Already at maximum security." }

	var next_data: Dictionary = GameData.VEIN_SECURITY[next_id]
	var cost: int = next_data["cost"]
	var player: Dictionary = GameState.state["player"]
	if player["cash"] < cost:
		return { "ok": false, "reason": "Not enough cash." }

	player["cash"] -= cost
	vein["security"] = next_id
	Notify.push("Installed %s on your %s vein." % [next_data["label"], GameData.ORE_TYPES[vein["oreType"]]["name"]])
	EventBus.state_changed.emit()
	SaveManager.autosave()  # R§6: autosave on purchase
	return { "ok": true }

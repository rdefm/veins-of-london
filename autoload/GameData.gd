extends Node

# Loads every data/*.json table once at boot into typed constants, and
# validates required keys + cross-references. Systems read GameData.*
# directly; nothing here ever touches GameState or the scene tree.

var ORE_TYPES: Dictionary = {}

var VEIN_GROWTH: Dictionary = {}
var SEED_ORE_COST: int = 0
var CULTIVATING_XP_LEVELS: Array = []

var RECIPES: Dictionary = {}
var CRAFTING_XP_LEVELS: Array = []
var CONSUMABLE_PRICES: Dictionary = {}

var DEVICE_XP_LEVELS: Array = []
var DEVICES: Dictionary = {}

var ITEMS: Dictionary = {}

var VEIN_SECURITY: Dictionary = {}

# vein-raiding ticket 05: the "alarm/cameras" upgrade — independent of
# VEIN_SECURITY's tier ladder above, per the PRD. Purchased ids land in a
# vein's own "alarmUpgrades" array (Cultivating.make_vein), mirroring how
# HOME_SECURITY's ids land in state.home["security"].
var VEIN_ALARM: Dictionary = {}

# vein-raiding ticket 01/02: third skill, same progression shape as
# CULTIVATING_XP_LEVELS/CRAFTING_XP_LEVELS above. Its own file (rather than
# folded into vein_security.json) since it's not tier-keyed content.
var STEALTH_XP_LEVELS: Array = []

var HOME_TIER_ORDER: Array = []
var HOME_TIERS: Dictionary = {}
var HOME_SECURITY: Dictionary = {}
var HOME_ROOMS: Dictionary = {}

var APPROACHES: Dictionary = {}

var FACTIONS: Dictionary = {}

# collective1-01: per-faction trade lane config (Economy.get_faction_*),
# replacing the formerly-hardcoded GUILD_SPREAD_MAX/GUILD_SPREAD_ZERO_RELATION.
var FACTION_TRADE: Dictionary = {}

var DISTRICTS: Dictionary = {}

var MAP_LAYOUT: Dictionary = {}

var SITE_TIER_ORDER: Array = []
var SITE_TIER_WEIGHTS: Dictionary = {}
var SITE_AT_CAP_TIER_WEIGHTS: Dictionary = {}
var SITE_PROSPECT_XP: Dictionary = {}
var SITE_SEED_TIER_MOD: Dictionary = {}
var SITE_DISCOVERY_BONUS_POOL: Array = []
var SITE_NATURAL_VEIN_CHANCE: float = 0.0

var BAROMETER_STATES: Dictionary = {}
var BAROMETER_ACTIONS: Array = []
var FACTION_BAROMETER_PREFS: Dictionary = {}

var ENEMY_RAID_GUARDS: Dictionary = {}
var ENEMY_HOME_RAID_RAIDER: Dictionary = {}

var TIME_BLOCKS: Array = []
var ARCHIE_ORE_GOAL: int = 0
var CONTACTS_DEFAULTS: Dictionary = {}
var JAMES_JOB_TRUST_BANDS: Array = []

var EVENTS: Dictionary = {}
var SMS_THREADS: Dictionary = {}

# collective1-07, spec §9.5: per-vendor flavour lines drawn on completing a
# Collective trade (systems/collective.gd) -- cosmetic only, the three doors
# trade at identical terms. Keyed by contact id.
var COLLECTIVE_BARKS: Dictionary = {}

# collective1-02: data/objectives.json, keyed by objective id. Empty until a
# thread ticket (08/11/12/13) authors real Act 1 entries -- see
# systems/objectives.gd.
var OBJECTIVES: Dictionary = {}

# M0-T13's full tutorial event roster (R§3.11, R§3.8). JAMES_CRAFT_CARDS
# from the HTML is deliberately excluded — dead/unreachable content.
const EVENT_IDS: Array[String] = [
	"intro", "buyer", "james_meeting", "archie_craft_chat",
	"home_raid_intro", "home_raid_debrief_win", "home_raid_debrief_loss",
	"archie_motion", "james_motion",
	# M1-LONDON D6 — cultivating tutorial, triggered by scenes/screens/map.gd
	# on the first Map-tab visit after archiePartnerSeen.
	"archie_cultivation",
	# vein-raiding ticket 03: the Raid button's one representative event card
	# (systems/raiding.gd's begin_raid()) — directly triggered, like
	# home_raid_intro above, not part of any district's weighted event deck.
	# Named plainly rather than after any one faction/district/ore, since it
	# actually targets whichever real site's Raid button was pressed (see
	# events.gd's _event_site_id()), not a single fixed combination.
	"vein_raid",
]

# M1-LONDON D5's district event deck roster. Loaded into the same EVENTS
# dict as EVENT_IDS above — a district event file is a normal event file
# (cards/on_complete) plus a "deck" sub-object (district, weight,
# excludeIfFlag, barometerState) that systems/district_deck.gd reads.
# The engine (ticket 08) is exercised against synthetic entries in
# tests/test_district_deck.gd; these are the real ticket-09 content.
const DISTRICT_EVENT_IDS: Array[String] = [
	"busker_greenwich", "city_suit", "camden_shakedown", "heath_dogwalker",
	"whitechapel_grief", "kx_delay", "soho_tout", "battersea_hum",
	"shoreditch_archie", "conclave_watch", "pigeon_omen", "rain",
	"rival_prospector", "foxes", "roman_brick",
]

var loaded := false
var _load_errors: Array[String] = []
var _errors: Array[String] = []


func _ready() -> void:
	load_all()
	validate()


func load_all() -> void:
	ORE_TYPES = _load_json("res://data/ore_types.json")

	VEIN_GROWTH = _load_json("res://data/vein_growth.json")
	SEED_ORE_COST = VEIN_GROWTH.get("seedOreCost", 0)
	CULTIVATING_XP_LEVELS = VEIN_GROWTH.get("cultivatingXpLevels", [])

	var recipes := _load_json("res://data/recipes.json")
	RECIPES = recipes.get("recipes", {})
	CRAFTING_XP_LEVELS = recipes.get("craftingXpLevels", [])
	CONSUMABLE_PRICES = recipes.get("consumablePrices", {})

	var devices := _load_json("res://data/devices.json")
	DEVICE_XP_LEVELS = devices.get("deviceXpLevels", [])
	DEVICES = devices.get("devices", {})

	ITEMS = _load_json("res://data/items.json")
	VEIN_SECURITY = _load_json("res://data/vein_security.json")
	VEIN_ALARM = _load_json("res://data/vein_alarm.json")

	STEALTH_XP_LEVELS = _load_json("res://data/stealth.json").get("stealthXpLevels", [])

	var home := _load_json("res://data/home.json")
	HOME_TIER_ORDER = home.get("tierOrder", [])
	HOME_TIERS = home.get("tiers", {})
	HOME_SECURITY = home.get("security", {})
	HOME_ROOMS = home.get("rooms", {})

	APPROACHES = _load_json("res://data/approaches.json")

	FACTIONS = _load_json("res://data/factions.json")
	FACTION_TRADE = _load_json("res://data/faction_trade.json")

	DISTRICTS = _load_json("res://data/districts.json")

	MAP_LAYOUT = _load_json("res://data/map_layout.json")

	var sites := _load_json("res://data/sites.json")
	SITE_TIER_ORDER = sites.get("tierOrder", [])
	SITE_TIER_WEIGHTS = sites.get("tierWeights", {})
	SITE_AT_CAP_TIER_WEIGHTS = sites.get("atCapTierWeights", {})
	SITE_PROSPECT_XP = sites.get("prospectXp", {})
	SITE_SEED_TIER_MOD = sites.get("seedTierMod", {})
	SITE_DISCOVERY_BONUS_POOL = sites.get("discoveryBonusPool", [])
	SITE_NATURAL_VEIN_CHANCE = sites.get("naturalVeinChance", 0.0)

	var barometer := _load_json("res://data/barometer.json")
	BAROMETER_STATES = barometer.get("states", {})
	BAROMETER_ACTIONS = barometer.get("actions", [])
	FACTION_BAROMETER_PREFS = barometer.get("factionPrefs", {})

	var enemies := _load_json("res://data/enemies.json")
	ENEMY_RAID_GUARDS = enemies.get("raidGuards", {})
	ENEMY_HOME_RAID_RAIDER = enemies.get("homeRaidRaider", {})

	var constants := _load_json("res://data/constants.json")
	TIME_BLOCKS = constants.get("timeBlocks", [])
	ARCHIE_ORE_GOAL = constants.get("archieOreGoal", 0)
	CONTACTS_DEFAULTS = constants.get("contacts", {})
	JAMES_JOB_TRUST_BANDS = constants.get("jamesJobTrustBands", [])

	EVENTS = {}
	for event_id in EVENT_IDS + DISTRICT_EVENT_IDS:
		var event_def := _load_json("res://data/events/%s.json" % event_id)
		if not event_def.is_empty():
			EVENTS[event_id] = event_def

	SMS_THREADS = _load_json("res://data/sms.json")

	OBJECTIVES = _load_json("res://data/objectives.json")

	COLLECTIVE_BARKS = _load_json("res://data/collective_barks.json")

	loaded = true


func validate() -> bool:
	_errors = _load_errors + validate_tables(snapshot())
	return _errors.is_empty()


func get_errors() -> Array[String]:
	return _errors


# Pure, side-effect-free validation over an arbitrary snapshot of tables —
# takes the same shape _snapshot() returns. Kept separate from validate()
# so tests can feed it a deliberately corrupted copy without touching the
# real data/*.json files.
func validate_tables(t: Dictionary) -> Array[String]:
	var errors: Array[String] = []

	_validate_ore_types(t.get("ore_types", {}), errors)
	_validate_vein_growth(t.get("vein_growth", {}), t.get("cultivating_xp_levels", []), errors)
	_validate_recipes(t.get("recipes", {}), t.get("ore_types", {}), errors)
	_validate_devices(t.get("devices", {}), t.get("recipes", {}), t.get("ore_types", {}), errors)
	_validate_items(t.get("items", {}), errors)
	_validate_vein_security(t.get("vein_security", {}), errors)
	_validate_vein_alarm(t.get("vein_alarm", {}), errors)
	_validate_stealth(t.get("stealth_xp_levels", []), errors)
	_validate_home(t.get("home_tier_order", []), t.get("home_tiers", {}), t.get("home_security", {}), t.get("home_rooms", {}), errors)
	_validate_approaches(t.get("approaches", {}), t.get("home_rooms", {}), errors)
	_validate_factions(t.get("factions", {}), errors)
	_validate_faction_trade(t.get("faction_trade", {}), errors)
	_validate_districts(t.get("districts", {}), t.get("ore_types", {}), errors)
	_validate_map_layout(t.get("map_layout", {}), t.get("districts", {}), errors)
	_validate_sites(t.get("site_tier_order", []), t.get("site_tier_weights", {}), t.get("site_at_cap_tier_weights", {}), t.get("site_prospect_xp", {}), t.get("site_seed_tier_mod", {}), t.get("site_discovery_bonus_pool", []), errors)
	_validate_barometer(t.get("barometer_states", {}), t.get("barometer_actions", []), t.get("faction_prefs", {}), t.get("factions", {}), errors)
	_validate_enemies(t.get("enemy_raid_guards", {}), t.get("enemy_home_raid_raider", {}), errors)
	_validate_constants(t.get("time_blocks", []), t.get("contacts_defaults", {}), errors)
	_validate_events(t.get("events", {}), t.get("districts", {}), errors)
	_validate_sms(t.get("sms_threads", {}), errors)
	_validate_objectives(t.get("objectives", {}), t.get("factions", {}), t.get("ore_types", {}), t.get("site_tier_order", []), errors)
	_validate_collective_barks(t.get("collective_barks", {}), errors)

	return errors


# Public snapshot of every loaded table, keyed for validate_tables().
# Tests use this to build a deliberately corrupted copy without touching
# the real data/*.json files.
func snapshot() -> Dictionary:
	return {
		"ore_types": ORE_TYPES,
		"vein_growth": VEIN_GROWTH,
		"cultivating_xp_levels": CULTIVATING_XP_LEVELS,
		"recipes": RECIPES,
		"devices": DEVICES,
		"items": ITEMS,
		"vein_security": VEIN_SECURITY,
		"vein_alarm": VEIN_ALARM,
		"stealth_xp_levels": STEALTH_XP_LEVELS,
		"home_tier_order": HOME_TIER_ORDER,
		"home_tiers": HOME_TIERS,
		"home_security": HOME_SECURITY,
		"home_rooms": HOME_ROOMS,
		"approaches": APPROACHES,
		"factions": FACTIONS,
		"faction_trade": FACTION_TRADE,
		"districts": DISTRICTS,
		"map_layout": MAP_LAYOUT,
		"site_tier_order": SITE_TIER_ORDER,
		"site_tier_weights": SITE_TIER_WEIGHTS,
		"site_at_cap_tier_weights": SITE_AT_CAP_TIER_WEIGHTS,
		"site_prospect_xp": SITE_PROSPECT_XP,
		"site_seed_tier_mod": SITE_SEED_TIER_MOD,
		"site_discovery_bonus_pool": SITE_DISCOVERY_BONUS_POOL,
		"barometer_states": BAROMETER_STATES,
		"barometer_actions": BAROMETER_ACTIONS,
		"faction_prefs": FACTION_BAROMETER_PREFS,
		"enemy_raid_guards": ENEMY_RAID_GUARDS,
		"enemy_home_raid_raider": ENEMY_HOME_RAID_RAIDER,
		"time_blocks": TIME_BLOCKS,
		"contacts_defaults": CONTACTS_DEFAULTS,
		"events": EVENTS,
		"sms_threads": SMS_THREADS,
		"objectives": OBJECTIVES,
		"collective_barks": COLLECTIVE_BARKS,
	}


# ── per-table checks ──────────────────────────────────────────────────

const CANONICAL_ORE_TYPES: Array[String] = ["time", "physics", "life", "fate", "emotion"]


func _validate_ore_types(ore_types: Dictionary, errors: Array[String]) -> void:
	for key in CANONICAL_ORE_TYPES:
		if not ore_types.has(key):
			errors.append("ore_types: missing canonical type '%s'" % key)
	for key in ore_types.keys():
		if not CANONICAL_ORE_TYPES.has(key):
			errors.append("ore_types: unexpected type '%s' (old roster? not in R§1.1)" % key)
		_require_keys(ore_types[key], ["name", "symbol", "colour", "basePrice", "flavorText"], "ore_types.%s" % key, errors)


func _validate_vein_growth(vein_growth: Dictionary, xp_levels: Array, errors: Array[String]) -> void:
	_require_keys(vein_growth, [
		"neutral", "ceiling", "wildCeilingBonus", "bands", "yieldPerPoint", "hardPruneBonus",
		"pruneLightDepth", "pruneHardDepth", "cultivateBase", "cultivatePerSkill", "cultivateMinGain",
		"collapseChancePerDay", "seedGrowth", "rampantSeedDays", "selfSeedGrowth", "terroirYieldMult",
	], "vein_growth", errors)

	if xp_levels.size() != 6:
		errors.append("cultivatingXpLevels: expected 6 entries (index=level, 0..5), got %d" % xp_levels.size())

	if not vein_growth.has("bands"):
		return
	var neutral: int = vein_growth.get("neutral", 50)
	var bands: Array = vein_growth["bands"]
	var sorted_bands: Array = bands.duplicate()
	sorted_bands.sort_custom(func(a, b): return a["min"] < b["min"])

	if sorted_bands.is_empty():
		errors.append("vein_growth.bands: must not be empty")
		return
	if sorted_bands[0]["min"] != 0:
		errors.append("vein_growth.bands: must start at growth 0")

	for i in range(sorted_bands.size()):
		_require_keys(sorted_bands[i], ["id", "min", "max", "label", "drift"], "vein_growth.bands[%d]" % i, errors)
		if i > 0 and sorted_bands[i - 1]["max"] + 1 != sorted_bands[i]["min"]:
			errors.append("vein_growth.bands: gap or overlap between '%s' and '%s'" % [sorted_bands[i - 1].get("id"), sorted_bands[i].get("id")])

	if sorted_bands[-1]["max"] < 100:
		errors.append("vein_growth.bands: must cover through growth 100")

	# Exactly one non-pinned ("resting") band should sit at drift 0 and
	# straddle neutral (dormant) — collapsed/rampant are pinned walls, not
	# resting bands, even though they also carry drift 0.
	var resting_zero_drift := 0
	for band in sorted_bands:
		if band.get("id") == "collapsed":
			continue
		if band["min"] == 0 or band["min"] >= vein_growth.get("ceiling", 100):
			continue
		if band["drift"] == 0 and band["min"] <= neutral and neutral <= band["max"]:
			resting_zero_drift += 1
	if resting_zero_drift != 1:
		errors.append("vein_growth.bands: expected exactly one drift:0 band straddling neutral (dormant), found %d" % resting_zero_drift)


func _validate_recipes(recipes: Dictionary, ore_types: Dictionary, errors: Array[String]) -> void:
	for key in recipes.keys():
		var entry = recipes[key]
		_require_keys(entry, ["name", "symbol", "ingredients", "baseSuccess", "effectPower", "xpReward", "eventUsable", "description"], "recipes.%s" % key, errors)
		if entry.has("ingredients"):
			var ingredients: Dictionary = entry["ingredients"]
			if ingredients.is_empty():
				errors.append("recipes.%s: ingredients must have at least one entry" % key)
			for ingredient_key in ingredients.keys():
				if not ore_types.has(ingredient_key):
					errors.append("recipes.%s: ingredient '%s' is not a known ore type" % [key, ingredient_key])
		if entry.has("effectPower") and entry["effectPower"].size() != 6:
			errors.append("recipes.%s: effectPower must have 6 entries (index=skill 0..5)" % key)


func _validate_devices(devices: Dictionary, recipes: Dictionary, ore_types: Dictionary, errors: Array[String]) -> void:
	for key in devices.keys():
		var entry = devices[key]
		_require_keys(entry, ["name", "symbol", "calcType", "recipeKey", "effect", "unlockFlag", "eventUsable"], "devices.%s" % key, errors)
		if entry.has("calcType") and not ore_types.has(entry["calcType"]):
			errors.append("devices.%s: calcType '%s' is not a known ore type" % [key, entry["calcType"]])
		if entry.has("recipeKey") and not recipes.is_empty() and not recipes.has(entry["recipeKey"]):
			errors.append("devices.%s: recipeKey '%s' is not a known recipe" % [key, entry["recipeKey"]])


func _validate_items(items: Dictionary, errors: Array[String]) -> void:
	for key in items.keys():
		_require_keys(items[key], ["name", "slot", "description"], "items.%s" % key, errors)


func _validate_vein_security(security: Dictionary, errors: Array[String]) -> void:
	for key in ["none", "basic", "warded", "guarded"]:
		if not security.has(key):
			errors.append("vein_security: missing tier '%s'" % key)
			continue
		_require_keys(security[key], ["label", "raidResist", "cost"], "vein_security.%s" % key, errors)


func _validate_vein_alarm(alarm: Dictionary, errors: Array[String]) -> void:
	if not alarm.has("alarm"):
		errors.append("vein_alarm: missing upgrade 'alarm'")
		return
	_require_keys(alarm["alarm"], ["id", "label", "cost", "description"], "vein_alarm.alarm", errors)


func _validate_stealth(xp_levels: Array, errors: Array[String]) -> void:
	if xp_levels.size() != 6:
		errors.append("stealthXpLevels: expected 6 entries (index=level, 0..5), got %d" % xp_levels.size())


func _validate_home(tier_order: Array, tiers: Dictionary, security: Dictionary, rooms: Dictionary, errors: Array[String]) -> void:
	if tier_order.size() != tiers.size():
		errors.append("home: tierOrder size (%d) does not match tiers size (%d)" % [tier_order.size(), tiers.size()])
	for id in tier_order:
		if not tiers.has(id):
			errors.append("home: tierOrder references unknown tier '%s'" % id)
	for key in tiers.keys():
		_require_keys(tiers[key], ["id", "name", "tier", "upgradeCost", "dailyCost", "raidBaseChance", "maxRooms", "description"], "home.tiers.%s" % key, errors)

	for key in security.keys():
		var sec_entry: Dictionary = security[key]
		_require_keys(sec_entry, ["id", "name", "cost", "raidReduction", "minTier", "description"], "home.security.%s" % key, errors)
		if sec_entry.has("minTier") and not tiers.has(sec_entry["minTier"]):
			errors.append("home.security.%s: minTier '%s' is not a known home tier" % [key, sec_entry["minTier"]])

	for key in rooms.keys():
		var entry = rooms[key]
		_require_keys(entry, ["id", "name", "cost", "minTier", "bonus", "bonusValue", "description"], "home.rooms.%s" % key, errors)
		if entry.has("minTier") and not tiers.has(entry["minTier"]):
			errors.append("home.rooms.%s: minTier '%s' is not a known home tier" % [key, entry["minTier"]])


const VALID_APPROACH_SOURCE_TYPES: Array[String] = ["start", "room", "contact", "faction", "device"]


func _validate_approaches(approaches: Dictionary, rooms: Dictionary, errors: Array[String]) -> void:
	for key in ["heat", "grinding", "compression", "distilling"]:
		if not approaches.has(key):
			errors.append("approaches: missing canonical approach '%s'" % key)

	for key in approaches.keys():
		var entry = approaches[key]
		_require_keys(entry, ["name", "symbol", "source"], "approaches.%s" % key, errors)
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var source = entry.get("source")
		if typeof(source) != TYPE_DICTIONARY:
			errors.append("approaches.%s: source must be an object" % key)
			continue
		var source_type = source.get("type")
		if not VALID_APPROACH_SOURCE_TYPES.has(source_type):
			errors.append("approaches.%s: unknown source type '%s'" % [key, source_type])
		elif source_type == "room":
			if not rooms.is_empty() and not rooms.has(source.get("id")):
				errors.append("approaches.%s: source.id '%s' is not a known home room" % [key, source.get("id")])


func _validate_factions(factions: Dictionary, errors: Array[String]) -> void:
	for key in ["collective", "firm", "guild", "network", "conclave"]:
		if not factions.has(key):
			errors.append("factions: missing faction '%s'" % key)
			continue
		_require_keys(factions[key], ["id", "name", "shortName", "tagline", "industries", "description", "colour", "joinRelation", "securityBias", "resourceLevel"], "factions.%s" % key, errors)


# collective1-01: every faction with a trade lane (Economy.get_faction_*)
# needs a row here. Only guild and collective have one so far.
func _validate_faction_trade(faction_trade: Dictionary, errors: Array[String]) -> void:
	for key in ["guild", "collective"]:
		if not faction_trade.has(key):
			errors.append("faction_trade: missing faction '%s'" % key)
			continue
		_require_keys(faction_trade[key], ["anchorRelation", "zeroRelation", "sellSpreadMax", "sellSpreadMin", "buySpreadMax", "buySpreadMin", "memberOnly", "applyDistrictPriceMod", "mugRisk"], "faction_trade.%s" % key, errors)


const CANONICAL_DISTRICT_IDS: Array[String] = [
	"shoreditch", "city", "greenwich", "camden", "kingscross",
	"battersea", "hampstead", "whitechapel", "soho",
]


func _validate_districts(districts: Dictionary, ore_types: Dictionary, errors: Array[String]) -> void:
	for key in CANONICAL_DISTRICT_IDS:
		if not districts.has(key):
			errors.append("districts: missing canonical district '%s'" % key)
			continue
		var entry = districts[key]
		_require_keys(entry, ["id", "name", "oreBias", "siteQualityMod", "dangerMod", "priceMod", "siteCap", "special", "factionPresence", "blurb"], "districts.%s" % key, errors)
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		if entry.get("id") != key:
			errors.append("districts.%s: id field '%s' does not match key" % [key, entry.get("id")])
		var ore_bias = entry.get("oreBias", {})
		if typeof(ore_bias) == TYPE_DICTIONARY:
			for ore_key in ore_bias.keys():
				if not ore_types.is_empty() and not ore_types.has(ore_key):
					errors.append("districts.%s.oreBias: '%s' is not a known ore type" % [key, ore_key])
	for key in districts.keys():
		if not CANONICAL_DISTRICT_IDS.has(key):
			errors.append("districts: unexpected district '%s' (not in M1-LONDON.md D1)" % key)


# M1.5 N3: data/map_layout.json. Cross-references districts' siteCap to
# enforce "each district has >= siteCap + 2 stopSlots" — the buffer that
# lets a saturated site's bonus natural vein occupy a second slot beyond
# one-per-site (see systems/map_layout.gd's assign_slots).
func _validate_map_layout(layout: Dictionary, districts: Dictionary, errors: Array[String]) -> void:
	_require_keys(layout, ["mapSize", "districts", "riverPath", "homeAnchor"], "map_layout", errors)

	var map_size = layout.get("mapSize")
	if typeof(map_size) != TYPE_ARRAY or map_size.size() != 2:
		errors.append("map_layout.mapSize: expected [x, y], got %s" % str(map_size))

	var home_anchor = layout.get("homeAnchor")
	if typeof(home_anchor) != TYPE_ARRAY or home_anchor.size() != 2:
		errors.append("map_layout.homeAnchor: expected [x, y], got %s" % str(home_anchor))

	var river_path = layout.get("riverPath")
	if typeof(river_path) != TYPE_ARRAY or river_path.size() < 2:
		errors.append("map_layout.riverPath: expected an array of >= 2 [x, y] points")

	var layout_districts = layout.get("districts", {})
	if typeof(layout_districts) != TYPE_DICTIONARY:
		return

	for key in CANONICAL_DISTRICT_IDS:
		if not layout_districts.has(key):
			errors.append("map_layout.districts: missing canonical district '%s'" % key)
			continue
		var entry = layout_districts[key]
		_require_keys(entry, ["anchor", "labelAnchor", "zonePolygon", "stopSlots"], "map_layout.districts.%s" % key, errors)
		if typeof(entry) != TYPE_DICTIONARY:
			continue

		var anchor = entry.get("anchor")
		if typeof(anchor) != TYPE_ARRAY or anchor.size() != 2:
			errors.append("map_layout.districts.%s.anchor: expected [x, y]" % key)
		var label_anchor = entry.get("labelAnchor")
		if typeof(label_anchor) != TYPE_ARRAY or label_anchor.size() != 2:
			errors.append("map_layout.districts.%s.labelAnchor: expected [x, y]" % key)
		var zone_polygon = entry.get("zonePolygon")
		if typeof(zone_polygon) != TYPE_ARRAY or zone_polygon.size() < 3:
			errors.append("map_layout.districts.%s.zonePolygon: expected an array of >= 3 [x, y] points" % key)

		var stop_slots = entry.get("stopSlots")
		if typeof(stop_slots) != TYPE_ARRAY:
			errors.append("map_layout.districts.%s.stopSlots: expected an array of [x, y] points" % key)
			continue
		if not districts.is_empty() and districts.has(key):
			var site_cap: int = districts[key].get("siteCap", 0)
			if stop_slots.size() < site_cap + 2:
				errors.append("map_layout.districts.%s.stopSlots: needs >= siteCap+2 (%d) slots, got %d" % [key, site_cap + 2, stop_slots.size()])

	for key in layout_districts.keys():
		if not CANONICAL_DISTRICT_IDS.has(key):
			errors.append("map_layout.districts: unexpected district '%s' (not in M1-LONDON.md D1)" % key)


const CANONICAL_SITE_TIERS: Array[String] = ["barren", "poor", "fair", "rich", "saturated"]
const CANONICAL_SITE_BONUSES: Array[String] = ["vigour", "wildCeiling", "yield"]


func _validate_sites(tier_order: Array, tier_weights: Dictionary, at_cap_tier_weights: Dictionary, prospect_xp: Dictionary, seed_tier_mod: Dictionary, discovery_bonus_pool: Array, errors: Array[String]) -> void:
	if tier_order != CANONICAL_SITE_TIERS:
		errors.append("sites: tierOrder must be exactly %s, got %s" % [CANONICAL_SITE_TIERS, tier_order])
	for tier in CANONICAL_SITE_TIERS:
		if not tier_weights.has(tier):
			errors.append("sites: tierWeights missing tier '%s'" % tier)
		if not at_cap_tier_weights.has(tier):
			errors.append("sites: atCapTierWeights missing tier '%s'" % tier)
		if not prospect_xp.has(tier):
			errors.append("sites: prospectXp missing tier '%s'" % tier)
	for tier in ["poor", "fair", "rich", "saturated"]:
		if not seed_tier_mod.has(tier):
			errors.append("sites: seedTierMod missing tier '%s'" % tier)
	if seed_tier_mod.has("barren"):
		errors.append("sites: seedTierMod must not include 'barren' — barren sites can't be seeded")
	for bonus in CANONICAL_SITE_BONUSES:
		if not discovery_bonus_pool.has(bonus):
			errors.append("sites: discoveryBonusPool missing bonus '%s'" % bonus)


func _validate_barometer(states: Dictionary, actions: Array, faction_prefs: Dictionary, factions: Dictionary, errors: Array[String]) -> void:
	for section in ["economic", "social", "political"]:
		if not states.has(section):
			errors.append("barometer: missing section '%s'" % section)
			continue
		for state_id in states[section].keys():
			var state_entry = states[section][state_id]
			_require_keys(state_entry, ["id", "label", "description", "effects", "headlines"], "barometer.%s.%s" % [section, state_id], errors)
			if typeof(state_entry) == TYPE_DICTIONARY and state_entry.has("headlines") and state_entry["headlines"].size() < 2:
				errors.append("barometer.%s.%s: headlines needs at least 2 variants (D4.5), got %d" % [section, state_id, state_entry["headlines"].size()])

	for action in actions:
		_require_keys(action, ["id", "label", "section", "cost", "requireFaction", "description"], "barometer.actions.%s" % action.get("id", "?"), errors)
		if action.has("section") and not states.has(action["section"]):
			errors.append("barometer.actions.%s: section '%s' is not a known barometer section" % [action.get("id", "?"), action["section"]])
		var require_faction = action.get("requireFaction")
		if require_faction != null and not factions.is_empty() and not factions.has(require_faction):
			errors.append("barometer.actions.%s: requireFaction '%s' is not a known faction" % [action.get("id", "?"), require_faction])

	for faction_id in faction_prefs.keys():
		if not factions.is_empty() and not factions.has(faction_id):
			errors.append("barometer.factionPrefs: '%s' is not a known faction" % faction_id)
		for pref in faction_prefs[faction_id]:
			_require_keys(pref, ["section", "state", "direction", "strength"], "barometer.factionPrefs.%s" % faction_id, errors)
			if pref.has("section") and pref.has("state"):
				if not states.has(pref["section"]):
					errors.append("barometer.factionPrefs.%s: section '%s' is not a known barometer section" % [faction_id, pref["section"]])
				elif not states[pref["section"]].has(pref["state"]):
					errors.append("barometer.factionPrefs.%s: state '%s' does not exist in section '%s'" % [faction_id, pref["state"], pref["section"]])


func _validate_enemies(raid_guards: Dictionary, home_raid_raider: Dictionary, errors: Array[String]) -> void:
	for key in raid_guards.keys():
		_require_keys(raid_guards[key], ["name", "hpBase", "attackMin", "attackMax"], "enemies.raidGuards.%s" % key, errors)
	_require_keys(home_raid_raider, ["name", "hp", "attackMin", "attackMax"], "enemies.homeRaidRaider", errors)


func _validate_constants(time_blocks: Array, contacts_defaults: Dictionary, errors: Array[String]) -> void:
	if time_blocks.size() != 3:
		errors.append("constants: timeBlocks must have exactly 3 entries, got %d" % time_blocks.size())
	# collective1-07, spec §9.3: des/nadia/hakim join archie/james as real
	# contacts, all five now carrying recruitable (§7.1 -- the row that reads
	# it is ContactCards.build_recruit_row()).
	for key in ["archie", "james", "des", "nadia", "hakim"]:
		if not contacts_defaults.has(key):
			errors.append("constants: contacts is missing '%s'" % key)
			continue
		_require_keys(contacts_defaults[key], ["startRelation", "unlocked", "recruitThreshold", "recruitable"], "constants.contacts.%s" % key, errors)


# collective1-07, spec §9.5: cosmetic-only flavour lines, minimum 6 per
# vendor so no-repeat-until-exhausted (Collective._next_bark) has room to
# cycle before wrapping.
func _validate_collective_barks(barks: Dictionary, errors: Array[String]) -> void:
	for key in ["des", "nadia", "hakim"]:
		if not barks.has(key):
			errors.append("collective_barks: missing vendor '%s'" % key)
			continue
		var lines: Array = barks[key]
		if lines.size() < 6:
			errors.append("collective_barks.%s: needs at least 6 lines, got %d" % [key, lines.size()])


const VALID_CARD_TYPES: Array[String] = ["narration", "speaker", "tension", "resolution", "craft", "choice"]
const VALID_EFFECT_OPS: Array[String] = [
	"set_flag", "add", "add_ore", "add_item", "relation",
	"set_screen", "notify", "set_stage", "start_home_raid_combat",
	# M1-LONDON D5 district-event ops (systems/events.gd):
	"chance", "start_street_mugging", "npc_claim_best_unclaimed_site", "lose_time_block",
	# M1-LONDON D6/D7 ops (systems/events.gd): grant_vein_with_site pairs a
	# granted vein with a matching claimed site (home-raid debrief);
	# tutorial_cultivate forces one free successful cultivate (archie_cultivation).
	"grant_vein_with_site", "tutorial_cultivate",
	# vein-raiding ticket 02/03 ops (systems/events.gd): stealth_check/
	# start_raid_combat/claim_raid_vein/loot_raid_vein.
	"stealth_check", "start_raid_combat", "claim_raid_vein", "loot_raid_vein",
	# collective1-03 ops (systems/events.gd, systems/messages.gd):
	# unlock_contact flips contacts.<id>.unlocked; push_message appends a
	# plain unread text to a conversation (no follow-up action -- for that,
	# systems call Messages.queue_pending() directly, the same road
	# systems/raiding.gd already uses to hand runtime context to an event).
	"unlock_contact", "push_message",
]


func _validate_events(events: Dictionary, districts: Dictionary, errors: Array[String]) -> void:
	for expected_id in EVENT_IDS + DISTRICT_EVENT_IDS:
		if not events.has(expected_id):
			errors.append("events: missing event file '%s'" % expected_id)

	for key in events.keys():
		var entry = events[key]
		_require_keys(entry, ["id", "cards", "on_complete"], "events.%s" % key, errors)
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		if entry.get("id") != key:
			errors.append("events.%s: id field '%s' does not match filename" % [key, entry.get("id")])
		for card in entry.get("cards", []):
			_require_keys(card, ["type", "label", "speaker", "text"], "events.%s.cards" % key, errors)
			if card.has("type") and not VALID_CARD_TYPES.has(card["type"]):
				errors.append("events.%s: unknown card type '%s'" % [key, card["type"]])
			if card.get("type") == "choice":
				_validate_choice_card(card, "events.%s.cards" % key, errors)
		_validate_effect_list(entry.get("on_complete", []), "events.%s.on_complete" % key, errors)
		if entry.has("deck"):
			_validate_deck_entry(entry["deck"], "events.%s.deck" % key, errors)
			if not DISTRICT_EVENT_IDS.has(key):
				errors.append("events.%s: has a 'deck' sub-object but is not registered in GameData.DISTRICT_EVENT_IDS — it would silently join the district-deck draw pool" % key)
		if entry.has("pin"):
			_validate_event_pin(entry["pin"], districts, "events.%s.pin" % key, errors)

	for expected_id in DISTRICT_EVENT_IDS:
		if events.has(expected_id) and not events[expected_id].has("deck"):
			errors.append("events.%s: registered in GameData.DISTRICT_EVENT_IDS but missing its 'deck' sub-object" % expected_id)


# M1.5 N2's contact pin: { district, showWhenFlagsTrue:[flag,...],
# showWhenFlagsFalse:[flag,...] } — read by systems/map_pins.gd to decide
# whether a pin for this event is currently showing on the Network map.
func _validate_event_pin(pin: Dictionary, districts: Dictionary, context: String, errors: Array[String]) -> void:
	_require_keys(pin, ["district", "showWhenFlagsTrue", "showWhenFlagsFalse"], context, errors)
	if typeof(pin) != TYPE_DICTIONARY:
		return
	var district: Variant = pin.get("district")
	if not districts.is_empty() and not districts.has(district):
		errors.append("%s: district '%s' is not a known district" % [context, district])


# M1-LONDON D5's `choices` card type: { type:"choice", text,
# choices:[{label, effects, result_text}] }.
func _validate_choice_card(card: Dictionary, context: String, errors: Array[String]) -> void:
	if not card.has("choices") or typeof(card["choices"]) != TYPE_ARRAY:
		errors.append("%s: 'choice' card missing 'choices' array" % context)
		return
	for choice in card["choices"]:
		_require_keys(choice, ["label", "effects", "result_text"], "%s.choices" % context, errors)
		if typeof(choice) != TYPE_DICTIONARY:
			continue
		_validate_effect_list(choice.get("effects", []), "%s.choices.effects" % context, errors)


# Shared by on_complete lists and choice-card effects lists. Recurses into
# "chance" ops' on_success/on_fail sub-lists (M1-LONDON D5) so a bad op
# buried inside a chance branch doesn't sail through unnoticed.
func _validate_effect_list(effects: Array, context: String, errors: Array[String]) -> void:
	for effect in effects:
		_require_keys(effect, ["op"], context, errors)
		if typeof(effect) != TYPE_DICTIONARY or not effect.has("op"):
			continue
		if not VALID_EFFECT_OPS.has(effect["op"]):
			errors.append("%s: unknown effect op '%s'" % [context, effect["op"]])
			continue
		if effect["op"] == "chance":
			_require_keys(effect, ["p", "on_success", "on_fail"], context, errors)
			_validate_effect_list(effect.get("on_success", []), "%s.chance.on_success" % context, errors)
			_validate_effect_list(effect.get("on_fail", []), "%s.chance.on_fail" % context, errors)
		# vein-raiding ticket 03: stealth_check branches into on_success/
		# on_caught the same way "chance" branches into on_success/on_fail --
		# recursed here for the same reason, so a bad op buried inside either
		# branch doesn't sail through unnoticed.
		if effect["op"] == "stealth_check":
			_require_keys(effect, ["on_success", "on_caught"], context, errors)
			_validate_effect_list(effect.get("on_success", []), "%s.stealth_check.on_success" % context, errors)
			_validate_effect_list(effect.get("on_caught", []), "%s.stealth_check.on_caught" % context, errors)


# M1-LONDON D5's deck filter metadata: district (or "any"), weight,
# excludeIfFlag (nullable), barometerState (nullable — reserved plumbing,
# not exercised by any current data per D5).
func _validate_deck_entry(deck: Dictionary, context: String, errors: Array[String]) -> void:
	_require_keys(deck, ["district", "weight", "excludeIfFlag", "barometerState"], context, errors)
	if typeof(deck) != TYPE_DICTIONARY:
		return
	var district: Variant = deck.get("district")
	if district != "any" and not CANONICAL_DISTRICT_IDS.has(district):
		errors.append("%s: district '%s' is neither 'any' nor a known district" % [context, district])


func _validate_sms(threads: Dictionary, errors: Array[String]) -> void:
	for expected_id in ["archie_1", "archie_2"]:
		if not threads.has(expected_id):
			errors.append("sms: missing thread '%s'" % expected_id)
			continue
		for msg in threads[expected_id]:
			_require_keys(msg, ["from", "text"], "sms.%s" % expected_id, errors)
			if msg.has("from") and not ["player", "archie"].has(msg["from"]):
				errors.append("sms.%s: unknown sender '%s'" % [expected_id, msg["from"]])


# collective1-02: data/objectives.json — Objectives.refresh()'s four
# canonical evaluator types (systems/objectives.gd), each with its own fixed
# param schema.
const OBJECTIVE_TYPES: Array[String] = [
	"sites_discovered_matching", "traded_with_faction", "vein_sold_to_faction", "vein_growth_above",
]
const OBJECTIVE_TYPE_PARAMS: Dictionary = {
	"sites_discovered_matching": ["requireEachOreType", "minTier", "unclaimed"],
	"traded_with_faction": ["factionId", "oreType", "qty", "minTransactions"],
	"vein_sold_to_faction": ["factionId", "oreType"],
	"vein_growth_above": ["veinIdStatePath", "threshold"],
}


func _validate_objectives(objectives: Dictionary, factions: Dictionary, ore_types: Dictionary, site_tier_order: Array, errors: Array[String]) -> void:
	for key in objectives.keys():
		var entry = objectives[key]
		_require_keys(entry, ["id", "title", "detail", "type", "params", "activateFlag", "completeFlag"], "objectives.%s" % key, errors)
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		if entry.get("id") != key:
			errors.append("objectives.%s: id field '%s' does not match key" % [key, entry.get("id")])
		if entry.has("activateFlag") and typeof(entry["activateFlag"]) != TYPE_STRING:
			errors.append("objectives.%s: activateFlag must be a string" % key)
		if entry.has("completeFlag") and typeof(entry["completeFlag"]) != TYPE_STRING:
			errors.append("objectives.%s: completeFlag must be a string" % key)

		var obj_type = entry.get("type")
		if not OBJECTIVE_TYPES.has(obj_type):
			errors.append("objectives.%s: unknown type '%s'" % [key, obj_type])
			continue

		var params = entry.get("params")
		if typeof(params) != TYPE_DICTIONARY:
			errors.append("objectives.%s: params must be an object" % key)
			continue
		for required_param in OBJECTIVE_TYPE_PARAMS[obj_type]:
			if not params.has(required_param):
				errors.append("objectives.%s: type '%s' missing param '%s'" % [key, obj_type, required_param])

		match obj_type:
			"sites_discovered_matching":
				for ore_key in params.get("requireEachOreType", []):
					if not ore_types.is_empty() and not ore_types.has(ore_key):
						errors.append("objectives.%s: requireEachOreType '%s' is not a known ore type" % [key, ore_key])
				var min_tier = params.get("minTier")
				if not site_tier_order.is_empty() and not site_tier_order.has(min_tier):
					errors.append("objectives.%s: minTier '%s' is not a known site tier" % [key, min_tier])
			"traded_with_faction", "vein_sold_to_faction":
				var faction_id = params.get("factionId")
				if not factions.is_empty() and not factions.has(faction_id):
					errors.append("objectives.%s: factionId '%s' is not a known faction" % [key, faction_id])
				var ore_key = params.get("oreType")
				if not ore_types.is_empty() and not ore_types.has(ore_key):
					errors.append("objectives.%s: oreType '%s' is not a known ore type" % [key, ore_key])
			"vein_growth_above":
				if typeof(params.get("veinIdStatePath")) != TYPE_STRING:
					errors.append("objectives.%s: veinIdStatePath must be a string" % key)


func _require_keys(entry: Dictionary, keys: Array, context: String, errors: Array[String]) -> void:
	if typeof(entry) != TYPE_DICTIONARY:
		errors.append("%s: expected a Dictionary, got %s" % [context, type_string(typeof(entry))])
		return
	for key in keys:
		if not entry.has(key):
			errors.append("%s: missing required key '%s'" % [context, key])


# ── file loading ──────────────────────────────────────────────────────

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		_load_errors.append("Missing data file: %s" % path)
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_load_errors.append("Could not open data file: %s (error %d)" % [path, FileAccess.get_open_error()])
		return {}
	var text := file.get_as_text()
	var parsed = JSON.parse_string(text)
	if parsed == null:
		_load_errors.append("Failed to parse JSON: %s" % path)
		return {}
	if typeof(parsed) != TYPE_DICTIONARY:
		_load_errors.append("Expected a JSON object at top level: %s" % path)
		return {}
	return _normalize_numbers(parsed)


# JSON has no int type — JSON.parse_string() returns every number as a
# float, including whole numbers like 10 or 80. Every downstream table
# (contacts defaults, event effect templates like grant_vein_with_site, etc.) gets
# read into GameState's pure state tree, where int vs. float is load-
# bearing (deep-equality save/load checks, and dict lookups that str()
# a growth band's id to key into VEIN_GROWTH — "1.0" isn't "1"). Rather than
# casting at every consumption site, normalize once here: any float with
# no fractional part becomes int. Safe against the current data/*.json —
# every genuinely-fractional field (baseSuccess: 0.35, raidBaseChance:
# 0.005, etc.) stays float; nothing in the data is an intentionally-whole
# float (e.g. "1.0") that this would misclassify.
func _normalize_numbers(value: Variant) -> Variant:
	match typeof(value):
		TYPE_DICTIONARY:
			var result := {}
			for key in (value as Dictionary).keys():
				result[key] = _normalize_numbers(value[key])
			return result
		TYPE_ARRAY:
			var result := []
			for item in value as Array:
				result.append(_normalize_numbers(item))
			return result
		TYPE_FLOAT:
			var f: float = value
			if f == floor(f):
				return int(f)
			return f
		_:
			return value

extends Node

# Loads every data/*.json table once at boot into typed constants, and
# validates required keys + cross-references. Systems read GameData.*
# directly; nothing here ever touches GameState or the scene tree.

var ORE_TYPES: Dictionary = {}

var VEIN_LEVELS: Dictionary = {}
var SEED_ORE_COST: int = 0
var CULTIVATING_XP_LEVELS: Array = []

var RECIPES: Dictionary = {}
var CRAFTING_XP_LEVELS: Array = []
var CONSUMABLE_PRICES: Dictionary = {}

var DEVICE_XP_LEVELS: Array = []
var DEVICES: Dictionary = {}

var ITEMS: Dictionary = {}

var VEIN_SECURITY: Dictionary = {}

var HOME_TIER_ORDER: Array = []
var HOME_TIERS: Dictionary = {}
var HOME_SECURITY: Dictionary = {}
var HOME_ROOMS: Dictionary = {}

var FACTIONS: Dictionary = {}

var DISTRICTS: Dictionary = {}

var SITE_TIER_ORDER: Array = []
var SITE_TIER_WEIGHTS: Dictionary = {}
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

# M0-T13's full tutorial event roster (R§3.11, R§3.8). JAMES_CRAFT_CARDS
# from the HTML is deliberately excluded — dead/unreachable content.
const EVENT_IDS: Array[String] = [
	"intro", "buyer", "james_meeting", "archie_craft_chat",
	"home_raid_intro", "home_raid_debrief_win", "home_raid_debrief_loss",
	"archie_motion", "james_motion",
]

# M1-LONDON D5's district event deck roster. Loaded into the same EVENTS
# dict as EVENT_IDS above — a district event file is a normal event file
# (cards/on_complete) plus a "deck" sub-object (district, weight,
# excludeIfFlag, barometerState) that systems/district_deck.gd reads.
# Empty until ticket 09 authors the 15 events; the engine (ticket 08) is
# exercised against synthetic entries in tests/test_district_deck.gd.
const DISTRICT_EVENT_IDS: Array[String] = []

var loaded := false
var _load_errors: Array[String] = []
var _errors: Array[String] = []


func _ready() -> void:
	load_all()
	validate()


func load_all() -> void:
	ORE_TYPES = _load_json("res://data/ore_types.json")

	var vein_levels := _load_json("res://data/vein_levels.json")
	VEIN_LEVELS = vein_levels.get("levels", {})
	SEED_ORE_COST = vein_levels.get("seedOreCost", 0)
	CULTIVATING_XP_LEVELS = vein_levels.get("cultivatingXpLevels", [])

	var recipes := _load_json("res://data/recipes.json")
	RECIPES = recipes.get("recipes", {})
	CRAFTING_XP_LEVELS = recipes.get("craftingXpLevels", [])
	CONSUMABLE_PRICES = recipes.get("consumablePrices", {})

	var devices := _load_json("res://data/devices.json")
	DEVICE_XP_LEVELS = devices.get("deviceXpLevels", [])
	DEVICES = devices.get("devices", {})

	ITEMS = _load_json("res://data/items.json")
	VEIN_SECURITY = _load_json("res://data/vein_security.json")

	var home := _load_json("res://data/home.json")
	HOME_TIER_ORDER = home.get("tierOrder", [])
	HOME_TIERS = home.get("tiers", {})
	HOME_SECURITY = home.get("security", {})
	HOME_ROOMS = home.get("rooms", {})

	FACTIONS = _load_json("res://data/factions.json")

	DISTRICTS = _load_json("res://data/districts.json")

	var sites := _load_json("res://data/sites.json")
	SITE_TIER_ORDER = sites.get("tierOrder", [])
	SITE_TIER_WEIGHTS = sites.get("tierWeights", {})
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
	_validate_vein_levels(t.get("vein_levels", {}), t.get("cultivating_xp_levels", []), errors)
	_validate_recipes(t.get("recipes", {}), t.get("ore_types", {}), errors)
	_validate_devices(t.get("devices", {}), t.get("recipes", {}), t.get("ore_types", {}), errors)
	_validate_items(t.get("items", {}), errors)
	_validate_vein_security(t.get("vein_security", {}), errors)
	_validate_home(t.get("home_tier_order", []), t.get("home_tiers", {}), t.get("home_security", {}), t.get("home_rooms", {}), errors)
	_validate_factions(t.get("factions", {}), errors)
	_validate_districts(t.get("districts", {}), t.get("ore_types", {}), errors)
	_validate_sites(t.get("site_tier_order", []), t.get("site_tier_weights", {}), t.get("site_prospect_xp", {}), t.get("site_seed_tier_mod", {}), t.get("site_discovery_bonus_pool", []), errors)
	_validate_barometer(t.get("barometer_states", {}), t.get("barometer_actions", []), t.get("faction_prefs", {}), t.get("factions", {}), errors)
	_validate_enemies(t.get("enemy_raid_guards", {}), t.get("enemy_home_raid_raider", {}), errors)
	_validate_constants(t.get("time_blocks", []), t.get("contacts_defaults", {}), errors)
	_validate_events(t.get("events", {}), errors)
	_validate_sms(t.get("sms_threads", {}), errors)

	return errors


# Public snapshot of every loaded table, keyed for validate_tables().
# Tests use this to build a deliberately corrupted copy without touching
# the real data/*.json files.
func snapshot() -> Dictionary:
	return {
		"ore_types": ORE_TYPES,
		"vein_levels": VEIN_LEVELS,
		"cultivating_xp_levels": CULTIVATING_XP_LEVELS,
		"recipes": RECIPES,
		"devices": DEVICES,
		"items": ITEMS,
		"vein_security": VEIN_SECURITY,
		"home_tier_order": HOME_TIER_ORDER,
		"home_tiers": HOME_TIERS,
		"home_security": HOME_SECURITY,
		"home_rooms": HOME_ROOMS,
		"factions": FACTIONS,
		"districts": DISTRICTS,
		"site_tier_order": SITE_TIER_ORDER,
		"site_tier_weights": SITE_TIER_WEIGHTS,
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


func _validate_vein_levels(levels: Dictionary, xp_levels: Array, errors: Array[String]) -> void:
	for lvl in ["1", "2", "3", "4", "5"]:
		if not levels.has(lvl):
			errors.append("vein_levels: missing level '%s'" % lvl)
			continue
		var entry = levels[lvl]
		_require_keys(entry, ["label", "yieldCautious", "yieldFull", "rechargeBlocks", "devBarMax", "devBarHarvestCost"], "vein_levels.%s" % lvl, errors)
		if entry.has("yieldCautious") and entry["yieldCautious"].size() != 2:
			errors.append("vein_levels.%s: yieldCautious must be [min,max]" % lvl)
		if entry.has("yieldFull") and entry["yieldFull"].size() != 2:
			errors.append("vein_levels.%s: yieldFull must be [min,max]" % lvl)
	if xp_levels.size() != 6:
		errors.append("cultivatingXpLevels: expected 6 entries (index=level, 0..5), got %d" % xp_levels.size())


func _validate_recipes(recipes: Dictionary, ore_types: Dictionary, errors: Array[String]) -> void:
	for key in recipes.keys():
		var entry = recipes[key]
		_require_keys(entry, ["name", "symbol", "ingredient", "baseSuccess", "baseCalcCost", "effectPower", "xpReward", "eventUsable", "description"], "recipes.%s" % key, errors)
		if entry.has("ingredient") and not ore_types.has(entry["ingredient"]):
			errors.append("recipes.%s: ingredient '%s' is not a known ore type" % [key, entry["ingredient"]])
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


func _validate_home(tier_order: Array, tiers: Dictionary, security: Dictionary, rooms: Dictionary, errors: Array[String]) -> void:
	if tier_order.size() != tiers.size():
		errors.append("home: tierOrder size (%d) does not match tiers size (%d)" % [tier_order.size(), tiers.size()])
	for id in tier_order:
		if not tiers.has(id):
			errors.append("home: tierOrder references unknown tier '%s'" % id)
	for key in tiers.keys():
		_require_keys(tiers[key], ["id", "name", "tier", "upgradeCost", "dailyCost", "raidBaseChance", "maxSecuritySlots", "maxRooms", "description"], "home.tiers.%s" % key, errors)

	for key in security.keys():
		_require_keys(security[key], ["id", "name", "cost", "raidReduction", "description"], "home.security.%s" % key, errors)

	for key in rooms.keys():
		var entry = rooms[key]
		_require_keys(entry, ["id", "name", "cost", "minTier", "bonus", "bonusValue", "description"], "home.rooms.%s" % key, errors)
		if entry.has("minTier") and not tiers.has(entry["minTier"]):
			errors.append("home.rooms.%s: minTier '%s' is not a known home tier" % [key, entry["minTier"]])


func _validate_factions(factions: Dictionary, errors: Array[String]) -> void:
	for key in ["collective", "firm", "guild", "network", "conclave"]:
		if not factions.has(key):
			errors.append("factions: missing faction '%s'" % key)
			continue
		_require_keys(factions[key], ["id", "name", "shortName", "tagline", "industries", "description", "colour", "joinRelation"], "factions.%s" % key, errors)


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


const CANONICAL_SITE_TIERS: Array[String] = ["barren", "poor", "fair", "rich", "saturated"]
const CANONICAL_SITE_BONUSES: Array[String] = ["recharge", "maxLevel", "yield"]


func _validate_sites(tier_order: Array, tier_weights: Dictionary, prospect_xp: Dictionary, seed_tier_mod: Dictionary, discovery_bonus_pool: Array, errors: Array[String]) -> void:
	if tier_order != CANONICAL_SITE_TIERS:
		errors.append("sites: tierOrder must be exactly %s, got %s" % [CANONICAL_SITE_TIERS, tier_order])
	for tier in CANONICAL_SITE_TIERS:
		if not tier_weights.has(tier):
			errors.append("sites: tierWeights missing tier '%s'" % tier)
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
	for key in ["archie", "james"]:
		if not contacts_defaults.has(key):
			errors.append("constants: contacts is missing '%s'" % key)
			continue
		_require_keys(contacts_defaults[key], ["startRelation", "unlocked", "recruitThreshold"], "constants.contacts.%s" % key, errors)


const VALID_CARD_TYPES: Array[String] = ["narration", "speaker", "tension", "resolution", "craft", "choice"]
const VALID_EFFECT_OPS: Array[String] = [
	"set_flag", "add", "add_ore", "add_item", "relation", "grant_vein",
	"set_screen", "notify", "set_stage", "start_home_raid_combat",
]


func _validate_events(events: Dictionary, errors: Array[String]) -> void:
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
		for effect in entry.get("on_complete", []):
			_require_keys(effect, ["op"], "events.%s.on_complete" % key, errors)
			if effect.has("op") and not VALID_EFFECT_OPS.has(effect["op"]):
				errors.append("events.%s: unknown effect op '%s'" % [key, effect["op"]])
		if entry.has("deck"):
			_validate_deck_entry(entry["deck"], "events.%s.deck" % key, errors)
			if not DISTRICT_EVENT_IDS.has(key):
				errors.append("events.%s: has a 'deck' sub-object but is not registered in GameData.DISTRICT_EVENT_IDS — it would silently join the district-deck draw pool" % key)

	for expected_id in DISTRICT_EVENT_IDS:
		if events.has(expected_id) and not events[expected_id].has("deck"):
			errors.append("events.%s: registered in GameData.DISTRICT_EVENT_IDS but missing its 'deck' sub-object" % expected_id)


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
		for effect in choice.get("effects", []):
			_require_keys(effect, ["op"], "%s.choices.effects" % context, errors)
			if effect.has("op") and not VALID_EFFECT_OPS.has(effect["op"]):
				errors.append("%s.choices: unknown effect op '%s'" % [context, effect["op"]])


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
# (contacts defaults, event effect templates like grant_vein, etc.) gets
# read into GameState's pure state tree, where int vs. float is load-
# bearing (deep-equality save/load checks, and dict lookups that str()
# a vein level to key into VEIN_LEVELS — "1.0" isn't "1"). Rather than
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

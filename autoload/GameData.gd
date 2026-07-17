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
	for event_id in EVENT_IDS:
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


func _validate_barometer(states: Dictionary, actions: Array, faction_prefs: Dictionary, factions: Dictionary, errors: Array[String]) -> void:
	for section in ["economic", "social", "political"]:
		if not states.has(section):
			errors.append("barometer: missing section '%s'" % section)
			continue
		for state_id in states[section].keys():
			_require_keys(states[section][state_id], ["id", "label", "description", "effects"], "barometer.%s.%s" % [section, state_id], errors)

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


const VALID_CARD_TYPES: Array[String] = ["narration", "speaker", "tension", "resolution", "craft"]
const VALID_EFFECT_OPS: Array[String] = [
	"set_flag", "add", "add_ore", "add_item", "relation", "grant_vein",
	"set_screen", "notify", "set_stage", "start_home_raid_combat",
]


func _validate_events(events: Dictionary, errors: Array[String]) -> void:
	for expected_id in EVENT_IDS:
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
		for effect in entry.get("on_complete", []):
			_require_keys(effect, ["op"], "events.%s.on_complete" % key, errors)
			if effect.has("op") and not VALID_EFFECT_OPS.has(effect["op"]):
				errors.append("events.%s: unknown effect op '%s'" % [key, effect["op"]])


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
	return parsed

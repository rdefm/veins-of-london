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
var OFFER_TEMPLATES: Dictionary = {}

# Same shape as CULTIVATING_XP_LEVELS/CRAFTING_XP_LEVELS -- lives in
# home.json since Sales is gated by the Operations Room defined there.
var SALES_XP_LEVELS: Array = []

# data/dial.json (R§1.4): Dial.attempt_seed()'s cost/chance inputs and
# cosmetic haft whitelist. *_BY_LEVEL/*_BY_TIER below index level/tier 0..5.
var DIAL_SEED_COST: Dictionary = {}
var DIAL_SEED_BASE_SUCCESS: float = 0.0
var DIAL_HAFTS: Dictionary = {}

# Charge-pool baseline Dial._charge_stats_for() starts from before applying
# the seated Movement's per-archetype bonus/downside curve.
var DIAL_BASE_MAX_CHARGE: int = 0
var DIAL_BASE_RECHARGE_RATE: float = 0.0

# Tier-5 Recharge Movement's regen: Dial.combat_turn_tick() adds this every
# N player turns while seated, independent of Dial.daily_regen()'s rechargeRate.
var DIAL_RECHARGE_COMBAT_REGEN_TURNS: int = 0
var DIAL_RECHARGE_COMBAT_REGEN_AMOUNT: int = 0

# "movements" table (per-archetype baseSuccess/ingredientBase/xpReward,
# tier-indexed bonus/downside/windingCostPerCharge) + shared attunement bonus.
var DIAL_MOVEMENTS: Dictionary = {}
var DIAL_ATTUNEMENT_BONUS_BY_TIER: Array = []

# Dial.capacity_max()'s lookup, independent of which Movement is seated.
var DIAL_CAPACITY_BY_LEVEL: Array = []

# Dial's level ladder. maxChargeBonusByLevel is the primary per-level curve
# on top of the seated Movement's stats; rechargeRateBonusByLevel is
# sparser -- bigger reserve now, faster refill later.
var DIAL_XP_LEVELS: Array = []
var DIAL_MAX_CHARGE_BONUS_BY_LEVEL: Array = []
var DIAL_RECHARGE_RATE_BONUS_BY_LEVEL: Array = []

var ITEMS: Dictionary = {}

var VEIN_SECURITY: Dictionary = {}

# "alarm/cameras" upgrade, independent of VEIN_SECURITY's tier ladder --
# purchased ids land in a vein's "alarmUpgrades" array, mirroring how
# HOME_SECURITY's ids land in state.home["security"].
var VEIN_ALARM: Dictionary = {}

# Third skill, same progression shape as CULTIVATING_XP_LEVELS/
# CRAFTING_XP_LEVELS. Own file since it's not tier-keyed content.
var STEALTH_XP_LEVELS: Array = []

var HOME_TIER_ORDER: Array = []
var HOME_TIERS: Dictionary = {}
var HOME_SECURITY: Dictionary = {}
var HOME_ROOMS: Dictionary = {}
# Daily bill constants (ADR 0006): utilities formula, arrears interest and thresholds.
var HOME_BILLS: Dictionary = {}
# Per-tier floorplan geometry, keyed by home tier id; tiers without a plan are absent.
var FLOORPLANS: Dictionary = {}

var APPROACHES: Dictionary = {}

var FACTIONS: Dictionary = {}

# Per-faction trade lane config, read by Economy.get_faction_*.
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

# Bounded solo combat prototype's teaching roster (systems/
# combat_prototype.gd) -- prototype-only, not production balance. Own
# table so a validation/balance pass over the real roster skips it.
var COMBAT_PROTOTYPE: Dictionary = {}

# Player Combat Skill curves (R§3.7a), colocated in data/enemies.json
# rather than a new file of their own.
var COMBAT_XP_LEVELS: Array = []
var COMBAT_ATTACK_BONUS_BY_LEVEL: Array = []
var COMBAT_SPEED_BY_LEVEL: Array = []

# data/combat_visuals.json (docs/combat-animation-vision.md §2.1/§6):
# "backdrops" -- context id -> { image, fallbackColor (PALETTE key) }.
# "locationBackdrops" -- combat.locationKey -> { image }, checked first.
# "templates" -- per-subject idle sheets + shared "default" hurt/dead/
# attack stand-in; unvalidated below (shape not finalised).
var COMBAT_VISUALS: Dictionary = {}

# data/palette.json (docs/ART-BIBLE.md §2): colour id -> Color, so any
# screen can resolve a data-declared palette key without hardcoding hex.
# Not its own validate_tables() subject -- cross-referenced by
# _validate_combat_visuals() below instead.
var PALETTE: Dictionary = {}

# Fixed, presentation-only simulated-phone home configuration. This never
# enters GameState and never consults host time, battery, or network state.
var PHONE_HOME: Dictionary = {}

# data/map_palette.json (M1.5 §Map palette): "light"/"dark" token -> hex
# string sets with identical keys, plus "darkOverrides" per faction/ore id.
# Resolved to Color by scenes/components/map_palette.gd.
var MAP_PALETTE: Dictionary = {}

# data/hq_visuals.json (docs/hq-diorama-vision.md §9): "rooms" table --
# room-plate id -> { image, fallbackColor, width, height, regions: { zone
# id -> {x,y,width,height,label,image} } }, read generically by
# hq_diorama.gd (no hardcoded room/zone roster).
var HQ_VISUALS: Dictionary = {}

var TIME_BLOCKS: Array = []
var DAY_CLOCK: Dictionary = {}
var DAILY_CYCLE: Dictionary = {}
var ARCHIE_ORE_GOAL: int = 0
var CONTACTS_DEFAULTS: Dictionary = {}
var JAMES_JOB_TRUST_BANDS: Array = []

# Missed-defend guard-repel chance, shared by Home._guards_repel_pending_
# raid() (HQ's guardCount) and Raiding._guards_repel_defend_raid() (a
# vein's extraGuards) -- one data source so retuning skips both .gd files.
var GUARD_REPEL_CHANCE_PER_GUARD: float = 0.0
var GUARD_REPEL_CHANCE_CAP: float = 0.0

# Cultivating XP a staffed cultivator earns per block action (prune or
# cultivate roll, success or fail), R§3.10.
var CULTIVATOR_ACTION_XP: int = 0

# Days of staff production kept in state.productionLog, R§2.
var PRODUCTION_LOG_DAYS: int = 0

# Business pot payday cadence (days) and weekly wage per waged staff
# contact id, R§3.10 "Business pot and payday".
var BUSINESS_PAYDAY_INTERVAL_DAYS: int = 0
var BUSINESS_WEEKLY_WAGES: Dictionary = {}
var BUSINESS_JAMES_JOIN_CRAFTING_SKILL: int = 0
var BUSINESS_OWEN_CRAFT_MIN_CULTIVATING: int = 0

# Loaded by _list_event_ids() from every *.json file under data/events/ --
# no id roster to keep in sync; drop a file in, it's discovered on next
# boot. Deck membership (M1-LONDON D5) is decided per file by a "deck"
# sub-object, not a separate list.
var EVENTS: Dictionary = {}

# Per-vendor flavour lines on completing a Collective trade (systems/
# collective.gd) -- cosmetic only, all three doors trade at identical
# terms. Keyed by contact id.
var COLLECTIVE_BARKS: Dictionary = {}

# data/objectives.json, keyed by objective id (systems/objectives.gd).
# "questline" groups an entry for todo.gd's ToDo-app rendering: the
# tutorial's flag chain and Collective's Act 1 threads are both just
# objectives, distinguished only by questline.
var OBJECTIVES: Dictionary = {}

var loaded := false
var _load_errors: Array[String] = []
var _errors: Array[String] = []


func _ready() -> void:
	load_all()
	validate()


# Declarative load table: one entry per data/*.json table, each field
# naming the JSON key to pull ("" for the file's own root) and the Variant
# type it must be. load_all() is the single loop reading every table once,
# type-checking and assigning each field, so a new field never needs its
# own extraction line. "snapshot" overrides the key snapshot() files a
# field under (FACTION_BAROMETER_PREFS's non-default snapshot key).
# PALETTE/EVENTS are genuine transforms (a directory scan, not a file/
# key/type row) so _load_palette()/_load_events() stay bespoke, mirrored
# as fixed extra lines in snapshot() too.
const MANIFEST: Array[Dictionary] = [
	{"table": "ore_types", "file": "res://data/ore_types.json", "fields": [
		{"field": "ORE_TYPES", "key": "", "type": TYPE_DICTIONARY},
	]},
	{"table": "vein_growth", "file": "res://data/vein_growth.json", "fields": [
		{"field": "VEIN_GROWTH", "key": "", "type": TYPE_DICTIONARY},
		{"field": "SEED_ORE_COST", "key": "seedOreCost", "type": TYPE_INT},
		{"field": "CULTIVATING_XP_LEVELS", "key": "cultivatingXpLevels", "type": TYPE_ARRAY},
	]},
	{"table": "recipes", "file": "res://data/recipes.json", "fields": [
		{"field": "RECIPES", "key": "recipes", "type": TYPE_DICTIONARY},
		{"field": "CRAFTING_XP_LEVELS", "key": "craftingXpLevels", "type": TYPE_ARRAY},
		{"field": "CONSUMABLE_PRICES", "key": "consumablePrices", "type": TYPE_DICTIONARY},
	]},
	{"table": "offers", "file": "res://data/offers.json", "fields": [
		{"field": "OFFER_TEMPLATES", "key": "templates", "type": TYPE_DICTIONARY},
	]},
	{"table": "dial", "file": "res://data/dial.json", "fields": [
		{"field": "DIAL_SEED_COST", "key": "seedCost", "type": TYPE_DICTIONARY},
		{"field": "DIAL_SEED_BASE_SUCCESS", "key": "seedBaseSuccess", "type": TYPE_FLOAT},
		{"field": "DIAL_BASE_MAX_CHARGE", "key": "baseMaxCharge", "type": TYPE_INT},
		{"field": "DIAL_BASE_RECHARGE_RATE", "key": "baseRechargeRate", "type": TYPE_FLOAT},
		{"field": "DIAL_RECHARGE_COMBAT_REGEN_TURNS", "key": "rechargeCombatRegenEveryTurns", "type": TYPE_INT},
		{"field": "DIAL_RECHARGE_COMBAT_REGEN_AMOUNT", "key": "rechargeCombatRegenAmount", "type": TYPE_INT},
		{"field": "DIAL_HAFTS", "key": "hafts", "type": TYPE_DICTIONARY},
		{"field": "DIAL_MOVEMENTS", "key": "movements", "type": TYPE_DICTIONARY},
		{"field": "DIAL_ATTUNEMENT_BONUS_BY_TIER", "key": "attunementBonusByTier", "type": TYPE_ARRAY},
		{"field": "DIAL_CAPACITY_BY_LEVEL", "key": "capacityByLevel", "type": TYPE_ARRAY},
		{"field": "DIAL_XP_LEVELS", "key": "xpLevels", "type": TYPE_ARRAY},
		{"field": "DIAL_MAX_CHARGE_BONUS_BY_LEVEL", "key": "maxChargeBonusByLevel", "type": TYPE_ARRAY},
		{"field": "DIAL_RECHARGE_RATE_BONUS_BY_LEVEL", "key": "rechargeRateBonusByLevel", "type": TYPE_ARRAY},
	]},
	{"table": "items", "file": "res://data/items.json", "fields": [
		{"field": "ITEMS", "key": "", "type": TYPE_DICTIONARY},
	]},
	{"table": "vein_security", "file": "res://data/vein_security.json", "fields": [
		{"field": "VEIN_SECURITY", "key": "", "type": TYPE_DICTIONARY},
	]},
	{"table": "vein_alarm", "file": "res://data/vein_alarm.json", "fields": [
		{"field": "VEIN_ALARM", "key": "", "type": TYPE_DICTIONARY},
	]},
	{"table": "stealth", "file": "res://data/stealth.json", "fields": [
		{"field": "STEALTH_XP_LEVELS", "key": "stealthXpLevels", "type": TYPE_ARRAY},
	]},
	{"table": "home", "file": "res://data/home.json", "fields": [
		{"field": "HOME_TIER_ORDER", "key": "tierOrder", "type": TYPE_ARRAY},
		{"field": "HOME_TIERS", "key": "tiers", "type": TYPE_DICTIONARY},
		{"field": "HOME_SECURITY", "key": "security", "type": TYPE_DICTIONARY},
		{"field": "HOME_ROOMS", "key": "rooms", "type": TYPE_DICTIONARY},
		{"field": "HOME_BILLS", "key": "bills", "type": TYPE_DICTIONARY},
		{"field": "SALES_XP_LEVELS", "key": "salesXpLevels", "type": TYPE_ARRAY},
	]},
	{"table": "floorplans", "file": "res://data/floorplans.json", "fields": [
		{"field": "FLOORPLANS", "key": "", "type": TYPE_DICTIONARY},
	]},
	{"table": "approaches", "file": "res://data/approaches.json", "fields": [
		{"field": "APPROACHES", "key": "", "type": TYPE_DICTIONARY},
	]},
	{"table": "factions", "file": "res://data/factions.json", "fields": [
		{"field": "FACTIONS", "key": "", "type": TYPE_DICTIONARY},
	]},
	{"table": "faction_trade", "file": "res://data/faction_trade.json", "fields": [
		{"field": "FACTION_TRADE", "key": "", "type": TYPE_DICTIONARY},
	]},
	{"table": "districts", "file": "res://data/districts.json", "fields": [
		{"field": "DISTRICTS", "key": "", "type": TYPE_DICTIONARY},
	]},
	{"table": "map_layout", "file": "res://data/map_layout.json", "fields": [
		{"field": "MAP_LAYOUT", "key": "", "type": TYPE_DICTIONARY},
	]},
	{"table": "sites", "file": "res://data/sites.json", "fields": [
		{"field": "SITE_TIER_ORDER", "key": "tierOrder", "type": TYPE_ARRAY},
		{"field": "SITE_TIER_WEIGHTS", "key": "tierWeights", "type": TYPE_DICTIONARY},
		{"field": "SITE_AT_CAP_TIER_WEIGHTS", "key": "atCapTierWeights", "type": TYPE_DICTIONARY},
		{"field": "SITE_PROSPECT_XP", "key": "prospectXp", "type": TYPE_DICTIONARY},
		{"field": "SITE_SEED_TIER_MOD", "key": "seedTierMod", "type": TYPE_DICTIONARY},
		{"field": "SITE_DISCOVERY_BONUS_POOL", "key": "discoveryBonusPool", "type": TYPE_ARRAY},
		{"field": "SITE_NATURAL_VEIN_CHANCE", "key": "naturalVeinChance", "type": TYPE_FLOAT},
	]},
	{"table": "barometer", "file": "res://data/barometer.json", "fields": [
		{"field": "BAROMETER_STATES", "key": "states", "type": TYPE_DICTIONARY},
		{"field": "BAROMETER_ACTIONS", "key": "actions", "type": TYPE_ARRAY},
		{"field": "FACTION_BAROMETER_PREFS", "key": "factionPrefs", "type": TYPE_DICTIONARY, "snapshot": "faction_prefs"},
	]},
	{"table": "enemies", "file": "res://data/enemies.json", "fields": [
		{"field": "ENEMY_RAID_GUARDS", "key": "raidGuards", "type": TYPE_DICTIONARY},
		{"field": "ENEMY_HOME_RAID_RAIDER", "key": "homeRaidRaider", "type": TYPE_DICTIONARY},
		{"field": "COMBAT_XP_LEVELS", "key": "combatXpLevels", "type": TYPE_ARRAY},
		{"field": "COMBAT_ATTACK_BONUS_BY_LEVEL", "key": "combatAttackBonusByLevel", "type": TYPE_ARRAY},
		{"field": "COMBAT_SPEED_BY_LEVEL", "key": "combatSpeedByLevel", "type": TYPE_ARRAY},
	]},
	{"table": "combat_prototype", "file": "res://data/combat_prototype.json", "fields": [
		{"field": "COMBAT_PROTOTYPE", "key": "", "type": TYPE_DICTIONARY},
	]},
	{"table": "combat_visuals", "file": "res://data/combat_visuals.json", "fields": [
		{"field": "COMBAT_VISUALS", "key": "", "type": TYPE_DICTIONARY},
	]},
	{"table": "hq_visuals", "file": "res://data/hq_visuals.json", "fields": [
		{"field": "HQ_VISUALS", "key": "", "type": TYPE_DICTIONARY},
	]},
	{"table": "constants", "file": "res://data/constants.json", "fields": [
		{"field": "TIME_BLOCKS", "key": "timeBlocks", "type": TYPE_ARRAY},
		{"field": "DAY_CLOCK", "key": "dayClock", "type": TYPE_DICTIONARY},
		{"field": "ARCHIE_ORE_GOAL", "key": "archieOreGoal", "type": TYPE_INT},
		{"field": "CONTACTS_DEFAULTS", "key": "contacts", "type": TYPE_DICTIONARY},
		{"field": "JAMES_JOB_TRUST_BANDS", "key": "jamesJobTrustBands", "type": TYPE_ARRAY},
		{"field": "GUARD_REPEL_CHANCE_PER_GUARD", "key": "guardRepel.chancePerGuard", "type": TYPE_FLOAT},
		{"field": "GUARD_REPEL_CHANCE_CAP", "key": "guardRepel.cap", "type": TYPE_FLOAT},
		{"field": "CULTIVATOR_ACTION_XP", "key": "cultivatorActionXp", "type": TYPE_INT},
		{"field": "PRODUCTION_LOG_DAYS", "key": "productionLogDays", "type": TYPE_INT},
		{"field": "BUSINESS_PAYDAY_INTERVAL_DAYS", "key": "business.paydayIntervalDays", "type": TYPE_INT},
		{"field": "BUSINESS_WEEKLY_WAGES", "key": "business.weeklyWages", "type": TYPE_DICTIONARY},
		{"field": "BUSINESS_JAMES_JOIN_CRAFTING_SKILL", "key": "business.jamesJoinCraftingSkill", "type": TYPE_INT},
		{"field": "BUSINESS_OWEN_CRAFT_MIN_CULTIVATING", "key": "business.owenCraftMinCultivating", "type": TYPE_INT},
	]},
	{"table": "daily_cycle", "file": "res://data/daily_cycle.json", "fields": [
		{"field": "DAILY_CYCLE", "key": "", "type": TYPE_DICTIONARY},
	]},
	{"table": "objectives", "file": "res://data/objectives.json", "fields": [
		{"field": "OBJECTIVES", "key": "", "type": TYPE_DICTIONARY},
	]},
	{"table": "collective_barks", "file": "res://data/collective_barks.json", "fields": [
		{"field": "COLLECTIVE_BARKS", "key": "", "type": TYPE_DICTIONARY},
	]},
	{"table": "map_palette", "file": "res://data/map_palette.json", "fields": [
		{"field": "MAP_PALETTE", "key": "", "type": TYPE_DICTIONARY},
	]},
	{"table": "phone_home", "file": "res://data/phone_home.json", "fields": [
		{"field": "PHONE_HOME", "key": "", "type": TYPE_DICTIONARY},
	]},
]


func load_all() -> void:
	for group in MANIFEST:
		var parsed: Dictionary = _load_json(group["file"], group["table"])
		for field_entry in group["fields"]:
			set(field_entry["field"], _resolve_manifest_value(parsed, field_entry, group["table"], _load_errors))

	_load_palette()
	_load_events()

	loaded = true


# Pure: extracts and type-checks one manifest field out of its table's
# parsed file dict. A missing key falls back to the type's default --
# only a type mismatch is an error, since load_all() already logged a
# "missing data file" error if the read failed.
func _resolve_manifest_value(parsed: Dictionary, field_entry: Dictionary, table: String, errors: Array[String]) -> Variant:
	var key: String = field_entry.get("key", "")
	var expected_type: int = field_entry["type"]
	var value: Variant = parsed if key.is_empty() else _dig(parsed, key)
	if value == null:
		return _default_for_type(expected_type)
	# _normalize_numbers() turns any whole-number JSON float (e.g.
	# "baseRechargeRate": 2.0) into an int -- a float field reading one
	# is not a data mistake, just ordinary int->float widening.
	if expected_type == TYPE_FLOAT and typeof(value) == TYPE_INT:
		return float(value)
	if typeof(value) != expected_type:
		errors.append("%s.%s: expected %s at key '%s', got %s" % [table, field_entry["field"], type_string(expected_type), key, type_string(typeof(value))])
		return _default_for_type(expected_type)
	return value


func _default_for_type(type: int) -> Variant:
	match type:
		TYPE_DICTIONARY:
			return {}
		TYPE_ARRAY:
			return []
		TYPE_FLOAT:
			return 0.0
		_:
			return 0


# Dot-path lookup into a parsed JSON dict (e.g. "guardRepel.chancePerGuard").
# Returns null on any missing segment, same contract as Dictionary.get().
func _dig(dict: Dictionary, dotted_key: String) -> Variant:
	var current: Variant = dict
	for part in dotted_key.split("."):
		if typeof(current) != TYPE_DICTIONARY or not current.has(part):
			return null
		current = current[part]
	return current


# Bespoke: data/palette.json is an array of {id, hex} entries, not a
# file/key/type row -- becomes an id -> Color dict.
func _load_palette() -> void:
	PALETTE = {}
	for entry in _load_json("res://data/palette.json", "palette").get("colors", []):
		var id: String = entry.get("id", "")
		if not id.is_empty() and entry.has("hex"):
			PALETTE[id] = Color(entry["hex"])


# Bespoke: loaded by _list_event_ids() from every *.json file under
# data/events/; discovered on next boot, no id roster to keep in sync.
func _load_events() -> void:
	EVENTS = {}
	for event_id in _list_event_ids():
		var event_def := _load_json("res://data/events/%s.json" % event_id, "events.%s" % event_id)
		if not event_def.is_empty():
			EVENTS[event_id] = event_def


func validate() -> bool:
	_errors = _load_errors + validate_tables(snapshot())
	return _errors.is_empty()


func get_errors() -> Array[String]:
	return _errors


# Pure validation over a snapshot()-shaped table dict. Kept separate from
# validate() so tests can feed it a deliberately corrupted copy.
func validate_tables(t: Dictionary) -> Array[String]:
	var errors: Array[String] = []

	_validate_ore_types(t.get("ore_types", {}), errors)
	_validate_vein_growth(t.get("vein_growth", {}), t.get("cultivating_xp_levels", []), errors)
	_validate_recipes(t.get("recipes", {}), t.get("ore_types", {}), errors)
	_validate_dial(t, errors)
	_validate_items(t.get("items", {}), errors)
	_validate_vein_security(t.get("vein_security", {}), errors)
	_validate_vein_alarm(t.get("vein_alarm", {}), errors)
	_validate_stealth(t.get("stealth_xp_levels", []), errors)
	_validate_home(t.get("home_tier_order", []), t.get("home_tiers", {}), t.get("home_security", {}), t.get("home_rooms", {}), errors)
	_validate_home_bills(t.get("home_bills", {}), t.get("home_tiers", {}), errors)
	_validate_approaches(t.get("approaches", {}), t.get("home_rooms", {}), errors)
	_validate_factions(t.get("factions", {}), errors)
	_validate_faction_trade(t.get("faction_trade", {}), errors)
	_validate_districts(t.get("districts", {}), t.get("ore_types", {}), errors)
	_validate_map_layout(t.get("map_layout", {}), t.get("districts", {}), errors)
	_validate_sites(t, errors)
	_validate_barometer(t.get("barometer_states", {}), t.get("barometer_actions", []), t.get("faction_prefs", {}), t.get("factions", {}), errors)
	_validate_enemies(t, errors)
	_validate_combat_prototype(t.get("combat_prototype", {}), errors)
	_validate_combat_visuals(t.get("combat_visuals", {}), t.get("palette", {}), errors)
	_validate_hq_visuals(t.get("hq_visuals", {}), t.get("palette", {}), errors)
	_validate_constants(t.get("time_blocks", []), t.get("contacts_defaults", {}), errors)
	_validate_events(t.get("events", {}), t.get("districts", {}), errors)
	_validate_objectives(t.get("objectives", {}), t.get("factions", {}), t.get("ore_types", {}), t.get("site_tier_order", []), t.get("recipes", {}), errors)
	_validate_collective_barks(t.get("collective_barks", {}), errors)
	_validate_phone_home(t.get("phone_home", {}), errors)
	_validate_map_palette(t.get("map_palette", {}), t.get("factions", {}), t.get("ore_types", {}), errors)

	return errors


# The drawer toggle's label is set; every token is a valid colour string and light/dark carry identical keys;
# darkOverrides may only name real faction/ore ids.
func _validate_map_palette(map_palette: Dictionary, factions: Dictionary, ore_types: Dictionary, errors: Array[String]) -> void:
	_require_keys(map_palette, ["darkModeLabel", "light", "dark", "darkOverrides"], "map_palette", errors)
	var label: Variant = map_palette.get("darkModeLabel")
	if map_palette.has("darkModeLabel") and (typeof(label) != TYPE_STRING or String(label).is_empty()):
		errors.append("map_palette.darkModeLabel: must be a non-empty string")
	var light: Dictionary = map_palette.get("light", {})
	var dark: Dictionary = map_palette.get("dark", {})
	if light.is_empty():
		errors.append("map_palette.light: must define at least one token")
	for key in light:
		if not dark.has(key):
			errors.append("map_palette.dark: missing token '%s' present in light" % key)
	for key in dark:
		if not light.has(key):
			errors.append("map_palette.light: missing token '%s' present in dark" % key)
	for set_name in ["light", "dark"]:
		var tokens: Dictionary = map_palette.get(set_name, {})
		for key in tokens:
			_validate_colour_string(tokens[key], "map_palette.%s.%s" % [set_name, key], errors)
	var overrides: Dictionary = map_palette.get("darkOverrides", {})
	for group in [["factions", factions], ["oreTypes", ore_types]]:
		var entries: Dictionary = overrides.get(group[0], {})
		for id in entries:
			if not group[1].has(id):
				errors.append("map_palette.darkOverrides.%s: '%s' is not a known id" % [group[0], id])
			_validate_colour_string(entries[id], "map_palette.darkOverrides.%s.%s" % [group[0], id], errors)


func _validate_colour_string(value: Variant, context: String, errors: Array[String]) -> void:
	if typeof(value) != TYPE_STRING or not Color.html_is_valid(value):
		errors.append("%s: '%s' is not a valid colour" % [context, str(value)])


func _validate_phone_home(phone_home: Dictionary, errors: Array[String]) -> void:
	_require_keys(phone_home, ["wallpaper", "status", "widget"], "phone_home", errors)
	var wallpaper: String = phone_home.get("wallpaper", "")
	if wallpaper != "res://assets/phone/phone-wallpaper.jpg":
		errors.append("phone_home.wallpaper: must reference the approved assets/phone/phone-wallpaper.jpg")
	elif not FileAccess.file_exists(wallpaper):
		errors.append("phone_home.wallpaper: approved asset does not exist")
	var status: Dictionary = phone_home.get("status", {})
	_require_keys(status, ["time", "cellular", "wifi", "batteryGlyph", "batteryPercent"], "phone_home.status", errors)
	_require_exact_values(status, {"time": "08:14", "cellular": "▂▄▆█", "wifi": "⌁", "batteryGlyph": "▰", "batteryPercent": "87%"}, "phone_home.status", errors)
	var widget: Dictionary = phone_home.get("widget", {})
	_require_keys(widget, ["date", "weather", "temperature", "location", "flavour"], "phone_home.widget", errors)
	_require_exact_values(widget, {"date": "Tue, 14 May", "weather": "☁", "temperature": "12°C", "location": "London", "flavour": "Same city. Different rules."}, "phone_home.widget", errors)


func _require_exact_values(actual: Dictionary, expected: Dictionary, context: String, errors: Array[String]) -> void:
	for key in expected:
		if actual.get(key) != expected[key]:
			errors.append("%s.%s: expected fixed presentation value '%s'" % [context, key, expected[key]])


# Public snapshot of every loaded table, keyed for validate_tables().
# Derived from MANIFEST (each field's key is its var name lowercased, or
# its "snapshot" override) so loading and snapshotting can't drift apart --
# PALETTE/EVENTS are the same bespoke exceptions added by hand.
func snapshot() -> Dictionary:
	var result: Dictionary = {}
	for group in MANIFEST:
		for field_entry in group["fields"]:
			var snapshot_key: String = field_entry.get("snapshot", String(field_entry["field"]).to_lower())
			result[snapshot_key] = get(field_entry["field"])
	result["palette"] = PALETTE
	result["events"] = EVENTS
	return result


# ── per-table checks ──────────────────────────────────────────────────

const CANONICAL_ORE_TYPES: Array[String] = ["time", "physics", "life", "fate", "emotion"]

# v1 launch set of four Movement archetypes (R§1.4); Dial.MOVEMENT_ARCHETYPES mirrors this.
const CANONICAL_MOVEMENT_ARCHETYPES: Array[String] = ["recharge", "capacitor", "impact", "spread"]


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
		"pruneLightDepth", "pruneHardDepth", "cultivateGainMinOffset", "cultivateGainMaxOffset",
		"collapseChancePerDay", "seedGrowth", "rampantSeedDays", "selfSeedGrowth", "terroirYieldMult",
		"levelCapByTerroir", "driftRandomMin", "driftRandomMax",
	], "vein_growth", errors)

	if xp_levels.size() != 6:
		errors.append("cultivatingXpLevels: expected 6 entries (index=level, 0..5), got %d" % xp_levels.size())

	if not vein_growth.has("bands"):
		return
	var bands: Array = vein_growth["bands"]
	var sorted_bands: Array = bands.duplicate()
	sorted_bands.sort_custom(func(a, b): return a["min"] < b["min"])

	if sorted_bands.is_empty():
		errors.append("vein_growth.bands: must not be empty")
		return
	if sorted_bands[0]["min"] != 0:
		errors.append("vein_growth.bands: must start at growth 0")

	for i in range(sorted_bands.size()):
		_require_keys(sorted_bands[i], ["id", "min", "max", "label"], "vein_growth.bands[%d]" % i, errors)
		if i > 0 and sorted_bands[i - 1]["max"] + 1 != sorted_bands[i]["min"]:
			errors.append("vein_growth.bands: gap or overlap between '%s' and '%s'" % [sorted_bands[i - 1].get("id"), sorted_bands[i].get("id")])

	if sorted_bands[-1]["max"] < 100:
		errors.append("vein_growth.bands: must cover through growth 100")


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


# seedCost must cover every canonical ore type (R§1.4's mixed five-ore-type
# cost) -- a partial cost here would silently let seeding skip an ore type.
# Hafts are cosmetic-only (no stat fields), so each only needs a display
# name, not the fuller schema recipes/movements use.
func _validate_dial(t: Dictionary, errors: Array[String]) -> void:
	var seed_cost: Dictionary = t.get("dial_seed_cost", {})
	var seed_base_success: float = t.get("dial_seed_base_success", 0.0)
	var base_max_charge: int = t.get("dial_base_max_charge", 0)
	var base_recharge_rate: float = t.get("dial_base_recharge_rate", 0.0)
	var recharge_combat_regen_turns: int = t.get("dial_recharge_combat_regen_turns", 0)
	var recharge_combat_regen_amount: int = t.get("dial_recharge_combat_regen_amount", 0)
	var hafts: Dictionary = t.get("dial_hafts", {})
	var movements: Dictionary = t.get("dial_movements", {})
	var attunement_bonus_by_tier: Array = t.get("dial_attunement_bonus_by_tier", [])
	var capacity_by_level: Array = t.get("dial_capacity_by_level", [])
	var xp_levels: Array = t.get("dial_xp_levels", [])
	var max_charge_bonus_by_level: Array = t.get("dial_max_charge_bonus_by_level", [])
	var recharge_rate_bonus_by_level: Array = t.get("dial_recharge_rate_bonus_by_level", [])

	for ore_key in CANONICAL_ORE_TYPES:
		if not seed_cost.has(ore_key):
			errors.append("dial.seedCost: missing canonical ore type '%s'" % ore_key)
	for ore_key in seed_cost.keys():
		if not CANONICAL_ORE_TYPES.has(ore_key):
			errors.append("dial.seedCost: unexpected ore type '%s'" % ore_key)
	if seed_base_success <= 0.0:
		errors.append("dial: seedBaseSuccess must be > 0")
	if base_max_charge <= 0:
		errors.append("dial: baseMaxCharge must be > 0")
	if base_recharge_rate <= 0.0:
		errors.append("dial: baseRechargeRate must be > 0")
	# Dial.combat_turn_tick()'s cadence/amount for tier-5 Recharge regen.
	if recharge_combat_regen_turns <= 0:
		errors.append("dial: rechargeCombatRegenEveryTurns must be > 0")
	if recharge_combat_regen_amount <= 0:
		errors.append("dial: rechargeCombatRegenAmount must be > 0")
	if hafts.is_empty():
		errors.append("dial: hafts must not be empty")
	for key in hafts.keys():
		_require_keys(hafts[key], ["name"], "dial.hafts.%s" % key, errors)

	# Each archetype needs a tier-indexed bonus/downside array (mirrors
	# effectPower's array-of-arrays shape -- index 0 unused, tiers 1-5 real).
	for archetype in CANONICAL_MOVEMENT_ARCHETYPES:
		if not movements.has(archetype):
			errors.append("dial.movements: missing canonical archetype '%s'" % archetype)
			continue
		var entry: Dictionary = movements[archetype]
		_require_keys(entry, ["name", "symbol", "baseSuccess", "ingredientBase", "xpReward", "bonus", "downside", "windingCostPerCharge"], "dial.movements.%s" % archetype, errors)
		if entry.has("bonus") and entry["bonus"].size() != 6:
			errors.append("dial.movements.%s: bonus must have 6 entries (index=tier 0..5)" % archetype)
		if entry.has("downside") and entry["downside"].size() != 6:
			errors.append("dial.movements.%s: downside must have 6 entries (index=tier 0..5)" % archetype)
		if entry.has("windingCostPerCharge") and entry["windingCostPerCharge"].size() != 6:
			errors.append("dial.movements.%s: windingCostPerCharge must have 6 entries (index=tier 0..5)" % archetype)
	for key in movements.keys():
		if not CANONICAL_MOVEMENT_ARCHETYPES.has(key):
			errors.append("dial.movements: unexpected archetype '%s' (not in the PRD's v1 launch set)" % key)

	if attunement_bonus_by_tier.size() != 6:
		errors.append("dial.attunementBonusByTier: expected 6 entries (index=tier 0..5), got %d" % attunement_bonus_by_tier.size())

	if capacity_by_level.size() != 6:
		errors.append("dial.capacityByLevel: expected 6 entries (index=level 0..5), got %d" % capacity_by_level.size())

	# hq_dial.gd's flanking-socket layout hard-codes exactly 4 tile
	# positions with no bounds check of its own -- an edit exceeding 4
	# would silently crash that screen instead of failing loudly here.
	for level_value in capacity_by_level:
		if int(level_value) > 4:
			errors.append("dial.capacityByLevel: entry %s exceeds 4 -- hq_dial.gd's socket layout has only 4 fixed positions" % str(level_value))
			break

	if xp_levels.size() != 6:
		errors.append("dial.xpLevels: expected 6 entries (index=level 0..5), got %d" % xp_levels.size())
	if max_charge_bonus_by_level.size() != 6:
		errors.append("dial.maxChargeBonusByLevel: expected 6 entries (index=level 0..5), got %d" % max_charge_bonus_by_level.size())
	if recharge_rate_bonus_by_level.size() != 6:
		errors.append("dial.rechargeRateBonusByLevel: expected 6 entries (index=level 0..5), got %d" % recharge_rate_bonus_by_level.size())


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
		_require_keys(tiers[key], ["id", "name", "tier", "buyPrice", "rentOnly", "dailyCost", "raidBaseChance", "maxRooms", "description"], "home.tiers.%s" % key, errors)

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


# ADR 0006: the bedsit is rent-only; every other tier has a positive buy price.
func _validate_home_bills(bills: Dictionary, tiers: Dictionary, errors: Array[String]) -> void:
	_require_keys(bills, ["interestRate", "interestThresholdDays", "downgradeThresholdDays"], "home.bills", errors)
	for key in bills.keys():
		var v = bills[key]
		if (typeof(v) != TYPE_INT and typeof(v) != TYPE_FLOAT) or v < 0:
			errors.append("home.bills.%s: expected a non-negative number" % key)
	if tiers.has("bedsit") and tiers["bedsit"].get("rentOnly", false) != true:
		errors.append("home.tiers.bedsit: must be rentOnly")
	for key in tiers.keys():
		var tier: Dictionary = tiers[key]
		if typeof(tier.get("rentOnly")) != TYPE_BOOL:
			errors.append("home.tiers.%s: rentOnly must be a bool" % key)
		elif not tier["rentOnly"] and not (float(tier.get("buyPrice", 0)) > 0.0):
			errors.append("home.tiers.%s: buyable tier needs a positive buyPrice" % key)
		elif not tier["rentOnly"] and not tier.has("ownedDailyCost"):
			errors.append("home.tiers.%s: buyable tier needs an ownedDailyCost" % key)


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


# Every faction with a trade lane (Economy.get_faction_*) needs a row here; only guild and collective have one so far.
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


# data/map_layout.json (docs/M1.5-NETWORK-MAP.md). Cross-references
# districts' siteCap to enforce >= siteCap*2 stopSlots per district: a
# saturated site's two veins can diverge independently (sold/raided/
# collapsed one at a time), so siteCap*2 is the margin that always covers
# any subset of claimed sites being mid-divergence at once.
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
			if stop_slots.size() < site_cap * 2:
				errors.append("map_layout.districts.%s.stopSlots: needs >= siteCap*2 (%d) slots, got %d" % [key, site_cap * 2, stop_slots.size()])

	for key in layout_districts.keys():
		if not CANONICAL_DISTRICT_IDS.has(key):
			errors.append("map_layout.districts: unexpected district '%s' (not in M1-LONDON.md D1)" % key)


const CANONICAL_SITE_TIERS: Array[String] = ["barren", "poor", "fair", "rich", "saturated"]
const CANONICAL_SITE_BONUSES: Array[String] = ["vigour", "wildCeiling", "yield"]


func _validate_sites(t: Dictionary, errors: Array[String]) -> void:
	var tier_order: Array = t.get("site_tier_order", [])
	var tier_weights: Dictionary = t.get("site_tier_weights", {})
	var at_cap_tier_weights: Dictionary = t.get("site_at_cap_tier_weights", {})
	var prospect_xp: Dictionary = t.get("site_prospect_xp", {})
	var seed_tier_mod: Dictionary = t.get("site_seed_tier_mod", {})
	var discovery_bonus_pool: Array = t.get("site_discovery_bonus_pool", [])

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


func _validate_enemies(t: Dictionary, errors: Array[String]) -> void:
	var raid_guards: Dictionary = t.get("enemy_raid_guards", {})
	var home_raid_raider: Dictionary = t.get("enemy_home_raid_raider", {})
	var combat_xp_levels: Array = t.get("combat_xp_levels", [])
	var combat_attack_bonus_by_level: Array = t.get("combat_attack_bonus_by_level", [])
	var combat_speed_by_level: Array = t.get("combat_speed_by_level", [])

	for key in raid_guards.keys():
		_require_keys(raid_guards[key], ["name", "hpBase", "attackMin", "attackMax", "speed"], "enemies.raidGuards.%s" % key, errors)
	_require_keys(home_raid_raider, ["name", "hp", "attackMin", "attackMax", "speed"], "enemies.homeRaidRaider", errors)

	# Same "6 entries, index=level 0..5" shape every skill ladder enforces.
	if combat_xp_levels.size() != 6:
		errors.append("enemies.combatXpLevels: expected 6 entries (index=level, 0..5), got %d" % combat_xp_levels.size())
	if combat_attack_bonus_by_level.size() != 6:
		errors.append("enemies.combatAttackBonusByLevel: expected 6 entries (index=level, 0..5), got %d" % combat_attack_bonus_by_level.size())
	if combat_speed_by_level.size() != 6:
		errors.append("enemies.combatSpeedByLevel: expected 6 entries (index=level, 0..5), got %d" % combat_speed_by_level.size())


# Every encounterOrder id needs a matching flat single-enemy `encounters`
# entry. Any other entry is a squad ('enemies': non-empty array) or a
# multi-wave roster ('waves': non-empty array of non-empty 'enemies'
# arrays) -- never both, never flat.
func _validate_combat_prototype(combat_prototype: Dictionary, errors: Array[String]) -> void:
	var order: Array = combat_prototype.get("encounterOrder", [])
	if order.is_empty():
		errors.append("combat_prototype.encounterOrder: must not be empty")
	var encounters: Dictionary = combat_prototype.get("encounters", {})
	for encounter_id in order:
		if not encounters.has(encounter_id):
			errors.append("combat_prototype.encounters: missing entry for encounterOrder id '%s'" % encounter_id)
			continue
		_validate_combat_prototype_enemy(encounters[encounter_id], "combat_prototype.encounters.%s" % encounter_id, errors)

	for encounter_id in encounters.keys():
		if order.has(encounter_id):
			continue
		var entry: Dictionary = encounters[encounter_id]
		var path: String = "combat_prototype.encounters.%s" % encounter_id
		_require_keys(entry, ["name"], path, errors)
		var has_enemies: bool = entry.has("enemies")
		var has_waves: bool = entry.has("waves")
		if has_enemies and has_waves:
			errors.append("%s: must not set both 'enemies' and 'waves'" % path)
		elif has_enemies:
			var roster: Array = entry.get("enemies", [])
			if roster.is_empty():
				errors.append("%s.enemies: must not be empty" % path)
			for i in range(roster.size()):
				_validate_combat_prototype_enemy(roster[i], "%s.enemies[%d]" % [path, i], errors)
		elif has_waves:
			var waves: Array = entry.get("waves", [])
			if waves.is_empty():
				errors.append("%s.waves: must not be empty" % path)
			for w in range(waves.size()):
				var wave_roster: Array = waves[w]
				if wave_roster.is_empty():
					errors.append("%s.waves[%d]: must not be empty" % [path, w])
				for i in range(wave_roster.size()):
					_validate_combat_prototype_enemy(wave_roster[i], "%s.waves[%d][%d]" % [path, w, i], errors)
		else:
			errors.append("%s: must set either 'enemies' or 'waves' (it's outside encounterOrder, so the flat single-enemy shape doesn't apply)" % path)


func _validate_combat_prototype_enemy(entry: Dictionary, path: String, errors: Array[String]) -> void:
	_require_keys(entry, ["name", "hp", "attackMin", "attackMax", "speed", "script"], path, errors)
	var script: Array = entry.get("script", [])
	if script.is_empty():
		errors.append("%s.script: must not be empty" % path)
	for action in script:
		if not CombatPrototype.SCRIPTABLE_ACTIONS.has(action):
			errors.append("%s.script: unknown action '%s'" % [path, action])


# Every context in Combat.CANONICAL_CONTEXTS must have a backdrop entry.
# An entry needs an image OR a fallbackColor (never neither, or the stage
# renders nothing); fallbackColor must name a real data/palette.json colour id.
func _validate_combat_visuals(combat_visuals: Dictionary, palette: Dictionary, errors: Array[String]) -> void:
	var backdrops: Dictionary = combat_visuals.get("backdrops", {})
	for context in Combat.CANONICAL_CONTEXTS:
		if not backdrops.has(context):
			errors.append("combat_visuals.backdrops: missing entry for canonical context '%s'" % context)
			continue
		var entry: Dictionary = backdrops[context]
		_require_keys(entry, ["image", "fallbackColor"], "combat_visuals.backdrops.%s" % context, errors)
		var image: String = entry.get("image", "")
		var fallback_color: String = entry.get("fallbackColor", "")
		if image.is_empty() and fallback_color.is_empty():
			errors.append("combat_visuals.backdrops.%s: neither 'image' nor 'fallbackColor' set -- stage would render nothing" % context)
		if not fallback_color.is_empty() and not palette.has(fallback_color):
			errors.append("combat_visuals.backdrops.%s: fallbackColor '%s' is not a data/palette.json colour id" % [context, fallback_color])

	# archie_deal_mugging is a permanent alias of mugging's backdrop, never
	# its own plate (docs/combat-animation-vision.md §2.1).
	if backdrops.has(Combat.CONTEXT_ARCHIE_DEAL_MUGGING) and backdrops.has(Combat.CONTEXT_MUGGING):
		if backdrops[Combat.CONTEXT_ARCHIE_DEAL_MUGGING] != backdrops[Combat.CONTEXT_MUGGING]:
			errors.append("combat_visuals.backdrops.archie_deal_mugging: must exactly match backdrops.mugging (permanent alias, not its own plate)")

	var turn_pause: Dictionary = combat_visuals.get("pacing", {}).get("turnPause", {})
	for mode in CombatPacing.MODES:
		if not (turn_pause.get(mode) is float or turn_pause.get(mode) is int):
			errors.append("combat_visuals.pacing.turnPause: missing numeric entry for pacing mode '%s'" % mode)

	var sprite_scale = combat_visuals.get("stage", {}).get("spriteScale")
	if not ((sprite_scale is float or sprite_scale is int) and sprite_scale > 0):
		errors.append("combat_visuals.stage.spriteScale: must be a positive number")

	# Location plates are optional per key, but an entry that exists must
	# name an image -- an empty one would silently mask the context tier.
	var location_backdrops: Dictionary = combat_visuals.get("locationBackdrops", {})
	for location_key in location_backdrops.keys():
		var location_entry: Dictionary = location_backdrops[location_key]
		if str(location_entry.get("image", "")).is_empty():
			errors.append("combat_visuals.locationBackdrops.%s: 'image' must be a res:// path (drop the entry instead of leaving it empty)" % location_key)


# Iterates whatever room/region ids data/hq_visuals.json has -- no
# CANONICAL_* roster, since the point (§9/§3.2) is a plate or region can
# be added with no reader code change. "labBench" is a second top-level
# plate, sibling to "rooms" (§5.1), same rules via _validate_hq_plate().
func _validate_hq_visuals(hq_visuals: Dictionary, palette: Dictionary, errors: Array[String]) -> void:
	var rooms: Dictionary = hq_visuals.get("rooms", {})
	for room_id in rooms:
		_validate_hq_plate(rooms[room_id], "hq_visuals.rooms.%s" % room_id, palette, errors)

	if hq_visuals.has("labBench"):
		_validate_hq_plate(hq_visuals["labBench"], "hq_visuals.labBench", palette, errors)


func _validate_hq_plate(plate: Dictionary, context: String, palette: Dictionary, errors: Array[String]) -> void:
	_require_keys(plate, ["image", "fallbackColor", "width", "height", "regions"], context, errors)
	var image: String = plate.get("image", "")
	var fallback_color: String = plate.get("fallbackColor", "")
	if image.is_empty() and fallback_color.is_empty():
		errors.append("%s: neither 'image' nor 'fallbackColor' set -- the plate would render nothing" % context)
	if not fallback_color.is_empty() and not palette.has(fallback_color):
		errors.append("%s: fallbackColor '%s' is not a data/palette.json colour id" % [context, fallback_color])

	var regions: Dictionary = plate.get("regions", {})
	var seen_ids: Array[String] = []
	var seen_rects: Array[Rect2] = []
	for region_id in regions:
		var region: Dictionary = regions[region_id]
		var region_context := "%s.regions.%s" % [context, region_id]
		_require_keys(region, ["x", "y", "width", "height", "label", "image"], region_context, errors)
		var width: float = region.get("width", 0.0)
		var height: float = region.get("height", 0.0)
		if width < 44 or height < 44:
			errors.append("%s: %sx%s is below the 44x44 minimum hit-region size (docs/hq-diorama-vision.md §3.2)" % [region_context, width, height])
		var rect := Rect2(region.get("x", 0.0), region.get("y", 0.0), width, height)
		for i in seen_rects.size():
			if rect.intersects(seen_rects[i]):
				errors.append("%s: overlaps region '%s' in the same plate -- hit regions must not overlap (docs/hq-diorama-vision.md §3.2)" % [region_context, seen_ids[i]])
		seen_ids.append(region_id)
		seen_rects.append(rect)


func _validate_constants(time_blocks: Array, contacts_defaults: Dictionary, errors: Array[String]) -> void:
	if time_blocks.size() != 3:
		errors.append("constants: timeBlocks must have exactly 3 entries, got %d" % time_blocks.size())
	# Every contact carries recruitable -- the row that reads it is
	# ContactCards.build_recruit_row().
	for key in ["archie", "james", "des", "nadia", "hakim", "handler"]:
		if not contacts_defaults.has(key):
			errors.append("constants: contacts is missing '%s'" % key)
			continue
		_require_keys(contacts_defaults[key], ["startRelation", "unlocked", "recruitThreshold", "recruitable"], "constants.contacts.%s" % key, errors)


# Cosmetic-only flavour lines, minimum 6 per vendor so no-repeat-until-
# exhausted (Collective._next_bark) has room to cycle before wrapping.
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
	"chance", "start_street_mugging", "npc_claim_best_unclaimed_site", "lose_time_block",
	# grant_vein_with_site pairs a granted vein with a matching claimed site
	# (home-raid debrief); grant_contact_vein is its contact-handoff cousin,
	# stashing the new vein's id at a named state path. tutorial_cultivate
	# forces one free successful cultivate.
	"grant_vein_with_site", "tutorial_cultivate",
	"stealth_check", "start_raid_combat", "claim_raid_vein", "loot_raid_vein",
	# unlock_contact flips contacts.<id>.unlocked; push_message appends
	# a plain unread text (no follow-up action); queue_pending_message
	# is push_message's follow-up-action cousin (Messages.queue_pending()).
	# recruit_contact is Contacts.force_recruit() (story recruits).
	# activate_business is Business.activate() (Beat 3: pot + partners);
	# set_james_crafting_skill is BusinessQuest.set_james_crafting_skill() (Beat 5);
	# issue_recurring_offers is BusinessQuest.maybe_issue_recurring() (Beats 3, 6).
	"unlock_contact", "push_message", "recruit_contact", "activate_business",
	"set_james_crafting_skill", "issue_recurring_offers",
	# faction_relation is "relation"'s faction-facing twin (Factions.
	# adjust_player_relation); log_method writes state.methodLog[key]=value.
	"queue_pending_message", "faction_relation",
	"log_method",
	# Seeds a faction vein on each site recorded in a named objective's progress.
	"faction_seed_reported_sites",
	"grant_contact_vein",
	# Resolves a vein id from a named state path and reuses
	# VeinTrade.sell_to_faction() at a forced price.
	"sell_contact_vein_to_faction",
	# Chains straight into a second event, so a branch's own on_complete
	# can reach cards a sibling branch must never see.
	"start_event",
	# scripted_seed creates a site + claimed vein at seedGrowth + map
	# events, bypassing siteCap/ore-cost/travel. join_faction is the
	# only Factions.join() path when the generic Join button is suppressed.
	"scripted_seed", "join_faction",
	# reveal_site queues the discover map event for a site id.
	# set_hakim_intel_day stamps state.collective.hakimIntelLastDay with today.
	"reveal_site", "set_hakim_intel_day",
	# Contested-vein choice ops (col_a2_contested_vein, spec §6.5): resolve a
	# site id from a named state path (siteIdStatePath) rather than a raid's
	# threaded context, then reuse Raiding.claim_vein()/VeinTrade.
	# buy_from_faction() respectively. veinIdStatePath names the faction
	# vein instead (col_a2_hakim_retake).
	"claim_faction_vein", "buy_faction_vein",
	# col_a2_nadia_defend_brief's on_complete (T8a, spec §6.8a): picks and
	# stamps state.collective.nadiaDefendVeinId via Collective.
	# pick_nadia_defend_vein() -- no per-raid context to resolve a site from.
	"col_a2_pick_nadia_defend_vein",
	# col_a2_second_loss's on_complete (T11, spec §5.4): unrolled ownership
	# transfer via Collective.force_vein_loss(), target from veinIdStatePath
	# or Collective.second_loss_target_id().
	"col_a2_force_vein_loss",
	# col_a2_hakim_retake's choices (T13, spec §5.4): Collective.
	# ruin_hakim_site() empties Hakim's retaken site for good.
	"col_a2_ruin_site",
	# col_a2_hostile_member's "make an example" (T7, spec §6.7): Collective.
	# provoke_firm() stamps a timed Firm-targets-Collective weight multiplier.
	"col_a2_provoke_firm",
	# Network handler products (spec §5.3): NetworkHandler.reveal_vulnerable_
	# vein() (site id from effect/context, "effect" claim_bonus|security_freeze)
	# and NetworkHandler.reveal_site() ("oreType", "minTier").
	"network_reveal_vulnerable_vein", "network_reveal_site",
]


# Screens only swap on EventBus.screen_changed (Nav.go_to()), never fired
# by Events.advance() itself -- an on_complete forgetting a "set_screen"
# op leaves EventScreen mounted dereferencing a null state.event.
# "start_home_raid_combat" is the one exception (sets currentScreen
# itself in combat.gd).
const SELF_NAVIGATING_ON_COMPLETE_OPS: Array[String] = ["start_home_raid_combat"]


func _on_complete_navigates(on_complete: Array) -> bool:
	for effect in on_complete:
		if typeof(effect) != TYPE_DICTIONARY:
			continue
		var op = effect.get("op")
		if op == "set_screen" or SELF_NAVIGATING_ON_COMPLETE_OPS.has(op):
			return true
	return false


func _validate_events(events: Dictionary, districts: Dictionary, errors: Array[String]) -> void:
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
		if not _on_complete_navigates(entry.get("on_complete", [])):
			errors.append("events.%s: on_complete has no 'set_screen' op (and no self-navigating op like 'start_home_raid_combat') — Events.advance() never navigates on its own, so the EventScreen is left stuck on a dead Continue button once this event completes" % key)
		if entry.has("deck"):
			_validate_deck_entry(entry["deck"], "events.%s.deck" % key, errors)
		if entry.has("pin"):
			_validate_event_pin(entry["pin"], districts, "events.%s.pin" % key, errors)


# Contact pin (docs/M1.5-NETWORK-MAP.md N2): { district, showWhenFlagsTrue:
# [flag,...], showWhenFlagsFalse:[flag,...] } -- systems/map_pins.gd reads
# this to decide whether a pin shows on the Network map. "contact"/
# "phoneLabel" optionally name the phone contact this pin belongs to and
# its phone-card shortcut label; one without the other is a data mistake.
func _validate_event_pin(pin: Dictionary, districts: Dictionary, context: String, errors: Array[String]) -> void:
	_require_keys(pin, ["district", "showWhenFlagsTrue", "showWhenFlagsFalse"], context, errors)
	if typeof(pin) != TYPE_DICTIONARY:
		return
	var district: Variant = pin.get("district")
	if not districts.is_empty() and not districts.has(district):
		errors.append("%s: district '%s' is not a known district" % [context, district])
	if pin.has("contact") != pin.has("phoneLabel"):
		errors.append("%s: 'contact' and 'phoneLabel' must be declared together" % context)


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
		# stealth_check branches into on_success/on_caught the same way
		# "chance" branches above -- recursed for the same reason.
		if effect["op"] == "stealth_check":
			_require_keys(effect, ["on_success", "on_caught"], context, errors)
			_validate_effect_list(effect.get("on_success", []), "%s.stealth_check.on_success" % context, errors)
			_validate_effect_list(effect.get("on_caught", []), "%s.stealth_check.on_caught" % context, errors)


# M1-LONDON D5's deck filter metadata: district (or "any"), weight,
# excludeIfFlag (nullable), barometerState (nullable, reserved plumbing).
func _validate_deck_entry(deck: Dictionary, context: String, errors: Array[String]) -> void:
	_require_keys(deck, ["district", "weight", "excludeIfFlag", "barometerState"], context, errors)
	if typeof(deck) != TYPE_DICTIONARY:
		return
	var district: Variant = deck.get("district")
	if district != "any" and not CANONICAL_DISTRICT_IDS.has(district):
		errors.append("%s: district '%s' is neither 'any' nor a known district" % [context, district])


# data/objectives.json -- Objectives.refresh()'s canonical evaluator
# types, each with its own fixed param schema. flag_true takes no params
# (complete once completeFlag is true, the tutorial chain's shape); other
# types inspect world/faction/vein state.
const OBJECTIVE_TYPES: Array[String] = [
	"sites_discovered_matching", "traded_with_faction", "supplied_to_contact", "vein_sold_to_faction", "vein_growth_above", "flag_true",
	"alarm_defend_wins", "faction_vein_seeded_count", "items_crafted_set", "contracts_completed", "all_of",
	"recurring_proof",
]
const OBJECTIVE_TYPE_PARAMS: Dictionary = {
	"sites_discovered_matching": ["requireEachOreType", "minTier", "unclaimed"],
	"traded_with_faction": ["factionId", "oreType", "qty", "minTransactions"],
	"supplied_to_contact": ["contactId", "factionId", "oreType", "qty"],
	"vein_sold_to_faction": ["factionId", "oreType"],
	"vein_growth_above": ["veinIdStatePath", "threshold"],
	"flag_true": [],
	"alarm_defend_wins": ["minCount"],
	"faction_vein_seeded_count": ["factionId", "minCount"],
	"items_crafted_set": ["recipeKeys", "minEach"],
	"contracts_completed": ["minCount"],
	"all_of": ["conditions"],
	"recurring_proof": ["minContracts", "minCrafted"],
}
# all_of's live condition kinds (Objectives.condition_met()), each with its
# required keys beside "kind" and the ToDo checklist "label".
const OBJECTIVE_CONDITION_KEYS: Dictionary = {
	"contact_skill": ["contactId", "skill", "minLevel"],
	"home_room": ["roomId"],
}


func _validate_objectives(objectives: Dictionary, factions: Dictionary, ore_types: Dictionary, site_tier_order: Array, recipes: Dictionary, errors: Array[String]) -> void:
	for key in objectives.keys():
		var entry = objectives[key]
		_require_keys(entry, ["id", "title", "detail", "type", "params", "activateFlag", "completeFlag", "questline"], "objectives.%s" % key, errors)
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		if entry.get("id") != key:
			errors.append("objectives.%s: id field '%s' does not match key" % [key, entry.get("id")])
		# activateFlag may be null -- active from game start (the tutorial
		# chain's first checkpoint). Every other objective needs a real flag name.
		if entry.has("activateFlag") and entry["activateFlag"] != null and typeof(entry["activateFlag"]) != TYPE_STRING:
			errors.append("objectives.%s: activateFlag must be a string or null" % key)
		if entry.has("completeFlag") and typeof(entry["completeFlag"]) != TYPE_STRING:
			errors.append("objectives.%s: completeFlag must be a string" % key)
		if entry.has("questline") and (typeof(entry["questline"]) != TYPE_STRING or entry["questline"].is_empty()):
			errors.append("objectives.%s: questline must be a non-empty string" % key)
		# Optional day-gated title override for systems/todo.gd's
		# _display_text() -- either both fields are present or neither is.
		if entry.has("earlyTitle") != entry.has("earlyTitleBeforeDay"):
			errors.append("objectives.%s: earlyTitle and earlyTitleBeforeDay must be set together" % key)
		elif entry.has("earlyTitle"):
			if typeof(entry["earlyTitle"]) != TYPE_STRING:
				errors.append("objectives.%s: earlyTitle must be a string" % key)
			if not (entry["earlyTitleBeforeDay"] is float or entry["earlyTitleBeforeDay"] is int):
				errors.append("objectives.%s: earlyTitleBeforeDay must be a number" % key)

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
			"all_of":
				for condition in params.get("conditions", []):
					var cond_kind = condition.get("kind") if typeof(condition) == TYPE_DICTIONARY else null
					if not OBJECTIVE_CONDITION_KEYS.has(cond_kind):
						errors.append("objectives.%s: unknown condition kind '%s'" % [key, cond_kind])
						continue
					for cond_key in OBJECTIVE_CONDITION_KEYS[cond_kind] + ["label"]:
						if not condition.has(cond_key):
							errors.append("objectives.%s: condition '%s' missing '%s'" % [key, cond_kind, cond_key])
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
			"faction_vein_seeded_count":
				var seed_faction_id = params.get("factionId")
				if not factions.is_empty() and not factions.has(seed_faction_id):
					errors.append("objectives.%s: factionId '%s' is not a known faction" % [key, seed_faction_id])
			"items_crafted_set":
				var recipe_keys = params.get("recipeKeys")
				if typeof(recipe_keys) != TYPE_ARRAY or recipe_keys.is_empty():
					errors.append("objectives.%s: recipeKeys must be a non-empty array" % key)
				elif not recipes.is_empty():
					for recipe_key in recipe_keys:
						if not recipes.has(recipe_key):
							errors.append("objectives.%s: recipeKeys '%s' is not a known recipe" % [key, recipe_key])


func _require_keys(entry: Dictionary, keys: Array, context: String, errors: Array[String]) -> void:
	if typeof(entry) != TYPE_DICTIONARY:
		errors.append("%s: expected a Dictionary, got %s" % [context, type_string(typeof(entry))])
		return
	for key in keys:
		if not entry.has(key):
			errors.append("%s: missing required key '%s'" % [context, key])


# ── file loading ──────────────────────────────────────────────────────

# DirAccess reads res:// through Godot's packed resource filesystem, not
# the OS filesystem -- works the same in editor, headless, and exported builds.
func _list_event_ids() -> Array[String]:
	var ids: Array[String] = []
	var dir := DirAccess.open("res://data/events/")
	if dir == null:
		_load_errors.append("Could not open directory: res://data/events/")
		return ids
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			ids.append(file_name.get_basename())
		file_name = dir.get_next()
	dir.list_dir_end()
	ids.sort()
	return ids


# `table` is purely for error messages, so a missing/broken file's error
# names the table it was meant to fill, not just its path.
func _load_json(path: String, table: String = "") -> Dictionary:
	var tag: String = " (table '%s')" % table if not table.is_empty() else ""
	if not FileAccess.file_exists(path):
		_load_errors.append("Missing data file: %s%s" % [path, tag])
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_load_errors.append("Could not open data file: %s (error %d)%s" % [path, FileAccess.get_open_error(), tag])
		return {}
	var text := file.get_as_text()
	var parsed = JSON.parse_string(text)
	if parsed == null:
		_load_errors.append("Failed to parse JSON: %s%s" % [path, tag])
		return {}
	if typeof(parsed) != TYPE_DICTIONARY:
		_load_errors.append("Expected a JSON object at top level: %s%s" % [path, tag])
		return {}
	return _normalize_numbers(parsed)


# JSON.parse_string() returns every number as a float, but int vs. float
# is load-bearing once it's in GameState's pure state tree (deep-equality
# save/load checks, id lookups that str() a key -- "1.0" isn't "1").
# Normalize once here: any float with no fractional part becomes int;
# genuinely-fractional fields (baseSuccess, raidBaseChance, etc.) stay float.
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

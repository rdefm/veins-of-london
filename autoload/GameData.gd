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

# Same shape as CULTIVATING_XP_LEVELS/CRAFTING_XP_LEVELS above -- lives in
# home.json since the Sales role is gated by the Operations Room defined there.
var SALES_XP_LEVELS: Array = []

# data/dial.json (R§1.4): Dial.attempt_seed()'s cost/chance inputs and the
# cosmetic haft whitelist.
var DIAL_SEED_COST: Dictionary = {}
var DIAL_SEED_BASE_SUCCESS: float = 0.0
var DIAL_HAFTS: Dictionary = {}

# The Dial-wide charge-pool baseline Dial._charge_stats_for() starts from
# before applying the seated Movement's per-archetype bonus/downside curve.
var DIAL_BASE_MAX_CHARGE: int = 0
var DIAL_BASE_RECHARGE_RATE: float = 0.0

# The tier-5 Recharge Movement's regen: Dial.combat_turn_tick() adds this
# amount every N player turns while seated, independent of the daily
# rechargeRate ticked by Dial.daily_regen().
var DIAL_RECHARGE_COMBAT_REGEN_TURNS: int = 0
var DIAL_RECHARGE_COMBAT_REGEN_AMOUNT: int = 0

# data/dial.json's "movements" table (Dial.attempt_craft_movement()'s
# per-archetype baseSuccess/ingredientBase/xpReward, tier-indexed bonus/
# downside/windingCostPerCharge arrays) and the shared tier-indexed
# attunement chance bonus (Dial.attunement_bonus()).
var DIAL_MOVEMENTS: Dictionary = {}
var DIAL_ATTUNEMENT_BONUS_BY_TIER: Array = []

# data/dial.json's "capacityByLevel" -- the Dial-level lookup table
# Dial.capacity_max() reads (index=level 0..5), independent of which
# Movement (if any) is seated.
var DIAL_CAPACITY_BY_LEVEL: Array = []

# data/dial.json's "xpLevels" -- Dial.cast_complication()'s level-ladder
# table (index=level 0..5), reused via Progression.award_xp().
# "maxChargeBonusByLevel" is the primary per-level curve added on top of the
# seated Movement's own charge stats; "rechargeRateBonusByLevel" is a
# deliberately sparser curve so levelling reads as bigger reserve now,
# faster refill only as a rarer milestone.
var DIAL_XP_LEVELS: Array = []
var DIAL_MAX_CHARGE_BONUS_BY_LEVEL: Array = []
var DIAL_RECHARGE_RATE_BONUS_BY_LEVEL: Array = []

var ITEMS: Dictionary = {}

var VEIN_SECURITY: Dictionary = {}

# The "alarm/cameras" upgrade — independent of VEIN_SECURITY's tier ladder
# above. Purchased ids land in a vein's own "alarmUpgrades" array
# (Cultivating.make_vein), mirroring how HOME_SECURITY's ids land in
# state.home["security"].
var VEIN_ALARM: Dictionary = {}

# Third skill, same progression shape as CULTIVATING_XP_LEVELS/
# CRAFTING_XP_LEVELS above. Its own file since it's not tier-keyed content.
var STEALTH_XP_LEVELS: Array = []

var HOME_TIER_ORDER: Array = []
var HOME_TIERS: Dictionary = {}
var HOME_SECURITY: Dictionary = {}
var HOME_ROOMS: Dictionary = {}

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

# The bounded solo combat prototype's teaching roster (systems/
# combat_prototype.gd) — prototype-only, not production balance. Kept in
# its own table so a validation/balance pass over the real roster never has
# to reason about throwaway-experiment entries.
var COMBAT_PROTOTYPE: Dictionary = {}

# Player Combat Skill curves (R§3.7a), colocated in data/enemies.json rather
# than a new file of their own.
var COMBAT_XP_LEVELS: Array = []
var COMBAT_ATTACK_BONUS_BY_LEVEL: Array = []
var COMBAT_SPEED_BY_LEVEL: Array = []

# data/combat_visuals.json (docs/combat-animation-vision.md §2.1/§6):
# "backdrops" -- Combat.CANONICAL_CONTEXTS context id -> { "image": res://
# path or "" when no plate exists, "fallbackColor": a PALETTE key the stage
# fills with instead }. "templates" -- per-subject idle sheets (see the
# json's own "templateRule" note) plus a shared "default" hurt/dead/attack
# stand-in; deliberately unvalidated below since its shape isn't finalised,
# so scenes/screens/combat.gd reads it defensively.
var COMBAT_VISUALS: Dictionary = {}

# data/palette.json (docs/ART-BIBLE.md §2): the master colour palette, keyed
# by colour id (e.g. "brick_shadow") -> Color, so any screen can resolve a
# data-declared palette key without hardcoding a hex value. Not a per-table
# validate_tables() subject on its own -- _validate_combat_visuals() below
# cross-references into it instead.
var PALETTE: Dictionary = {}

# data/hq_visuals.json (docs/hq-diorama-vision.md §9): "rooms" table --
# room-plate id -> { image, fallbackColor, width, height, regions: { zone id
# -> {x,y,width,height,label,image} } }, read generically by scenes/
# components/hq_diorama.gd (no hardcoded room/zone roster) so a plate or
# region can be added with no reader code change.
var HQ_VISUALS: Dictionary = {}

var TIME_BLOCKS: Array = []
var DAY_CLOCK: Dictionary = {}
var DAILY_CYCLE: Dictionary = {}
var ARCHIE_ORE_GOAL: int = 0
var CONTACTS_DEFAULTS: Dictionary = {}
var JAMES_JOB_TRUST_BANDS: Array = []

# The missed-defend guard-repel chance, shared by both Home.
# _guards_repel_pending_raid() (HQ's guardCount) and Raiding.
# _guards_repel_defend_raid() (a vein's extraGuards) -- one data source for
# both so retuning it never touches either .gd file.
var GUARD_REPEL_CHANCE_PER_GUARD: float = 0.0
var GUARD_REPEL_CHANCE_CAP: float = 0.0

var EVENTS: Dictionary = {}

# Per-vendor flavour lines drawn on completing a Collective trade (systems/
# collective.gd) -- cosmetic only, the three doors trade at identical terms.
# Keyed by contact id.
var COLLECTIVE_BARKS: Dictionary = {}

# data/objectives.json, keyed by objective id -- see systems/objectives.gd.
# Each entry's "questline" field groups it for systems/todo.gd's Notes-app
# rendering: the tutorial's flag chain and Collective's Act 1 threads are
# both just objectives, distinguished only by questline.
var OBJECTIVES: Dictionary = {}

# Full tutorial + Collective Act 1 event roster (R§3.11, R§3.8).
const EVENT_IDS: Array[String] = [
	"intro", "buyer", "james_meeting", "archie_craft_chat",
	"home_raid_intro", "home_raid_debrief_win", "home_raid_debrief_loss",
	"archie_motion", "james_motion",
	# Cultivating tutorial, triggered by scenes/screens/map.gd on the first
	# Map-tab visit after archiePartnerSeen.
	"archie_cultivation",
	# The Raid button's one representative event card (systems/raiding.gd's
	# begin_raid()) — directly triggered, not part of any district's
	# weighted event deck. Targets whichever site's Raid button was pressed
	# (events.gd's _event_site_id()), not a fixed combination.
	"vein_raid",
	# Act 1 Phase 1's mandatory tuition chain.
	"col_a1_intro", "col_a1_prospecting", "col_a1_seeding", "col_a1_hub",
	# Des's two location-agnostic beats -- direct-triggered from
	# Sites.prospect() (systems/collective.gd's maybe_trigger_weather_beat()),
	# hence EVENT_IDS not DISTRICT_EVENT_IDS.
	"col_a1_firm_skirmish", "col_a1_firm_intimidation",
	"col_a1_des_report", "col_a1_des_report_first_fate", "col_a1_des_report_first_physics",
	"col_a1_nadia_meet",
	"col_a1_nadia_vein",
	"col_a1_nadia_done",
	"col_a1_hakim_meet",
	"col_a1_hakim_done",
	"col_a1_archie_pry", "col_a1_archie_pry_debt",
	"col_a1_closer", "col_a1_deferred_join",
	# Hakim's repeatable post-Act-1 intel. Not "col_a1_"-prefixed since it
	# keeps firing after the act ends.
	"col_hakim_intel",
]

# District event deck roster (M1-LONDON D5). Loaded into the same EVENTS
# dict as EVENT_IDS above — a district event file is a normal event file
# (cards/on_complete) plus a "deck" sub-object (district, weight,
# excludeIfFlag, barometerState) that systems/district_deck.gd reads.
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
	OFFER_TEMPLATES = _load_json("res://data/offers.json").get("templates", {})

	var dial := _load_json("res://data/dial.json")
	DIAL_SEED_COST = dial.get("seedCost", {})
	DIAL_SEED_BASE_SUCCESS = dial.get("seedBaseSuccess", 0.0)
	DIAL_BASE_MAX_CHARGE = dial.get("baseMaxCharge", 0)
	DIAL_BASE_RECHARGE_RATE = dial.get("baseRechargeRate", 0.0)
	DIAL_RECHARGE_COMBAT_REGEN_TURNS = dial.get("rechargeCombatRegenEveryTurns", 0)
	DIAL_RECHARGE_COMBAT_REGEN_AMOUNT = dial.get("rechargeCombatRegenAmount", 0)
	DIAL_HAFTS = dial.get("hafts", {})
	DIAL_MOVEMENTS = dial.get("movements", {})
	DIAL_ATTUNEMENT_BONUS_BY_TIER = dial.get("attunementBonusByTier", [])
	DIAL_CAPACITY_BY_LEVEL = dial.get("capacityByLevel", [])
	DIAL_XP_LEVELS = dial.get("xpLevels", [])
	DIAL_MAX_CHARGE_BONUS_BY_LEVEL = dial.get("maxChargeBonusByLevel", [])
	DIAL_RECHARGE_RATE_BONUS_BY_LEVEL = dial.get("rechargeRateBonusByLevel", [])

	ITEMS = _load_json("res://data/items.json")
	VEIN_SECURITY = _load_json("res://data/vein_security.json")
	VEIN_ALARM = _load_json("res://data/vein_alarm.json")

	STEALTH_XP_LEVELS = _load_json("res://data/stealth.json").get("stealthXpLevels", [])

	var home := _load_json("res://data/home.json")
	HOME_TIER_ORDER = home.get("tierOrder", [])
	HOME_TIERS = home.get("tiers", {})
	HOME_SECURITY = home.get("security", {})
	HOME_ROOMS = home.get("rooms", {})
	SALES_XP_LEVELS = home.get("salesXpLevels", [])

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
	COMBAT_XP_LEVELS = enemies.get("combatXpLevels", [])
	COMBAT_ATTACK_BONUS_BY_LEVEL = enemies.get("combatAttackBonusByLevel", [])
	COMBAT_SPEED_BY_LEVEL = enemies.get("combatSpeedByLevel", [])

	COMBAT_PROTOTYPE = _load_json("res://data/combat_prototype.json")

	COMBAT_VISUALS = _load_json("res://data/combat_visuals.json")

	HQ_VISUALS = _load_json("res://data/hq_visuals.json")

	PALETTE = {}
	for entry in _load_json("res://data/palette.json").get("colors", []):
		var id: String = entry.get("id", "")
		if not id.is_empty() and entry.has("hex"):
			PALETTE[id] = Color(entry["hex"])

	var constants := _load_json("res://data/constants.json")
	TIME_BLOCKS = constants.get("timeBlocks", [])
	DAY_CLOCK = constants.get("dayClock", {})
	DAILY_CYCLE = JSON.parse_string(FileAccess.get_file_as_string("res://data/daily_cycle.json"))
	ARCHIE_ORE_GOAL = constants.get("archieOreGoal", 0)
	CONTACTS_DEFAULTS = constants.get("contacts", {})
	JAMES_JOB_TRUST_BANDS = constants.get("jamesJobTrustBands", [])
	var guard_repel: Dictionary = constants.get("guardRepel", {})
	GUARD_REPEL_CHANCE_PER_GUARD = guard_repel.get("chancePerGuard", 0.0)
	GUARD_REPEL_CHANCE_CAP = guard_repel.get("cap", 0.0)

	EVENTS = {}
	for event_id in EVENT_IDS + DISTRICT_EVENT_IDS:
		var event_def := _load_json("res://data/events/%s.json" % event_id)
		if not event_def.is_empty():
			EVENTS[event_id] = event_def

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
	_validate_dial(t.get("dial_seed_cost", {}), t.get("dial_seed_base_success", 0.0), t.get("dial_base_max_charge", 0), t.get("dial_base_recharge_rate", 0.0), t.get("dial_recharge_combat_regen_turns", 0), t.get("dial_recharge_combat_regen_amount", 0), t.get("dial_hafts", {}), t.get("dial_movements", {}), t.get("dial_attunement_bonus_by_tier", []), t.get("dial_capacity_by_level", []), t.get("dial_xp_levels", []), t.get("dial_max_charge_bonus_by_level", []), t.get("dial_recharge_rate_bonus_by_level", []), errors)
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
	_validate_enemies(t.get("enemy_raid_guards", {}), t.get("enemy_home_raid_raider", {}), t.get("combat_xp_levels", []), t.get("combat_attack_bonus_by_level", []), t.get("combat_speed_by_level", []), errors)
	_validate_combat_prototype(t.get("combat_prototype", {}), errors)
	_validate_combat_visuals(t.get("combat_visuals", {}), t.get("palette", {}), errors)
	_validate_hq_visuals(t.get("hq_visuals", {}), t.get("palette", {}), errors)
	_validate_constants(t.get("time_blocks", []), t.get("contacts_defaults", {}), errors)
	_validate_events(t.get("events", {}), t.get("districts", {}), errors)
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
		"dial_seed_cost": DIAL_SEED_COST,
		"dial_seed_base_success": DIAL_SEED_BASE_SUCCESS,
		"dial_base_max_charge": DIAL_BASE_MAX_CHARGE,
		"dial_base_recharge_rate": DIAL_BASE_RECHARGE_RATE,
		"dial_recharge_combat_regen_turns": DIAL_RECHARGE_COMBAT_REGEN_TURNS,
		"dial_recharge_combat_regen_amount": DIAL_RECHARGE_COMBAT_REGEN_AMOUNT,
		"dial_hafts": DIAL_HAFTS,
		"dial_movements": DIAL_MOVEMENTS,
		"dial_attunement_bonus_by_tier": DIAL_ATTUNEMENT_BONUS_BY_TIER,
		"dial_capacity_by_level": DIAL_CAPACITY_BY_LEVEL,
		"dial_xp_levels": DIAL_XP_LEVELS,
		"dial_max_charge_bonus_by_level": DIAL_MAX_CHARGE_BONUS_BY_LEVEL,
		"dial_recharge_rate_bonus_by_level": DIAL_RECHARGE_RATE_BONUS_BY_LEVEL,
		"items": ITEMS,
		"vein_security": VEIN_SECURITY,
		"vein_alarm": VEIN_ALARM,
		"stealth_xp_levels": STEALTH_XP_LEVELS,
		"home_tier_order": HOME_TIER_ORDER,
		"home_tiers": HOME_TIERS,
		"home_security": HOME_SECURITY,
		"home_rooms": HOME_ROOMS,
		"sales_xp_levels": SALES_XP_LEVELS,
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
		"combat_xp_levels": COMBAT_XP_LEVELS,
		"combat_attack_bonus_by_level": COMBAT_ATTACK_BONUS_BY_LEVEL,
		"combat_speed_by_level": COMBAT_SPEED_BY_LEVEL,
		"combat_prototype": COMBAT_PROTOTYPE,
		"combat_visuals": COMBAT_VISUALS,
		"hq_visuals": HQ_VISUALS,
		"palette": PALETTE,
		"time_blocks": TIME_BLOCKS,
		"contacts_defaults": CONTACTS_DEFAULTS,
		"events": EVENTS,
		"objectives": OBJECTIVES,
		"collective_barks": COLLECTIVE_BARKS,
	}


# ── per-table checks ──────────────────────────────────────────────────

const CANONICAL_ORE_TYPES: Array[String] = ["time", "physics", "life", "fate", "emotion"]

# The v1 launch set of four Movement archetypes (R§1.4) -- Dial.
# MOVEMENT_ARCHETYPES mirrors this list rather than duplicating it, same as
# every other CANONICAL_* roster here.
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


# seedCost must cover every canonical ore type (R§1.4's mixed five-ore-type
# cost) -- unlike a recipe's ingredients dict, a partial cost here would
# silently let seeding skip an ore type. Hafts are cosmetic-only (no stat
# fields, no code path reads one for anything but display), so each only
# needs a display name, not the fuller schema recipes/movements use.
func _validate_dial(seed_cost: Dictionary, seed_base_success: float, base_max_charge: int, base_recharge_rate: float, recharge_combat_regen_turns: int, recharge_combat_regen_amount: int, hafts: Dictionary, movements: Dictionary, attunement_bonus_by_tier: Array, capacity_by_level: Array, xp_levels: Array, max_charge_bonus_by_level: Array, recharge_rate_bonus_by_level: Array, errors: Array[String]) -> void:
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
	# Dial.combat_turn_tick()'s cadence/amount for the tier-5 Recharge
	# Movement's in-combat regen.
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
		# Dial.winding_cost_per_charge()'s lookup -- same tier-indexed shape
		# as bonus/downside above.
		if entry.has("windingCostPerCharge") and entry["windingCostPerCharge"].size() != 6:
			errors.append("dial.movements.%s: windingCostPerCharge must have 6 entries (index=tier 0..5)" % archetype)
	for key in movements.keys():
		if not CANONICAL_MOVEMENT_ARCHETYPES.has(key):
			errors.append("dial.movements: unexpected archetype '%s' (not in the PRD's v1 launch set)" % key)

	if attunement_bonus_by_tier.size() != 6:
		errors.append("dial.attunementBonusByTier: expected 6 entries (index=tier 0..5), got %d" % attunement_bonus_by_tier.size())

	# Dial.capacity_max()'s lookup -- same index=level 0..5 shape as
	# attunementBonusByTier above.
	if capacity_by_level.size() != 6:
		errors.append("dial.capacityByLevel: expected 6 entries (index=level 0..5), got %d" % capacity_by_level.size())

	# hq_dial.gd's flanking-socket layout hard-codes exactly 4 tile positions
	# and indexes into it by capacityMax with no bounds check of its own -- a
	# capacityByLevel edit exceeding 4 would silently crash that screen
	# instead of failing loudly here at boot.
	for level_value in capacity_by_level:
		if int(level_value) > 4:
			errors.append("dial.capacityByLevel: entry %s exceeds 4 -- hq_dial.gd's socket layout has only 4 fixed positions" % str(level_value))
			break

	# The XP ladder and the two level-indexed charge-economy bonus curves it
	# drives -- same index=level 0..5 shape as capacityByLevel above.
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


# Every faction with a trade lane (Economy.get_faction_*) needs a row here.
# Only guild and collective have one so far.
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
# collapsed one at a time), so any subset of a district's claimed sites
# could be mid-divergence — pinning both their slots — at once, and
# siteCap*2 is the only margin that always covers that (see systems/
# map_layout.gd's assign_slots).
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


func _validate_enemies(raid_guards: Dictionary, home_raid_raider: Dictionary, combat_xp_levels: Array, combat_attack_bonus_by_level: Array, combat_speed_by_level: Array, errors: Array[String]) -> void:
	for key in raid_guards.keys():
		_require_keys(raid_guards[key], ["name", "hpBase", "attackMin", "attackMax", "speed"], "enemies.raidGuards.%s" % key, errors)
	_require_keys(home_raid_raider, ["name", "hp", "attackMin", "attackMax", "speed"], "enemies.homeRaidRaider", errors)

	# Same "6 entries, index=level 0..5" shape every other skill ladder
	# enforces — level 1 must be index 1, so a wrong-length array is a data
	# bug, not a design choice.
	if combat_xp_levels.size() != 6:
		errors.append("enemies.combatXpLevels: expected 6 entries (index=level, 0..5), got %d" % combat_xp_levels.size())
	if combat_attack_bonus_by_level.size() != 6:
		errors.append("enemies.combatAttackBonusByLevel: expected 6 entries (index=level, 0..5), got %d" % combat_attack_bonus_by_level.size())
	if combat_speed_by_level.size() != 6:
		errors.append("enemies.combatSpeedByLevel: expected 6 entries (index=level, 0..5), got %d" % combat_speed_by_level.size())


# Every id in encounterOrder needs a matching encounters entry with the
# fields CombatPrototype.start_encounter() reads, and every scripted action
# must be one of CombatPrototype.SCRIPTABLE_ACTIONS — a typo would otherwise
# silently no-op an enemy's teaching script instead of failing at boot.
#
# encounterOrder ids keep the flat single-enemy shape; any other `encounters`
# entry must be either a squad ('enemies': non-empty array of enemy defs) or
# a multi-wave roster ('waves': non-empty array of non-empty 'enemies'-shaped
# arrays) — never both, and never the flat shape (which CombatPrototype.
# _current_wave_defs() would silently never read).
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


# Every context in Combat.CANONICAL_CONTEXTS must have a backdrop entry --
# a new context is caught here too, the same guarantee _validate_events()
# gives the rest of the content pipeline. An entry needs an image OR a
# fallbackColor (never neither, or the stage renders nothing); a
# fallbackColor must name a real data/palette.json colour id.
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
	# its own plate (docs/combat-animation-vision.md §2.1) -- enforced here
	# so a future edit that gives mugging a real plate can't silently leave
	# archie_deal_mugging behind.
	if backdrops.has(Combat.CONTEXT_ARCHIE_DEAL_MUGGING) and backdrops.has(Combat.CONTEXT_MUGGING):
		if backdrops[Combat.CONTEXT_ARCHIE_DEAL_MUGGING] != backdrops[Combat.CONTEXT_MUGGING]:
			errors.append("combat_visuals.backdrops.archie_deal_mugging: must exactly match backdrops.mugging (permanent alias, not its own plate)")


# Deliberately iterates whatever room/region ids data/hq_visuals.json
# actually has -- no CANONICAL_* roster like _validate_combat_visuals()'s,
# since the point of this manifest (docs/hq-diorama-vision.md §9/§3.2) is
# that a plate or region can be added with no reader code change.
# "labBench" is a second top-level plate, sibling to "rooms" (§5.1 --
# reached from the lab zone, not a property tier); same rules apply, so the
# per-plate body is factored into _validate_hq_plate() and called for both.
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
	# All five contacts carry recruitable -- the row that reads it is
	# ContactCards.build_recruit_row().
	for key in ["archie", "james", "des", "nadia", "hakim"]:
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
	# (home-raid debrief); tutorial_cultivate forces one free successful
	# cultivate (archie_cultivation).
	"grant_vein_with_site", "tutorial_cultivate",
	"stealth_check", "start_raid_combat", "claim_raid_vein", "loot_raid_vein",
	# unlock_contact flips contacts.<id>.unlocked; push_message appends a
	# plain unread text to a conversation (no follow-up action -- for that,
	# systems call Messages.queue_pending() directly).
	"unlock_contact", "push_message",
	# queue_pending_message is push_message's follow-up-action cousin, wired
	# to Messages.queue_pending(); faction_relation is "relation"'s
	# faction-facing twin (Factions.adjust_player_relation).
	"queue_pending_message", "faction_relation",
	# log_method writes state.methodLog[key] = value.
	"log_method",
	# faction_seed_reported_sites seeds a faction vein on each site recorded
	# in a named objective's progress.
	"faction_seed_reported_sites",
	# grant_contact_vein is grant_vein_with_site's contact-handoff cousin --
	# also stores the new vein's id at a named state path.
	"grant_contact_vein",
	# sell_contact_vein_to_faction resolves a vein id from a named state path
	# and reuses VeinTrade.sell_to_faction() at a forced price.
	"sell_contact_vein_to_faction",
	# start_event chains straight into a second event, so a branch's own
	# on_complete can reach cards a sibling branch must never see (cardIndex
	# has no branching of its own).
	"start_event",
	# scripted_seed creates a site (district/tier/oreType from the effect), a
	# claimed vein at seedGrowth, and the matching map events, bypassing
	# siteCap/ore-cost/travel entirely. join_faction is the only remaining
	# path to Factions.join() when the generic Join button is suppressed.
	"scripted_seed", "join_faction",
	# reveal_site queues the discover map event for a site id (from the
	# pending message's payload, or the event's own "site_id"; same fallback
	# _event_site_id() gives raid ops). set_hakim_intel_day stamps
	# state.collective.hakimIntelLastDay with today.
	"reveal_site", "set_hakim_intel_day",
]


# Screens only ever swap on EventBus.screen_changed, fired by Nav.go_to() --
# Events.advance() never calls that itself when an event completes, so
# on_complete is the only place left to do it. An event whose on_complete
# forgets a "set_screen" op leaves the EventScreen mounted with a Continue
# button that dereferences a null state.event. "start_home_raid_combat" is
# the one recognized exception (it sets currentScreen itself in
# combat.gd's _start_combat) -- add an op here only after confirming the
# same.
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
		if not _on_complete_navigates(entry.get("on_complete", [])):
			errors.append("events.%s: on_complete has no 'set_screen' op (and no self-navigating op like 'start_home_raid_combat') — Events.advance() never navigates on its own, so the EventScreen is left stuck on a dead Continue button once this event completes" % key)
		if entry.has("deck"):
			_validate_deck_entry(entry["deck"], "events.%s.deck" % key, errors)
			if not DISTRICT_EVENT_IDS.has(key):
				errors.append("events.%s: has a 'deck' sub-object but is not registered in GameData.DISTRICT_EVENT_IDS — it would silently join the district-deck draw pool" % key)
		if entry.has("pin"):
			_validate_event_pin(entry["pin"], districts, "events.%s.pin" % key, errors)

	for expected_id in DISTRICT_EVENT_IDS:
		if events.has(expected_id) and not events[expected_id].has("deck"):
			errors.append("events.%s: registered in GameData.DISTRICT_EVENT_IDS but missing its 'deck' sub-object" % expected_id)


# Contact pin (docs/M1.5-NETWORK-MAP.md N2): { district, showWhenFlagsTrue:
# [flag,...], showWhenFlagsFalse:[flag,...] } — read by systems/map_pins.gd
# to decide whether a pin for this event is showing on the Network map.
# "contact"/"phoneLabel" are an optional pair naming the phone contact this
# pin belongs to and the label for its phone-card shortcut (ContactCards.
# build_pin_shortcut_actions()); one without the other is a data mistake.
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
# excludeIfFlag (nullable), barometerState (nullable — reserved plumbing,
# not exercised by any current data per D5).
func _validate_deck_entry(deck: Dictionary, context: String, errors: Array[String]) -> void:
	_require_keys(deck, ["district", "weight", "excludeIfFlag", "barometerState"], context, errors)
	if typeof(deck) != TYPE_DICTIONARY:
		return
	var district: Variant = deck.get("district")
	if district != "any" and not CANONICAL_DISTRICT_IDS.has(district):
		errors.append("%s: district '%s' is neither 'any' nor a known district" % [context, district])


# data/objectives.json — Objectives.refresh()'s canonical evaluator types
# (systems/objectives.gd), each with its own fixed param schema. flag_true
# takes no params: complete once the objective's own completeFlag is true --
# the shape a flag-driven questline (the tutorial chain) needs, vs. the
# other types which all inspect world/faction/vein state.
const OBJECTIVE_TYPES: Array[String] = [
	"sites_discovered_matching", "traded_with_faction", "supplied_to_contact", "vein_sold_to_faction", "vein_growth_above", "flag_true",
]
const OBJECTIVE_TYPE_PARAMS: Dictionary = {
	"sites_discovered_matching": ["requireEachOreType", "minTier", "unclaimed"],
	"traded_with_faction": ["factionId", "oreType", "qty", "minTransactions"],
	"supplied_to_contact": ["contactId", "factionId", "oreType", "qty"],
	"vein_sold_to_faction": ["factionId", "oreType"],
	"vein_growth_above": ["veinIdStatePath", "threshold"],
	"flag_true": [],
}


func _validate_objectives(objectives: Dictionary, factions: Dictionary, ore_types: Dictionary, site_tier_order: Array, errors: Array[String]) -> void:
	for key in objectives.keys():
		var entry = objectives[key]
		_require_keys(entry, ["id", "title", "detail", "type", "params", "activateFlag", "completeFlag", "questline"], "objectives.%s" % key, errors)
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		if entry.get("id") != key:
			errors.append("objectives.%s: id field '%s' does not match key" % [key, entry.get("id")])
		# activateFlag may be null -- active from game start, no gating flag
		# (the tutorial chain's first checkpoint). Every other objective
		# still needs a real flag name.
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


# JSON has no int type -- JSON.parse_string() returns every number as a
# float, but int vs. float is load-bearing once it's in GameState's pure
# state tree (deep-equality save/load checks, dict lookups that str() an id
# — "1.0" isn't "1"). Normalize once here rather than casting at every call
# site: any float with no fractional part becomes int. Every genuinely-
# fractional field in the current data (baseSuccess, raidBaseChance, etc.)
# stays float.
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

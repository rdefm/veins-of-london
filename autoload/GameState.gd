extends Node

# The entire game state: one pure data tree (Dictionaries/Arrays/primitives
# only — no object references, no Nodes, no Callables). This purity is what
# makes save, snapshot, and Rewind work. Systems read/write `state` directly
# and emit EventBus.state_changed; screens only ever read it. Not one line
# of screen code mutates this directly.

var state: Dictionary = {}


func _ready() -> void:
	reset()


func reset() -> void:
	state = new_game_state()


func new_game_state() -> Dictionary:
	return {
		"meta": { "saveVersion": 1 },
		"currentScreen": "title",
		"modal": null,
		"bagDrawerOpen": false,
		"inventoryTab": "ore",
		"mapNav": { "selectedDistrict": null, "selectedSiteId": null },
		"mapEvents": { "queue": [], "playing": false },
		"phoneNav": { "app": "home", "selectedAxis": null },
		"notifications": [],
		"sellState": {},
		"event": null,

		"player": {
			"cash": 40,
			"hp": 100, "hpMax": 100,
			"attackMin": 5, "attackMax": 12,
			"orichalchum": {},
			"veins": [],
			"inventory": { "timePearl": 0, "enhancementPowder": 0, "rewind": 0 },
			"equipment": { "weapon": null, "device": null },
			"items": [],
			"devicesInProgress": [],
			"devicesCompleted": [],
			"craftingSkill": 1, "craftingXP": 0,
			"cultivatingSkill": 1, "cultivatingXP": 0,
			"stealthSkill": 1, "stealthXP": 0,
		},

		"world": {
			"day": 1, "timeBlock": 0, "timeBlocksDone": [],
			"archieChatUnlockDay": null,
			"currentDistrict": "shoreditch",
			"sites": [],
			"recentEvents": [],  # D5: [{id, day}] — district-deck no-repeat-within-5-days tracking
			# vein-raiding ticket 07: a successful Direction-B raid attempt
			# against an alarmed vein queues here instead of resolving
			# immediately (Raiding._queue_defend_raid) -- each entry is an
			# outcome dict shaped { attackerId, veinId, siteId, success: true },
			# the same shape resolve_raid_outcome() already consumes. Cleared
			# and re-resolved off-screen (ticket 06's default path) at the
			# start of the next daily_tick's raid-resolution step
			# (Raiding._expire_pending_defend_raids) if the player never
			# travelled to the vein's district in the meantime.
			"pendingDefendRaids": [],
			# The one pending entry (above) currently being fought as a
			# "defend_vein" combat, popped off pendingDefendRaids by
			# Raiding.maybe_trigger_defend() when the player travels into its
			# district. Combat.exit_combat() reads this to resolve a loss via
			# Raiding.resolve_defend_outcome(), then clears it back to null.
			"activeDefendRaid": null,
		},

		"home": { "tier": "bedsit", "security": [], "rooms": [], "lastRaidDay": 0 },

		"factions": _new_factions_state(),

		# faction-territory-rivalry T01: a separate, internal-only matrix of
		# every faction's relation *toward* every other faction (directional
		# -- state.factionRelations[a][b] is a's relation toward b, and need
		# not equal state.factionRelations[b][a]). Distinct from
		# state.factions[id].relation above, which is the player-facing
		# player<->faction stat and is never read/written by this matrix.
		"factionRelations": _new_faction_relations_state(),

		"barometer": {
			"economic": "stable", "social": "stable", "political": "stable",
			"progress": {},
			"cooldowns": {},
		},

		"contacts": _new_contacts_state(),

		"combat": {
			"active": false, "context": "raid", "veinId": null, "enemy": null, "log": [],
			"outcome": null, "frozenTurns": 0, "motionTurns": 0, "motionPower": 0,
			"evadeTurns": 0, "evadeChance": 0.0, "onWin": null, "snapshots": [],
		},

		"jamesJob": null,
		"pendingSaleCut": 0,
		"labThresholds": {},
		"veinStationVeins": [],

		"flags": {
			"tutorialStage": "intro",
			"metArchie": false, "metJames": false, "buyerEventSeen": false,
			"craftingUnlocked": false, "archieCraftChatSeen": false,
			"canSellConsumables": false, "consSoldCount": 0,
			"archieMotionPending": false, "archieMotionEventSeen": false,
			"jamesMotionEventSeen": false, "enhancementUnlocked": false,
			"jamesJobActive": false,
			"homeRaidEventPending": false, "homeRaidEventSeen": false, "homeRaidWon": false,
			"archiePartnerSeen": false, "homeUnlocked": false, "securityContactUnlocked": false,
			# M1-LONDON D5 — district event one-shot flags/counters.
			"greenwichTipOff": false, "luckyOmen": false, "conclaveNoticed": false, "oddities": 0,
			# M1-LONDON D6 — cultivating tutorial.
			"cultivationTutorialSeen": false,
			# vein-raiding ticket 03: set by the raid event's stealth_check
			# on_success/on_caught branches, read by the loot_raid_vein op's
			# _event_caught() fallback (systems/events.gd) so the shared
			# claim/loot card knows which path got the player there.
			"raidCaught": false,
		},
	}


func _new_factions_state() -> Dictionary:
	var factions := {}
	for faction_id in GameData.FACTIONS.keys():
		factions[faction_id] = {
			"relation": 0,
			"joined": false,
			# faction-resource-economy T01: a real ledger balance (income/spend
			# land in later tickets — this only seeds the baseline), distinct
			# from data/factions.json's existing `resourceLevel` (a security-roll
			# opulence input, Factions._security_opulence()). resourceLevel ties
			# Guild to Firm/Network at 2, which doesn't read "Guild richer" per
			# its flavour text, so `startingResources` is its own tiered field:
			# Collective scrappiest, Firm/Network mid, Guild/Conclave richest.
			"resources": GameData.FACTIONS[faction_id].get("startingResources", 0),
		}
	return factions


# faction-territory-rivalry T01: seeds every ordered pair of the 5 canonical
# factions to a neutral baseline (0). The PRD leaves the exact seed values as
# an open question and only tickets 03/04 (rivalry odds + resolution) ever
# read or write this matrix, so a flat neutral start is the simplest
# defensible choice here -- it makes the day-1 rivalry odds this matrix will
# eventually feed into depend purely on resource/security disparity (ticket
# 03's other two inputs), not on an arbitrary industries-overlap guess this
# ticket has no gameplay evidence to justify. Every relationship still drifts
# from here per ticket 04's "grudges compound" feedback loop.
func _new_faction_relations_state() -> Dictionary:
	var relations := {}
	for a in GameData.FACTIONS.keys():
		var row := {}
		for b in GameData.FACTIONS.keys():
			if b != a:
				row[b] = 0
		relations[a] = row
	return relations


func _new_contacts_state() -> Dictionary:
	var contacts := {}
	for contact_id in GameData.CONTACTS_DEFAULTS.keys():
		var defaults: Dictionary = GameData.CONTACTS_DEFAULTS[contact_id]
		contacts[contact_id] = {
			"relation": defaults.get("startRelation", 0),
			"unlocked": defaults.get("unlocked", false),
			"recruited": false,
			"recruitThreshold": defaults.get("recruitThreshold", 0),
			"craftingSkill": 1, "craftingXP": 0,
			"cultivatingSkill": 1, "cultivatingXP": 0,
			"stealthSkill": 1, "stealthXP": 0,
			"assignedRoom": null,
		}
	return contacts


# Dot-path convenience reader, e.g. read_path("player.cash"). Named
# read_path (not get_path) because Node already declares a native
# get_path() -> NodePath — GameState is an autoload extending Node, so
# reusing that name silently overrides the engine's method instead of
# declaring a new one, which Godot 4.4 now treats as a hard parse error.
# Not a replacement for direct dict access (systems should still
# read/write `state` directly) — just a small helper for tests/
# notifications that want a value without knowing which layer holds it.
func read_path(path: String, default: Variant = null) -> Variant:
	var current: Variant = state
	for part in path.split("."):
		if current is Dictionary and current.has(part):
			current = current[part]
		else:
			return default
	return current


# Recursive deep copy of a pure data value (Dictionary/Array/primitive).
# What Snapshots.gd and SaveManager.gd build on.
static func deep_copy(value: Variant) -> Variant:
	if value is Dictionary:
		var copy := {}
		for key in value.keys():
			copy[key] = deep_copy(value[key])
		return copy
	elif value is Array:
		var copy := []
		for item in value:
			copy.append(deep_copy(item))
		return copy
	else:
		return value


# round() with a tiny epsilon safety margin. Use this (never plain round())
# anywhere a price/cost/etc. is rounded from a computed multiplier — IEEE-754
# double precision means e.g. 90 * (1 - 0.35 + 0.5) evaluates to
# 103.49999999999999, not exactly 103.5, so a literal round() lands on 103
# where the intended math (and REFERENCE.md's worked examples) says 104.
static func round_epsilon(value: float) -> int:
	return int(round(value + 0.000000001))

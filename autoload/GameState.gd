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
		"inventoryTab": "ore",
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
		},

		"world": {
			"day": 1, "timeBlock": 0, "timeBlocksDone": [],
			"archieChatUnlockDay": null,
			"currentDistrict": "shoreditch",
		},

		"home": { "tier": "bedsit", "security": [], "rooms": [], "lastRaidDay": 0, "storedOre": {} },

		"factions": _new_factions_state(),

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
		},
	}


func _new_factions_state() -> Dictionary:
	var factions := {}
	for faction_id in GameData.FACTIONS.keys():
		factions[faction_id] = { "relation": 0, "joined": false }
	return factions


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
			"assignedRoom": null,
		}
	return contacts


# Dot-path convenience reader, e.g. get_path("player.cash"). Not a
# replacement for direct dict access (systems should still read/write
# `state` directly) — just a small helper for tests/notifications that
# want a value without knowing which layer holds it.
func get_path(path: String, default: Variant = null) -> Variant:
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

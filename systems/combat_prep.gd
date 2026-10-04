class_name CombatPrep
extends RefCounted

# Pending pre-fight preparation (R§3.7 "Preparation"). Every combat entry path
# parks here as state.combatPrep before its costs, rolls or first turn:
#   { kind, args, forced, returnScreen }
# Fight (commit) replays the path's existing entry; Cancel (planned only)
# clears it and spends nothing. Forced/scripted encounters have no Cancel.

const SCREEN := "combat_prep"

const KIND_VEIN_RAID := "vein_raid"
const KIND_STOCKPILE_RAID := "stockpile_raid"
const KIND_VEIN_DEFEND := "vein_defend"
const KIND_HQ_DEFEND := "hq_defend"
const KIND_DEBUG := "debug"
const KIND_MUGGING := "mugging"
const KIND_ARCHIE_DEAL_MUGGING := "archie_deal_mugging"
const KIND_STREET_MUGGING := "street_mugging"
const KIND_HOME_RAID := "home_raid"

const FORCED_KINDS: Array[String] = [KIND_MUGGING, KIND_ARCHIE_DEAL_MUGGING, KIND_STREET_MUGGING, KIND_HOME_RAID]


static func is_pending() -> bool:
	return GameState.state.get("combatPrep") != null


static func pending() -> Dictionary:
	var prep: Variant = GameState.state.get("combatPrep")
	return prep if prep is Dictionary else {}


static func is_forced(kind: String) -> bool:
	return FORCED_KINDS.has(kind)


# Parks the encounter in preparation and takes the screen over. Writes state
# only: nothing is spent and nothing rolls until commit().
static func request(kind: String, args: Dictionary = {}) -> void:
	var return_screen: String = GameState.state.get("currentScreen", "map")
	if return_screen == SCREEN:
		return_screen = str(pending().get("returnScreen", "map"))
	GameState.state["combatPrep"] = {
		"kind": kind, "args": args.duplicate(true), "forced": is_forced(kind),
		"returnScreen": return_screen,
	}
	GameState.state["currentScreen"] = SCREEN
	EventBus.screen_changed.emit(SCREEN)
	EventBus.state_changed.emit()
	MapEvents.abandon_playback()


# Planned encounter only. Returns false for a forced prep or when none is pending.
static func cancel() -> bool:
	var prep := pending()
	if prep.is_empty() or prep["forced"]:
		return false
	_clear_and_leave(str(prep["returnScreen"]))
	return true


# Fight: clears the prep, then runs the encounter's own entry. { ok, reason? };
# a refused entry (e.g. no blocks left) leaves the prep screen for the caller's
# previous screen.
static func commit() -> Dictionary:
	var prep := pending()
	if prep.is_empty():
		return { "ok": false, "reason": "Nothing to prepare." }
	GameState.state["combatPrep"] = null
	var result := _dispatch(str(prep["kind"]), prep["args"])
	if not result.get("ok", false):
		_leave(str(prep["returnScreen"]))
	return result


static func _dispatch(kind: String, args: Dictionary) -> Dictionary:
	match kind:
		KIND_VEIN_RAID:
			var vein: Variant = Sites.find_faction_vein(str(args["veinId"]))
			if vein == null:
				return { "ok": false, "reason": "That vein is gone." }
			return Raiding.begin_raid(vein, args.get("allyIds", []))
		KIND_STOCKPILE_RAID:
			return Raiding.begin_stockpile_raid(str(args["factionId"]), args.get("allyIds", []))
		KIND_VEIN_DEFEND:
			return { "ok": Raiding.trigger_defend(str(args["veinId"])) }
		KIND_HQ_DEFEND:
			return { "ok": Home.trigger_defend() }
		KIND_MUGGING:
			Combat.start_mugging(bool(args.get("veinIncluded", false)))
		KIND_ARCHIE_DEAL_MUGGING:
			Combat.start_archie_deal_mugging()
		KIND_STREET_MUGGING:
			Combat.start_street_mugging()
		KIND_HOME_RAID:
			Combat.start_home_raid_combat()
		KIND_DEBUG:
			Combat.start_debug_combat(str(args["context"]), str(args["locationKey"]), int(args["valueTier"]),
				int(args["guards"]), str(args["templateKey"]), args.get("allyIds", []))
		_:
			return { "ok": false, "reason": "Unknown encounter." }
	return { "ok": true }


static func _clear_and_leave(return_screen: String) -> void:
	GameState.state["combatPrep"] = null
	_leave(return_screen)


static func _leave(return_screen: String) -> void:
	GameState.state["currentScreen"] = return_screen
	EventBus.screen_changed.emit(return_screen)
	EventBus.state_changed.emit()


# ── who is in the fight ──────────────────────────────────────────────────

# [{ name, role: you|ally|foe, units: [{ recipe, tier }], note }] for the prep
# screen. Partner helpers are rolled when the fight starts, so they aren't listed.
static func participants(prep: Dictionary) -> Array:
	var kind := str(prep.get("kind", ""))
	var args: Dictionary = prep.get("args", {})
	var rows: Array = [{ "name": "You", "role": "you", "units": Loadout.equipped_units().duplicate(true), "note": "" }]
	for contact_id in _ally_contact_ids(kind, args):
		rows.append({ "name": Contacts.display_name(contact_id), "role": "ally", "units": _contact_units(contact_id), "note": "" })
	var guards := _ally_guard_count(kind, args)
	if guards > 0:
		rows.append({ "name": "Guards" if guards > 1 else "Guard", "role": "ally", "units": [], "note": "×%d" % guards })
	rows.append({ "name": foe_label(prep), "role": "foe", "units": [], "note": "" })
	return rows


static func _ally_contact_ids(kind: String, args: Dictionary) -> Array:
	var ids: Array = []
	match kind:
		KIND_MUGGING, KIND_ARCHIE_DEAL_MUGGING:
			ids.append("archie")
		KIND_VEIN_RAID, KIND_STOCKPILE_RAID, KIND_DEBUG:
			for contact_id in args.get("allyIds", []):
				if Contacts.can_join_combat(contact_id):
					ids.append(contact_id)
		KIND_VEIN_DEFEND:
			for contact_id in GameState.state["contacts"].keys():
				if Contacts.can_join_combat(contact_id):
					ids.append(contact_id)
	return ids


static func _ally_guard_count(kind: String, args: Dictionary) -> int:
	match kind:
		KIND_HQ_DEFEND:
			return Home.get_guard_count()
		KIND_VEIN_DEFEND:
			var vein: Variant = Cultivating.find_vein(str(args.get("veinId", "")))
			return 0 if vein == null else Cultivating.vein_guard_count(vein)
	return 0


static func _contact_units(contact_id: String) -> Array:
	var units: Array = []
	if not GameState.state["contacts"].get(contact_id, {}).has("loadout"):
		return units
	for i in range(Loadout.slot_count()):
		var entry: Variant = Loadout.slot(i, contact_id)
		if entry is Dictionary:
			units.append(entry.duplicate(true))
	return units


# PROSE-REVIEW: opposition labels on the prep screen.
static func foe_label(prep: Dictionary) -> String:
	var args: Dictionary = prep.get("args", {})
	match str(prep.get("kind", "")):
		KIND_VEIN_RAID:
			var vein: Variant = Sites.find_faction_vein(str(args.get("veinId", "")))
			return "Vein guards" if vein == null else "%s guards" % GameData.FACTIONS[vein["factionId"]]["shortName"]
		KIND_STOCKPILE_RAID:
			return "%s stockpile guards" % GameData.FACTIONS[str(args["factionId"])]["shortName"]
		KIND_VEIN_DEFEND:
			var attacker := str(args.get("attackerId", ""))
			return "Raiders" if attacker == "" else "%s raiders" % GameData.FACTIONS[attacker]["shortName"]
		KIND_HQ_DEFEND, KIND_HOME_RAID:
			return "Raider"
		KIND_DEBUG:
			return "Raid guards"
	return "Muggers"


static func title(prep: Dictionary) -> String:
	match str(prep.get("kind", "")):
		KIND_VEIN_RAID, KIND_STOCKPILE_RAID:
			return "Raid"
		KIND_VEIN_DEFEND, KIND_HQ_DEFEND:
			return "Defend"
		KIND_DEBUG:
			return "Debug fight"
	return "Trouble"

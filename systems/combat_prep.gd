class_name CombatPrep
extends RefCounted

# Pending pre-fight preparation (R§3.7 "Preparation"). Every combat entry path
# parks here as state.combatPrep before its costs, rolls or first turn:
#   { kind, args, forced, returnScreen, loadoutEdit? }
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
	var prep_args := args.duplicate(true)
	if kind == KIND_VEIN_DEFEND or kind == KIND_HQ_DEFEND:
		# Defences open with every eligible recruit chosen, in contact order.
		prep_args["allyIds"] = recruit_pool(kind)
	GameState.state["combatPrep"] = {
		"kind": kind, "args": prep_args, "forced": is_forced(kind),
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
			return Raiding.begin_raid(vein, chosen_recruits(kind, args))
		KIND_STOCKPILE_RAID:
			return Raiding.begin_stockpile_raid(str(args["factionId"]), chosen_recruits(kind, args))
		KIND_VEIN_DEFEND:
			return { "ok": Raiding.trigger_defend(str(args["veinId"]), chosen_recruits(kind, args)) }
		KIND_HQ_DEFEND:
			return { "ok": Home.trigger_defend(chosen_recruits(kind, args)) }
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
	match kind:
		KIND_MUGGING, KIND_ARCHIE_DEAL_MUGGING:
			return ["archie"]
		KIND_DEBUG:
			return args.get("allyIds", []).filter(Contacts.can_join_combat)
	return chosen_recruits(kind, args)


# ── recruit selection (R§3.7a "Preparation") ─────────────────────────────

# Planned raids and defences let the player pick and order recruits; muggings,
# scripted fights and the debug setup keep their own roster.
static func has_recruit_choice(kind: String) -> bool:
	return kind == KIND_VEIN_RAID or kind == KIND_STOCKPILE_RAID or kind == KIND_VEIN_DEFEND or kind == KIND_HQ_DEFEND


static func _recruit_eligible(kind: String, contact_id: String) -> bool:
	if kind == KIND_VEIN_RAID or kind == KIND_STOCKPILE_RAID:
		return Contacts.can_assist_raid(contact_id)
	return Contacts.can_join_combat(contact_id)


# Every recruit this encounter could take right now, in contact order.
static func recruit_pool(kind: String) -> Array:
	var ids: Array = []
	if not has_recruit_choice(kind):
		return ids
	for contact_id in GameState.state["contacts"].keys():
		if _recruit_eligible(kind, contact_id):
			ids.append(contact_id)
	return ids


# The chosen recruits still eligible, in chosen order; what the fight receives.
static func chosen_recruits(kind: String, args: Dictionary) -> Array:
	var ids: Array = []
	if not has_recruit_choice(kind):
		return ids
	for contact_id in args.get("allyIds", []):
		if _recruit_eligible(kind, contact_id) and not ids.has(contact_id):
			ids.append(contact_id)
	return ids


# Chosen recruits first (in order), then eligible ones left behind.
static func recruit_options(prep: Dictionary) -> Array:
	var kind := str(prep.get("kind", ""))
	var options: Array = chosen_recruits(kind, prep.get("args", {}))
	for contact_id in recruit_pool(kind):
		if not options.has(contact_id):
			options.append(contact_id)
	return options


static func toggle_recruit(contact_id: String) -> bool:
	var prep := pending()
	var kind := str(prep.get("kind", ""))
	if prep.is_empty() or not _recruit_eligible(kind, contact_id) or not has_recruit_choice(kind):
		return false
	var ids := chosen_recruits(kind, prep["args"])
	if ids.has(contact_id):
		ids.erase(contact_id)
	else:
		ids.append(contact_id)
	prep["args"]["allyIds"] = ids
	EventBus.state_changed.emit()
	return true


# Moves a chosen recruit one place earlier (-1) or later (+1) in the order.
static func move_recruit(contact_id: String, step: int) -> bool:
	var prep := pending()
	if prep.is_empty():
		return false
	var ids := chosen_recruits(str(prep["kind"]), prep["args"])
	var from := ids.find(contact_id)
	var to := from + step
	if from == -1 or to < 0 or to >= ids.size():
		return false
	ids.remove_at(from)
	ids.insert(to, contact_id)
	prep["args"]["allyIds"] = ids
	EventBus.state_changed.emit()
	return true


# ── loadout warning and Change loadout (R§3.7 "Preparation") ─────────────

# Owner ids ("" = player) of participants whose personal loadout is editable.
static func loadout_owner_ids(prep: Dictionary) -> Array:
	var ids: Array = [""]
	for contact_id in _ally_contact_ids(str(prep.get("kind", "")), prep.get("args", {})):
		if GameState.state["contacts"].get(contact_id, {}).has("loadout"):
			ids.append(contact_id)
	return ids


# Names of participants with an empty slot while eligible unequipped stock exists.
static func loadout_warning_names(prep: Dictionary) -> Array:
	var names: Array = []
	for owner_id in loadout_owner_ids(prep):
		if Loadout.equippable_stock(owner_id).is_empty():
			continue
		for i in range(Loadout.slot_count()):
			if Loadout.slot(i, owner_id) == null:
				names.append("You" if owner_id == "" else Contacts.display_name(owner_id))
				break
	return names


static func is_editing_loadout() -> bool:
	return bool(pending().get("loadoutEdit", false))


# Opens Profile focused on the participants. The prep stays pending, uncommitted.
static func change_loadout() -> bool:
	var prep := pending()
	if prep.is_empty():
		return false
	prep["loadoutEdit"] = true
	Nav.go_to("phone")
	PhoneNav.open_app("profile")
	return true


# Back from Profile to the same pending encounter.
static func finish_loadout_edit() -> void:
	var prep := pending()
	if not prep.is_empty():
		prep.erase("loadoutEdit")
	PhoneNav.go_home()
	Nav.go_to(SCREEN)


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

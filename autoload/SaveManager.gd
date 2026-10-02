extends Node

# Save/load/autosave/export-import per R§6. 3 manual slots + 3 rotating
# autosaves. autosave() is called from daily_tick, exit_combat, event
# completion, and every successful cash purchase.

const SAVE_VERSION := 3
const SLOT_COUNT := 3
const AUTOSAVE_COUNT := 3
const SAVES_DIR := "user://saves/"
const AUTOSAVE_DIR := "user://autosave/"


func slot_path(slot: int) -> String:
	return SAVES_DIR + "slot_%d.json" % slot


func autosave_path(index: int) -> String:
	return AUTOSAVE_DIR + "autosave_%d.json" % index


func slot_exists(slot: int) -> bool:
	return FileAccess.file_exists(slot_path(slot))


# Non-destructive peek at a slot's headline numbers for the save screen —
# unlike load_from_slot, does NOT touch GameState.state. Empty dict if the
# slot doesn't exist or is unreadable.
func slot_summary(slot: int) -> Dictionary:
	var path := slot_path(slot)
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed == null or typeof(parsed) != TYPE_DICTIONARY:
		return {}
		# JSON returns numbers as float; cast explicitly (see _restore_int_types).
	return {
		"day": int(parsed.get("world", {}).get("day", 0)),
		"cash": int(parsed.get("player", {}).get("cash", 0)),
	}


func save_to_slot(slot: int) -> Dictionary:
	DirAccess.make_dir_recursive_absolute(SAVES_DIR)
	return _write_json(slot_path(slot), GameState.state)


func load_from_slot(slot: int) -> Dictionary:
	return _load_json_into_state(slot_path(slot))


func delete_slot(slot: int) -> void:
	var path := slot_path(slot)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


# Writes to whichever of the AUTOSAVE_COUNT rotation slots is emptiest/
# oldest, so the 3 most recent autosaves survive.
func autosave() -> Dictionary:
	DirAccess.make_dir_recursive_absolute(AUTOSAVE_DIR)
	var index := _find_autosave_slot_to_write()
	return _write_json(autosave_path(index), GameState.state)


func _find_autosave_slot_to_write() -> int:
	var oldest_index := 0
	var oldest_time := -1
	for i in range(AUTOSAVE_COUNT):
		var path := autosave_path(i)
		if not FileAccess.file_exists(path):
			return i
		var mtime := FileAccess.get_modified_time(path)
		if oldest_time == -1 or mtime < oldest_time:
			oldest_time = mtime
			oldest_index = i
	return oldest_index


func export_string() -> String:
	return JSON.stringify(GameState.state)


func import_string(text: String) -> Dictionary:
	var parsed = JSON.parse_string(text)
	if parsed == null or typeof(parsed) != TYPE_DICTIONARY:
		return { "ok": false, "reason": "Invalid save data." }
	return _load_save_dict(parsed)


func _write_json(path: String, data: Dictionary) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return { "ok": false, "reason": "Could not open %s for writing (error %d)." % [path, FileAccess.get_open_error()] }
	file.store_string(JSON.stringify(data))
	return { "ok": true }


func _load_json_into_state(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return { "ok": false, "reason": "No save at %s." % path }
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return { "ok": false, "reason": "Could not open %s for reading (error %d)." % [path, FileAccess.get_open_error()] }
	var text := file.get_as_text()
	var parsed = JSON.parse_string(text)
	if parsed == null or typeof(parsed) != TYPE_DICTIONARY:
		return { "ok": false, "reason": "Corrupt save data." }
	return _load_save_dict(parsed)


func _load_save_dict(raw: Dictionary) -> Dictionary:
	var version_check := _check_save_version(raw)
	if not version_check["ok"]:
		return version_check

	var filled := backfill_defaults(raw)
	_restore_int_types(filled)
	_clamp_loaded_combat_selection(filled)
	_migrate_vein_station_veins(filled)
	_strip_unowned_cultivator_veins(filled)
	_fix_up_founders(filled)
	_migrate_nadia_supply_order(filled)
	_migrate_faction_holdings(filled)
	_migrate_player_model(filled)
	_migrate_weekly_cadence(filled)
	_migrate_drop_delegation(filled)
	_remap_retired_screen_id(filled)
	_remap_retired_messages_list(filled)
	_remap_retired_lab_screen(filled)
	_remap_retired_notes_app(filled)
	GameState.state = filled
	EventBus.state_changed.emit()
	return { "ok": true }


# R§3.10 "Weekly cadence": every offer's weekday is Monday, and an active
# recurring contract due on another weekday moves to the next Monday. The
# home arrears clock counts weeks (ADR 0006 "Weekly ordering"): a day count
# rounds up to whole weeks.
func _migrate_weekly_cadence(state: Dictionary) -> void:
	var home: Dictionary = state.get("home", {})
	if home.has("arrearsDays"):
		home["arrearsWeeks"] = ceili(float(home["arrearsDays"]) / float(Calendar.days_per_week()))
		home.erase("arrearsDays")
	var sales: Dictionary = state.get("sales", {})
	for offer in sales.get("pendingOffers", []):
		offer["weekday"] = Offers.RECURRING_WEEKDAY
	for contract in sales.get("activeContracts", []):
		contract["weekday"] = Offers.RECURRING_WEEKDAY
		if contract.get("contractType") == "recurring":
			contract["dueDay"] = Calendar.monday_on_or_after(int(contract["dueDay"]))


# Sales delivers every contract (R§3.10 "Sales delivery"); per-contract
# delegation fields are dropped. Between Beat 1 and the Staff tab opening,
# Archie holds Sales, as the Beat 1 scene now sets.
func _migrate_drop_delegation(state: Dictionary) -> void:
	for contract in state.get("sales", {}).get("activeContracts", []):
		contract.erase("delegated")
		contract.erase("delegatedWholePeriod")
	var flags: Dictionary = state.get("flags", {})
	var archie: Dictionary = state.get("contacts", {}).get("archie", {})
	if flags.get("bizArchieSalesRole", false) and not flags.get("bizStaffTabOpen", false) \
			and archie.get("assignedRole") == null and archie.get("assignedRoom") == null:
		archie["assignedRole"] = "sales"


# A save's top-level owenTexts becomes contactTexts.owen.
func _migrate_owen_texts(save: Dictionary) -> void:
	if not save.has("owenTexts"):
		return
	var old: Variant = save["owenTexts"]
	save.erase("owenTexts")
	if old is Dictionary and not save["contactTexts"].has("owen"):
		save["contactTexts"]["owen"] = old


# player.model is a data/combat_visuals.json templates key; the "protagonist2"
# sprite set is keyed "territorial3".
func _migrate_player_model(save: Dictionary) -> void:
	var player: Dictionary = save.get("player", {})
	if player.get("model", "") == "protagonist2":
		player["model"] = "territorial3"


# A save without faction holdings gets the placeholder starting stock, with
# any saved per-ore oreStock added on top; faction cash is left as saved.
# A faction without a stockpile gets one picked now, and one without
# stockpile guards gets its full guard target; missing consumption
# keys (kitBurns, shortfall, consumeAccrued) start empty. Faction veins
# without a kit get one from FactionSim.allocate_kits_in.
func _migrate_faction_holdings(save: Dictionary) -> void:
	for faction_id in save.get("factions", {}):
		var faction: Dictionary = save["factions"][faction_id]
		if not faction.has("holdings"):
			faction["holdings"] = FactionSim.starting_holdings(faction_id)
			var ore: Dictionary = faction["holdings"]["ore"]
			var old_stock: Dictionary = faction.get("oreStock", {})
			for ore_type in old_stock:
				ore[ore_type] = int(ore.get(ore_type, 0)) + int(old_stock[ore_type])
		faction.erase("oreStock")
		if not faction.has("stockpile"):
			faction["stockpile"] = FactionSim.pick_stockpile(faction_id)
		if not faction["stockpile"].has("guards"):
			faction["stockpile"]["guards"] = FactionSim.stockpile_guard_target(faction_id)
		if not faction.has("kitBurns"):
			faction["kitBurns"] = []
		if not faction.has("shortfall"):
			faction["shortfall"] = {}
		if not faction.has("consumeAccrued"):
			faction["consumeAccrued"] = {}
	for site in save.get("world", {}).get("sites", []):
		var vein: Variant = site.get("factionVein")
		if vein != null and not vein.has("kit"):
			FactionSim.allocate_kits_in(save)
			break


# A save with an in-progress col_a1_nadia_supply objective can't identify
# which Collective door handled qualifying time-calc sales made before this
# migration existed, so it receives one compatibility credit exactly once;
# a completed objective is preserved without re-running its reward.
func _migrate_nadia_supply_order(save: Dictionary) -> void:
	var objectives: Dictionary = save.get("objectives", {})
	var runtime: Dictionary = objectives.get("col_a1_nadia_supply", {})
	var flags: Dictionary = save.get("flags", {})
	if runtime.get("complete", false) or flags.get("colA1NadiaSupplied", false):
		runtime["active"] = true
		runtime["complete"] = true
		objectives["col_a1_nadia_supply"] = runtime
		flags["colA1NadiaSupplied"] = true
		save["objectives"] = objectives
		save["flags"] = flags
		return
	if not flags.get("colA1NadiaMet", false) or runtime.get("progress", {}).has("delivered"):
		return

	var faction: Dictionary = save.get("factions", {}).get("collective", {})
	var current: Dictionary = faction.get("oreSold", {}).get("time", {})
	var baseline: Dictionary = runtime.get("progress", {}).get("baseline", {})
	var delivered := clampi(int(current.get("units", 0)) - int(baseline.get("units", 0)), 0, int(GameData.OBJECTIVES["col_a1_nadia_supply"]["params"]["qty"]))
	runtime["active"] = true
	runtime["complete"] = false
	runtime["progress"] = { "delivered": delivered, "legacyCredit": true }
	objectives["col_a1_nadia_supply"] = runtime
	save["objectives"] = objectives


# home/you/bag/inventory are retired screen ids, not tied to any
# particular saveVersion (any save ever written could carry one), so this
# lives outside the version-keyed migrate() table. A save with one of
# these in currentScreen lands on the phone app grid on load instead of
# soft-locking, and additionally resets phoneNav to its home view --
# Main.gd's resolve_screen_id() covers the same case on the render side
# but must not mutate state, so it deliberately leaves phoneNav alone.
const RETIRED_CURRENT_SCREENS := ["home", "you", "bag", "inventory"]


func _remap_retired_screen_id(save: Dictionary) -> void:
	if not RETIRED_CURRENT_SCREENS.has(save.get("currentScreen", "")):
		return
	save["currentScreen"] = "phone"
	var phone_nav: Dictionary = save.get("phoneNav", {})
	phone_nav["app"] = "home"
	phone_nav["selectedAxis"] = null
	phone_nav["confirmingNewGame"] = false
	save["phoneNav"] = phone_nav


# A save can have phoneNav.app == "messages" with no selectedContactId --
# a state MessagesApp.build() can't render (it assumes a contact is always
# selected). Remaps back to the home grid, same as _remap_retired_screen_id().
func _remap_retired_messages_list(save: Dictionary) -> void:
	var phone_nav: Dictionary = save.get("phoneNav", {})
	if phone_nav.get("app") == "messages" and phone_nav.get("selectedContactId") == null:
		phone_nav["app"] = "home"
		save["phoneNav"] = phone_nav


# "lab" has no surviving app-grid equivalent, so it lands on "hq" (whose
# "lab" zone opens hq_lab_bench) instead of "phone". No phoneNav reset
# needed: state.benchNav has no field to read back into on a fresh state.
func _remap_retired_lab_screen(save: Dictionary) -> void:
	if save.get("currentScreen", "") == "lab":
		save["currentScreen"] = "hq"


# "notes" is the ToDo app's retired id; a save left open on it reopens ToDo.
# Grid slot order comes from PhoneApps.apps(), never the save, so nothing
# else carries the id.
func _remap_retired_notes_app(save: Dictionary) -> void:
	var phone_nav: Dictionary = save.get("phoneNav", {})
	if phone_nav.get("app") == "notes":
		phone_nav["app"] = "todo"
		save["phoneNav"] = phone_nav


# A save whose meta.saveVersion doesn't match SAVE_VERSION is rejected
# outright with a clear reason rather than half-loaded (R§6: no migrator
# for a save-breaking schema rewrite). A save with no meta.saveVersion at
# all is treated as current (matches new_game_state()'s own default).
# v3's break: every site now carries a stamped slotIndex MapLayout.
# assign_positions() depends on, with no way to reconstruct historical
# discovery order for an older save to backfill it from.
func _check_save_version(save: Dictionary) -> Dictionary:
	var meta: Dictionary = save.get("meta", {})
	var version: int = meta.get("saveVersion", SAVE_VERSION)
	if version != SAVE_VERSION:
		return { "ok": false, "reason": "This save is from an older version of the game (v%d) and can't be loaded. Start a new game." % version }
	return { "ok": true }


# Fills any missing TOP-LEVEL keys from a fresh new_game_state() (R§6:
# "validates required top-level keys and fills missing keys from
# defaults"). Existing top-level keys are kept as-is, even if something
# nested under them is itself missing -- intentionally shallow, not a deep
# recursive merge. The _backfill_new_*_keys() functions below cover the
# cases that shallow fill can't: a key added inside an already-present
# top-level dict (or, for _backfill_new_contacts, a whole new contact id
# added inside the already-present "contacts" dict). Each seeds only what's
# missing from the matching default, never touching a key/id the save already has.
func backfill_defaults(save: Dictionary) -> Dictionary:
	var defaults := GameState.new_game_state()
	var result: Dictionary = save.duplicate(true)
	var had_stances := result.has("factionStances")
	# A save from before the market existed starts at resting prices, not base.
	if not result.has("market"):
		result["market"] = Market.new_state(true)
	for key in defaults.keys():
		if not result.has(key):
			result[key] = defaults[key]
	# Staff wages all go through Business (R§3.10 "Business pot and payday").
	result.erase("payroll")
	_migrate_owen_texts(result)
	_backfill_new_contacts(result, defaults)
	_backfill_new_contact_keys(result, defaults)
	_backfill_contact_combat_kits(result, defaults)
	_backfill_new_collective_keys(result, defaults)
	_backfill_new_world_keys(result, defaults)
	_backfill_new_player_keys(result, defaults)
	_backfill_new_home_keys(result, defaults)
	_backfill_new_sales_keys(result, defaults)
	_backfill_new_combat_keys(result, defaults)
	_backfill_new_flag_keys(result, defaults)
	_backfill_new_business_keys(result, defaults)
	_backfill_new_guard_upkeep_keys(result, defaults)
	_backfill_new_faction_war_keys(result, defaults)
	_backfill_new_faction_conclave_keys(result, defaults)
	_backfill_vein_guard_kits(result)
	_backfill_expense_kinds(result)
	FactionAI.migrate_save(result, had_stances)
	return result


# Every player vein carries a guardKit (spec §State); a save without one gets {}.
func _backfill_vein_guard_kits(result: Dictionary) -> void:
	for vein in result["player"].get("veins", []):
		if not (vein.get("guardKit") is Dictionary):
			vein["guardKit"] = {}


# A guardUpkeep key added after the save was made (e.g. pendingShortfall)
# starts at its new-game default.
func _backfill_new_guard_upkeep_keys(result: Dictionary, defaults: Dictionary) -> void:
	var guard_upkeep: Dictionary = result["guardUpkeep"]
	for key in defaults["guardUpkeep"].keys():
		if not guard_upkeep.has(key):
			guard_upkeep[key] = GameState.deep_copy(defaults["guardUpkeep"][key])


# A factionWar key added after the save was made (e.g. truces) starts at
# its new-game default.
func _backfill_new_faction_war_keys(result: Dictionary, defaults: Dictionary) -> void:
	var war: Dictionary = result["factionWar"]
	for key in defaults["factionWar"].keys():
		if not war.has(key):
			war[key] = GameState.deep_copy(defaults["factionWar"][key])


# A factionConclave key added after the save was made (e.g. stockpile)
# starts at its new-game default.
func _backfill_new_faction_conclave_keys(result: Dictionary, defaults: Dictionary) -> void:
	var conclave: Dictionary = result["factionConclave"]
	for key in defaults["factionConclave"].keys():
		if not conclave.has(key):
			conclave[key] = GameState.deep_copy(defaults["factionConclave"][key])


# A business key added after the save was made (e.g. float) starts at its
# new-game default.
func _backfill_new_business_keys(result: Dictionary, defaults: Dictionary) -> void:
	var business: Dictionary = result["business"]
	for key in defaults["business"].keys():
		if not business.has(key):
			business[key] = GameState.deep_copy(defaults["business"][key])


# Stats tallies saved before expenses were split by kind read each kind as 0;
# their unsplit total stays in "expenses".
func _backfill_expense_kinds(result: Dictionary) -> void:
	var business_stats: Dictionary = result.get("businessStats", {})
	var records: Array = business_stats.get("days", []).duplicate()
	if business_stats.has("today"):
		records.append(business_stats["today"])
	for record in records:
		for metric in BusinessStats.EXPENSE_KIND_METRICS.values():
			if not record.has(metric):
				record[metric] = 0


# A flag added after the save was made starts at its new-game default.
func _backfill_new_flag_keys(result: Dictionary, defaults: Dictionary) -> void:
	var flags: Dictionary = result["flags"]
	for key in defaults["flags"].keys():
		if not flags.has(key):
			flags[key] = defaults["flags"][key]


# A save made mid-fight before a combat key existed (e.g. locationKey) gets
# the fresh default, which for locationKey means "no location plate".
func _backfill_new_combat_keys(result: Dictionary, defaults: Dictionary) -> void:
	if not result.has("combat"):
		return
	var combat: Dictionary = result["combat"]
	var default_combat: Dictionary = defaults["combat"]
	for key in default_combat.keys():
		if not combat.has(key):
			combat[key] = default_combat[key].duplicate(true) if default_combat[key] is Array or default_combat[key] is Dictionary else default_combat[key]


# A mid-fight save whose selection was backfilled (or otherwise points at
# a koed/missing combatant) gets the same KO-clamp a live KO would.
func _clamp_loaded_combat_selection(state: Dictionary) -> void:
	var combat: Dictionary = state.get("combat", {})
	if combat.get("active", false):
		Combat.clamp_selection(combat)


func _backfill_new_sales_keys(result: Dictionary, defaults: Dictionary) -> void:
	if not result.has("sales"):
		return
	var sales: Dictionary = result["sales"]
	var default_sales: Dictionary = defaults["sales"]
	for key in default_sales.keys():
		if not sales.has(key):
			sales[key] = default_sales[key].duplicate(true) if default_sales[key] is Array or default_sales[key] is Dictionary else default_sales[key]
	for contract in sales.get("activeContracts", []):
		if not contract.has("periodId"):
			contract["periodId"] = "period-%d" % int(sales["nextPeriodId"])
			sales["nextPeriodId"] += 1
		if not sales["priorityOrder"].has(contract["id"]):
			sales["priorityOrder"].append(contract["id"])
	# R§3.10 "Offer price and expiry": a contract's quote is its signedQuote.
	for contract in sales.get("activeContracts", []):
		_rename_quote_to_signed(contract)
	for entry in sales.get("contractHistory", []):
		if entry.get("contract") is Dictionary:
			_rename_quote_to_signed(entry["contract"])
	# R§3.10 "Counterparty": offers/contracts from before counterparties exist.
	for entry in sales.get("pendingOffers", []) + sales.get("activeContracts", []):
		Offers.ensure_counterparty(entry, result.get("factions", {}))


func _rename_quote_to_signed(contract: Dictionary) -> void:
	if contract.has("quote") and not contract.has("signedQuote"):
		contract["signedQuote"] = contract["quote"]
		contract.erase("quote")


# R§3.10 "Staff roles": the single shared veinStationVeins list moves onto
# the Station occupant's cultivatorVeins list, or Owen's if he is the only
# cultivator; with neither, the assignments are dropped (targets are kept).
# Runs before _fix_up_founders, which may clear a founder's Station room.
func _migrate_vein_station_veins(state: Dictionary) -> void:
	if not state.has("veinStationVeins"):
		return
	var old_list: Array = state["veinStationVeins"]
	state.erase("veinStationVeins")
	if old_list.is_empty():
		return
	var contacts: Dictionary = state.get("contacts", {})
	var occupant: Variant = null
	var cultivators: Array = []
	for contact_id in contacts.keys():
		var c: Dictionary = contacts[contact_id]
		if not c.get("recruited", false):
			continue
		if c.get("assignedRoom") == "veinStation":
			occupant = contact_id
		if c.get("assignedRoom") == "veinStation" or c.get("assignedRole") == "cultivation":
			cultivators.append(contact_id)
	var destination: Variant = occupant
	if destination == null and cultivators == ["owen"]:
		destination = "owen"
	if destination == null:
		return
	var lists: Dictionary = state["cultivatorVeins"]
	if not lists.has(destination):
		lists[destination] = []
	for vein_id in old_list:
		if not lists[destination].has(vein_id):
			lists[destination].append(vein_id)


# R§3.10 "Staff roles": a cultivator list only holds veins the player owns.
func _strip_unowned_cultivator_veins(state: Dictionary) -> void:
	var owned: Dictionary = {}
	for vein in state.get("player", {}).get("veins", []):
		owned[vein["id"]] = true
	var lists: Dictionary = state.get("cultivatorVeins", {})
	for contact_id in lists.keys():
		lists[contact_id] = lists[contact_id].filter(func(vein_id): return owned.has(vein_id))


# R§3.10 "Staff roles": recruitable follows constants.json (Archie/James
# recruit only by story), the home-raid debrief recruits Archie, and a
# founder saved in a role-room holds that role room-free instead.
func _fix_up_founders(state: Dictionary) -> void:
	if not state.has("contacts"):
		return
	var contacts: Dictionary = state["contacts"]
	for contact_id in contacts.keys():
		var c: Dictionary = contacts[contact_id]
		if GameData.CONTACTS_DEFAULTS.has(contact_id):
			c["recruitable"] = GameData.CONTACTS_DEFAULTS[contact_id].get("recruitable", true)
		var room: Variant = c.get("assignedRoom")
		var room_roles := Contacts.room_roles()
		if Contacts.is_founder(contact_id) and room != null and room_roles.has(room):
			c["assignedRole"] = room_roles[room]
			c["assignedRoom"] = null
	if state.get("flags", {}).get("homeRaidEventSeen", false) and contacts.has("archie"):
		contacts["archie"]["recruited"] = true


func _backfill_new_contacts(result: Dictionary, defaults: Dictionary) -> void:
	if not result.has("contacts"):
		return
	var contacts: Dictionary = result["contacts"]
	for contact_id in defaults["contacts"].keys():
		if not contacts.has(contact_id):
			contacts[contact_id] = defaults["contacts"][contact_id]


# A contact saved before constants.json gave them a combat kit carries
# combatHpMax 0 (present, so _backfill_new_contact_keys skips it) -- adopt
# the default kit whole. Never touches a contact that already had one.
func _backfill_contact_combat_kits(result: Dictionary, defaults: Dictionary) -> void:
	if not result.has("contacts"):
		return
	var contacts: Dictionary = result["contacts"]
	var default_contacts: Dictionary = defaults["contacts"]
	for contact_id in contacts.keys():
		if not default_contacts.has(contact_id):
			continue
		var contact: Dictionary = contacts[contact_id]
		var fresh: Dictionary = default_contacts[contact_id]
		if int(contact.get("combatHpMax", 0)) > 0 or int(fresh["combatHpMax"]) <= 0:
			continue
		for key in ["combatHpMax", "combatHp", "combatAttackMin", "combatAttackMax", "combatStashMax", "combatStash", "combatHealAmount", "combatSpeed", "koCooldownDays", "dialCharges"]:
			contact[key] = fresh[key]


func _backfill_new_contact_keys(result: Dictionary, defaults: Dictionary) -> void:
	if not result.has("contacts"):
		return
	var contacts: Dictionary = result["contacts"]
	var default_contacts: Dictionary = defaults["contacts"]
	for contact_id in contacts.keys():
		if not default_contacts.has(contact_id):
			continue
		var contact: Dictionary = contacts[contact_id]
		for key in default_contacts[contact_id].keys():
			if not contact.has(key):
				contact[key] = default_contacts[contact_id][key]


func _backfill_new_collective_keys(result: Dictionary, defaults: Dictionary) -> void:
	if not result.has("collective"):
		return
	var collective: Dictionary = result["collective"]
	for key in defaults["collective"].keys():
		if not collective.has(key):
			collective[key] = defaults["collective"][key]


func _backfill_new_world_keys(result: Dictionary, defaults: Dictionary) -> void:
	if not result.has("world"):
		return
	var world: Dictionary = result["world"]
	for key in defaults["world"].keys():
		if not world.has(key):
			world[key] = defaults["world"][key]


# A pre-Dial save's devicesInProgress/devicesCompleted/equipment.device
# are deliberately left untouched here -- they migrate into a null
# player.dial, not a converted one, per the PRD. craftingUnlocked/
# enhancementUnlocked live under "flags", a separate top-level key this
# function doesn't touch, so they survive automatically.
func _backfill_new_player_keys(result: Dictionary, defaults: Dictionary) -> void:
	if not result.has("player"):
		return
	var player: Dictionary = result["player"]
	for key in defaults["player"].keys():
		if not player.has(key):
			player[key] = defaults["player"][key]


func _backfill_new_home_keys(result: Dictionary, defaults: Dictionary) -> void:
	if not result.has("home"):
		return
	var home: Dictionary = result["home"]
	# Pre-tenure saves paid upgradeCost to move up, so they own their tier;
	# the bedsit is rent-only (ADR 0006 §Migration).
	if not home.has("tenure"):
		home["tenure"] = Home.TENURE_RENTED if home.get("tier", "bedsit") == "bedsit" else Home.TENURE_OWNED
	for key in defaults["home"].keys():
		if not home.has(key):
			home[key] = defaults["home"][key]


# JSON has no int/float distinction, so every number in a just-parsed save
# comes back as a float -- Godot's Dictionary/Array equality treats
# int(1) and float(1.0) as distinct once nested inside a container, and
# real game code assumes these fields stay ints: maxi()/mini()/clampi()
# calls (barometer.gd, combat.gd) require int arguments, and formatting
# like "£%d" % cash would misbehave. Restore ints in place, per R§2's
# schema, immediately after backfill so every top-level key is guaranteed
# present. Genuinely-float fields (combat.evadeChance, combatPrototype.
# enemy.evadeChance, mapView.zoom) are deliberately left untouched.
func _restore_int_types(state: Dictionary) -> void:
	_int_key(state, "pendingSaleCut")
	_int_key(state, "pendingArchieDealCut")
	_int_dict_values(state.get("labThresholds", {}))
	Rooms.clamp_lab_thresholds(state.get("labThresholds", {}))
	_int_dict_values(state.get("veinStationTargets", {}))
	var sales: Dictionary = state.get("sales", {})
	for key in ["nextOfferId", "nextContractId", "nextPeriodId", "nextSettlementId"]:
		_int_key(sales, key)
	for offer in sales.get("pendingOffers", []):
		for key in ["createdDay", "expiresDay", "weekday", "deadlineAfterDays", "extraTypeDeadlineDays"]:
			_int_key(offer, key)
		_restore_request_int_types(offer.get("request", {}))
		_restore_quote_int_types(offer.get("quote", {}))
	for contract in sales.get("activeContracts", []):
		_restore_contract_int_types(contract)
	for settlement in sales.get("settlements", []):
		_restore_settlement_int_types(settlement)
	# Each entry embeds its own full copies of a settled contract/settlement
	# (systems/contracts.gd's settle()), not references into activeContracts/
	# settlements above -- same nested request/quote/delivered shape, so it
	# needs the same restoration applied separately.
	for entry in sales.get("contractHistory", []):
		_restore_contract_int_types(entry.get("contract", {}))
		_restore_settlement_int_types(entry.get("settlement", {}))
		_int_key(entry, "cancelledDay")
		_int_key(entry, "expiredDay")
	for notification in state.get("notifications", []):
		_int_key(notification, "day")
	for bank_entry in state.get("bankLog", []):
		_int_key(bank_entry, "amount")
		_int_key(bank_entry, "day")
	var morning_accounts: Dictionary = state.get("morningAccounts", {})
	_int_key(morning_accounts, "autoOpenedDay")
	var block_production: Dictionary = morning_accounts.get("blockProduction", {})
	_int_dict_values(block_production.get("ore", {}))
	_int_dict_values(block_production.get("items", {}))
	_int_dict_values(block_production.get("oreMovement", {}))
	for day_record in state.get("productionLog", []):
		_int_key(day_record, "day")
		for block_record in day_record.get("blocks", []):
			_int_key(block_record, "block")
			for entry in block_record.get("entries", []):
				for recipe_key in entry.get("made", {}):
					_int_dict_values(entry["made"][recipe_key])
				_int_dict_values(entry.get("failed", {}))
	var market: Dictionary = state.get("market", {})
	_int_key(market, "startedDay")
	for kind_goods in market.get("goods", {}).values():
		for good in kind_goods.values():
			_int_key(good, "stock")
			_int_key(good, "price")
			_int_key(good, "prevPrice")
			_int_array_values(good.get("history", []))
	for side in ["supply", "demand"]:
		for by_type in market.get(side, {}).values():
			for by_source in by_type.values():
				_int_dict_values(by_source)
	for note in market.get("annotations", []):
		_int_key(note, "day")
		_int_key(note, "value")
	for delivery in market.get("deliveries", []):
		_int_key(delivery, "day")
		_int_key(delivery, "qty")
	for entry in market.get("salesHistory", []):
		_int_key(entry, "day")
		for by_type in entry.get("supply", {}).values():
			for by_source in by_type.values():
				_int_dict_values(by_source)
	for bucket in state.get("shares", {}).get("days", []):
		_int_key(bucket, "day")
		for tally in ["ore", "craft"]:
			for by_type in bucket.get(tally, {}).values():
				_int_dict_values(by_type)
		_int_dict_values(bucket.get("deliveries", {}))
		_int_dict_values(bucket.get("londonBuys", {}))
	var business_stats: Dictionary = state.get("businessStats", {})
	_int_dict_values(business_stats.get("today", {}))
	for record in business_stats.get("days", []):
		_int_dict_values(record)
	for record in state.get("guardUpkeep", {}).get("history", []):
		_int_key(record, "day")
		_int_dict_values(record.get("places", {}))
	var shortfall = state.get("guardUpkeep", {}).get("pendingShortfall")
	if shortfall != null:
		for key in ["day", "deadline", "reserve"]:
			_int_key(shortfall, key)
		_int_dict_values(shortfall.get("places", {}))
	var morning =morning_accounts.get("latest")
	if morning != null:
		for key in ["day", "openingBalance", "closingBalance", "income", "expenses"]:
			_int_key(morning, key)
		_int_dict_values(morning.get("oreMovement", {}))
		_int_dict_values(morning.get("sales", {}))
		_int_dict_values(morning.get("production", {}).get("ore", {}))
		_int_dict_values(morning.get("production", {}).get("items", {}))
		_int_dict_values(morning.get("losses", {}).get("ore", {}))
		_int_key(morning.get("losses", {}), "veins")
		for exception in morning.get("exceptions", []):
			_int_key(exception, "target")
			_int_key(exception, "actual")
			for key in ["amount", "arrears", "roomsLost", "interestInDays", "downgradeInDays", "due", "reserve", "deadline"]:
				_int_key(exception, key)
			_int_dict_values(exception.get("walked", {}))
	for thread in state.get("messages", {}).values():
		for msg in thread:
			_int_key(msg, "day")
	_int_dict_values(state.get("collective", {}).get("barkCursors", {}))
	_int_key(state.get("collective", {}), "hakimIntelLastDay")
	for intel in state.get("collective", {}).get("networkIntel", {}).values():
		_int_key(intel, "expiresDay")
	var firm_provocation = state.get("collective", {}).get("firmProvocation")
	if firm_provocation != null:
		_int_key(firm_provocation, "expiresDay")
	var business: Dictionary = state.get("business", {})
	for key in ["pot", "float", "nextPaydayId"]:
		_int_key(business, key)
	var week: Dictionary = business.get("week", {})
	_int_key(week, "startDay")
	_int_key(week, "receipts")
	for expense in week.get("expenses", []):
		_int_key(expense, "amount")
	for wage in business.get("wages", {}).values():
		for key in ["weekly", "owed", "hiredDay", "daysWorked"]:
			_int_key(wage, key)
	for record in business.get("ledger", []):
		_restore_payday_int_types(record)
	var business_quest: Dictionary = state.get("businessQuest", {})
	_int_key(business_quest, "starterIndex")
	_int_key(business_quest, "starterReissueDay")
	_int_key(business_quest, "proofLedgerSize")
	var reissue_days: Dictionary = business_quest.get("recurringReissueDay", {})
	for template_id in reissue_days:
		_int_key(reissue_days, template_id)
	for texts in state.get("contactTexts", {}).values():
		_int_key(texts, "nextDay")
		_int_key(texts, "playSeq")
		_int_dict_values(texts.get("played", {}))
	if morning != null and morning.get("payday") != null:
		_restore_payday_int_types(morning["payday"])

	if state.has("meta"):
		_int_key(state["meta"], "saveVersion")

	if state.has("flags"):
		_int_key(state["flags"], "consSoldCount")
		_int_key(state["flags"], "oddities")

	if state.has("player"):
		var player: Dictionary = state["player"]
		for key in ["cash", "hp", "hpMax", "attackMin", "attackMax", "craftingSkill", "craftingXP", "cultivatingSkill", "cultivatingXP", "stealthSkill", "stealthXP", "combatSkill", "combatXP", "shieldPool", "healingSalveDaysLeft", "healingSalveDailyAmount"]:
			_int_key(player, key)
		_int_dict_values(player.get("orichalchum", {}))
		_int_dict_values(player.get("craftedCounts", {}))
		_migrate_inventory(player.get("inventory", {}))
		# player.stash mirrors orichalchum/inventory's own shapes one level
		# down -- same int-restore/tier-migrate calls, scoped to the stash
		# sub-dict backfill_defaults() already guarantees exists by now.
		var stash: Dictionary = player.get("stash", {})
		_int_dict_values(stash.get("orichalchum", {}))
		_migrate_inventory(stash.get("inventory", {}))
		if player.has("bench"):
			var bench: Dictionary = player["bench"]
			_int_dict_values(bench.get("surveyed", {}))
			for cell in bench.get("cells", {}).values():
				_int_key(cell, "misses")
				_int_key(cell, "refine")
			for note_list in bench.get("notes", {}).values():
				for note in note_list:
					_int_key(note, "day")
		for vein in player.get("veins", []):
			for key in ["growth", "rampantDays", "claimedOnDay", "slotIndex", "extraGuards", "level", "developmentStreak"]:
				_int_key(vein, key)
			for buckets in vein.get("guardKit", {}).values():
				_int_dict_values(buckets)
		for device in player.get("devicesCompleted", []):
			for key in ["level", "xp", "chargesPerDay", "chargesUsedToday", "lastResetDay"]:
				_int_key(device, key)
		# devicesInProgress[].progress is a float (10.0, +5.0 on success —
		# see systems/devices.gd) — intentionally not touched here.
		if player.get("dial") != null:
			var dial: Dictionary = player["dial"]
			for key in ["level", "xp", "currentCharge", "maxCharge", "capacityMax"]:
				_int_key(dial, key)
			# rechargeRate is "possibly fractional" per the PRD (Implementation
			# Decisions, "Charge model") — intentionally not touched here, same
			# convention as combat.evadeChance/mapView.zoom above.
			if dial.get("movement") != null:
				_int_key(dial["movement"], "tier")
		# Crafted-but-unseated Movements carry the same tier field.
		for movement in player.get("movementInventory", []):
			_int_key(movement, "tier")

	if state.has("world"):
		var world: Dictionary = state["world"]
		_int_key(world, "day")
		_int_key(world, "timeBlock")
		_int_key(world, "archieChatUnlockDay")
		_int_array_values(world.get("timeBlocksDone", []))
		for site in world.get("sites", []):
			_int_key(site, "discoveredDay")
			_int_key(site, "slotIndex")
			if site.get("factionVein") != null:
				var faction_vein: Dictionary = site["factionVein"]
				for key in ["growth", "rampantDays", "claimedOnDay", "extraGuards", "level", "developmentStreak"]:
					_int_key(faction_vein, key)
				_int_dict_values(faction_vein.get("kit", {}))
		for recent in world.get("recentEvents", []):
			_int_key(recent, "day")
		_int_dict_values(world.get("mapSlotCounters", {}))
		# mapSlotFreePool is Dictionary<district_id, Array[int]>, not a flat
		# Dictionary<String, int> -- _int_dict_values only int-ifies a dict's
		# own values, so each district's freed-slot array needs its own pass.
		for freed in world.get("mapSlotFreePool", {}).values():
			_int_array_values(freed)
		_int_dict_values(world.get("relationAwardedToday", {}))

	if state.has("home"):
		var home: Dictionary = state["home"]
		_int_key(home, "lastRaidDay")
		_int_key(home, "guardCount")
		_int_key(home, "arrears")
		_int_key(home, "arrearsWeeks")
		for buckets in home.get("guardKit", {}).values():
			_int_dict_values(buckets)

	if state.has("mapView"):
		var map_view: Dictionary = state["mapView"]
		_int_key(map_view, "scrollX")
		_int_key(map_view, "scrollY")
		# mapView.zoom is a genuine float (MapZoom.MIN..MAX) -- intentionally
		# left untouched, same as combat.evadeChance/devicesInProgress[].
		# progress above.

	# revealFromIndex is null on a fresh/no-conversation-open state (see
	# GameState.gd's phoneNav default) -- _int_key() is already a no-op on
	# null, only firing when a save was captured mid-conversation.
	if state.has("phoneNav"):
		_int_key(state["phoneNav"], "revealFromIndex")

	if state.has("factions"):
		for faction in state["factions"].values():
			_int_key(faction, "relation")
			_int_key(faction, "resources")
			_int_key(faction, "tradeProgress")
			if faction.get("stockpile") is Dictionary:
				_int_key(faction["stockpile"], "guards")
			for ore_entry in faction.get("oreSold", {}).values():
				_int_key(ore_entry, "units")
				_int_key(ore_entry, "transactions")
			var holdings: Dictionary = faction.get("holdings", {})
			_int_dict_values(holdings.get("ore", {}))
			for buckets in holdings.get("items", {}).values():
				_int_dict_values(buckets)
			_int_dict_values(faction.get("shortfall", {}))
			_int_dict_values(faction.get("consumeAccrued", {}))
			for burn in faction.get("kitBurns", []):
				_int_key(burn, "day")
				_int_dict_values(burn.get("items", {}))
			for entry in faction.get("activityLog", []):
				_int_key(entry, "day")

	if state.has("factionRelations"):
		for row in state["factionRelations"].values():
			_int_dict_values(row)

	for row in state.get("intel", {}).values():
		_int_dict_values(row)
	var intel_timers: Dictionary = state.get("intelTimers", {})
	_int_dict_values(intel_timers.get("privacy", {}))
	_int_dict_values(intel_timers.get("raidWarnings", {}))
	for entry in intel_timers.get("disinformation", []):
		_int_key(entry, "untilDay")
	for entry in state.get("pendingMessages", []):
		if entry.get("kind", "") == Diplomacy.FAVOUR_KIND:
			_int_key(entry.get("payload", {}), "expiresDay")
		elif entry.get("kind", "") == Partners.TROUBLE_KIND:
			for key in ["expiresDay", "qty", "unitPrice", "amount"]:
				_int_key(entry.get("payload", {}), key)
	var favours: Dictionary = state.get("favours", {})
	_int_dict_values(favours.get("lastIssued", {}))
	for entry in favours.get("accepted", []):
		for key in ["acceptedDay", "dueDay"]:
			_int_key(entry, key)
		for key in ["qty", "days"]:
			_int_key(entry.get("params", {}), key)
	var partners: Dictionary = state.get("partners", {})
	for key in ["priceFavours", "lastPriceAsk", "lastTrouble"]:
		_int_dict_values(partners.get(key, {}))
	for row in partners.get("warned", {}).values():
		_int_dict_values(row)
	for entry in state.get("gifts", {}).values():
		for key in ["lastDay", "count"]:
			_int_key(entry, key)

	for group in state.get("factionStances", {}).values():
		for entry in group.values():
			_int_key(entry, "pendingDays")

	for row in state.get("factionEscalation", {}).get("targets", {}).values():
		for entry in row.values():
			_int_key(entry, "lastMoveDay")
	for entry in state.get("factionEscalation", {}).get("withholds", []):
		_int_key(entry, "untilDay")
	_int_key(state.get("factionEscalation", {}), "lastVeinLostDay")
	for row in state.get("factionEscalation", {}).get("shortfallDays", {}).values():
		_int_dict_values(row)
	var war: Dictionary = state.get("factionWar", {})
	for entry in war.get("wars", []):
		_int_key(entry, "startDay")
		_int_key(entry, "lastHostileDay")
	_int_dict_values(war.get("lastHostile", {}))
	_int_key(war, "nagLevel")
	for truce in war.get("truces", []):
		for key in ["startDay", "endDay", "dailyBonus"]:
			_int_key(truce, key)
		for line in truce.get("weekly", []):
			_int_key(line, "amount")
	_int_dict_values(war.get("peaceCooldown", {}))
	_int_dict_values(state.get("factionConclave", {}).get("runs", {}))
	_int_dict_values(state.get("factionConclave", {}).get("stockpile", {}))
	_int_dict_values(state.get("factionConclave", {}).get("squeezed", {}))
	_int_key(state.get("factionConclave", {}), "lastPushDay")
	for position in state.get("factionConclave", {}).get("positions", []):
		for key in ["units", "openedDay", "pushed"]:
			_int_key(position, key)
	var talks: Dictionary = war.get("negotiation", {})
	_int_key(talks, "round")
	for terms_key in ["draft", "counter"]:
		var terms: Dictionary = talks.get(terms_key, {})
		for key in [FactionAI.TERM_TRUCE_DAYS, FactionAI.TERM_CASH_TO_FACTION, FactionAI.TERM_CASH_TO_PLAYER, FactionAI.TERM_WEEKLY_TO_FACTION, FactionAI.TERM_WEEKLY_TO_PLAYER]:
			_int_key(terms, key)
	for offer in state.get("sales", {}).get("pendingOffers", []):
		if offer.has("poach"):
			_int_key(offer["poach"], "payment")

	if state.has("contacts"):
		for contact in state["contacts"].values():
			for key in ["relation", "recruitThreshold", "raidAssistThreshold", "craftingSkill", "craftingXP", "cultivatingSkill", "cultivatingXP", "salesSkill", "salesXP", "stealthSkill", "stealthXP",
					"combatHpMax", "combatHp", "combatAttackMin", "combatAttackMax", "combatStashMax", "combatStash", "combatHealAmount", "combatSpeed", "koCooldownDays", "koCooldownUntilDay",
					"dialCharges", "tradeProgress"]:
				_int_key(contact, key)

	if state.has("barometer"):
		var barometer: Dictionary = state["barometer"]
		for section_progress in barometer.get("progress", {}).values():
			_int_dict_values(section_progress)
		for section_cooldowns in barometer.get("cooldowns", {}).values():
			for entry in section_cooldowns.values():
				_int_key(entry, "push")
				_int_key(entry, "pull")
		for entry in barometer.get("headlines", []):
			_int_key(entry, "day")
		for entry in barometer.get("pushes", []):
			_int_key(entry, "strength")

	if state.has("combat"):
		_restore_combat_int_types(state["combat"])

	if state.has("combatPrototype"):
		_restore_combat_prototype_int_types(state["combatPrototype"])

	# state.objectives[*].progress is a free-form bag (systems/objectives.gd)
	# -- only its known numeric shapes need restoring (activatedDay,
	# traded_with_faction's baseline snapshot, alarm_defend_wins' win
	# counter, items_crafted_set's crafted-count baseline).
	if state.has("objectives"):
		for objective in state["objectives"].values():
			var progress: Dictionary = objective.get("progress", {})
			_int_key(progress, "activatedDay")
			_int_key(progress, "defendWinCount")
			if progress.has("baseline"):
				_int_key(progress["baseline"], "units")
				_int_key(progress["baseline"], "transactions")
			_int_dict_values(progress.get("craftedBaseline", {}))

	if state.get("jamesJob") != null:
		var job: Dictionary = state["jamesJob"]
		for key in ["qty", "payPerItem", "totalPay", "byDay", "pay"]:
			_int_key(job, key)

	# state.event.snapshots holds full-state copies (see systems/events.gd);
	# recurse the same restoration into each one. In practice this is
	# always empty at a real save point (autosave only fires from daily
	# tick / combat exit / event completion / a purchase — never mid-event)
	# but it costs nothing to handle defensively.
	if state.get("event") != null:
		var event: Dictionary = state["event"]
		_int_key(event, "cardIndex")
		for snap in event.get("snapshots", []):
			_restore_int_types(snap)

	if state.get("modal") != null:
		_restore_modal_int_types(state["modal"])


func _restore_combat_int_types(combat: Dictionary) -> void:
	for key in ["frozenTurns", "motionTurns", "motionPower", "evadeTurns"]:
		_int_key(combat, key)
	# evadeChance is a float (0.0–1.0) — intentionally not touched here.
	if combat.has("selection"):
		_int_key(combat["selection"], "index")
	for enemy in combat.get("enemies", []):
		for key in ["hp", "hpMax", "attackMin", "attackMax", "speed"]:
			_int_key(enemy, key)
	# combat.snapshots entries (systems/combat.gd's push_combat_snapshot)
	# are a small hand-picked dict, not a full-state copy — different
	# shape from event snapshots, restored explicitly here.
	for snap in combat.get("snapshots", []):
		for key in ["playerHp", "enemyHp", "enemyIndex", "frozenTurns", "motionTurns", "motionPower", "evadeTurns"]:
			_int_key(snap, key)
		if snap.has("selection"):
			_int_key(snap["selection"], "index")
		if snap.has("turnCursor"):
			_restore_turn_cursor_int_types(snap["turnCursor"])
	# allies[] entries (Contacts.build_combat_ally), speed included.
	for ally in combat.get("allies", []):
		for key in ["hp", "hpMax", "attackMin", "attackMax", "stash", "healAmount", "speed", "dialCharges"]:
			_int_key(ally, key)
	if combat.has("turnCursor"):
		_restore_turn_cursor_int_types(combat["turnCursor"])


# R§3.7a resumable-progression cursor: index/round are ints, and each
# queued entry (systems/combat.gd's build_turn_queue() shape) carries its
# own int speed plus an int index for an ally/enemy entry (absent on a
# player-type entry).
func _restore_turn_cursor_int_types(cursor: Dictionary) -> void:
	for key in ["index", "round"]:
		_int_key(cursor, key)
	for entry in cursor.get("queue", []):
		_int_key(entry, "speed")
		_int_key(entry, "index")


# Same fixed-schema restoration as _restore_combat_int_types() above, over
# the bounded solo combat prototype's own hand-picked snapshot shape
# (systems/combat_prototype.gd's push_prototype_snapshot()). enemy.
# evadeChance is a float (0.0-1.0), same convention as combat.evadeChance
# -- intentionally not touched here.
func _restore_combat_prototype_int_types(cp: Dictionary) -> void:
	for key in ["round", "wave", "totalWaves", "frozenTurns", "motionTurns", "motionPower"]:
		_int_key(cp, key)
	var player: Dictionary = cp.get("player", {})
	for key in ["hp", "hpMax", "shieldPool"]:
		_int_key(player, key)
	if player.has("committedTarget") and typeof(player["committedTarget"]) == TYPE_FLOAT:
		player["committedTarget"] = int(player["committedTarget"])
	for enemy in cp.get("enemies", []):
		for key in ["hp", "hpMax", "attackMin", "attackMax", "speed", "scriptIndex"]:
			_int_key(enemy, key)
	for snap in cp.get("snapshots", []):
		for key in ["round", "wave", "frozenTurns", "motionTurns", "motionPower"]:
			_int_key(snap, key)
		var snap_player: Dictionary = snap.get("player", {})
		for key in ["hp", "shieldPool"]:
			_int_key(snap_player, key)
		if snap_player.has("committedTarget") and typeof(snap_player["committedTarget"]) == TYPE_FLOAT:
			snap_player["committedTarget"] = int(snap_player["committedTarget"])
		for snap_enemy in snap.get("enemies", []):
			_int_key(snap_enemy, "hp")
			_int_key(snap_enemy, "scriptIndex")


# state.modal.data's shape depends on modal.type (systems/crafting.gd,
# economy.gd, jobs.gd) — unlike the fixed-schema fields
# above, it's polymorphic, so it needs its own per-type table rather than
# a flat key list. seed_result and james_job_offer without a job aren't
# listed: they carry no int fields.
func _restore_modal_int_types(modal: Dictionary) -> void:
	var data: Dictionary = modal.get("data", {})
	match modal.get("type"):
		"craft_result":
			_int_key(data, "power")
		"craft_batch_result":
			_int_key(data, "requested")
			_int_key(data, "completed")
			_int_key(data, "successes")
			for attempt in data.get("attempts", []):
				_int_key(attempt, "power")
		"sale_result", "archie_deal_result":
			_int_key(data, "earned")
			_int_key(data, "gross")
		"james_job_complete":
			_int_key(data, "earned")
		"james_job_offer", "james_job_short":
			_int_key(data, "have")
			if data.get("job") != null:
				var job: Dictionary = data["job"]
				for key in ["qty", "payPerItem", "totalPay", "byDay", "pay"]:
					_int_key(job, key)


# A sales offer/contract request (systems/contracts.gd's request_lines()):
# single-type shape has "qty" directly on the request; a mixed one-off
# instead carries a "types" array, one { kind, type, qty } line per
# requested type.
func _restore_request_int_types(request: Dictionary) -> void:
	_int_key(request, "qty")
	for line in request.get("types", []):
		_int_key(line, "qty")


# A sales offer/contract quote (systems/offers.gd's quote_for_request()):
# unitValue/liveValue/payment/salesSkill on the quote itself, plus the same
# unitValue/liveValue pair repeated per quote.lines[] entry (one requested
# type each).
func _restore_quote_int_types(quote: Dictionary) -> void:
	for key in ["unitValue", "liveValue", "payment", "salesSkill"]:
		_int_key(quote, key)
	for line in quote.get("lines", []):
		_int_key(line, "unitValue")
		_int_key(line, "liveValue")


# An active or settled contract (systems/contracts.gd) -- shared by
# sales.activeContracts and each sales.contractHistory entry's own embedded
# "contract" copy.
func _restore_contract_int_types(contract: Dictionary) -> void:
	for key in ["acceptedDay", "dueDay", "weekday", "periodStartDay", "startDay", "termWeeks", "expiryDay"]:
		_int_key(contract, key)
	_restore_request_int_types(contract.get("request", {}))
	_restore_quote_int_types(contract.get("signedQuote", {}))
	_int_dict_values(contract.get("delivered", {}))


# A contract settlement receipt (systems/contracts.gd's settle()) -- shared
# by sales.settlements and each sales.contractHistory entry's own embedded
# "settlement" copy.
func _restore_settlement_int_types(settlement: Dictionary) -> void:
	for key in ["day", "payment"]:
		_int_key(settlement, key)
	_int_dict_values(settlement.get("delivered", {}))


func _restore_payday_int_types(record: Dictionary) -> void:
	_int_key(record, "day")
	_int_key(record, "receipts")
	for expense in record.get("expenses", []):
		_int_key(expense, "amount")
	_int_dict_values(record.get("shares", {}))


func _int_key(dict: Dictionary, key: String) -> void:
	if dict.has(key) and typeof(dict[key]) == TYPE_FLOAT:
		dict[key] = int(dict[key])


# player.inventory[recipeKey] is a tier-bucketed { "<tier>": count } dict.
# A save with a bare-number shape per recipe migrates into the "0"
# (untiered/legacy — quality unknown) bucket instead of being rejected. A
# save already in the bucketed shape just gets its counts int-ified.
func _migrate_inventory(inventory: Dictionary) -> void:
	for recipe_key in inventory.keys():
		var value = inventory[recipe_key]
		if value is Dictionary:
			_int_dict_values(value)
		else:
			inventory[recipe_key] = { "0": int(value) }


func _int_dict_values(dict: Dictionary) -> void:
	for key in dict.keys():
		if typeof(dict[key]) == TYPE_FLOAT:
			dict[key] = int(dict[key])


func _int_array_values(arr: Array) -> void:
	for i in range(arr.size()):
		if typeof(arr[i]) == TYPE_FLOAT:
			arr[i] = int(arr[i])

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
	_migrate_nadia_supply_order(filled)
	_remap_retired_screen_id(filled)
	_remap_retired_messages_list(filled)
	_remap_retired_lab_screen(filled)
	GameState.state = filled
	EventBus.state_changed.emit()
	return { "ok": true }


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
	var delivered := clampi(int(current.get("units", 0)) - int(baseline.get("units", 0)), 0, 30)
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
	for key in defaults.keys():
		if not result.has(key):
			result[key] = defaults[key]
	_backfill_new_contacts(result, defaults)
	_backfill_new_contact_keys(result, defaults)
	_backfill_new_collective_keys(result, defaults)
	_backfill_new_world_keys(result, defaults)
	_backfill_new_player_keys(result, defaults)
	_backfill_new_home_keys(result, defaults)
	_backfill_new_sales_keys(result, defaults)
	return result


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


func _backfill_new_contacts(result: Dictionary, defaults: Dictionary) -> void:
	if not result.has("contacts"):
		return
	var contacts: Dictionary = result["contacts"]
	for contact_id in defaults["contacts"].keys():
		if not contacts.has(contact_id):
			contacts[contact_id] = defaults["contacts"][contact_id]


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
	for notification in state.get("notifications", []):
		_int_key(notification, "day")
	for bank_entry in state.get("bankLog", []):
		_int_key(bank_entry, "amount")
		_int_key(bank_entry, "day")
	var morning_accounts: Dictionary = state.get("morningAccounts", {})
	_int_key(morning_accounts, "autoOpenedDay")
	var morning = morning_accounts.get("latest")
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
	for thread in state.get("messages", {}).values():
		for msg in thread:
			_int_key(msg, "day")
	_int_dict_values(state.get("collective", {}).get("barkCursors", {}))
	_int_key(state.get("collective", {}), "hakimIntelLastDay")
	var payroll_summary = state.get("payroll", {}).get("lastSummary")
	if payroll_summary != null:
		_int_key(payroll_summary, "day")
		for entry in payroll_summary.get("entries", []):
			_int_key(entry, "wage")

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
			for key in ["growth", "rampantDays", "claimedOnDay", "slotIndex", "extraGuards", "level"]:
				_int_key(vein, key)
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
				for key in ["growth", "rampantDays", "claimedOnDay", "extraGuards", "level"]:
					_int_key(faction_vein, key)
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
			for ore_entry in faction.get("oreSold", {}).values():
				_int_key(ore_entry, "units")
				_int_key(ore_entry, "transactions")
			_int_dict_values(faction.get("oreStock", {}))

	if state.has("factionRelations"):
		for row in state["factionRelations"].values():
			_int_dict_values(row)

	if state.has("contacts"):
		for contact in state["contacts"].values():
			for key in ["relation", "recruitThreshold", "raidAssistThreshold", "craftingSkill", "craftingXP", "cultivatingSkill", "cultivatingXP", "salesSkill", "salesXP", "stealthSkill", "stealthXP",
					"combatHpMax", "combatHp", "combatAttackMin", "combatAttackMax", "combatStashMax", "combatStash", "combatHealAmount", "combatSpeed", "koCooldownDays", "koCooldownUntilDay",
					"tradeProgress"]:
				_int_key(contact, key)

	if state.has("barometer"):
		var barometer: Dictionary = state["barometer"]
		for section_progress in barometer.get("progress", {}).values():
			_int_dict_values(section_progress)
		for section_cooldowns in barometer.get("cooldowns", {}).values():
			for entry in section_cooldowns.values():
				_int_key(entry, "push")
				_int_key(entry, "pull")

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
	for key in ["frozenTurns", "motionTurns", "motionPower", "evadeTurns", "focusedEnemyIndex"]:
		_int_key(combat, key)
	# evadeChance is a float (0.0–1.0) — intentionally not touched here.
	for enemy in combat.get("enemies", []):
		for key in ["hp", "hpMax", "attackMin", "attackMax", "speed"]:
			_int_key(enemy, key)
	# combat.snapshots entries (systems/combat.gd's push_combat_snapshot)
	# are a small hand-picked dict, not a full-state copy — different
	# shape from event snapshots, restored explicitly here.
	for snap in combat.get("snapshots", []):
		for key in ["playerHp", "enemyHp", "focusedEnemyIndex", "frozenTurns", "motionTurns", "motionPower", "evadeTurns"]:
			_int_key(snap, key)
		if snap.has("turnCursor"):
			_restore_turn_cursor_int_types(snap["turnCursor"])
	# allies[] entries (Contacts.build_combat_ally), speed included.
	for ally in combat.get("allies", []):
		for key in ["hp", "hpMax", "attackMin", "attackMax", "stash", "healAmount", "speed"]:
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
# cultivating.gd, economy.gd, jobs.gd) — unlike the fixed-schema fields
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
		"cultivate_result":
			_int_key(data, "gain")
			_int_key(data, "newLevel")
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
	for key in ["acceptedDay", "dueDay", "weekday"]:
		_int_key(contract, key)
	_restore_request_int_types(contract.get("request", {}))
	_restore_quote_int_types(contract.get("quote", {}))
	_int_dict_values(contract.get("delivered", {}))


# A contract settlement receipt (systems/contracts.gd's settle()) -- shared
# by sales.settlements and each sales.contractHistory entry's own embedded
# "settlement" copy.
func _restore_settlement_int_types(settlement: Dictionary) -> void:
	for key in ["day", "payment"]:
		_int_key(settlement, key)
	_int_dict_values(settlement.get("delivered", {}))


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

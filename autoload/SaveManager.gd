extends Node

# Save/load/autosave/export-import per R§6. 3 manual slots + 3 rotating
# autosaves. autosave() is called from daily_tick, exit_combat, Events.
# advance (on completion), and every successful cash purchase (home
# upgrade/security/room, barometer manual push/pull) — M0-T14 wiring.

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
	# JSON has no int type, so these come back as float — cast explicitly
	# (see _restore_int_types()'s note below; this path bypasses that
	# helper since it only ever touches these two scalars).
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
	_remap_retired_screen_id(filled)
	GameState.state = filled
	EventBus.state_changed.emit()
	return { "ok": true }


# Ticket 12: home/you/bag/inventory are retired screen ids -- not tied to
# any particular saveVersion (they were only just deleted, so every save
# ever written could carry one), which is why this lives here rather than
# in the version-keyed migrate() table above. An old save with one of these
# in currentScreen must land on the phone app grid on load, not soft-lock.
# Main.gd's resolve_screen_id() fallback covers the same case defensively
# on the render side; this is the persisted-state side, and additionally
# resets phoneNav to its home view (a screen-render function must not
# mutate state, so resolve_screen_id() deliberately leaves phoneNav alone).
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


# vein-growth-state spec §11: save-breaking is accepted for the growth-model
# rewrite — no migrator. A save whose meta.saveVersion doesn't match the
# current SAVE_VERSION is rejected outright with a clear reason, rather than
# half-loading a v1 save's now-meaningless devBar/level/charged vein fields.
# A save with no meta.saveVersion at all is treated as the current version
# (matches new_game_state()'s own default) rather than rejected.
#
# 52-map-vein-line-position-drift bumped v2 -> v3 the same way: every site
# (and a saturated site's extra natural-vein stop) now carries a stamped
# slotIndex MapLayout.assign_positions() depends on -- a v2 save has none,
# and there's no way to reconstruct historical discovery order after the
# fact, so it's rejected rather than half-loaded with sites that fall back
# to whatever slotIndex 0 means.
func _check_save_version(save: Dictionary) -> Dictionary:
	var meta: Dictionary = save.get("meta", {})
	var version: int = meta.get("saveVersion", SAVE_VERSION)
	if version != SAVE_VERSION:
		return { "ok": false, "reason": "This save is from an older version of the game (v%d) and can't be loaded. Start a new game." % version }
	return { "ok": true }


# Fills any missing TOP-LEVEL keys from a fresh new_game_state() (R§6:
# "validates required top-level keys and fills missing keys from
# defaults"). Existing top-level keys are kept as-is, even if something
# nested under them is itself missing — this is intentionally shallow,
# not a deep recursive merge.
func backfill_defaults(save: Dictionary) -> Dictionary:
	var defaults := GameState.new_game_state()
	var result: Dictionary = save.duplicate(true)
	for key in defaults.keys():
		if not result.has(key):
			result[key] = defaults[key]
	return result


# JSON has no int/float distinction, so every number in a just-parsed save
# comes back as a float — Godot's own Dictionary/Array equality treats
# int(1) and float(1.0) as distinct once nested inside a container (this
# is what test_savemanager.gd's exact-round-trip assertions caught), and
# real game code assumes these fields stay ints: maxi()/mini()/clampi()
# calls (barometer.gd, combat.gd) require int arguments, and formatting
# like "£%d" % cash would misbehave. Restore ints in place, per R§2's
# schema, immediately after backfill so every top-level key is guaranteed
# present. The three genuinely-float fields in the whole schema —
# combat.evadeChance, devicesInProgress[].progress, and mapView.zoom —
# are deliberately left untouched.
func _restore_int_types(state: Dictionary) -> void:
	_int_key(state, "pendingSaleCut")
	_int_dict_values(state.get("labThresholds", {}))
	_int_dict_values(state.get("veinStationTargets", {}))
	for notification in state.get("notifications", []):
		_int_key(notification, "day")
	for bank_entry in state.get("bankLog", []):
		_int_key(bank_entry, "amount")
		_int_key(bank_entry, "day")
	# collective1-03
	for thread in state.get("messages", {}).values():
		for msg in thread:
			_int_key(msg, "day")

	if state.has("meta"):
		_int_key(state["meta"], "saveVersion")

	if state.has("flags"):
		_int_key(state["flags"], "consSoldCount")
		_int_key(state["flags"], "oddities")

	if state.has("player"):
		var player: Dictionary = state["player"]
		for key in ["cash", "hp", "hpMax", "attackMin", "attackMax", "craftingSkill", "craftingXP", "cultivatingSkill", "cultivatingXP", "stealthSkill", "stealthXP", "shieldPool", "healingSalveDaysLeft", "healingSalveDailyAmount"]:
			_int_key(player, key)
		_int_dict_values(player.get("orichalchum", {}))
		_migrate_inventory(player.get("inventory", {}))
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
			for key in ["growth", "rampantDays", "claimedOnDay", "slotIndex"]:
				_int_key(vein, key)
		for device in player.get("devicesCompleted", []):
			for key in ["level", "xp", "chargesPerDay", "chargesUsedToday", "lastResetDay"]:
				_int_key(device, key)
		# devicesInProgress[].progress is a float (10.0, +5.0 on success —
		# see systems/devices.gd) — intentionally not touched here.

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
				for key in ["growth", "rampantDays", "claimedOnDay"]:
					_int_key(faction_vein, key)
		for recent in world.get("recentEvents", []):
			_int_key(recent, "day")
		_int_dict_values(world.get("mapSlotCounters", {}))

	if state.has("home"):
		var home: Dictionary = state["home"]
		_int_key(home, "lastRaidDay")

	if state.has("mapView"):
		var map_view: Dictionary = state["mapView"]
		_int_key(map_view, "scrollX")
		_int_key(map_view, "scrollY")
		# mapView.zoom is a genuine float (MapZoom.MIN..MAX) -- intentionally
		# left untouched, same as combat.evadeChance/devicesInProgress[].
		# progress above.

	if state.has("factions"):
		for faction in state["factions"].values():
			_int_key(faction, "relation")
			_int_key(faction, "resources")
			# collective1-02
			for ore_entry in faction.get("oreSold", {}).values():
				_int_key(ore_entry, "units")
				_int_key(ore_entry, "transactions")

	if state.has("factionRelations"):
		for row in state["factionRelations"].values():
			_int_dict_values(row)

	if state.has("contacts"):
		for contact in state["contacts"].values():
			for key in ["relation", "recruitThreshold", "raidAssistThreshold", "craftingSkill", "craftingXP", "cultivatingSkill", "cultivatingXP", "stealthSkill", "stealthXP",
					"combatHpMax", "combatHp", "combatAttackMin", "combatAttackMax", "combatStashMax", "combatStash", "combatHealAmount", "koCooldownDays", "koCooldownUntilDay"]:
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

	# collective1-02: state.objectives[*].progress is a free-form bag
	# (systems/objectives.gd) -- only its two known numeric shapes need
	# restoring (activatedDay, and traded_with_faction's baseline snapshot).
	if state.has("objectives"):
		for objective in state["objectives"].values():
			var progress: Dictionary = objective.get("progress", {})
			_int_key(progress, "activatedDay")
			if progress.has("baseline"):
				_int_key(progress["baseline"], "units")
				_int_key(progress["baseline"], "transactions")

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
	if combat.get("enemy") != null:
		var enemy: Dictionary = combat["enemy"]
		for key in ["hp", "hpMax", "attackMin", "attackMax"]:
			_int_key(enemy, key)
	# combat.snapshots entries (systems/combat.gd's push_combat_snapshot)
	# are a small hand-picked dict, not a full-state copy — different
	# shape from event snapshots, restored explicitly here.
	for snap in combat.get("snapshots", []):
		for key in ["playerHp", "enemyHp", "frozenTurns", "motionTurns", "motionPower", "evadeTurns"]:
			_int_key(snap, key)
	# 44-archie-combat-ally: allies[] entries (Contacts.build_combat_ally)
	for ally in combat.get("allies", []):
		for key in ["hp", "hpMax", "attackMin", "attackMax", "stash", "healAmount"]:
			_int_key(ally, key)


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
		"sale_result":
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


func _int_key(dict: Dictionary, key: String) -> void:
	if dict.has(key) and typeof(dict[key]) == TYPE_FLOAT:
		dict[key] = int(dict[key])


# ticket 64: player.inventory[recipeKey] moved from a flat count to a
# tier-bucketed { "<tier>": count } dict. A save from before this ticket
# has the old bare-number shape per recipe -- migrate each into the "0"
# (untiered/legacy — quality unknown) bucket rather than rejecting the
# save or crashing on it. A save already in the new shape just gets its
# bucket counts int-ified, same as every other numeric field here.
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

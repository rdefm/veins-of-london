extends Node

# Save/load/autosave/export-import per R§6. 3 manual slots + 3 rotating
# autosaves. autosave() is called from daily_tick, exit_combat, Events.
# advance (on completion), and every successful cash purchase (home
# upgrade/security/room, barometer manual push/pull) — M0-T14 wiring.

const SAVE_VERSION := 1
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
	var migrated := migrate(raw)
	var filled := backfill_defaults(migrated)
	_restore_int_types(filled)
	GameState.state = filled
	EventBus.state_changed.emit()
	return { "ok": true }


# Version-keyed migration function table. Currently identity for v1 —
# this project starts on the new ore roster, so there is no migration #1
# (R§6). Dispatches on meta.saveVersion, defaulting to the current
# version if absent.
func migrate(save: Dictionary) -> Dictionary:
	var meta: Dictionary = save.get("meta", {})
	var version: int = meta.get("saveVersion", SAVE_VERSION)
	var migrators := {
		1: func(s: Dictionary) -> Dictionary: return s,
	}
	if not migrators.has(version):
		return save
	var migrator: Callable = migrators[version]
	return migrator.call(save)


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
# present. The two genuinely-float fields in the whole schema —
# combat.evadeChance and devicesInProgress[].progress — are deliberately
# left untouched.
func _restore_int_types(state: Dictionary) -> void:
	_int_key(state, "pendingSaleCut")
	_int_dict_values(state.get("labThresholds", {}))

	if state.has("meta"):
		_int_key(state["meta"], "saveVersion")

	if state.has("flags"):
		_int_key(state["flags"], "consSoldCount")

	if state.has("player"):
		var player: Dictionary = state["player"]
		for key in ["cash", "hp", "hpMax", "attackMin", "attackMax", "craftingSkill", "craftingXP", "cultivatingSkill", "cultivatingXP"]:
			_int_key(player, key)
		_int_dict_values(player.get("orichalchum", {}))
		_int_dict_values(player.get("inventory", {}))
		for vein in player.get("veins", []):
			for key in ["level", "devBar", "chargeBlocks", "claimedOnDay"]:
				_int_key(vein, key)
		for device in player.get("devicesCompleted", []):
			for key in ["level", "xp", "chargesPerDay", "chargesUsedToday", "lastResetDay"]:
				_int_key(device, key)
		# devicesInProgress[].progress is a float (10.0, ±5.0/±2.5 deltas —
		# see systems/devices.gd) — intentionally not touched here.

	if state.has("world"):
		var world: Dictionary = state["world"]
		_int_key(world, "day")
		_int_key(world, "timeBlock")
		_int_key(world, "archieChatUnlockDay")
		for site in world.get("sites", []):
			_int_key(site, "discoveredDay")
			_int_key(site, "npcClaimedDay")

	if state.has("home"):
		var home: Dictionary = state["home"]
		_int_key(home, "lastRaidDay")
		_int_dict_values(home.get("storedOre", {}))

	if state.has("factions"):
		for faction in state["factions"].values():
			_int_key(faction, "relation")

	if state.has("contacts"):
		for contact in state["contacts"].values():
			for key in ["relation", "recruitThreshold", "craftingSkill", "craftingXP", "cultivatingSkill", "cultivatingXP"]:
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

	if state.get("jamesJob") != null:
		var job: Dictionary = state["jamesJob"]
		for key in ["qty", "payPerItem", "totalPay"]:
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
				for key in ["qty", "payPerItem", "totalPay"]:
					_int_key(job, key)


func _int_key(dict: Dictionary, key: String) -> void:
	if dict.has(key) and typeof(dict[key]) == TYPE_FLOAT:
		dict[key] = int(dict[key])


func _int_dict_values(dict: Dictionary) -> void:
	for key in dict.keys():
		if typeof(dict[key]) == TYPE_FLOAT:
			dict[key] = int(dict[key])

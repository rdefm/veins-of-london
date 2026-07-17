extends Node

# Save/load/autosave/export-import per R§6. 3 manual slots + 3 rotating
# autosaves. Actual autosave *trigger wiring* (daily tick, combat exit,
# event completion, purchases) is M0-T14's job — this just builds the
# machinery those calls will use.

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

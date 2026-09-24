extends "res://tests/test_base.gd"

# collective-act2 12, spec.md §8/§9: Act 2 data validity -- every new event
# JSON loads, every effect op its events use is a known op, every objective
# id Act 2 references exists, and every colA2* flag (plus spec §8.3's
# networkHandlerUnlocked) referenced anywhere has at least one setter.

const SOURCE_DIRS: Array[String] = ["res://systems", "res://scenes", "res://autoload", "res://data"]

const A2_EVENT_IDS: Array[String] = [
	"col_a2_intro", "col_a2_shop", "col_a2_pattern", "col_a2_handler_deferred",
	"col_a2_contested_vein", "col_a2_vulnerable_site", "col_a2_hostile_member",
	"col_a2_nadia_ledger", "col_a2_nadia_defend_brief", "col_a2_checkpoint",
	"col_a2_hakim_vein_lost", "col_a2_second_loss", "col_a2_handler_meet",
	"col_a2_hakim_retake", "col_a2_closer",
]

const A2_OBJECTIVE_IDS: Array[String] = ["col_a2_nadia_defend", "col_a2_nadia_reseed", "col_a2_nadia_supplies"]


func _collect_files(dir_path: String, out: Array[String]) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	for sub in dir.get_directories():
		_collect_files("%s/%s" % [dir_path, sub], out)
	for file in dir.get_files():
		if file.ends_with(".gd") or file.ends_with(".json"):
			out.append("%s/%s" % [dir_path, file])


func _source_text() -> String:
	var files: Array[String] = []
	for dir_path in SOURCE_DIRS:
		_collect_files(dir_path, files)
	var text := ""
	for path in files:
		text += FileAccess.get_file_as_string(path) + "\n"
	return text


func _has_setter(flag: String, text: String) -> bool:
	if text.contains("\"flag\": \"%s\"" % flag):
		return true
	if text.contains("[\"%s\"] = " % flag):
		return true
	for id in GameData.OBJECTIVES.keys():
		if GameData.OBJECTIVES[id]["completeFlag"] == flag:
			return true
	return false


func run() -> void:
	run_case("every_act2_event_json_loads", func():
		for event_id in A2_EVENT_IDS:
			assert_true(GameData.EVENTS.has(event_id), "%s should load" % event_id)
			var path := "res://data/events/%s.json" % event_id
			assert_true(JSON.parse_string(FileAccess.get_file_as_string(path)) != null, "%s should parse" % path)
	)

	run_case("every_op_in_act2_events_is_a_known_op", func():
		var op_pattern := RegEx.create_from_string("\"op\":\\s*\"([a-z_0-9]+)\"")
		for event_id in A2_EVENT_IDS:
			var text := FileAccess.get_file_as_string("res://data/events/%s.json" % event_id)
			for m in op_pattern.search_all(text):
				assert_true(GameData.VALID_EFFECT_OPS.has(m.get_string(1)), "%s uses unknown op %s" % [event_id, m.get_string(1)])
	)

	run_case("every_act2_objective_id_exists_and_its_activate_flag_has_a_setter", func():
		var text := _source_text()
		for id in A2_OBJECTIVE_IDS:
			assert_true(GameData.OBJECTIVES.has(id), "objective %s should exist" % id)
			assert_true(_has_setter(GameData.OBJECTIVES[id]["activateFlag"], text), "%s's activateFlag needs a setter" % id)
		for id in Collective.CHECKPOINT_MISSIONS:
			assert_true(GameData.OBJECTIVES.has(id), "CHECKPOINT_MISSIONS names unknown objective %s" % id)
	)

	run_case("every_referenced_act2_flag_has_a_setter", func():
		var text := _source_text()
		var flag_pattern := RegEx.create_from_string("colA2[A-Za-z]+")
		var flags := { "networkHandlerUnlocked": true }
		for m in flag_pattern.search_all(text):
			flags[m.get_string()] = true
		assert_true(flags.size() > 10, "sanity: the scan should find Act 2's flags")
		for flag in flags.keys():
			assert_true(_has_setter(flag, text), "flag %s is referenced but never set" % flag)
	)

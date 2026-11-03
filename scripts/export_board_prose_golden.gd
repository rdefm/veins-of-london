extends SceneTree

# Writes tests/fixtures/board_prose_golden.json: for each fact set in
# tests/fixtures/board_prose_parity_input.json, the prose card ids of every
# pack slot whose `when` holds (BoardMeetings._qualifying). tools/test_storyboard.js
# holds the storyboard's JS eligibility to this file. Regenerate:
#   godot --headless -s scripts/export_board_prose_golden.gd

const INPUT := "res://tests/fixtures/board_prose_parity_input.json"
const OUTPUT := "res://tests/fixtures/board_prose_golden.json"


func _initialize() -> void:
	var version := Engine.get_version_info()
	if int(version.major) != 4 or int(version.minor) != 7:
		print("export_board_prose_golden: needs Godot 4.7 (running %s)" % version.string)
		quit(1)
		return
	await process_frame
	var board: GDScript = load("res://systems/board_meetings.gd")
	var input: Variant = JSON.parse_string(FileAccess.get_file_as_string(INPUT))
	if typeof(input) != TYPE_DICTIONARY:
		print("export_board_prose_golden: can't read %s" % INPUT)
		quit(1)
		return
	var out := {}
	for set_id in input["factSets"]:
		var facts: Dictionary = input["factSets"][set_id]
		var per_pack := {}
		for pack_id in input["packs"]:
			var by_slot := {}
			var slots: Array = []
			for prose in input["packs"][pack_id]["cards"]:
				if not slots.has(prose["slot"]):
					slots.append(prose["slot"])
			for slot in slots:
				var pool: Array = input["packs"][pack_id]["cards"].filter(func(p: Dictionary) -> bool: return p["slot"] == slot)
				var ids: Array = []
				for prose in board.call("_qualifying", pool, facts):
					ids.append(prose["id"])
				by_slot[slot] = ids
			per_pack[pack_id] = by_slot
		out[set_id] = per_pack
	var file := FileAccess.open(OUTPUT, FileAccess.WRITE)
	if file == null:
		print("export_board_prose_golden: can't write %s" % OUTPUT)
		quit(1)
		return
	file.store_string(JSON.stringify(out, "  ", true) + "\n")
	file.close()
	print("export_board_prose_golden: wrote %s" % OUTPUT)
	quit(0)

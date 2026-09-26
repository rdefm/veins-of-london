extends "res://tests/test_base.gd"

# calc-discovery ticket 07: Approaches.source_text() is the pairing panel's
# "where to get this" line for an unlearned approach (M3 §8.3) -- plain
# words instead of a lock icon.


func run() -> void:
	run_case("source_text_for_a_room_sourced_approach_names_the_room", func():
		GameData.APPROACHES["_testGated"] = { "name": "Gated", "symbol": "?", "source": { "type": "room", "id": "lab" } }
		assert_eq(Approaches.source_text("_testGated"), "Needs the Improved Lab.", "a lab-sourced approach names the room")
		GameData.APPROACHES.erase("_testGated")
	)

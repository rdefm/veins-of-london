extends "res://tests/test_base.gd"

# calc-discovery ticket 07: Approaches.source_text() is the pairing panel's
# "where to get this" line for an unlearned approach (M3 §8.3) -- plain
# words instead of a lock icon.


func run() -> void:
	run_case("source_text_for_a_room_sourced_approach_names_the_room", func():
		assert_eq(Approaches.source_text("compression"), "Needs the Workshop.", "compression is sourced from the workshop room")
		assert_eq(Approaches.source_text("distilling"), "Needs the Improved Lab.", "distilling is sourced from the (renamed) lab room")
	)

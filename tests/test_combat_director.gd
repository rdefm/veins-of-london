extends "res://tests/test_base.gd"

# combat-presentation ticket 05, docs/combat-animation-vision.md §4.1: the
# director's own hit-stop wiring (a beat carrying a positive `dmg` gets an
# extra HIT_STOP_DURATION pause added to its timeline) plus the shared
# beat_is_damaging() test the screen's own juice layer (scenes/screens/
# combat.gd's _on_beat_played()/_play_juice()) keys off. Full playback
# pacing/skip/fast-forward behaviour is ticket 04's own territory and stays
# untested at the unit level here (no dedicated test file existed for it
# before this ticket either) -- this file covers only what ticket 05 adds.


func _dmg_beat(dmg: int) -> Dictionary:
	return { "kind": "player_attack", "logLine": "x", "targetType": "enemy", "targetIndex": 0, "dmg": dmg }


func _non_dmg_beat() -> Dictionary:
	return { "kind": "motion_announce", "logLine": "x" }


func run() -> void:
	run_case("beat_is_damaging_is_true_for_a_beat_with_a_positive_dmg_field", func():
		assert_true(CombatDirector.beat_is_damaging(_dmg_beat(7)))
	)

	run_case("beat_is_damaging_is_false_for_a_beat_with_no_dmg_field_at_all", func():
		assert_true(not CombatDirector.beat_is_damaging(_non_dmg_beat()))
	)

	run_case("beat_is_damaging_is_false_for_a_beat_with_dmg_zero", func():
		assert_true(not CombatDirector.beat_is_damaging(_dmg_beat(0)))
	)

	run_case("hit_stop_duration_is_within_the_60_to_90ms_range_the_vision_doc_specifies", func():
		assert_true(CombatDirector.HIT_STOP_DURATION >= 0.06 and CombatDirector.HIT_STOP_DURATION <= 0.09)
	)

	run_case("play_creates_a_tween_for_the_first_beat_and_calls_its_on_beat_synchronously_first", func():
		var director := CombatDirector.new()
		var received: Array = []
		director.play([_dmg_beat(5)], func(b): received.append(b))

		assert_eq(received.size(), 1, "on_beat must fire before the beat's own pause, not after")
		assert_true(director._active_tween != null, "a tween should be kicked off for the beat's paced pause")
		assert_true(director.is_playing())
	)

	run_case("turn_pause_is_data_driven_and_shorter_on_quick_pacing", func():
		var pauses: Dictionary = GameData.COMBAT_VISUALS["pacing"]["turnPause"]
		assert_eq(CombatDirector.turn_pause_for("normal"), float(pauses["normal"]))
		assert_eq(CombatDirector.turn_pause_for("quick"), float(pauses["quick"]))
		assert_true(CombatDirector.turn_pause_for("quick") < CombatDirector.turn_pause_for("normal"))
		assert_true(CombatDirector.turn_pause_for("normal") > 0.0)
	)

	run_case("is_turn_boundary_only_between_beats_of_different_occurrences", func():
		var beats: Array = [_turn_beat("0:0"), _turn_beat("0:0"), _turn_beat("0:1"), _turn_beat(""), _turn_beat("1:0")]
		assert_true(not CombatDirector.is_turn_boundary(beats, 0), "two beats of one turn (e.g. a Motion double attack) play back to back")
		assert_true(CombatDirector.is_turn_boundary(beats, 1))
		assert_true(CombatDirector.is_turn_boundary(beats, 2), "a round-boundary beat reads as its own turn")
		assert_true(CombatDirector.is_turn_boundary(beats, 3))
		assert_true(not CombatDirector.is_turn_boundary(beats, 4), "no pause after the last beat")
	)

	run_case("is_turn_boundary_holds_for_reversed_rewind_playback", func():
		var beats: Array = [_turn_beat("0:1"), _turn_beat("0:0"), _turn_beat("0:0")]
		beats.reverse()
		assert_true(not CombatDirector.is_turn_boundary(beats, 0))
		assert_true(CombatDirector.is_turn_boundary(beats, 1))
	)


func _turn_beat(occurrence_id: String) -> Dictionary:
	var occurrence: Variant = null if occurrence_id.is_empty() else { "occurrenceId": occurrence_id }
	return { "kind": "player_attack", "logLine": "x", "occurrence": occurrence }

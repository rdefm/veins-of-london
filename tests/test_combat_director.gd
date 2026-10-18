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

	run_case("is_turn_boundary_only_between_beats_of_different_turns", func():
		var beats: Array = [
			_turn_beat(1, 0, 0), _turn_beat(1, 0, 0), _turn_beat(1, 1, 0), _turn_beat(1, 1, 1),
			_turn_beat(2, -1, -1), _turn_beat(2, -1, -1), _turn_beat(2, 1, 0),
		]
		assert_true(not CombatDirector.is_turn_boundary(beats, 0), "two beats of one action (e.g. an attack and its KO) play back to back")
		assert_true(CombatDirector.is_turn_boundary(beats, 1), "a different actor's turn")
		assert_true(CombatDirector.is_turn_boundary(beats, 2), "the same actor's next timeline entry")
		assert_true(CombatDirector.is_turn_boundary(beats, 3), "a round-boundary beat reads as its own turn")
		assert_true(not CombatDirector.is_turn_boundary(beats, 4), "a round's entry beats share one turn")
		assert_true(CombatDirector.is_turn_boundary(beats, 5))
		assert_true(not CombatDirector.is_turn_boundary(beats, 6), "no pause after the last beat")
	)

	run_case("is_turn_boundary_never_pauses_into_a_turnless_settle_beat", func():
		var beats: Array = [_turn_beat(1, 0, 0), { "kind": "settle" }]
		assert_true(not CombatDirector.is_turn_boundary(beats, 0))
	)

	run_case("is_turn_boundary_holds_for_reversed_rewind_playback", func():
		var beats: Array = [_turn_beat(1, 1, 0), _turn_beat(1, 0, 0), _turn_beat(1, 0, 0)]
		beats.reverse()
		assert_true(not CombatDirector.is_turn_boundary(beats, 0))
		assert_true(CombatDirector.is_turn_boundary(beats, 1))
	)

	run_case("a_round_fights_real_beats_pause_only_between_actions", func():
		var beats: Array = _round_beats()
		assert_true(beats.size() >= 2, "the fixture round should produce several beats")
		for i in range(beats.size() - 1):
			var same_turn: bool = beats[i]["round"] == beats[i + 1]["round"] \
				and beats[i]["turnActor"] == beats[i + 1]["turnActor"] and beats[i]["turnIndex"] == beats[i + 1]["turnIndex"]
			assert_eq(CombatDirector.is_turn_boundary(beats, i), not same_turn)
	)


# A seeded street mugging's first pick: the player strikes between the
# mugger's two strikes, so its beats span several actions.
func _round_beats() -> Array:
	GameState.reset()
	var mugger := {
		"name": "A mugger", "hp": 28, "hpMax": 28, "attackMin": 4, "attackMax": 10,
		"isMugging": true, "weapon": null, "ability": null, "evadeChance": 0.0,
		"speed": Combat.MUGGER_SPEED, "archetype": Combat.MUGGER_ARCHETYPE, "level": 1,
	}
	Combat._start_round_combat(Combat.CONTEXT_EVENT_MUGGING, null, [mugger], [], "", [], null,
		{ "seed": 1, "fog": false, "enemyPlans": [[["strike", "strike"]]] })
	return Combat.choose_move("strike", 1)["beats"]


func _turn_beat(round_no: int, turn_actor: int, turn_index: int) -> Dictionary:
	return { "kind": "player_attack", "text": "x", "round": round_no, "turnActor": turn_actor, "turnIndex": turn_index }

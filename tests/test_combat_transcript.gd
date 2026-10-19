extends "res://tests/test_base.gd"

# CombatTranscript (the play-by-play under the combat stage) and its feed
# from state.combat.transcript through CombatRoundsScreen's beat playback.


func _slow_mugger(hp: int) -> Dictionary:
	return {
		"name": "A mugger", "hp": hp, "hpMax": hp, "attackMin": 4, "attackMax": 10,
		"isMugging": true, "weapon": null, "ability": null, "evadeChance": 0.0,
		"speed": 1, "archetype": Combat.MUGGER_ARCHETYPE, "level": 1,
	}


# A seeded mugging holding a rewind unit, the mugger guarding all round.
func _start_fight() -> void:
	GameState.state["player"]["loadout"]["slots"][0] = { "recipe": "rewind", "tier": 1 }
	GameState.state["player"]["loadout"]["lastRecipe"][0] = "rewind"
	Combat._start_round_combat(Combat.CONTEXT_EVENT_MUGGING, null, [_slow_mugger(200)], ["They step out."], "", [], null,
		{ "seed": 1, "fog": false, "enemyPlans": [[["guard", "guard"]]] })


func _screen() -> Array:
	var host := CombatScreen.new()
	host._ready()
	var screen: CombatRoundsScreen = host._round_screen
	screen._ready()
	return [host, screen]


func run() -> void:
	run_case("lines_append_newest_last_and_remove_by_text_from_the_end", func():
		var transcript := CombatTranscript.new()
		transcript.set_lines(["A.", "B.", "A."])
		transcript.append_line("C.")
		assert_eq(transcript.lines(), ["A.", "B.", "A.", "C."])
		transcript.remove_last("A.")
		assert_eq(transcript.lines(), ["A.", "B.", "C."], "the newest match goes")
		transcript.remove_last("Z.")
		assert_eq(transcript._lines.get_child_count(), 3, "no match removes nothing")
		transcript.free()
	)

	run_case("set_lines_keeps_the_shown_lines_when_unchanged", func():
		var transcript := CombatTranscript.new()
		transcript.set_lines(["A.", "B."])
		var first := transcript._lines.get_child(0)
		transcript.set_lines(["A.", "B."])
		assert_true(transcript._lines.get_child(0) == first, "no rebuild, so the scroll holds")
		transcript.free()
	)

	run_case("a_fight_opens_with_its_intro_lines_and_no_notifications", func():
		GameState.reset()
		var before: int = GameState.state["notifications"].size()
		_start_fight()
		var pair := _screen()
		var screen: CombatRoundsScreen = pair[1]
		assert_eq(screen._transcript.lines()[0], "They step out.")
		assert_eq(screen._transcript.lines(), GameState.state["combat"]["transcript"])
		assert_eq(GameState.state["notifications"].size(), before)
		pair[0].free()
	)

	run_case("a_picks_lines_land_one_per_beat_as_it_plays", func():
		GameState.reset()
		_start_fight()
		var pair := _screen()
		var screen: CombatRoundsScreen = pair[1]
		var before: Array = screen._transcript.lines()
		screen._transcript_held = true
		var beats: Array = Combat.choose_move("guard")["beats"]
		assert_true(beats.size() > 1)
		assert_eq(screen._transcript.lines(), before, "nothing ahead of playback")
		screen._on_beat_played(beats[0])
		var expected: Array = before.duplicate()
		expected.append(beats[0]["text"])
		assert_eq(screen._transcript.lines(), expected, "the played beat's line only")
		screen._end_playback()
		assert_eq(screen._transcript.lines(), GameState.state["combat"]["transcript"], "every line once playback ends")
		pair[0].free()
	)

	run_case("rewind_takes_the_undone_lines_off_as_their_beats_rewind", func():
		GameState.reset()
		_start_fight()
		var pair := _screen()
		var screen: CombatRoundsScreen = pair[1]
		var before_pick: Array = GameState.state["combat"]["transcript"].duplicate()
		Combat.choose_move("guard")
		screen._refresh()
		var shown: Array = screen._transcript.lines()
		var undone := screen.begin_rewind_playback()
		assert_eq(screen._transcript.lines(), shown, "held until the rewind plays")
		screen._on_rewind_beat_played(undone[0])
		assert_eq(screen._transcript.lines(), shown.slice(0, shown.size() - 1), "the newest beat's line goes first")
		screen._end_playback()
		var expected: Array = before_pick.duplicate()
		expected.append(Combat.LINE_REWIND)
		assert_eq(GameState.state["combat"]["transcript"], expected, "the undone lines are gone from state")
		assert_eq(screen._transcript.lines(), GameState.state["combat"]["transcript"])
		pair[0].free()
	)

	run_case("a_mid_fight_save_without_a_transcript_loads_with_one_from_its_log", func():
		GameState.reset()
		_start_fight()
		Combat.choose_move("guard")
		var save: Dictionary = GameState.deep_copy(GameState.state)
		save["combat"].erase("transcript")
		var filled := SaveManager.backfill_defaults(save)
		assert_eq(filled["combat"]["transcript"], save["combat"]["log"].map(func(b): return b["text"]))
	)

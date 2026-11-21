extends "res://tests/test_base.gd"

const Fixtures := preload("res://tests/support/fixtures.gd")
const RaidingTests := preload("res://tests/test_raiding.gd")

# Convention event art (ADR 0005): ore-suffixed raid card art. The asset
# probe is swapped for a fake file set so no fixture images ship.

const STEM := "res://assets/events/test_art_event/test_art_event_card"


func _install_art_event(image_card: Variant = "absent") -> Dictionary:
	var original_events: Dictionary = GameData.EVENTS
	GameData.EVENTS = GameData.EVENTS.duplicate()
	var first := { "type": "narration", "key": "first", "label": null, "speaker": null, "text": "First" }
	if not (image_card is String and image_card == "absent"):
		first["image"] = image_card
	GameData.EVENTS["test_art_event"] = {
		"id": "test_art_event",
		"cards": [
			first,
			{
				"type": "choice", "key": "pick", "label": null, "speaker": null, "text": "Pick",
				"choices": [{ "label": "Go", "effects": [], "result_text": "Gone." }],
			},
			{ "type": "narration", "key": "after", "label": null, "speaker": null, "text": "After" },
		],
	}
	return original_events


func _fake_files(paths: Array) -> Callable:
	var original: Callable = Events.convention_asset_exists
	Events.convention_asset_exists = func(path: String) -> bool: return paths.has(path)
	return original


func run() -> void:
	run_case("begin_raid_records_the_raided_veins_ore_as_plain_context_data", func():
		GameState.reset()
		var vein := RaidingTests._faction_vein_of_growth(30, "fate", "none", "firm")
		GameState.state["world"]["sites"] = [Fixtures.site_with_vein(vein["siteId"], vein)]
		assert_true(Raiding.begin_raid(vein)["ok"], "raid starts")
		var ore: Variant = GameState.state["event"]["context"].get("raidOre")
		assert_eq(ore, "fate", "the raided vein's ore is in the event context")
		assert_true(ore is String, "pure data")
	)

	run_case("a_raid_shows_the_ore_suffixed_file_and_rewind_keeps_it", func():
		GameState.reset()
		var original_events := _install_art_event()
		var original_probe := _fake_files(["%s1.png" % STEM, "%s1_life.png" % STEM])
		GameState.state["player"]["inventory"]["rewind"] = { "1": 1 }
		Events.start_event("test_art_event", { "raidOre": "life" })
		assert_eq(Events.current_image_path(), "%s1_life.png" % STEM, "ore-suffixed file wins during a raid")
		Events.advance()
		Events.choose(0)
		assert_true(Events.rewind()["ok"], "rewind works")
		assert_eq(GameState.state["event"]["context"].get("raidOre"), "life", "rewind keeps the raid's ore")
		assert_eq(Events.current_image_path(), "%s1_life.png" % STEM, "still the ore art after rewind")
		Events.convention_asset_exists = original_probe
		GameData.EVENTS = original_events
	)

	run_case("a_raid_with_no_ore_file_falls_back_to_the_plain_file", func():
		GameState.reset()
		var original_events := _install_art_event()
		var original_probe := _fake_files(["%s1.png" % STEM, "%s1_life.png" % STEM])
		Events.start_event("test_art_event", { "raidOre": "time" })
		assert_eq(Events.current_image_path(), "%s1.png" % STEM, "plain file when no time variant exists")
		Events.convention_asset_exists = original_probe
		GameData.EVENTS = original_events
	)

	run_case("an_explicit_image_key_beats_both_convention_files", func():
		for explicit in ["res://explicit.png", null]:
			GameState.reset()
			var original_events := _install_art_event(explicit)
			var original_probe := _fake_files(["%s1.png" % STEM, "%s1_time.png" % STEM])
			Events.start_event("test_art_event", { "raidOre": "time" })
			assert_eq(Events.current_image_path(), explicit, "explicit image %s wins" % str(explicit))
			Events.convention_asset_exists = original_probe
			GameData.EVENTS = original_events
	)

	run_case("a_non_raid_event_never_picks_an_ore_suffixed_file", func():
		GameState.reset()
		var original_events := _install_art_event()
		var original_probe := _fake_files(["%s1_time.png" % STEM])
		Events.start_event("test_art_event")
		assert_eq(Events.current_image_path(), null, "no raidOre, no suffixed lookup")
		Events.convention_asset_exists = original_probe
		GameData.EVENTS = original_events
	)

	run_case("next_image_paths_names_the_next_cards_still_without_touching_state", func():
		GameState.reset()
		assert_eq(Events.next_image_paths(), [], "no live event, nothing to prefetch")
		var original_events := _install_art_event()
		var original_probe := _fake_files(["%s1.png" % STEM, "%s2.png" % STEM, "%s3.png" % STEM])
		Events.start_event("test_art_event")
		var before: Dictionary = GameState.state["event"].duplicate(true)
		assert_eq(Events.next_image_paths(), ["%s2.png" % STEM], "card 1 reaches only card 2")
		assert_eq(GameState.state["event"], before, "a pure read")
		Events.convention_asset_exists = original_probe
		GameData.EVENTS = original_events
	)

	run_case("next_image_paths_covers_option_and_outcome_gotos_and_images", func():
		GameState.reset()
		var original_events: Dictionary = GameData.EVENTS
		GameData.EVENTS = GameData.EVENTS.duplicate()
		var choice_card := {
			"type": "choice", "key": "pick", "label": null, "speaker": null, "text": "Pick",
			"choices": [
				{ "label": "Look", "effects": [], "result_text": "Seen.", "image": "res://look.png" },
				{ "label": "Run", "effects": [], "result_text": "Gone.", "goto": "far" },
				{ "label": "Try", "effects": [], "check": { "ore": "fate", "dc": 1 },
					"success": { "result_text": "Yes.", "goto": 3, "image": "res://win.png" },
					"fail": { "result_text": "No.", "image": "res://look.png" } },
			],
		}
		GameData.EVENTS["test_art_event"] = {
			"id": "test_art_event",
			"cards": [
				choice_card,
				{ "type": "narration", "key": "next", "label": null, "speaker": null, "text": "Next", "image": null },
				{ "type": "narration", "key": "far", "label": null, "speaker": null, "text": "Far", "image": "res://far.png" },
				{ "type": "narration", "key": "won", "label": null, "speaker": null, "text": "Won" },
			],
		}
		var original_probe := _fake_files(["%s4.png" % STEM])
		Events.start_event("test_art_event")
		var paths: Array = Events.next_image_paths()
		paths.sort()
		var expected: Array = ["res://far.png", "res://look.png", "res://win.png", "%s4.png" % STEM]
		expected.sort()
		assert_eq(paths, expected, "option images, goto targets' stills, distinct; a null image is skipped")
		Events.convention_asset_exists = original_probe
		GameData.EVENTS = original_events
	)

extends "res://tests/test_base.gd"

# Stage engine: direction data integrity, fold resolution, viewport fit, and a
# headless StagePlayer run through every card of archie_craft_chat.

const EVENT_ID := "archie_craft_chat"


func run() -> void:
	run_case("every_stage_references_resolve", func():
		assert_true(GameData.STAGES.has(EVENT_ID), "archie_craft_chat has a stage")
		for event_id in GameData.STAGES:
			var stage: Dictionary = GameData.STAGES[event_id]
			assert_true(GameData.EVENTS.has(event_id), "%s stage matches an event" % event_id)
			assert_true(stage["cards"].size() <= GameData.EVENTS[event_id]["cards"].size(), "%s: no more direction entries than cards" % event_id)
			assert_true(GameData.STAGE_SETS.has(stage["set"]), "%s: set exists" % event_id)
			var set_def: Dictionary = GameData.STAGE_SETS[stage["set"]]
			_assert_set_files(set_def)
			for actor_id in stage["actors"]:
				var rig_id: String = stage["actors"][actor_id]["rig"]
				assert_true(GameData.STAGE_RIGS.has(rig_id), "%s: rig %s exists" % [event_id, rig_id])
				_assert_rig_files(GameData.STAGE_RIGS[rig_id])
				var facing: String = stage["actors"][actor_id].get("facing", "right")
				assert_true(facing == "left" or facing == "right", "%s: %s facing is left/right" % [event_id, actor_id])
			for object_id in stage.get("objects", {}):
				assert_true(set_def["objects"].has(object_id), "%s: object %s exists in the set" % [event_id, object_id])
			for card in stage["cards"]:
				for step in card["steps"]:
					_assert_step_valid(event_id, stage, set_def, step)
	)

	run_case("fold_keeps_the_dropped_falafel_and_the_camera_move", func():
		var stage: Dictionary = GameData.STAGES[EVENT_ID]
		var start := StageDirection.resolve_start(stage, 0)
		assert_eq(start["camera_x"], float(stage["camera"]["x"]), "camera starts at the stage default")
		assert_eq(start["actors"]["archie"]["arm_l"], "hold", "rig defaults before card 1")
		assert_eq(StageDirection.resolve_start(stage, 3)["props"].size(), 0, "nothing on the floor before card 4")
		var card5 := StageDirection.resolve_start(stage, 4)
		assert_eq(card5["props"].size(), 1, "the falafel stays on the floor after card 4")
		assert_eq(card5["props"][0]["prop"], "falafel_crumb", "it is the falafel crumb")
		assert_eq(card5["actors"]["archie"]["mouth"], "agape", "mouth still hangs open entering card 5")
		var after_tilt := StageDirection.resolve_end(stage, 6)
		assert_eq(after_tilt["actors"]["archie"]["tilt"], -7, "card 7 ends with the head tilted")
		var last := StageDirection.resolve_end(stage, 11)
		assert_eq(last["camera_x"], 150.0, "card 12 pans to the bin")
		assert_eq(last["actors"]["archie"]["arm_l"], "rest", "throw action ends at rest")
		assert_eq(last["props"].size(), 1, "the falafel is still there at the end")
	)

	run_case("talk_seconds_counts_quoted_speech_and_clamps", func():
		var behaviour := {"talk_per_char": 0.1, "talk_min": 1.0, "talk_max": 3.0}
		assert_almost_eq(StageDirection.talk_seconds("\"Hello there.\" He tilts his head.", behaviour), 1.2, 0.001, "narration is silent")
		assert_almost_eq(StageDirection.talk_seconds("\"Hi\"", behaviour), 1.0, 0.001, "short line clamps up")
		assert_almost_eq(StageDirection.talk_seconds("x".repeat(100), behaviour), 3.0, 0.001, "unquoted long text clamps down")
	)

	run_case("viewport_fit_is_integer_scaled_and_covers_the_frame", func():
		var fit := StageDirection.viewport_fit(Vector2(1170, 1572), 180)
		assert_eq(fit["scale"], 6, "1170px wide -> 6x")
		assert_eq(fit["size"], Vector2i(195, 262), "viewport covers the frame")
		var small := StageDirection.viewport_fit(Vector2(100, 80), 180)
		assert_eq(small["scale"], 1, "never below 1x")
		assert_eq(small["size"], Vector2i(100, 80), "tiny frame maps 1:1")
	)

	run_case("events_uses_vn_mode_for_a_staged_event", func():
		GameState.reset()
		Events.start_event(EVENT_ID)
		assert_true(Events.has_stage(), "stage found for the live event")
		assert_true(Events.is_vn_mode(), "staged event renders in VN layout")
	)

	run_case("a_short_stage_covers_only_its_first_cards", func():
		GameState.reset()
		var original_stages: Dictionary = GameData.STAGES
		GameData.STAGES = GameData.STAGES.duplicate()
		var short: Dictionary = GameData.STAGES[EVENT_ID].duplicate()
		short["cards"] = short["cards"].slice(0, 2)
		GameData.STAGES[EVENT_ID] = short
		Events.start_event(EVENT_ID)
		assert_true(Events.is_staged_card(), "card 1 is staged")
		GameState.state["event"]["cardIndex"] = 2
		assert_true(not Events.is_staged_card(), "card 3 is past the stage")
		assert_true(Events.is_vn_mode(), "unstaged cards keep the VN layout")
		GameData.STAGES = original_stages
	)

	run_case("intro_mockups_stage_six_intro_cards_and_end_inert", func():
		var intro: Dictionary = GameData.EVENTS["intro"]
		for mock_id in ["intro2", "intro3", "intro4", "intro5", "intro6"]:
			var mock: Dictionary = GameData.EVENTS[mock_id]
			assert_eq(mock["cards"].size(), intro["cards"].size(), "%s keeps every intro card" % mock_id)
			for i in range(1, intro["cards"].size()):
				assert_eq(mock["cards"][i], intro["cards"][i], "%s card %d matches intro" % [mock_id, i + 1])
			var stage: Dictionary = GameData.STAGES[mock_id]
			assert_eq(stage["cards"].size(), 6, "%s stages cards 1-6" % mock_id)
			var style: String = stage["set"].trim_prefix("alley_")
			for actor in stage["actors"].values():
				assert_true(actor["rig"].ends_with("_" + style), "%s rig %s matches set style %s" % [mock_id, actor["rig"], style])
			GameState.reset()
			var flags_before: Dictionary = GameState.state["flags"].duplicate(true)
			Events.start_event(mock_id)
			for i in range(mock["cards"].size()):
				assert_eq(Events.is_staged_card(), i < 6, "%s card %d staged only within the first six" % [mock_id, i + 1])
				Events.advance()
			assert_eq(GameState.state["flags"], flags_before, "%s sets no flags or tutorial stage" % mock_id)
			assert_eq(GameState.state["currentScreen"], "phone", "%s ends on the phone" % mock_id)
	)

	run_case("player_rests_and_wakes_cleanly", func():
		GameState.reset()
		GameState.state["meta"]["reducedMotion"] = false
		var player := _player()
		player.show_card(3)
		for _tick in range(5):
			player.advance(0.1)
		player.rest()
		assert_true(not player.visible, "a resting stage is hidden")
		assert_eq(player._steps.size() + player._fx.size(), 0, "nothing left queued or in flight")
		assert_eq(_resting_props(player), 0, "no props left behind")
		player.show_card(4)
		assert_true(player.visible, "the next staged card wakes it")
		assert_eq(_resting_props(player), 1, "falafel rebuilt from the fold")
		player.free()
	)

	run_case("player_steps_through_every_card", func():
		GameState.reset()
		GameState.state["meta"]["reducedMotion"] = false
		var player := _player()
		var stage: Dictionary = GameData.STAGES[EVENT_ID]
		for i in range(stage["cards"].size()):
			player.show_card(i)
			for _tick in range(80):
				player.advance(0.1)
			if i == 3:
				assert_eq(_resting_props(player), 1, "falafel lands and stays after card 4 plays")
				assert_eq(player._actors["archie"].attrs["mouth"], "agape", "mouth hangs open")
		assert_eq(player._fx.size(), 0, "every effect finished")
		assert_almost_eq(player._camera_x, 150.0, 0.01, "camera reached the bin")
		player.show_card(1)
		assert_almost_eq(player._camera_x, float(stage["camera"]["x"]), 0.01, "rewinding snaps the camera back")
		player.free()
	)

	run_case("reduced_motion_snaps_each_card_to_its_end_state", func():
		GameState.reset()
		GameState.state["meta"]["reducedMotion"] = true
		var player := _player()
		player.show_card(3)
		assert_eq(_resting_props(player), 1, "falafel already on the floor")
		assert_eq(player._steps.size(), 0, "no timed steps queued")
		assert_eq(player._actors["archie"].attrs["eyes"], "wide", "card 4 end look")
		player.free()
		GameState.state["meta"]["reducedMotion"] = false
	)

	run_case("fold_tracks_moves_facing_and_visibility", func():
		var restore := _install_cast_stage()
		var stage := _cast_stage()
		var start := StageDirection.resolve_start(stage, 0)
		assert_eq(start["objects"]["bin"]["x"], -30, "stage override starts the object off-screen")
		assert_eq(start["actors"]["buyer"]["visible"], false, "hidden actor starts hidden")
		assert_eq(start["actors"]["buyer"]["facing"], "left", "actor def sets starting facing")
		assert_eq(start["actors"]["archie"]["facing"], "right", "rig's drawn facing by default")
		assert_eq(start["actors"]["archie"]["x"], 230, "actor def x")
		var card1_end := StageDirection.resolve_end(stage, 0)
		assert_eq(card1_end["objects"]["bin"]["x"], 100, "object ends where it drove to")
		assert_eq(card1_end["actors"]["buyer"]["visible"], true, "shown actor stays shown")
		var card3 := StageDirection.resolve_start(stage, 2)
		assert_eq(card3["actors"]["buyer"]["x"], 180, "move target x rounded to an integer")
		assert_eq(card3["actors"]["archie"]["facing"], "left", "facing set persists")
		var last := StageDirection.resolve_end(stage, 2)
		assert_eq(last["actors"]["buyer"]["visible"], false, "hide persists")
		assert_eq(last["actors"]["archie"]["x"], 330, "actor ends at the walk target")
		assert_eq(last["objects"]["bin"]["x"], 100, "object stays parked")
		restore.call()
	)

	run_case("validation_catches_bad_cast_steps", func():
		var restore := _install_cast_stage()
		var stage := _cast_stage()
		var set_def: Dictionary = GameData.STAGE_SETS[stage["set"]]
		for card in stage["cards"]:
			for step in card["steps"]:
				assert_eq(_step_problems(stage, set_def, step).size(), 0, "fixture step %s is valid" % str(step))
		var bad := [
			{"t": 0, "move": {"target": "nobody", "x": 10, "dur": 1}},
			{"t": 0, "move": {"target": "archie", "dur": 1}},
			{"t": 0, "show": "nobody"},
			{"t": 0, "hide": "nobody"},
			{"t": 0, "set": {"archie.facing": "up"}},
			{"t": 0, "set": {"nobody.arm_l": "rest"}},
			{"t": 0, "set": {"archie.arm_l": "no_such_frame"}},
			{"t": 0, "wiggle": "archie"},
			{"t": 0, "throw": {"prop": "falafel_crumb", "from": "archie.hand_l", "to": "bin", "at": 50, "dur": 1, "arc": 1}},
			{"t": 0, "throw": {"prop": "falafel_crumb", "from": "archie.hand_l", "dur": 1, "arc": 1}},
			{"t": 0, "slow": {"x": 10, "scale": 0.5}},
			{"t": 0, "slow": {"x": 10, "radius": 20, "scale": 0}},
			{"t": 0, "slow": {"x": 10, "radius": 20, "scale": 1.5}},
		]
		for card in _slow_stage()["cards"]:
			for step in card["steps"]:
				assert_eq(_step_problems(_slow_stage(), set_def, step).size(), 0, "slow fixture step %s is valid" % str(step))
		for step in bad:
			assert_true(_step_problems(stage, set_def, step).size() > 0, "caught bad step %s" % str(step))
		var rig: Dictionary = _walker_rig()
		assert_eq(_walk_problems(rig).size(), 0, "fixture walk cycle is valid")
		rig["walk"]["frames"] = ["stride_a", "no_such_frame"]
		assert_true(_walk_problems(rig).size() > 0, "caught missing walk frame")
		restore.call()
	)

	run_case("facing_flip_mirrors_anchors_and_drops", func():
		GameState.reset()
		var actor := StageActor.new()
		actor.setup(GameData.STAGE_RIGS["archie"])
		var hand := actor.anchor("hand_l")
		var mouth := actor.anchor("mouth")
		actor.apply_attrs({"facing": "left"})
		assert_eq(actor.scale.x, -1.0, "rig flips")
		assert_eq(actor.anchor("hand_l"), Vector2(-hand.x, hand.y), "hand anchor mirrors")
		assert_eq(actor.anchor("mouth"), Vector2(-mouth.x, mouth.y), "mouth anchor mirrors")
		actor.apply_attrs({"facing": "right"})
		assert_eq(actor.anchor("hand_l"), hand, "facing back restores the anchor")
		actor.free()
		var stage := _cast_stage()
		var drop := {"prop": "falafel_crumb", "from": "archie.mouth", "land": [5, 0]}
		assert_eq(StageDirection.drop_landing(stage, drop, 100.0, "right").x, 105.0, "drop lands ahead")
		assert_eq(StageDirection.drop_landing(stage, drop, 100.0, "left").x, 95.0, "mirrored drop lands the other side")
	)

	run_case("idle_life_is_per_actor_and_springs_to_tilt", func():
		GameState.reset()
		var rig: Dictionary = GameData.STAGE_RIGS["archie_minimal"]
		var a := StageActor.new()
		var b := StageActor.new()
		a.setup(rig)
		b.setup(rig)
		assert_true(a._breathe_phase != b._breathe_phase or a._breathe_period != b._breathe_period, "two actors breathe on their own rhythm")
		a.set_attr("tilt", -7)
		for i in range(40):
			a.step(0.05)
			var body: Vector2 = a._body.position
			var px := float(rig["px"])
			assert_eq(body / px, (body / px).round(), "body offset stays on whole art pixels")
		assert_almost_eq(a._tilt, -7.0 + a._idle_tilt, 1.0, "tilt spring settles on target plus idle drift")
		a.motion = false
		a.apply_attrs({"tilt": 3})
		assert_eq(a._tilt, 3.0, "reduced motion: tilt snaps with no idle drift")
		a.free()
		b.free()
	)

	run_case("live_turn_dips_then_flips_snapshot_flips_at_once", func():
		GameState.reset()
		var actor := StageActor.new()
		actor.setup(GameData.STAGE_RIGS["archie_minimal"])
		var turn := float(actor.rig["behaviour"]["turn_len"])
		actor.set_attr("facing", "left")
		assert_true(not actor.is_mirrored(), "live turn starts on the old facing")
		actor.step(turn * 0.25)
		var px := float(actor.rig["px"])
		assert_eq(actor._body.position.y, px, "body dips one art pixel into the turn")
		actor.step(turn * 0.5)
		assert_true(actor.is_mirrored(), "flips halfway through the turn")
		assert_eq(actor.scale.x, -1.0, "drawn mirrored after the flip")
		actor.apply_attrs({"facing": "right"})
		assert_true(not actor.is_mirrored(), "snapshot apply flips at once")
		actor.set_attr("arm_r", "vial")
		actor.step(0.01)
		assert_eq(actor._body.position.y, px, "arm move dips the body for the effort")
		actor.motion = false
		actor.set_attr("facing", "left")
		assert_true(actor.is_mirrored(), "reduced motion flips at once")
		actor.free()
	)

	run_case("player_moves_walks_and_rewinds_the_cast", func():
		GameState.reset()
		GameState.state["meta"]["reducedMotion"] = false
		var restore := _install_cast_stage()
		var player := _player(CAST_ID)
		var buyer: StageActor = player._actors["buyer"]
		var archie: StageActor = player._actors["archie"]
		player.show_card(0)
		assert_eq(player._objects["bin"]["x"], -30.0, "object starts off-screen")
		assert_true(not buyer.visible, "buyer starts hidden")
		player.advance(0.5)
		var mid_x: float = player._objects["bin"]["x"]
		assert_true(mid_x > -30.0 and mid_x < 100.0, "object is on its way")
		assert_eq(mid_x, roundf(mid_x), "object x stays integer")
		for _tick in range(20):
			player.advance(0.1)
		assert_eq(player._objects["bin"]["x"], 100.0, "object parked")
		assert_true(buyer.visible, "buyer appears")
		player.show_card(1)
		assert_eq(buyer.position.x, 40.0, "buyer snaps to card start")
		player.advance(0.05)
		player.advance(0.3)
		assert_true(buyer.walking, "buyer walks while moving")
		assert_true(buyer.shown_frame("legs") in ["stride_a", "stride_b"], "walk cycle plays on the legs")
		assert_eq(buyer.position.x, roundf(buyer.position.x), "actor x stays integer")
		for _tick in range(30):
			player.advance(0.1)
		assert_eq(buyer.position.x, 180.0, "buyer arrives")
		assert_true(not buyer.walking, "buyer stops walking on arrival")
		assert_eq(buyer.shown_frame("legs"), "base", "standing legs restored")
		assert_eq(archie.scale.x, -1.0, "archie turned to face left")
		player.show_card(2)
		player.advance(0.5)
		assert_true(not buyer.visible, "buyer leaves")
		assert_eq(archie.shown_frame("legs"), "base", "rig without a walk cycle just slides")
		player.show_card(0)
		assert_eq(buyer.position.x, 40.0, "rewind puts the buyer back")
		assert_true(not buyer.visible, "rewind hides the buyer again")
		assert_eq(archie.scale.x, 1.0, "rewind restores archie's facing")
		assert_eq(archie.position.x, 230.0, "rewind restores archie's position")
		assert_eq(player._moves.size(), 0, "no moves carried across cards")
		player.free()
		restore.call()
	)

	run_case("reduced_motion_snaps_moves_without_walking", func():
		GameState.reset()
		GameState.state["meta"]["reducedMotion"] = true
		var restore := _install_cast_stage()
		var player := _player(CAST_ID)
		var buyer: StageActor = player._actors["buyer"]
		player.show_card(1)
		assert_eq(buyer.position.x, 180.0, "buyer already at the end position")
		assert_true(buyer.visible, "buyer shown")
		assert_true(not buyer.walking, "no walk")
		assert_eq(buyer.shown_frame("legs"), "base", "standing legs")
		assert_eq(player._objects["bin"]["x"], 100.0, "object already parked")
		assert_eq(player._steps.size() + player._moves.size(), 0, "nothing queued")
		player.show_card(2)
		assert_eq(player._actors["archie"].position.x, 330.0, "archie already at the exit")
		player.free()
		restore.call()
		GameState.state["meta"]["reducedMotion"] = false
	)

	run_case("fold_keeps_slow_fields", func():
		var restore := _install_cast_stage()
		var stage := _slow_stage()
		assert_eq(StageDirection.resolve_start(stage, 0)["fields"].size(), 0, "no field before the vial")
		var fields: Array = StageDirection.resolve_start(stage, 2)["fields"]
		assert_eq(fields.size(), 1, "the field persists into later cards")
		assert_eq(fields[0], {"x": 120, "radius": 40, "height": StageDirection.FIELD_HEIGHT, "scale": 0.25}, "field shape")
		assert_eq(StageDirection.time_scale_at(fields, 150.0), 0.25, "inside the field runs slow")
		assert_eq(StageDirection.time_scale_at(fields, 330.0), 1.0, "outside runs at normal speed")
		var thrown := StageDirection.resolve_end(stage, 0)
		assert_eq(thrown["props"].size(), 0, "a shattered vial leaves no prop")
		restore.call()
	)

	run_case("floor_throw_shatters_and_field_slows_actors_inside", func():
		GameState.reset()
		GameState.state["meta"]["reducedMotion"] = false
		var restore := _install_cast_stage()
		var player := _player(SLOW_ID)
		var buyer: StageActor = player._actors["buyer"]
		var archie: StageActor = player._actors["archie"]
		player.show_card(0)
		for _tick in range(7):
			player.advance(0.1)
		var shards := player._fx.filter(func(fx: Dictionary) -> bool: return fx["kind"] == "shard")
		assert_true(shards.size() > 0, "vial shatters on the floor")
		assert_eq(player._fields.size(), 1, "field stands where it landed")
		for _tick in range(10):
			player.advance(0.1)
		assert_eq(player.time_scale_of(buyer), 0.25, "buyer inside the grown field is slowed")
		assert_eq(player.time_scale_of(archie), 1.0, "archie outside keeps normal speed")
		var buyer_t := buyer._time
		var archie_t := archie._time
		for _tick in range(10):
			player.advance(0.1)
		assert_almost_eq(buyer._time - buyer_t, 0.25, 0.001, "buyer's clock runs at a quarter")
		assert_almost_eq(archie._time - archie_t, 1.0, 0.001, "archie's clock runs normally")
		assert_eq(player._fx.size(), 0, "shards have faded")
		player.show_card(1)
		assert_eq(player._fields.size(), 1, "later card rebuilds the field from the fold")
		assert_eq(player.time_scale_of(buyer), 0.25, "buyer slowed straight away on a jump")
		for _tick in range(10):
			player.advance(0.1)
		assert_true(buyer.position.x < 150.0, "slowed walk hasn't arrived after its nominal duration")
		assert_true(buyer.walking, "still walking")
		for _tick in range(40):
			player.advance(0.1)
		assert_eq(buyer.position.x, 150.0, "slowed walk arrives in the end")
		player.show_card(0)
		assert_eq(player._fields.size(), 0, "rewinding before the vial clears the field")
		assert_eq(player.time_scale_of(buyer), 1.0, "and the buyer runs normally again")
		player.free()
		restore.call()
	)

	run_case("reduced_motion_shows_a_static_field", func():
		GameState.reset()
		GameState.state["meta"]["reducedMotion"] = true
		var restore := _install_cast_stage()
		var player := _player(SLOW_ID)
		player.show_card(0)
		assert_eq(player._fields.size(), 1, "field already standing")
		var material: ShaderMaterial = player._fields[0]["material"]
		assert_eq(material.get_shader_parameter("motion"), 0.0, "no ripple")
		assert_eq(material.get_shader_parameter("grow"), 1.0, "full size, no growth")
		player.advance(0.5)
		assert_eq(material.get_shader_parameter("time"), 0.0, "ripple clock held")
		assert_eq(player._fx.size(), 0, "no shatter")
		assert_true(not player._actors["buyer"].motion, "slowed actor holds still")
		player.free()
		restore.call()
		GameState.state["meta"]["reducedMotion"] = false
	)


const CAST_ID := "test_stage_cast"
const SLOW_ID := "test_stage_slow"


# Archie throws a vial at the floor by the buyer; a slow field stands there.
# Archie walks off (outside it); next card the buyer walks inside it.
func _slow_stage() -> Dictionary:
	return {
		"set": "spitalfields", "camera": {"x": 205},
		"actors": {
			"archie": {"rig": "archie", "x": 230},
			"buyer": {"rig": "test_walker", "x": 120},
		},
		"cards": [
			{"steps": [
				{"t": 0.0, "throw": {"prop": "falafel_crumb", "from": "archie.hand_l", "at": 120, "dur": 0.6, "arc": 30}},
				{"t": 0.6, "slow": {"x": 120, "radius": 40, "scale": 0.25, "grow": 0.5}},
				{"t": 0.6, "move": {"target": "archie", "x": 330, "dur": 2.0}},
			]},
			{"steps": [{"t": 0.0, "move": {"target": "buyer", "x": 150, "dur": 1.0}}]},
			{"steps": []},
		],
	}


# Bin stands in for a car: drives in from off-screen. Buyer uses a rig with a
# walk cycle; archie's rig has none.
func _cast_stage() -> Dictionary:
	return {
		"set": "spitalfields", "camera": {"x": 205},
		"actors": {
			"archie": {"rig": "archie", "x": 230},
			"buyer": {"rig": "test_walker", "x": 40, "hidden": true, "facing": "left"},
		},
		"objects": {"bin": {"x": -30}},
		"cards": [
			{"steps": [{"t": 0.0, "move": {"target": "bin", "x": 100, "dur": 1.5}}, {"t": 1.6, "show": "buyer"}]},
			{"steps": [{"t": 0.0, "move": {"target": "buyer", "x": 180.4, "dur": 2.0}}, {"t": 0.5, "set": {"archie.facing": "left"}}]},
			{"steps": [{"t": 0.0, "hide": "buyer"}, {"t": 0.0, "move": {"target": "archie", "x": 330, "dur": 2.0}}]},
		],
	}


func _walker_rig() -> Dictionary:
	var rig: Dictionary = GameData.STAGE_RIGS["archie"].duplicate(true)
	rig["id"] = "test_walker"
	rig["parts"]["legs"]["frames"]["stride_a"] = "legs.png"
	rig["parts"]["legs"]["frames"]["stride_b"] = "legs.png"
	rig["walk"] = {"part": "legs", "frames": ["stride_a", "stride_b"], "frame_time": 0.1, "stand": "base"}
	return rig


# Registers the cast stage (and its rig) in GameData; returns the undo.
func _install_cast_stage() -> Callable:
	var original_stages: Dictionary = GameData.STAGES
	var original_rigs: Dictionary = GameData.STAGE_RIGS
	GameData.STAGE_RIGS = GameData.STAGE_RIGS.duplicate()
	GameData.STAGE_RIGS["test_walker"] = _walker_rig()
	GameData.STAGES = GameData.STAGES.duplicate()
	GameData.STAGES[CAST_ID] = _cast_stage()
	GameData.STAGES[SLOW_ID] = _slow_stage()
	return func():
		GameData.STAGES = original_stages
		GameData.STAGE_RIGS = original_rigs


func _player(event_id: String = EVENT_ID) -> StagePlayer:
	var player := StagePlayer.new()
	player.size = Vector2(390, 520)
	player.setup(event_id)
	return player


func _resting_props(player: StagePlayer) -> int:
	var count := 0
	for child in player._props_root.get_children():
		if not child.is_queued_for_deletion():
			count += 1
	return count - player._fx.size()


func _assert_set_files(set_def: Dictionary) -> void:
	var dir: String = set_def["dir"]
	var files: Array = []
	for layer in set_def["layers"]:
		files.append(layer["file"])
	for walker in set_def["walkers"]["list"]:
		files.append_array(walker["frames"])
	for entry in set_def["ambient"]:
		files.append_array(entry["frames"])
	files.append(set_def["lights"]["file"])
	for obj in set_def["objects"].values():
		files.append(obj["back"])
		if obj.has("front"):
			files.append(obj["front"])
	files.append_array(set_def["props"].values())
	for file in files:
		assert_true(ResourceLoader.exists(dir + String(file)), "set file %s exists" % file)


func _assert_rig_files(rig: Dictionary) -> void:
	for part_id in rig["order"]:
		for frame_id in rig["parts"][part_id]["frames"]:
			var path: String = String(rig["dir"]) + String(rig["parts"][part_id]["frames"][frame_id])
			assert_true(ResourceLoader.exists(path), "rig file %s exists" % path)
	for action_id in rig["actions"]:
		for step in rig["actions"][action_id]:
			for attr in step["set"]:
				assert_true(rig["parts"][attr]["frames"].has(step["set"][attr]), "action %s frame %s exists" % [action_id, step["set"][attr]])
	for problem in _walk_problems(rig):
		assert_true(false, "%s: %s" % [rig["id"], problem])


func _assert_step_valid(event_id: String, stage: Dictionary, set_def: Dictionary, step: Dictionary) -> void:
	for problem in _step_problems(stage, set_def, step):
		assert_true(false, "%s: %s" % [event_id, problem])


# Everything wrong with one direction step (empty = valid).
func _step_problems(stage: Dictionary, set_def: Dictionary, step: Dictionary) -> Array:
	var problems: Array = []
	var actors: Dictionary = stage["actors"]
	if not step.has("t"):
		problems.append("step has no time")
	if step.has("set"):
		for path in step["set"]:
			var target := StageDirection.split_target(path)
			if not actors.has(target[0]):
				problems.append("set: unknown actor %s" % target[0])
				continue
			var rig := StageDirection.rig_for(stage, target[0])
			var value: Variant = step["set"][path]
			if target[1] == "tilt":
				if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
					problems.append("tilt is not a number")
			elif target[1] == "facing":
				if value != "left" and value != "right":
					problems.append("facing %s is not left/right" % value)
			elif target[1] == "mouth":
				if not (rig["parts"]["mouth"]["frames"].has(value) or rig["mouth_states"].has(value)):
					problems.append("mouth %s missing" % value)
			elif not rig["parts"].has(target[1]) or not rig["parts"][target[1]]["frames"].has(value):
				problems.append("%s frame %s missing" % [target[1], value])
	elif step.has("play"):
		var target := StageDirection.split_target(step["play"])
		if not actors.has(target[0]) or not StageDirection.rig_for(stage, target[0])["actions"].has(target[1]):
			problems.append("action %s missing" % step["play"])
	elif step.has("talk"):
		if not actors.has(step["talk"]):
			problems.append("talking actor %s missing" % step["talk"])
	elif step.has("drop"):
		if not set_def["props"].has(step["drop"]["prop"]):
			problems.append("drop prop %s missing" % step["drop"]["prop"])
		if not actors.has(StageDirection.split_target(step["drop"]["from"])[0]):
			problems.append("drop actor missing")
	elif step.has("throw"):
		var throw: Dictionary = step["throw"]
		if not set_def["props"].has(throw["prop"]):
			problems.append("throw prop %s missing" % throw["prop"])
		if throw.has("to") == throw.has("at"):
			problems.append("throw needs exactly one of to (object) / at (floor x)")
		elif throw.has("to") and not set_def["objects"].has(throw["to"]):
			problems.append("throw target %s missing" % throw["to"])
		elif throw.has("at") and typeof(throw["at"]) != TYPE_INT and typeof(throw["at"]) != TYPE_FLOAT:
			problems.append("throw at is not a number")
	elif step.has("slow"):
		var slow: Dictionary = step["slow"]
		for key in ["x", "radius", "scale"]:
			if typeof(slow.get(key)) != TYPE_INT and typeof(slow.get(key)) != TYPE_FLOAT:
				problems.append("slow %s is not a number" % key)
		if problems.is_empty():
			if float(slow["radius"]) <= 0.0:
				problems.append("slow radius must be positive")
			if float(slow["scale"]) <= 0.0 or float(slow["scale"]) > 1.0:
				problems.append("slow scale must be in (0, 1]")
	elif step.has("move"):
		var move: Dictionary = step["move"]
		var target: String = move.get("target", "")
		if actors.has(target) == set_def["objects"].has(target):
			problems.append("move target %s is not exactly one actor or object" % target)
		if typeof(move.get("x")) != TYPE_INT and typeof(move.get("x")) != TYPE_FLOAT:
			problems.append("move x is not a number")
	elif step.has("show") or step.has("hide"):
		if not actors.has(step.get("show", step.get("hide"))):
			problems.append("show/hide actor %s missing" % step.get("show", step.get("hide")))
	elif not step.has("camera"):
		problems.append("unknown step kind %s" % str(step.keys()))
	return problems


# Everything wrong with a rig's walk cycle declaration (empty = valid or none).
func _walk_problems(rig: Dictionary) -> Array:
	if not rig.has("walk"):
		return []
	var walk: Dictionary = rig["walk"]
	if not rig["parts"].has(walk.get("part", "")):
		return ["walk part %s missing" % walk.get("part", "")]
	var frames: Dictionary = rig["parts"][walk["part"]]["frames"]
	var problems: Array = []
	for frame_id in walk["frames"] + [walk["stand"]]:
		if not frames.has(frame_id):
			problems.append("walk frame %s missing" % frame_id)
	if float(walk.get("frame_time", 0.0)) <= 0.0:
		problems.append("walk frame_time must be positive")
	return problems

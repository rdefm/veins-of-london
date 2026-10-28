extends "res://tests/test_base.gd"

# CombatStage's own layout and juice maths, off-tree.

func run() -> void:
	run_case("slot_sizes_scale_by_configured_sprite_scale", func():
		var scale: float = CombatStage.configured_sprite_scale()
		assert_eq(scale, float(GameData.COMBAT_VISUALS["stage"]["spriteScale"]), "stage reads its sprite scale from data/combat_visuals.json")
		var stage_size := Vector2(CombatStage.STAGE_WIDTH, CombatStage.STAGE_HEIGHT)
		var clearance: float = CombatRoundsScreen._STRIP_TOP_INSET + TurnOrderStrip.MAX_EXPANDED_CARD_HEIGHT
		for side in ["player", "enemy"]:
			var base := CombatStage.group_rects(Combat.SQUAD_MAX, side, stage_size, clearance, 1.0)
			var scaled := CombatStage.group_rects(Combat.SQUAD_MAX, side, stage_size, clearance, scale)
			for i in range(base.size()):
				assert_true(is_equal_approx(scaled[i].size.y, base[i].size.y * scale) and is_equal_approx(scaled[i].size.x, base[i].size.x * scale), "%s slot %d must be %.2fx its base size" % [side, i, scale])
	)

	run_case("a_figure_box_fills_its_slot_bottom_centred_and_mirrors_when_flipped", func():
		# A 128² frame whose figure is 29×71 at (45, 57), like the shipped idle sheets.
		var frame := Vector2(128, 128)
		var box := Rect2(45, 57, 29, 71)
		var slot := Vector2(40, 80)
		var rect := CombatStage.StageSlot.figure_frame_rect(slot, frame, box, false)
		var fit: float = rect.size.x / frame.x
		var figure := Rect2(rect.position + box.position * fit, box.size * fit)
		assert_almost_eq(figure.size.y, slot.y, 0.01, "a tall figure fills the slot's height")
		assert_almost_eq(figure.end.y, slot.y, 0.01, "feet on the slot's bottom edge")
		assert_almost_eq(figure.get_center().x, slot.x / 2.0, 0.01, "horizontally centred")

		var flipped := CombatStage.StageSlot.figure_frame_rect(slot, frame, box, true)
		var mirrored_x: float = frame.x - box.end.x
		assert_almost_eq(flipped.position.x + (mirrored_x + box.size.x / 2.0) * fit, slot.x / 2.0, 0.01, "a flipped frame's figure is still centred")
	)

	run_case("rewind_label_sits_below_top_clearance", func():
		var stage := CombatStage.new()
		stage._build()
		stage.set_top_clearance(200.0)
		var label := stage._rewind_fx.get_child(0) as Label
		assert_true(label.position.y >= 200.0, "label clears the strip band")
		stage.free()
	)

	run_case("rewind_effect_shows_only_when_set_and_clears_again", func():
		var stage := CombatStage.new()
		stage._build()
		assert_true(not stage.is_rewind_effect_active(), "no VHS look before a Rewind")
		stage.set_rewind_effect(true)
		assert_true(stage.is_rewind_effect_active(), "VHS look shows during the reverse")
		stage.set_rewind_effect(false)
		assert_true(not stage.is_rewind_effect_active(), "VHS look clears afterwards")
		assert_eq(CombatDirector.rewind_speed(), 5.0, "pacing.rewindSpeed")
		stage.free()
	)

	run_case("freeze_visual_changes_directly_off_tree_and_ko_clears_it_at_once", func():
		var slot := CombatStage.StageSlot.new()
		slot.set_frozen_visual(true, true)
		assert_true(slot._sprite_rect.material != null, "freeze installs the pause shader")
		assert_true(slot._freeze_tween == null, "no tape-stop tween off-tree (restored frames rebuild directly)")
		slot.set_frozen_visual(false, true)
		assert_true(slot._sprite_rect.material == null, "off-tree unfreeze clears with no play-snap")
		slot.set_frozen_visual(true)
		slot.play_ko()
		assert_true(slot._sprite_rect.material == null, "KO clears the freeze look instantly")
		slot.free()
	)

	run_case("stunned_bob_never_shows_on_a_frozen_sprite_and_ko_clears_it", func():
		var slot := CombatStage.StageSlot.new()
		slot.set_stunned_visual(true)
		assert_true(slot._sprite_rect.material == slot._stun_material, "stunned installs the bob shader")
		slot.set_frozen_visual(true)
		assert_true(slot._sprite_rect.material == slot._frozen_shader_material, "freeze look wins")
		slot.set_stunned_visual(false)
		assert_true(slot._sprite_rect.material == slot._frozen_shader_material, "still frozen")
		slot.set_stunned_visual(true)
		slot.set_frozen_visual(false)
		assert_true(slot._sprite_rect.material == slot._stun_material, "bob takes over when the freeze ends")
		slot.set_stunned_visual(false)
		assert_true(slot._sprite_rect.material == null, "clears when the last lost action passes")
		slot.set_stunned_visual(true)
		slot.play_ko()
		assert_true(slot._sprite_rect.material == null, "KO clears the bob at once")
		slot.free()
	)

	run_case("powder_linger_speeds_idle_and_clears_directly_on_ko", func():
		var slot := CombatStage.StageSlot.new()
		var frames: Array[Texture2D] = [PlaceholderTexture2D.new(), PlaceholderTexture2D.new()]
		slot.set_idle_animation(frames, 10.0)
		assert_almost_eq(slot._idle_timer.wait_time, 0.1, 0.0001, "base idle")
		slot.set_powder_linger(true)
		assert_almost_eq(slot._idle_timer.wait_time, 0.1 / float(CombatStage.powder_fx()["idleSpeed"]), 0.0001, "faster idle")
		slot.set_powder_linger(false)
		assert_almost_eq(slot._idle_timer.wait_time, 0.1, 0.0001, "off-tree exit sets it outright")
		slot.set_powder_linger(true)
		slot.play_ko()
		assert_almost_eq(slot._idle_timer.wait_time, 0.1, 0.0001, "KO clears instantly")
		slot.free()
	)

	run_case("panic_linger_greys_and_jitters_rapture_linger_slows_idle_and_tints_and_ko_clears_both", func():
		var slot := CombatStage.StageSlot.new()
		var frames: Array[Texture2D] = [PlaceholderTexture2D.new(), PlaceholderTexture2D.new()]
		slot.set_idle_animation(frames, 10.0)
		slot.set_panic_linger(true)
		assert_true(slot._figure_holder.modulate.r < 1.0, "panic greys the figure")
		assert_true(slot._jitter_timer != null and slot._jitter_timer.autostart, "jitter runs")
		slot.set_panic_linger(false)
		assert_eq(slot._figure_holder.modulate, Color.WHITE, "tint ends with the status")
		slot.set_rapture_linger(true)
		assert_almost_eq(slot._idle_timer.wait_time, 0.1 / float(CombatStage.pan_fx("rapture")["idleSpeed"]), 0.0001, "idle at half speed")
		assert_true(slot._figure_holder.modulate.b < 1.0, "warm pink tint")
		slot.clear_pan_state()
		assert_almost_eq(slot._idle_timer.wait_time, 0.1, 0.0001, "clear restores idle")
		assert_eq(slot._figure_holder.modulate, Color.WHITE, "clear drops the tint")
		slot.set_panic_linger(true)
		slot.play_ko()
		assert_eq(slot._figure_holder.modulate, Color.WHITE, "KO clears instantly")
		slot.free()
	)

	run_case("reduced_motion_keeps_the_pan_tints_but_drops_jitter", func():
		var prior = GameState.state.get("meta", {}).get("reducedMotion", false)
		GameState.state["meta"]["reducedMotion"] = true
		var slot := CombatStage.StageSlot.new()
		slot.set_panic_linger(true)
		assert_true(slot._jitter_timer == null, "no jitter timer")
		assert_true(slot._figure_holder.modulate.r < 1.0, "tint stays")
		slot.free()
		GameState.state["meta"]["reducedMotion"] = prior
	)

	run_case("anger_state_hot_cold_rims_scale_flip_and_ko_clear", func():
		var slot := CombatStage.StageSlot.new()
		var fx := CombatStage.anger_fx()
		var pct := float(fx["scalePct"]) / 100.0
		slot.set_anger_state("hot", false, false)
		assert_true(slot._anger_rim != null, "rim up")
		assert_true(slot._anger_rim.modulate.r > 0.9 and slot._anger_rim.modulate.b < 0.5, "hot rim is red")
		assert_almost_eq(slot._figure_holder.scale.y, 1.0 + pct, 0.0001, "hot scales up")
		slot.set_anger_state("cold", false, false)
		assert_true(slot._anger_rim.modulate.b > 0.6, "cold rim is purple")
		assert_almost_eq(slot._figure_holder.scale.y, 1.0 - pct, 0.0001, "cold scales down")
		assert_almost_eq(slot._figure_holder.position.y, float(fx["slumpPx"]), 0.0001, "cold slumps")
		slot.set_anger_state("cold", true, false)
		assert_true(slot._anger_steam_tween == null, "no steam off-tree")
		slot.set_anger_state("", false, false)
		assert_true(slot._anger_rim == null, "calm drops the rim outright off-tree")
		assert_almost_eq(slot._figure_holder.scale.y, 1.0, 0.0001, "scale home")
		assert_almost_eq(slot._figure_holder.position.y, 0.0, 0.0001, "slump gone")
		slot.set_anger_state("hot", false, false)
		slot.play_ko()
		assert_true(slot._anger_rim == null and absf(slot._figure_holder.scale.y - 1.0) < 0.0001, "KO clears instantly")
		slot.free()
	)

	run_case("reduced_motion_keeps_the_anger_rim_colour_but_drops_scale", func():
		var prior = GameState.state.get("meta", {}).get("reducedMotion", false)
		GameState.state["meta"]["reducedMotion"] = true
		var slot := CombatStage.StageSlot.new()
		slot.set_anger_state("hot", false, false)
		assert_true(slot._anger_rim != null, "rim colour stays")
		assert_almost_eq(slot._figure_holder.scale.y, 1.0, 0.0001, "no scale")
		slot.free()
		GameState.state["meta"]["reducedMotion"] = prior
	)

	run_case("pan_fx_is_data_for_both_statuses_and_both_effects_carry_stand_in_data", func():
		for which in ["panic", "rapture"]:
			assert_true(not CombatStage.pan_fx(which).is_empty(), "%s panFx" % which)
			var data := CombatStage.effect_data(which)
			for field in ["colour", "landColour", "travelSeconds", "landSeconds"]:
				assert_true(data.has(field), "%s has %s" % [which, field])
		assert_true(float(CombatStage.effect_data("panic")["travelSeconds"]) < float(CombatStage.effect_data("rapture")["travelSeconds"]), "panic fast, rapture slow")
		assert_true(float(CombatStage.effect_data("panic")["landSeconds"]) < float(CombatStage.effect_data("rapture")["landSeconds"]), "panic small, rapture wide")
	)

	run_case("freeze_fx_durations_are_data_driven_and_halve_when_quick", func():
		var fx: Dictionary = GameData.COMBAT_VISUALS["pacing"]["freezeFx"]
		var prior: String = CombatPacing.pacing_mode()
		CombatPacing.set_pacing_mode("normal")
		assert_almost_eq(CombatStage.StageSlot._freeze_seconds("tapeStopSeconds"), float(fx["tapeStopSeconds"]), 0.001, "normal reads freezeFx")
		CombatPacing.set_pacing_mode("quick")
		assert_almost_eq(CombatStage.StageSlot._freeze_seconds("playSnapSeconds"), float(fx["playSnapSeconds"]) * 0.5, 0.001, "quick halves")
		CombatPacing.set_pacing_mode(prior)
	)

	run_case("every_effect_carries_stand_in_data_and_blast_travels_with_a_crit_shake", func():
		for key in ["timePearl", "blast", "shield", "healingBurst", "blackHole"]:
			var data := CombatStage.effect_data(key)
			for field in ["colour", "travelSeconds", "landSeconds", "shakeScale"]:
				assert_true(data.has(field), "%s has %s" % [key, field])
			assert_true(float(data["landSeconds"]) > 0.0, "%s stand-in lasts" % key)
		var blast := CombatStage.effect_data("blast")
		assert_true(float(blast["travelSeconds"]) > 0.0, "blast spark travels")
		assert_almost_eq(float(blast["shakeScale"]), 1.5, 0.001, "crit-scale shake")
		assert_almost_eq(CombatStage.fx_seconds(1.0), 1.0 if CombatPacing.pacing_mode() != "quick" else 0.5, 0.001, "fx seconds follow pacing")
	)

	run_case("shield_panels_follow_the_pool_and_the_guard_marker_waits_out_a_burst", func():
		var n := CombatStage.StageSlot.shield_panel_count()
		assert_true(n > 0, "panels are data")
		assert_eq(CombatStage.StageSlot.shield_visible_count(1.0), n, "fresh pool shows all")
		assert_eq(CombatStage.StageSlot.shield_visible_count(0.0), 0, "none")
		assert_eq(CombatStage.StageSlot.shield_visible_count(0.01), 1, "any pool shows a panel")
		var stage := CombatStage.new()
		stage._build()
		var slot := CombatStage.StageSlot.new()
		slot.size = Vector2(100.0, 100.0)
		stage.add_child(slot)
		(Engine.get_main_loop() as SceneTree).root.add_child(stage)
		slot.set_guard_marker(CombatStage.GUARD_MARKER_GUARDED)
		slot.set_shield_level(1.0, false)
		assert_eq(slot._shield_alpha.size(), n, "panels built")
		assert_true(slot._shimmer_tween != null, "shimmer runs while up")
		slot.set_shield_level(0.5, true)
		assert_true(slot._shield_tween != null and slot._shield_tween.is_valid(), "absorb sheds panels")
		slot.set_shield_level(0.0, true)
		assert_true(slot._shield_bursting, "break bursts")
		slot.set_guard_marker(CombatStage.GUARD_MARKER_OPEN)
		assert_eq(slot.guard_marker, CombatStage.GUARD_MARKER_GUARDED, "marker holds through the burst")
		slot._finish_shield_burst()
		assert_eq(slot.guard_marker, CombatStage.GUARD_MARKER_OPEN, "then settles on the real state")
		assert_true(slot._shimmer_tween == null, "shimmer stops")
		slot.set_shield_level(0.5, false)
		slot.set_shield_level(0.0, false)
		assert_true(not slot._shield_bursting and Array(slot._shield_alpha).max() == 0.0, "KO or rewind clears instantly")
		stage.free()
	)

	run_case("sheetless_effect_draws_a_stand_in_ring_on_the_target", func():
		var stage := CombatStage.new()
		stage._build()
		var slot := CombatStage.StageSlot.new()
		slot.size = Vector2(100.0, 100.0)
		stage.add_child(slot)
		slot.play_stand_in(Color.WHITE, 0.4)
		assert_true(not slot.get_children().any(func(n): return n is CombatStage.RingFx), "nothing drawn off-tree")
		(Engine.get_main_loop() as SceneTree).root.add_child(stage)
		slot.play_stand_in(Color.WHITE, 0.4)
		assert_true(slot.get_children().any(func(n): return n is CombatStage.RingFx), "ring added")
		stage.free()
	)

	run_case("shake_magnitude_scales_with_damage_as_a_fraction_of_hp_max_between_3_and_6px", func():
		var stage := CombatStage.new()

		assert_almost_eq(stage._shake_magnitude(0, 20), CombatStage.SHAKE_MIN_PX, 0.01, "no damage should read as the floor")
		assert_almost_eq(stage._shake_magnitude(10, 20), CombatStage.SHAKE_MAX_PX, 0.01, "50%+ of hpMax should already be at the cap (SHAKE_FULL_FRACTION)")
		assert_almost_eq(stage._shake_magnitude(1000, 20), CombatStage.SHAKE_MAX_PX, 0.01, "damage far beyond hpMax must still clamp at the cap, never exceed it")
		var mid: float = stage._shake_magnitude(5, 20)  # 25% of hpMax -- halfway to SHAKE_FULL_FRACTION
		assert_true(mid > CombatStage.SHAKE_MIN_PX and mid < CombatStage.SHAKE_MAX_PX, "a hit for a quarter of hpMax should shake somewhere between the floor and the cap")
	)

	run_case("run_off_exits_by_the_nearest_edge_for_every_slot", func():
		var fx: Dictionary = GameData.COMBAT_VISUALS["pacing"]["runOffFx"]
		var margin: float = float(fx["edgeMarginPx"])
		var left := CombatStage.StageSlot.run_off_path(60.0, 390.0, 40.0, margin)
		assert_eq(left["dir"], -1.0, "a slot left of centre runs off the left edge")
		assert_almost_eq(float(left["travel"]), 60.0 + 20.0 + margin, 0.01, "travel clears the figure past the edge")
		var right := CombatStage.StageSlot.run_off_path(300.0, 390.0, 40.0, margin)
		assert_eq(right["dir"], 1.0, "a slot right of centre runs off the right edge")
		assert_almost_eq(float(right["travel"]), 90.0 + 20.0 + margin, 0.01, "travel measured to the right edge")
	)

	run_case("run_off_durations_are_data_driven_and_halve_when_quick", func():
		var fx: Dictionary = GameData.COMBAT_VISUALS["pacing"]["runOffFx"]
		assert_true(float(fx["runSeconds"]) > 0.0 and int(fx["afterimageCount"]) == 2, "run-off tuning lives in data")
		var prev: String = CombatPacing.pacing_mode()
		CombatPacing.set_pacing_mode("quick")
		assert_almost_eq(CombatStage.StageSlot._run_off_seconds("runSeconds"), float(fx["runSeconds"]) * 0.5, 0.0001, "quick halves the run")
		CombatPacing.set_pacing_mode(prev)
	)

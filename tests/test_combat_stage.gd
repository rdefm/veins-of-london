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

	run_case("shake_magnitude_scales_with_damage_as_a_fraction_of_hp_max_between_3_and_6px", func():
		var stage := CombatStage.new()

		assert_almost_eq(stage._shake_magnitude(0, 20), CombatStage.SHAKE_MIN_PX, 0.01, "no damage should read as the floor")
		assert_almost_eq(stage._shake_magnitude(10, 20), CombatStage.SHAKE_MAX_PX, 0.01, "50%+ of hpMax should already be at the cap (SHAKE_FULL_FRACTION)")
		assert_almost_eq(stage._shake_magnitude(1000, 20), CombatStage.SHAKE_MAX_PX, 0.01, "damage far beyond hpMax must still clamp at the cap, never exceed it")
		var mid: float = stage._shake_magnitude(5, 20)  # 25% of hpMax -- halfway to SHAKE_FULL_FRACTION
		assert_true(mid > CombatStage.SHAKE_MIN_PX and mid < CombatStage.SHAKE_MAX_PX, "a hit for a quarter of hpMax should shake somewhere between the floor and the cap")
	)

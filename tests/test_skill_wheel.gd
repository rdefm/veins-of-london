extends "res://tests/test_base.gd"

# SkillWheel component: builds from a SkillTree projection;
# selecting a segment sets the selected bucket / expanded state.


func run() -> void:
	run_case("wheel_builds_from_projection_with_body_selected_and_collapsed", func():
		GameState.reset()
		var wheel := SkillWheel.build(SkillTree.project(), "body", false)
		assert_eq(wheel.selected_id, "body", "Body selected")
		assert_true(not wheel.expanded, "collapsed")
		assert_eq(wheel._clip.custom_minimum_size.y, 0.0, "details hidden")
		wheel.free()
	)

	run_case("wheel_tap_selects_opens_and_retap_collapses", func():
		GameState.reset()
		var seen: Array = []
		var wheel := SkillWheel.build(SkillTree.project(), "body", false, func(b, e): seen.append([b, e]))
		wheel.select("mind")
		assert_eq([wheel.selected_id, wheel.expanded], ["mind", true], "mind opens")
		wheel.select("mind")
		assert_eq([wheel.selected_id, wheel.expanded], ["mind", false], "re-tap collapses")
		wheel.select("soul")
		assert_eq([wheel.selected_id, wheel.expanded], ["soul", true], "other segment reopens")
		assert_eq(seen, [["mind", true], ["mind", false], ["soul", true]], "on_change reported each time")
		wheel.free()
	)

	run_case("wheel_details_list_sub_skills_and_feats_for_selected_bucket", func():
		GameState.reset()
		var wheel := SkillWheel.build(SkillTree.project(), "mind", true)
		var texts: Array = wheel._details.find_children("", "Label", true, false).map(func(l): return l.text)
		assert_true(texts.any(func(t): return t.begins_with("Sense")), "sense listed")
		assert_true(texts.any(func(t): return t.begins_with("Crafting")), "crafting listed")
		assert_true(texts.any(func(t): return t.begins_with("Lv")), "feat lines listed")
		assert_true(wheel._clip.custom_minimum_size.y > 0.0, "open height set")
		wheel.free()
	)

	run_case("wheel_segment_hit_test_follows_rotation", func():
		GameState.reset()
		var wheel := SkillWheel.build(SkillTree.project(), "body", false)
		wheel._wheel.size = Vector2(240, 240)
		assert_eq(wheel.segment_at(Vector2(120, 220)), "body", "bottom is Body at rest")
		wheel.select("mind")
		assert_eq(wheel.segment_at(Vector2(120, 220)), "mind", "selected segment rotates to bottom")
		wheel.free()
	)

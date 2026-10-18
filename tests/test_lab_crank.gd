extends "res://tests/test_base.gd"

# LabGauges.CrankGauge's drag maths, driven by _drag_to off-tree.

var _committed := []


func _crank() -> LabGauges.CrankGauge:
	var crank := LabGauges.CrankGauge.new()
	crank.size = Vector2(300, 220)
	var data := Lab.gauge("compression")
	crank.gain_per_rev = float(data["crankGainPerRev"])
	crank.deadzone_deg = float(data["crankDeadzoneDeg"])
	crank.min_radius_frac = float(data["crankMinRadiusFrac"])
	crank.min_bend_deg = float(data["crankMinBendDeg"])
	crank.crack_at = -1.0
	return crank


# Presses at the ring's top, then drags round it by step_deg per move.
func _turn(crank: LabGauges.CrankGauge, total_deg: float, step_deg: float) -> void:
	var hub := crank._centre()
	var radius := crank._crank_radius()
	var angle := -PI / 2.0
	crank._turning = true
	crank._value = 0.0
	crank._last_step = Vector2.ZERO
	crank._last = hub + Vector2.from_angle(angle) * radius
	var sign_ := 1.0 if total_deg >= 0.0 else -1.0
	var done := 0.0
	while done < absf(total_deg):
		angle += deg_to_rad(step_deg) * sign_
		done += step_deg
		crank._drag_to(hub + Vector2.from_angle(angle) * radius)


func run() -> void:
	run_case("clockwise_turn_advances_in_proportion_to_angle", func():
		var crank := _crank()
		_turn(crank, 360.0, 10.0)
		assert_almost_eq(crank._value, crank.gain_per_rev * 350.0 / 360.0, 0.01, "a revolution less the first step (it only sets the heading)")
		crank.free()
	)

	run_case("anticlockwise_turn_does_nothing", func():
		var crank := _crank()
		_turn(crank, -360.0, 10.0)
		assert_eq(crank._value, 0.0, "no advance")
		crank.free()
	)

	run_case("straight_drag_does_nothing", func():
		var crank := _crank()
		var hub := crank._centre()
		var radius := crank._crank_radius()
		crank._turning = true
		crank._last_step = Vector2.ZERO
		crank._last = hub + Vector2(-radius, -radius * 0.9)
		for i in 20:
			crank._drag_to(hub + Vector2(-radius + radius * 2.0 * (i + 1) / 20.0, -radius * 0.9))
		assert_eq(crank._value, 0.0, "a straight line is not a turn")
		crank.free()
	)

	run_case("steps_under_the_deadzone_and_near_the_hub_are_ignored", func():
		var crank := _crank()
		_turn(crank, 90.0, crank.deadzone_deg * 0.5)
		assert_eq(crank._value, 0.0, "jitter is ignored")
		var hub := crank._centre()
		crank._last = hub + Vector2(2, 0)
		crank._drag_to(hub + Vector2(0, 2))
		assert_eq(crank._value, 0.0, "hub wobble is ignored")
		crank.free()
	)

	run_case("release_commits_the_needle_and_crack_commits_at_once", func():
		var crank := _crank()
		_committed.clear()
		crank.committed.connect(func(value: float): _committed.append(value))
		_turn(crank, 180.0, 10.0)
		crank._release()
		assert_eq(_committed.size(), 1, "release commits once")
		assert_almost_eq(_committed[0], crank.gain_per_rev * 170.0 / 360.0, 0.01, "the raw needle value")
		crank.crack_at = 10.0
		_turn(crank, 360.0, 10.0)
		assert_eq(_committed.size(), 2, "crossing crack_at commits immediately")
		crank.free()
	)

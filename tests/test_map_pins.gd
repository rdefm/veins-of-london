extends "res://tests/test_base.gd"

# MapPins.active_contact_pins() (M1.5 N2 contact pin). Exercised against
# the real archie_cultivation event data (the only pin-bearing event as of
# T13) rather than a synthetic fixture, since GameData.EVENTS is loaded
# once at boot and isn't swappable per-test.
#
# collective1-08 adds two more real pin-bearing events (col_a1_prospecting,
# col_a1_seeding); their own gating is exercised against the real event
# data in tests/test_col_a1_tuition.gd instead of duplicated here.


func run() -> void:
	run_case("archie_cultivation_pin_hidden_before_archiePartnerSeen", func():
		GameState.reset()
		var pins := MapPins.active_contact_pins()
		var ids: Array = []
		for pin in pins:
			ids.append(pin["eventId"])
		assert_true(not ids.has("archie_cultivation"), "flag gate not met yet -- pin shouldn't show")
		GameState.reset()
	)

	run_case("archie_cultivation_pin_shows_once_flags_line_up", func():
		GameState.reset()
		GameState.state["flags"]["archiePartnerSeen"] = true
		GameState.state["flags"]["cultivationTutorialSeen"] = false

		var pins := MapPins.active_contact_pins()
		var found: Variant = null
		for pin in pins:
			if pin["eventId"] == "archie_cultivation":
				found = pin
		assert_true(found != null, "archiePartnerSeen true + cultivationTutorialSeen false -- pin should show")
		assert_eq(found["district"], "whitechapel", "pin district comes from the event's own pin data")
		GameState.reset()
	)

	run_case("archie_cultivation_pin_hidden_once_tutorial_seen", func():
		GameState.reset()
		GameState.state["flags"]["archiePartnerSeen"] = true
		GameState.state["flags"]["cultivationTutorialSeen"] = true

		var pins := MapPins.active_contact_pins()
		var ids: Array = []
		for pin in pins:
			ids.append(pin["eventId"])
		assert_true(not ids.has("archie_cultivation"), "showWhenFlagsFalse should hide the pin once the flag flips true")
		GameState.reset()
	)

	# collective1-04: MapPins gate extension -- minRelation/minDay, tested
	# directly against _flags_satisfied() with synthetic pin blocks since
	# no real event currently carries these keys.

	run_case("min_relation_absent_defaults_to_no_constraint", func():
		GameState.reset()
		var pin := { "district": "shoreditch" }
		assert_true(MapPins._flags_satisfied(pin, GameState.state), "no minRelation key -- unconstrained")
		GameState.reset()
	)

	run_case("min_relation_blocks_below_threshold", func():
		GameState.reset()
		GameState.state["factions"]["collective"]["relation"] = 10
		var pin := { "district": "shoreditch", "minRelation": { "faction": "collective", "value": 25 } }
		assert_true(not MapPins._flags_satisfied(pin, GameState.state), "relation 10 < required 25 -- gate fails")
		GameState.reset()
	)

	run_case("min_relation_passes_at_or_above_threshold", func():
		GameState.reset()
		GameState.state["factions"]["collective"]["relation"] = 25
		var pin := { "district": "shoreditch", "minRelation": { "faction": "collective", "value": 25 } }
		assert_true(MapPins._flags_satisfied(pin, GameState.state), "relation 25 >= required 25 -- gate passes")
		GameState.reset()
	)

	run_case("min_day_absent_defaults_to_no_constraint", func():
		GameState.reset()
		var pin := { "district": "shoreditch" }
		assert_true(MapPins._flags_satisfied(pin, GameState.state), "no minDay key -- unconstrained")
		GameState.reset()
	)

	run_case("min_day_blocks_before_threshold", func():
		GameState.reset()
		GameState.state["world"]["day"] = 1
		var pin := { "district": "shoreditch", "minDay": 4 }
		assert_true(not MapPins._flags_satisfied(pin, GameState.state), "day 1 < required 4 -- gate fails")
		GameState.reset()
	)

	run_case("min_day_passes_at_or_after_threshold", func():
		GameState.reset()
		GameState.state["world"]["day"] = 4
		var pin := { "district": "shoreditch", "minDay": 4 }
		assert_true(MapPins._flags_satisfied(pin, GameState.state), "day 4 >= required 4 -- gate passes")
		GameState.reset()
	)

	run_case("min_relation_and_min_day_combine_with_flag_gates", func():
		GameState.reset()
		GameState.state["flags"]["colA1DesMet"] = true
		GameState.state["flags"]["colA1ProspectingTaught"] = false
		GameState.state["factions"]["collective"]["relation"] = 30
		GameState.state["world"]["day"] = 5
		var pin := {
			"district": "shoreditch",
			"showWhenFlagsTrue": ["colA1DesMet"],
			"showWhenFlagsFalse": ["colA1ProspectingTaught"],
			"minRelation": { "faction": "collective", "value": 25 },
			"minDay": 4,
		}
		assert_true(MapPins._flags_satisfied(pin, GameState.state), "all four gates satisfied -- pin should show")

		GameState.state["factions"]["collective"]["relation"] = 10
		assert_true(not MapPins._flags_satisfied(pin, GameState.state), "flags+day satisfied but relation too low -- pin hidden")

		GameState.state["factions"]["collective"]["relation"] = 30
		GameState.state["world"]["day"] = 2
		assert_true(not MapPins._flags_satisfied(pin, GameState.state), "flags+relation satisfied but day too early -- pin hidden")

		GameState.state["world"]["day"] = 5
		GameState.state["flags"]["colA1ProspectingTaught"] = true
		assert_true(not MapPins._flags_satisfied(pin, GameState.state), "relation+day satisfied but showWhenFlagsFalse flag flipped true -- pin hidden")
		GameState.reset()
	)

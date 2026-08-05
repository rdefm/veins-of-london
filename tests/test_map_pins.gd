extends "res://tests/test_base.gd"

# MapPins.active_contact_pins() (M1.5 N2 contact pin). Exercised against
# the real archie_cultivation event data (the only pin-bearing event as of
# T13) rather than a synthetic fixture, since GameData.EVENTS is loaded
# once at boot and isn't swappable per-test.


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

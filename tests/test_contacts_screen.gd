extends "res://tests/test_base.gd"

func run() -> void:
	run_case("contacts_screen_uses_the_phone_device_shell", func():
		GameState.reset()
		var screen := ContactsScreen.new()
		screen._ready()
		assert_true(screen._device_shell != null)
		assert_true(screen._device_shell.app_surface.visible, "opened Contacts uses the dark app surface")
		assert_eq(screen._device_shell.app_surface.color, GameData.PALETTE["phone_bg_content"])
	)

	run_case("contact_actions_are_inline_and_retain_their_routes", func():
		GameState.reset()
		GameState.state["flags"]["buyerEventSeen"] = true
		GameState.state["player"]["orichalchum"]["time"] = 1
		var screen := ContactsScreen.new()
		screen._ready()
		var quick: Dictionary = {}
		for b in screen.find_children("", "Button", true, false):
			if (b as Button).has_meta("contact_quick_action"):
				quick[(b as Button).get_meta("contact_quick_action")] = b
		assert_true(quick.has("messages") and quick.has("trade") and quick.has("recruit"))
		assert_true((quick["recruit"] as Button).disabled, "recruitment remains relation-gated")
		(quick["trade"] as Button).pressed.emit()
		assert_eq(GameState.state["modal"]["type"], "sell_menu", "Trade retains Archie's sale route")
	)

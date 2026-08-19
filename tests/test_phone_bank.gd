extends "res://tests/test_base.gd"

# bugfixes-38: Reynard's (the Bank app) -- balance readout + the full
# transaction log Bank.record() builds (GameState.state["bankLog"]),
# screen-level-tested against a real PhoneScreen instance, same
# headless-scene pattern as tests/test_phone_notifications.gd.


static func _label_texts(root: Node) -> Array[String]:
	var texts: Array[String] = []
	for l in root.find_children("", "Label", true, false):
		texts.append((l as Label).text)
	return texts


func run() -> void:
	run_case("bank_shows_the_current_cash_balance", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 1234
		GameState.state["phoneNav"]["app"] = "bank"

		var phone := PhoneScreen.new()
		phone._ready()

		assert_true(_label_texts(phone).has("£1234"), "the balance card shows player.cash")

		phone.free()
	)

	run_case("bank_shows_an_empty_state_when_the_log_is_empty", func():
		GameState.reset()
		GameState.state["phoneNav"]["app"] = "bank"

		var phone := PhoneScreen.new()
		phone._ready()

		assert_true(_label_texts(phone).has("No transactions yet."), "an empty log shows an empty-state message")

		phone.free()
	)

	run_case("bank_shows_the_full_log_newest_first", func():
		GameState.reset()
		Bank.record(100, "First")
		Bank.record(-50, "Second")
		Bank.record(200, "Third")
		GameState.state["phoneNav"]["app"] = "bank"

		var phone := PhoneScreen.new()
		phone._ready()

		var texts := _label_texts(phone)
		var idx_first := texts.find("First — +£100")
		var idx_second := texts.find("Second — -£50")
		var idx_third := texts.find("Third — +£200")
		assert_true(idx_first != -1 and idx_second != -1 and idx_third != -1, "all three entries render with signed amounts")
		assert_true(idx_third < idx_second, "the newest entry (Third) renders above the middle one")
		assert_true(idx_second < idx_first, "the middle entry renders above the oldest one")

		phone.free()
	)

	run_case("bank_respects_the_50_entry_cap", func():
		GameState.reset()
		for i in range(55):
			Bank.record(i, "Transaction %d" % i)
		GameState.state["phoneNav"]["app"] = "bank"

		var phone := PhoneScreen.new()
		phone._ready()

		assert_eq(GameState.state["bankLog"].size(), Bank.LOG_CAP, "sanity: the underlying log is capped at 50")

		var texts := _label_texts(phone)
		assert_true(not texts.has("Transaction 0 — +£0"), "entries evicted from the log below the cap must not render")
		assert_true(texts.has("Transaction 54 — +£54"), "the newest entry renders")

		phone.free()
	)

	run_case("bank_is_reachable_from_the_app_grid_via_the_bank_tile", func():
		GameState.reset()

		var phone := PhoneScreen.new()
		phone._ready()

		var bank_tile: AppTile = null
		for t in phone.find_children("", "AppTile", true, false):
			if (t as AppTile)._app_id == "bank":
				bank_tile = t
		assert_true(bank_tile != null, "the app grid must include a Reynard's tile")

		var event := InputEventScreenTouch.new()
		event.pressed = true
		bank_tile._on_gui_input(event)

		assert_eq(GameState.state["phoneNav"]["app"], "bank", "tapping the tile opens the bank app via PhoneNav")

		phone.free()
	)

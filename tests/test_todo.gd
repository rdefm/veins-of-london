extends "res://tests/test_base.gd"

# Todo — the flag-driven home-screen checklist (R§3.11), shared by the
# tutorial-era `home` screen and Phone's Notes app.


func run() -> void:
	run_case("fresh_game_shows_only_the_first_item_undone", func():
		GameState.reset()
		var items := Todo.get_items()
		assert_eq(items.size(), 1, "only the first checklist item should be unlocked at game start")
		assert_eq(items[0]["done"], false, "first item should be undone")
		assert_eq(items[0]["text"], "Get back to Archie. He's sorting the new buyer.", "first item text")
	)

	run_case("buyer_wait_text_depends_on_day", func():
		GameState.reset()
		GameState.state["flags"]["metArchie"] = true
		GameState.state["world"]["day"] = 1
		var items := Todo.get_items()
		assert_eq(items[1]["text"], "Wait for Archie's text — he's lining up the buyer.", "day < 2 shows the waiting text")

		GameState.state["world"]["day"] = 2
		items = Todo.get_items()
		assert_eq(items[1]["text"], "Back up Archie on the sale tonight. Check Contacts.", "day >= 2 shows the follow-up text")
	)

	run_case("only_the_last_4_items_are_shown", func():
		GameState.reset()
		var flags: Dictionary = GameState.state["flags"]
		flags["metArchie"] = true
		flags["buyerEventSeen"] = true
		flags["metJames"] = true
		flags["craftingUnlocked"] = true
		flags["archieCraftChatSeen"] = true
		flags["homeRaidEventSeen"] = true
		flags["archiePartnerSeen"] = true

		var items := Todo.get_items()
		assert_eq(items.size(), 4, "checklist should cap at 4 items")
		assert_eq(items[3]["text"], "Archie's time vein is yours. Cultivate it. Harvest. Make pearls. Archie sells them.", "the newest unlocked item should be last")
	)

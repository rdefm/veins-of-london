extends "res://tests/test_base.gd"

# calc-effect-wiring-02: the Consumables tab now iterates every recipe key
# with inventory[key] > 0 instead of a hardcoded 3-item list, so any owned
# consumable shows up -- and only healingSalve/healingBurst (the two
# out-of-combat-usable effects) get a Use button on this tab. Same
# headless-scene pattern as tests/test_lab_screen.gd -- InventoryScreen.new()
# then _ready(), no live tree needed.


static func _label_texts(root: Node) -> Array[String]:
	var texts: Array[String] = []
	for l in root.find_children("", "Label", true, false):
		texts.append((l as Label).text)
	return texts


static func _find_button_in_card(root: Node, label_text: String, button_text: String) -> Button:
	for l in root.find_children("", "Label", true, false):
		if (l as Label).text == label_text:
			for sibling in l.get_parent().get_children():
				if sibling is Button and (sibling as Button).text == button_text:
					return sibling
	return null


func run() -> void:
	run_case("consumables_tab_lists_every_owned_recipe_not_just_the_original_three", func():
		GameState.reset()
		GameState.state["inventoryTab"] = "consumables"
		var player: Dictionary = GameState.state["player"]
		player["inventory"]["timePearl"] = 1
		player["inventory"]["blast"] = 1
		player["inventory"]["healingSalve"] = 1
		player["inventory"]["rejuvenation"] = 1

		var screen := InventoryScreen.new()
		screen._ready()

		var texts := _label_texts(screen)
		var joined := "\n".join(texts)
		assert_true(joined.contains("Time Pearl"), "still lists a pre-existing hardcoded item")
		assert_true(joined.contains("Blast"), "a newly-wired combat effect should show up without another hardcoded-list edit")
		assert_true(joined.contains("Healing Salve"), "healingSalve should show up")
		assert_true(joined.contains("Rejuvenation"), "sale-only rejuvenation should still be visible/sellable from this tab")

		screen.free()
	)

	run_case("consumables_tab_omits_recipes_the_player_does_not_hold", func():
		GameState.reset()
		GameState.state["inventoryTab"] = "consumables"
		GameState.state["player"]["inventory"]["shield"] = 0

		var screen := InventoryScreen.new()
		screen._ready()

		var joined := "\n".join(_label_texts(screen))
		assert_true(not joined.contains("Shield"), "a recipe at qty 0 should not appear")

		screen.free()
	)

	run_case("healingSalve_and_healingBurst_get_a_use_button_on_this_tab", func():
		GameState.reset()
		GameState.state["inventoryTab"] = "consumables"
		var player: Dictionary = GameState.state["player"]
		player["inventory"]["healingSalve"] = 1
		player["inventory"]["healingBurst"] = 1

		var screen := InventoryScreen.new()
		screen._ready()

		assert_true(_find_button_in_card(screen, "♥ Healing Salve ×1", "Use") != null, "healingSalve should get a Use button")
		assert_true(_find_button_in_card(screen, "✚ Healing Burst ×1", "Use") != null, "healingBurst should get a Use button")

		screen.free()
	)

	run_case("combat_only_and_sale_only_recipes_get_no_use_button_on_this_tab", func():
		GameState.reset()
		GameState.state["inventoryTab"] = "consumables"
		var player: Dictionary = GameState.state["player"]
		player["inventory"]["blast"] = 1
		player["inventory"]["shield"] = 1
		player["inventory"]["blackHole"] = 1
		player["inventory"]["rejuvenation"] = 1

		var screen := InventoryScreen.new()
		screen._ready()

		assert_true(_find_button_in_card(screen, "☄ Blast ×1", "Use") == null, "blast is combat-only, no Use button here")
		assert_true(_find_button_in_card(screen, "⛨ Shield ×1", "Use") == null, "shield is combat-only, no Use button here")
		assert_true(_find_button_in_card(screen, "⊙ Black Hole ×1", "Use") == null, "blackHole is combat-only, no Use button here")
		assert_true(_find_button_in_card(screen, "❀ Rejuvenation ×1", "Use") == null, "rejuvenation is sale-only, no Use action")

		screen.free()
	)

	run_case("use_button_calls_through_to_consumables_system", func():
		GameState.reset()
		GameState.state["inventoryTab"] = "consumables"
		var player: Dictionary = GameState.state["player"]
		player["inventory"]["healingBurst"] = 1
		player["hp"] = 50
		player["hpMax"] = 100

		var screen := InventoryScreen.new()
		screen._ready()

		var use_button := _find_button_in_card(screen, "✚ Healing Burst ×1", "Use")
		use_button.pressed.emit()

		assert_eq(GameState.state["player"]["inventory"]["healingBurst"], 0, "pressing Use should consume the item via Consumables.use_healing_burst()")
		assert_true(GameState.state["player"]["hp"] > 50, "pressing Use should actually apply the heal")

		screen.free()
	)

	run_case("active_healing_salve_hot_status_stays_visible_after_the_last_salve_is_used", func():
		GameState.reset()
		GameState.state["inventoryTab"] = "consumables"
		var player: Dictionary = GameState.state["player"]
		player["inventory"]["healingSalve"] = 0
		player["healingSalveDaysLeft"] = 1
		player["healingSalveDailyAmount"] = 5

		var screen := InventoryScreen.new()
		screen._ready()

		var joined := "\n".join(_label_texts(screen))
		assert_true(joined.contains("Healing Salve active"), "an active HoT should stay visible even once the card itself (qty 0) stops showing")

		screen.free()
	)

extends "res://tests/test_base.gd"


func run() -> void:
	run_case("equip_weapon_requires_an_owned_item", func():
		GameState.reset()
		var result := Equipment.equip_weapon("does_not_exist")
		assert_true(not result["ok"], "should refuse an item id the player doesn't own")
		assert_eq(GameState.state["player"]["equipment"]["weapon"], null, "weapon slot unchanged")
	)

	run_case("equip_and_unequip_weapon", func():
		GameState.reset()
		GameState.state["player"]["items"] = [{ "id": "item1", "type": "crowbar" }]
		var result := Equipment.equip_weapon("item1")
		assert_true(result["ok"], "should succeed for an owned item")
		assert_eq(GameState.state["player"]["equipment"]["weapon"], "item1", "weapon slot set")

		Equipment.unequip_weapon()
		assert_eq(GameState.state["player"]["equipment"]["weapon"], null, "weapon slot cleared")
	)

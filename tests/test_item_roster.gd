extends "res://tests/test_base.gd"

# The 24 roster-only items (docs/brainstorm.md): recipe row, price, market and
# master-source entries, shared placeholder icon, Bag listing while held.

const ROSTER := ["nearMiss", "sodsLaw", "happyAccident", "introduction", "smellingSalts", "rootFeed", "bloom", "borrowedTime", "patina", "ricochet", "deadweight", "signalFailure", "trueLevel", "dejaVu", "skeletonKey", "goodYear", "secondImpression", "stiffUpperLip", "heavyMetal", "coldFeet", "nostalgia", "navvysDraught", "cleanSlate", "keystone"]
const LORE_PRICE_EXCEPTIONS := { "introduction": 200, "nostalgia": 280 }


func run() -> void:
	run_case("roster_items_load_with_recipe_price_market_icon", func():
		for key in ROSTER:
			assert_true(GameData.RECIPES.has(key), "%s recipe" % key)
			var recipe: Dictionary = GameData.RECIPES.get(key, {})
			assert_true(not str(recipe.get("description", "")).is_empty(), "%s description" % key)
			var expected: int = LORE_PRICE_EXCEPTIONS.get(key, int(recipe.get("xpReward", 0)) * 6)
			assert_eq(int(GameData.CONSUMABLE_PRICES.get(key, 0)), expected, "%s price" % key)
			assert_true(GameData.MARKET["goods"]["consumable"].has(key), "%s market entry" % key)
			assert_true(ItemIcons.texture(key) != null, "%s icon" % key)
	)

	run_case("roster_bag_lists_item_only_while_held", func():
		GameState.reset()
		assert_eq(Crafting.inventory_qty("nearMiss"), 0, "none held")
		DebugTools.add_item("nearMiss", 1, 2)
		assert_eq(Crafting.inventory_qty("nearMiss"), 2, "debug grant lands in inventory")
		Bag.open()
		var drawer := BagDrawer.new()
		drawer._ready()
		var found := false
		for label in drawer.find_children("", "Label", true, false):
			if label.text == "Near Miss: 2":
				found = true
			assert_true(label.text != "Sod's Law: 0", "unheld roster item hidden")
		assert_true(found, "held roster item row shown")
		drawer.free()
	)

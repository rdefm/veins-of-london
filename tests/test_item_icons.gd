extends "res://tests/test_base.gd"

# ItemIcons lookup + SymbolGlyph icon binding on the Bag drawer's Consumables rows.

const CONSUMABLES := ["timePearl", "enhancementPowder", "rewind", "healingSalve", "blast", "shield", "blackHole", "prophetsBreath", "beALady", "panic", "panger", "pandemonium", "pansRapture", "healingBurst", "failsafe", "rejuvenation", "wormhole"]


func run() -> void:
	run_case("every_consumable_has_a_distinct_icon", func():
		var seen := {}
		for key in CONSUMABLES:
			var tex := ItemIcons.texture(key)
			assert_true(tex != null, "%s has an icon" % key)
			if tex != null:
				seen[tex.resource_path] = true
		assert_eq(seen.size(), CONSUMABLES.size(), "icons are distinct")
		assert_true(ItemIcons.texture("nonsense") == null, "unknown key -> no icon")
	)

	run_case("convention_path_then_icon_field_then_symbol", func():
		var old_dir: String = ItemIcons.icon_dir
		var saved: Dictionary = GameData.RECIPES.get("timePearl", {}).duplicate()
		var pearl: Dictionary = GameData.RECIPES["timePearl"]
		# Convention file wins over a different "icon" field.
		ItemIcons.icon_dir = "res://assets/combat/icons/"
		pearl["icon"] = "res://assets/combat/icons/rewind.png"
		ItemIcons._cache.clear()
		assert_eq(ItemIcons.texture("timePearl").resource_path, "res://assets/combat/icons/timePearl.png", "convention wins")
		# No convention file -> icon field.
		ItemIcons.icon_dir = "res://assets/items_nonexistent/"
		ItemIcons._cache.clear()
		assert_eq(ItemIcons.texture("timePearl").resource_path, "res://assets/combat/icons/rewind.png", "icon field fallback")
		# Neither -> null (symbol glyph).
		pearl.erase("icon")
		ItemIcons._cache.clear()
		assert_true(ItemIcons.texture("timePearl") == null, "symbol fallback")
		assert_true(ItemIcons.part("timePearl")["icon"] == null, "part has no icon")
		ItemIcons.icon_dir = old_dir
		pearl.merge(saved, true)
		ItemIcons._cache.clear()
	)

	run_case("bag_consumable_rows_bind_icons", func():
		GameState.reset()
		for key in Bag.CONSUMABLE_KEYS:
			Crafting.inventory_add(key, 1, 1)
		Bag.open()
		var drawer := BagDrawer.new()
		drawer._ready()
		var bound := {}
		for g in drawer.find_children("", "Control", true, false):
			if g is SymbolGlyph and g.icon != null:
				bound[g.icon.resource_path] = true
		for key in Bag.CONSUMABLE_KEYS:
			assert_true(bound.has(ItemIcons.texture(key).resource_path), "bag row for %s shows its icon" % key)
		drawer.free()
	)

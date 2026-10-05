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

	run_case("bag_consumable_rows_bind_icons", func():
		GameState.reset()
		Bag.open()
		var drawer := BagDrawer.new()
		drawer._ready()
		var bound := {}
		for g in drawer.find_children("", "Control", true, false):
			if g is SymbolGlyph and g.icon != null:
				bound[g.icon.resource_path] = true
		for key in BagDrawer.CONSUMABLE_KEYS:
			assert_true(bound.has(ItemIcons.texture(key).resource_path), "bag row for %s shows its icon" % key)
		drawer.free()
	)

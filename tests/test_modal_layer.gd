extends "res://tests/test_base.gd"

# Ticket 12: tapping outside a modal (_dim's gui_input) must close it,
# running the same side effect as that modal's own Close/Cancel/Decline
# button — not a bare Modal.close() that would leave sellState half-applied
# or skip james_job_offer's Jobs.decline_job() bookkeeping.
#
# ModalLayer.new() is safe to call _ready() on directly without adding it to
# a live scene tree, same reasoning tests/test_map_controls.gd already
# relies on for MapControls: nothing _ready() touches (UI.*, EventBus,
# GameState) depends on get_tree()/get_viewport() having run.


func _synthetic_tap() -> InputEventScreenTouch:
	var event := InputEventScreenTouch.new()
	event.pressed = true
	return event


static func _label_texts(root: Node) -> Array[String]:
	var texts: Array[String] = []
	for l in root.find_children("", "Label", true, false):
		texts.append((l as Label).text)
	return texts


static func _find_button(root: Node, text: String) -> Button:
	for b in root.find_children("", "Button", true, false):
		if (b as Button).text == text:
			return b
	return null


# vein-trade-assets ticket 01: one player vein wired to its site, same shape
# tests/test_vein_trade.gd's own _seed_vein uses, so VeinTrade.quote() and
# sell_to_faction() resolve for real inside the faction lane's Assets rows.
static func _seed_vein(id: String, growth: int, ore_type: String = "life") -> Dictionary:
	var site := {
		"id": "site_%s" % id, "district": "shoreditch", "tier": "fair", "oreType": ore_type,
		"bonuses": [], "discoveredDay": 1, "claimed": true, "factionVein": null,
		"hasNaturalVein": false,
	}
	var vein := {
		"id": id, "district": "shoreditch", "oreType": ore_type, "growth": growth,
		"security": "none", "alarmUpgrades": [], "location": "Test Alley",
		"claimedOnDay": 1, "siteId": "site_%s" % id, "hospitability": { "tier": "fair", "bonuses": [] },
		"rampantDays": 0,
	}
	GameState.state["world"]["sites"].append(site)
	GameState.state["player"]["veins"].append(vein)
	return vein


func run() -> void:
	run_case("tap_outside_a_no_side_effect_modal_just_closes_it", func():
		GameState.reset()
		Modal.open("seed_result", { "success": true, "oreType": "time" })

		var layer := ModalLayer.new()
		layer._ready()
		layer._on_dim_gui_input(_synthetic_tap())

		assert_eq(GameState.state["modal"], null, "outside tap closes the modal")

		layer.free()
	)

	run_case("tap_outside_sell_menu_clears_sell_state_same_as_cancel", func():
		GameState.reset()
		GameState.state["sellState"] = { "ore_time": 2 }
		Modal.open("sell_menu")

		var layer := ModalLayer.new()
		layer._ready()
		layer._on_dim_gui_input(_synthetic_tap())

		assert_eq(GameState.state["modal"], null, "outside tap closes sell_menu")
		assert_eq(GameState.state["sellState"], {}, "sellState is cleared, same as tapping Cancel")

		layer.free()
	)

	run_case("tap_outside_james_job_offer_declines_the_job_same_as_decline", func():
		GameState.reset()
		var job := { "type": "craft", "recipeKey": "timePearl", "recipeName": "Time Pearl", "symbol": "⧖", "qty": 2, "payPerItem": 10, "totalPay": 20, "byDay": 10 }
		GameState.state["jamesJob"] = job
		GameState.state["flags"]["jamesJobActive"] = true
		Modal.open("james_job_offer", { "job": job })

		var layer := ModalLayer.new()
		layer._ready()
		layer._on_dim_gui_input(_synthetic_tap())

		assert_eq(GameState.state["modal"], null, "outside tap closes james_job_offer")
		assert_eq(GameState.state["flags"]["jamesJobActive"], false, "declining clears jamesJobActive, same as tapping Decline")
		assert_eq(GameState.state["jamesJob"], null, "declining clears jamesJob, same as tapping Decline")

		layer.free()
	)

	run_case("tap_outside_sale_result_navigates_to_phone_home_same_as_back_to_it", func():
		GameState.reset()
		Nav.go_to("hq")
		Modal.open("sale_result", { "mugged": false, "earned": 40 })

		var layer := ModalLayer.new()
		layer._ready()
		layer._on_dim_gui_input(_synthetic_tap())

		assert_eq(GameState.state["modal"], null, "outside tap closes sale_result")
		assert_eq(GameState.state["currentScreen"], "phone", "outside tap navs to phone home, same as tapping Back to it")
		assert_eq(GameState.state["phoneNav"]["app"], "home", "should land on the grid itself, not whatever app was last open")

		layer.free()
	)

	# ── collective1-07: sell_menu's faction-lane branch ───────────────────

	run_case("faction_sell_menu_prices_via_the_faction_lane_not_archies_cut", func():
		GameState.reset()
		GameState.state["contacts"]["des"] = { "unlocked": true, "relation": 0 }
		GameState.state["player"]["orichalchum"]["time"] = 10
		Economy.adjust_sell_qty("ore_time", 3, 10)
		Modal.open("sell_menu", { "factionId": "collective", "contactId": "des" })

		var layer := ModalLayer.new()
		layer._ready()

		assert_true(_label_texts(layer).has("Trade with The Collective"), "heading names the faction, not 'Find a buyer'")
		# time basePrice 60, collective relation 0 -> sell spread 0.45 -> 33/unit -> 3*33=99
		assert_true(_label_texts(layer).has("You'll get: £99"), "gross reflects the collective's price, not archie's basePrice/cut split")

		layer.free()
	)

	run_case("faction_sell_menu_go_button_sells_appends_a_bark_and_opens_sale_result", func():
		GameState.reset()
		GameState.state["contacts"]["des"] = { "unlocked": true, "relation": 0 }
		GameState.state["player"]["orichalchum"]["time"] = 10
		Economy.adjust_sell_qty("ore_time", 2, 10)
		Modal.open("sell_menu", { "factionId": "collective", "contactId": "des" })

		var layer := ModalLayer.new()
		layer._ready()

		var go_button := _find_button(layer, "Go — trade")
		assert_true(go_button != null, "faction sell menu has a Go button")
		go_button.pressed.emit()

		assert_eq(GameState.state["player"]["cash"], 40 + 66, "2 units at 33/unit credited, no cut")
		assert_eq(GameState.state["messages"]["des"].size(), 1, "completing the trade appends a bark to des's conversation")
		assert_eq(GameState.state["modal"]["type"], "sale_result", "sale_result reused for the faction lane, same as Archie's")

		layer.free()
	)

	# Ticket 80: the Collective lane's sell_menu branch loops
	# GameData.CONSUMABLE_PRICES.keys() the same as Archie's, so with stock of
	# all 14 craftable recipes in hand, all 14 must render as sell rows.
	run_case("faction_sell_menu_lists_all_fourteen_craftable_recipes_when_held", func():
		GameState.reset()
		GameState.state["contacts"]["des"] = { "unlocked": true, "relation": 0 }
		GameState.state["flags"]["canSellConsumables"] = true
		for recipe_key in GameData.CONSUMABLE_PRICES.keys():
			Crafting.inventory_add(recipe_key, 1, 1)
		Modal.open("sell_menu", { "factionId": "collective", "contactId": "des" })

		var layer := ModalLayer.new()
		layer._ready()

		assert_eq(GameData.CONSUMABLE_PRICES.size(), 14, "sanity: all 14 craftable recipes must have a sale price")
		for recipe_key in GameData.RECIPES.keys():
			var recipe: Dictionary = GameData.RECIPES[recipe_key]
			var found := false
			for text in _label_texts(layer):
				if text.begins_with("%s %s (" % [recipe["symbol"], recipe["name"]]):
					found = true
					break
			assert_true(found, "%s must render as a sell row" % recipe_key)

		layer.free()
	)

	# ── vein-trade-assets ticket 01: Ore/Items/Assets sections ─────────────

	run_case("both_sell_menu_lanes_render_ore_items_and_assets_section_headers_when_unlocked", func():
		GameState.reset()
		GameState.state["contacts"]["des"] = { "unlocked": true, "relation": 0 }
		GameState.state["flags"]["veinSaleUnlocked"] = true

		var archie_layer := ModalLayer.new()
		Modal.open("sell_menu")
		archie_layer._ready()
		assert_true(_find_button(archie_layer, "Ore ▾") != null, "Archie lane: Ore section header")
		assert_true(_find_button(archie_layer, "Items ▾") != null, "Archie lane: Items section header")
		assert_true(_find_button(archie_layer, "Assets ▾") != null, "Archie lane: Assets section header")
		archie_layer.free()

		var faction_layer := ModalLayer.new()
		Modal.open("sell_menu", { "factionId": "collective", "contactId": "des" })
		faction_layer._ready()
		assert_true(_find_button(faction_layer, "Ore ▾") != null, "faction lane: Ore section header")
		assert_true(_find_button(faction_layer, "Items ▾") != null, "faction lane: Items section header")
		assert_true(_find_button(faction_layer, "Assets ▾") != null, "faction lane: Assets section header")
		faction_layer.free()
	)

	run_case("assets_section_is_absent_from_both_lanes_when_vein_sale_is_locked", func():
		GameState.reset()
		GameState.state["contacts"]["des"] = { "unlocked": true, "relation": 0 }
		GameState.state["flags"]["veinSaleUnlocked"] = false

		var archie_layer := ModalLayer.new()
		Modal.open("sell_menu")
		archie_layer._ready()
		assert_true(_find_button(archie_layer, "Assets ▾") == null, "Archie lane hides Assets while locked")
		archie_layer.free()

		var faction_layer := ModalLayer.new()
		Modal.open("sell_menu", { "factionId": "collective", "contactId": "des" })
		faction_layer._ready()
		assert_true(_find_button(faction_layer, "Assets ▾") == null, "faction lane hides Assets while locked")
		faction_layer.free()
	)

	run_case("archies_assets_section_lists_no_vein_rows_even_when_the_player_owns_one", func():
		GameState.reset()
		GameState.state["flags"]["veinSaleUnlocked"] = true
		_seed_vein("v1", 50)
		Modal.open("sell_menu")

		var layer := ModalLayer.new()
		layer._ready()

		assert_true(_find_button(layer, "Assets ▾") != null, "Assets header still renders")
		assert_true(_find_button(layer, "☐") == null, "no vein toggle row -- Archie's Assets stays inert")

		layer.free()
	)

	run_case("faction_sell_menus_assets_section_lists_every_owned_vein_as_a_toggle_row", func():
		GameState.reset()
		GameState.state["contacts"]["des"] = { "unlocked": true, "relation": 0 }
		GameState.state["flags"]["veinSaleUnlocked"] = true
		var vein := _seed_vein("v1", 50)
		var price: int = VeinTrade.quote(vein)
		Modal.open("sell_menu", { "factionId": "collective", "contactId": "des" })

		var layer := ModalLayer.new()
		layer._ready()

		var expected_label := "Shoreditch — %s %s (£%d)" % [GameData.ORE_TYPES["life"]["symbol"], GameData.ORE_TYPES["life"]["name"], price]
		assert_true(_label_texts(layer).has(expected_label), "vein row shows district/ore/price")
		assert_true(_find_button(layer, "☐") != null, "vein row starts unselected")

		layer.free()
	)

	run_case("toggling_a_vein_in_the_faction_lane_updates_the_go_label_and_gross", func():
		GameState.reset()
		GameState.state["contacts"]["des"] = { "unlocked": true, "relation": 0 }
		GameState.state["flags"]["veinSaleUnlocked"] = true
		var vein := _seed_vein("v1", 50)
		var price: int = VeinTrade.quote(vein)
		Modal.open("sell_menu", { "factionId": "collective", "contactId": "des" })

		var layer := ModalLayer.new()
		layer._ready()
		assert_true(_find_button(layer, "Go — trade") != null, "no vein selected yet -- plain label")

		var toggle := _find_button(layer, "☐")
		toggle.pressed.emit()

		assert_true(_find_button(layer, "Go — trade (includes 1 vein sale)") != null, "label calls out the vein sale")
		assert_true(_label_texts(layer).has("You'll get: £%d" % price), "gross includes the toggled vein's quote")

		layer.free()
	)

	run_case("go_on_the_faction_lane_sells_ore_and_a_toggled_vein_in_one_trade", func():
		GameState.reset()
		GameState.state["contacts"]["des"] = { "unlocked": true, "relation": 0 }
		GameState.state["flags"]["veinSaleUnlocked"] = true
		GameState.state["player"]["orichalchum"]["time"] = 10
		Economy.adjust_sell_qty("ore_time", 2, 10)
		var vein := _seed_vein("v1", 50)
		var vein_price: int = VeinTrade.quote(vein)
		var cash_before: int = GameState.state["player"]["cash"]
		Modal.open("sell_menu", { "factionId": "collective", "contactId": "des" })

		var layer := ModalLayer.new()
		layer._ready()
		_find_button(layer, "☐").pressed.emit()
		_find_button(layer, "Go — trade (includes 1 vein sale)").pressed.emit()

		# time basePrice 60, relation 0 -> sell spread 0.45 -> 33/unit -> 2*33=66
		assert_eq(GameState.state["player"]["cash"], cash_before + 66 + vein_price, "ore and vein proceeds land in one trade")
		assert_eq(GameState.state["player"]["veins"].size(), 0, "the sold vein leaves player.veins")
		assert_eq(GameState.state["modal"]["type"], "sale_result", "same result modal as an ore-only trade")

		layer.free()
	)

	run_case("non_press_input_on_the_dim_does_not_close_the_modal", func():
		GameState.reset()
		Modal.open("seed_result", { "success": true, "oreType": "time" })

		var layer := ModalLayer.new()
		layer._ready()

		var release := InputEventScreenTouch.new()
		release.pressed = false
		layer._on_dim_gui_input(release)

		assert_eq(GameState.state["modal"]["type"], "seed_result", "a release event doesn't dismiss the modal")

		layer.free()
	)

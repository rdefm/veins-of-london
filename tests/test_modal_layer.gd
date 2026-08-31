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


# vein-trade-assets ticket 03: the buy-side fixture -- a site already owned
# by the faction, so the faction lane's Assets section has a real buyable
# row to render.
static func _seed_faction_vein(id: String, growth: int, faction_id: String = "collective", ore_type: String = "life") -> Dictionary:
	var site := {
		"id": "site_%s" % id, "district": "shoreditch", "tier": "fair", "oreType": ore_type,
		"bonuses": [], "discoveredDay": 1, "claimed": false, "factionVein": null,
		"hasNaturalVein": false,
	}
	var vein := Factions.create_faction_vein(faction_id, site, growth)
	vein["id"] = id
	site["factionVein"] = vein
	GameState.state["world"]["sites"].append(site)
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

	# ── vein-trade-assets ticket 02: Archie's Assets section goes live ─────

	run_case("archies_assets_section_lists_every_owned_vein_as_a_toggle_row_priced_with_the_markup", func():
		GameState.reset()
		GameState.state["flags"]["veinSaleUnlocked"] = true
		var vein := _seed_vein("v1", 50)
		var price: int = Economy.get_archie_vein_price(vein)
		assert_true(price > VeinTrade.quote(vein), "sanity: the markup should price above the plain quote")
		Modal.open("sell_menu")

		var layer := ModalLayer.new()
		layer._ready()

		var expected_label := "Shoreditch — %s %s (£%d)" % [GameData.ORE_TYPES["life"]["symbol"], GameData.ORE_TYPES["life"]["name"], price]
		assert_true(_find_button(layer, "Assets ▾") != null, "Assets header still renders")
		assert_true(_label_texts(layer).has(expected_label), "vein row shows district/ore/Archie's marked-up price")
		assert_true(_find_button(layer, "☐") != null, "vein row starts unselected")

		layer.free()
	)

	run_case("toggling_a_vein_in_archies_lane_folds_the_markup_price_into_gross_and_cut", func():
		GameState.reset()
		GameState.state["flags"]["veinSaleUnlocked"] = true
		var vein := _seed_vein("v1", 50)
		var price: int = Economy.get_archie_vein_price(vein)
		var cut_ratio := Economy.get_archie_cut_ratio()
		Modal.open("sell_menu")

		var layer := ModalLayer.new()
		layer._ready()
		_find_button(layer, "☐").pressed.emit()

		var expected_cut: int = int(floor(price * cut_ratio))
		assert_true(_label_texts(layer).has("Your cut (%d%%): £%d" % [int(round(cut_ratio * 100)), expected_cut]), "cut reflects the vein's marked-up price")

		layer.free()
	)

	run_case("selecting_a_vein_in_archies_lane_swaps_the_displayed_mugging_chance_to_the_vein_rate", func():
		GameState.reset()
		GameState.state["flags"]["veinSaleUnlocked"] = true
		_seed_vein("v1", 50)
		Modal.open("sell_menu")

		var layer := ModalLayer.new()
		layer._ready()
		assert_true(_label_texts(layer).has("%d%% chance of mugging" % int(round(Economy.MUG_BASE_CHANCE * 100))), "no vein selected -- plain rate shown")

		_find_button(layer, "☐").pressed.emit()
		assert_true(_label_texts(layer).has("%d%% chance of mugging" % int(round(Economy.MUG_BASE_CHANCE_VEIN * 100))), "vein selected -- lower vein-lane rate shown")

		layer.free()
	)

	run_case("go_on_archies_lane_sells_ore_and_a_toggled_vein_in_one_trade_when_the_roll_does_not_mug", func():
		var seed := -1
		for candidate in range(300):
			GameState.reset()
			GameState.state["flags"]["veinSaleUnlocked"] = true
			GameState.state["player"]["orichalchum"]["time"] = 10
			Economy.adjust_sell_qty("ore_time", 2, 10)
			_seed_vein("v1", 50)
			Economy.toggle_sell_vein("v1")
			Rng.set_seed(candidate)
			var result := Economy.sell_from_sell_state()
			if not result.get("mugged", false):
				seed = candidate
				break
		assert_true(seed != -1, "should find a non-mugged roll within 300 tries")
		assert_eq(GameState.state["player"]["veins"].size(), 0, "the toggled vein left player.veins even though it was sold via Archie")
		assert_eq(GameState.state["modal"]["type"], "sale_result", "same result modal as an ore-only Archie sale")
	)

	run_case("archies_lane_transfers_a_mugged_vein_immediately_but_defers_its_cash_to_pendingSaleCut", func():
		var seed := -1
		for candidate in range(300):
			GameState.reset()
			GameState.state["flags"]["veinSaleUnlocked"] = true
			var vein := _seed_vein("v1", 50)
			var vein_key := "vein_%s" % vein["id"]
			GameState.state["sellState"][vein_key] = 1
			Rng.set_seed(candidate)
			var result := Economy.sell_from_sell_state()
			if result.get("mugged", false):
				seed = candidate
				break
		assert_true(seed != -1, "should find a mugged roll within 300 tries")
		assert_eq(GameState.state["player"]["veins"].size(), 0, "vein-trade-assets ticket 02, spec: the vein leaves player ownership regardless of the mugging outcome")
		assert_true(GameState.state["pendingSaleCut"] > 0, "cash is deferred, not lost -- paid out on muggingWon")
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

	# ── vein-trade-assets ticket 03: buy-side rows in the faction lane ──────

	run_case("faction_sell_menus_assets_section_lists_the_factions_own_veins_as_buyable_rows", func():
		GameState.reset()
		GameState.state["contacts"]["des"] = { "unlocked": true, "relation": 0 }
		GameState.state["flags"]["veinSaleUnlocked"] = true
		var faction_vein := _seed_faction_vein("fv1", 50)
		var price: int = VeinTrade.quote(faction_vein)
		Modal.open("sell_menu", { "factionId": "collective", "contactId": "des" })

		var layer := ModalLayer.new()
		layer._ready()

		var expected_label := "Buy: Shoreditch — %s %s (£%d)" % [GameData.ORE_TYPES["life"]["symbol"], GameData.ORE_TYPES["life"]["name"], price]
		assert_true(_label_texts(layer).has(expected_label), "buy row shows district/ore/price")
		assert_true(_find_button(layer, "☐") != null, "buy row starts unselected")

		layer.free()
	)

	run_case("archies_lane_never_shows_a_buy_vein_row_even_when_a_faction_vein_exists", func():
		GameState.reset()
		GameState.state["flags"]["veinSaleUnlocked"] = true
		_seed_faction_vein("fv1", 50)
		Modal.open("sell_menu")

		var layer := ModalLayer.new()
		layer._ready()

		for text in _label_texts(layer):
			assert_true(not text.begins_with("Buy:"), "Archie's lane has no faction vein stock to offer")

		layer.free()
	)

	run_case("toggling_a_buy_vein_in_the_faction_lane_updates_the_go_label_and_shows_the_net_cost", func():
		GameState.reset()
		GameState.state["contacts"]["des"] = { "unlocked": true, "relation": 0 }
		GameState.state["flags"]["veinSaleUnlocked"] = true
		var faction_vein := _seed_faction_vein("fv1", 50)
		var price: int = VeinTrade.quote(faction_vein)
		GameState.state["player"]["cash"] = 100000
		Modal.open("sell_menu", { "factionId": "collective", "contactId": "des" })

		var layer := ModalLayer.new()
		layer._ready()
		_find_button(layer, "☐").pressed.emit()

		assert_true(_find_button(layer, "Go — trade (includes 1 vein purchase)") != null, "label calls out the vein purchase")
		assert_true(_label_texts(layer).has("You'll pay: £%d" % price), "net flips to a cost once a buy outweighs the (empty) sell side")

		layer.free()
	)

	run_case("go_on_the_faction_lane_buys_a_toggled_faction_vein", func():
		GameState.reset()
		GameState.state["contacts"]["des"] = { "unlocked": true, "relation": 0 }
		GameState.state["flags"]["veinSaleUnlocked"] = true
		var faction_vein := _seed_faction_vein("fv1", 50)
		var price: int = VeinTrade.quote(faction_vein)
		GameState.state["player"]["cash"] = 100000
		var cash_before: int = GameState.state["player"]["cash"]
		Modal.open("sell_menu", { "factionId": "collective", "contactId": "des" })

		var layer := ModalLayer.new()
		layer._ready()
		_find_button(layer, "☐").pressed.emit()
		_find_button(layer, "Go — trade (includes 1 vein purchase)").pressed.emit()

		assert_eq(GameState.state["player"]["cash"], cash_before - price, "the purchase price is deducted")
		assert_eq(GameState.state["player"]["veins"].size(), 1, "the bought vein lands in player.veins")
		var site: Variant = Sites.find_site("site_fv1")
		assert_eq(site["factionVein"], null, "the faction no longer owns it")
		assert_eq(GameState.state["modal"]["type"], "sale_result", "a net-purchase trade still opens the result modal")

		layer.free()
	)

	run_case("go_button_disables_when_a_buy_would_overdraw_cash", func():
		GameState.reset()
		GameState.state["contacts"]["des"] = { "unlocked": true, "relation": 0 }
		GameState.state["flags"]["veinSaleUnlocked"] = true
		var faction_vein := _seed_faction_vein("fv1", 50)
		var price: int = VeinTrade.quote(faction_vein)
		GameState.state["player"]["cash"] = price - 1
		Modal.open("sell_menu", { "factionId": "collective", "contactId": "des" })

		var layer := ModalLayer.new()
		layer._ready()
		_find_button(layer, "☐").pressed.emit()

		var go_button := _find_button(layer, "Go — trade (includes 1 vein purchase)")
		assert_true(go_button.disabled, "can't afford this purchase")

		layer.free()
	)

	run_case("go_on_the_faction_lane_nets_a_sold_vein_and_a_bought_vein_in_one_trade", func():
		GameState.reset()
		GameState.state["contacts"]["des"] = { "unlocked": true, "relation": 0 }
		GameState.state["flags"]["veinSaleUnlocked"] = true
		var sell_vein := _seed_vein("v1", 50)
		var sell_price: int = VeinTrade.quote(sell_vein)
		var faction_vein := _seed_faction_vein("fv1", 50)
		var buy_price: int = VeinTrade.quote(faction_vein)
		GameState.state["player"]["cash"] = 100000
		var cash_before: int = GameState.state["player"]["cash"]
		# Both toggles set directly rather than via two sequential button
		# presses on the same "☐" glyph -- _card_content's old row buttons
		# are only queue_free()'d (deferred), not removed synchronously, so a
		# second find-by-glyph mid-test can pick up a stale, about-to-be-freed
		# button instead of the freshly rebuilt one. Single-toggle presses
		# (elsewhere in this file) never hit this, since they always re-query
		# by a label that's unique to the post-toggle state.
		Economy.toggle_sell_vein("v1")
		Economy.toggle_buy_vein("fv1")
		Modal.open("sell_menu", { "factionId": "collective", "contactId": "des" })

		var layer := ModalLayer.new()
		layer._ready()

		var go_button := _find_button(layer, "Go — trade (includes 1 vein sale, 1 vein purchase)")
		assert_true(go_button != null, "label calls out both directions")
		go_button.pressed.emit()

		assert_eq(GameState.state["player"]["cash"], cash_before + sell_price - buy_price, "one net trade across both directions")
		assert_eq(GameState.state["player"]["veins"].size(), 1, "sold vein left, bought vein arrived")
		assert_eq(GameState.state["player"]["veins"][0]["id"], faction_vein["id"])

		layer.free()
	)

	# ── collective-ore-stock T02: buy-ore rows in the faction lane's Ore section ──

	run_case("faction_sell_menu_ore_section_shows_a_buy_row_for_every_ore_type_priced_via_get_faction_buy_price", func():
		GameState.reset()
		GameState.state["contacts"]["des"] = { "unlocked": true, "relation": 0 }
		GameState.state["factions"]["collective"]["oreStock"] = { "time": 8, "physics": 8, "life": 8, "fate": 8, "emotion": 8 }
		Modal.open("sell_menu", { "factionId": "collective", "contactId": "des" })

		var layer := ModalLayer.new()
		layer._ready()

		for ore_type in GameData.ORE_TYPES.keys():
			var ore: Dictionary = GameData.ORE_TYPES[ore_type]
			var price := Economy.get_faction_buy_price("collective", "ore", ore_type)
			var expected := "Buy: %s %s (£%d/u, stock 8)" % [ore["symbol"], ore["name"], price]
			assert_true(_label_texts(layer).has(expected), "%s must render a buy row priced via get_faction_buy_price, unchanged" % ore_type)

		layer.free()
	)

	run_case("faction_sell_menus_buy_ore_rows_show_sold_out_with_no_stepper_when_stock_is_zero", func():
		GameState.reset()
		GameState.state["contacts"]["des"] = { "unlocked": true, "relation": 0 }
		GameState.state["factions"]["collective"]["oreStock"] = { "time": 0, "physics": 0, "life": 0, "fate": 0, "emotion": 0 }
		Modal.open("sell_menu", { "factionId": "collective", "contactId": "des" })

		var layer := ModalLayer.new()
		layer._ready()

		var sold_out_count := 0
		for text in _label_texts(layer):
			if text == "Sold out":
				sold_out_count += 1
		assert_eq(sold_out_count, 5, "every one of the 5 ore types is sold out")
		assert_true(_find_button(layer, "+") == null, "a sold-out row has no qty stepper at all")

		layer.free()
	)

	run_case("go_on_the_faction_lane_buys_ore_from_collective_stock_and_debits_the_shared_pool", func():
		GameState.reset()
		GameState.state["contacts"]["des"] = { "unlocked": true, "relation": 0 }
		GameState.state["player"]["cash"] = 100000
		var cash_before: int = GameState.state["player"]["cash"]
		GameState.state["factions"]["collective"]["oreStock"] = { "time": 10, "physics": 10, "life": 10, "fate": 10, "emotion": 10 }
		var price := Economy.get_faction_buy_price("collective", "ore", "time")
		GameState.state["sellState"]["buyOre_time"] = 3
		Modal.open("sell_menu", { "factionId": "collective", "contactId": "des" })

		var layer := ModalLayer.new()
		layer._ready()

		var go_button := _find_button(layer, "Go — trade (includes 3 ore bought)")
		assert_true(go_button != null, "label calls out the ore purchase")
		go_button.pressed.emit()

		assert_eq(GameState.state["player"]["cash"], cash_before - price * 3, "buy price matches get_faction_buy_price, unchanged")
		assert_eq(GameState.state["player"]["orichalchum"]["time"], 3, "bought ore lands in the player's stock")
		assert_eq(GameState.state["factions"]["collective"]["oreStock"]["time"], 7, "the Collective's shared stock is decremented")
		assert_eq(GameState.state["modal"]["type"], "sale_result", "same result modal as any other faction-lane trade")

		layer.free()
	)

	run_case("the_collectives_ore_stock_is_the_same_shared_pool_regardless_of_which_contact_opened_the_modal", func():
		GameState.reset()
		GameState.state["contacts"]["des"] = { "unlocked": true, "relation": 0 }
		GameState.state["contacts"]["hakim"] = { "unlocked": true, "relation": 0 }
		GameState.state["player"]["cash"] = 100000
		GameState.state["factions"]["collective"]["oreStock"] = { "time": 10, "physics": 10, "life": 10, "fate": 10, "emotion": 10 }
		GameState.state["sellState"]["buyOre_time"] = 4
		Modal.open("sell_menu", { "factionId": "collective", "contactId": "des" })

		var des_layer := ModalLayer.new()
		des_layer._ready()
		_find_button(des_layer, "Go — trade (includes 4 ore bought)").pressed.emit()
		des_layer.free()

		Modal.open("sell_menu", { "factionId": "collective", "contactId": "hakim" })
		var hakim_layer := ModalLayer.new()
		hakim_layer._ready()

		var price := Economy.get_faction_buy_price("collective", "ore", "time")
		assert_true(_label_texts(hakim_layer).has("Buy: %s %s (£%d/u, stock 6)" % [GameData.ORE_TYPES["time"]["symbol"], GameData.ORE_TYPES["time"]["name"], price]), "Hakim's door onto the Trade modal reflects Des's purchase against the same shared stock")

		hakim_layer.free()
	)

	run_case("guild_marketplace_qty_ceiling_is_unaffected_by_the_collectives_stock_or_lack_thereof", func():
		GameState.reset()
		GameState.state["factions"]["guild"]["relation"] = 40
		GameState.state["player"]["cash"] = 100000
		GameState.state["factions"]["collective"]["oreStock"] = { "time": 0, "physics": 0, "life": 0, "fate": 0, "emotion": 0 }
		assert_true(Economy.get_faction_buy_max_qty("guild", "ore", "time") > 100, "the Collective being sold out must not leak a stock cap onto the unrelated Guild lane")
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

	# ── bugfixes ticket 105: Craft Components menu replaces hq.gd's old
	# always-inline archetype list -- reached from the Dial card's "Craft
	# Components" button instead of rendering directly on the card.

	run_case("craft_components_menu_lists_every_canonical_archetype_with_its_description_and_a_craft_button", func():
		GameState.reset()
		Modal.open("craft_components_menu")

		var layer := ModalLayer.new()
		layer._ready()

		for archetype in GameData.CANONICAL_MOVEMENT_ARCHETYPES:
			var m: Dictionary = GameData.DIAL_MOVEMENTS[archetype]
			assert_true(_label_texts(layer).has(m["description"]), "%s's effect description must render in the menu" % archetype)
			assert_true(_label_texts(layer).any(func(t: String): return t.begins_with(m["symbol"])), "%s's name/symbol must render in the menu" % archetype)

		layer.free()
	)

	run_case("craft_components_menus_craft_button_opens_the_movement_craft_modal_for_that_archetype", func():
		GameState.reset()
		Modal.open("craft_components_menu")

		var layer := ModalLayer.new()
		layer._ready()

		var craft_buttons := []
		for b in layer.find_children("", "Button", true, false):
			if (b as Button).text == "Craft":
				craft_buttons.append(b)
		assert_eq(craft_buttons.size(), GameData.CANONICAL_MOVEMENT_ARCHETYPES.size(), "one Craft button per archetype")

		craft_buttons[0].pressed.emit()

		assert_eq(GameState.state["modal"]["type"], "movement_craft", "tapping Craft must hand off to the calc-type picker modal")
		assert_eq(GameState.state["modal"]["data"]["archetype"], GameData.CANONICAL_MOVEMENT_ARCHETYPES[0], "the handoff must carry the tapped row's own archetype")

		layer.free()
	)

	run_case("craft_components_menu_close_button_dismisses_the_modal", func():
		GameState.reset()
		Modal.open("craft_components_menu")

		var layer := ModalLayer.new()
		layer._ready()

		_find_button(layer, "Close").pressed.emit()

		assert_eq(GameState.state["modal"], null, "Close must dismiss the menu")

		layer.free()
	)

	# ── bugfixes ticket 104: calc-type craft modal replaces the direct row
	# of 5 ore-symbol buttons on hq.gd's Dial card — cost/chance (identical
	# across all 5 calc types for a given archetype, since Dial.movement_
	# calc_cost/movement_craft_chance take the archetype and skill, not the
	# ore type) move from that card's single label into a per-row label here.

	run_case("movement_craft_modal_shows_the_archetypes_description_and_all_5_calc_types_with_cost_and_chance", func():
		GameState.reset()
		GameState.state["player"]["craftingSkill"] = 1
		Modal.open("movement_craft", { "archetype": "impact" })

		var layer := ModalLayer.new()
		layer._ready()

		var m: Dictionary = GameData.DIAL_MOVEMENTS["impact"]
		assert_true(_label_texts(layer).has(m["description"]), "the archetype's effect description renders in the modal")

		var cost: int = Dial.movement_calc_cost("impact", 1)
		var chance_pct: int = int(round(Dial.movement_craft_chance("impact", 1) * 100))
		for ore_type in GameData.ORE_TYPES.keys():
			var ore: Dictionary = GameData.ORE_TYPES[ore_type]
			var expected := "%s %s — %d calc, chance %d%%" % [ore["symbol"], ore["name"], cost, chance_pct]
			assert_true(_find_button(layer, expected) != null, "%s row must show its cost and chance" % ore_type)

		layer.free()
	)

	run_case("selecting_a_calc_type_in_the_movement_craft_modal_performs_the_same_craft_attempt_the_old_direct_button_did", func():
		GameState.reset()
		GameState.state["player"]["craftingSkill"] = 1
		GameState.state["player"]["orichalchum"]["time"] = 999
		Modal.open("movement_craft", { "archetype": "impact" })

		var layer := ModalLayer.new()
		layer._ready()

		var cost: int = Dial.movement_calc_cost("impact", 1)
		var chance_pct: int = int(round(Dial.movement_craft_chance("impact", 1) * 100))
		var ore: Dictionary = GameData.ORE_TYPES["time"]
		var button := _find_button(layer, "%s %s — %d calc, chance %d%%" % [ore["symbol"], ore["name"], cost, chance_pct])
		assert_true(button != null, "time row must be present")
		button.pressed.emit()

		assert_eq(GameState.state["player"]["orichalchum"]["time"], 999 - cost, "calc is spent on the attempt regardless of outcome, same as Dial.attempt_craft_movement always did")
		assert_eq(GameState.state["modal"], null, "the modal closes once the attempt resolves")

		layer.free()
	)

	run_case("a_successful_movement_craft_via_the_modal_lands_the_movement_in_inventory_same_as_the_old_direct_button_flow", func():
		var seed := -1
		for candidate in range(200):
			GameState.reset()
			GameState.state["player"]["craftingSkill"] = 5
			GameState.state["player"]["orichalchum"]["physics"] = 1000
			Modal.open("movement_craft", { "archetype": "capacitor" })

			var layer := ModalLayer.new()
			layer._ready()
			var cost: int = Dial.movement_calc_cost("capacitor", 5)
			var chance_pct: int = int(round(Dial.movement_craft_chance("capacitor", 5) * 100))
			var ore: Dictionary = GameData.ORE_TYPES["physics"]
			var button := _find_button(layer, "%s %s — %d calc, chance %d%%" % [ore["symbol"], ore["name"], cost, chance_pct])
			Rng.set_seed(candidate)
			button.pressed.emit()
			layer.free()

			var inventory: Array = GameState.state["player"]["movementInventory"]
			if inventory.size() == 1:
				seed = candidate
				break
		assert_true(seed != -1, "should find a successful Movement craft within 200 tries")

		var inventory: Array = GameState.state["player"]["movementInventory"]
		assert_eq(inventory[0]["archetype"], "capacitor", "archetype matches what was picked in the modal")
		assert_eq(inventory[0]["oreType"], "physics", "the calc type picked in the modal becomes the Movement's attunement")
		assert_eq(inventory[0]["tier"], 5, "tier is set from crafting skill at craft time, unchanged from the old direct-button flow")

		var notifications: Array = GameState.state["notifications"]
		var last: Dictionary = notifications[notifications.size() - 1]
		var m: Dictionary = GameData.DIAL_MOVEMENTS["capacitor"]
		assert_eq(last["text"], "Movement crafted: %s (tier %d)." % [m["name"], 5], "same success notification text the old direct-button flow pushed")
		assert_eq(last["category"], Notify.CATEGORY_SUCCESS, "same success category the old direct-button flow pushed")
	)

	run_case("a_failed_movement_craft_via_the_modal_gives_the_same_failure_feedback_the_old_direct_button_flow_did", func():
		var seed := -1
		for candidate in range(200):
			GameState.reset()
			GameState.state["player"]["craftingSkill"] = 1
			GameState.state["player"]["orichalchum"]["time"] = 1000
			Modal.open("movement_craft", { "archetype": "impact" })

			var layer := ModalLayer.new()
			layer._ready()
			var cost: int = Dial.movement_calc_cost("impact", 1)
			var chance_pct: int = int(round(Dial.movement_craft_chance("impact", 1) * 100))
			var ore: Dictionary = GameData.ORE_TYPES["time"]
			var button := _find_button(layer, "%s %s — %d calc, chance %d%%" % [ore["symbol"], ore["name"], cost, chance_pct])
			Rng.set_seed(candidate)
			button.pressed.emit()
			layer.free()

			if GameState.state["player"]["movementInventory"].is_empty():
				seed = candidate
				break
		assert_true(seed != -1, "should find a failed Movement craft within 200 tries")

		assert_eq(GameState.state["player"]["movementInventory"], [], "a failed craft leaves no partial Movement in inventory, unchanged from the old direct-button flow")

		var notifications: Array = GameState.state["notifications"]
		var last: Dictionary = notifications[notifications.size() - 1]
		assert_eq(last["text"], "Movement-crafting failed — calc spent, no Movement gained.", "same failure notification text the old direct-button flow pushed")
		assert_eq(last["category"], Notify.CATEGORY_DANGER, "same failure category the old direct-button flow pushed")
	)

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


# Ticket 114: symbol_row()/symbol_button() split what used to be one Label's
# raw-symbol string into a Label per text part plus a SymbolGlyph glyph (see
# ui.gd's own comment on symbol_row()) -- reconstructs the row's displayed
# text by walking a symbol_row/symbol_button's direct children in order,
# substituting SymbolGlyph.symbol for the glyph's drawn text, with no
# separator added (call sites already author any needed space into their
# text parts, e.g. modal_layer.gd's " %s (£%d)" -- the hbox's own pixel gap
# covers the rest visually).
static func _effective_text(control: Control) -> String:
	var out := ""
	for child in control.get_children():
		if child is SymbolGlyph:
			out += (child as SymbolGlyph).symbol
		elif child is Label:
			out += (child as Label).text
	return out


static func _label_texts(root: Node) -> Array[String]:
	var texts: Array[String] = []
	for l in root.find_children("", "Label", true, false):
		texts.append((l as Label).text)
	for g in root.find_children("", "SymbolGlyph", true, false):
		var parent := (g as SymbolGlyph).get_parent() as Control
		if parent:
			texts.append(_effective_text(parent))
	return texts


static func _find_button(root: Node, text: String) -> Button:
	for b in root.find_children("", "Button", true, false):
		var btn := b as Button
		if btn.text == text or btn.text == UI.format_block_cost_label(text):
			return btn
		if btn.get_child_count() > 0 and _effective_text(btn.get_child(0) as Control) == text:
			return btn
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
	run_case("evening_train_label_predicts_one_automatic_rollover", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 500
		TimeSystem.advance_time_block()
		TimeSystem.advance_time_block()
		Modal.open("hq_gym")
		var layer := ModalLayer.new()
		layer._ready()
		var button := _find_button(layer, "Train — last block today")
		assert_true(button != null)
		button.pressed.emit()
		assert_eq(GameState.state["world"]["day"], 2)
		assert_eq(GameState.state["world"]["timeBlock"], 0)
		assert_eq(GameState.state["player"]["combatXP"], Combat.COMBAT_XP_PER_WORKOUT_SESSION)
		assert_eq(GameState.state["player"]["cash"], 450)
		layer.free()
	)

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
		GameState.state["contacts"]["des"] = { "unlocked": true, "relation": 0, "tradeProgress": 0 }
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
		GameState.state["contacts"]["des"] = { "unlocked": true, "relation": 0, "tradeProgress": 0 }
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
		GameState.state["contacts"]["des"] = { "unlocked": true, "relation": 0, "tradeProgress": 0 }
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
				if text.begins_with("%s%s (" % [recipe["symbol"], recipe["name"]]):
					found = true
					break
			assert_true(found, "%s must render as a sell row" % recipe_key)

		layer.free()
	)

	# ── vein-trade-assets ticket 01: Ore/Items/Assets sections ─────────────

	run_case("both_sell_menu_lanes_render_ore_items_and_assets_section_headers_when_unlocked", func():
		GameState.reset()
		GameState.state["contacts"]["des"] = { "unlocked": true, "relation": 0, "tradeProgress": 0 }
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
		GameState.state["contacts"]["des"] = { "unlocked": true, "relation": 0, "tradeProgress": 0 }
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
		GameState.state["contacts"]["des"] = { "unlocked": true, "relation": 0, "tradeProgress": 0 }
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
		GameState.state["contacts"]["des"] = { "unlocked": true, "relation": 0, "tradeProgress": 0 }
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
		GameState.state["contacts"]["des"] = { "unlocked": true, "relation": 0, "tradeProgress": 0 }
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
		GameState.state["contacts"]["des"] = { "unlocked": true, "relation": 0, "tradeProgress": 0 }
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
		GameState.state["contacts"]["des"] = { "unlocked": true, "relation": 0, "tradeProgress": 0 }
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
		GameState.state["contacts"]["des"] = { "unlocked": true, "relation": 0, "tradeProgress": 0 }
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
		GameState.state["contacts"]["des"] = { "unlocked": true, "relation": 0, "tradeProgress": 0 }
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
		GameState.state["contacts"]["des"] = { "unlocked": true, "relation": 0, "tradeProgress": 0 }
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
		GameState.state["contacts"]["des"] = { "unlocked": true, "relation": 0, "tradeProgress": 0 }
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
		GameState.state["contacts"]["des"] = { "unlocked": true, "relation": 0, "tradeProgress": 0 }
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
		GameState.state["contacts"]["des"] = { "unlocked": true, "relation": 0, "tradeProgress": 0 }
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
		GameState.state["contacts"]["des"] = { "unlocked": true, "relation": 0, "tradeProgress": 0 }
		GameState.state["contacts"]["hakim"] = { "unlocked": true, "relation": 0, "tradeProgress": 0 }
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

	# ── hq-diorama ticket 16: hq_dial.gd's "Swap" button opens this in place
	# of the old always-rendered per-inventory-item "Seat" card list -- same
	# Dial.seat_movement(index) call the deleted cards used, unchanged, just
	# gathered behind one button tap.

	run_case("movement_swap_lists_movement_inventory_and_seats_the_chosen_entry_via_dial_system", func():
		GameState.reset()
		var player: Dictionary = GameState.state["player"]
		player["dial"] = Dial.new_dial(GameData.DIAL_HAFTS.keys()[0])
		player["movementInventory"] = [{ "archetype": "recharge", "oreType": "time", "tier": 1 }]

		Modal.open("movement_swap")
		var layer := ModalLayer.new()
		layer._ready()

		_find_button(layer, "↻Recharge Movement — attuned time, tier 1").pressed.emit()

		assert_eq(GameState.state["player"]["dial"]["movement"]["archetype"], "recharge", "movement_swap's row should seat via Dial.seat_movement")
		assert_eq(GameState.state["player"]["movementInventory"], [], "the seated Movement should leave movementInventory")
		assert_eq(GameState.state["modal"], null, "seating from the picker should close the modal")

		layer.free()
	)

	run_case("movement_swap_cancel_button_dismisses_the_modal_without_seating_anything", func():
		GameState.reset()
		var player: Dictionary = GameState.state["player"]
		player["dial"] = Dial.new_dial(GameData.DIAL_HAFTS.keys()[0])
		player["movementInventory"] = [{ "archetype": "recharge", "oreType": "time", "tier": 1 }]

		Modal.open("movement_swap")
		var layer := ModalLayer.new()
		layer._ready()

		_find_button(layer, "Cancel").pressed.emit()

		assert_eq(GameState.state["modal"], null, "Cancel must dismiss the picker")
		assert_eq(GameState.state["player"]["dial"]["movement"], null, "Cancel must not seat anything")

		layer.free()
	)

	# ── hq-diorama ticket 17: hq_dial.gd's flanking sockets tap an Empty
	# housing to open this in place of the old always-rendered bottom tray
	# (deleted this ticket) -- same tier-bucketed inventory scan and
	# Dial.load_complication() call the tray used, gathered behind one tap.

	run_case("dial_load_complication_lists_loadable_complications_and_loads_via_dial_system", func():
		GameState.reset()
		var player: Dictionary = GameState.state["player"]
		player["dial"] = Dial.new_dial(GameData.DIAL_HAFTS.keys()[0])
		player["inventory"]["timePearl"] = { "1": 1 }

		Modal.open("dial_load_complication")
		var layer := ModalLayer.new()
		layer._ready()

		_find_button(layer, "⧖Time Pearl tier 1 (1)").pressed.emit()

		var loaded: Array = GameState.state["player"]["dial"]["loadedComplications"]
		assert_eq(loaded.size(), 1, "picking a row should load via Dial.load_complication")
		assert_eq(Crafting.inventory_qty("timePearl"), 0, "loading should move the unit out of regular inventory")
		assert_eq(GameState.state["modal"], null, "loading from the picker should close the modal")

		layer.free()
	)

	run_case("dial_load_complication_shows_nothing_in_stock_message_when_empty", func():
		GameState.reset()
		var player: Dictionary = GameState.state["player"]
		player["dial"] = Dial.new_dial(GameData.DIAL_HAFTS.keys()[0])

		Modal.open("dial_load_complication")
		var layer := ModalLayer.new()
		layer._ready()

		assert_true(_label_texts(layer).has("Nothing in stock to load."), "must show the empty-stock message when nothing is loadable")

		layer.free()
	)

	run_case("dial_load_complication_cancel_button_dismisses_the_modal_without_loading_anything", func():
		GameState.reset()
		var player: Dictionary = GameState.state["player"]
		player["dial"] = Dial.new_dial(GameData.DIAL_HAFTS.keys()[0])
		player["inventory"]["timePearl"] = { "1": 1 }

		Modal.open("dial_load_complication")
		var layer := ModalLayer.new()
		layer._ready()

		_find_button(layer, "Cancel").pressed.emit()

		assert_eq(GameState.state["modal"], null, "Cancel must dismiss the picker")
		assert_eq(GameState.state["player"]["dial"]["loadedComplications"], [], "Cancel must not load anything")

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
			var expected := "%s%s — %d calc, chance %d%%" % [ore["symbol"], ore["name"], cost, chance_pct]
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
		var button := _find_button(layer, "%s%s — %d calc, chance %d%%" % [ore["symbol"], ore["name"], cost, chance_pct])
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
			var button := _find_button(layer, "%s%s — %d calc, chance %d%%" % [ore["symbol"], ore["name"], cost, chance_pct])
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
			var button := _find_button(layer, "%s%s — %d calc, chance %d%%" % [ore["symbol"], ore["name"], cost, chance_pct])
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

	# ── hq-diorama ticket 02: HQ zone destination modals ───────────────────
	# hq.gd's old always-inline Security/Rooms/Ore-store cards, moved here
	# unchanged -- these tests mirror the assertions the old
	# tests/test_hq_screen.gd made against those cards directly.

	# hq-diorama ticket 09: the old "hq_dial" modal cases used to live here --
	# moved (not deleted) to tests/test_hq_dial.gd, since the Dial is now the
	# full-bleed hq_dial.gd screen, not a modal (same move ticket 05 made for
	# "hq_security_list" -> tests/test_hq_door.gd, below).

	# hq-diorama ticket 05: the old "hq_security_list" modal cases used to
	# live here -- moved (not deleted) to tests/test_hq_door.gd, since
	# Security/the door is now the full-bleed hq_door.gd screen, not a modal
	# (same move ticket 04 made for "hq_rooms_list" -> tests/
	# test_hq_floorplan.gd).

	run_case("hq_ore_readout_modal_shows_stored_ore_quantities_and_a_raid_risk_note", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["life"] = 12
		Modal.open("hq_ore_readout")

		var layer := ModalLayer.new()
		layer._ready()

		var life_ore: Dictionary = GameData.ORE_TYPES["life"]
		assert_true(_label_texts(layer).any(func(t: String): return t.ends_with("%s — 12" % life_ore["name"])), "must show the stored ore's own name and quantity")

		var raid_pct: int = int(round(Home.get_home_raid_chance() * 100))
		assert_true(_label_texts(layer).has("Raid risk: %d%%" % raid_pct), "must show the raid-risk note alongside stored contents, per §12.4's recommended default")

		layer.free()
	)

	run_case("hq_ore_readout_modal_shows_none_in_stock_when_no_ore_is_held", func():
		GameState.reset()
		Modal.open("hq_ore_readout")

		var layer := ModalLayer.new()
		layer._ready()

		assert_true(_label_texts(layer).has("None in stock."), "must show the empty-stock message when nothing is held")

		layer.free()
	)

	run_case("hq_ore_readout_modal_close_button_dismisses_the_modal", func():
		GameState.reset()
		Modal.open("hq_ore_readout")

		var layer := ModalLayer.new()
		layer._ready()

		_find_button(layer, "Close").pressed.emit()
		assert_eq(GameState.state["modal"], null, "Close must dismiss the readout")

		layer.free()
	)

	# field-kit-chrome ticket 07, ui-vision.md §5's component table ("Ore-store
	# readout: a handwritten inventory slip... The raid-warning line rides the
	# same slip rather than a separate element"): the ore totals and the raid
	# line must both trace back to the same wrapping container, and that
	# container must itself be a single panel nested one level inside the
	# modal's own generic card -- not bare siblings of Close the way the old
	# plain-card readout rendered them.
	run_case("hq_ore_readout_modal_renders_ore_totals_and_raid_warning_on_one_shared_slip_panel", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["life"] = 12
		Modal.open("hq_ore_readout")

		var layer := ModalLayer.new()
		layer._ready()

		var heading: Label = null
		for l in layer.find_children("", "Label", true, false):
			if (l as Label).text == "Ore store":
				heading = l
				break
		assert_true(heading != null, "slip must carry its own 'Ore store' heading")

		var raid_pct: int = int(round(Home.get_home_raid_chance() * 100))
		var raid_label: Label = null
		for l in layer.find_children("", "Label", true, false):
			if (l as Label).text == "Raid risk: %d%%" % raid_pct:
				raid_label = l
				break
		assert_true(raid_label != null, "raid-risk line must still render")

		# heading -> slip_content; raid_label -> _SlipStamp -> slip_content
		var slip_from_heading: Node = heading.get_parent()
		var slip_from_raid: Node = raid_label.get_parent().get_parent()
		assert_eq(slip_from_heading, slip_from_raid, "raid-warning line must ride the same slip object as the ore totals, not a separate card/section")
		assert_true(slip_from_heading.get_parent() is PanelContainer, "the slip's heading and raid line sit inside one wrapping panel object")

		layer.free()
	)

	# ui-vision.md §5: "e.g. a stamped/red-ink annotation using ui_action_red" --
	# same GameData.PALETTE lookup + fallback pattern ticket 05/06's action-card
	# tests assert against.
	run_case("hq_ore_readout_modal_raid_warning_stamp_uses_ui_action_red", func():
		GameState.reset()
		Modal.open("hq_ore_readout")

		var layer := ModalLayer.new()
		layer._ready()

		var raid_pct: int = int(round(Home.get_home_raid_chance() * 100))
		var raid_label: Label = null
		for l in layer.find_children("", "Label", true, false):
			if (l as Label).text == "Raid risk: %d%%" % raid_pct:
				raid_label = l
				break
		assert_true(raid_label != null, "raid-risk line must still render")

		var expected: Color = GameData.PALETTE.get("ui_action_red", ModalLayer._ACTION_COLOR_FALLBACK)
		assert_eq(raid_label.get_theme_color("font_color"), expected, "raid-warning renders as a red-ink annotation in ui_action_red")

		layer.free()
	)

	# ── squad-combat ticket 05 / hq-diorama ticket 02: Gym modal / Train ───

	run_case("hq_gym_modal_offers_a_train_button_and_a_build_hint_without_a_built_home_gym", func():
		GameState.reset()
		Modal.open("hq_gym")

		var layer := ModalLayer.new()
		layer._ready()

		assert_true(_find_button(layer, "Train") != null, "Train must be available even before Home Gym is built")
		assert_true(_label_texts(layer).has("Build a Home Gym to get more out of each workout."), "must show the upgrade hint alongside Train")

		layer.free()
	)

	run_case("hq_gym_modal_train_button_awards_the_lower_workout_xp_without_a_built_home_gym", func():
		GameState.reset()
		Modal.open("hq_gym")

		var layer := ModalLayer.new()
		layer._ready()

		_find_button(layer, "Train").pressed.emit()

		assert_eq(GameState.state["player"]["combatXP"], Combat.COMBAT_XP_PER_WORKOUT_SESSION, "pressing Train without a Home Gym should award the lower workout XP")
		assert_eq(GameState.state["world"]["timeBlocksDone"].size(), 1, "pressing Train should spend one of the day's time blocks")

		layer.free()
	)

	run_case("hq_gym_modal_train_button_spends_a_block_and_awards_combat_xp", func():
		GameState.reset()
		GameState.state["home"]["rooms"].append("homeGym")
		Modal.open("hq_gym")

		var layer := ModalLayer.new()
		layer._ready()

		var train_button := _find_button(layer, "Train")
		assert_true(train_button != null, "a built Home Gym must expose a Train button")

		train_button.pressed.emit()

		assert_eq(GameState.state["player"]["combatXP"], Combat.COMBAT_XP_PER_GYM_SESSION, "pressing Train should award the gym-session XP")
		assert_eq(GameState.state["world"]["timeBlocksDone"].size(), 1, "pressing Train should spend one of the day's time blocks")

		layer.free()
	)

	run_case("hq_gym_modal_train_button_is_disabled_once_the_days_time_blocks_are_exhausted", func():
		GameState.reset()
		GameState.state["home"]["rooms"].append("homeGym")
		GameState.state["world"]["timeBlocksDone"] = [0, 1, 2]
		Modal.open("hq_gym")

		var layer := ModalLayer.new()
		layer._ready()

		var train_button := _find_button(layer, "Train")
		assert_true(train_button != null, "the button should still be present, just disabled")
		assert_true(train_button.disabled, "Train should be disabled once the day's time blocks are exhausted")

		layer.free()
	)

	run_case("hq_gym_modal_close_button_dismisses_the_modal", func():
		GameState.reset()
		Modal.open("hq_gym")

		var layer := ModalLayer.new()
		layer._ready()

		_find_button(layer, "Close").pressed.emit()
		assert_eq(GameState.state["modal"], null, "Close must dismiss the gym modal")

		layer.free()
	)

	# field-kit-chrome ticket 06, ui-vision.md §5's component table: Train
	# drops the default theme Button's amber fill (reserved for calc/cash
	# reads only, §6) in favour of the locked `ui_action_red` accent, same
	# GameData.PALETTE lookup + hardcoded-hex-fallback pattern ticket 05's
	# combat action-card test asserts against.
	run_case("hq_gym_train_button_uses_ui_action_red_not_the_default_theme_amber", func():
		GameState.reset()
		Modal.open("hq_gym")

		var layer := ModalLayer.new()
		layer._ready()

		var expected: Color = GameData.PALETTE.get("ui_action_red", ModalLayer._ACTION_COLOR_FALLBACK)
		var train_button := _find_button(layer, "Train")
		assert_true(train_button != null)
		assert_eq(train_button.get_theme_color("font_color"), expected, "Train button uses ui_action_red")

		layer.free()
	)

	# A disabled Train (day's time blocks exhausted, same gate as above)
	# reads muted grey instead -- the project's existing "this is disabled"
	# tint, not ui_action_red, which is reserved for an actually-available
	# action.
	run_case("hq_gym_disabled_train_button_reads_muted_grey_not_ui_action_red", func():
		GameState.reset()
		GameState.state["world"]["timeBlocksDone"] = [0, 1, 2]
		Modal.open("hq_gym")

		var layer := ModalLayer.new()
		layer._ready()

		var train_button := _find_button(layer, "Train")
		assert_true(train_button != null)
		assert_true(train_button.disabled)
		assert_eq(train_button.get_theme_color("font_color"), ModalLayer._ACTION_DISABLED_COLOR, "disabled Train button stays muted grey")

		layer.free()
	)

	# ── hq-diorama ticket 07: Lab bench modals ─────────────────────────────

	run_case("lab_bench_recipe_book_lists_found_recipes_with_a_craft_button", func():
		GameState.reset()
		Modal.open("lab_bench_recipe_book")

		var layer := ModalLayer.new()
		layer._ready()

		assert_true(_label_texts(layer).has("Time Pearl"), "tutorial-taught recipes are already Found on a fresh save")
		assert_true(_find_button(layer, "Craft ×1") != null, "each row's batch stepper defaults to qty 1")

		layer.free()
	)

	run_case("lab_bench_recipe_book_shows_nothing_found_yet_when_the_found_list_is_empty", func():
		GameState.reset()
		# Override the 3 tutorial-taught cells (otherwise Found by default with
		# no stored cells entry, per Bench._default_cell()) back to untried.
		var cells: Dictionary = GameState.state["player"]["bench"]["cells"]
		cells["time|compression"] = { "state": "untried", "misses": 0, "refine": 0 }
		cells["life|grinding"] = { "state": "untried", "misses": 0, "refine": 0 }
		cells["time|heat"] = { "state": "untried", "misses": 0, "refine": 0 }
		Modal.open("lab_bench_recipe_book")

		var layer := ModalLayer.new()
		layer._ready()

		assert_true(_label_texts(layer).has("Nothing found yet."), "same empty-state line lab.gd's home used to show")

		layer.free()
	)

	run_case("lab_bench_recipe_book_craft_button_runs_the_normal_batch_craft_path", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["time"] = 20
		Modal.open("lab_bench_recipe_book")

		var layer := ModalLayer.new()
		layer._ready()
		_find_button(layer, "Craft ×1").pressed.emit()

		assert_eq(GameState.state["modal"]["type"], "craft_batch_result", "crafting from the book opens the normal batch-result modal on top, same as lab.gd's old crafting section")

		layer.free()
	)

	run_case("lab_bench_recipe_book_refine_button_is_disabled_when_not_enough_calc", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["time"] = 0
		Modal.open("lab_bench_recipe_book")

		var layer := ModalLayer.new()
		layer._ready()

		var refine_button := _find_button(layer, "Refine to tier 1")
		assert_true(refine_button != null, "§5.6: every Found recipe exposes Refine as a book-page action")
		assert_true(refine_button.disabled, "not enough calc -- Bench.refine_block_reason() blocks it")

		layer.free()
	)

	run_case("lab_bench_notes_modal_shows_nothing_recorded_yet_when_the_bench_is_untouched", func():
		GameState.reset()
		Modal.open("lab_bench_notes")

		var layer := ModalLayer.new()
		layer._ready()

		assert_true(_label_texts(layer).has("Nothing recorded yet."))

		layer.free()
	)

	run_case("lab_bench_notes_modal_lists_a_touched_pairing_never_the_full_15_type_sets", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["life"] = 3
		Bench.probe(["life"], "heat")
		Modal.open("lab_bench_notes")

		var layer := ModalLayer.new()
		layer._ready()

		assert_true(_label_texts(layer).has("Life"), "the touched pairing's own heading renders")
		assert_true(not _label_texts(layer).has("Nothing recorded yet."))

		layer.free()
	)

	run_case("lab_bench_notes_modal_shows_a_found_recipes_current_refine_tier", func():
		GameState.reset()
		GameState.state["player"]["bench"]["cells"]["life|heat"] = { "state": "found", "misses": 0, "refine": 2 }
		Modal.open("lab_bench_notes")

		var layer := ModalLayer.new()
		layer._ready()

		assert_true(_label_texts(layer).has("Healing Salve — tier 2"), "§5.2 point 2: the notebook shows current recipe levels, not just that something was found")

		layer.free()
	)

	# ── ticket 102: one-tap refine from the Experiments notebook ───────────

	run_case("lab_bench_notes_modal_found_recipe_row_shows_a_refine_button", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["life"] = 100
		GameState.state["player"]["bench"]["cells"]["life|heat"] = { "state": "found", "misses": 0, "refine": 2 }
		Modal.open("lab_bench_notes")

		var layer := ModalLayer.new()
		layer._ready()

		var refine_button := _find_button(layer, "Refine to tier 3")
		assert_true(refine_button != null, "a Found recipe's notebook row exposes the same next-tier action the recipe book does")
		assert_true(not refine_button.disabled, "enough calc and a known technique -- nothing should block this tap")

		layer.free()
	)

	run_case("lab_bench_notes_modal_refine_button_runs_the_experiment_immediately_with_no_picker", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["life"] = 100
		GameState.state["player"]["bench"]["cells"]["life|heat"] = { "state": "found", "misses": 0, "refine": 2 }
		Modal.open("lab_bench_notes")

		var layer := ModalLayer.new()
		layer._ready()
		_find_button(layer, "Refine to tier 3").pressed.emit()

		assert_eq(GameState.state["player"]["orichalchum"]["life"], 88, "the tap spends the recipe's own established ore combo (3 * (3+1) = 12) at once -- no intermediate ore/apparatus picker")
		assert_eq(GameState.state["modal"]["type"], "lab_bench_notes", "the experiment resolves in place -- no picker or result modal opens over the notebook")

		layer.free()
	)

	run_case("lab_bench_notes_modal_refine_button_is_disabled_when_not_enough_calc", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["life"] = 0
		GameState.state["player"]["bench"]["cells"]["life|heat"] = { "state": "found", "misses": 0, "refine": 2 }
		Modal.open("lab_bench_notes")

		var layer := ModalLayer.new()
		layer._ready()

		var refine_button := _find_button(layer, "Refine to tier 3")
		assert_true(refine_button != null)
		assert_true(refine_button.disabled, "not enough calc -- Bench.refine_block_reason() blocks it, same reason the recipe book's button respects")
		assert_true(_label_texts(layer).has("Not enough calc."), "a disabled refine button always states why -- never a dead tap with no reason")

		layer.free()
	)

	run_case("lab_bench_notes_modal_refine_button_is_disabled_when_the_technique_is_unknown", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["physics"] = 100
		# compression's source is the "workshop" room (data/approaches.json), not
		# built on a fresh save -- a second, distinct block-reason branch from
		# the ore-cost one above. "physics" (blackHole, approach compression)
		# rather than "time"/"life" avoids colliding with the tutorial-taught
		# timePearl/rewind/enhancementPowder cells, which default to Found at
		# already-known approaches and would confuse a same-text button lookup.
		GameState.state["player"]["bench"]["cells"]["physics|compression"] = { "state": "found", "misses": 0, "refine": 0 }
		Modal.open("lab_bench_notes")

		var layer := ModalLayer.new()
		layer._ready()

		var refine_button := _find_button(layer, "Refine to tier 1")
		assert_true(refine_button != null)
		assert_true(refine_button.disabled, "compression isn't known yet -- Bench.refine_block_reason() blocks it")
		assert_true(_label_texts(layer).has("You haven't the technique for that yet."))

		layer.free()
	)

	run_case("lab_bench_probe_result_modal_found_names_the_recipe", func():
		GameState.reset()
		Modal.open("lab_bench_probe_result", { "outcome": "found", "recipeKey": "healingSalve" })

		var layer := ModalLayer.new()
		layer._ready()

		assert_true(_label_texts(layer).has("Found it."))
		assert_true(_find_button(layer, "Got it") != null)

		layer.free()
	)

	run_case("lab_bench_probe_result_modal_hot_reads_as_a_lure", func():
		GameState.reset()
		Modal.open("lab_bench_probe_result", { "outcome": "hot" })

		var layer := ModalLayer.new()
		layer._ready()

		assert_true(_label_texts(layer).has("Something's there."))

		layer.free()
	)

	run_case("lab_bench_probe_result_modal_inert_lands_flat", func():
		GameState.reset()
		Modal.open("lab_bench_probe_result", { "outcome": "inert" })

		var layer := ModalLayer.new()
		layer._ready()

		assert_true(_label_texts(layer).has("Inert."))

		layer.free()
	)

	run_case("lab_bench_probe_result_got_it_button_closes_the_modal", func():
		GameState.reset()
		Modal.open("lab_bench_probe_result", { "outcome": "inert" })

		var layer := ModalLayer.new()
		layer._ready()
		_find_button(layer, "Got it").pressed.emit()

		assert_eq(GameState.state["modal"], null)

		layer.free()
	)

class_name SellMenuModal
extends RefCounted


static func build(container: VBoxContainer, data: Dictionary) -> void:
	var faction_id: String = data.get("factionId", "")
	if faction_id != "":
		_build_faction(container, faction_id, data.get("contactId", ""))
		return
	_build_archie(container)


static func cancel() -> void:
	Economy.clear_sell_state()
	Modal.close()


static func _build_archie(container: VBoxContainer) -> void:
	var player: Dictionary = GameState.state["player"]
	var sell_state: Dictionary = GameState.state["sellState"]

	container.add_child(UI.heading("Find a buyer"))
	container.add_child(UI.muted_label("Archie splits 50/50. Select what you want to move."))

	var gross := 0
	var ore_rows: Array = []
	var item_rows: Array = []

	for ore_type in GameData.ORE_TYPES.keys():
		var have: int = player["orichalchum"].get(ore_type, 0)
		if have <= 0:
			continue
		var ore: Dictionary = GameData.ORE_TYPES[ore_type]
		var key := "ore_%s" % ore_type
		var qty: int = sell_state.get(key, 0)
		gross += ore["basePrice"] * qty
		ore_rows.append(SellRowBuilders.sell_row([{ "symbol": ore["symbol"], "fallback": SymbolGlyph.ore_fallback(ore_type) }, "%s (£%d/u, have %d)" % [ore["name"], ore["basePrice"], have]], key, qty, have))

	if GameState.state["flags"]["canSellConsumables"]:
		for recipe_key in GameData.CONSUMABLE_PRICES.keys():
			var buckets: Dictionary = player["inventory"].get(recipe_key, {})
			var recipe: Dictionary = GameData.RECIPES[recipe_key]
			var base_price: int = GameData.CONSUMABLE_PRICES[recipe_key]
			var tier_keys: Array = buckets.keys()
			tier_keys.sort_custom(func(a, b): return int(a) < int(b))
			for tier_key in tier_keys:
				var have: int = buckets[tier_key]
				if have <= 0:
					continue
				var tier: int = int(tier_key)
				var price: int = GameState.round_epsilon(base_price * Economy.quality_price_multiplier(tier))
				var key := "con_%s_%s" % [recipe_key, tier_key]
				var qty: int = sell_state.get(key, 0)
				gross += price * qty
				var tier_label := "untiered" if tier <= 0 else "tier %d" % tier
				item_rows.append(SellRowBuilders.sell_row([{ "symbol": recipe["symbol"], "fallback": SymbolGlyph.generic_fallback() }, "%s (%s, £%d/ea, have %d)" % [recipe["name"], tier_label, price, have]], key, qty, have))

	var asset_rows: Array = []
	var veins_selected := 0
	if GameState.state["flags"].get("veinSaleUnlocked", false):
		for vein in player["veins"]:
			var vein_key := "vein_%s" % vein["id"]
			var selected: bool = sell_state.get(vein_key, 0) > 0
			var vein_price := Economy.get_archie_vein_price(vein)
			if selected:
				gross += vein_price
				veins_selected += 1
			var vein_ore: Dictionary = GameData.ORE_TYPES[vein["oreType"]]
			var vein_district: Dictionary = GameData.DISTRICTS[vein["district"]]
			var vein_parts := ["%s — " % vein_district["name"], { "symbol": vein_ore["symbol"], "fallback": SymbolGlyph.ore_fallback(vein["oreType"]) }, " %s (£%d)" % [vein_ore["name"], vein_price]]
			asset_rows.append(SellRowBuilders.sell_vein_row(vein_parts, vein["id"], selected))

	SellRowBuilders.sell_sections(container, ore_rows, item_rows, asset_rows)

	var cut_ratio := Economy.get_archie_cut_ratio()
	var player_cut: int = int(floor(gross * cut_ratio))
	container.add_child(UI.label("Your cut (%d%%): £%d" % [int(round(cut_ratio * 100)), player_cut]))
	var mug_pct: float = Economy.MUG_BASE_CHANCE_VEIN if veins_selected > 0 else Economy.MUG_BASE_CHANCE
	container.add_child(UI.muted_label("%d%% chance of mugging" % int(round(mug_pct * 100))))

	var go_button := UI.button("Go — find a buyer", func(): Economy.sell_from_sell_state())
	go_button.disabled = player_cut == 0
	container.add_child(go_button)
	container.add_child(UI.button("Cancel", func(): cancel()))


static func _build_faction(container: VBoxContainer, faction_id: String, contact_id: String) -> void:
	var player: Dictionary = GameState.state["player"]
	var sell_state: Dictionary = GameState.state["sellState"]
	var faction_name: String = GameData.FACTIONS[faction_id]["name"]

	container.add_child(UI.heading("Trade with %s" % faction_name))
	container.add_child(UI.muted_label("Straight sale. No cut, no risk of a mugging."))

	var gross := 0
	var ore_rows: Array = []
	var item_rows: Array = []

	for ore_type in GameData.ORE_TYPES.keys():
		var have: int = player["orichalchum"].get(ore_type, 0)
		if have <= 0:
			continue
		var ore: Dictionary = GameData.ORE_TYPES[ore_type]
		var key := "ore_%s" % ore_type
		var qty: int = sell_state.get(key, 0)
		var price := Economy.get_faction_sell_price(faction_id, "ore", ore_type)
		gross += price * qty
		ore_rows.append(SellRowBuilders.sell_row([{ "symbol": ore["symbol"], "fallback": SymbolGlyph.ore_fallback(ore_type) }, "%s (£%d/u, have %d)" % [ore["name"], price, have]], key, qty, have))

	var ore_stock: Dictionary = GameState.state["factions"][faction_id]["oreStock"]
	var buy_cost := 0
	var ore_bought := 0
	for ore_type in GameData.ORE_TYPES.keys():
		var ore: Dictionary = GameData.ORE_TYPES[ore_type]
		var buy_key := "buyOre_%s" % ore_type
		var buy_qty: int = sell_state.get(buy_key, 0)
		var buy_price := Economy.get_faction_buy_price(faction_id, "ore", ore_type)
		var buy_max: int = Economy.get_faction_buy_max_qty(faction_id, "ore", ore_type)
		var stock: int = int(ore_stock.get(ore_type, 0))
		if buy_qty > 0:
			buy_cost += buy_price * buy_qty
			ore_bought += buy_qty
		ore_rows.append(SellRowBuilders.buy_ore_row(["Buy: ", { "symbol": ore["symbol"], "fallback": SymbolGlyph.ore_fallback(ore_type) }, " %s (£%d/u, stock %d)" % [ore["name"], buy_price, stock]], buy_key, buy_qty, buy_max))

	if GameState.state["flags"]["canSellConsumables"]:
		for recipe_key in GameData.CONSUMABLE_PRICES.keys():
			var buckets: Dictionary = player["inventory"].get(recipe_key, {})
			var recipe: Dictionary = GameData.RECIPES[recipe_key]
			var price := Economy.get_faction_sell_price(faction_id, "consumable", recipe_key)
			var tier_keys: Array = buckets.keys()
			tier_keys.sort_custom(func(a, b): return int(a) < int(b))
			for tier_key in tier_keys:
				var have: int = buckets[tier_key]
				if have <= 0:
					continue
				var key := "con_%s_%s" % [recipe_key, tier_key]
				var qty: int = sell_state.get(key, 0)
				gross += price * qty
				var tier_label := "untiered" if int(tier_key) <= 0 else "tier %d" % int(tier_key)
				item_rows.append(SellRowBuilders.sell_row([{ "symbol": recipe["symbol"], "fallback": SymbolGlyph.generic_fallback() }, "%s (%s, £%d/ea, have %d)" % [recipe["name"], tier_label, price, have]], key, qty, have))

	var asset_rows: Array = []
	var veins_selected := 0
	var veins_bought := 0
	if GameState.state["flags"].get("veinSaleUnlocked", false):
		for vein in player["veins"]:
			var vein_key := "vein_%s" % vein["id"]
			var selected: bool = sell_state.get(vein_key, 0) > 0
			var vein_price := VeinTrade.quote(vein)
			if selected:
				gross += vein_price
				veins_selected += 1
			var vein_ore: Dictionary = GameData.ORE_TYPES[vein["oreType"]]
			var vein_district: Dictionary = GameData.DISTRICTS[vein["district"]]
			var vein_parts := ["%s — " % vein_district["name"], { "symbol": vein_ore["symbol"], "fallback": SymbolGlyph.ore_fallback(vein["oreType"]) }, " %s (£%d)" % [vein_ore["name"], vein_price]]
			asset_rows.append(SellRowBuilders.sell_vein_row(vein_parts, vein["id"], selected))

		for site in Sites.sites_with_faction_vein(faction_id):
			var faction_vein: Dictionary = site["factionVein"]
			var buy_key := "buyVein_%s" % faction_vein["id"]
			var buy_selected: bool = sell_state.get(buy_key, 0) > 0
			var buy_price := VeinTrade.quote(faction_vein)
			if buy_selected:
				buy_cost += buy_price
				veins_bought += 1
			var buy_ore: Dictionary = GameData.ORE_TYPES[faction_vein["oreType"]]
			var buy_district: Dictionary = GameData.DISTRICTS[faction_vein["district"]]
			var buy_parts := ["Buy: %s — " % buy_district["name"], { "symbol": buy_ore["symbol"], "fallback": SymbolGlyph.ore_fallback(faction_vein["oreType"]) }, " %s (£%d)" % [buy_ore["name"], buy_price]]
			asset_rows.append(SellRowBuilders.buy_vein_row(buy_parts, faction_vein["id"], buy_selected))

	SellRowBuilders.sell_sections(container, ore_rows, item_rows, asset_rows)

	var net := gross - buy_cost
	if net >= 0:
		container.add_child(UI.label("You'll get: £%d" % net))
	else:
		container.add_child(UI.label("You'll pay: £%d" % -net))

	var go_label := "Go — trade"
	var go_notes: Array = []
	if veins_selected == 1:
		go_notes.append("1 vein sale")
	elif veins_selected > 1:
		go_notes.append("%d vein sales" % veins_selected)
	if veins_bought == 1:
		go_notes.append("1 vein purchase")
	elif veins_bought > 1:
		go_notes.append("%d vein purchases" % veins_bought)
	if ore_bought > 0:
		go_notes.append("%d ore bought" % ore_bought)
	if not go_notes.is_empty():
		go_label += " (includes %s)" % ", ".join(go_notes)
	var go_button := UI.button(go_label, func(): Collective.complete_trade(contact_id))
	var nothing_selected := gross == 0 and buy_cost == 0
	var unaffordable: bool = net < 0 and -net > int(player["cash"])
	go_button.disabled = nothing_selected or unaffordable
	container.add_child(go_button)
	container.add_child(UI.button("Cancel", func(): cancel()))

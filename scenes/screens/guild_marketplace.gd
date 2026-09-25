class_name GuildMarketplaceScreen
extends Control

var _content: VBoxContainer

func _ready() -> void:
	UI.anchor_full_rect(self)
	_content = UI.screen_body(self)
	EventBus.state_changed.connect(_refresh)
	_refresh()

func _refresh() -> void:
	for child in _content.get_children():
		child.queue_free()

	_content.add_child(UI.back_to_home_button())
	_content.add_child(UI.heading("Guild Marketplace"))

	if not GameState.state["factions"]["guild"]["joined"]:
		_build_locked()
		return

	# Off the Map tab: light card family (MapCardStyle).
	MapPalette.build_light(_build_trading_ui)
func _build_locked() -> void:
	_content.add_child(UI.muted_label("Guild members only."))
	_content.add_child(UI.label("They don't trade with outsiders. Build relation and join to get in."))
func _build_trading_ui() -> void:
	_content.add_child(UI.muted_label("Ticker-effective prices. Spread narrows the more the Guild trusts you."))

	for ore_type in GameData.ORE_TYPES.keys():
		_content.add_child(_build_goods_row("ore", ore_type))
	if GameState.state["flags"]["canSellConsumables"]:
		for recipe_key in GameData.CONSUMABLE_PRICES.keys():
			_content.add_child(_build_goods_row("consumable", recipe_key))

func _build_goods_row(kind: String, item_type: String) -> Control:
	var player: Dictionary = GameState.state["player"]
	var name: String
	var symbol: String
	var have: int
	if kind == "ore":
		var ore: Dictionary = GameData.ORE_TYPES[item_type]
		name = ore["name"]
		symbol = ore["symbol"]
		have = player["orichalchum"].get(item_type, 0)
	else:
		var recipe: Dictionary = GameData.RECIPES[item_type]
		name = recipe["name"]
		symbol = recipe["symbol"]
		have = Crafting.inventory_qty(item_type)

	var buy_price := Economy.get_faction_buy_price("guild", kind, item_type)
	var sell_price := Economy.get_faction_sell_price("guild", kind, item_type)

	var fallback: Callable = SymbolGlyph.ore_fallback(item_type) if kind == "ore" else SymbolGlyph.generic_fallback()

	var c := MapCardStyle.card()
	c["content"].add_child(UI.symbol_row([{ "symbol": symbol, "fallback": fallback }, name], { "heading_size": 15 }))
	c["content"].add_child(UI.label("Buy £%d/u · Sell £%d/u · Have %d" % [buy_price, sell_price, have]))
	var buy_max_qty := Economy.get_faction_buy_max_qty("guild", kind, item_type)
	var sell_max_qty := have
	var stepper_max := maxi(buy_max_qty, sell_max_qty)
	var qty: int = clampi(Economy.get_marketplace_qty("guild", kind, item_type), 1, maxi(stepper_max, 1))

	c["content"].add_child(_build_qty_stepper_row(kind, item_type, qty, stepper_max))
	var row := UI.hflow()

	var buy_total := qty * buy_price
	var buy := func(): Economy.execute_faction_purchase("guild", [{ "kind": kind, "type": item_type, "qty": qty }])
	row.add_child(MapCardStyle.text_button("Buy ×%d (£%d)" % [qty, buy_total], buy, qty > buy_max_qty))

	var sell_total := qty * sell_price
	var sell := func(): Economy.execute_faction_sale("guild", [{ "kind": kind, "type": item_type, "qty": qty }])
	row.add_child(MapCardStyle.text_button("Sell ×%d (£%d)" % [qty, sell_total], sell, qty > sell_max_qty))

	c["content"].add_child(row)
	return c["panel"]
func _build_qty_stepper_row(kind: String, item_type: String, qty: int, max_qty: int) -> Control:
	return MapCardStyle.stepper("Qty", qty, func(delta: int): Economy.adjust_marketplace_qty("guild", kind, item_type, delta, max_qty))

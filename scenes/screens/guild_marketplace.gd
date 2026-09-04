class_name GuildMarketplaceScreen
extends Control

# bugfixes-29: trading UI for economy.gd's Guild lane (bugfixes-28,
# generalized to a per-faction lane by collective1-01 —
# get_faction_buy_price()/get_faction_sell_price()/execute_faction_purchase()/
# execute_faction_sale(), called here with faction_id "guild"). Reached from
# the guild's faction card
# (ContactCards.build_faction_card, always shown so a non-member can find
# out the Guild exists) -- membership itself is checked here, not at the
# entry point, so a non-member always lands on the locked state rather than
# the trading UI regardless of how they got here. Catalog matches the
# existing sell_menu modal's roster exactly (all 5 ore types +
# GameData.CONSUMABLE_PRICES, consumables behind the same flags.
# canSellConsumables tutorial gate) -- no separate goods list exists
# anywhere in the game to draw a different one from.

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

	_build_trading_ui()


# PROSE-REVIEW: new copy, tone bible per docs/CONTENT-GUIDE.md.
func _build_locked() -> void:
	_content.add_child(UI.muted_label("Guild members only."))
	_content.add_child(UI.label("They don't trade with outsiders. Build relation and join to get in."))


# PROSE-REVIEW: new copy, tone bible per docs/CONTENT-GUIDE.md.
func _build_trading_ui() -> void:
	_content.add_child(UI.muted_label("Ticker-effective prices. Spread narrows the more the Guild trusts you."))

	for ore_type in GameData.ORE_TYPES.keys():
		_content.add_child(_build_goods_row("ore", ore_type))

	# Same canSellConsumables tutorial gate as modal_layer.gd's sell_menu --
	# this is the catalog it's mirroring, so consumables shouldn't become
	# tradeable here before that reveal has actually happened elsewhere.
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

	var c := UI.card()
	c["content"].add_child(UI.symbol_row([{ "symbol": symbol, "fallback": fallback }, name], { "heading_size": 15 }))
	c["content"].add_child(UI.label("Buy £%d/u · Sell £%d/u · Have %d" % [buy_price, sell_price, have]))

	# Ticket 66: one shared qty stepper per row, feeding both the Buy and
	# Sell buttons below -- buy_max_qty/sell_max_qty are each direction's
	# own ceiling (affordability / stock), the stepper's own max is the
	# larger of the two so neither direction is stuck unable to reach its
	# own ceiling, and each button disables independently against its own
	# ceiling rather than the shared stepper max.
	var buy_max_qty := Economy.get_faction_buy_max_qty("guild", kind, item_type)
	var sell_max_qty := have
	var stepper_max := maxi(buy_max_qty, sell_max_qty)
	var qty: int = clampi(Economy.get_marketplace_qty("guild", kind, item_type), 1, maxi(stepper_max, 1))

	c["content"].add_child(_build_qty_stepper_row(kind, item_type, qty, stepper_max))

	var row := UI.hbox()

	var buy_total := qty * buy_price
	var buy_button := UI.button("Buy ×%d (£%d)" % [qty, buy_total], func():
		Economy.execute_faction_purchase("guild", [{ "kind": kind, "type": item_type, "qty": qty }])
	)
	buy_button.disabled = qty > buy_max_qty
	row.add_child(buy_button)

	var sell_total := qty * sell_price
	var sell_button := UI.button("Sell ×%d (£%d)" % [qty, sell_total], func():
		Economy.execute_faction_sale("guild", [{ "kind": kind, "type": item_type, "qty": qty }])
	)
	sell_button.disabled = qty > sell_max_qty
	row.add_child(sell_button)

	c["content"].add_child(row)
	return c["panel"]


# Ticket 66: same "-"/qty/"+" row shape as lab.gd's _build_craft_qty_row and
# modal_layer.gd's _build_sell_row -- including the same ASCII "-" fix
# (bugfixes ticket 13: U+2212 MINUS SIGN doesn't render).
func _build_qty_stepper_row(kind: String, item_type: String, qty: int, max_qty: int) -> Control:
	var row := UI.hbox()
	row.add_child(UI.label("Qty:"))
	row.add_child(UI.button("-", func(): Economy.adjust_marketplace_qty("guild", kind, item_type, -1, max_qty)))
	row.add_child(UI.label(str(qty)))
	row.add_child(UI.button("+", func(): Economy.adjust_marketplace_qty("guild", kind, item_type, 1, max_qty)))
	return row

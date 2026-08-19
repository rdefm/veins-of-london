class_name GuildMarketplaceScreen
extends Control

# bugfixes-29: trading UI for economy.gd's Guild lane (bugfixes-28's
# get_guild_buy_price()/get_guild_sell_price()/execute_guild_purchase()/
# execute_guild_sale()). Reached from the guild's faction card
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
		have = player["inventory"].get(item_type, 0)

	var buy_price := Economy.get_guild_buy_price(kind, item_type)
	var sell_price := Economy.get_guild_sell_price(kind, item_type)

	var c := UI.card()
	c["content"].add_child(UI.heading("%s %s" % [symbol, name], 15))
	c["content"].add_child(UI.label("Buy £%d/u · Sell £%d/u · Have %d" % [buy_price, sell_price, have]))

	var row := UI.hbox()

	var buy_button := UI.button("Buy 1 (£%d)" % buy_price, func():
		Economy.execute_guild_purchase([{ "kind": kind, "type": item_type, "qty": 1 }])
	)
	buy_button.disabled = player["cash"] < buy_price
	row.add_child(buy_button)

	var sell_button := UI.button("Sell 1 (£%d)" % sell_price, func():
		Economy.execute_guild_sale([{ "kind": kind, "type": item_type, "qty": 1 }])
	)
	sell_button.disabled = have <= 0
	row.add_child(sell_button)

	c["content"].add_child(row)
	return c["panel"]

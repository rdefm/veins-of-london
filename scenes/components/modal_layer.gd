class_name ModalLayer
extends Control

# Dim background + centred card, dispatching on modal.type. Covers the
# roster T12 asks for except room_detail and generic confirm dialogs
# (deferred — see the note at the bottom of this file).

var _dim: ColorRect
var _card: PanelContainer
var _scroll: ScrollContainer
var _card_content: VBoxContainer

# vein-trade-assets ticket 01: Ore/Items/Assets sections in sell_menu, all
# starting expanded. _refresh() rebuilds _card_content from scratch on every
# EventBus.state_changed, so the section nodes can't remember their own
# expand state -- these instance vars are what persists it across a rebuild
# (same pattern hq.gd's _security_expanded/_rooms_expanded use). Shared
# between Archie's lane and the faction lane since only one sell_menu is ever
# open at a time.
var _sell_ore_expanded: bool = true
var _sell_items_expanded: bool = true
var _sell_assets_expanded: bool = true

# Root cause of "cultivate/seed shows a blank white modal, nothing tappable"
# (bugfixes ticket 06): _card is a shrink-to-fit PanelContainer (UI.anchor_
# center — its rect clamps up to its own minimum size, per Control's normal
# anchor/offset/minimum-size resolution), sized by its one child, _scroll.
# But a ScrollContainer deliberately reports ZERO minimum size on any axis
# where scrolling isn't disabled (that's what lets it scroll instead of
# forcing its parent bigger) — vertical_scroll_mode was left at its default
# (enabled), so _card's computed minimum height was always 0 regardless of
# how much content _card_content held. The card rect was really there
# (330 wide) but zero-tall: invisible and untappable, on every modal, every
# time — not just seed/cultivate, just first hit there because those are
# the earliest modals a fresh playthrough reaches. Fixed by capping
# _scroll's own minimum height to whatever _card_content actually needs (so
# short results like this one size the card to fit, like PanelContainer
# always should have), falling back to MAX_CARD_HEIGHT and real scrolling
# only for content taller than that (sell_menu, network_reference).
const MAX_CARD_HEIGHT := 620.0

func _ready() -> void:
	UI.anchor_full_rect(self)
	visible = false

	_dim = ColorRect.new()
	_dim.color = Color(0, 0, 0, 0.5)
	UI.anchor_full_rect(_dim)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	# Ticket 12: without this, STOP just swallows the tap silently, leaving
	# scrolling to an explicit Close/Cancel/Decline button as the only way
	# out. Same pattern as map_controls.gd's filter drawer.
	_dim.gui_input.connect(_on_dim_gui_input)
	add_child(_dim)

	_card = PanelContainer.new()
	UI.anchor_center(_card)
	add_child(_card)

	_scroll = UI.scroll_container()
	_scroll.custom_minimum_size = Vector2(330, 0)
	_card.add_child(_scroll)

	# Anchors are ignored for a ScrollContainer's child, and without
	# SIZE_EXPAND_FILL it shrinks to its content's minimum width instead of
	# scroll's 330px — the same failure mode UI.screen_body()'s own comment
	# documents (a word-wrapped Label's minimum width collapses near 0,
	# breaking mid-word), and the same fix bag_drawer.gd needed.
	_card_content = UI.vbox(8)
	_card_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_card_content)

	EventBus.state_changed.connect(_refresh)
	_refresh()


func _on_dim_gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed:
		_dismiss_modal()


# Ticket 12: tapping outside must run the same side effect as the modal's
# own Close/Cancel/Decline button, not a bare Modal.close() that leaves
# state half-applied — sell_menu's sellState selections, james_job_offer's
# job-decline bookkeeping, and sale_result's return-to-home nav all need
# that. Every other modal's own close button is a bare Modal.close() with no
# side effect (checked against the full match in _build_modal_content()
# above), so they fall through to the default. james_job_offer's Accept
# isn't included here: it's a positive action, not the modal's dismiss path,
# so outside-tap must not run it.
func _dismiss_modal() -> void:
	var modal = GameState.state["modal"]
	if modal == null:
		return
	match modal.get("type", ""):
		"sell_menu":
			_on_sell_menu_cancel()
		"james_job_offer":
			_on_job_decline()
		"sale_result":
			_on_sale_result_close()
		"archie_deal_result":
			_on_archie_deal_result_close()
		_:
			Modal.close()


func _refresh() -> void:
	var modal = GameState.state["modal"]
	visible = modal != null
	if modal == null:
		return

	for child in _card_content.get_children():
		child.queue_free()

	_build_modal_content(modal)

	# One pass now (covers every unwrapped/single-line label immediately, so
	# there's never a fully blank frame) and one deferred (a freshly-added
	# autowrapping Label can't know its own wrapped height until a layout
	# pass has actually handed it _card_content's real width — same chicken-
	# and-egg UI.screen_body()'s own comments describe — so the first pass
	# can undercount a wrapped line and needs the deferred correction).
	_size_card_to_content()
	_size_card_to_content.call_deferred()


func _size_card_to_content() -> void:
	if _card_content.get_child_count() == 0:
		return
	var content_height: float = _card_content.get_combined_minimum_size().y
	_scroll.custom_minimum_size.y = minf(content_height, MAX_CARD_HEIGHT)


func _build_modal_content(modal: Dictionary) -> void:
	var type_id: String = modal.get("type", "")
	var data: Dictionary = modal.get("data", {})

	match type_id:
		"seed_result":
			_build_seed_result(data)
		"cultivate_result":
			_build_cultivate_result(data)
		"craft_result":
			_build_craft_result(data)
		"craft_batch_result":
			_build_craft_batch_result(data)
		"sell_menu":
			_build_sell_menu()
		"sale_result":
			_build_sale_result(data)
		"archie_deal_result":
			_build_archie_deal_result(data)
		"james_job_offer":
			_build_james_job_offer(data)
		"james_job_short":
			_build_james_job_short(data)
		"james_job_complete":
			_build_james_job_complete(data)
		"network_reference":
			_build_network_reference()
		"sell_vein_quote":
			_build_sell_vein_quote(data)
		"movement_craft":
			_build_movement_craft(data)
		"craft_components_menu":
			_build_craft_components_menu()
		"movement_swap":
			_build_movement_swap()
		"dial_load_complication":
			_build_dial_load_complication()
		"combat_setup":
			_build_combat_setup()
		"hq_ore_readout":
			_build_hq_ore_readout()
		"hq_gym":
			_build_hq_gym()
		"lab_bench_recipe_book":
			_build_lab_bench_recipe_book()
		"lab_bench_notes":
			_build_lab_bench_notes()
		"lab_bench_probe_result":
			_build_lab_bench_probe_result(data)
		_:
			_card_content.add_child(UI.heading(type_id))
			_card_content.add_child(UI.label("…"))
			_card_content.add_child(UI.button("Close", func(): Modal.close()))


func _build_seed_result(data: Dictionary) -> void:
	var success: bool = data.get("success", false)
	_card_content.add_child(UI.heading("✅ Vein seeded." if success else "❌ Nothing took."))
	if success:
		var ore: Dictionary = GameData.ORE_TYPES[data["oreType"]]
		_card_content.add_child(UI.label("A level 1 %s vein has formed. Cultivate it to grow." % ore["name"]))
	else:
		_card_content.add_child(UI.label("The calc dispersed without forming anything. Happens. Keep practising."))
	_card_content.add_child(UI.button("Got it", func(): Modal.close()))


func _build_cultivate_result(data: Dictionary) -> void:
	var success: bool = data.get("success", false)
	var levelled_up: bool = data.get("levelledUp", false)
	_card_content.add_child(UI.heading("🌱 Cultivation worked." if success else "❌ Nothing happened."))
	if success:
		if levelled_up:
			_card_content.add_child(UI.label("The vein responded well. It's levelled up to %s." % data.get("newLabel", "")))
		else:
			_card_content.add_child(UI.label("Development bar +%d. Keep at it." % data.get("gain", 0)))
	else:
		_card_content.add_child(UI.label("The vein didn't respond this time. Happens. Your cultivating skill will improve with practice."))
	_card_content.add_child(UI.button("Got it", func(): Modal.close()))


func _build_craft_result(data: Dictionary) -> void:
	var success: bool = data.get("success", false)
	var recipe_key: String = data.get("recipeKey", "")
	var r: Dictionary = GameData.RECIPES.get(recipe_key, {})
	_card_content.add_child(UI.heading("✅ Success" if success else "❌ Failed"))
	if success:
		var power = data.get("power", 0)
		_card_content.add_child(UI.label("You made a %s. Effect power: %s. The calc cost was worth it." % [r.get("name", ""), str(power)]))
	else:
		_card_content.add_child(UI.label("The calc dispersed. Nothing to show for it."))
	_card_content.add_child(UI.button("Got it", func(): Modal.close()))


# Ticket 57: overwrites craft_result's single-outcome modal once the batch
# finishes (Crafting.attempt_craft_batch). Every attempt is listed
# individually per the ticket's acceptance check -- not just an aggregate
# count -- since each was independently rolled, not one pooled chance.
# PROSE-REVIEW: new UI strings, tone bible per docs/CONTENT-GUIDE.md.
func _build_craft_batch_result(data: Dictionary) -> void:
	var recipe_key: String = data.get("recipeKey", "")
	var r: Dictionary = GameData.RECIPES.get(recipe_key, {})
	var requested: int = data.get("requested", 0)
	var completed: int = data.get("completed", 0)
	var successes: int = data.get("successes", 0)
	var attempts: Array = data.get("attempts", [])

	_card_content.add_child(UI.heading("Batch: %s" % r.get("name", "")))
	if completed < requested:
		_card_content.add_child(UI.label("Ran out of calc after %d of the %d you asked for." % [completed, requested]))
	_card_content.add_child(UI.label("%d/%d succeeded." % [successes, completed]))
	for i in range(attempts.size()):
		var attempt: Dictionary = attempts[i]
		var success: bool = attempt.get("success", false)
		var line := "%d. %s" % [i + 1, "✅ Success" if success else "❌ Failed"]
		if success:
			line += " — effect power %s" % str(attempt.get("power", 0))
		_card_content.add_child(UI.label(line))
	_card_content.add_child(UI.button("Got it", func(): Modal.close()))


func _build_sale_result(data: Dictionary) -> void:
	var mugged: bool = data.get("mugged", false)
	var earned: int = data.get("earned", 0)
	_card_content.add_child(UI.heading("You held them off." if mugged else "Done."))
	if mugged:
		_card_content.add_child(UI.label("They tried their luck. They didn't get it. Archie owes you a pint."))
	elif earned < 0:
		# vein-trade-assets ticket 03: a faction-lane cart can now net a
		# purchase (a buy-side vein outweighing whatever else was sold in the
		# same trade) rather than a sale -- "Buyer paid" reads wrong when the
		# player was the one paying. PROSE-REVIEW: new line, tone bible.
		_card_content.add_child(UI.label("Paid up, no fuss. It's yours now."))
	else:
		_card_content.add_child(UI.label("Smooth as you like. Buyer paid promptly and left."))
	_card_content.add_child(UI.label(("+£%d" % earned) if earned >= 0 else ("-£%d" % -earned)))
	_card_content.add_child(UI.button("Back to it", _on_sale_result_close))


func _on_sale_result_close() -> void:
	Modal.close()
	PhoneNav.route_home()


# bugfixes-95: same shape as _build_sale_result/_on_sale_result_close above,
# for Archie's own tag-along deal -- only ever opened on a win (a straight
# accept or a won mugging); a lost mugging routes home with no modal at all
# (Combat._exit_archie_deal_mugging), same as a normal Archie-sale mugging
# loss shows nothing either.
# PROSE-REVIEW: new copy, drafted against CONTENT-GUIDE.md's tone bible.
func _build_archie_deal_result(data: Dictionary) -> void:
	var mugged: bool = data.get("mugged", false)
	_card_content.add_child(UI.heading("You held them off." if mugged else "Sorted."))
	if mugged:
		_card_content.add_child(UI.label("They tried their luck on Archie's stock. Didn't get it."))
	else:
		_card_content.add_child(UI.label("Went smooth. Archie's buyer paid up, no fuss."))
	_card_content.add_child(UI.label("+£%d" % data.get("earned", 0)))
	_card_content.add_child(UI.button("Back to it", _on_archie_deal_result_close))


func _on_archie_deal_result_close() -> void:
	Modal.close()
	PhoneNav.route_home()


# collective1-07: modal.data carries an optional { factionId, contactId }
# context -- absent (Archie's ContactCards.build_sell_action() still calls
# Modal.open("sell_menu") with no data) means the original Archie-lane menu
# below, unchanged. Present, it's one of the three Collective doors
# (ContactCards.build_trade_action()) and routes to _build_faction_sell_menu.
func _build_sell_menu() -> void:
	var modal: Dictionary = GameState.state["modal"]
	var data: Dictionary = modal.get("data", {})
	var faction_id: String = data.get("factionId", "")
	if faction_id != "":
		_build_faction_sell_menu(faction_id, data.get("contactId", ""))
		return

	var player: Dictionary = GameState.state["player"]
	var sell_state: Dictionary = GameState.state["sellState"]

	_card_content.add_child(UI.heading("Find a buyer"))
	_card_content.add_child(UI.muted_label("Archie splits 50/50. Select what you want to move."))

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
		ore_rows.append(_build_sell_row([{ "symbol": ore["symbol"], "fallback": SymbolGlyph.ore_fallback(ore_type) }, "%s (£%d/u, have %d)" % [ore["name"], ore["basePrice"], have]], key, qty, have))

	# ticket 64: one sell row per (recipe, tier) with stock -- price now
	# scales by quality tier (Economy.quality_price_multiplier), so tiers of
	# the same consumable are no longer fungible at sale time.
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
				item_rows.append(_build_sell_row([{ "symbol": recipe["symbol"], "fallback": SymbolGlyph.generic_fallback() }, "%s (%s, £%d/ea, have %d)" % [recipe["name"], tier_label, price, have]], key, qty, have))

	# vein-trade-assets ticket 02: Archie's Assets section goes live -- same
	# 0/1 toggle rows the faction lane's Assets section uses below, priced at
	# Economy.get_archie_vein_price() (quote + Archie's markup) rather than
	# the faction lane's plain VeinTrade.quote(). Toggling folds the vein
	# into this same gross/cut/mugging-roll flow via Economy.sell_from_sell_state().
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
			asset_rows.append(_build_sell_vein_row(vein_parts, vein["id"], selected))

	_build_sell_sections(ore_rows, item_rows, asset_rows)

	var cut_ratio := Economy.get_archie_cut_ratio()
	var player_cut: int = int(floor(gross * cut_ratio))
	_card_content.add_child(UI.label("Your cut (%d%%): £%d" % [int(round(cut_ratio * 100)), player_cut]))
	# vein-trade-assets ticket 02, spec: a vein in the trade rolls a lower
	# base mugging chance (Economy.MUG_BASE_CHANCE_VEIN) than the plain
	# ore/item rate -- against a harder roster, per Combat.start_mugging's
	# vein_included argument (not shown here; this label is the base-chance
	# figure only, same simplification the pre-existing "20%" label made by
	# never accounting for district dangerMod either).
	var mug_pct: float = Economy.MUG_BASE_CHANCE_VEIN if veins_selected > 0 else Economy.MUG_BASE_CHANCE
	_card_content.add_child(UI.muted_label("%d%% chance of mugging" % int(round(mug_pct * 100))))

	var go_button := UI.button("Go — find a buyer", func(): Economy.sell_from_sell_state())
	go_button.disabled = player_cut == 0
	_card_content.add_child(go_button)
	_card_content.add_child(UI.button("Cancel", _on_sell_menu_cancel))


func _on_sell_menu_cancel() -> void:
	Economy.clear_sell_state()
	Modal.close()


# collective1-07, spec §5.5/§8.1: straight sale at the faction's spread-
# narrowed price -- no cut, no mugging (unlike the Archie-lane menu above).
# Same sellState cart and the same _build_sell_row() qty steppers; only the
# price source and the Go action differ.
func _build_faction_sell_menu(faction_id: String, contact_id: String) -> void:
	var player: Dictionary = GameState.state["player"]
	var sell_state: Dictionary = GameState.state["sellState"]
	var faction_name: String = GameData.FACTIONS[faction_id]["name"]

	_card_content.add_child(UI.heading("Trade with %s" % faction_name))
	_card_content.add_child(UI.muted_label("Straight sale. No cut, no risk of a mugging."))

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
		ore_rows.append(_build_sell_row([{ "symbol": ore["symbol"], "fallback": SymbolGlyph.ore_fallback(ore_type) }, "%s (£%d/u, have %d)" % [ore["name"], price, have]], key, qty, have))

	# collective-ore-stock T02: the buy side of the same Ore section --
	# priced via the existing get_faction_buy_price (unchanged formula), qty
	# capped by get_faction_buy_max_qty (which now also folds in the
	# faction's oreStock, T01) rather than the sell loop's plain "have". All
	# 5 canonical ore types render a row regardless of what the player
	# currently holds, unlike the sell loop above.
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
		ore_rows.append(_build_buy_ore_row(["Buy: ", { "symbol": ore["symbol"], "fallback": SymbolGlyph.ore_fallback(ore_type) }, " %s (£%d/u, stock %d)" % [ore["name"], buy_price, stock]], buy_key, buy_qty, buy_max))

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
				item_rows.append(_build_sell_row([{ "symbol": recipe["symbol"], "fallback": SymbolGlyph.generic_fallback() }, "%s (%s, £%d/ea, have %d)" % [recipe["name"], tier_label, price, have]], key, qty, have))

	# vein-trade-assets ticket 01, spec: the faction lane's Assets section --
	# every player-owned vein as a 0/1 include/exclude row (not a +/- stepper,
	# a vein isn't stackable), priced at the same VeinTrade.quote() the
	# standalone vein-list Sell flow already uses. A selected vein folds
	# straight into this trade's gross/Go tap; there's no separate per-vein
	# confirm step here (that guard is the Go button's own label below).
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
			asset_rows.append(_build_sell_vein_row(vein_parts, vein["id"], selected))

		# vein-trade-assets ticket 03: the reverse row -- this faction's own
		# site veins, buyable straight at VeinTrade.quote(), same 0/1 toggle,
		# folded into the same Assets section and the same Go tap. Read
		# straight off state.world.sites' live factionVein roster rather than
		# any player-owned list, since these are the faction's own stock.
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
			asset_rows.append(_build_buy_vein_row(buy_parts, faction_vein["id"], buy_selected))

	_build_sell_sections(ore_rows, item_rows, asset_rows)

	# vein-trade-assets ticket 03: net cash change for the trade as a whole --
	# `gross` was already "positive = credited to the player" before buy rows
	# existed; `net` keeps that same meaning once a purchase can outweigh it,
	# so it's the one figure that always matches result.earned and the
	# player's actual cash delta.
	var net := gross - buy_cost
	if net >= 0:
		_card_content.add_child(UI.label("You'll get: £%d" % net))
	else:
		_card_content.add_child(UI.label("You'll pay: £%d" % -net))

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
	_card_content.add_child(go_button)
	_card_content.add_child(UI.button("Cancel", _on_sell_menu_cancel))


# vein-trade-assets ticket 01: both sell_menu lanes (Archie above, the
# faction lane below) render Ore/Items/Assets as three UI.collapsible_section
# panels rather than a flat list -- ore/item row contents and cart behaviour
# are unchanged, just regrouped. Assets is gated entirely by
# flags.veinSaleUnlocked (Archie's lane always passes an empty asset_rows,
# so the section still shows -- inert -- once unlocked, same as the faction
# lane's populated one).
func _build_sell_sections(ore_rows: Array, item_rows: Array, asset_rows: Array) -> void:
	var ore_section := UI.collapsible_section("Ore", _sell_ore_expanded, func(v): _sell_ore_expanded = v)
	for row in ore_rows:
		ore_section["content"].add_child(row)
	_card_content.add_child(ore_section["panel"])

	var items_section := UI.collapsible_section("Items", _sell_items_expanded, func(v): _sell_items_expanded = v)
	for row in item_rows:
		items_section["content"].add_child(row)
	_card_content.add_child(items_section["panel"])

	if GameState.state["flags"].get("veinSaleUnlocked", false):
		var assets_section := UI.collapsible_section("Assets", _sell_assets_expanded, func(v): _sell_assets_expanded = v)
		for row in asset_rows:
			assets_section["content"].add_child(row)
		_card_content.add_child(assets_section["panel"])


# The faction lane's Assets row: a 0/1 toggle (Economy.toggle_sell_vein), not
# _build_sell_row's -/+ stepper -- a vein isn't stackable. `parts`: same
# UI.symbol_row()-shaped Array every caller here now builds (bugfixes ticket
# 114), since every row this function renders pairs an ore symbol with text.
func _build_sell_vein_row(parts: Array, vein_id: String, selected: bool) -> Control:
	# Was UI.hbox(6) -- a bare hbox never wraps, so a long
	# vein_parts string (district + ore + price) plus the checkbox could add
	# up to more than _card's fixed 330px content width. That doesn't just
	# clip to the right: _card is a shrink-to-fit PanelContainer centred via
	# UI.anchor_center (GROW_DIRECTION_BOTH), and _scroll's horizontal
	# scrolling is deliberately disabled (UI.scroll_container()'s own
	# comment), so a too-wide row inflates _card's own minimum width and it
	# grows symmetrically past both edges of the screen instead. hflow wraps
	# the text onto its own line under the checkbox rather than forcing the
	# whole card wider.
	var row := UI.hflow(6)
	row.add_child(UI.button("☑" if selected else "☐", func(): Economy.toggle_sell_vein(vein_id)))
	var text_row := UI.symbol_row(parts)
	text_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text_row)
	return row


# vein-trade-assets ticket 03: the buy-side counterpart -- same 0/1 toggle
# shape, wired to Economy.toggle_buy_vein() instead.
func _build_buy_vein_row(parts: Array, vein_id: String, selected: bool) -> Control:
	# See _build_sell_vein_row's own comment just above.
	var row := UI.hflow(6)
	row.add_child(UI.button("☑" if selected else "☐", func(): Economy.toggle_buy_vein(vein_id)))
	var text_row := UI.symbol_row(parts)
	text_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text_row)
	return row


# collective-ore-stock T02: an ore buy row -- same -/+ stepper shape as
# _build_sell_row below, wired to the same Economy.adjust_sell_qty (the
# "buyOre_<type>" key is just another sellState cart slot), except when
# max_qty is 0 (stock exhausted) it renders "Sold out" with no steppers at
# all, rather than a stepper that silently refuses to move past 0.
func _build_buy_ore_row(parts: Array, key: String, qty: int, max_qty: int) -> Control:
	# Was UI.hbox() -- see _build_sell_vein_row's comment above
	# for why a bare hbox here can force _card wider than the screen on both
	# sides rather than just clipping. hflow wraps the stepper onto its own
	# line under the text instead; the stepper's own "-"/qty/"+" trio is
	# bundled into one sub-hbox so hflow wraps it as a unit, not scattered
	# one control per line.
	var row := UI.hflow()
	var text_row := UI.symbol_row(parts)
	text_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text_row)
	if max_qty <= 0:
		row.add_child(UI.muted_label("Sold out"))
		return row
	var stepper := UI.hbox()
	stepper.add_child(UI.button("-", func(): Economy.adjust_sell_qty(key, -1, max_qty)))
	stepper.add_child(UI.label(str(qty)))
	stepper.add_child(UI.button("+", func(): Economy.adjust_sell_qty(key, 1, max_qty)))
	row.add_child(stepper)
	return row


func _build_sell_row(parts: Array, key: String, qty: int, max_qty: int) -> Control:
	# Was UI.hbox() -- see _build_sell_vein_row's comment above.
	var row := UI.hflow()
	var text_row := UI.symbol_row(parts)
	# Same fix as UI.message_bubble()/checklist_row(): a non-expand
	# autowrapping Label's minimum size collapses to ~1px, so without this
	# it renders as a 1px-wide column with the text overflowing across the
	# "-"/qty/"+" controls that follow it in this row.
	text_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text_row)
	var stepper := UI.hbox()
	# Bugfixes ticket 13: this was "−" (U+2212 MINUS SIGN), the same
	# invisible-non-ASCII-glyph bug as the map top bar's "☰"/"🎒", and
	# unlike its "+" sibling it had no fallback text to keep the button
	# legible. ASCII "-" renders correctly.
	stepper.add_child(UI.button("-", func(): Economy.adjust_sell_qty(key, -1, max_qty)))
	stepper.add_child(UI.label(str(qty)))
	stepper.add_child(UI.button("+", func(): Economy.adjust_sell_qty(key, 1, max_qty)))
	row.add_child(stepper)
	return row


func _build_james_job_offer(data: Dictionary) -> void:
	var job: Dictionary = data["job"]
	_card_content.add_child(UI.heading("Job from James"))
	if job["type"] == "flatPay":
		# PROSE-REVIEW: new flatPay offer copy, drafted against CONTENT-GUIDE.md's tone bible.
		_card_content.add_child(UI.label("\"Need an extra pair of hands for an afternoon. Pays well.\""))
		_card_content.add_child(UI.label("Costs 1 time block — £%d flat." % job["pay"]))
	else:
		_card_content.add_child(UI.label("\"I need %d %s. Standard rate. Don't take too long about it.\"" % [job["qty"], job["recipeName"]]))
		_card_content.add_child(UI.symbol_row([{ "symbol": job["symbol"], "fallback": SymbolGlyph.generic_fallback() }, "%s ×%d — £%d/ea — total £%d — needed by day %d" % [job["recipeName"], job["qty"], job["payPerItem"], job["totalPay"], job["byDay"]]]))
	_card_content.add_child(UI.button("Accept", _on_job_accept))
	_card_content.add_child(UI.button("Decline", _on_job_decline))


func _on_job_accept() -> void:
	Jobs.accept_job()
	Modal.close()


func _on_job_decline() -> void:
	Modal.close()
	Jobs.decline_job()


func _build_james_job_short(data: Dictionary) -> void:
	var job: Dictionary = data["job"]
	_card_content.add_child(UI.heading("Not enough stock"))
	_card_content.add_child(UI.label("James needs %d× %s. You have %d. Get crafting." % [job["qty"], job["recipeName"], data.get("have", 0)]))
	_card_content.add_child(UI.button("Back to it", func(): Modal.close()))


func _build_james_job_complete(data: Dictionary) -> void:
	_card_content.add_child(UI.heading("Job done."))
	_card_content.add_child(UI.label("\"Adequate work. Prompt enough.\" He counts out the money without ceremony."))
	_card_content.add_child(UI.label("+£%d" % data.get("earned", 0)))
	_card_content.add_child(UI.button("Good.", func(): Modal.close()))


# M1.5 N5's legend button ("?" on the filter chip row, map_controls.gd) ->
# "Network Reference": the glyph grammar, N2, plain-listed. PROSE-REVIEW:
# every string in this function — the flavour line and all the row
# descriptions below — is new prose, drafted per CONTENT-GUIDE.md's tone
# bible, not yet human-audited.
func _build_network_reference() -> void:
	_card_content.add_child(UI.heading("Network Reference"))
	_card_content.add_child(UI.muted_label("The lines are money. The dots are where it's coming from — or where someone beat you to it."))
	_card_content.add_child(_legend_row("Amber line", "Your line — stops joined in claim order."))
	_card_content.add_child(_legend_row("Coloured line", "A faction's line, in their colour."))
	_card_content.add_child(_legend_row("Grey stub", "Someone else's claim — not yours, not connected to anything."))
	_card_content.add_child(_legend_row("Ringed dot + symbol", "Your vein. The symbol shows the ore."))
	_card_content.add_child(_legend_row("Tick mark", "Unclaimed site. Double tick — richer ground."))
	_card_content.add_child(_legend_row("Filled grey dot", "Claimed. Not by you."))
	_card_content.add_child(_legend_row("Amber halo", "Charged — ready to harvest."))
	_card_content.add_child(_legend_row("Numeral badge", "Vein level."))
	_card_content.add_child(_legend_row("Padlock", "Security tier — colour shows how well-warded."))
	_card_content.add_child(_legend_row("Zone tint", "A faction's presence in the district."))
	# These two glyphs (unlike every other legend row here, all plain ASCII
	# words) are the same "⌂"/"✉" text-glyph tofu bug map_canvas.gd's own
	# home-pin/quest-pin comments document -- both live pins were already
	# swapped for Icons.draw_home/draw_phone; this legend text just still
	# spelled out the retired raw glyphs. Reuses those same two Icons
	# draw_* funcs as the fallback so the legend entry matches the actual
	# pin shape rather than a generic placeholder.
	_card_content.add_child(_legend_glyph_row("⌂", Icons.draw_home, " pin", "Home. Taps through to HQ."))
	_card_content.add_child(_legend_glyph_row("✉", Icons.draw_phone, " pin", "Someone's waiting on you there."))
	_card_content.add_child(_legend_row("Padlocked pin", "The Soho market. Not yet."))
	_card_content.add_child(_legend_row("Amber ring", "Where you are right now."))
	_card_content.add_child(UI.button("Close", func(): Modal.close()))


func _legend_row(glyph_label: String, description: String) -> Control:
	var row := UI.vbox(2)
	row.add_child(UI.label(glyph_label))
	row.add_child(UI.muted_label(description))
	return row


# _legend_row()'s counterpart for the two rows whose "glyph" is itself a
# tofu-prone unicode character (see the call sites' own comment) rather than
# a plain word describing one -- routes that character through SymbolGlyph
# instead of a bare Label.
func _legend_glyph_row(symbol: String, fallback: Callable, suffix_text: String, description: String) -> Control:
	var row := UI.vbox(2)
	row.add_child(UI.symbol_row([{ "symbol": symbol, "fallback": fallback }, suffix_text]))
	row.add_child(UI.muted_label(description))
	return row


# collective1-05, spec §5.6's guard: "Quote, then confirm... losing a vein
# must never be one tap." This is the first per-action-type confirm modal
# the "Deferred" note at the bottom of this file anticipated (modal.type =
# "sell_vein_quote", data = { veinId, price, factionId } -- systems/
# vein_list.gd's apply_option(SELL_ID, ...) is the only thing that opens
# it). Cancel is a bare Modal.close() with no side effect to unwind (unlike
# sell_menu's sellState), so _dismiss_modal()'s match above needs no entry
# for it -- the default case already covers it correctly.
# PROSE-REVIEW: new copy, drafted against CONTENT-GUIDE.md's tone bible.
func _build_sell_vein_quote(data: Dictionary) -> void:
	var vein_id: String = data["veinId"]
	var price: int = data["price"]
	var vein: Variant = Cultivating.find_vein(vein_id)
	if vein == null:
		Modal.close()
		return
	var ore: Dictionary = GameData.ORE_TYPES[vein["oreType"]]

	_card_content.add_child(UI.heading("Sell this vein?"))
	_card_content.add_child(UI.symbol_row([{ "symbol": ore["symbol"], "fallback": SymbolGlyph.ore_fallback(vein["oreType"]) }, "%s vein — £%d." % [ore["name"], price]]))
	_card_content.add_child(UI.muted_label("It stops being yours. Someone else's line, someone else's cut, from here on."))
	_card_content.add_child(UI.button("Confirm sale", func(): _on_sell_vein_confirm(vein_id)))
	_card_content.add_child(UI.button("Cancel", func(): Modal.close()))


func _on_sell_vein_confirm(vein_id: String) -> void:
	VeinTrade.sell_to_faction(vein_id, VeinTrade.SELL_FACTION_ID)
	Modal.close()


# bugfixes ticket 105: hq.gd's Dial card's "Craft Components" button opens
# this -- the ticket-104 archetype list (name + one-line effect description
# + Craft button) moved here wholesale from hq.gd's old always-inline
# _build_movement_crafting_section, so the Dial card itself only links out to
# it instead of rendering it. The m["description"] line rendered below
# (data/dial.json's movements.*.description strings) is unchanged copy
# already flagged PROSE-REVIEW at ticket 104 -- nothing new to re-review here.
func _build_craft_components_menu() -> void:
	_card_content.add_child(UI.heading("Craft Components"))
	for archetype in GameData.CANONICAL_MOVEMENT_ARCHETYPES:
		var m: Dictionary = GameData.DIAL_MOVEMENTS[archetype]
		var block := UI.vbox(4)
		block.add_child(UI.symbol_row([{ "symbol": m["symbol"], "fallback": SymbolGlyph.generic_fallback() }, m["name"]]))
		block.add_child(UI.muted_label(m.get("description", "")))
		var captured_archetype: String = archetype
		block.add_child(UI.button("Craft", func(): Modal.open("movement_craft", { "archetype": captured_archetype })))
		_card_content.add_child(block)
	_card_content.add_child(UI.button("Close", func(): Modal.close()))


# hq-diorama ticket 16: hq_dial.gd's consolidated top block's "Swap" button
# opens this in place of the old always-rendered per-inventory-item Seat
# card list -- same Dial.seat_movement(index) call the deleted cards used,
# unchanged, just gathered behind one button tap instead of always
# rendered below the seated Movement.
func _build_movement_swap() -> void:
	_card_content.add_child(UI.heading("Swap Movement"))
	var player: Dictionary = GameState.state["player"]
	var inventory: Array = player["movementInventory"]
	for i in range(inventory.size()):
		var inv_movement: Dictionary = inventory[i]
		var md: Dictionary = GameData.DIAL_MOVEMENTS[inv_movement["archetype"]]
		var captured_index: int = i
		_card_content.add_child(UI.symbol_button([{ "symbol": md["symbol"], "fallback": SymbolGlyph.generic_fallback() }, "%s — attuned %s, tier %d" % [md["name"], inv_movement["oreType"], inv_movement["tier"]]], func():
			Dial.seat_movement(captured_index)
			Modal.close()
		))
	_card_content.add_child(UI.button("Cancel", func(): Modal.close()))


# hq-diorama ticket 17: hq_dial.gd's flanking sockets tap an Empty housing to
# open this instead of the old always-rendered bottom tray (deleted this
# ticket) -- same tier-bucketed inventory scan and Dial.load_complication()
# call the tray used, just gathered behind one tap per Empty housing
# instead. No slot-targeting: load_complication() has no concept of which
# housing a load lands in (it just appends), so picking a recipe here always
# fills the lowest-index Empty housing, same as the tray's own behaviour did.
func _build_dial_load_complication() -> void:
	# PROSE-REVIEW: "Load a Complication" heading is new copy (drafted
	# against the terse imperative headings already used elsewhere in this
	# file -- "Swap Movement", "Craft Components" -- not extracted from the
	# HTML source or CONTENT-GUIDE.md).
	_card_content.add_child(UI.heading("Load a Complication"))
	var player: Dictionary = GameState.state["player"]
	var any_loadable := false
	for recipe_key in GameData.RECIPES.keys():
		var recipe: Dictionary = GameData.RECIPES[recipe_key]
		var buckets: Dictionary = player["inventory"].get(recipe_key, {})
		for tier_key in buckets.keys():
			if buckets[tier_key] <= 0:
				continue
			any_loadable = true
			var captured_key: String = recipe_key
			var captured_tier: int = int(tier_key)
			_card_content.add_child(UI.symbol_button([{ "symbol": recipe["symbol"], "fallback": SymbolGlyph.generic_fallback() }, "%s tier %s (%d)" % [recipe["name"], tier_key, buckets[tier_key]]], func():
				Dial.load_complication(captured_key, captured_tier)
				Modal.close()
			))
	if not any_loadable:
		# PROSE-REVIEW: carried over unchanged from the old tray/drawer copy.
		_card_content.add_child(UI.muted_label("Nothing in stock to load."))
	_card_content.add_child(UI.button("Cancel", func(): Modal.close()))


# bugfixes ticket 104: hq.gd's "Craft" button opens this instead of crafting
# directly -- cost/chance are identical across all 5 calc types (Dial.
# movement_calc_cost/movement_craft_chance take the archetype and the
# player's skill, not the ore type), so they're computed once here and shown
# on every row rather than re-derived per option.
func _build_movement_craft(data: Dictionary) -> void:
	var archetype: String = data.get("archetype", "")
	var m: Dictionary = GameData.DIAL_MOVEMENTS[archetype]
	var player: Dictionary = GameState.state["player"]
	var skill: int = player["craftingSkill"]
	var cost: int = Dial.movement_calc_cost(archetype, skill)
	var chance_pct: int = int(round(Dial.movement_craft_chance(archetype, skill) * 100))

	_card_content.add_child(UI.symbol_row([{ "symbol": m["symbol"], "fallback": SymbolGlyph.generic_fallback() }, m["name"]], { "heading_size": 20 }))
	_card_content.add_child(UI.muted_label(m.get("description", "")))
	for ore_type in GameData.ORE_TYPES.keys():
		var ore: Dictionary = GameData.ORE_TYPES[ore_type]
		var have: int = player["orichalchum"].get(ore_type, 0)
		var captured_archetype: String = archetype
		var captured_ore: String = ore_type
		var b := UI.symbol_button([{ "symbol": ore["symbol"], "fallback": SymbolGlyph.ore_fallback(ore_type) }, "%s — %d calc, chance %d%%" % [ore["name"], cost, chance_pct]], func(): _on_movement_craft_pressed(captured_archetype, captured_ore))
		b.disabled = have < cost
		_card_content.add_child(b)
	_card_content.add_child(UI.button("Cancel", func(): Modal.close()))


# bugfixes ticket 97: attempt_craft_movement()'s three outcomes were
# previously discarded, a silent-tap problem -- carried over unchanged from
# hq.gd's old direct-button handler, just triggered from the modal's picker
# rows instead.
# PROSE-REVIEW: notification text below is new copy, drafted against
# CONTENT-GUIDE.md §3's tone bible -- flag for human review.
func _on_movement_craft_pressed(archetype: String, ore_type: String) -> void:
	var result := Dial.attempt_craft_movement(archetype, ore_type)
	Modal.close()
	if not result["ok"]:
		Notify.push(result["reason"], Notify.CATEGORY_WARNING)
	elif result["success"]:
		var m: Dictionary = GameData.DIAL_MOVEMENTS[archetype]
		Notify.push("Movement crafted: %s (tier %d)." % [m["name"], result["tier"]], Notify.CATEGORY_SUCCESS)
	else:
		Notify.push("Movement-crafting failed — calc spent, no Movement gained.", Notify.CATEGORY_DANGER)


# Phone Debug app "Combat" card (phone.gd:_build_debug_combat_card): a picker
# UI in front of Combat.start_raid(), the function combat.gd already documents
# as "Debug-only in M0" (R§3.7). Picker selections (template/count/tier/ally
# toggles) live only as local Control state here, same as the LineEdit amount
# fields on the debug screen's other cards -- never written to GameState until
# Fight is pressed, so there's no state to unwind on Cancel and no entry
# needed in _dismiss_modal()'s match above.
func _build_combat_setup() -> void:
	_card_content.add_child(UI.heading("Combat setup"))

	var template_options: Array = ["Random"]
	template_options.append_array(GameData.ENEMY_RAID_GUARDS.keys())
	_card_content.add_child(UI.label("Enemy type"))
	var template_select := UI.option_button(template_options)
	_card_content.add_child(template_select)

	var count_options: Array = []
	for i in range(1, Combat.SQUAD_MAX + 1):
		count_options.append(str(i))
	_card_content.add_child(UI.label("Number of enemies"))
	var count_select := UI.option_button(count_options)
	_card_content.add_child(count_select)

	var tier_options: Array = []
	for i in range(1, 7):
		tier_options.append(str(i))
	_card_content.add_child(UI.label("Value tier"))
	var tier_select := UI.option_button(tier_options)
	_card_content.add_child(tier_select)

	_card_content.add_child(UI.label("Allies"))
	var selected_allies: Array = []
	var eligible_allies := false
	for contact_id in GameState.state["contacts"].keys():
		if not Contacts.can_join_combat(contact_id):
			continue
		eligible_allies = true
		_card_content.add_child(_build_combat_setup_ally_row(contact_id, selected_allies))
	if not eligible_allies:
		_card_content.add_child(UI.muted_label("No recruited contact is fit for a fight right now."))

	_card_content.add_child(UI.button("Fight", func():
		var template_key: String = template_select.get_item_text(template_select.selected)
		if template_key == "Random":
			template_key = ""
		var count: int = count_select.get_item_text(count_select.selected).to_int()
		var value_tier: int = tier_select.get_item_text(tier_select.selected).to_int()
		Modal.close()
		Combat.start_raid("debug_combat_setup", value_tier, count, template_key, Combat.CONTEXT_RAID, selected_allies)
	))
	_card_content.add_child(UI.button("Cancel", func(): Modal.close()))


func _build_combat_setup_ally_row(contact_id: String, selected_allies: Array) -> Control:
	var row := UI.hbox(6)
	var toggle_btn: Button
	toggle_btn = UI.button("☐", func():
		if contact_id in selected_allies:
			selected_allies.erase(contact_id)
			toggle_btn.text = "☐"
		else:
			selected_allies.append(contact_id)
			toggle_btn.text = "☑"
	)
	row.add_child(toggle_btn)
	row.add_child(UI.label(Contacts.display_name(contact_id)))
	return row


# ── hq-diorama ticket 02: HQ zone destinations ────────────────────────
#
# hq.gd's old always-inline cards (Dial/Security/Rooms/Ore-store), moved
# here verbatim — every button and system call below is the exact code
# that used to render inline on the HQ screen, just reached by tapping the
# room's own object instead of scrolling to a card. Tickets 04/05/06/09
# replace these one at a time with the vision doc's diegetic sub-views
# (Dial view §4, floorplan §6, door §8); until then these modals are
# "today's existing destination", per ticket 02's own spec.

# hq-diorama ticket 09: the old "hq_dial" modal (_build_hq_dial(),
# _on_hq_seed_pressed()) is deleted -- its content (unseeded-gift-gate copy/
# seed buttons, Movement seat/unseat/wind, Complication load/unload) now
# lives on the full-bleed scenes/screens/hq_dial.gd, the Dial zone's own
# diegetic sub-view (docs/hq-diorama-vision.md §4), reached directly via
# Nav.go_to("hq_dial") rather than this modal layer. "craft_components_menu"/
# "movement_craft" below are unchanged -- that screen still opens them the
# same way this modal used to.


# M1-LONDON-T06: home.storedOre was merged into player.orichalchum (see
# systems/home.gd) — carried ore is what a raid actually risks, so this
# readout shows the same ore the Bag tab shows, framed as what's at stake.
# docs/hq-diorama-vision.md §12.4: the ore-store zone's recommended default
# is "contents + raid warning" -- the raid-risk line below is new (the old
# inline card only had it on HQ's now-removed top summary), everything
# else is hq.gd's old _build_stored_ore_card() unchanged.
#
# field-kit-chrome ticket 07, ui-vision.md §5's component table ("Ore-store
# readout: a handwritten inventory slip -- running totals per ore type, in
# hand, the kind of thing someone updates every time stock moves. The
# raid-warning line rides the same slip rather than a separate element"):
# the content/values here are untouched (same ore-type loop, same "None in
# stock."/raid-risk text) -- only the wrapper changes, from bare children of
# _card_content to one slip-styled panel. §7 locks a single shared UI sans
# across every family ("never... by swapping typeface"), and no handwriting
# font ships in this repo (same gap the dot-matrix board's own §5 note
# describes for its font), so the "handwritten" read comes from linework,
# not a cursive typeface: a wobbled ruled underline under the heading
# (_SlipRule) and a wobbled, rotated stamp border around the raid line
# (_SlipStamp) -- the same "engine can't render this, hand-draw it instead"
# precedent ore_glyphs.gd/SymbolGlyph already set for the ore symbols, so no
# produced texture asset is needed here either (no ART-REVIEW flag).
func _build_hq_ore_readout() -> void:
	var player: Dictionary = GameState.state["player"]

	var slip := UI.card()
	slip["panel"].add_theme_stylebox_override("panel", _slip_panel_style())
	var slip_content: VBoxContainer = slip["content"]

	slip_content.add_child(UI.heading("Ore store", 14))
	var rule := _SlipRule.new()
	rule.custom_minimum_size = Vector2(0, 10)
	slip_content.add_child(rule)

	var any_ore := false
	for ore_type in GameData.ORE_TYPES.keys():
		var qty: int = player["orichalchum"].get(ore_type, 0)
		if qty <= 0:
			continue
		any_ore = true
		var ore: Dictionary = GameData.ORE_TYPES[ore_type]
		slip_content.add_child(UI.symbol_row([{ "symbol": ore["symbol"], "fallback": SymbolGlyph.ore_fallback(ore_type) }, "%s — %d" % [ore["name"], qty]]))
	if not any_ore:
		slip_content.add_child(UI.muted_label("None in stock."))

	var raid_pct: int = int(round(Home.get_home_raid_chance() * 100))
	slip_content.add_child(_build_raid_stamp(raid_pct))
	# PROSE-REVIEW: new flavour text, tone bible per docs/CONTENT-GUIDE.md.
	# Carried over unchanged from hq.gd's old card.
	slip_content.add_child(UI.muted_label("Ore kept at the flat is what a raid takes — carry less, lose less."))

	_card_content.add_child(slip["panel"])
	_card_content.add_child(UI.button("Close", func(): Modal.close()))


# Aged-paper fill/ink colours for the slip -- distinct from ticket 06's
# _ACTION_CARD_FILL (a flat app-card cream) and from the generic ModalLayer
# card behind it: warmer, and near-sharp corners (radius 2, not 10) so it
# reads as a torn-off slip of paper rather than another rounded app panel.
const _SLIP_FILL := Color(0.976471, 0.960784, 0.882353, 1)
const _SLIP_INK := Color(0.219608, 0.219608, 0.239216, 1)
const _STAMP_ROTATION_DEGREES := -3.5

func _slip_panel_style() -> StyleBoxFlat:
	return _bordered_panel_style(_SLIP_FILL, _SLIP_INK, 2, 16, 14)


# Shared shape both _slip_panel_style() above and ticket 06's
# _action_card_panel_style() (below) build a StyleBoxFlat from -- 1px border
# on all four sides, one corner radius, one margin per axis. Only the fill/
# border colour, radius and margins actually differ between the slip and the
# Train button's card, so those are the only params.
func _bordered_panel_style(fill: Color, border_color: Color, corner_radius: int, margin_h: int, margin_v: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = border_color
	style.set_corner_radius_all(corner_radius)
	style.content_margin_left = margin_h
	style.content_margin_top = margin_v
	style.content_margin_right = margin_h
	style.content_margin_bottom = margin_v
	return style


# The raid line's "stamped/red-ink annotation" (§5): a small rotated box in
# ui_action_red wrapping the same "Raid risk: NN%" text the old plain
# muted_label used, rather than a separate card/section.
func _build_raid_stamp(raid_pct: int) -> Control:
	var accent := _action_color()

	var stamp := _SlipStamp.new()
	stamp.ink_color = accent
	stamp.rotation_degrees = _STAMP_ROTATION_DEGREES
	stamp.add_theme_constant_override("margin_left", 10)
	stamp.add_theme_constant_override("margin_top", 6)
	stamp.add_theme_constant_override("margin_right", 10)
	stamp.add_theme_constant_override("margin_bottom", 6)

	var raid_label := UI.label("Raid risk: %d%%" % raid_pct)
	raid_label.add_theme_color_override("font_color", accent)
	stamp.add_child(raid_label)

	return stamp


# Hand-drawn ruled underline beneath the slip's "Ore store" heading -- short
# segments with a small alternating y-jitter instead of one perfectly
# straight line, reading as a pen stroke rather than a printed rule.
# Shared by _SlipRule/_SlipStamp below -- both hand-wobbled shapes are just
# a run of straight segments between points, drawn on whichever CanvasItem
# is currently drawing itself.
static func _draw_ink_polyline(target: CanvasItem, points: PackedVector2Array, ink_color: Color) -> void:
	for i in range(points.size() - 1):
		target.draw_line(points[i], points[i + 1], ink_color, 1.5)


class _SlipRule extends Control:
	var ink_color: Color = _SLIP_INK

	func _draw() -> void:
		if size.x <= 0:
			return
		var segments := 5
		var jitter_amount := 1.5
		var y: float = size.y * 0.5
		var seg_w: float = size.x / float(segments)
		var points := PackedVector2Array()
		for i in range(segments + 1):
			var jitter: float = 0.0
			if i > 0 and i < segments:
				jitter = jitter_amount if i % 2 == 0 else -jitter_amount
			points.append(Vector2(seg_w * i, y + jitter))
		ModalLayer._draw_ink_polyline(self, points, ink_color)


# Wobbled rectangle border for the raid-risk stamp -- eight hand-uneven
# points instead of StyleBoxFlat's clean rect border, which would just read
# as another printed UI chip rather than something inked onto the slip.
# Extends MarginContainer (not bare Control) so it sizes itself to its
# label child + the margins _build_raid_stamp() sets, the same way
# UI.card()'s PanelContainer sizes around its content.
class _SlipStamp extends MarginContainer:
	# Always overwritten by _build_raid_stamp() with _action_color() before
	# this node is shown -- points at the same named fallback constant
	# (rather than repeating its literal) purely so there's no bare, unused
	# accent-red literal sitting in this file a second time.
	var ink_color: Color = ModalLayer._ACTION_COLOR_FALLBACK

	func _draw() -> void:
		var w: float = size.x
		var h: float = size.y
		if w <= 0 or h <= 0:
			return
		var points := PackedVector2Array([
			Vector2(2, 2), Vector2(w * 0.5, 0), Vector2(w - 2, 3),
			Vector2(w - 1, h * 0.5), Vector2(w - 3, h - 2),
			Vector2(w * 0.5, h - 1), Vector2(1, h - 3), Vector2(2, h * 0.5),
			Vector2(2, 2),
		])
		ModalLayer._draw_ink_polyline(self, points, ink_color)


# field-kit-chrome ticket 06, ui-vision.md §5's component table ("HQ Train
# panel: Generic Family-4 chrome, no bespoke object"): Train carries no
# inherent diegetic identity of its own (unlike the estate-agent floorplan
# or the inventory-slip ore readout sharing this file), so per §5 it gets
# the *same* plain field-kit card+button treatment ticket 05 already gave
# the combat action cards, not just the same accent colour -- a UI.card()
# panel (cream fill, accent border, corner radius) wrapping a borderless
# button whose only accent is a hover/pressed wash, mirroring combat.gd's
# _build_action_card()/_action_card_button_style() layer split exactly
# (panel carries the border, the button doesn't) rather than putting a
# border straight on a bare button, which would read as its own bespoke
# boxed control instead of the shared chrome. Locked `ui_action_red`
# replaces the default theme Button's amber fill (main_theme.tres
# StyleBoxFlat_btn_normal, reserved for calc/cash reads only per §6) --
# rather than a bespoke workout-app object (explicitly scrapped, §5 session
# note). Close is left alone: it's the same generic dismiss control every
# other modal in this file builds via a bare UI.button("Close", ...), which
# is ModalLayer's own shared chrome and explicitly out of scope for this
# family (§5: "The shared ModalLayer... dialog card is out of scope
# here... not owned by any single family").
const _ACTION_COLOR_FALLBACK := Color(0.784314, 0.062745, 0.180392, 1)
const _ACTION_DISABLED_COLOR := Color(0.541176, 0.541176, 0.541176, 1)
const _ACTION_CARD_FILL := Color(0.980392, 0.972549, 0.952941, 1)

func _action_color() -> Color:
	return GameData.PALETTE.get("ui_action_red", _ACTION_COLOR_FALLBACK)


func _action_card_panel_style(accent: Color) -> StyleBoxFlat:
	return _bordered_panel_style(_ACTION_CARD_FILL, accent, 10, 16, 16)


func _action_button_style(accent: Color, alpha: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(accent.r, accent.g, accent.b, alpha)
	style.set_corner_radius_all(8)
	style.content_margin_left = 8
	style.content_margin_top = 6
	style.content_margin_right = 8
	style.content_margin_bottom = 6
	return style


func _style_action_button(b: Button, accent: Color) -> void:
	b.add_theme_stylebox_override("normal", _action_button_style(accent, 0.0))
	b.add_theme_stylebox_override("hover", _action_button_style(accent, 0.14))
	b.add_theme_stylebox_override("pressed", _action_button_style(accent, 0.22))
	b.add_theme_stylebox_override("disabled", _action_button_style(accent, 0.0))
	b.add_theme_color_override("font_color", accent)
	b.add_theme_color_override("font_hover_color", accent)
	b.add_theme_color_override("font_pressed_color", accent)
	b.add_theme_color_override("font_disabled_color", accent)


# hq-diorama ticket 02: Gym is wired into the bedsit plate despite §3.1's
# "First tier present: flat" (see hq.gd's own top comment and this
# manifest's "gymDeviation" meta note for why) -- carried over unchanged
# from hq.gd's old _build_gym_card(). squad-combat ticket 05: Train is the
# Home Gym's repeatable action -- unrelated to (and doesn't replace) the
# room's own one-time +10 hpMax build bonus (Home.add_room()), which fires
# the moment the room is bought. Train is always available (no gym needed
# to throw a bodyweight workout); building the Home Gym just raises the flat
# XP amount it awards, per Combat.train().
# PROSE-REVIEW: new flavour text, tone bible per docs/CONTENT-GUIDE.md.
func _build_hq_gym() -> void:
	var player: Dictionary = GameState.state["player"]
	var has_gym: bool = GameState.state["home"]["rooms"].has("homeGym")
	_card_content.add_child(UI.heading("Gym", 14))
	_card_content.add_child(UI.label("Combat Skill: Lv%d (%d XP)" % [player["combatSkill"], player["combatXP"]]))
	if not has_gym:
		_card_content.add_child(UI.muted_label("Build a Home Gym to get more out of each workout."))
	_card_content.add_child(_build_train_button())
	_card_content.add_child(UI.button("Close", func(): Modal.close()))


func _build_train_button() -> Control:
	var disabled: bool = TimeSystem.is_time_exhausted()
	var accent: Color = _ACTION_DISABLED_COLOR if disabled else _action_color()

	var c := UI.card()
	c["panel"].add_theme_stylebox_override("panel", _action_card_panel_style(accent))

	var b := UI.button("Train", func(): Combat.train())
	b.disabled = disabled
	_style_action_button(b, accent)
	c["content"].add_child(b)

	return c["panel"]


# ── hq-diorama ticket 07: Lab bench modals ────────────────────────────
#
# The bench's own notebook content and probe feedback, all reached from
# scenes/screens/hq_lab_bench.gd rather than a full drill-down screen (that
# screen, lab.gd, plus systems/bench_nav.gd, are all deleted this ticket --
# see hq_lab_bench.gd's own top comment). Recipe rows and the notes/history
# rendering below are lab.gd's old _build_recipe_card()/_build_notes_card()/
# _history_line() moved here near-verbatim, since a modal card is the same
# shape a screen card was.

# Ticket 07, §5.2/§5.6: the Recipes-mode book path -- pick a known recipe
# and a quantity, craft -- plus refinement (§5.6: "a recipe-page action in
# the book, not a fifth apparatus"), both per recipe row. Crafting a batch
# or refining from here re-opens *this* modal's own content on the next
# EventBus.state_changed (Crafting.attempt_craft_batch opens its own
# "craft_batch_result" modal on top, which replaces this one when it fires
# -- closing that result modal returns to the bare bench, not back into the
# book; re-tapping "Recipe book" reopens it. Bench.refine() opens no modal
# of its own, so a refine tap re-renders this same book in place instead).
func _build_lab_bench_recipe_book() -> void:
	_card_content.add_child(UI.heading("Recipe book"))
	var found := Bench.found_recipe_keys()
	if found.is_empty():
		_card_content.add_child(UI.muted_label("Nothing found yet."))
	else:
		for recipe_key in found:
			_card_content.add_child(_build_lab_bench_recipe_row(recipe_key))
	_card_content.add_child(UI.button("Close", func(): Modal.close()))


func _build_lab_bench_recipe_row(recipe_key: String) -> Control:
	var player: Dictionary = GameState.state["player"]
	var skill: int = player["craftingSkill"]
	var r: Dictionary = GameData.RECIPES[recipe_key]
	var costs: Dictionary = Crafting.calc_cost(recipe_key, skill)
	var chance: float = Crafting.craft_chance(recipe_key, skill)
	var power = Crafting.effect_power(recipe_key, skill)
	var can_make: bool = Crafting.can_craft(recipe_key)
	var stock: int = Crafting.inventory_qty(recipe_key)

	var c := UI.card()
	c["content"].add_child(UI.symbol_row([{ "symbol": r["symbol"], "fallback": SymbolGlyph.generic_fallback() }, r["name"]], { "heading_size": 15 }))
	c["content"].add_child(UI.muted_label(r["description"]))
	for ingredient in costs:
		var have: int = player["orichalchum"].get(ingredient, 0)
		var ore: Dictionary = GameData.ORE_TYPES[ingredient]
		c["content"].add_child(UI.symbol_row(["Ingredient: ", { "symbol": ore["symbol"], "fallback": SymbolGlyph.ore_fallback(ingredient) }, " %s — %d/%d" % [ore["name"], have, costs[ingredient]]]))
	c["content"].add_child(UI.label("Success: %d%%   Effect: %s   Stock: %d" % [int(round(chance * 100)), str(power), stock]))

	var qty: int = Crafting.get_craft_qty(recipe_key)
	var qty_row := UI.hbox()
	qty_row.add_child(UI.label("Batch:"))
	qty_row.add_child(UI.button("-", func(): Crafting.adjust_craft_qty(recipe_key, -1)))
	qty_row.add_child(UI.label(str(qty)))
	qty_row.add_child(UI.button("+", func(): Crafting.adjust_craft_qty(recipe_key, 1)))
	c["content"].add_child(qty_row)

	var craft_btn := UI.button("Craft ×%d" % qty, func(): Crafting.attempt_craft_batch(recipe_key, qty))
	craft_btn.disabled = not can_make
	c["content"].add_child(craft_btn)

	# §5.6: refinement stays a recipe-page action in the book, not a fifth
	# apparatus. Every Lab-discovered recipe carries a `discovery` cell
	# (M3 §9.2 -- the tutorial-taught three do too), so refine is reachable
	# from every row this list shows.
	var discovery: Dictionary = r.get("discovery", {})
	if not discovery.is_empty():
		_append_lab_bench_refine_controls(c["content"], r, discovery["types"], discovery["approach"])

	return c["panel"]


# Shared by the Recipe book's per-recipe page above and the Experiments
# notebook's found-recipe rows below (ticket 102) -- same one-tap refine
# action, one place for the button/disabled-reason wiring.
func _append_lab_bench_refine_controls(container: Control, recipe: Dictionary, types: Array, approach: String) -> void:
	var tier := Bench.refine_tier_target(types, approach)
	var reason := Bench.refine_block_reason(types, approach)
	var refine_btn := UI.button("Refine to tier %d" % tier, func(): _on_lab_bench_refine_pressed(recipe["name"], types, approach, tier))
	refine_btn.disabled = reason != ""
	container.add_child(refine_btn)
	if reason != "":
		container.add_child(UI.muted_label(reason))


# PROSE-REVIEW: new notification lines, tone bible per docs/CONTENT-GUIDE.md.
func _on_lab_bench_refine_pressed(recipe_name: String, types: Array, approach: String, tier: int) -> void:
	var result := Bench.refine(types, approach)
	if result.get("outcome", "") == "refined":
		Notify.push("%s refined to tier %d." % [recipe_name, tier], Notify.CATEGORY_SUCCESS)
	else:
		Notify.push("No improvement this time. Still tier %d." % (tier - 1), Notify.CATEGORY_WARNING)


# Ticket 07, §5.2 point 2: "The Experiments notebook is tappable here -- a
# panel of pairings already tried and their results, and current recipe
# levels." Moved from lab.gd's old _build_notes()/_build_notes_card()
# near-verbatim -- only pairings Bench.touched_type_sets() reports appear,
# never the full 15 type sets (M3 §8.0/hq-diorama-vision.md §5.6).
func _build_lab_bench_notes() -> void:
	_card_content.add_child(UI.heading("Bench notes"))
	var touched := Bench.touched_type_sets()
	if touched.is_empty():
		_card_content.add_child(UI.muted_label("Nothing recorded yet."))  # PROSE-REVIEW: new empty-state line, tone bible per docs/CONTENT-GUIDE.md.
	else:
		for types in touched:
			_card_content.add_child(_build_lab_bench_notes_card(types))
	_card_content.add_child(UI.button("Close", func(): Modal.close()))


func _build_lab_bench_notes_card(types: Array) -> Control:
	var c := UI.card()
	c["content"].add_child(UI.heading(_lab_bench_pairing_label(types), 15))
	c["content"].add_child(UI.label("%d/%d" % [Bench.found_count_in_set(types), Bench.get_surveyed_count(types)]))
	for row in _lab_bench_found_recipe_rows(types):
		c["content"].add_child(row)
	for entry in Bench.notes_for(types):
		c["content"].add_child(UI.muted_label(_lab_bench_history_line(entry)))
	return c["panel"]


# "...and current recipe levels" (§5.2 point 2) -- one row per approach this
# pairing has Found a recipe on, naming it and its refine tier (Bench.get_
# cell()["refine"], 0 until the first successful refine), plus (ticket 102)
# the same one-tap "Refine to tier N" action the Recipe book exposes -- the
# notebook is read-only history everywhere else, but a Found recipe's own
# ore + apparatus combo is already fully established, so there's no picker
# to run first. Walks every approach rather than asking Bench for a
# pairing's found recipes directly: Bench has no such getter (only a total
# count via found_count_in_set()), and this is the same per-approach scan
# hq_lab_bench.gd's own apparatus-arming label already does.
func _lab_bench_found_recipe_rows(types: Array) -> Array:
	var rows: Array = []
	for approach_id in GameData.APPROACHES.keys():
		var recipe_key := Bench.find_recipe_for_cell(types, approach_id)
		if recipe_key == "" or Bench.cell_state(types, approach_id) != "found":
			continue
		var r: Dictionary = GameData.RECIPES[recipe_key]
		var tier: int = Bench.get_cell(types, approach_id)["refine"]
		var row := UI.vbox(4)
		row.add_child(UI.symbol_row([{ "symbol": r["symbol"], "fallback": SymbolGlyph.generic_fallback() }, "%s — tier %d" % [r["name"], tier]]))
		_append_lab_bench_refine_controls(row, r, types, approach_id)
		rows.append(row)
	return rows


func _lab_bench_pairing_label(types: Array) -> String:
	var names: Array[String] = []
	for type_id in types:
		names.append(String(type_id).capitalize())
	if names.size() == 1:
		return names[0]
	return "%s and %s" % [names[0], names[1]]


# PROSE-REVIEW: new history-line template, tone bible per docs/CONTENT-GUIDE.md.
func _lab_bench_history_line(entry: Dictionary) -> String:
	var approach_name: String = GameData.APPROACHES[entry["approach"]]["name"]
	return "Day %d — %s: %s" % [entry["day"], approach_name, _lab_bench_outcome_heading(entry["outcome"])]


# Shared by the notes history line above and the probe-result heading below
# -- the same five outcome words, one vocabulary, reviewed once.
# PROSE-REVIEW: tone bible per docs/CONTENT-GUIDE.md.
func _lab_bench_outcome_heading(outcome: String) -> String:
	match outcome:
		"found":
			return "Found it."
		"hot":
			return "Something's there."
		"inert":
			return "Inert."
		"refined":
			return "Refined."
		"refine_failed":
			return "No better this time."
		_:
			return ""


# Ticket 07, §5.2 point 4: "It animates, consumes ore, and reports the
# outcome." No animation this ticket (ticket 08's own scope, §5.5) -- the
# outcome is reported the instant Bench.probe() returns, same "mutation
# already happened, this is only the reveal" shape every other instant-
# feedback modal in this file uses (_build_craft_result() etc.). Only ever
# opened with outcome found/hot/inert (Bench.probe()'s own roster) --
# refined/refine_failed come from Bench.refine(), handled inline by the
# recipe book above instead.
func _build_lab_bench_probe_result(data: Dictionary) -> void:
	_card_content.add_child(UI.heading(_lab_bench_outcome_heading(data.get("outcome", ""))))
	_card_content.add_child(UI.symbol_row(_lab_bench_probe_prose_parts(data)))
	_card_content.add_child(UI.button("Got it", func(): Modal.close()))


# PROSE-REVIEW: outcome prose, tone bible per docs/CONTENT-GUIDE.md. Register
# per M3 §8.4: found is the payoff (name, symbol, what it does), hot is a
# lure that says plainly something's there, inert lands flat.
func _lab_bench_probe_prose_parts(data: Dictionary) -> Array:
	match data.get("outcome", ""):
		"found":
			var r: Dictionary = GameData.RECIPES[data["recipeKey"]]
			return [{ "symbol": r["symbol"], "fallback": SymbolGlyph.generic_fallback() }, "%s. %s Craftable now." % [r["name"], r["description"]]]
		"hot":
			return ["Something's in there. It didn't come out this time."]
		"inert":
			return ["Nothing in it. Never was."]
		_:
			return [""]


# Item-use during combat used to be a modal here ("combat_items"); D4.4's
# BagDrawer (scenes/components/bag_drawer.gd) replaces it — combat.gd's
# "Item" button now opens that instead of a modal.

# Deferred: room_detail (manage/assign a built room) and a *generic*
# confirm dialog. state.modal.data can't hold a Callable (state purity,
# R§2), so a reusable "confirm with an arbitrary callback" modal still
# isn't possible under this schema. collective1-05's _build_sell_vein_quote
# above is the first per-action-type confirm built on that same dispatch
# shape (modal.type = "sell_vein_quote", data = {veinId, price, factionId})
# — any future destructive action needing a confirm step follows the same
# pattern rather than waiting on a generic solution.

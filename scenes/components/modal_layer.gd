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
		ore_rows.append(_build_sell_row("%s %s (£%d/u, have %d)" % [ore["symbol"], ore["name"], ore["basePrice"], have], key, qty, have))

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
				item_rows.append(_build_sell_row("%s %s (%s, £%d/ea, have %d)" % [recipe["symbol"], recipe["name"], tier_label, price, have], key, qty, have))

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
			var vein_label := "%s — %s %s (£%d)" % [vein_district["name"], vein_ore["symbol"], vein_ore["name"], vein_price]
			asset_rows.append(_build_sell_vein_row(vein_label, vein["id"], selected))

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
		ore_rows.append(_build_sell_row("%s %s (£%d/u, have %d)" % [ore["symbol"], ore["name"], price, have], key, qty, have))

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
				item_rows.append(_build_sell_row("%s %s (%s, £%d/ea, have %d)" % [recipe["symbol"], recipe["name"], tier_label, price, have], key, qty, have))

	# vein-trade-assets ticket 01, spec: the faction lane's Assets section --
	# every player-owned vein as a 0/1 include/exclude row (not a +/- stepper,
	# a vein isn't stackable), priced at the same VeinTrade.quote() the
	# standalone vein-list Sell flow already uses. A selected vein folds
	# straight into this trade's gross/Go tap; there's no separate per-vein
	# confirm step here (that guard is the Go button's own label below).
	var asset_rows: Array = []
	var veins_selected := 0
	var buy_cost := 0
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
			var vein_label := "%s — %s %s (£%d)" % [vein_district["name"], vein_ore["symbol"], vein_ore["name"], vein_price]
			asset_rows.append(_build_sell_vein_row(vein_label, vein["id"], selected))

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
			var buy_label := "Buy: %s — %s %s (£%d)" % [buy_district["name"], buy_ore["symbol"], buy_ore["name"], buy_price]
			asset_rows.append(_build_buy_vein_row(buy_label, faction_vein["id"], buy_selected))

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
# _build_sell_row's -/+ stepper -- a vein isn't stackable.
func _build_sell_vein_row(label_text: String, vein_id: String, selected: bool) -> Control:
	var row := UI.hbox(6)
	row.add_child(UI.button("☑" if selected else "☐", func(): Economy.toggle_sell_vein(vein_id)))
	var text_label := UI.label(label_text)
	text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text_label)
	return row


# vein-trade-assets ticket 03: the buy-side counterpart -- same 0/1 toggle
# shape, wired to Economy.toggle_buy_vein() instead.
func _build_buy_vein_row(label_text: String, vein_id: String, selected: bool) -> Control:
	var row := UI.hbox(6)
	row.add_child(UI.button("☑" if selected else "☐", func(): Economy.toggle_buy_vein(vein_id)))
	var text_label := UI.label(label_text)
	text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text_label)
	return row


func _build_sell_row(label_text: String, key: String, qty: int, max_qty: int) -> Control:
	var row := UI.hbox()
	var text_label := UI.label(label_text)
	# Same fix as UI.message_bubble()/checklist_row(): a non-expand
	# autowrapping Label's minimum size collapses to ~1px, so without this
	# it renders as a 1px-wide column with the text overflowing across the
	# "-"/qty/"+" controls that follow it in this row.
	text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text_label)
	# Bugfixes ticket 13: this was "−" (U+2212 MINUS SIGN), the same
	# invisible-non-ASCII-glyph bug as the map top bar's "☰"/"🎒", and
	# unlike its "+" sibling it had no fallback text to keep the button
	# legible. ASCII "-" renders correctly.
	row.add_child(UI.button("-", func(): Economy.adjust_sell_qty(key, -1, max_qty)))
	row.add_child(UI.label(str(qty)))
	row.add_child(UI.button("+", func(): Economy.adjust_sell_qty(key, 1, max_qty)))
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
		_card_content.add_child(UI.label("%s %s ×%d — £%d/ea — total £%d — needed by day %d" % [job["symbol"], job["recipeName"], job["qty"], job["payPerItem"], job["totalPay"], job["byDay"]]))
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
	_card_content.add_child(_legend_row("⌂ pin", "Home. Taps through to HQ."))
	_card_content.add_child(_legend_row("✉ pin", "Someone's waiting on you there."))
	_card_content.add_child(_legend_row("Padlocked pin", "The Soho market. Not yet."))
	_card_content.add_child(_legend_row("Amber ring", "Where you are right now."))
	_card_content.add_child(UI.button("Close", func(): Modal.close()))


func _legend_row(glyph_label: String, description: String) -> Control:
	var row := UI.vbox(2)
	row.add_child(UI.label(glyph_label))
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
	_card_content.add_child(UI.label("%s %s vein — £%d." % [ore["symbol"], ore["name"], price]))
	_card_content.add_child(UI.muted_label("It stops being yours. Someone else's line, someone else's cut, from here on."))
	_card_content.add_child(UI.button("Confirm sale", func(): _on_sell_vein_confirm(vein_id)))
	_card_content.add_child(UI.button("Cancel", func(): Modal.close()))


func _on_sell_vein_confirm(vein_id: String) -> void:
	VeinTrade.sell_to_faction(vein_id, VeinTrade.SELL_FACTION_ID)
	Modal.close()


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

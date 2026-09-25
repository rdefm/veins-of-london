# Harrow's: current HQ tier card (with buy-out when rented, and the arrears
# balance and countdown while in arrears), then listings for the next tier up
# and the tier below (docs/hq-diorama-vision.md §7, ADR 0006). Tapping a
# listing opens its particulars: floor plan, the tier's `particulars` copy and
# the Rent/Buy offers, which appear only there.
#
# PROSE-REVIEW: tenure, rent/buy, buy-out, move-down, room-wipe and arrears strings.
class_name PropertyApp
extends PhoneApp

const LISTING_NODE_PREFIX := "Listing_"

# Tier id whose particulars are open; "" shows the listings. View state only.
var _open_tier_id: String = ""


static func listing_node_name(tier_id: String) -> String:
	return LISTING_NODE_PREFIX + tier_id


func build(content: VBoxContainer) -> void:
	var tier_id: String = GameState.state["home"]["tier"]
	var next_id: String = Home.get_next_tier_id(tier_id)
	var prev_id: String = Home.get_prev_tier_id(tier_id)
	if _open_tier_id != "" and _open_tier_id == next_id:
		_build_particulars(content, "NEXT UP", next_id, Home.rent_up, Home.buy_up)
		return
	if _open_tier_id != "" and _open_tier_id == prev_id:
		_build_particulars(content, "MOVE DOWN", prev_id, Home.downgrade.bind(Home.TENURE_RENTED), Home.downgrade.bind(Home.TENURE_OWNED))
		return
	_open_tier_id = ""

	content.add_child(back_button())
	content.add_child(UI.heading("Harrow's"))
	content.add_child(_build_current_card())
	if next_id == "":
		var c := UI.card()
		c["content"].add_child(UI.muted_label("NEXT UP"))
		c["content"].add_child(UI.muted_label("Top of the ladder. Nowhere further to move."))
		content.add_child(c["panel"])
	else:
		content.add_child(_build_listing_card("NEXT UP", next_id))
	if prev_id != "":
		content.add_child(_build_listing_card("MOVE DOWN", prev_id))


func _build_current_card() -> Control:
	var home: Dictionary = GameState.state["home"]
	var tier_id: String = home["tier"]
	var tier: Dictionary = GameData.HOME_TIERS[tier_id]
	var raid_pct: int = int(round(Home.get_home_raid_chance() * 100))
	var rented: bool = home["tenure"] == Home.TENURE_RENTED

	var c := UI.card()
	c["content"].add_child(UI.muted_label("YOUR PLACE"))
	c["content"].add_child(UI.heading(tier["name"], 14))
	c["content"].add_child(UI.muted_label(tier["description"]))
	c["content"].add_child(UI.label("Daily cost: £%d · Raid risk: %d%% · Rooms %d/%d" % [Home.current_bill_base(), raid_pct, home["rooms"].size(), tier["maxRooms"]]))
	c["content"].add_child(UI.muted_label("Rented." if rented else "Owned outright."))
	var countdown: Dictionary = Home.arrears_countdown()
	if not countdown.is_empty():
		c["content"].add_child(UI.label("Arrears: £%d" % countdown["arrears"]))
		for line in MorningAccounts.countdown_lines(countdown):
			c["content"].add_child(UI.muted_label(line))
	if rented and Home.can_buy_tier(tier_id):
		var price: int = Home.buy_price(tier_id)
		_add_purchase_button(c["content"], "Buy out for £%d" % price, price, Home.buy_out)
		c["content"].add_child(UI.muted_label("Then £%d/day in utilities. Rooms stay." % Home.bill_base_for(tier_id, Home.TENURE_OWNED)))
	_add_static_plan(c["content"], tier_id)
	return c["panel"]


# A listing is the card plus a flat overlay button covering it, so the whole
# card is the tap target and a scroll drag still cancels the press.
func _build_listing_card(caption: String, tier_id: String) -> Control:
	var tier: Dictionary = GameData.HOME_TIERS[tier_id]
	var c := UI.card()
	c["content"].add_child(UI.muted_label(caption))
	c["content"].add_child(UI.heading(tier["name"], 14))
	c["content"].add_child(UI.muted_label(tier["description"]))
	c["content"].add_child(_tier_stats_label(tier_id))
	c["content"].add_child(UI.muted_label("Tap for particulars ›"))
	var tap := Button.new()
	tap.name = listing_node_name(tier_id)
	tap.flat = true
	tap.focus_mode = Control.FOCUS_NONE
	tap.pressed.connect(_open_particulars.bind(tier_id))
	c["panel"].add_child(tap)
	return c["panel"]


func _build_particulars(content: VBoxContainer, caption: String, tier_id: String, on_rent: Callable, on_buy: Callable) -> void:
	var tier: Dictionary = GameData.HOME_TIERS[tier_id]
	content.add_child(UI.button("‹ Listings", _open_particulars.bind("")))
	content.add_child(UI.muted_label(caption))
	content.add_child(UI.heading(tier["name"]))
	_add_static_plan(content, tier_id)
	content.add_child(UI.label(tier["particulars"]))
	content.add_child(_tier_stats_label(tier_id))

	var c := UI.card()
	c["content"].add_child(UI.button("Rent for £%d/day" % Home.bill_base_for(tier_id, Home.TENURE_RENTED), _close_then.bind(on_rent)))
	if Home.can_buy_tier(tier_id):
		var price: int = Home.buy_price(tier_id)
		_add_purchase_button(c["content"], "Buy for £%d" % price, price, _close_then.bind(on_buy))
		c["content"].add_child(UI.muted_label("Then £%d/day in utilities." % Home.bill_base_for(tier_id, Home.TENURE_OWNED)))

	c["content"].add_child(UI.muted_label("Moving clears every installed room. No refunds."))
	var lost: Array[String] = []
	for security_id in Home.security_lost_moving_to(tier_id):
		lost.append(GameData.HOME_SECURITY[security_id]["name"])
	var guards: int = Home.guards_lost_moving_to(tier_id)
	if guards > 0:
		lost.append("%d guard%s" % [guards, "" if guards == 1 else "s"])
	if not lost.is_empty():
		c["content"].add_child(UI.muted_label("Left behind: %s." % ", ".join(lost)))
	content.add_child(c["panel"])


func _tier_stats_label(tier_id: String) -> Label:
	var raid_pct: int = int(round(Home.get_raid_chance_for_tier(tier_id) * 100))
	return UI.label("Raid risk: %d%% · Rooms %d" % [raid_pct, GameData.HOME_TIERS[tier_id]["maxRooms"]])


func _open_particulars(tier_id: String) -> void:
	_open_tier_id = tier_id
	refresh()


# The move changes which tiers are next/prev, so the listings come back first.
func _close_then(action: Callable) -> void:
	_open_tier_id = ""
	action.call()
	refresh()


func _add_purchase_button(content: VBoxContainer, text: String, price: int, on_press: Callable) -> void:
	var b := UI.button(text, on_press)
	b.disabled = GameState.state["player"]["cash"] < price
	content.add_child(b)
	if b.disabled:
		content.add_child(UI.muted_label("Not enough cash."))


# Plans are read-only here; rooms are bought on HQ's noticeboard (§7).
func _add_static_plan(content: VBoxContainer, tier_id: String) -> void:
	if FloorplanView.has_plan(tier_id):
		content.add_child(FloorplanView.build(tier_id))

# Harrow's: current HQ tier card (with buy-out when rented), the next tier's
# rent/buy offer and the tier below's move-down offer
# (docs/hq-diorama-vision.md §7, ADR 0006).
#
# PROSE-REVIEW: tenure, rent/buy, buy-out, move-down and room-wipe strings.
class_name PropertyApp
extends PhoneApp


func build(content: VBoxContainer) -> void:
	content.add_child(back_button())
	content.add_child(UI.heading("Harrow's"))
	content.add_child(_build_current_card())
	content.add_child(_build_next_card())
	var prev_id: String = Home.get_prev_tier_id(GameState.state["home"]["tier"])
	if prev_id != "":
		content.add_child(_build_move_card("MOVE DOWN", prev_id, Home.downgrade.bind(Home.TENURE_RENTED), Home.downgrade.bind(Home.TENURE_OWNED)))


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
	if rented and Home.can_buy_tier(tier_id):
		var price: int = Home.buy_price(tier_id)
		_add_purchase_button(c["content"], "Buy out for £%d" % price, price, Home.buy_out)
		c["content"].add_child(UI.muted_label("Then £%d/day in utilities. Rooms stay." % Home.bill_base_for(tier_id, Home.TENURE_OWNED)))
	_add_static_plan(c["content"], tier_id)
	return c["panel"]


func _build_next_card() -> Control:
	var next_id: String = Home.get_next_tier_id(GameState.state["home"]["tier"])
	if next_id == "":
		var c := UI.card()
		c["content"].add_child(UI.muted_label("NEXT UP"))
		c["content"].add_child(UI.muted_label("Top of the ladder. Nowhere further to move."))
		return c["panel"]
	return _build_move_card("NEXT UP", next_id, Home.rent_up, Home.buy_up)


func _build_move_card(caption: String, tier_id: String, on_rent: Callable, on_buy: Callable) -> Control:
	var tier: Dictionary = GameData.HOME_TIERS[tier_id]
	var raid_pct: int = int(round(Home.get_raid_chance_for_tier(tier_id) * 100))

	var c := UI.card()
	c["content"].add_child(UI.muted_label(caption))
	c["content"].add_child(UI.heading(tier["name"], 14))
	c["content"].add_child(UI.muted_label(tier["description"]))
	c["content"].add_child(UI.label("Raid risk: %d%% · Rooms %d" % [raid_pct, tier["maxRooms"]]))
	_add_static_plan(c["content"], tier_id)

	c["content"].add_child(UI.button("Rent for £%d/day" % Home.bill_base_for(tier_id, Home.TENURE_RENTED), on_rent))
	if Home.can_buy_tier(tier_id):
		var price: int = Home.buy_price(tier_id)
		_add_purchase_button(c["content"], "Buy for £%d" % price, price, on_buy)
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
	return c["panel"]


func _add_purchase_button(content: VBoxContainer, text: String, price: int, on_press: Callable) -> void:
	var b := UI.button(text, on_press)
	b.disabled = GameState.state["player"]["cash"] < price
	content.add_child(b)
	if b.disabled:
		content.add_child(UI.muted_label("Not enough cash."))


# Listings show the tier's plan read-only; rooms are bought on HQ's noticeboard (§7).
func _add_static_plan(content: VBoxContainer, tier_id: String) -> void:
	if FloorplanView.has_plan(tier_id):
		content.add_child(FloorplanView.build(tier_id))

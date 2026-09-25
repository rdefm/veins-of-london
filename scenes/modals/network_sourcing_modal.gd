class_name NetworkSourcingModal
extends RefCounted

# The handler's Sourcing product (collective-act2 spec §5.3): pick an ore
# type and a minimum tier, pay, and the site arrives as a handler text.


static func build(container: VBoxContainer, _data: Dictionary) -> void:
	container.add_child(UI.heading("Sourcing"))
	container.add_child(UI.muted_label("Say what you want in the ground. The handler finds one."))

	var ore_ids: Array = GameData.ORE_TYPES.keys()
	var ore_names: Array = []
	for ore_id in ore_ids:
		ore_names.append(GameData.ORE_TYPES[ore_id]["name"])
	var ore_pick := UI.option_button(ore_names)
	container.add_child(ore_pick)

	var tier_names: Array = []
	for tier in NetworkHandler.SOURCING_TIERS:
		tier_names.append("At least %s" % tier.capitalize())
	var tier_pick := UI.option_button(tier_names)
	container.add_child(tier_pick)

	var price_label := UI.label("")
	container.add_child(price_label)
	var status := UI.label("")
	container.add_child(status)

	var update_price := func(_index: int = 0) -> void:
		var price := NetworkHandler.sourcing_price(ore_ids[ore_pick.selected], NetworkHandler.SOURCING_TIERS[tier_pick.selected])
		price_label.text = "£%d" % price
	update_price.call()
	ore_pick.item_selected.connect(update_price)
	tier_pick.item_selected.connect(update_price)

	var place := MapCardStyle.text_button("Place order", func():
		var result := NetworkHandler.buy_sourcing(ore_ids[ore_pick.selected], NetworkHandler.SOURCING_TIERS[tier_pick.selected])
		if not result.get("ok", false):
			status.text = result.get("reason", "")
			return
		Modal.close()
		Nav.go_to("phone")
		PhoneNav.select_conversation(NetworkHandler.CONTACT_ID)
	)
	container.add_child(MapCardStyle.footer([MapCardStyle.text_button("Close", func(): Modal.close()), place]))

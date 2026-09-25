class_name NadiaSupplyModal
extends RefCounted


static func build(container: VBoxContainer, data: Dictionary) -> void:
	var status := Collective.nadia_supply_status()
	var presentation: Dictionary = GameData.OBJECTIVES["col_a1_nadia_supply"].get("presentation", {})
	var stock: int = GameState.state["player"]["orichalchum"].get(status["oreType"], 0)
	var price: int = Economy.get_faction_sell_price("collective", "ore", status["oreType"])
	container.add_child(UI.heading(presentation.get("heading", "")))
	container.add_child(UI.label(presentation.get("delivered", "") % [status["delivered"], status["required"]]))
	container.add_child(UI.label(presentation.get("remaining", "") % status["remaining"]))
	container.add_child(UI.label(presentation.get("inStock", "") % [stock, GameData.ORE_TYPES[status["oreType"]]["name"]]))
	container.add_child(UI.label(presentation.get("pricePerUnit", "") % price))

	var qty := SpinBox.new()
	qty.min_value = 1
	qty.max_value = maxi(stock, 1)
	qty.step = 1
	qty.value = mini(maxi(status["remaining"], 1), maxi(stock, 1))
	qty.allow_greater = false
	qty.editable = stock > 0
	container.add_child(qty)

	var payment := UI.label("")
	container.add_child(payment)
	var update_payment := func(value: float) -> void:
		payment.text = presentation.get("payment", "") % (price * int(value))
	update_payment.call(qty.value)
	qty.value_changed.connect(update_payment)

	var on_supply := func():
		var result := Collective.supply_nadia(int(qty.value))
		if result.get("ok", false):
			Modal.open("sale_result", { "earned": result["earned"], "gross": result["earned"], "mugged": false })
	var supply := MapCardStyle.text_button(presentation.get("supply", ""), on_supply, stock <= 0)
	container.add_child(MapCardStyle.footer([MapCardStyle.text_button(presentation.get("cancel", ""), func(): Modal.close()), supply]))

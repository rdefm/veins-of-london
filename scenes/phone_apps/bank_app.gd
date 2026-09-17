# Reynard's: display-only cash balance plus the transaction log, newest first.
class_name BankApp
extends PhoneApp


func build(content: VBoxContainer) -> void:
	content.add_child(back_button())
	content.add_child(UI.heading("Reynard's"))
	content.add_child(_build_balance_card())

	var log: Array = GameState.state["bankLog"]
	if log.is_empty():
		content.add_child(UI.muted_label("No transactions yet."))
	else:
		for i in range(log.size() - 1, -1, -1):
			content.add_child(_build_transaction_row(log[i]))


func _build_balance_card() -> Control:
	var c := UI.card()
	c["content"].add_child(UI.muted_label("BALANCE"))
	c["content"].add_child(UI.tinted_label("£%d" % GameState.state["player"]["cash"], _calc_gold()))
	return c["panel"]


func _build_transaction_row(entry: Dictionary) -> Control:
	var c := UI.card()
	var amount: int = entry["amount"]
	var amount_text: String = "+£%d" % amount if amount >= 0 else "-£%d" % -amount
	var row := UI.hbox()
	row.add_child(UI.expand_fill(UI.label(entry["label"])))
	row.add_child(UI.tinted_label(amount_text, _calc_gold()))
	c["content"].add_child(row)
	c["content"].add_child(UI.muted_label("Day %d" % entry["day"]))
	return c["panel"]


func _calc_gold() -> Color:
	return GameData.PALETTE.get("calc_gold", Color("#d4af52"))

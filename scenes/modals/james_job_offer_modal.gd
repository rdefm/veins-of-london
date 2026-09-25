class_name JamesJobOfferModal
extends RefCounted


static func build(container: VBoxContainer, data: Dictionary) -> void:
	var job: Dictionary = data["job"]
	container.add_child(UI.heading("Job from James"))
	if job["type"] == "flatPay":
		container.add_child(UI.label("\"Need an extra pair of hands for an afternoon. Pays well.\""))
		container.add_child(UI.label("Costs 1 time block — £%d flat." % job["pay"]))
	else:
		container.add_child(UI.label("\"I need %d %s. Standard rate. Don't take too long about it.\"" % [job["qty"], job["recipeName"]]))
		container.add_child(UI.symbol_row([{ "symbol": job["symbol"], "fallback": SymbolGlyph.generic_fallback() }, "%s ×%d — £%d/ea — total £%d — needed by day %d" % [job["recipeName"], job["qty"], job["payPerItem"], job["totalPay"], job["byDay"]]]))
	container.add_child(MapCardStyle.footer([
		MapCardStyle.text_button("Decline", func(): decline()),
		MapCardStyle.text_button("Accept", func(): accept()),
	]))


static func accept() -> void:
	Jobs.accept_job()
	Modal.close()


static func decline() -> void:
	Modal.close()
	Jobs.decline_job()

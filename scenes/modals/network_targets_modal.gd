class_name NetworkTargetsModal
extends RefCounted

# The handler's Targets product (collective-act2 spec §5.3): one row per
# faction vein the Collective doesn't hold, each with the two questions the
# handler sells. The answer arrives as a text in the handler's thread.


static func build(container: VBoxContainer, _data: Dictionary) -> void:
	container.add_child(UI.heading("Targets"))
	container.add_child(UI.muted_label("Name a vein. You'll get a true answer, and pay for it either way."))
	var status := UI.label("")
	container.add_child(status)

	var site_ids := NetworkHandler.target_site_ids()
	if site_ids.is_empty():
		container.add_child(UI.label("Nothing out there worth asking about."))
	for site_id in site_ids:
		var site: Dictionary = Sites.find_site(site_id)
		var vein: Dictionary = site["factionVein"]
		var price := NetworkHandler.target_price(site_id)
		container.add_child(UI.label("%s · %s · %s" % [
			GameData.DISTRICTS[site["district"]]["name"],
			GameData.ORE_TYPES[vein["oreType"]]["name"],
			GameData.FACTIONS[vein["factionId"]]["name"],
		]))
		var row := UI.hbox(8)
		row.add_child(UI.button("Is it soft? £%d" % price, _buy.bind(site_id, NetworkHandler.EFFECT_CLAIM_BONUS, status)))
		row.add_child(UI.button("Delay guards £%d" % price, _buy.bind(site_id, NetworkHandler.EFFECT_SECURITY_FREEZE, status)))
		container.add_child(row)

	container.add_child(UI.button("Close", func(): Modal.close()))


static func _buy(site_id: String, effect: String, status: Label) -> void:
	var result := NetworkHandler.buy_target(site_id, effect)
	if not result.get("ok", false):
		status.text = result.get("reason", "")
		return
	Modal.close()
	Nav.go_to("phone")
	PhoneNav.select_conversation(NetworkHandler.CONTACT_ID)

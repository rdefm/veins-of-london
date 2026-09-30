class_name NetworkIntelModal
extends RefCounted

# The handler's intel menu (R§3.1 "Network intel menu"): one row per
# product at today's relation-adjusted price, locked below its relation
# gate. Targeted products read the faction picker; disinformation also reads
# the mode picker. Answers and confirmations arrive in the handler's thread.


static func build(container: VBoxContainer, _data: Dictionary) -> void:
	container.add_child(UI.heading("Intel"))
	container.add_child(UI.muted_label("Network relation %d. Prices move with it." % int(GameState.state["factions"]["network"]["relation"])))
	for line in _active_lines():
		container.add_child(UI.muted_label(line))
	var status := UI.label("")
	container.add_child(status)

	var faction_ids := NetworkHandler.intel_targets()
	var faction_names: Array = faction_ids.map(func(id: String) -> String: return GameData.FACTIONS[id]["name"])
	container.add_child(MapCardStyle.section_label("Faction"))
	var faction_pick := UI.option_button(faction_names)
	container.add_child(faction_pick)
	var modes := NetworkHandler.disinformation_modes()
	container.add_child(MapCardStyle.section_label("Disinformation"))
	var mode_pick := UI.option_button(modes.map(func(m: String) -> String: return NetworkHandler.disinformation_mode_label(m)))
	container.add_child(mode_pick)

	var picked := func() -> String: return faction_ids[faction_pick.selected]
	var buys := {
		NetworkHandler.PRODUCT_RAID_INTEL: func() -> Dictionary: return NetworkHandler.buy_raid_intel(),
		NetworkHandler.PRODUCT_RAID_WARNINGS: func() -> Dictionary: return NetworkHandler.buy_raid_warnings(),
		NetworkHandler.PRODUCT_MARKET_INTEL: func() -> Dictionary: return NetworkHandler.buy_market_intel(),
		NetworkHandler.PRODUCT_BOOST: func() -> Dictionary: return NetworkHandler.buy_intel_boost(picked.call()),
		NetworkHandler.PRODUCT_PRIVACY: func() -> Dictionary: return NetworkHandler.buy_privacy(),
		NetworkHandler.PRODUCT_DISINFORMATION: func() -> Dictionary: return NetworkHandler.buy_disinformation(picked.call(), modes[mode_pick.selected]),
		NetworkHandler.PRODUCT_REDUCTION: func() -> Dictionary: return NetworkHandler.buy_intel_reduction(picked.call()),
	}
	for product_id in NetworkHandler.PRODUCTS:
		var open := NetworkHandler.product_open(product_id)
		var reason := "" if open else "Needs Network relation %d" % NetworkHandler.product_min_relation(product_id)
		var text := "%s · £%d" % [NetworkHandler.product_name(product_id), NetworkHandler.product_price(product_id)]
		container.add_child(MapCardStyle.action_button(text, _buy.bind(buys[product_id], status), not open, reason))

	container.add_child(MapCardStyle.footer([MapCardStyle.text_button("Close", func(): Modal.close())]))


# Running raid warnings, privacy and disinformation, one line each.
static func _active_lines() -> Array[String]:
	var lines: Array[String] = []
	if Intel.raid_warnings_active(Shares.PLAYER):
		lines.append("Raid warnings until %s" % Calendar.format_day(Intel.raid_warnings_until(Shares.PLAYER)))
	if Intel.privacy_active(Shares.PLAYER):
		lines.append("Privacy until %s" % Calendar.format_day(Intel.privacy_until(Shares.PLAYER)))
	for faction_id in NetworkHandler.intel_targets():
		var mode := Intel.disinformation(faction_id, Shares.PLAYER)
		if mode != "":
			lines.append("%s: %s until %s" % [GameData.FACTIONS[faction_id]["name"], NetworkHandler.disinformation_mode_label(mode), Calendar.format_day(Intel.disinformation_until(faction_id, Shares.PLAYER))])
	return lines


static func _buy(buy: Callable, status: Label) -> void:
	var result: Dictionary = buy.call()
	if not result.get("ok", false):
		status.text = result.get("reason", "")
		return
	Modal.close()
	Nav.go_to("phone")
	PhoneNav.select_conversation(NetworkHandler.CONTACT_ID)

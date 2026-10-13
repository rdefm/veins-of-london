# Non-violent moves against one faction: file a complaint, tip off the
# police, leak to the Ticker. Each row shows cost and the reason it's
# unavailable; every move goes through PlayerMoves.
class_name PlayerMovesModal
extends RefCounted


static func build(container: VBoxContainer, data: Dictionary) -> void:
	var faction_id: String = data.get("factionId", "")
	container.add_child(UI.heading("Move against %s" % GameData.FACTIONS[faction_id]["shortName"]))
	var status := UI.label("")
	container.add_child(status)

	var site_ids: Array = _vein_site_ids(faction_id)
	var site_pick: OptionButton = null
	if not site_ids.is_empty():
		container.add_child(MapCardStyle.section_label("Vein (for complaints)"))
		site_pick = UI.option_button(site_ids.map(_site_label))
		container.add_child(site_pick)

	for move_id in PlayerMoves.move_ids():
		var m := PlayerMoves.move(move_id)
		container.add_child(UI.muted_label(String(m["description"])))
		var get_site := func() -> String:
			return "" if site_pick == null else String(site_ids[site_pick.selected])
		var reason := PlayerMoves.block_reason(move_id, faction_id, get_site.call())
		var text := "%s · £%d · %d block" % [m["label"], int(m["cost"]["cash"]), int(m["cost"]["blocks"])]
		container.add_child(MapCardStyle.action_button(text, func(): _do(move_id, faction_id, get_site.call(), status), reason != "", reason))

	container.add_child(MapCardStyle.footer([MapCardStyle.text_button("Close", func(): Modal.close())]))


static func _vein_site_ids(faction_id: String) -> Array:
	var ids: Array = []
	for site in GameState.state["world"]["sites"]:
		var vein: Variant = site["factionVein"]
		if vein != null and vein["factionId"] == faction_id:
			ids.append(site["id"])
	return ids


static func _site_label(site_id: String) -> String:
	var site: Dictionary = Sites.find_site(site_id)
	return "%s · %s" % [site.get("name", site_id), site["factionVein"]["security"]]


static func _do(move_id: String, faction_id: String, site_id: String, status: Label) -> void:
	var result := PlayerMoves.perform(move_id, faction_id, site_id)
	if not result.get("ok", false):
		status.text = result.get("reason", "")
		return
	Modal.close()

# Gift sheet for one faction (R§3.10 "Gifts"): pick a key member, then
# give cash or one consumable. Shows each member's relation, what they
# like and when they next take a gift. Every gift goes through Diplomacy;
# a landed gift opens the member's thread for the reply.
class_name GiftModal
extends RefCounted


static func build(container: VBoxContainer, data: Dictionary) -> void:
	var faction_id: String = data.get("factionId", "")
	container.add_child(UI.heading("Gift · %s" % GameData.FACTIONS[faction_id]["shortName"]))
	container.add_child(UI.muted_label("Faction relation %d." % int(GameState.state["factions"][faction_id]["relation"])))
	var status := UI.label("")
	container.add_child(status)

	var contact_ids: Array = KeyMembers.members(faction_id).map(func(m: Dictionary) -> String: return m["contactId"])
	for contact_id in contact_ids:
		container.add_child(UI.muted_label(_member_line(contact_id)))
	container.add_child(MapCardStyle.section_label("To"))
	var member_pick := UI.option_button(contact_ids.map(func(id: String) -> String: return KeyMembers.member(id)["name"]))
	container.add_child(member_pick)
	var picked := func() -> String: return contact_ids[member_pick.selected]

	container.add_child(MapCardStyle.section_label("Cash"))
	for amount in GameData.FACTION_GIFTS["cashOptions"]:
		var cash := int(amount)
		var short := int(GameState.state["player"]["cash"]) < cash
		container.add_child(MapCardStyle.action_button("Give £%d" % cash, func(): _give(Diplomacy.gift_cash(picked.call(), cash), picked.call(), status), short, "Not enough cash." if short else ""))

	container.add_child(MapCardStyle.section_label("Items"))
	var items := Diplomacy.giftable_items()
	if items.is_empty():
		container.add_child(UI.muted_label("Nothing to give."))
	for recipe_key in items:
		var text := "Give %s · ×%d held · £%d" % [GameData.RECIPES[recipe_key]["name"], Crafting.inventory_qty(recipe_key), Diplomacy.item_value(recipe_key)]
		container.add_child(MapCardStyle.action_button(text, func(): _give(Diplomacy.gift_item(picked.call(), recipe_key), picked.call(), status), false, ""))

	container.add_child(MapCardStyle.footer([MapCardStyle.text_button("Close", func(): Modal.close())]))


# "Name · relation N · likes A, B · ready" (or when they next take one).
static func _member_line(contact_id: String) -> String:
	var member := KeyMembers.member(contact_id)
	var likes: Array = member.get("giftPrefs", []).map(func(key: String) -> String: return GameData.RECIPES[key]["name"])
	var check := Diplomacy.can_gift(contact_id)
	var when: String = "ready" if check["ok"] else check["reason"]
	var relation := int(GameState.state["contacts"].get(contact_id, {}).get("relation", 0))
	return "%s · relation %d · likes %s · %s" % [member["name"], relation, ", ".join(likes), when]


static func _give(result: Dictionary, contact_id: String, status: Label) -> void:
	if not result.get("ok", false):
		status.text = result.get("reason", "")
		return
	Modal.close()
	Nav.go_to("phone")
	PhoneNav.select_conversation(contact_id)

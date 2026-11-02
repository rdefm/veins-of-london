class_name ApplyVeinItemModal
extends RefCounted

# "Apply item…" picker for one player vein (ADR 0007): one button per Bag
# stack of a vein-boost item. The pick goes through Cultivating.apply_item.


static func build(container: VBoxContainer, data: Dictionary) -> void:
	var vein_id: String = data["veinId"]
	var vein: Variant = Cultivating.find_vein(vein_id)
	if vein == null:
		Modal.close()
		return

	container.add_child(UI.heading("Apply item"))
	container.add_child(UI.muted_label("One of each per vein. Using it again restarts the days."))
	var stacks: Array = Cultivating.usable_boost_stacks()
	if stacks.is_empty():
		container.add_child(UI.muted_label("Nothing in the Bag to apply."))
	for stack in stacks:
		var item: String = stack["item"]
		var tier: int = stack["tier"]
		var days: int = stack["days"]
		var text := "%s · tier %d · %d day%s · ×%d" % [GameData.RECIPES[item]["name"], tier, days, "" if days == 1 else "s", stack["qty"]]
		container.add_child(MapCardStyle.action_button(text, func(): _apply(vein_id, item, tier), days <= 0, "Too weak to take." if days <= 0 else ""))
	container.add_child(MapCardStyle.footer([MapCardStyle.text_button("Close", func(): Modal.close())]))


static func _apply(vein_id: String, item: String, tier: int) -> void:
	Cultivating.apply_item(vein_id, item, tier)
	Modal.close()

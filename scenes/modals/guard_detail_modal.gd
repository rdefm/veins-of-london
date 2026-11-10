class_name GuardDetailModal
extends RefCounted

# "guard_detail" modal: data.guardId. Full name, level, XP and the next
# threshold, wage, post, traits (tap one to read what it does) and Dismiss.
#
# PROSE-REVIEW: the labels on this sheet.


static func build(container: VBoxContainer, data: Dictionary) -> void:
	var g := Muscle.guard(str(data.get("guardId", "")))
	if g.is_empty():
		Modal.close()
		return
	container.add_child(UI.heading(Muscle.full_name(g), 20))
	container.add_child(UI.label("Level %d" % int(g["level"])))
	container.add_child(UI.muted_label(xp_text(g)))
	container.add_child(UI.label("Wage £%d/week" % Muscle.wage(g)))
	container.add_child(UI.muted_label("Post: %s" % SecurityScreen.post_text(g)))
	container.add_child(MapCardStyle.section_label("Traits"))
	var open_trait: String = str(data.get("openTrait", ""))
	for trait_id in g["traits"]:
		var captured: String = trait_id
		var entry: Dictionary = GameData.MUSCLE_TRAITS[trait_id]
		container.add_child(MapCardStyle.option_row(entry["label"], func(): _toggle_trait(captured), open_trait == trait_id))
		if open_trait == trait_id:
			container.add_child(UI.muted_label(entry["effect"]))
	var gid: String = g["id"]
	container.add_child(MapCardStyle.footer([
		MapCardStyle.text_button("Close", func(): Modal.close()),
		MapCardStyle.action_button("Dismiss", func(): Modal.open("guard_dismiss", { "guardId": gid }), not Muscle.can_manage(), "Needs a Security Office."),
	]))


# "XP 120 / 200" or "XP 410 (top level)".
static func xp_text(g: Dictionary) -> String:
	var next := Muscle.next_level_xp(g)
	if next < 0:
		return "XP %d (top level)" % int(g["xp"])
	return "XP %d / %d" % [int(g["xp"]), next]


static func _toggle_trait(trait_id: String) -> void:
	var open: String = str(GameState.state["modal"]["data"].get("openTrait", ""))
	Modal.set_data("openTrait", "" if open == trait_id else trait_id)

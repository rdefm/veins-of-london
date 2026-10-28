class_name HqMeditateModal
extends RefCounted


static func build(container: VBoxContainer, _data: Dictionary) -> void:
	var has_garden: bool = GameState.state["home"]["rooms"].has("garden")
	container.add_child(UI.heading("Meditate", 14))
	container.add_child(UI.muted_label("%d Soul XP per session." % int(GameData.MEDITATE["gardenXp" if has_garden else "xp"])))
	if not has_garden:
		container.add_child(UI.muted_label("Build a Garden to get more out of each session."))
	var disabled: bool = TimeSystem.is_time_exhausted()
	var c := MapCardStyle.card(12, 0.0)
	c["content"].add_child(MapCardStyle.text_button(UI.format_block_cost_label("Meditate", 1, not disabled), func(): Soul.meditate(), disabled))
	container.add_child(c["panel"])
	container.add_child(MapCardStyle.footer([MapCardStyle.text_button("Close", func(): Modal.close())]))

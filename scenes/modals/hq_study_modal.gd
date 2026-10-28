class_name HqStudyModal
extends RefCounted


static func build(container: VBoxContainer, _data: Dictionary) -> void:
	var has_library: bool = GameState.state["home"]["rooms"].has("library")
	container.add_child(UI.heading("Study", 14))
	container.add_child(UI.muted_label("%d Mind XP per session." % int(GameData.STUDY["libraryXp" if has_library else "xp"])))
	if not has_library:
		container.add_child(UI.muted_label("Build a Library to get more out of each session."))
	var disabled: bool = TimeSystem.is_time_exhausted()
	var c := MapCardStyle.card(12, 0.0)
	c["content"].add_child(MapCardStyle.text_button(UI.format_block_cost_label("Study", 1, not disabled), func(): Mind.study(), disabled))
	container.add_child(c["panel"])
	container.add_child(MapCardStyle.footer([MapCardStyle.text_button("Close", func(): Modal.close())]))

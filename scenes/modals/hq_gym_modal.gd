class_name HqGymModal
extends RefCounted


static func build(container: VBoxContainer, _data: Dictionary) -> void:
	var player: Dictionary = GameState.state["player"]
	var has_gym: bool = GameState.state["home"]["rooms"].has("homeGym")
	container.add_child(UI.heading("Gym", 14))
	container.add_child(UI.label("Combat Skill: Lv%d (%d XP)" % [player["combatSkill"], player["combatXP"]]))
	if not has_gym:
		container.add_child(UI.muted_label("Build a Home Gym to get more out of each workout."))
	container.add_child(_train_button())
	container.add_child(MapCardStyle.footer([MapCardStyle.text_button("Close", func(): Modal.close())]))


static func _train_button() -> Control:
	var disabled: bool = TimeSystem.is_time_exhausted()
	var c := MapCardStyle.card(12, 0.0)
	c["content"].add_child(MapCardStyle.text_button(UI.format_block_cost_label("Train", 1, not disabled), func(): Combat.train(), disabled))
	return c["panel"]

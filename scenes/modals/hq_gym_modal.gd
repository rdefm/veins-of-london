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
	container.add_child(UI.button("Close", func(): Modal.close()))


static func _train_button() -> Control:
	var disabled: bool = TimeSystem.is_time_exhausted()
	var accent: Color = UI.ACTION_DISABLED_COLOUR if disabled else UI.action_colour()

	var c := UI.card()
	c["panel"].add_theme_stylebox_override("panel", UI.action_card_panel_style(accent))

	var b := UI.button(UI.format_block_cost_label("Train", 1, not disabled), func(): Combat.train())
	b.disabled = disabled
	UI.style_action_button(b, accent)
	c["content"].add_child(b)

	return c["panel"]

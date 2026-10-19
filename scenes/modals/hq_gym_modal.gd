class_name HqGymModal
extends RefCounted


static func build(container: VBoxContainer, _data: Dictionary) -> void:
	var has_gym: bool = GameState.state["home"]["rooms"].has("homeGym")
	container.add_child(UI.heading("Gym", 14))
	container.add_child(_skill_card(Combat.skill_summary()))
	container.add_child(_moves_card(MoveLevels.summary("")))
	if not has_gym:
		container.add_child(UI.muted_label("Build a Home Gym to get more out of each workout."))
	container.add_child(_train_button())
	container.add_child(MapCardStyle.footer([MapCardStyle.text_button("Close", func(): Modal.close())]))


# R§3.7a: level, XP band bar, current bonuses, and the next level's gains.
static func _skill_card(s: Dictionary) -> Control:
	var c := MapCardStyle.card(12, 0.0)
	var box: VBoxContainer = c["content"]
	if s["isMax"]:
		box.add_child(UI.label("Combat Skill: Lv%d (max)" % s["level"]))
		box.add_child(UI.muted_label("%d XP" % s["xp"]))
	else:
		box.add_child(UI.label("Combat Skill: Lv%d" % s["level"]))
		box.add_child(UI.muted_label("%d / %d XP" % [s["xp"], s["xpNext"]]))
		box.add_child(MapCardStyle.style_bar(UI.bar(s["xp"] - s["xpFloor"], s["xpNext"] - s["xpFloor"])))
	box.add_child(UI.label(stats_text(s["stats"])))
	if not s["isMax"]:
		box.add_child(UI.muted_label("Next level: " + stats_text(s["nextStats"])))
	return c["panel"]


# R§3.7b Move levels: each move's level and XP toward the next, grown in fights.
static func _moves_card(rows: Array) -> Control:
	var c := MapCardStyle.card(12, 0.0)
	var box: VBoxContainer = c["content"]
	box.add_child(UI.label("Moves"))
	for row in rows:
		if row["isMax"]:
			box.add_child(UI.muted_label("%s: Lv%d (max)" % [row["name"], row["level"]]))
		else:
			box.add_child(UI.muted_label("%s: Lv%d · %d / %d XP" % [row["name"], row["level"], row["xp"], row["xpNext"]]))
	return c["panel"]


static func stats_text(stats: Dictionary) -> String:
	return "HP %d · ATK %d–%d · SPD %d · ACT %d · CRIT %d%%" % [stats["hpMax"], stats["attackMin"], stats["attackMax"], stats["speed"], stats["actionsPerRound"], roundi(stats["critChance"] * 100.0)]


static func _train_button() -> Control:
	var disabled: bool = TimeSystem.is_time_exhausted()
	var c := MapCardStyle.card(12, 0.0)
	c["content"].add_child(MapCardStyle.text_button(UI.format_block_cost_label("Train", 1, not disabled), func(): Combat.train(), disabled))
	return c["panel"]

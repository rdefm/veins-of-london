class_name SecurityScreen
extends Control

# Security screen, opened from the Security Office tile. Guards tab: one row
# per hired guard (short name, level, wage, traits, post), a detail sheet on
# tap and the Hire board. Reads state and calls Muscle only.

const SCREEN_ID := "security"


func _ready() -> void:
	UI.anchor_full_rect(self)
	EventBus.state_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	if is_queued_for_deletion():
		return
	for child in get_children():
		child.queue_free()
	_build()


func _build() -> void:
	var sc := UI.scroll_container()
	add_child(sc)

	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", int(UI.top_bar_clearance()) + 16)
	margin.add_theme_constant_override("margin_bottom", int(UI.nav_bar_clearance()) + 16)
	sc.add_child(margin)

	var content := UI.vbox(8)
	margin.add_child(content)

	content.add_child(UI.back_button("hq_floorplan"))
	content.add_child(UI.heading("Security"))
	if not Muscle.can_manage():
		content.add_child(UI.muted_label("The Security Office is gone. Guards stay employed, but you can't manage them."))
	content.add_child(MapCardStyle.section_label("Guards"))
	content.add_child(MapCardStyle.action_button("Hire", func(): Modal.open("guard_hire"), not Muscle.can_manage()))

	var guards := Muscle.guards()
	if guards.is_empty():
		content.add_child(UI.muted_label("No guards. Hire from the board."))
		return
	var c := MapCardStyle.card(12)
	c["panel"].size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(c["panel"])
	for g in guards:
		c["content"].add_child(_build_row(g))


func _build_row(g: Dictionary) -> Button:
	var gid: String = g["id"]
	var row := MapCardStyle.option_row(row_text(g), func(): Modal.open("guard_detail", { "guardId": gid }))
	row.name = "GuardRow_%s" % gid
	row.custom_minimum_size.y = maxf(row.custom_minimum_size.y, 52.0)
	return row


# "Dee O. · L2 · £660/wk · Cheap, Brawler\nReserve ›".
static func row_text(g: Dictionary) -> String:
	return "%s\n%s ›" % [summary_text(g), post_text(g)]


# "Dee O. · L2 · £660/wk · Cheap, Brawler".
static func summary_text(g: Dictionary) -> String:
	return "%s · L%d · £%d/wk · %s" % [Muscle.short_name(g), int(g["level"]), Muscle.wage(g), trait_names(g)]


static func trait_names(g: Dictionary) -> String:
	var names: Array = g["traits"].map(func(t): return GameData.MUSCLE_TRAITS[t]["label"])
	return ", ".join(names)


# The guard's post, with "Injured" while they're out.
static func post_text(g: Dictionary) -> String:
	var text := GuardUpkeep.place_label(g["post"])
	if int(g["injuredUntilDay"]) > int(GameState.state["world"]["day"]):
		text += " · Injured"
	return text

class_name GuardHireModal
extends RefCounted

# "guard_hire" modal: the weekly board. One card per slot (name, level, wage,
# traits, today's advance) with a Hire button; a hired slot stays empty until
# the next Monday roll.
#
# PROSE-REVIEW: the board strings.


static func build(container: VBoxContainer, _data: Dictionary) -> void:
	container.add_child(UI.heading("Hire", 20))
	container.add_child(UI.muted_label("Four on the board. The board changes every Monday."))
	var cards := Muscle.board()
	for i in cards.size():
		container.add_child(_card(i, cards[i]))
	container.add_child(MapCardStyle.footer([MapCardStyle.text_button("Close", func(): Modal.close())]))


static func _card(index: int, g: Variant) -> Control:
	var c := MapCardStyle.card(12, 0.0)
	var box: VBoxContainer = c["content"]
	if g == null:
		box.add_child(UI.muted_label("Taken. Next board Monday."))
		return c["panel"]
	box.add_child(UI.label(SecurityScreen.summary_text(g)))
	if bool(g.get("returning", false)):
		box.add_child(UI.muted_label("Worked for you before"))
	var reason := Muscle.hire_block_reason(index)
	var label := "Hire (£%d today)" % GuardUpkeep.guard_hire_advance(g)
	box.add_child(MapCardStyle.action_button(label, func(): Muscle.hire(index), reason != "", reason))
	return c["panel"]

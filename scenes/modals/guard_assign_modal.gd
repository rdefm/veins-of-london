class_name GuardAssignModal
extends RefCounted

# "guard_assign" modal: data.place. Picks a Reserve guard for that post, or
# points at the hire board when Reserve is empty.
#
# PROSE-REVIEW: the labels on this sheet.


static func build(container: VBoxContainer, data: Dictionary) -> void:
	var place_id := str(data.get("place", ""))
	container.add_child(UI.heading("Assign to %s" % GuardUpkeep.place_label(place_id), 20))
	var options: Array = Muscle.reserve().filter(func(g): return Muscle.is_available(g["id"]))
	if options.is_empty():
		var hire := MapCardStyle.option_row("No one in reserve — Hire ›", func(): Modal.open("guard_hire"))
		hire.name = "HireLink"
		container.add_child(hire)
	for g in options:
		var gid: String = g["id"]
		var row := MapCardStyle.option_row(SecurityScreen.summary_text(g), func(): _pick(gid, place_id))
		row.name = "AssignRow_%s" % gid
		container.add_child(row)
	container.add_child(MapCardStyle.footer([MapCardStyle.text_button("Close", func(): Modal.close())]))


static func _pick(guard_id: String, place_id: String) -> void:
	var result := Muscle.post(guard_id, place_id)
	if result["ok"]:
		Modal.close()

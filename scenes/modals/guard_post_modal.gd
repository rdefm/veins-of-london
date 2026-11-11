class_name GuardPostModal
extends RefCounted

# "guard_post" modal: data.guardId. The Post picker for one guard: HQ, every
# vein and Reserve, each with its headcount. Picking calls Muscle.post.
#
# PROSE-REVIEW: the labels on this sheet.


static func build(container: VBoxContainer, data: Dictionary) -> void:
	var g := Muscle.guard(str(data.get("guardId", "")))
	if g.is_empty():
		Modal.close()
		return
	var gid: String = g["id"]
	container.add_child(UI.heading("Post %s" % Muscle.short_name(g), 20))
	for place_id in SecurityScreen.place_ids():
		var captured: String = place_id
		var reason := Muscle.post_block_reason(gid, captured)
		var current: bool = g["post"] == captured
		var row := MapCardStyle.option_row(SecurityScreen.place_header(captured), func(): _pick(gid, captured), current)
		row.disabled = reason != "" and not current
		container.add_child(row)
	container.add_child(MapCardStyle.footer([
		MapCardStyle.text_button("Back", func(): Modal.open("guard_detail", { "guardId": gid })),
	]))


static func _pick(guard_id: String, place_id: String) -> void:
	var result := Muscle.post(guard_id, place_id)
	if result["ok"]:
		Modal.open("guard_detail", { "guardId": guard_id })

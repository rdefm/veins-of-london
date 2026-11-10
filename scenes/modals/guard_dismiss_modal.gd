class_name GuardDismissModal
extends RefCounted

# "guard_dismiss" modal: data.guardId. Confirm before Muscle.dismiss.
#
# PROSE-REVIEW: the confirm copy.


static func build(container: VBoxContainer, data: Dictionary) -> void:
	var g := Muscle.guard(str(data.get("guardId", "")))
	if g.is_empty():
		Modal.close()
		return
	var gid: String = g["id"]
	container.add_child(UI.heading("Dismiss %s?" % Muscle.short_name(g), 20))
	container.add_child(UI.muted_label("They go at once. No severance, no refund. They might turn up on the board again."))
	container.add_child(MapCardStyle.footer([
		MapCardStyle.text_button("Keep", func(): Modal.open("guard_detail", { "guardId": gid })),
		MapCardStyle.text_button("Dismiss", func(): _confirm(gid)),
	]))


static func _confirm(guard_id: String) -> void:
	Muscle.dismiss(guard_id)
	Modal.close()

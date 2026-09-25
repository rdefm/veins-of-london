class_name ArchieDealResultModal
extends RefCounted


static func build(container: VBoxContainer, data: Dictionary) -> void:
	var mugged: bool = data.get("mugged", false)
	container.add_child(UI.heading("You held them off." if mugged else "Sorted."))
	if mugged:
		container.add_child(UI.label("They tried their luck on Archie's stock. Didn't get it."))
	else:
		container.add_child(UI.label("Went smooth. Archie's buyer paid up, no fuss."))
	container.add_child(UI.label("+£%d" % data.get("earned", 0)))
	container.add_child(MapCardStyle.footer([MapCardStyle.text_button("Back to it", func(): close())]))


static func close() -> void:
	Modal.close()
	PhoneNav.route_home()

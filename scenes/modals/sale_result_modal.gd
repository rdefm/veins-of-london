class_name SaleResultModal
extends RefCounted


static func build(container: VBoxContainer, data: Dictionary) -> void:
	var mugged: bool = data.get("mugged", false)
	var earned: int = data.get("earned", 0)
	container.add_child(UI.heading("You held them off." if mugged else "Done."))
	if mugged:
		container.add_child(UI.label("They tried their luck. They didn't get it. Archie owes you a pint."))
	elif earned < 0:
		container.add_child(UI.label("Paid up, no fuss. It's yours now."))
	else:
		container.add_child(UI.label("Smooth as you like. Buyer paid promptly and left."))
	container.add_child(UI.label(("+£%d" % earned) if earned >= 0 else ("-£%d" % -earned)))
	container.add_child(MapCardStyle.footer([MapCardStyle.text_button("Back to it", func(): close())]))


# A quest beat parked behind the sale plays instead of routing home.
static func close() -> void:
	var has_follow := Modal.has_follow_event()
	Modal.close()
	if not has_follow:
		PhoneNav.route_home()

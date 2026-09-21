class_name DialerApp
extends PhoneApp


func build(content: VBoxContainer) -> void:
	content.add_child(back_button())
	content.add_child(UI.heading("Phone"))
	content.add_child(UI.heading("Recent Calls", 14))
	# PROSE-REVIEW: new recent-calls empty-state copy.
	content.add_child(UI.muted_label("No recent calls."))

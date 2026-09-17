# Base for one phone app's view. scenes/screens/phone.gd's shell makes one
# instance per app id from PhoneAppRegistry, keeps it for the screen's
# lifetime (so per-app view state such as a selected tab survives a
# refresh), and calls build() into a freshly emptied content column on
# every refresh.
class_name PhoneApp
extends RefCounted

var shell: PhoneScreen


func build(_content: VBoxContainer) -> void:
	pass


# Called by the shell before every rebuild; an app that mounts a view
# outside the content column frees it here.
func teardown() -> void:
	pass


func back_button() -> Control:
	return UI.button("‹ Back", func(): PhoneNav.go_home())


func refresh() -> void:
	shell._refresh()

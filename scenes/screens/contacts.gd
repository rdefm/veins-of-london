class_name ContactsScreen
extends Control

const PhoneDeviceShellScript := preload("res://scenes/components/phone_device_shell.gd")

var _content: VBoxContainer
var _device_shell: PhoneDeviceShellScript

func _ready() -> void:
	UI.anchor_full_rect(self)
	_device_shell = PhoneDeviceShellScript.new()
	add_child(_device_shell)
	_device_shell.ensure_built()
	_device_shell.set_home_mode(false)
	_content = _device_shell.content
	EventBus.state_changed.connect(_refresh)
	_refresh()

func _refresh() -> void:
	for child in _content.get_children():
		_content.remove_child(child)
		child.queue_free()

	var back := UI.back_to_home_button()
	back.text = "‹ Phone"
	back.set_meta("contact_back", true)
	_content.add_child(back)
	var heading := UI.heading("Contacts", 32)
	_content.add_child(heading)

	var previous_initial := ""
	for contact_id in ["archie", "des", "hakim", "james", "nadia"]:
		if not GameState.state["contacts"][contact_id]["unlocked"]:
			continue
		var initial: String = Contacts.display_name(contact_id).substr(0, 1)
		if initial != previous_initial:
			var section := UI.muted_label(initial)
			section.add_theme_font_size_override("font_size", 13)
			_content.add_child(section)
			previous_initial = initial
		var card := _build_card(contact_id)
		ContactCards.layout_directory_row(card, contact_id)
		_content.add_child(card)
	ContactCards.apply_phone_os_chrome(_content)


func _build_card(contact_id: String) -> Control:
	match contact_id:
		"archie": return ContactCards.build_archie_card()
		"des": return ContactCards.build_des_card()
		"hakim": return ContactCards.build_hakim_card()
		"james": return ContactCards.build_james_card()
		"nadia": return ContactCards.build_nadia_card()
	return Control.new()

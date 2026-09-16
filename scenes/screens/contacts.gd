class_name ContactsScreen
extends Control

var _content: VBoxContainer

func _ready() -> void:
	UI.anchor_full_rect(self)
	_paint_family2_background()
	_content = UI.screen_body(self)
	EventBus.state_changed.connect(_refresh)
	_refresh()
func _paint_family2_background() -> void:
	var bg := Panel.new()
	UI.anchor_full_rect(bg)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = GameData.PALETTE.get("phone_bg_content", Color("#252528"))
	bg.add_theme_stylebox_override("panel", style)
	add_child(bg)

func _refresh() -> void:
	for child in _content.get_children():
		child.queue_free()

	_content.add_child(UI.back_to_home_button())
	_content.add_child(UI.heading("Contacts"))

	_content.add_child(ContactCards.build_archie_card())
	if GameState.state["contacts"]["des"]["unlocked"]:
		_content.add_child(ContactCards.build_des_card())

	if GameState.state["contacts"]["nadia"]["unlocked"]:
		_content.add_child(ContactCards.build_nadia_card())

	if GameState.state["contacts"]["hakim"]["unlocked"]:
		_content.add_child(ContactCards.build_hakim_card())

	if GameState.state["contacts"]["james"]["unlocked"]:
		_content.add_child(ContactCards.build_james_card())
	ContactCards.apply_phone_os_chrome(_content)

class_name NavBar
extends Control

# Bottom nav, 5 tabs. Hidden by Main.gd on the R§2.2 excluded screens
# (title, intro, event, combat) — this component doesn't know about that
# list itself, just renders the tabs.

const BAR_HEIGHT := 64.0

const TABS := [
	{ "screen": "home", "label": "Home" },
	{ "screen": "inventory", "label": "Inventory" },
	{ "screen": "crafting", "label": "Craft" },
	{ "screen": "world", "label": "World" },
	{ "screen": "contacts", "label": "Contacts" },
]


func _ready() -> void:
	set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	offset_top = -BAR_HEIGHT
	offset_bottom = 0.0

	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(row)

	for tab in TABS:
		var button := Button.new()
		button.text = tab["label"]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_on_tab_pressed.bind(tab["screen"]))
		row.add_child(button)


func _on_tab_pressed(screen_id: String) -> void:
	Nav.go_to(screen_id)

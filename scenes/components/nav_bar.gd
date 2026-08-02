class_name NavBar
extends Control

# Bottom nav, 5 tabs (D4: Map · HQ · Phone · Bag · You — supersedes the M0
# Home/Inventory/Craft/World/Contacts set). Hidden by Main.gd on the R§2.2
# excluded screens (title, intro, event, combat) — this component doesn't
# know about that list itself, just renders the tabs.

const BAR_HEIGHT := 64.0

const TABS := [
	{ "screen": "map", "label": "Map" },
	{ "screen": "hq", "label": "HQ" },
	{ "screen": "phone", "label": "Phone" },
	{ "screen": "bag", "label": "Bag" },
	{ "screen": "you", "label": "You" },
]


func _ready() -> void:
	UI.anchor_bottom_wide(self)
	offset_top = -BAR_HEIGHT
	offset_bottom = 0.0

	var row := HBoxContainer.new()
	UI.anchor_full_rect(row)
	add_child(row)

	for tab in TABS:
		var button := Button.new()
		button.text = tab["label"]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_on_tab_pressed.bind(tab["screen"]))
		row.add_child(button)


func _on_tab_pressed(screen_id: String) -> void:
	Nav.go_to(screen_id)

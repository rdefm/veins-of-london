class_name HqGuardKitScreen
extends Control

# HQ Guard Kit list (guard-kit spec §UI): one row per player vein with guards
# or a non-empty kit; tapping a row opens that vein's stocking sheet.


func _ready() -> void:
	UI.anchor_full_rect(self)
	EventBus.state_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	for child in get_children():
		child.queue_free()
	MapPalette.build_light(_build)


func _build() -> void:
	var sc := UI.scroll_container()
	add_child(sc)

	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", int(UI.top_bar_clearance()) + 16)
	margin.add_theme_constant_override("margin_bottom", int(UI.nav_bar_clearance()) + 16)
	sc.add_child(margin)

	var content := UI.vbox(8)
	margin.add_child(content)

	content.add_child(UI.back_button("hq_door"))
	content.add_child(UI.heading("Guard kits"))

	var veins := GuardKit.kit_veins()
	if veins.is_empty():
		content.add_child(UI.muted_label("No guarded veins. Post a guard first."))
		return

	var c := MapCardStyle.card(12)
	c["panel"].size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(c["panel"])
	for vein in veins:
		c["content"].add_child(_build_row(vein))


func _build_row(vein: Dictionary) -> Button:
	var target := { "kind": "vein", "veinId": vein["id"] }
	var status := GuardKit.status_text(vein.get("guardKit", {}), GuardKit.capacity(vein))
	var text := "%s\n%s ›" % [GuardKit.target_name(target), status]
	var row := MapCardStyle.option_row(text, func(): Modal.open("guard_kit", { "target": target }))
	row.name = "GuardKitRow_%s" % vein["id"]
	row.custom_minimum_size.y = maxf(row.custom_minimum_size.y, 52.0)
	return row

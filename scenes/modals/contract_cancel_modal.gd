class_name ContractCancelModal
extends RefCounted

# Confirm pop-up for cancelling an active BizBrief contract. data:
# { contractId, summary } — summary is the request line BizBrief shows.


static func build(container: VBoxContainer, data: Dictionary) -> void:
	var contract_id: String = data["contractId"]
	var heading := UI.heading("Cancel this contract?", 20)
	var serif := SystemFont.new()
	serif.font_names = PackedStringArray(["Georgia", "Times New Roman", "Noto Serif", "DejaVu Serif", "serif"])
	heading.add_theme_font_override("font", serif)
	heading.add_theme_color_override("font_color", Color("#fbfaf6"))
	container.add_child(heading)
	var summary := UI.label(data.get("summary", ""))
	summary.add_theme_color_override("font_color", Color("#fbfaf6"))
	container.add_child(summary)
	var consequence := UI.muted_label("Nothing more gets paid. What's already delivered stays delivered. The buyer will remember it.")
	consequence.add_theme_color_override("font_color", Color("#a9b5bd"))
	container.add_child(consequence)
	var actions := UI.hbox(8)
	for spec in [
		{ "text": "Keep", "action": func(): Modal.close(), "primary": false },
		{ "text": "Confirm", "action": func(): _confirm(contract_id), "primary": true },
	]:
		var button := UI.button(spec["text"], spec["action"])
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 42
		var style := StyleBoxFlat.new()
		style.bg_color = Color("#e9353c") if spec["primary"] else Color("#1b2a38")
		style.border_color = Color("#e9353c") if spec["primary"] else Color("#354454")
		style.set_border_width_all(1)
		style.set_corner_radius_all(4)
		style.set_content_margin_all(8)
		for state in ["normal", "hover", "pressed", "disabled"]:
			button.add_theme_stylebox_override(state, style)
		for state in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color"]:
			button.add_theme_color_override(state, Color("#fbfaf6"))
		actions.add_child(button)
	container.add_child(actions)


static func _confirm(contract_id: String) -> void:
	Contracts.cancel(contract_id)
	Modal.close()

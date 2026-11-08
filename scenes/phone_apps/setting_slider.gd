class_name SettingSlider
extends VBoxContainer

# One labelled 0..max slider on BizBrief's master controller. The value text
# follows the finger live; `committed` fires once on release (or a keyboard
# step) and the screen calls its system. R§3.6 "Auto-sell", R§3.10.

signal committed(value: int)

const LABEL_SIZE := 13
const VALUE_SIZE := 15
const SLIDER_HEIGHT := 40.0

var _value_label: Label
var _slider: HSlider
var _none_text := ""


# none_text replaces the number at the top of the range (Sell above 50 sells nothing).
func configure(title: String, tint: Color, top: int, low: int, value: int, locked: bool, none_text: String = "") -> void:
	_none_text = none_text
	add_theme_constant_override("separation", 2)
	var head := HBoxContainer.new()
	var name_label := Label.new()
	name_label.text = title
	name_label.add_theme_font_size_override("font_size", LABEL_SIZE)
	name_label.add_theme_color_override("font_color", tint)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(name_label)
	_value_label = Label.new()
	_value_label.name = "Value"
	_value_label.add_theme_font_size_override("font_size", VALUE_SIZE)
	_value_label.add_theme_color_override("font_color", tint)
	head.add_child(_value_label)
	add_child(head)
	_slider = HSlider.new()
	_slider.name = "Slider"
	_slider.min_value = low
	_slider.max_value = top
	_slider.step = 1
	_slider.value = clampi(value, low, top)
	_slider.editable = not locked
	_slider.custom_minimum_size.y = SLIDER_HEIGHT
	_slider.modulate = tint
	_slider.value_changed.connect(func(v: float) -> void: _show(int(v)))
	_slider.drag_ended.connect(func(changed: bool) -> void:
		if changed:
			committed.emit(int(_slider.value)))
	add_child(_slider)
	_show(int(_slider.value))


func value() -> int:
	return int(_slider.value)


func value_text() -> String:
	return _value_label.text


func _show(v: int) -> void:
	_value_label.text = _none_text if _none_text != "" and v >= int(_slider.max_value) else str(v)

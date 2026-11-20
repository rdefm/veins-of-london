class_name MarketInsightIcon
extends Button

# The market row `!` (R§3.13 "Insight") on the Ticker's Stock Market rows and
# Trade sheet rows. Grey and untappable while no source speaks; ui_action_red
# and pulsing when any source flags the good notable. A tap shows every
# source's lines together in one bubble. Presentation only.

const IDLE_ID := "neutral_light"
const NOTABLE_ID := "ui_action_red"
const PULSE_SECONDS := 0.6
const PULSE_ALPHA := 0.35
const BUBBLE_WIDTH := 220.0

var lines: Array = []
var notable := false


# An icon for one good's MarketInsight.read_for() result.
static func make(read: Dictionary) -> MarketInsightIcon:
	var icon := MarketInsightIcon.new()
	icon.lines = read["lines"]
	icon.notable = read["notable"]
	icon.text = "!"
	icon.flat = true
	icon.focus_mode = Control.FOCUS_NONE
	icon.custom_minimum_size = Vector2(24, 36)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.disabled = icon.lines.is_empty()
	icon.mouse_filter = Control.MOUSE_FILTER_STOP if not icon.disabled else Control.MOUSE_FILTER_IGNORE
	icon.accessibility_name = "Market insight" if not icon.disabled else "No market insight"
	var colour: Color = GameData.PALETTE.get(NOTABLE_ID if icon.notable else IDLE_ID, Color.GRAY)
	for font_colour in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color"]:
		icon.add_theme_color_override(font_colour, colour)
	icon.add_theme_font_size_override("font_size", 18)
	icon.pressed.connect(icon._show_bubble)
	return icon


func _ready() -> void:
	if not notable or CombatStage.reduced_motion():
		return
	var tween := create_tween().set_loops()
	tween.tween_property(self, "modulate:a", PULSE_ALPHA, PULSE_SECONDS)
	tween.tween_property(self, "modulate:a", 1.0, PULSE_SECONDS)


# Every line in one popover under the icon; a tap anywhere else dismisses it.
func _show_bubble() -> void:
	if lines.is_empty():
		return
	var popup := PopupPanel.new()
	popup.name = "MarketInsightBubble"
	var box := UI.vbox(4)
	for line in lines:
		var caption := UI.label(str(line))
		caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		caption.custom_minimum_size.x = BUBBLE_WIDTH
		box.add_child(caption)
	popup.add_child(box)
	popup.popup_hide.connect(popup.queue_free)
	add_child(popup)
	var below := get_screen_position() + Vector2(size.x - BUBBLE_WIDTH, size.y + 4.0)
	below.x = maxf(below.x, 4.0)
	popup.popup(Rect2i(Vector2i(below), Vector2i.ZERO))

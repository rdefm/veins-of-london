# Reynard's: display-only cash balance plus the transaction log, newest first,
# grouped under each entry's day. The oxblood/cream brand surfaces are local
# to this app (docs/ui-vision.md §10 "Per-app layout conventions"); currency
# figures stay calc_gold and the ledger rows stay neutral.
class_name BankApp
extends PhoneApp

const ICON_PATH := "res://assets/icons/apps/bank.png"
const HEADER_ICON_SIZE := 28.0
const OXBLOOD := Color("#720e13")
const OXBLOOD_DEEP := Color("#51090e")
const CREAM := Color("#f5da9f")
const BALANCE_CORNER_RADIUS := 22
const BALANCE_MARGIN := 22
const BALANCE_FONT_SIZE := 40
const EYEBROW_FONT_SIZE := 12
const WORDMARK_FONT_SIZE := 13
const AMOUNT_FONT_SIZE := 17
const ROW_MIN_HEIGHT := 44.0


func build(content: VBoxContainer) -> void:
	content.add_child(_build_header())
	content.add_child(_build_balance_card())

	var section := UI.hbox()
	section.add_child(UI.expand_fill(UI.heading("Activity", 18)))
	section.add_child(UI.muted_label("Latest first"))
	content.add_child(section)

	var log: Array = GameState.state["bankLog"]
	if log.is_empty():
		content.add_child(UI.muted_label("No transactions yet."))
		return

	var ledger := UI.vbox(0)
	var current_day := -1
	for i in range(log.size() - 1, -1, -1):
		var entry: Dictionary = log[i]
		var day: int = entry["day"]
		if day != current_day:
			current_day = day
			ledger.add_child(_build_day_header(day))
			ledger.add_child(UI.command_row_rule())
		ledger.add_child(_build_transaction_row(entry))
		ledger.add_child(UI.command_row_rule())
	content.add_child(ledger)


func _build_header() -> Control:
	var row := UI.hbox()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(back_button())
	row.add_child(UI.expand_fill(Control.new()))

	var wordmark := UI.tinted_label("REYNARD'S", CREAM)
	wordmark.add_theme_font_size_override("font_size", WORDMARK_FONT_SIZE)
	wordmark.autowrap_mode = TextServer.AUTOWRAP_OFF
	wordmark.custom_minimum_size.x = 0.0
	row.add_child(wordmark)

	var icon := TextureRect.new()
	icon.texture = load(ICON_PATH)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(HEADER_ICON_SIZE, HEADER_ICON_SIZE)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)
	return row


# Rounded panel clipping a diagonal oxblood gradient; the stylebox draws the
# rounded mask, the gradient TextureRect fills it edge to edge.
func _build_balance_card() -> Control:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	var style := StyleBoxFlat.new()
	style.bg_color = OXBLOOD_DEEP
	style.set_corner_radius_all(BALANCE_CORNER_RADIUS)
	panel.add_theme_stylebox_override("panel", style)

	var gradient := Gradient.new()
	gradient.set_color(0, OXBLOOD)
	gradient.set_color(1, OXBLOOD_DEEP)
	var tex := GradientTexture2D.new()
	tex.gradient = gradient
	tex.fill_from = Vector2(0.0, 0.0)
	tex.fill_to = Vector2(1.0, 1.0)
	var backdrop := TextureRect.new()
	backdrop.texture = tex
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_SCALE
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(backdrop)

	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, BALANCE_MARGIN)
	var body := UI.vbox(6)
	var eyebrow := UI.tinted_label("CURRENT BALANCE", CREAM)
	eyebrow.add_theme_font_size_override("font_size", EYEBROW_FONT_SIZE)
	body.add_child(eyebrow)
	var sum := UI.tinted_label("£%d" % GameState.state["player"]["cash"], _calc_gold())
	sum.add_theme_font_size_override("font_size", BALANCE_FONT_SIZE)
	sum.autowrap_mode = TextServer.AUTOWRAP_OFF
	sum.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	sum.custom_minimum_size.x = 0.0
	body.add_child(sum)
	margin.add_child(body)
	panel.add_child(margin)
	return panel


func _build_day_header(day: int) -> Control:
	var l := UI.muted_label("Day %d" % day)
	l.uppercase = true
	l.add_theme_font_size_override("font_size", EYEBROW_FONT_SIZE)
	return l


func _build_transaction_row(entry: Dictionary) -> Control:
	var amount: int = entry["amount"]
	var amount_text: String = "+£%d" % amount if amount >= 0 else "-£%d" % -amount
	var row := UI.hbox(12)
	row.custom_minimum_size.y = ROW_MIN_HEIGHT
	var desc := UI.label(entry["label"])
	desc.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(UI.expand_fill(desc))
	var amount_label := UI.tinted_label(amount_text, _calc_gold())
	amount_label.add_theme_font_size_override("font_size", AMOUNT_FONT_SIZE)
	amount_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	amount_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(amount_label)
	return row


func _calc_gold() -> Color:
	return GameData.PALETTE.get("calc_gold", Color("#d4af52"))

class_name CombatTranscript
extends PanelContainer

# The fight's play-by-play between the combat stage and the command dock,
# styled as an event card's text (UI.card() panel, UI.label lines): one line
# per entry, oldest at the top, the view kept on the newest as lines arrive;
# older lines scroll up. Presentation only -- CombatRoundsScreen feeds it
# state.combat.transcript, a line at a time while beats play.

const HEIGHT := 190.0
const LINE_SEPARATION := 4

var _texts: Array[String] = []
var _scroll: ScrollContainer
var _lines: VBoxContainer
# Narration pinned under the scrolling lines (refusal / lock prompt / coach
# lesson), the fight heading and a demo fight's hp readout above them; each
# hidden while empty.
var note_label: Label
var heading_label: Label
var hp_label: Label


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	custom_minimum_size.y = HEIGHT
	var column := UI.vbox(LINE_SEPARATION)
	add_child(column)
	heading_label = UI.muted_label("")
	heading_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	column.add_child(heading_label)
	hp_label = UI.muted_label("")
	hp_label.name = "DemoHp"
	hp_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hp_label.visible = false
	column.add_child(hp_label)
	_scroll = UI.scroll_container()
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(_scroll)
	note_label = UI.muted_label("")
	note_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	note_label.visible = false
	column.add_child(note_label)
	_lines = UI.vbox(LINE_SEPARATION)
	_lines.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_lines)
	# Content growing (a line added) pins the view to the newest line.
	var bar := _scroll.get_v_scroll_bar()
	bar.changed.connect(func(): _scroll.scroll_vertical = int(bar.max_value))


func lines() -> Array:
	var out: Array = []
	out.assign(_texts)
	return out


# Shows exactly `texts`, rebuilding only when they differ from what's shown.
func set_lines(texts: Array) -> void:
	var incoming: Array[String] = []
	for text in texts:
		incoming.append(str(text))
	if incoming == _texts:
		return
	_texts.clear()
	for child in _lines.get_children():
		_lines.remove_child(child)
		child.queue_free()
	for text in incoming:
		append_line(text)


func append_line(text: String) -> void:
	_texts.append(text)
	var line := UI.label(text)
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lines.add_child(line)


# Removes the newest line reading `text` (a rewound beat's); nothing when
# there's none.
func remove_last(text: String) -> void:
	var i := _texts.rfind(text)
	if i < 0:
		return
	_texts.remove_at(i)
	var line := _lines.get_child(i)
	_lines.remove_child(line)
	line.queue_free()

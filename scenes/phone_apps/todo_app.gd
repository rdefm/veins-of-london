# ToDo: one collapsible section per questline from Todo.get_questline_sections(),
# flat hairline-divided checklist rows (docs/ui-vision.md §10 "Per-app layout
# conventions"). Which sections are expanded is session-only view state: a
# static var, never the state tree, so it survives the app closing and
# reopening but not a restart.
class_name ToDoApp
extends PhoneApp

const HEADER_FONT_SIZE := 17
const CHECK_INDENT := 22

# "<questline>:<status>" -> expanded. Keyed on status too, so a questline
# that finishes mid-session falls back to its collapsed-when-done default.
static var _expanded_overrides: Dictionary = {}


func build(content: VBoxContainer) -> void:
	content.add_child(back_button())
	content.add_child(UI.heading("ToDo"))
	for section in Todo.get_questline_sections():
		content.add_child(_build_section(section))


func _build_section(section: Dictionary) -> Control:
	var key := "%s:%s" % [section["questline"], section["status"]]
	var done: bool = section["status"] == "done"
	var title: String = "%s ☑" % section["label"] if done else section["label"]
	var s := UI.collapsible_section(title, _expanded_overrides.get(key, section["defaultExpanded"]), func(expanded: bool): _expanded_overrides[key] = expanded)
	var header: Button = s["header"]
	header.flat = true
	header.add_theme_font_size_override("font_size", HEADER_FONT_SIZE)
	if done:
		header.add_theme_color_override("font_color", UI._MUTED_COLOUR)

	var rows := UI.vbox(6)
	rows.add_child(UI.command_row_rule())
	if section["status"] == "placeholder":
		rows.add_child(UI.muted_label(section["emptyText"]))
	for item in section["items"]:
		var text: String = item["title"] if item["detail"] == "" else "%s — %s" % [item["title"], item["detail"]]
		rows.add_child(UI.checklist_row(text, item["done"]))
		for check in item["checks"]:
			rows.add_child(_check_row(check))
		rows.add_child(UI.command_row_rule())
	if not section["ledger"].is_empty():
		rows.add_child(UI.muted_label("Ledger"))
		for row in section["ledger"]:
			rows.add_child(UI.label("%s — %s (%s)" % [row["district"], row["oreType"], row["security"]]))
			rows.add_child(UI.command_row_rule())
	s["content"].add_child(rows)
	return s["panel"]


# A sub-item of an all_of objective, indented under its parent row.
func _check_row(check: Dictionary) -> Control:
	var text: String = check["label"] if check["detail"] == "" else "%s — %s" % [check["label"], check["detail"]]
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", CHECK_INDENT)
	margin.add_child(UI.checklist_row(text, check["done"]))
	return margin

class_name GymSparModal
extends RefCounted

# Flip Reverse, the calc gym (map pin once flags.gymUnlocked): pick a sparring partner, see
# the session cost. Starting one opens the prep sheet; Fight runs Sparring.spar().


static func build(container: VBoxContainer, data: Dictionary) -> void:
	container.add_child(UI.heading("Flip Reverse", 14))
	container.add_child(UI.muted_label(Sparring.line("houseRules")))
	container.add_child(UI.muted_label(_sessions_text()))
	container.add_child(MoveBook.rows("", str(data.get("openMove", "")), _on_move_toggle))
	var skill: int = GameState.state["player"]["combatSkill"]
	for entry in Sparring.config()["partners"]:
		container.add_child(_partner_card(entry, skill))
	container.add_child(MapCardStyle.footer([MapCardStyle.text_button("Close", func(): Modal.close())]))


static func _on_move_toggle(move_id: String) -> void:
	var open: String = str(GameState.state["modal"]["data"].get("openMove", ""))
	Modal.set_data("openMove", "" if open == move_id else move_id)


static func _sessions_text() -> String:
	var free := Sparring.free_sessions_left()
	if free > 0:
		return "%d free session%s left." % [free, "" if free == 1 else "s"]
	return "Sessions are £%d each." % Sparring.next_fee()


static func _partner_card(entry: Dictionary, skill: int) -> Control:
	var reason := Sparring.block_reason(str(entry["id"]))
	var c := MapCardStyle.card(12, 0.0)
	var box: VBoxContainer = c["content"]
	box.add_child(UI.label("%s — %s" % [entry["label"], entry["name"]]))
	box.add_child(UI.muted_label("Level %d" % Sparring.partner_level(entry, skill)))
	var fee := Sparring.next_fee()
	var action := "Spar" if fee == 0 else "Spar (£%d)" % fee
	box.add_child(MapCardStyle.text_button(UI.format_block_cost_label(action, 1, reason == ""), func(): _start(str(entry["id"])), reason != ""))
	if reason != "":
		box.add_child(UI.muted_label(reason))
	return c["panel"]


static func _start(partner_id: String) -> void:
	if Sparring.block_reason(partner_id) == "":
		Modal.close()
		CombatPrep.request(CombatPrep.KIND_SPAR, { "partnerId": partner_id, "rack": {} })

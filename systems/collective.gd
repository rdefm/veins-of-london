class_name Collective
extends RefCounted

# collective1-07, spec §5.5/§7.2/§9.5: Des, Nadia and Hakim are three
# cosmetic doors onto one lane -- identical price and identical relation
# award, because both are already generic per-faction (systems/economy.gd's
# execute_faction_sale, systems/relation_accrual.gd's accrue_faction), driven
# here with faction_id "collective" regardless of which contact's Trade
# button opened the sell_menu. The only thing that varies by vendor is a
# flavour line appended to their own conversation on completing a trade
# (data/collective_barks.json), drawn without repeats until each vendor's
# pool is exhausted.


static func complete_trade(contact_id: String) -> Dictionary:
	var result := Economy.sell_to_faction_from_sell_state("collective")
	if result.get("ok", false) and result.get("earned", 0) > 0:
		Messages.append(contact_id, "them", _next_bark(contact_id))
		Modal.open("sale_result", { "earned": result["earned"], "gross": result["earned"], "mugged": false })
	return result


# Sequential cursor over data/collective_barks.json's array for this
# contact -- every line is shown once before any repeats, then wraps.
# Deterministic (no Rng) since draw order carries no meaning here, only
# non-repetition does.
static func _next_bark(contact_id: String) -> String:
	var lines: Array = GameData.COLLECTIVE_BARKS.get(contact_id, [])
	if lines.is_empty():
		return ""
	var cursors: Dictionary = GameState.state["collective"]["barkCursors"]
	var index: int = cursors.get(contact_id, 0)
	if index >= lines.size():
		index = 0
	cursors[contact_id] = index + 1
	return lines[index]

class_name Todo
extends RefCounted

# The home-screen to-do list (R§3.11), extracted so both the tutorial-era
# `home` screen and Phone's "Notes" app (M1-LONDON.md D4) can share the
# same flag-driven checklist instead of maintaining two copies. Static
# funcs only — pure read over GameState.state.


# Ported from the HTML's getTodoItems() (same conditional chain, last 4
# shown), with jamesCraftEventSeen mapped to craftingUnlocked — the R§2
# flag covering the same tutorial milestone under the current schema.
static func get_items() -> Array[Dictionary]:
	var f: Dictionary = GameState.state["flags"]
	var day: int = GameState.state["world"]["day"]
	var items: Array[Dictionary] = []

	items.append({ "done": f["metArchie"], "text": "Get back to Archie. He's sorting the new buyer." })

	if f["metArchie"]:
		items.append({
			"done": f["buyerEventSeen"],
			"text": "Wait for Archie's text — he's lining up the buyer." if day < 2 else "Back up Archie on the sale tonight. Check Contacts.",
		})

	if f["buyerEventSeen"]:
		items.append({ "done": f["metJames"], "text": "Archie mentioned a contact called James. SMS him to set it up." })

	if f["metJames"]:
		items.append({ "done": f["craftingUnlocked"], "text": "Go back to James when he's ready. He'll teach you the basics." })

	if f["craftingUnlocked"]:
		items.append({ "done": f["archieCraftChatSeen"], "text": "Catch up with Archie about what James taught you." })

	if f["archieCraftChatSeen"]:
		items.append({ "done": f["homeRaidEventSeen"], "text": "You have calc now. The flat isn't as secure as you thought." })

	if f["archiePartnerSeen"]:
		items.append({ "done": false, "text": "Archie's time vein is yours. Cultivate it. Harvest. Make pearls. Archie sells them." })

	if items.size() > 4:
		items = items.slice(items.size() - 4, items.size())
	return items

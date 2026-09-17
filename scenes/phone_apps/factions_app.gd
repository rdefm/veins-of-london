class_name FactionsApp
extends PhoneApp


func build(content: VBoxContainer) -> void:
	content.add_child(back_button())
	content.add_child(UI.heading("Factions"))
	content.add_child(UI.muted_label("Build relations. Join. Use rooms."))

	for faction_id in GameData.FACTIONS.keys():
		content.add_child(ContactCards.build_faction_card(faction_id))

class_name RegisterStandingModal
extends RefCounted

# The Register's "Your standing" sheet: one row per faction (stance, relation,
# alert, meter); a row closes the sheet and opens that faction's dossier.


static func build(container: VBoxContainer, _data: Dictionary) -> void:
	container.add_child(UI.heading("Your standing"))
	container.add_child(UI.muted_label("Five factions. One London."))
	for faction_id in GameData.FACTIONS.keys():
		container.add_child(FactionsApp.build_row(faction_id, func():
			Modal.close()
			PhoneNav.select_faction(faction_id)
		))
	container.add_child(MapCardStyle.footer([MapCardStyle.text_button("Close", func(): Modal.close())]))

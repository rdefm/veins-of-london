class_name LabBenchProbeResultModal
extends RefCounted


static func build(container: VBoxContainer, data: Dictionary) -> void:
	container.add_child(UI.heading(LabBenchModalHelpers.outcome_heading(data.get("outcome", ""))))
	container.add_child(UI.symbol_row(_prose_parts(data)))
	container.add_child(UI.button("Got it", func(): Modal.close()))


static func _prose_parts(data: Dictionary) -> Array:
	match data.get("outcome", ""):
		"found":
			var r: Dictionary = GameData.RECIPES[data["recipeKey"]]
			return [{ "symbol": r["symbol"], "fallback": SymbolGlyph.generic_fallback() }, "%s. %s Craftable now." % [r["name"], r["description"]]]
		"hot":
			return ["Something's in there. It didn't come out this time."]
		"inert":
			return ["Nothing in it. Never was."]
		_:
			return [""]

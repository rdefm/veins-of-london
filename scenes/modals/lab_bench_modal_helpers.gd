# Bits shared by the lab-bench modals (recipe book, notes, probe result).
class_name LabBenchModalHelpers
extends RefCounted


static func append_refine_controls(container: Control, recipe: Dictionary, types: Array, approach: String) -> void:
	var tier := Bench.refine_tier_target(types, approach)
	var reason := Bench.refine_block_reason(types, approach)
	var refine_btn := UI.button(UI.format_block_cost_label("Refine to tier %d" % tier, 1, reason.is_empty()), func(): _on_refine_pressed(recipe["name"], types, approach, tier))
	refine_btn.disabled = reason != ""
	container.add_child(refine_btn)
	if reason != "":
		container.add_child(UI.muted_label(reason))


static func _on_refine_pressed(recipe_name: String, types: Array, approach: String, tier: int) -> void:
	var result := Bench.refine(types, approach)
	if result.get("outcome", "") == "refined":
		Notify.push("%s refined to tier %d." % [recipe_name, tier], Notify.CATEGORY_SUCCESS)
	else:
		Notify.push("No improvement this time. Still tier %d." % (tier - 1), Notify.CATEGORY_WARNING)


static func outcome_heading(outcome: String) -> String:
	match outcome:
		"found":
			return "Found it."
		"hot":
			return "Something's there."
		"inert":
			return "Inert."
		"refined":
			return "Refined."
		"refine_failed":
			return "No better this time."
		_:
			return ""

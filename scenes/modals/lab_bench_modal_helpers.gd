# Bits shared by the lab-bench modals (recipe book, notes, probe result).
class_name LabBenchModalHelpers
extends RefCounted


# "Tier 2 / 5 · 1/3 to next" with a fill bar toward the next tier; at the top tier the bar is full and reads "Max tier".
static func tier_progress_block(types: Array, approach: String) -> Control:
	var block := UI.vbox(2)
	var maxed := Bench.is_max_tier(types, approach)
	var tier: int = Bench.get_cell(types, approach)["tier"]
	var progress: int = Bench.tier_progress(types, approach)
	var text := "Max tier (%d)" % tier if maxed else "Tier %d / %d · %d/%d to next" % [tier, Bench.MAX_TIER, progress, Bench.PROGRESS_TO_TIER]
	block.add_child(UI.muted_label(text))
	block.add_child(MapCardStyle.style_bar(UI.bar(Bench.PROGRESS_TO_TIER if maxed else progress, Bench.PROGRESS_TO_TIER)))
	return block


static func append_experiment_controls(container: Control, recipe: Dictionary, types: Array, approach: String) -> void:
	container.add_child(tier_progress_block(types, approach))
	var reason := Bench.experiment_block_reason(types, approach)
	container.add_child(MapCardStyle.action_button("Experiment", func(): _on_experiment_pressed(recipe["name"], types, approach), reason != "", reason))


static func _on_experiment_pressed(recipe_name: String, types: Array, approach: String) -> void:
	var result := Bench.experiment(types, approach)
	match result.get("outcome", ""):
		"tier_up":
			Notify.push("%s reached tier %d." % [recipe_name, Bench.get_cell(types, approach)["tier"]], Notify.CATEGORY_SUCCESS)
		"progress":
			Notify.push("%s improves. Not there yet." % recipe_name, Notify.CATEGORY_SUCCESS)
		_:
			Notify.push("No progress this time.", Notify.CATEGORY_WARNING)


# "Total: 10 Time · 6 Fate" -- a batch's whole calc cost, per ore.
static func batch_total_text(costs: Dictionary, qty: int) -> String:
	var parts: Array[String] = []
	for ore_type in costs:
		parts.append("%d %s" % [costs[ore_type] * qty, String(ore_type).capitalize()])
	return "Total: %s" % " · ".join(parts)


static func outcome_heading(outcome: String) -> String:
	match outcome:
		"found":
			return "Found it."
		"hot":
			return "Something's there."
		"inert":
			return "Inert."
		"tier_up":
			return "Tier up."
		"progress":
			return "Progress."
		"no_progress":
			return "No better this time."
		_:
			return ""

extends "res://tests/test_base.gd"

# UI.format_cost_label (D4.4) — the shared cost-label helper every
# cost-gated button routes through.


func run() -> void:
	run_case("ore_cost_label_matches_D4_4_example", func():
		var cost := { "label": "Seed", "resource": "physics", "amount": 40 }
		var holdings := { "physics": 52 }
		assert_eq(UI.format_cost_label(cost, holdings), "Seed — 40 physics (have 52)", "ore cost format")
	)

	run_case("cash_cost_label_matches_D4_4_example", func():
		var cost := { "label": "Bribe", "resource": "cash", "amount": 50 }
		var holdings := { "cash": 210 }
		assert_eq(UI.format_cost_label(cost, holdings), "Bribe — £50 (have £210)", "cash cost format")
	)

	run_case("missing_holding_defaults_to_zero", func():
		var cost := { "label": "Craft", "resource": "fate", "amount": 10 }
		assert_eq(UI.format_cost_label(cost, {}), "Craft — 10 fate (have 0)", "missing holdings key reads as 0")
	)

	run_case("empty_label_omits_the_dash", func():
		var cost := { "label": "", "resource": "cash", "amount": 5 }
		var holdings := { "cash": 5 }
		assert_eq(UI.format_cost_label(cost, holdings), "£5 (have £5)", "no label means no leading dash")
	)

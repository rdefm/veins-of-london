class_name CombatScreen
extends Control

# The "combat" screen: hosts the round-fight screen (CombatRoundsScreen,
# scenes/screens/combat_rounds.gd) over state.combat (R§3.7b), plus the
# fight's heading label and outcome button it reads.

var _round_screen: CombatRoundsScreen


func _ready() -> void:
	UI.anchor_full_rect(self)
	_round_screen = CombatRoundsScreen.new()
	add_child(_round_screen)


static func context_label(context: String) -> String:
	if context == Combat.CONTEXT_HOME_RAID or context == Combat.CONTEXT_HOME_ALARM_DEFEND:
		return "Home Raid"
	if context == "raid":
		return "Raid"
	if context == "defend_vein":
		return "Defend"
	if context == Combat.CONTEXT_ARCHIE_DEAL_MUGGING:
		return "Archie's Deal"
	if context == Combat.CONTEXT_SPAR:
		return "Sparring"
	return "Mugging"


static func outcome_button(outcome: String, context: String, demo: bool = false, spar: bool = false) -> Control:
	var label: String
	if demo:
		label = "▶ Carry on"
	elif spar or context == Combat.CONTEXT_SPAR:
		label = "▶ Back to the mats"
	elif outcome == "win":
		if Combat.NON_LETHAL_MUGGING_CONTEXTS.has(context):
			label = "✅ They've legged it"
		elif Combat.HOME_CONTEXTS.has(context):
			label = "✅ Flat secured"
		else:
			label = "✅ Vein secured"
	elif outcome == "fled":
		label = "🏃 Scarper"
	else:
		label = "💀 Come round"

	return MapCardStyle.chip_button(label, func(): Combat.exit_combat())

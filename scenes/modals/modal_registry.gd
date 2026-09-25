# One script per modal type; each exposes `static func build(container:
# VBoxContainer, data: Dictionary) -> void`. modal_layer.gd's chrome
# dispatches content here by type — adding a type is one script + one row.
class_name ModalRegistry
extends RefCounted

static var REGISTRY: Dictionary = {
	"seed_result": SeedResultModal,
	"craft_result": CraftResultModal,
	"craft_batch_result": CraftBatchResultModal,
	"sale_result": SaleResultModal,
	"archie_deal_result": ArchieDealResultModal,
	"james_job_offer": JamesJobOfferModal,
	"james_job_short": JamesJobShortModal,
	"james_job_complete": JamesJobCompleteModal,
	"sell_menu": SellMenuModal,
	"nadia_supply": NadiaSupplyModal,
	"network_targets": NetworkTargetsModal,
	"network_sourcing": NetworkSourcingModal,
	"sell_vein_quote": SellVeinQuoteModal,
	"craft_components_menu": CraftComponentsMenuModal,
	"network_reference": NetworkReferenceModal,
	"movement_craft": MovementCraftModal,
	"movement_swap": MovementSwapModal,
	"dial_load_complication": DialLoadComplicationModal,
	"combat_setup": CombatSetupModal,
	"hq_ore_readout": HqOreReadoutModal,
	"hq_gym": HqGymModal,
	"lab_bench_recipe_book": LabBenchRecipeBookModal,
	"lab_bench_notes": LabBenchNotesModal,
	"lab_bench_probe_result": LabBenchProbeResultModal,
}

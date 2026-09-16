# One script per modal type; each exposes `static func build(container:
# VBoxContainer, data: Dictionary) -> void`. modal_layer.gd's chrome
# dispatches content here by type — adding a type is one script + one row.
class_name ModalRegistry
extends RefCounted

static var REGISTRY: Dictionary = {
	"seed_result": SeedResultModal,
	"cultivate_result": CultivateResultModal,
	"craft_result": CraftResultModal,
	"craft_batch_result": CraftBatchResultModal,
	"sale_result": SaleResultModal,
	"archie_deal_result": ArchieDealResultModal,
	"james_job_offer": JamesJobOfferModal,
	"james_job_short": JamesJobShortModal,
	"james_job_complete": JamesJobCompleteModal,
}

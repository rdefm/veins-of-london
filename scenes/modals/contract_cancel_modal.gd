class_name ContractCancelModal
extends RefCounted

# Confirm pop-up for cancelling an active BizBrief contract. data:
# { contractId, summary } — summary is the request line BizBrief shows.


static func build(container: VBoxContainer, data: Dictionary) -> void:
	var contract_id: String = data["contractId"]
	container.add_child(UI.heading("Cancel this contract?"))
	container.add_child(UI.label(data.get("summary", "")))
	container.add_child(UI.muted_label("Nothing more gets paid. What's already delivered stays delivered. The buyer will remember it."))
	container.add_child(MapCardStyle.footer([
		MapCardStyle.text_button("Keep", func(): Modal.close()),
		MapCardStyle.text_button("Confirm", func(): _confirm(contract_id)),
	]))


static func _confirm(contract_id: String) -> void:
	Contracts.cancel(contract_id)
	Modal.close()

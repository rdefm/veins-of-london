class_name Bank
extends RefCounted

# Transaction log for player.cash mutations (the Bank app, "Reynard's").
# Mirrors systems/notify.gd's append-and-evict-from-front shape (LOG_CAP).
# Entries are pure data -- no Node/Timer/Callable (R§2 state purity).
# Display-only: no interest, loans, or transfers.
# Ids come from state.nextBankId ("bank-<n>"), never the clock, so a seeded
# run's state is reproducible (R§2 bankLog).

const LOG_CAP := 50


static func record(amount: int, label: String) -> void:
	# One discarded draw per record keeps every later roll on the same stream.
	Rng.randi_range(1000, 999999)
	var id := "bank-%d" % GameState.state["nextBankId"]
	GameState.state["nextBankId"] += 1
	var day: int = GameState.state["world"]["day"]
	var entry := { "id": id, "amount": amount, "label": label, "day": day }
	var log: Array = GameState.state["bankLog"]
	log.append(entry)
	while log.size() > LOG_CAP:
		log.remove_at(0)
	EventBus.mark_changed()


# The first id number safe to issue after `log`'s entries: past every
# "bank-<n>" id, and at least log size + 1. Pre-counter entries carry
# all-digit clock ids, which no "bank-<n>" id can equal.
static func next_id_after(log: Array) -> int:
	var next := log.size() + 1
	for entry in log:
		var id := str(entry.get("id", ""))
		if id.begins_with("bank-") and id.substr(5).is_valid_int():
			next = maxi(next, id.substr(5).to_int() + 1)
	return next

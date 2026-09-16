class_name Bank
extends RefCounted

# Transaction log for player.cash mutations (the Bank app, "Reynard's").
# Mirrors systems/notify.gd's append-and-evict-from-front shape (LOG_CAP).
# Entries are pure data -- no Node/Timer/Callable (R§2 state purity).
# Display-only: no interest, loans, or transfers.

const LOG_CAP := 50


static func record(amount: int, label: String) -> void:
	var id := str(Time.get_ticks_usec()) + str(Rng.randi_range(1000, 999999))
	var day: int = GameState.state["world"]["day"]
	var entry := { "id": id, "amount": amount, "label": label, "day": day }
	var log: Array = GameState.state["bankLog"]
	log.append(entry)
	while log.size() > LOG_CAP:
		log.remove_at(0)
	EventBus.state_changed.emit()

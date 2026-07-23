extends Node

# Seeded RNG autoload. Every probabilistic system must draw randomness
# from here, never from RandomNumberGenerator/randi/randf directly —
# that's what makes seeded tests deterministic.

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()


func set_seed(seed_value: int) -> void:
	_rng.seed = seed_value


func randi_range(from: int, to: int) -> int:
	return _rng.randi_range(from, to)


func randf() -> float:
	return _rng.randf()


func chance(p: float) -> bool:
	return _rng.randf() < p


func rand_from(array: Array):
	return array[_rng.randi_range(0, array.size() - 1)]

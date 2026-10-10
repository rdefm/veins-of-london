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


func randf_range(from: float, to: float) -> float:
	return _rng.randf_range(from, to)


func chance(p: float) -> bool:
	return _rng.randf() < p


func rand_from(array: Array):
	return array[_rng.randi_range(0, array.size() - 1)]


# A new per-game seed (world.rollSeed) drawn from its own generator, so
# starting a game never shifts the seeded global stream.
func fresh_seed() -> int:
	var gen := RandomNumberGenerator.new()
	gen.randomize()
	return gen.randi()


# Stable [0,1) value for a key string: same key, same value, every run.
# Doesn't touch the global stream (event checks' deterministic rolls).
func stable_unit(key: String) -> float:
	var gen := RandomNumberGenerator.new()
	gen.seed = key.hash()
	return gen.randf()

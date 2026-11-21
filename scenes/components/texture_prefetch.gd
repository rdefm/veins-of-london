class_name TexturePrefetch
extends RefCounted

# Background texture loads shared across screens: request() starts threaded
# loads, take() collects one (or loads it synchronously when it was never
# requested or the request failed), release_all() collects whatever is left so
# no threaded request outlives the screen that wanted it.

static var _requested: Dictionary = {}  # path -> true while its threaded load is uncollected


static func request(paths: Array) -> void:
	for path in paths:
		if not path is String or path.is_empty() or _requested.has(path):
			continue
		if ResourceLoader.has_cached(path) or not ResourceLoader.exists(path):
			continue
		if ResourceLoader.load_threaded_request(path) == OK:
			_requested[path] = true


static func take(path: String) -> Texture2D:
	if _requested.erase(path):
		var prefetched := _collect(path) as Texture2D
		if prefetched != null:
			return prefetched
	return load(path) as Texture2D


static func release_all() -> void:
	for path in _requested:
		_collect(path)
	_requested.clear()


static func _collect(path: String) -> Resource:
	if ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		return null
	return ResourceLoader.load_threaded_get(path)

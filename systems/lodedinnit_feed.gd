class_name LodedInnitFeed
extends RefCounted

# LodedInnit Feed (hiring-spec §6): one faux post per time block from a
# weighted pool of candidates and hires, with a rolled likes count and 0-2
# canned comments. Entries live in state.hiring.feed (capped), newest last;
# `feedUsed` tracks each author's spent post indexes, so a post repeats only
# after that author's pool is exhausted. Display-only; static funcs only.

const KIND_INDIVIDUAL := "individual"


# Staff block step: rolls this block's post (skipped until the app exists).
static func post_block(block: int = -1) -> void:
	if not Hiring.is_app_unlocked():
		return
	var world: Dictionary = GameState.state["world"]
	if block < 0:
		block = int(world["timeBlock"])
	var author := _pick_author()
	if author == "":
		return
	var hiring: Dictionary = GameState.state["hiring"]
	var voice: Array = _voice(author)
	var used: Array = hiring["feedUsed"].get(author, [])
	var unused: Array = []
	for i in voice.size():
		if not used.has(i):
			unused.append(i)
	var index: int = Rng.rand_from(unused)
	used.append(index)
	hiring["feedUsed"][author] = [] if used.size() >= voice.size() else used
	var feed: Array = hiring["feed"]
	var seq := 1 if feed.is_empty() else int(feed[-1]["seq"]) + 1
	feed.append({
		"postId": "%s:%d" % [author, index], "seq": seq, "authorKind": KIND_INDIVIDUAL, "author": author,
		"day": int(world["day"]), "block": block,
		"likes": Rng.randi_range(int(GameData.LODEDINNIT_FEED["likes"]["min"]), int(GameData.LODEDINNIT_FEED["likes"]["max"])),
		"comments": _roll_comments(author),
	})
	var cap := int(GameData.LODEDINNIT_FEED["cap"])
	while feed.size() > cap:
		feed.pop_front()
	EventBus.state_changed.emit()


static func _voice(author: String) -> Array:
	return GameData.LODEDINNIT_VOICES.get(Hiring.candidate(author).get("voice", author), [])


# Weight by market status (authorWeights); authors without a voice never post.
static func _pick_author() -> String:
	var weights: Dictionary = GameData.LODEDINNIT_FEED["authorWeights"]
	var authors: Array = []
	var total := 0.0
	for candidate_id in Hiring.candidate_ids():
		if _voice(candidate_id).is_empty():
			continue
		authors.append(candidate_id)
		total += float(weights.get(Hiring.status(candidate_id)["state"], 1.0))
	if authors.is_empty():
		return ""
	var roll := Rng.randf() * total
	var picked: String = authors[0]
	for candidate_id in authors:
		picked = candidate_id
		roll -= float(weights.get(Hiring.status(candidate_id)["state"], 1.0))
		if roll < 0.0:
			break
	return picked


# Commenters are other individuals; each entry is "<commenterId>:<commentId>".
static func _roll_comments(author: String) -> Array:
	var others: Array = Hiring.candidate_ids().filter(func(id): return id != author)
	var comments: Array = []
	var count: int = mini(Rng.randi_range(0, int(GameData.LODEDINNIT_FEED["maxComments"])), others.size())
	for i in count:
		var commenter: String = Rng.rand_from(others)
		others.erase(commenter)
		comments.append("%s:%s" % [commenter, Rng.rand_from(GameData.LODEDINNIT_COMMENTS)["id"]])
	return comments


# Feed entries newest first.
static func entries() -> Array:
	var feed: Array = GameState.state["hiring"]["feed"].duplicate()
	feed.reverse()
	return feed


# Badge: posts after feedSeen.
static func unseen_count() -> int:
	var hiring: Dictionary = GameState.state["hiring"]
	var count := 0
	for entry in hiring["feed"]:
		if int(entry["seq"]) > int(hiring["feedSeen"]):
			count += 1
	return count


# Opening the Feed clears the badge. No state_changed emit: it runs inside the
# app's own rebuild, and the home tiles rebuild when the app closes.
static func mark_seen() -> void:
	var hiring: Dictionary = GameState.state["hiring"]
	if not hiring["feed"].is_empty():
		hiring["feedSeen"] = int(hiring["feed"][-1]["seq"])


# Display model for one entry; a later entry kind may carry its own "text".
static func card(entry: Dictionary) -> Dictionary:
	var author: String = entry["author"]
	var comments: Array = []
	for ref in entry["comments"]:
		var parts: PackedStringArray = String(ref).split(":")
		comments.append({ "author": Contacts.display_name(parts[0]), "text": _comment_text(parts[1]) })
	return {
		"name": Contacts.display_name(author), "initials": initials(Contacts.display_name(author)),
		"meta": "%s · %s" % [Hiring.role(author)["label"], status_text(author)],
		"time": time_label(int(entry["day"]), int(entry["block"])),
		"body": body_text(entry), "likes": int(entry["likes"]), "comments": comments,
	}


static func body_text(entry: Dictionary) -> String:
	if entry.has("text"):
		return entry["text"]
	var parts: PackedStringArray = String(entry["postId"]).split(":")
	var post: Dictionary = _voice(parts[0])[int(parts[1])]
	return post.get("variants", {}).get(Hiring.candidate(parts[0]).get("trait", ""), post["text"])


static func _comment_text(comment_id: String) -> String:
	for comment in GameData.LODEDINNIT_COMMENTS:
		if comment["id"] == comment_id:
			return comment["text"]
	return ""


static func initials(full_name: String) -> String:
	var result := ""
	for word in full_name.split(" ", false).slice(0, 2):
		result += word.substr(0, 1).to_upper()
	return result


static func status_text(candidate_id: String) -> String:
	match Hiring.status(candidate_id)["state"]:
		Hiring.STATUS_OURS:
			return "Works for you"
		Hiring.STATUS_EMPLOYED:
			return "Employed at %s" % Hiring.faction_name(Hiring.employer(candidate_id))
	return "Open to work"


static func time_label(day: int, block: int) -> String:
	var world: Dictionary = GameState.state["world"]
	var days_ago: int = int(world["day"]) - day
	if days_ago == 0:
		return "This block" if block == int(world["timeBlock"]) else "Earlier today"
	if days_ago == 1:
		return "Yesterday"
	return "%dd ago" % days_ago

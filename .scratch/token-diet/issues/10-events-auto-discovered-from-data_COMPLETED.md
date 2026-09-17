# 10 — Events auto-discovered from data/events/

**What to build:** The set of events the game loads is whatever lives in the events data directory — the hardcoded id lists in the data loader go away. Whether an event belongs to a district deck is read from the file's own deck sub-object, as the deck engine already does. Validation (unknown districts, malformed cards, id/filename agreement) stays as strict as today; a file whose id doesn't match its filename is a load error. Adding an event is now: drop a JSON file in the directory.

**Blocked by:** 03 — Comment strip: systems/ + autoload/.

**Relevant files:** `autoload/GameData.gd` (the two id-list consts, the events load + validate path), `data/events/*.json`, `systems/district_deck.gd`, `systems/events.gd`, `tests/test_gamedata.gd`, `tests/test_district_deck.gd`, `tests/test_events.gd`, `CODEMAP.md`. Directory listing must work in an exported build (use the resource directory API, not filesystem globbing).

**Status:** ready-for-agent

- [ ] Loaded event set after boot equals the set of files in the directory (asserted by a test); the roster consts are gone.
- [ ] Deck membership and weights unchanged for all district events (existing deck tests pass unmodified).
- [ ] A test proves a filename/id mismatch is reported as a load error.
- [ ] Works headless and in an exported Android/Web build (resource-dir listing, not OS globbing); full test suite green.

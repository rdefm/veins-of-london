# 02 — Live cards carry stable keys

**What to build:** Every card in every live event has a `key`, unique within its event, that survives promote and re-import. Promote keeps keys in the live JSON instead of stripping them; live events with no proposal get keys backfilled using the same naming legacy import uses (`c1`, `c2`, … by position). Boot validation rejects a missing or duplicate key. Re-promoting an existing proposal yields the same file plus its keys.

**Blocked by:** None — can start immediately.

**Relevant files:** `tools/storyboard.html` ("Draft model (pure)" section: `promoteDraft`, `promoteForWrite`, `legacyToDraft`), `tools/promote_storyboard.js`, `tools/test_storyboard.js`, `autoload/GameData.gd` (event card validation near `_validate_choice_card`), `data/events/*.json`, `.scratch/writing-revamp/*-proposal*.md` (existing keys), REFERENCE.md §3.9a Event choice checks.

**Status:** ready-for-agent

- [ ] Promote output keeps each card's `key`; `node tools/test_storyboard.js` covers it
- [ ] All live events have unique per-event card keys; keys already used by a proposal match the proposal
- [ ] Boot validation fails on a missing/duplicate key (test)
- [ ] Import → promote of a keyed live event is byte-identical
- [ ] REFERENCE.md documents the card `key` field
- [ ] Full suite + `scripts/check_all.sh` green

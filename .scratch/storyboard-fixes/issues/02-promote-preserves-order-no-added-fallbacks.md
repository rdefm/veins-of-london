# 02 — Promote preserves card order and adds no fallbacks

**Status:** ready-for-agent

**What to build:** Importing a live event into the storyboard tool and promoting it again reproduces the original event: same card order, no extra `{card: ...}` fallback entries appended to conditional `goto` lists, no added `end` fields. Today promote topologically re-sorts cards and normalises routing, so the four raid events (`raid_arches`, `vein_raid`, `stockpile_raid`, `stockpile_raid_stash`) do not round-trip. `raid_arches` and `vein_raid` also change meaning (an `else` fallback is added to `goto` lists that had none, plus `end:` on cards), so promoting them would alter live play. Preserve authored order on import (carry it through the draft, as `_keyOrder` already does for keys) and have promote emit cards in that order, falling back to the current topological order only for cards added in the tool. Do not synthesise a fallback or `end` where the source had none; fall-through semantics must stay as authored. Stockpile events also differ only in inline-vs-expanded JSON formatting of `check` objects: promote's serialiser must match the live files or the files must be reformatted by an agreed rule (check with the human before rewriting live data).

Do not redesign mechanics; if preserving order conflicts with promote's loop/hub validation, stop and ask.

**Blocked by:** None — can start immediately.

**Relevant files:**
- `tools/storyboard.html` — `promoteDraft` (ordering: `rank`, `preferred`, topological loop), `importedDraft`, `legacyToDraft`, `serialiseEvent`, `_keyOrder` handling (`inKeyOrder`)
- `tools/promote_storyboard.js` — CLI promote sharing the same logic
- `tools/test_storyboard.js` — "import → promote reproduces every live event byte-for-byte" (currently failing for the four events above)
- `data/events/raid_arches.json`, `vein_raid.json`, `stockpile_raid.json`, `stockpile_raid_stash.json`
- Skill: `implement-storyboard-event`; `docs/writing-guide.md` only if event structure rules apply

- [ ] The byte-for-byte round-trip test passes for every live event, including the four raid events, with no events excluded
- [ ] Round-tripped events deep-equal the originals including card order; no `goto` entries or `end` fields added
- [ ] Cards newly added in the tool still get a valid order and promote still rejects loops/stuck hubs as before
- [ ] Existing promote tests (pick options, `promoteGate`, CLI parity with the Promote button) still pass
- [ ] Live event files are not rewritten unless the human approved a formatting rule

# 01 — Event card stills prefetch in the background

**What to build:** When an event card is shown, the stills for the cards the player can reach next (the next card, plus each option's target on a choice card) start loading on a background thread. When one of those cards is shown, its still comes from the prefetched request; if it isn't ready yet (or wasn't prefetched), the card falls back to today's synchronous load. No visible change except no hitch when a card with a new still opens. Source: code review 2026-11-21 item 9 (`.scratch/code-review/recommendations.md`).

Zero gameplay change: presentation only, no state touched. The rule that screens never mutate state still applies — the prefetch lives entirely Node-side; any "which cards are reachable next" lookup that needs event data is a pure read (put a small static helper in the Events system if one doesn't already exist, with a test).

**Blocked by:** None — can start immediately.

**Relevant files:**
- `scenes/screens/event.gd` (~line 991–992: `ResourceLoader.exists` + `load(image_path)` for `_vn_texture`)
- `systems/events.gd` (card/option/goto structure, current card key)
- `data/events/*.json` (card image paths)
- `docs/ui-vision.md` (event card presentation, for context only)

**Status:** ready-for-agent

- [ ] Opening a card issues `ResourceLoader.load_threaded_request` for every distinct still reachable from it that isn't already loaded/requested
- [ ] Showing a card uses `load_threaded_get` when a request exists, synchronous `load` otherwise; missing/invalid paths behave exactly as today (no still shown)
- [ ] Outstanding requests are not leaked when the event closes or the screen is freed (no errors at exit beyond the current baseline)
- [ ] Any new reachability helper in the Events system is pure and covered by a test in `tests/`
- [ ] Syntax check clean on touched files; full suite passes
- [ ] Report lists the on-device check: step through a multi-still event (e.g. one with several shot changes) — stills appear as before, no stall on card change

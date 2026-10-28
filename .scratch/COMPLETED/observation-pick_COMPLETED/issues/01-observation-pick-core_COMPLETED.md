# 01 — Observation pick: core mechanic

**Status:** ready-for-agent

**What to build:** A new kind of event option, the **observation pick**: one option that lets the player act on (or mention) something they observed, instead of one gated option per ore. Solves the 4-option cap (`Events.MAX_OPTIONS`) when several ores each deserve their own follow-up, and is the same mechanic for dialogue ("mention something you noticed") and raids ("act on what you saw") — the option's label makes clear it's a choice, not just speech.

Player flow:
- The option renders like any other option (its own label).
- Tapping it opens the Observe sheet in **pick mode**: each ore row that has a pick on this option and whose current-run level ≥ that pick's `atLeast` is tappable; the rest render greyed.
- Tapping a qualifying row commits the option with that ore's outcome (its `result_text`, `effects`, `goto` — the same outcome shape as a normal option).
- Closing the sheet without picking cancels: nothing is committed, the card's options show again.
- If no ore qualifies (including the player never having observed), the option shows **greyed** with a reason, using the existing disabled-option `?` modal (R§3.9a Requires `display: "disable"`). A default reason is fine; an authored `reason` overrides it.
- A Rewind re-roll that raises a level can make a previously unavailable pick available (no special handling beyond reading current levels).
- One pick per card for now. Multi-pick (raise several things on one card, e.g. via `reselectable` hub) is out of scope, but the schema must leave room for it.

Schema sketch (decision-rich parts only; final names are the implementer's call, written into REFERENCE §3.9d first):
```json
{ "id": "mention", "label": "\"Actually, Arch…\"",
  "pick": { "observation": "<obsId>", "reason": "You didn't spot anything worth saying.",
    "ores": {
      "physics": { "atLeast": 2, "result_text": "...", "effects": [], "goto": "..." },
      "emotion": { "atLeast": 1, "result_text": "..." } } } }
```
- Several tiers of the same ore can lead to different outcomes (e.g. top tier vs mid tier get different responses). Shape TBD — e.g. a list of `{atLeast, ...outcome}` per ore, best-first, first match wins. Pin it in the spec.
- Choice memory records the picked ore (e.g. option id + ore) so later `choice` conditions can test what was raised. Pin the stored form in the spec.

Update REFERENCE.md first (§3.9d Observation, plus the §3.9a option schema / Requires paragraph where the gate is described), then build to it.

**Blocked by:** None — can start immediately.

**Relevant files:**
- `systems/events.gd` — `option_gate()`, `choose()`, `condition_met()` (the `observed` branch), choice memory (`choice_id`)
- `systems/observation.gd` — `observed()`, `_stored()`, `rows()`, `option_ores()`, `read()`
- `scenes/screens/event.gd` — `_open_observation_sheet()`, `_on_observe_picked()`, option rendering + disabled `?` modal (~L486, ~L612), `_reveal_unlocked_options()`
- `tests/support/event_content_lint.gd` — add lint: pick names a defined observation, each ore exists in it, `atLeast` in 1..tiers, outcome shape valid
- `tests/test_events*.gd`, `tests/test_observation*.gd` (whichever exist) — new tests
- `docs/REFERENCE.md` §3.9d Observation, §3.9a (option schema, Requires, choice memory)
- `CODEMAP.md` if a file's responsibility changes

- [ ] REFERENCE §3.9d documents the pick option schema, qualification rule, pick-mode sheet, cancel, greyed-with-reason fallback, choice memory form, Rewind interaction
- [ ] Engine: an option with a pick is "show" only when ≥1 ore qualifies, else "disable" with reason; `choose()` with a picked ore runs that ore's outcome; choosing without a valid ore is refused
- [ ] Choice memory records the picked ore; a `choice` condition can match it
- [ ] After Rewind + re-roll improving a level, a newly qualifying ore is pickable
- [ ] Screen: tapping the option opens the sheet in pick mode, qualifying rows tappable, others greyed; closing without a pick commits nothing
- [ ] Event content lint covers pick refs; existing events still lint clean
- [ ] Headless tests for the above; `scripts/run_tests.sh` + `scripts/check_all.sh` clean
- [ ] Human on-device check list in the report (sheet pick mode, greyed option + `?` modal, cancel)

# 30 — Profile alert cover roll + covered/uncovered line

**What to build:** An item's event profile alert may carry a cover (same shape as the `alert` op's cover: base, optional mods). Each time the item is spent, its profile alert gets its own cover roll; a passed cover leaves the alert unchanged, a failed one raises it as the profile says (Blast +1, clamped). Be A Lady raises the cover probability. After every profile-alert cover roll the card always shows a covered or uncovered line: generic lines live in data, and an option may override either with `coveredText` / `uncoveredText`. Applies to any profile alert, not just Blast. Blast's profile gets a default cover.

**Blocked by:** None — can start immediately (22 is done).

**Relevant files:** `systems/events.gd` (`_apply_profile_alert`, `_apply_alert`, `_roll_cover`, `cover_roll`, `odds_for`), `data/recipes.json` (Blast `eventProfile`), `data/constants.json` (event-checks strings), `tests/test_events.gd`, the content-lint test; REFERENCE §3.9a.

**Status:** ready-for-agent

- [ ] Profile alert accepts a cover; lint validates it
- [ ] Each use rolls its own cover (deterministic, Rewind/save safe)
- [ ] Be A Lady raises the cover probability (test: higher with lady level than without)
- [ ] Covered: alert unchanged; uncovered: raised per the profile, clamped
- [ ] After every such roll the card shows the covered or uncovered line: generic from data, overridable per option
- [ ] New generic strings listed PROSE-REVIEW
- [ ] REFERENCE §3.9a updated

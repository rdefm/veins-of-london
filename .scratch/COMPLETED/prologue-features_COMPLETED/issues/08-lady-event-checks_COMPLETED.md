# 08 — Be A Lady: event check bonus

**What to build:** Every event choice with a % `check` gets better odds while Be A Lady is active: +X per Lady level (placeholder, data), shown as a labelled mod ("Be A Lady") in the odds readout, within the check's min/max clamp. Source: `docs/story-restructure.md` "Features to build" item 4.

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/events.gd` (`odds_for` L495, `_mod_delta`, check resolution ~L378), `systems/active_effects.gd`, `scenes/screens/event.gd` (odds readout), `data/constants.json` (`EVENT_CHECKS`). REFERENCE §3.9a Event choice checks.

**Status:** ready-for-agent

- [ ] With Lady active, `odds_for` adds the Lady mod to every check, labelled, and still clamped by the check's min/max.
- [ ] Without Lady, odds are unchanged.
- [ ] The odds hint word/readout reflects the boost.
- [ ] REFERENCE §3.9a is updated. Tests cover with/without Lady, and clamping.

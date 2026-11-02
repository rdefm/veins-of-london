# 18 — Déjà Vu (implement `reveal` item effect)

**What to build:** A new item-effect kind, `reveal`. Toggling Déjà Vu on a check shows the roll it will get before commit, per 17's cap and Rewind rules. Revealed rolls are stored as pure data in the event run state.

**Blocked by:** 17

**Relevant files:** `systems/events.gd`, `systems/event_items.gd`, `systems/rewind.gd`, `scenes/screens/event.gd`, `tests/test_event_items.gd`; REFERENCE §3.9a.

**Status:** needs-info

- [ ] The revealed roll equals the committed roll; the cap is enforced
- [ ] Save/reload and Rewind behave per 17
- [ ] REFERENCE §3.9a documents `reveal`

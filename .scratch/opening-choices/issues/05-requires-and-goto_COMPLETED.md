# 05 — Option gating (`requires`) and short branches (`goto`)

**What to build:** An option can declare `requires` using the same condition vocabulary as check modifiers (flag, choice, path ≥, relation ≥, cash ≥, item held/equipped) plus `"display": "hide" | "disable"` and a `reason` ("Needs £50"). Hidden options don't render; disabled ones render greyed with the reason and can't be committed. A plain option or a check outcome can carry `goto` to jump forward to a later card in the same event, giving short branches that rejoin the main line.

**Blocked by:** 02 — Check core (shares the condition evaluator).

**Relevant files:** `systems/events.gd` (`advance`, `choose`, `is_awaiting_choice`, `revealed_cards`, `rewind`), `scenes/screens/event.gd`, `tests/test_events.gd`, `tests/test_event_screen.gd`, REFERENCE.md check-schema section, `CODEMAP.md`.

**Status:** ready-for-agent

- [ ] One condition evaluator shared by mods and `requires`.
- [ ] Hide vs disable+reason tested; disabled option can't be committed.
- [ ] `goto` forward only; backwards/out-of-range rejected at runtime.
- [ ] Revealed-cards history and Rewind correct across a jump (test).
- [ ] Disabled reason readable at phone width.

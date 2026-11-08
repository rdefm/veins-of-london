# 04 — Set event triggers in the tool

**What to build:** Events in `data/events/` already auto-load, so a new event only lacks a way to fire. After this ticket, the user can create or edit an event in the storyboard tool, set when it fires, promote it, and have it reachable in play with no Claude step.

Add a Triggers panel for the event's top-level trigger fields, using dropdowns from known data rather than free text:

- **`deck`:** district, weight, `excludeIfFlag`, `barometerState`
- **`pin`:** district, `showWhenFlagsTrue`, `showWhenFlagsFalse`, contact, `phoneLabel`
- **`at`** (REFERENCE §3.9b)
- **`repeatable`**

An event with no trigger and no inbound reference gets a non-blocking "nothing fires this" warning. Flag fields use the shared flag picker if the quest editor has shipped it, otherwise a plain field that gets upgraded later.

Also correct `docs/agents/quest-drafts.md`, which still describes a registration step, and any similar stale wording. The mobile quest tool itself is retired: don't extend it.

**Blocked by:** 01 — Import → Promote round trip is lossless

**Relevant files:** `tools/storyboard.html`, `tools/test_storyboard.js`, `tools/lint_refs.json`, `systems/district_deck.gd`, `systems/events.gd`, `tests/test_event_content_lint.gd`, `docs/agents/quest-drafts.md`, `docs/M1-LONDON.md`, `data/districts.json`, `data/barometer.json`; REFERENCE §3.9b

**Status:** ready-for-agent

- [ ] Each trigger field can be set, changed and cleared in the tool
- [ ] Trigger fields survive Save and Promote exactly
- [ ] A new event given a deck entry from the tool appears in that district's deck in-game, verified headless
- [ ] A new event given a pin appears under its flag conditions, verified headless
- [ ] JS lint and GDScript lint agree on trigger validity
- [ ] The "nothing fires this" warning appears only when true, and never blocks
- [ ] Stale registration docs corrected

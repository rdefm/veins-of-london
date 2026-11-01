# 03 — Fix repeating result card in raid_shop

**What to build:** In raid_shop, after taking "round the back", the resolution card "The pins come out with some persuasion..." shows once. It currently reappears later (e.g. after picking a stockroom option, and in the cellar). Diagnose root cause first, then fix generally in the event engine (not by editing the event data), so no event re-shows a stale resolution. Suspected: `choiceResults` / visited cards keyed by cardIndex, so a stale result resurfaces when goto revisits or passes a card.

**Blocked by:** None — can start immediately

**Relevant files:** `systems/events.gd` (`revealed_cards`, `_visited_indices`, `choose`, `_goto_target`, `_continue`), `data/events/raid_shop.json` (~L985 back-door success), `tests/test_events.gd`. REFERENCE §3.9a Event choice checks.

**Status:** ready-for-agent

- [ ] Root cause stated in report
- [ ] "Pins come out" card shows exactly once through back door → stockroom → cellar path
- [ ] Hub reselect / goto loops in other events still behave as before
- [ ] Regression test reproducing the raid_shop path

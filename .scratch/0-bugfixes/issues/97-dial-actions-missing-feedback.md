# 97 — Dial seed/Movement-craft actions give player feedback

**What to build:** `scenes/screens/hq.gd`'s Dial card discards the return value of both `Dial.attempt_seed()` and `Dial.attempt_craft_movement()` — so tapping "Seed as X" or a Movement-crafting ore button gives the player zero feedback on the outcome. If the attempt is refused outright (e.g. not enough calc), the state doesn't change at all and the screen looks identical before and after the tap — reads as the button doing nothing. Even a real roll failure (spends calc, no Dial/Movement gained) is silently invisible today. This affects every player, not just debug testing.

**Confirmed mechanics (from 2026-08-29 grill-me session):**

- Both call sites should surface their result via `Notify.push()`, matching how the rest of the game surfaces action results (e.g. `Dial.cast_complication()`'s own level-up notification).
- Cover all three outcomes for each action: outright refusal (show the `reason` string returned), a failed roll (calc spent, no Dial/Movement gained), and success.

**Where:** `scenes/screens/hq.gd` (`_build_dial_card()`'s "Seed as" buttons, `_build_movement_crafting_section()`'s ore buttons), `systems/dial.gd` (`attempt_seed()`, `attempt_craft_movement()` — return shapes already carry everything needed, no signature changes expected).

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] Tapping "Seed as X" when refused (e.g. insufficient calc, no gift, already have a Dial) shows a notification with the specific reason.
- [ ] Tapping "Seed as X" on a failed roll shows a distinct failure notification (calc was spent, no Dial gained).
- [ ] Tapping "Seed as X" on success shows a success notification.
- [ ] Tapping a Movement-craft ore button gets the same three-outcome feedback treatment.
- [ ] Test coverage: not required beyond existing `Dial` system tests (this ticket is UI wiring only) — a manual check is sufficient, noted below.
- [ ] `godot --headless -s scripts/check_runner.gd -- path/to/file.gd` clean on every touched file.
- [ ] Manual check noted for the human: with insufficient calc, confirm a refusal notification appears; with enough calc, tap repeatedly until both a failed and a successful roll are observed, confirming distinct notifications each time.

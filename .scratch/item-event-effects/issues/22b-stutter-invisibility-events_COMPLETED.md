# 22b — Stutter and Invisibility in events

**What to build:** Both items work in events.

- **New effect kind `autoSuccess`** (check options only): the check isn't rolled and resolves as its `success` outcome. The item is spent on commit. The option's own alert raise and cover roll are skipped. It applies to that one check only, never lasting. The outcome marker shows a line naming the item instead of the d100 roll line (UI string in data, PROSE-REVIEW).
- **Invisibility profile:** tags `stealth`, kind `autoSuccess`. Auto-offered on every `stealth`-tagged check via ticket 21's mechanism. Shown greyed out when not payable; respects `excludeItems` and authored-mod precedence.
- **Stutter profile:** no tags, authored only (like Sod's Law). It's a guaranteed pass, authored with ticket 22's no-roll item-gated option shape (no roll, always succeeds, no built-in alert change). Typical use: sneaking past someone.
- **Gating:** both items can also gate options the author writes (`requires`), shown greyed out with the item named when not held.
- **Lint:** reject `autoSuccess` on a non-check option and malformed profiles for these items. `stealth` is a known tag (added in 20).
- **Out of scope:** no existing event content is changed. Adding Stutter/Invisibility beats to live events (e.g. `raid_playground`'s sneak-in) comes later as one-prose-beat tickets referencing `docs/writing-guide.md`.

**Blocked by:** 22

**Relevant files:**
- Systems: `systems/events.gd`, `systems/event_items.gd`.
- Data: `data/recipes.json` (item event profiles), `data/constants.json` (tag vocabulary, UI strings).
- Tests: `tests/test_event_items.gd`, `tests/test_events.gd`, `tests/test_event_content_lint.gd`.
- Docs: `.scratch/item-event-effects/spec.md`; REFERENCE §3.9a Event choice checks.

**Status:** ready-for-agent

- [ ] A `stealth` check auto-offers Invisibility: switchable when payable, greyed and refused when not; untagged/other-tag checks don't offer it
- [ ] Toggled Invisibility: no roll, success outcome, item spent, option's alert raise and cover roll skipped, marker line shown
- [ ] Dial-paid Invisibility behaves the same
- [ ] Stutter appears only where authored; its option always succeeds with no roll and is spent
- [ ] Item-gated options show greyed out with the item named when not held
- [ ] Rewind refunds the spent item; save/reload mid-event keeps state
- [ ] Lint rejects `autoSuccess` on a non-check option and malformed profiles
- [ ] REFERENCE §3.9a documents `autoSuccess` and both profiles; new strings flagged PROSE-REVIEW

# 06 — Move level-up notice names the gain

**Visual spec:** `.scratch/move-book/move-book.html` (live copy: https://claude.ai/artifact/FPL7F27VL6oHT5DTsSYgFR), placement "5 · Level-up notice". If this ticket and the mock disagree, stop and ask.

**What to build:** The existing move level-up Notification says what changed:
- Lv3 / Lv5: "{Move} reached Lv{n}" + "Unlocked: {unlock line}", with the milestone diamond.
- Lv2 / Lv4: "{Move} reached Lv{n}" + the stat change, e.g. "Damage +4 → +8" (Feint Lv4 also "Greater chance to auto-guard").
- Tapping the notice opens the Profile Move Book on that owner and move, expanded.
- Same text for recruits' level-ups (names the recruit). Strings from 02's data.

**Blocked by:** 02 — Move Book in the Profile app.

**Relevant files:**
- `systems/combat_rounds.gd` (`levelUp` beat, transcript line)
- `systems/move_levels.gd` (`award`)
- `systems/notify.gd`
- `scenes/phone_apps/profile_app.gd` (open on a given owner/move)
- `tests/test_combat_rounds.gd`

**Status:** ready-for-agent

- [ ] Notice text at Lv2, Lv3, Lv4, Lv5 matches the data strings (tests)
- [ ] Tapping opens Profile on the right owner/move, expanded
- [ ] PROSE-REVIEW: new notice strings flagged
- [ ] Human check: notice reads clearly on-device

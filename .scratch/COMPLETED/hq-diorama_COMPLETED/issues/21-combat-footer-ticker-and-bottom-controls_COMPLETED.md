# 21 — Combat menu: ticker under stage, dial/buttons pinned to bottom

**What to build:** `scenes/screens/combat.gd`'s mid-fight footer currently
stacks (via `_build_command_deck()`, inside `_footer_holder` which sits
right after the stage frame) the dial + complication detail + action row
first, then the combat log below it (`_build_log()`, up to 6 visible
lines). Reorder so the stage image (animations) is immediately followed by
the combat log ("ticker"), shrunk to ~2-3 visible lines, and the dial +
action row (attack/item/run) sits at the bottom of the screen with more
vertical space than the current compact row. Turn-order strip
(`_strip_holder`, above the stage) is unchanged. The post-combat state
(outcome resolved: log + outcome button, no command deck) already renders
the log directly under the stage and needs no change.

**Blocked by:** None — can start immediately

**Status:** ready-for-agent

- [ ] Mid-fight: combat log renders directly below the stage frame, before the dial/action row
- [ ] Combat log shows at most ~2-3 lines mid-fight (down from 6)
- [ ] Dial + complication detail + attack/item/run row renders at the bottom of the screen, given more vertical space than today
- [ ] Turn-order strip position and post-combat (outcome resolved) footer layout unchanged
- [ ] `tests/test_combat_screen.gd` updated for the new footer child order

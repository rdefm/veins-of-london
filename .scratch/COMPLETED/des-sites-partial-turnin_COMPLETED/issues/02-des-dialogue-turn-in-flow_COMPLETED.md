# 02 — Des dialogue turn-in flow (first + second report scenes)

**What to build:** Wire ticket 01's per-site reporting mechanic up to a player-facing action on Des' Contacts card. Whenever a qualifying, not-yet-reported site currently exists (fate or physics, matching `col_a1_des_sites`'s criteria) and the Des thread is active, show a "report to Des" action (same conditional-action-bar pattern as `build_des_report_action()` in `scenes/components/contact_cards.gd`).

Triggering it calls ticket 01's reporting mechanic and plays one of two new short event cards:
- **First report:** a brief new scene where Des reacts to the single site handed over and notes a second (naming the still-needed ore type) is still wanted. New prose — **PROSE-REVIEW**.
- **Second/final report:** a reworked version of the existing `col_a1_des_report` scene, adapted from its current "you give Des two addresses at once" framing (which no longer fits, since the two are now reported separately) to react to the second/closing report. New prose — **PROSE-REVIEW**.

The action should vanish once a given ore type has been reported (mirroring the "vanish, don't disable" convention `build_des_report_action()`/`build_nadia_meet_action()` already use), and disappear entirely once both are reported and the thread is done.

**Blocked by:** 01 — Per-site reporting mechanic for Des' find-ground quest.

**Status:** ready-for-agent

- [ ] Des' Contacts card shows a "report to Des" action whenever a qualifying unreported site currently exists, using the existing conditional-action-bar convention.
- [ ] Triggering the action for the first report calls ticket 01's mechanic and plays the new first-report scene naming which ore type is still needed.
- [ ] Triggering the action for the second report calls ticket 01's mechanic and plays the reworked final scene, then closes out the thread the same way `col_a1_des_report`'s `on_complete` does today (relation already awarded per-report by ticket 01, so this event's `on_complete` should not double-award it).
- [ ] The action vanishes once both ore types are reported; is never shown disabled.
- [ ] Both new/reworked scenes are flagged `PROSE-REVIEW` in the completion report per the content guide.
- [ ] Manual end-to-end playtest: find one qualifying site, report it, confirm the first scene and partial relation gain; find the second, report it, confirm the final scene, full thread completion, and both sites showing as Collective veins.

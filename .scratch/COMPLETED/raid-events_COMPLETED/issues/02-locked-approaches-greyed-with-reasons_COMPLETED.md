# 02 — Locked approaches show greyed with a `?` and the reasons

**What to build:** An event option the player can't use yet shows greyed with a `?` instead of being hidden. Tapping `?` opens a modal listing each missing requirement — which observation tier (ore + tier name) and/or which item — derived from the option's `requires` condition, so writers don't hand-write a reason per option (an authored `reason` may still override/add). Compound conditions (observation AND item) list every unmet part, not the met ones. `vein_raid`'s five observation-gated approaches switch to the greyed display.

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/events.gd` (`option_gate()` ~L588, `condition_met()` ~L548 condition vocabulary), `scenes/screens/event.gd` (`_build_disabled_option()` ~L534, modal content ~L629), `systems/observation.gd` (`observed()`, tier names), `data/events/vein_raid.json`, `tests/test_events.gd`, `tests/test_event_screen.gd`, `docs/REFERENCE.md` §3.9a Event choice checks, §3.9d Observation.

**Status:** ready-for-agent

- [ ] A system function returns the unmet requirement lines for an option (observation tier, item held/toggled, both); screen only renders them
- [ ] Only unmet parts are listed; a met option shows normally
- [ ] `vein_raid` gated approaches render greyed with `?`, never hidden
- [ ] Tests: reasons for observation-only, item-only and combined gates; met gate returns none
- [ ] New UI strings flagged `PROSE-REVIEW:`
- [ ] Human on-device check: greyed row, `?` opens modal with correct lines

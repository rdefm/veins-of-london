# 13 — Blocked cultivate/harvest shows its reason

**What to build:** When Cultivate or Harvest on a vein returns `{ok:false, reason}` (frozen by injunction, work banned this block, no blocks left), the player sees the reason instead of nothing happening. First check whether the vein card action handler already surfaces it; if so, close this as already-working.

**Blocked by:** None — can start immediately.

**Relevant files:** `scenes/screens/map.gd` (`_on_vein_bubble_action_selected`), `scenes/components/vein_bubble.gd` (`_select_action`), `systems/cultivating.gd` (`cultivate`, `prune`), `systems/harassment.gd` (`vein_gate`), `systems/notify.gd`.

**Status:** ready-for-agent

- [ ] Frozen vein: tapping Cultivate shows "Frozen by injunction."
- [ ] Work-banned block: shows "Work banned this block."
- [ ] Same for Harvest; no silent no-op remains
- [ ] Screens only call systems; message wording flagged `PROSE-REVIEW:` if new

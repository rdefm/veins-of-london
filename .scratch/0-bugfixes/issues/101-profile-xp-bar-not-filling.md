# 101 — Fix Profile app skills XP bar not filling

**What to build:** The Profile app's skills section shows a progress bar meant to fill as the player earns XP toward the next level, but it does not visibly update in play. Diagnose the real end-to-end cause rather than assuming from a read of the render code — check whether the XP-award call sites actually cause the currently-open Profile/skills tab to rebuild (e.g. whether `EventBus.state_changed` fires after an XP award, and whether the phone screen's refresh dispatch actually re-renders this tab), and fix the actual break in that chain.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] Reproduce the bug end-to-end (earn XP in a skill while the Profile/skills tab is open, or navigate to it after earning XP) and confirm the bar doesn't update before fixing anything.
- [ ] Root cause identified and fixed at the source (not papered over with a forced redraw).
- [ ] XP bar visibly fills proportionally as XP is earned, for all three skills (crafting, cultivating, stealth).
- [ ] Regression test covering an XP award followed by a Profile/skills tab render showing the updated bar value.

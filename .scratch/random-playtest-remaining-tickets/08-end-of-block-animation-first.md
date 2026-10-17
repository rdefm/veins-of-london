# 08 — End-of-block animation plays first

**What to build:** When a time block ends, the time-transition animation starts immediately and plays smoothly; the simulation work runs alongside it (chunked across frames / deferred) instead of freezing the frame first. Results (Morning Brief, notifications, screen re-render) appear only once both animation and work are done; input stays blocked until then. State purity and Rewind unaffected.

**Blocked by:** 07 — End-of-block lag: profile and optimise

**Relevant files:** `scenes/components/time_transition.gd`, `scenes/screens/hq.gd` (calls TimeSystem), `scenes/Main.gd`, `scenes/components/top_bar.gd`, `systems/time_system.gd`, `systems/morning_accounts.gd`

**Status:** ready-for-agent

- [ ] Animation's first frames render before heavy work starts
- [ ] Work chunked/deferred so the animation holds frame rate
- [ ] Results revealed after both complete; taps during transition can't double-advance
- [ ] Systems stay Node-free (orchestration in screen layer or via resumable system steps)
- [ ] Tests pass; human checks smoothness on device

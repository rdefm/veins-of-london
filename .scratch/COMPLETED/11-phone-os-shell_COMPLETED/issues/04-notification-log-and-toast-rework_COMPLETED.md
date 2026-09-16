# 04 — Notification log + toast rework

**What to build:** Rework notification state and toast rendering so at most 2 toasts show at once, auto-fade, queue on overflow, are suppressed entirely during combat, and feed a persistent capped log — demoable via toasts alone, no dedicated viewer screen required yet.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] Notification entries store as pure data (`id`, `text`, `seen`, `day`) — no Timer, Node, or Callable ever enters game state
- [ ] Log is capped at the 50 most recent entries
- [ ] Entries gain a `seen` flag instead of being deleted on dismiss
- [ ] At most 2 toasts visible at once; overflow queues and slides in as earlier ones fade
- [ ] Toasts auto-fade after a few seconds without requiring a tap
- [ ] Tapping a toast only dismisses it from view — never navigates, never removes it from the log
- [ ] While combat is active, toasts do not render at all; queued entries hold and drain once combat ends
- [ ] All fade/queue timing lives in the toast component, not in game state
- [ ] A snapshot/Rewind round-trip test confirms the notification log reverts correctly (a rewound day doesn't remember notifications for events that no longer happened)
- [ ] Tests cover: 50-entry cap eviction, `seen` transitions, max-2-visible + queue drain, full suppression while combat is active

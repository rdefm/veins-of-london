# 111 — Combat screen top bar renders under the OS status bar (Android)

**What to build:** On the Combat screen (Android), "Day 1 · Morning (0/3)" and
cash render directly under/behind the Android system status bar (clock,
notification icons, battery) instead of clearing it — `UI.safe_area_top_inset()`
isn't accounting for the OS chrome on this screen/device. Combat isn't in
`scenes/Main.gd`'s `TOP_BAR_HIDDEN_SCREENS`, so the global TopBar is expected to
show there like everywhere else, just positioned wrong. This is a distinct bug
from ticket 110's HQ/Phone scroll-through issue (different screen, different
symptom — the bar sits under OS chrome from the first frame rather than being
scrolled past) — do not merge the fixes.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] Reproduced on an Android build showing the top bar text overlapping the
      OS status bar on the Combat screen specifically.
- [ ] Root cause identified — why `UI.safe_area_top_inset()`/`TopBar`'s
      positioning doesn't clear the OS status bar on this screen when it's
      expected to.
- [ ] Day/time-blocks/cash render fully below the OS status bar on Combat,
      matching how the bar behaves on screens where this isn't reported.
- [ ] Checked whether this is Combat-specific or would recur on any screen
      entered by a similar path (e.g. straight into an event/fight from a
      cold start) — noted in the ticket even if out of scope to fix here.

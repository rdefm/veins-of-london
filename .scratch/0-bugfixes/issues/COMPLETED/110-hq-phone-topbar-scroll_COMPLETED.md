# 110 — HQ/Phone top bar covers content on scroll (Android)

**What to build:** On Android, scrolling the HQ or Phone tab causes text/
buttons to render above the persistent top bar (`scenes/components/top_bar.gd`'s
`TopBar`, day/time-blocks/cash/bag), and the bar can cover content — not
reproduced on desktop/editor, and not reproduced on other screens sharing the
same `UI.screen_body()` skeleton (Contacts, Factions, Lab, Vein List). Diagnose
why HQ and Phone specifically misbehave when the shared skeleton and clearance
math (`UI.top_bar_clearance()`) look structurally identical across all of them
— `scenes/screens/phone.gd`'s bespoke non-skeleton layout for its Messages
conversation view (`UI.anchor_below_bars()`) is one lead worth checking first,
since it's the one thing that makes Phone's layout diverge from the plain
skeleton HQ otherwise shares with the screens that don't show the bug.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] Reproduced on an actual Android build (or as close to the real export
      target as this project's tooling allows) before attempting a fix.
- [ ] Root cause identified and documented — why HQ/Phone diverge from
      Contacts/Factions/Lab/Vein List, which share the same skeleton.
- [ ] Scrolling HQ and Phone to their full extent never shows content above
      the persistent top bar, and the bar never covers unscrolled content.
- [ ] Fix verified on-device (or the closest available equivalent) — flag
      explicitly if only headless/desktop verification was possible.

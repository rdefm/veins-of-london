# 37 — Dock bar chrome (background bar + active-tab state)

**What to build:** `NavBar` (`scenes/components/nav_bar.gd`) is a bare `Control` with three `AppTile`s dropped in an `HBoxContainer` — no background panel behind the bar itself, so the 3 dock slots (Phone · Map · HQ) currently float directly over whatever screen is behind them with no visible bar/frame at all. Give the dock bar a real background panel (reuse the themed `Panel` style `UI.card()` already draws from in `main_theme.tres`, or a dedicated bottom-bar style if that reads better at `BAR_HEIGHT` — human's call). This is dock-bar chrome specifically — ticket 36 gives each individual `AppTile` its own placeholder frame; this ticket is about the bar surface those tiles sit inside of.

**Blocked by:** 36 (app tile placeholder frame) — do this after so the per-tile frame and the bar background are designed to sit together, not fought over separately.

**Status:** ready-for-agent

- [ ] The dock bar (`NavBar`, `scenes/components/nav_bar.gd`) renders a visible background panel behind the 3 tiles, distinguishing it from the screen content above it.
- [ ] Panel style is visually consistent with the rest of the phone/nav chrome (reuse the existing themed Panel style rather than inventing a new one, unless it doesn't read well at `BAR_HEIGHT` — human's call if unspecified).
- [ ] Active-tab highlight: `NavBar._refresh()` currently has no notion of "which screen is currently active" — none of the 3 tiles indicate the current screen. Add one (human's call on exact treatment — e.g. a tint, an underline, a filled vs. outline background on the active tile). This was folded into the same ticket as the bar background since both are "make the dock read as a dock" fixes to the same component; split it out if it turns out to be bigger than expected.
- [ ] Locked-Map rendering (padlock + tooltip/toast, already correct per ticket 11 of `11-phone-os-shell`) is unaffected by the new chrome.
- [ ] `tests/test_nav_bar.gd` covers: bar background presence, active-tab indicator matching `GameState.state["currentScreen"]` (and, for Phone, matching home vs. an open app per `PhoneNav`), locked-Map state still renders correctly alongside the new chrome.

**Human should check on-device:** the bottom dock reads as a single bar (not 3 floating labels), and the currently-open tab is visually distinguishable from the other two.

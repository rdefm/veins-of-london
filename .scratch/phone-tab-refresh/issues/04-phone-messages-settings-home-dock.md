# 04 — Phone, Messages, and Settings home dock

**What to build:** Add the simulated phone's home-only translucent/dark rounded dock with exactly Phone, Messages, and Settings, spaced symmetrically around its centre. Make all three real destinations without adding game mechanics: Phone is a recent-calls placeholder, Messages restores a conversation index that opens the existing threads, and Settings takes ownership of the existing reduced-motion/alarm-vibration controls. Messages shows the same numeric unread treatment as the launcher. Do not alter the external Phone / Map / HQ navigation.

**Mockup:** [`../phone_tab_mockup.png`](../phone_tab_mockup.png) is authoritative for dock shape, spacing, icon/label proportions, and Messages badge placement. [`../spec.md`](../spec.md) defines behavior and the separation from game navigation.

**Blocked by:** 03 — Four-column launcher, normalised icons, and count badges.

**Status:** ready-for-agent

**Relevant files:** `scenes/screens/phone.gd`; `scenes/components/app_tile.gd` (reuse visual/badge contract); new focused home-dock component if needed; `systems/phone_nav.gd`; `systems/messages.gd`; `scenes/phone_apps/phone_app_registry.gd`; `scenes/phone_apps/messages_app.gd`; `scenes/phone_apps/profile_app.gd`; new `scenes/phone_apps/dialer_app.gd`; new `scenes/phone_apps/settings_app.gd`; `scenes/components/contact_cards.gd`; `systems/preferences.gd`; `assets/icons/apps/dialer.png`; `assets/icons/apps/messages.png`; `assets/icons/apps/settings.png`; `tests/test_phone_app_registry.gd`; `tests/test_phone_home_grid.gd`; `tests/test_phone_messages.gd`; `tests/test_phone_profile.gd`; new `tests/test_phone_settings.gd`; new `tests/test_phone_dock.gd`; `CODEMAP.md`; `docs/CONTENT-GUIDE.md`

- [ ] Home dock is one translucent/dark rounded surface inside the simulated display, positioned near the bottom without colliding with frame curvature or the external nav bar.
- [ ] It contains exactly three equal-width, symmetric destinations in order: Phone, Messages, Settings. All use the same icon dimensions, rounding, label typography, and touch-target rules as the main launcher.
- [ ] Phone, Messages, and Settings runtime icons are square 128×128 alpha PNGs, visually coherent with the main icon set; Messages and Settings do not appear in `PhoneApps.apps()`.
- [ ] Dock is present only on the phone home view and disappears when any simulated app is open. The external Phone / Map / HQ nav remains mounted, unchanged, and independently interactive.
- [ ] Phone opens internal app id `dialer`: a simple Phone-OS content screen showing a recent-calls empty placeholder and Back; it adds no contacts/call history state, calling actions, permissions, timers, or telephony mechanics.
- [ ] Messages opens a master list of available conversations with contact name, latest-message preview where present, and unread count; selecting a row uses the existing `PhoneNav.select_conversation()`/thread view and marks it read as today.
- [ ] Back from a thread returns to the Messages conversation index; Back from the index returns home. Contact-card Messages buttons still open the same threads and remain functional.
- [ ] Messages dock badge is the total unread message count across contacts, updates from existing message state, hides at zero, and uses the shared numeric badge cap/overflow rule.
- [ ] Settings contains the existing reduced-motion and “Vibrate for alarms” controls with identical `Preferences` behavior/persistence. Those controls are removed from My File/Profile; Profile's stats, skills, and equipment remain unchanged.
- [ ] `dialer`, `messages`, and `settings` are registered `PhoneNav` apps; all navigation changes go through `PhoneNav`, and screens never mutate `GameState.state` directly.
- [ ] Any newly-authored empty-state/launcher copy is marked `PROSE-REVIEW:` and follows `docs/CONTENT-GUIDE.md`; supplied line `Same city. Different rules.` is not rewritten here.
- [ ] Tests cover exact dock membership/order, symmetry/equal sizing, home-only visibility, all three routes, unread count/update/clear behavior, conversation-index/thread back stack, moved preference controls, Profile regression, and proof the external nav still has exactly Phone/Map/HQ.
- [ ] `CODEMAP.md` records new component/app ownership and Messages' restored master-list responsibility.
- [ ] Every touched `.gd` passes the Godot 4.7 syntax runner immediately; full suite passes.
- [ ] Human QA: dock centring/translucency, three-way spacing, home-only visibility, icon/label consistency, Messages badge, Phone/Settings flows, keyboard-free scrolling, and zero visual confusion with the external game nav. Report exact on-device checks.

# 02 — Device shell, London wallpaper, and home widget

**What to build:** Put the Phone tab's existing home and app content inside a persistent dark, rounded simulated-device shell. On home, render the supplied `assets/phone/phone-wallpaper.jpg` as a clipped full-screen background behind a conventional status bar and the date/weather widget from the mockup; remove the old `Phone` heading. Opened apps stay inside the same shell on the existing dark content surface. The outer amber board and Phone / Map / HQ bar must remain visibly and behaviorally separate and unchanged.

**Mockup and wallpaper:** [`../phone_tab_mockup.png`](../phone_tab_mockup.png) is authoritative for frame silhouette, inset screen, status-bar hierarchy, widget placement, and wallpaper treatment. [`../../../assets/phone/phone-wallpaper.jpg`](../../../assets/phone/phone-wallpaper.jpg) is the approved runtime wallpaper. [`../spec.md`](../spec.md) locks the decorative values and fitting constraints.

**Blocked by:** 01 — Canonise the diegetic phone home.

**Status:** ready-for-agent

**Relevant files:** `scenes/screens/phone.gd`; new `scenes/components/phone_device_shell.gd` (or equivalently focused component); `scenes/components/ui.gd` (read first; safe areas/body layout); `scenes/components/top_bar.gd` and `scenes/components/nav_bar.gd` (read/regression only); `data/palette.json`; new `data/phone_home.json`; `autoload/GameData.gd`; `assets/phone/phone-wallpaper.jpg`; `.scratch/phone-tab-refresh/phone_tab_mockup.png`; `tests/test_phone_home_grid.gd`; new `tests/test_phone_device_shell.gd`; `CODEMAP.md`; `docs/ui-vision.md` §3/§10

- [ ] The simulated phone is a dark rounded frame entirely inside `UI.top_bar_clearance()` and above `NavBar.BAR_HEIGHT`; neither external component is reparented, recoloured, resized, or given phone-shell behavior.
- [ ] The inner display is clipped to the approved rounded silhouette so wallpaper/content cannot bleed over the bezel.
- [ ] Home uses the exact supplied `assets/phone/phone-wallpaper.jpg`; it is not regenerated, substituted, or baked together with the phone UI.
- [ ] Wallpaper uses an aspect-fill/cover treatment inside the clipped display: no stretching, exposed empty bands, or bleed over the bezel; responsive cropping preserves the Elizabeth Tower/Westminster composition and keeps icons legible.
- [ ] Home status bar shows `08:14`, cellular signal, Wi-Fi, a battery glyph, and `87%`, aligned like conventional contemporary phone chrome.
- [ ] Home widget shows `Tue, 14 May`, cloudy `12°C`, `London`, and exact flavour line `Same city. Different rules.` with the restrained hierarchy shown in the mockup.
- [ ] Fixed display values/copy and wallpaper reference live in `data/phone_home.json`, are loaded/validated once through `GameData`, never enter `GameState`, and trigger no host-clock/network access.
- [ ] The old home `Phone` heading is absent. Wallpaper/widget/status bar appear only on home; an opened existing app uses the current dark Phone-OS content background inside the same device frame.
- [ ] Existing app routing/back behavior still works inside the new content mount, including the Messages thread's custom full-height root.
- [ ] Layout survives the project's portrait viewport and safe-area offsets without clipping frame corners, widget text, or app content.
- [ ] Tests cover shell presence and bounds, fixed status/widget content, heading removal, home-vs-open-app surface switching, and unchanged external-bar ownership.
- [ ] `CODEMAP.md` records the new component/data/asset ownership.
- [ ] Every touched `.gd` passes the Godot 4.7 syntax runner immediately; full suite passes.
- [ ] Human QA: bezel proportions, rounded clipping, wallpaper legibility/restraint, status/widget alignment, dark app surface, and clear separation from both outer bars. Report exact on-device checks.

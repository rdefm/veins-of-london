# 03 — Four-column launcher, normalised icons, and count badges

**What to build:** Replace the current three-column loose launcher with the mockup's consistent four-column smartphone grid. Ship a coherent square icon set using the supplied `assets/phone/` artwork as source where available, preserve distinctive Reynard's/Harrow's branding, give mundane apps conventional contemporary treatment, and upgrade the badge from a boolean dot to a live numeric count. Keep Save/Load in the grid and preserve Debug's current debug-start-only app slot.

**Mockup:** [`../phone_tab_mockup.png`](../phone_tab_mockup.png) is authoritative for four-column geometry, icon/label proportions, badge placement, and the first eleven apps. [`../spec.md`](../spec.md) overrides it by adding Save/Load as slot 12 and conditional Debug after it.

**Blocked by:** 02 — Device shell, London wallpaper, and home widget.

**Status:** ready-for-agent

**Relevant files:** `systems/phone_apps.gd`; `systems/phone_nav.gd` (roster regression); `scenes/screens/phone.gd`; `scenes/components/app_tile.gd`; `scenes/phone_apps/phone_app_registry.gd` (regression); `assets/phone/`; `assets/icons/apps/`; `docs/adr/0003-app-icon-asset-contract.md`; `systems/raid_alarms.gd`; `systems/morning_accounts.gd`; `systems/messages.gd`; `systems/barometer.gd`; `systems/notify.gd`; `tests/test_app_tile.gd`; `tests/test_phone_apps.gd`; `tests/test_phone_home_grid.gd`; `tests/test_phone_saveload.gd`; `tests/test_phone_debug.gd`; `CODEMAP.md`; `docs/ui-vision.md` §10

- [ ] Normal-game grid is exactly 12 fixed slots in this order: `alarms`, `notes`, `bizbrief`, `ticker`, `factions`, `bank`, `property`, `profile`, `contacts`, `vfl`, `notifications`, `saveload`.
- [ ] Player-facing labels are exactly Alarms, Notes, BizBrief, The Ticker, Factions, Reynard's, Harrow's, My File, Contacts, TfL, Notifications, Save/Load; internal `profile`/`vfl` ids and TfL/VfL Map gate/routing remain unchanged.
- [ ] `debug` remains absent on a normal game and appends after Save/Load only when `flags.debugStartUsed` is true; its current tools/behavior remain unchanged.
- [ ] Grid has four equal columns and consistent row/column gaps. Every tile has the same icon box, rendered corner radius, centred single-label typography, touch target, and optical alignment without overlap or wallpaper-dependent legibility.
- [ ] Final main-grid assets are square 128×128 alpha PNGs at the ADR path. Supplied square source art is normalised rather than discarded; current wide/non-contract `bank`, `notes`, `property`, and `saveload` runtime images are replaced.
- [ ] Complete main-grid icon coverage includes Alarms, Notes, BizBrief, The Ticker, Factions, Reynard's, Harrow's, My File, Contacts, TfL, Notifications, Save/Load, and Debug. Missing art never silently falls back in the shipped refreshed launcher.
- [ ] Mundane apps read as contemporary system/productivity icons; fictional apps may brand more strongly. All still share coherent lighting/rendering, icon dimensions, rounding, labels, and badges.
- [ ] `AppTile` accepts a non-negative numeric badge count, hides it at zero, renders the number legibly in the locked `ui_action_red`, and uses one documented cap/overflow display for large values.
- [ ] Main-grid counts derive live without duplicate state: Alarms = pending alarm count; BizBrief = unresolved attention-item count; Ticker = count of sections with rumblings; Notifications = unseen-log count. Other main-grid badges are zero.
- [ ] Existing app opens/back paths remain intact, including Contacts' standalone screen, TfL's lock toast/direct Map route, Save/Load, and Debug.
- [ ] Tests pin exact roster/order/labels, normal/debug variants, four-column count, square icon availability/dimensions, numeric badge zero/nonzero/overflow rendering, each live badge source, tile non-overlap, and unchanged routing.
- [ ] `CODEMAP.md` is updated if badge-count ownership or asset responsibilities change.
- [ ] Every touched `.gd` passes the Godot 4.7 syntax runner immediately; full suite passes.
- [ ] Human QA: 4×3 normal grid fit, conditional Debug row, icon cohesion, label centring, badge legibility, branded-vs-mundane balance, wallpaper contrast, and touch targets. Report exact on-device checks.

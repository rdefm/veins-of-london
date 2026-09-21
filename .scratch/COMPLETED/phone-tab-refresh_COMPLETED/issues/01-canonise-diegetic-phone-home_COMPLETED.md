# 01 — Canonise the diegetic phone home

**What to build:** Reconcile the approved diegetic smartphone refresh with the project's canonical UI and roster documentation before code changes. Replace the superseded “full bleed/no bezel/no fake system chrome” direction with the approved framed device, decorative status bar, London wallpaper, home widget, four-column launcher, retained Save/Load/debug-start-only Debug apps, and Phone/Messages/Settings home dock. Lock the boundary that the amber top board and external Phone / Map / HQ navigation remain unchanged.

**Mockup:** [`../phone_tab_mockup.png`](../phone_tab_mockup.png) is the visual authority, subject to [`../spec.md`](../spec.md)'s written overrides—especially retained Save/Load and conditional Debug.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

**Relevant files:** `.scratch/phone-tab-refresh/spec.md`; `.scratch/phone-tab-refresh/phone_tab_mockup.png`; `docs/ui-vision.md` §3 and §10; `docs/REFERENCE.md` §2.2; `docs/adr/0003-app-icon-asset-contract.md` (read only; runtime path/128×128 contract remains); `docs/CONTENT-GUIDE.md` (read only)

- [x] `docs/ui-vision.md` explicitly supersedes its old no-bezel/no-fake-status/wallpaper-free home direction with this feature's device shell, decorative system chrome, wallpaper, widget, grid, badges, and dock.
- [x] `docs/REFERENCE.md` §2.2 records the launcher roster/order: Alarms, Notes, BizBrief, The Ticker, Factions, Reynard's, Harrow's, My File/Profile, Contacts, TfL/VfL, Notifications, Save/Load; Debug remains conditional on `debugStartUsed`.
- [x] Canon records that Messages and Settings live only in the simulated home dock and that the external Phone / Map / HQ navigation is a separate unchanged layer.
- [x] Canon records the approved dock behavior and ids: Phone (`dialer`) is a no-mechanics recent-calls placeholder; Messages is conversation index → existing thread; Settings (`settings`) owns reduced-motion/vibration.
- [x] Canon distinguishes fixed decorative mockup data from mechanics: no calendar/weather/connectivity/battery state, save fields, host-clock lookup, or network request.
- [x] Icon guidance preserves the existing runtime asset contract while allowing the larger `assets/phone/` files to serve as source artwork for normalisation.
- [x] Existing app mechanics and routing—including TfL/VfL's Map gate, Save/Load, and Debug—are explicitly unchanged.
- [x] No `.gd`, scene, gameplay data, or runtime behavior changes in this ticket.

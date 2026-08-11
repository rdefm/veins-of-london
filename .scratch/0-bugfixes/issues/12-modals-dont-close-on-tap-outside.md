# 12 — Modals and the Bag drawer don't close on tap-outside

**What to build:** Tapping outside a modal or the Bag drawer should close it, the same way `scenes/components/map_controls.gd`'s filter drawer already does (`_dim.gui_input.connect(...)` on its dim `ColorRect`, closing on tap) — but `scenes/components/modal_layer.gd` and `scenes/components/bag_drawer.gd` both set `_dim.mouse_filter = STOP` without ever connecting `gui_input` to close, so the tap is silently swallowed and the only way out is scrolling down to an explicit Close/Cancel button.

Where a modal's own Close/Cancel/Decline button has a side effect beyond just dismissing (e.g. `sell_menu`'s Cancel calls `Economy.clear_sell_state()`, `james_job_offer`'s Decline calls `Jobs.decline_job()`), tapping outside must run that same side effect — not just a bare dismiss that leaves state half-applied. Most modals only have "Got it"/"Close" with no side effect, so this only changes behaviour for `sell_menu` and `james_job_offer` specifically; audit `modal_layer.gd`'s full modal-type roster for any others in the same shape.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] Tapping outside any open modal (`ModalLayer`) closes it, running the same effect as that modal's own Close/Cancel/Decline button.
- [ ] Tapping outside the open Bag drawer (`BagDrawer`) closes it.
- [ ] Tapping inside a modal or the Bag drawer does not close it.
- [ ] `sell_menu`'s sell-state selections are cleared on outside-tap, same as tapping Cancel.
- [ ] `james_job_offer`'s outside-tap runs `Jobs.decline_job()`, same as tapping Decline.
- [ ] Existing explicit Close/Cancel/Decline buttons still work unchanged.

# 09 — Dial loadout view

**What to build:** The bag-and-umbrella zone opens the Dial view, drawn as
the device: the haft on one side, the seated Movement, and Complication
sockets as visible slots. Crafted Complications sit in a tray beside it and
move into and out of sockets by tap (drag as flourish, per the same
always-tap-works rule as the bench). Charge and capacity read off the
device itself rather than a progress bar. This becomes the sole entry point
to loadout adjustment — the bag drawer's management mode is removed.
Seeding an unseeded Dial and crafting components keep current behaviour,
reached from this view.

**Blocked by:** 02

**Status:** ready-for-agent

- [ ] Dial zone opens the diegetic loadout sub-view, full-bleed
- [ ] Movement and Complication sockets are drawn as slots; tray holds unslotted crafted Complications
- [ ] Tap moves Complications into/out of sockets; charge/capacity read off the device art, not a bar
- [ ] Seeding an unseeded Dial and crafting components work unchanged, reached from this view
- [ ] `bag_drawer.gd`'s `_build_dial_management()` and loadout adjustment path are removed

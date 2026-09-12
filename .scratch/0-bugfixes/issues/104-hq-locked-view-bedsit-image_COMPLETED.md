# 104 — HQ locked state shows the bedsit image, not the old card menu

**What to build:** Before HQ unlocks, the screen currently shows a generic card-stack menu (a "Locked" heading, an Actions card with Rest/Defend, a Back button) with no visual connection to the room itself. Replace that plain-card layout with the bedsit room background image as the base, with the same button set as today (Rest, Defend, Back) overlaid on top of it. This is scoped to swapping the background/presentation only — do not build out per-hotspot lock states or the full diorama interaction model; that stays for later, once more of HQ unlocks.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] A new game's HQ screen, before unlock, shows the bedsit room image as its background.
- [ ] The same Rest/Defend/Back buttons from today's locked view are overlaid on the image and work identically to before.
- [ ] No per-hotspot unlock states or new interactions are introduced — this ticket only changes the visual presentation of the existing locked-state buttons.
- [ ] `godot --headless -s scripts/check_runner.gd -- path/to/file.gd` clean on every touched file.
- [ ] Manual check noted for the human: start a new game, confirm HQ shows the bedsit image (not the old plain menu) with working Rest/Defend/Back buttons, before anything unlocks.

# 07 — New Dial menu: overview, zoom, Lens section

**What to build:** Replace HQ Dial's seeded view with the new Dial menu. It runs on placeholder art until 09: rough shapes per device layer, laid out on the spec's 72 × 352 vertical canvas. The old device art isn't sliced, because its parts are in the wrong order. The menu opens on an **overview**: the whole umbrella, with three tappable section bands, handle to tip: **Movement, Lenses, Complications**. The face/studs and Wind are not sections (Wind lives in the Movement section, 08). Tapping a section zooms and pans onto it at the spec's zoom rect and integer scale. The other parts move to the spec's exploded offsets and dim (Jedi: Survivor lightsaber-bench feel). Then the section's open beat plays. This ticket implements the **Lens** section fully; Movement and Complications may be stubs until 08.

Lens section: as the zoom lands, each unlocked port's shutter opens (placeholder iris beat). Ports above `lens_slots(level)` stay plugged. Loaded Lenses sit seated in their ports. Held Lenses are in a scrollable right-hand side list. Tapping a list item animates in a small info tag with the Lens's effects (same text as today's Lens Details). A Lens loads **immediately** when dragged onto a specific port, or via a Fit button in its tag (first empty port). Dropping on a filled port swaps. Dragging a seated Lens off the device unloads it. Tapping a seated Lens shows its tag. All changes go through the existing Dial system calls; the screen never mutates state. Back closes the shutters, zooms out, and the Dial reassembles. Unseeded Dials still show the seed screen (11 may change it independently).

Layout, offsets, zoom rects and beat order come from the 06 art spec. Timings can be code constants here; 09 moves them to data.

**Blocked by:** 06 — Dial menu art brainstorm (spec sign-off)

**Relevant files:**
- `.scratch/ui-previews-dial/dial-art-spec.md` (§1 canvas, §2.1 anchors, §3 layouts/offsets, §4 beats)
- `scenes/screens/hq_dial.gd` (unseeded + seeded screens; the seeded one is replaced)
- `scenes/components/dial_loadout_menu.gd` (current shared card; match its behaviour)
- `scenes/modals/dial_socket_modal.gd` (pick/swap/remove + Lens details; match its behaviour)
- `systems/dial.gd` (`dial_of`, `lens_slots`, Lens load/swap/unload), `systems/lenses.gd` (`one_line`, `effect_rows`)
- `docs/ui-vision.md`
- REFERENCE §1.4 (Loadout menu, Lenses), §3.5
- tests: `tests/test_hq_dial.gd`, `tests/test_dial.gd`

**Status:** ready-for-agent

- [ ] Overview shows the placeholder umbrella in spec layer order, with 3 tappable bands (Movement, Lenses, Complications)
- [ ] Section tap: integer-scale zoom/pan to the spec rect, other parts move to exploded offsets and dim; Back reverses and reassembles
- [ ] Lens section: shutter-open beat on unlocked ports, locked ports plugged, close on Back
- [ ] Lens side list scrolls; tap shows the animated info tag with Lens effects
- [ ] Drag onto a port or Fit loads immediately (via the Dial system); dropping on a filled port swaps; drag off unloads
- [ ] Tests cover load/swap/unload through the new view's handlers
- [ ] CODEMAP updated

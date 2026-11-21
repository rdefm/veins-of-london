# 07 — New Dial menu: overview, zoom, Lens section

**What to build:** Replace HQ Dial's seeded view with the new Dial menu, on placeholder art (slices/tweens of the existing device art until 09). It opens on an **overview**: the whole Dial with its three sections (Movement, Lenses, Complications) tappable, plus Wind. Tapping a section zooms/pans onto it while the other parts separate and float aside (Jedi: Survivor lightsaber-bench feel — see 06). This ticket implements the **Lens** section fully; the other two may be stubs until 08.

Lens section: loaded Lenses sit seated in their sockets (all Lens sockets visible); held Lenses are in a scrollable side list. Tapping a list item animates in a small info bubble with the Lens's effects (same text as today's Lens Details). A Lens loads **immediately** when dragged onto a specific socket, or via a Fit button in its bubble (first empty socket). Dropping on a filled socket swaps; dragging a seated Lens off the dial unloads it; tapping a seated Lens shows its bubble. All changes go through the existing Dial system calls — the screen never mutates state. Back zooms out and the Dial reassembles. Unseeded Dials still show the existing seed screen, unchanged.

**Blocked by:** None — can start immediately.

**Relevant files:**
- `scenes/screens/hq_dial.gd` (unseeded + seeded screens; seeded one is replaced)
- `scenes/components/dial_loadout_menu.gd` (current shared card — behaviour parity)
- `scenes/modals/dial_socket_modal.gd` (pick/swap/remove + Lens details — parity)
- `systems/dial.gd` (`dial_of`, Lens load/unload), `systems/lenses.gd` (`one_line`, `effect_rows`)
- `scenes/modals/dial_wind_modal.gd`
- `assets/hq/dial/`, `docs/ui-vision.md`
- REFERENCE §1.4 (Loadout menu, Lenses), §3.5
- tests: `tests/test_hq_dial.gd`, `tests/test_dial.gd`

**Status:** ready-for-agent

- [ ] Overview shows the Dial with 3 tappable sections + Wind
- [ ] Section tap: zoom/pan + other parts float aside; Back reverses and reassembles
- [ ] Lens side list scrolls; tap shows animated info bubble with Lens effects
- [ ] Drag onto socket or Fit loads immediately (via Dial system); swap on filled socket; drag off unloads
- [ ] Multiple Lens sockets visible; drop targets a specific socket
- [ ] Unseeded seed screen unchanged
- [ ] Tests cover load/swap/unload through the new view's handlers
- [ ] CODEMAP updated

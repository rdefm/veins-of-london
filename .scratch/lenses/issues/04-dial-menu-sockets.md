# 04 — Dial menu: three socket rows, one interaction model

**What to build:** Spec `.scratch/lenses/spec.md` "Dial menu". Rebuild `DialLoadoutMenu` as three labelled rows (MOVEMENT: powers it; LENSES: what you see; COMPLICATIONS: what you cast) plus a Craft component footer.

- Every socket: empty `+` opens one shared socket picker modal (held components of that kind, one-line effect each); filled opens Details / Swap / Remove. Replaces the Unseat/Swap/Unload buttons; fold `movement_swap` and `dial_load_complication` into the picker.
- Wind opens an ore choice only when more than one lens is loaded.
- Lens Details: effects grouped by Sense gate, locked ones greyed with the level needed (read from `Lenses`, never computed in the screen).
- Craft component opens the existing craft modal with Movement | Lens.
- HQ Dial: lens sockets as eyepieces on the crown; Complications stay flanking. Profile, HQ and combat-prep Change loadout share the menu. Contact Dial cards get lens rows too.
- New strings PROSE-REVIEW.

**Blocked by:** 01, 02, 03

**Status:** ready-for-agent

**Relevant files:**
- `scenes/components/dial_loadout_menu.gd`
- `scenes/screens/hq_dial.gd`
- `scenes/modals/movement_swap_modal.gd`
- `scenes/modals/dial_load_complication_modal.gd`
- `scenes/modals/modal_registry.gd`
- `scenes/screens/profile_app.gd`
- `tests/test_hq_dial.gd`
- `docs/ui-vision.md`
- `CODEMAP.md`

**Acceptance:**
- [ ] All three rows render for player and James; empty/filled socket taps open picker/details.
- [ ] Load/swap/remove go through system calls only (no state mutation in screens).
- [ ] Wind ore choice appears only with 2+ lenses.
- [ ] Lens Details shows locked/unlocked gates correctly for current Sense.
- [ ] Human QA block in report: phone-width layout, HQ eyepieces, Profile + prep.
- [ ] Syntax check clean, tests pass; REFERENCE/CODEMAP updated for this ticket's part.

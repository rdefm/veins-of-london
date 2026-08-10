# 09 — Bench notes screen

**What to build:** The one opt-in, full-detail view of the player's Lab history — listing only pairings they've actually touched, with numeric census counts and a capped history per pairing — so players who want to plan precisely have somewhere to look, without the game ever surfacing a checklist of untouched pairings anywhere else.

**Blocked by:** 08 — Confirm/result screens + animation.

**Status:** ready-for-agent

- [ ] Bench notes screen (`ScrollContainer` of `UI.card()` rows), reached from the Lab home screen's "Bench notes" entry point (wired for real now, replacing ticket 06's stub): lists only pairings present in `state.player.bench.notes`/`cells` — pairings never touched do not appear.
- [ ] Each listed pairing shows its exact numeric census count (found/total, per ticket 04's reveal data) and a short history list built from stored outcome enums, rendered to prose at render time (not stored as prose).
- [ ] History list per pairing respects the ~20-entry cap already enforced in state (ticket 04) — oldest entries dropped, this screen just renders what's there.
- [ ] The 15 type-pairings are still never enumerated as a matrix/list/tracker here — only touched pairings appear, and never a marker for pairings not yet touched.
- [ ] Screen test: bench notes only lists touched pairings; respects the ~20-entry cap; renders correct prose from stored enums.
- [ ] Syntax check clean on all touched `.gd` files.

**PROSE-REVIEW:** the per-outcome history-line templates are new prose against `docs/CONTENT-GUIDE.md`.

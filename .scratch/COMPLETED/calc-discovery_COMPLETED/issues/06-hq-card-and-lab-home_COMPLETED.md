# 06 — state.benchNav wiring + HQ Lab card + Lab home screen

**What to build:** The player's first visible entry into the Lab: a third HQ card alongside the workbench and gym, leading to a Lab home screen that shows what's been found and what approaches are known — never a checklist of what's missing. Deeper navigation (picker, pairing panel) can stub/no-op past this ticket's scope; the point here is the home screen reads correctly and `benchNav` actually drives screen state.

**Blocked by:** 05 — Refinement: tiers, cost/odds curves, refineStep.

**Status:** ready-for-agent

- [ ] `scenes/screens/hq.gd`: third card added for the Lab, in-fiction-named "The Lab", alongside workbench and gym.
- [ ] New Lab home screen (`ScrollContainer` of `UI.card()` rows, no new custom widgets): found-effects list (each row tappable — wiring to the pairing panel lands in ticket 07, a stub target is acceptable here), known-approaches sentence, entry points for "Run an experiment" and "Bench notes" (targets can stub/no-op until tickets 07/09 land).
- [ ] `state.benchNav` actually drives which bench screen is shown; navigating to/from the Lab home screen updates it correctly.
- [ ] Screen test (mirrors `tests/test_map_screen.gd`'s headless-scene pattern): Lab home card renders the found list and known-approaches sentence correctly from `state.player.bench`.
- [ ] Syntax check clean on all touched `.gd` files.

**PROSE-REVIEW:** the known-approaches sentence and any new HQ card copy are new prose against `docs/CONTENT-GUIDE.md`.

# 08 — Confirm/result screens + animation

**What to build:** The moment of actually running an experiment — cost, block cost, and pity-inclusive odds shown before confirming; an outcome-agnostic, skippable animation while it resolves; and a plain-language result (inert/hot/found) immediately after. This completes the core probing loop end-to-end (spec user stories 1–14) — a player can now go from HQ to a discovered effect entirely through the Lab.

**Blocked by:** 07 — Type picker + pairing panel.

**Status:** ready-for-agent

- [ ] Confirm screen, reached by tapping an approach row in the pairing panel: shows ore cost and time-block cost via `UI.format_cost_label`/`UI.format_block_cost_label`, and success odds already inclusive of accumulated pity. Confirming spends ore and a time block regardless of eventual outcome.
- [ ] One outcome-agnostic animation plays while the experiment resolves — its visuals give no early tell of the result — and is skippable, so repeat experimenting doesn't force the player to sit through it every time.
- [ ] Result screen/card: one line of outcome prose per vision-doc §8.4's register, branching on `inert` (told plainly, permanent), `hot` (told plainly something's there, pity now applied), or `found` (effect's name, symbol, and what it does, shown immediately as a real discovery payoff).
- [ ] A Lab session interrupted by app close/reopen mid-flow resumes correctly — no double ore charge, no lost cell/note state.
- [ ] Screen test extended: confirm screen displays pity-inclusive odds correctly; result screen renders the correct prose branch per outcome.
- [ ] `tests/test_bench.gd` or equivalent: resume-after-interrupt does not double-charge ore or duplicate a note entry.
- [ ] Syntax check clean on all touched `.gd` files.

**PROSE-REVIEW:** all three result-outcome lines are new prose against `docs/CONTENT-GUIDE.md`.

# 08 — Storyboard Prose pack mode: viewer + sandbox

**What to build:** the storyboard tool gets a **Prose pack** board kind, listing the prose packs from the repo folder it already opens. For a pack: slot tabs, and a variant list showing each prose card's condition, weight and first line. The **meeting sandbox** lets the writer pick 1-3 templates, edit meeting facts, reroll the seed and play the assembled meeting in the phone frame. A panel shows which prose card filled each slot and why (condition, weight, fallback), and any unfilled `{token}` is flagged. Read-only in this ticket.

Parity: a Godot headless export script writes golden eligibility results (fixture facts → eligible prose card ids per slot) to a fixture file; the JS tests check the tool's condition evaluation and eligibility against it. The JS side doesn't need to match the game's seeded pick.

**Blocked by:** 05 — Meeting facts…, 06 — Mini-scene replies…

**Relevant files:**
- `tools/storyboard.html` — board kinds (`kind: "proposal"`), phone preview, `useRoot`/`showDirectoryPicker`
- `tools/test_storyboard.js`
- New Godot export script under `scripts/`, golden fixture under `tests/fixtures/` (or similar)
- `data/board_prose/*`, `systems/board_meetings.gd` (facts, selection) — read
- `CODEMAP.md` (storyboard row)
- Spec: `.scratch/board-prose-cards/spec.md` → "Storyboard tool", "Sandbox parity"

**Status:** ready-for-agent

- [ ] Packs list and open; variants grouped by slot with condition and weight
- [ ] Sandbox assembles and plays a meeting; reroll changes the variants; why-it-fired panel correct
- [ ] Unfilled tokens flagged
- [ ] JS eligibility matches the Godot golden file; existing storyboard tests pass
- [ ] On-device check list for the human in the report

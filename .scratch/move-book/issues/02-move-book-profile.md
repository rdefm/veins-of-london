# 02 — Move Book in the Profile app

**Visual spec:** `.scratch/move-book/move-book.html` (live copy: https://claude.ai/artifact/FPL7F27VL6oHT5DTsSYgFR). Open it in a browser and match the top phone mock ("Profile · Moves") — layout, states, shapes and copy. If this ticket and the mock disagree, stop and ask.

**What to build:** The Profile app's move lines become the Move Book.
- **Owner tabs:** You, plus each recruited contact (same per-owner move levels).
- **Collapsed row per move:** name, level badge (`MAX` at Lv5), a five-stop mini track (Lv3 and Lv5 drawn as diamonds, others circles; reached stops filled; next stop outlined in the action red), and one line: "Next unlock, Lv{n}: {unlock} · {XP} XP" (or "All unlocks earned.").
- **Tap to expand** (one open at a time):
  - Level track: five stops on a rail; the rail fills to the current level then part-fills the next gap by XP progress. Under each stop, that level's absolute value of the move's per-level stat (Strike damage bonus, Guard chip taken, Feint extra damage, Stun Guard-through chance, Leg it escape chance); the current one is boxed.
  - Feint only: a second row, "Auto-guard after a Feint": — / — / Chance / Greater / Highest. No percentages shown.
  - Two unlock cards, Lv3 and Lv5: plain effect line, then the rule in smaller text. States: earned (solid), next (dashed action red, "XP to go"), locked (faded).
  - XP line: "{xp} / {next} XP to Lv{n} · +10 per use, +4 if it fizzles" (from data), or "max level".
- A recruit's contact page shows the same rows instead of its "Strike Lv1 · Guard Lv2 · …" line; tapping opens the same detail.
- Every number comes from `moveLevelEffects` / move XP data. All player-facing strings (stat labels, unlock lines, rule lines, Feint word row) live in data next to the numbers — draft from the mock's "What every card says" table.
- Colour rules: action red only for "next"; never `calc_gold` (ui-vision §6). Shape, not colour alone, marks milestones. Follows the dark toggle.

**Blocked by:** 01 — Stun rework (Stun's track and card copy depend on it).

**Relevant files:**
- `systems/move_levels.gd` (`summary`, `levels_of`, `xp_levels` — extend to return track values, unlock states and XP-to-go per owner)
- `data/combat_rounds.json` (`moveLevelEffects`, move XP; new display strings)
- `autoload/GameData.gd` (validation of the new strings)
- `scenes/phone_apps/profile_app.gd` (`_build_skills_card`, `_add_skill_row`, `move_levels_text`, contact view)
- `scenes/components/map_card_style.gd`, `scenes/components/contact_cards.gd`
- `tests/test_move_levels*.gd` (or the existing move-level tests in `tests/test_combat_rounds.gd`)
- `CODEMAP.md`; REFERENCE §3.7b Move levels
- `docs/ui-vision.md` §6–7, `docs/CONTENT-GUIDE.md`, `docs/writing-guide.md`

**Status:** ready-for-agent

- [ ] System helper returns, per owner and move: level, XP, XP to next, five stat values, Feint word row, Lv3/Lv5 unlock states (tested at Lv1, Lv3, Lv5)
- [ ] Profile shows collapsed rows + expandable detail as in the mock, for You and each recruit
- [ ] Contact page uses the same rows
- [ ] No number or display string hard-coded in the screen
- [ ] PROSE-REVIEW: all new strings flagged in the report, drafted against `docs/writing-guide.md`
- [ ] Human check: compare on-device against the mock (track legibility at phone width, diamond vs circle, three unlock-card states, dark mode)

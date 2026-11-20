# 01 — Be A Lady: % score multiplier

**What to build:** Be A Lady boosts a finished Lab run's score by a percentage based on its item level (5% per level, i.e. score × (1 + 0.05 × level), capped at 100), replacing the flat per-level points bonus. It must never let a low-level item shortcut straight to a high-tier result.

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/lab.gd` (`lady_score_bonus` ~L881, score assembly ~L708), `data/constants.json` (`ladyScorePerLevel`), `docs/REFERENCE.md` §3.5 (Scoring ~L792), Lab tests under `tests/`.

**Status:** ready-for-agent

- [ ] Score = clamp(raw × (1 + 0.05 × Lady level), 0, 100); flat `ladyScorePerLevel` removed from data/code/REFERENCE
- [ ] Per-level % lives in data, not code
- [ ] Result/ladyBonus readout in Lab UI still shows the boost sensibly
- [ ] Tests cover levels 1–5, cap at 100, inactive = no change
- [ ] REFERENCE.md updated; CODEMAP if responsibilities change

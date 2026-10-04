# 07 — Factions poach your staff

**What to build:** Factions try to lure the player's hires. Each week, each hire has a 0.1 chance of an offer from a faction weighted toward Hostile / Business-rival stance, at most 3 attempts per hire ever. The offer (+20%) appears as a BizBrief alert: "Match (£X/wk)" raises their `wageMult` permanently (never above +25%), "Let them go" lets them go. The player has the whole next day to answer; if a full day passes without an answer, it resolves as a refusal. On a refusal the hire leaves (as in ticket 05's let go) and becomes "Employed at {faction}".

**Blocked by:** 05 — Wage scales with level; let go; 06 — Market flips + poaching employed candidates.

**Relevant files:** `systems/hiring.gd`, `data/hiring.json` `market`, `systems/faction_ai.gd` (`player_stance` ~L75), `systems/time_system.gd`, `scenes/phone_apps/bizbrief_app.gd` (Brief prompts ~L116), `systems/morning_accounts.gd` (attention items), spec §1 C7, §4.3, §9 `poach`, §10 R7, REFERENCE.md §2 + §3.10.

**Status:** ready-for-agent

- [ ] Weekly roll, stance weighting and the attempt cap tested
- [ ] Match updates the wage; the offer never exceeds the cap
- [ ] Unanswered alert resolves at the rollover after a full day (`expiresDay = offerDay + 2`)
- [ ] Departed hire's status = employed at the poaching faction
- [ ] PROSE-REVIEW: alert text
- [ ] REFERENCE + CODEMAP updated
- [ ] Human check: BizBrief shows the poach alert with both buttons; it is still there the next day

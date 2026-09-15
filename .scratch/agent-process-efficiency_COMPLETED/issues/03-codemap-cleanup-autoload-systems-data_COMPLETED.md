# 03 — Rewrite CODEMAP.md: autoload / systems / data tables to current-state-only

**What to build:** Apply the rule from ticket 01 to three of CODEMAP.md's tables: `## autoload/*.gd`, `## systems/*.gd`, and `## data/*.json`. Every entry becomes a current-state description only — what the file/table does now, ~1-2 sentences, no ticket-number narration. The worst offenders in these three tables are `systems/combat_prototype.gd` and `data/hq_visuals.json`/`data/combat_visuals.json`/`data/combat_prototype.json` (each several sentences of accumulated ticket history).

Preserve any information that is genuinely load-bearing for understanding current behavior (e.g. "prototype-only, not cross-referenced by REFERENCE.md", "no `default` fallback for X") — only strip the *sequential ticket narration* ("ticket 14 did X, ticket 15 added Y"), not facts about how the system currently works.

**Relevant files:**
- `CODEMAP.md` lines 5-15 (`## autoload/*.gd`)
- `CODEMAP.md` lines 16-79 (`## systems/*.gd`) — `combat_prototype.gd` (line ~30) is the largest rewrite
- `CODEMAP.md` lines 129-158 (`## data/*.json`) — `hq_visuals.json`, `combat_visuals.json`, `combat_prototype.json` are the largest rewrites
- Line numbers are approximate as of this ticket's filing — re-`grep -n "^## "` CODEMAP.md to confirm current section boundaries before editing, since ticket 01 may have already shifted lines slightly

**Blocked by:** 01

**Status:** ready-for-agent

- [ ] Every entry in the autoload, systems, and data tables is current-state prose only — no "ticket N" sequential narration remains
- [ ] No factual information about current behavior is lost in the rewrite (spot-check a few entries against git blame / the actual .gd or .json file if unsure)
- [ ] Table structure (`| File | ... |` columns) is unchanged — this is a content edit, not a format change
- [ ] `scenes/screens/*.gd` and `scenes/components/*.gd` tables are untouched in this ticket (that's 04)

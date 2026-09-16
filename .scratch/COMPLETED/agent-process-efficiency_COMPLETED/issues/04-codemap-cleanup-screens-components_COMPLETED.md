# 04 — Rewrite CODEMAP.md: scenes/screens / scenes/components tables to current-state-only

**What to build:** Apply the rule from ticket 01 to CODEMAP.md's two most heavily-narrated tables: `## scenes/screens/*.gd` and `## scenes/components/*.gd`. These carry the worst offenders in the whole file — `combat.gd`, `hq.gd`, `hq_lab_bench.gd`, `hq_dial.gd`, `dial_widget.gd`, `modal_layer.gd` each currently run to several hundred words of accumulated per-ticket history. Rewrite every entry to current-state description only, ~1-3 sentences (a couple of these screens are genuinely complex enough to warrant slightly more than the 1-2 sentence norm — use judgement, but the target is an order of magnitude shorter than today, not a light trim).

Preserve genuinely load-bearing current-state facts (e.g. "ART-REVIEW: hit-region consts not yet confirmed on-device", "no default fallback for `tell`/`selfPatch`") — strip the sequential ticket narration only.

**Relevant files:**
- `CODEMAP.md` lines 80-100 (`## scenes/screens/*.gd`) — `combat.gd`, `hq.gd`, `hq_lab_bench.gd`, `hq_dial.gd` are the largest rewrites
- `CODEMAP.md` lines 101-128 (`## scenes/components/*.gd`) — `dial_widget.gd`, `modal_layer.gd`, `hq_diorama.gd` are the largest rewrites
- Line numbers are approximate as of this ticket's filing (ticket 01/03 may shift them slightly) — re-`grep -n "^## "` CODEMAP.md to confirm current section boundaries before editing

**Blocked by:** 01

**Status:** ready-for-agent

- [ ] Every entry in the scenes/screens and scenes/components tables is current-state prose only — no "ticket N" sequential narration remains
- [ ] No factual information about current behavior (ART-REVIEW flags, fallback rules, sizing/anchoring rationale that's still true today) is lost in the rewrite
- [ ] Table structure is unchanged — content edit only
- [ ] `autoload/*.gd`, `systems/*.gd`, `data/*.json` tables are untouched in this ticket (that's 03)

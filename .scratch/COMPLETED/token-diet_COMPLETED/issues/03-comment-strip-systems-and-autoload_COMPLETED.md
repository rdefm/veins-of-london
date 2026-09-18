# 03 — Comment strip: systems/ + autoload/

**What to build:** Every system and autoload file reads as a description of current behaviour. Ticket-history narration is deleted; where a comment carried a real rationale (a balance reason, a spec constraint, a non-obvious invariant) it is rewritten in one or two lines citing the spec § instead of the ticket. Long file headers collapse to a few lines saying what the file owns. Code is untouched — comment lines only — so the change is verifiable by "tests still pass, diff contains only comment lines". All these files leave the lint allowlist.

**Blocked by:** 01 — Comment + CODEMAP policy with lint.

**Relevant files:** all `systems/*.gd` and `autoload/*.gd`. Heaviest first: `systems/combat.gd`, `systems/raiding.gd`, `autoload/GameData.gd`, `autoload/GameState.gd`, `systems/factions.gd`, `systems/dial.gd`, `systems/combat_prototype.gd`, `systems/events.gd`, `systems/economy.gd`, `systems/cultivating.gd`, `systems/sites.gd`, `autoload/SaveManager.gd`, `systems/map_events.gd`, `systems/bench.gd`. Rationale that must survive lives in `docs/REFERENCE.md` — when a comment cites a number, confirm the § and cite that.

**Status:** ready-for-agent

- [ ] Diff touches only comment lines (and blank lines left by removed blocks) in systems/ and autoload/.
- [ ] Combined comment-line count across systems/ + autoload/ at most half of today's (5,806).
- [ ] Every comment that explained a *why* still explains it, in ≤2 lines, citing a doc § not a ticket.
- [ ] systems/ and autoload/ entries removed from the lint allowlist; syntax check and full test suite green.

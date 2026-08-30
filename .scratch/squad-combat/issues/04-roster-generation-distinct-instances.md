# 04 — Roster generation: distinct instances + variance

**What to build:** Convert mob-count content generation from "one stat block scaled by count" to N distinct enemy instances, so a "3× Mugger" fight is three separately-tracked muggers with slightly different HP/attack, not one blob wearing a plural name.

`Combat.generate_mugger()`'s `count` roll (1–3, unchanged range) now spawns `count` distinct entries, each independently rolled off the single existing "mugger" archetype's base stats — no new mugger archetypes are introduced. `Combat.generate_raid_enemy()`'s `guard_count` (also capped at 3, the squad max) spawns `guard_count` distinct entries; each slot independently rolls which existing guard template (`GameData.ENEMY_RAID_GUARDS`) to use — mixed-archetype squads become possible (e.g. one Scrapper alongside one Vein Guard) — unless the caller has forced a specific `template_key`, in which case every slot uses that one template.

Every spawned entry (mugger or guard) gets independent stat variance: hp/attackMin/attackMax each rolled at a small percentage above/below its archetype's base values (`Combat.ENEMY_INSTANCE_VARIANCE`, a placeholder percentage per `REFERENCE.md` §3.7a, not a balance-final number), rounded via the existing `GameState.round_epsilon()` — so two entries sharing the same archetype are not stat-for-stat identical. Each spawned entry also gets its authored `speed` (from ticket 02's per-template data) applied, with no variance on `speed` itself (only hp/attack roll).

**This is an explicit difficulty increase** over today's blob-scaling (three full-strength enemies vs. one enemy scaled to roughly three times the stats) and must not be treated as balance-neutral or silently shipped into a live encounter without its own playtest/balance pass.

**Blocked by:** 02 (needs the per-template `speed` field it authors)

**Status:** ready-for-agent

- [ ] `generate_mugger()` returns `count` (1–3) distinct entries in `combat.enemies`, each independently rolled off the mugger archetype's base stats with independent hp/attackMin/attackMax variance
- [ ] `generate_raid_enemy()` returns `guard_count` (capped at 3) distinct entries; when no `template_key` is forced, each slot independently rolls a template from `GameData.ENEMY_RAID_GUARDS` (mixed-archetype squads possible); when `template_key` is forced, every slot uses that template
- [ ] Every spawned entry's hp/attackMin/attackMax falls within its archetype's variance band (`ENEMY_INSTANCE_VARIANCE`), rounded via `GameState.round_epsilon()`; no two same-archetype entries in a roster are guaranteed identical
- [ ] Each spawned entry carries its template's authored `speed` value unchanged (no variance applied to speed)
- [ ] New tests assert shape invariants using the existing seeded-RNG test helper pattern (correct entry count, each entry's stats within its archetype's variance band, mixed-template raids are possible when not forced) — not pinned exact rolled values
- [ ] The ticket's own PR/commit description calls out the difficulty increase explicitly, per this spec's flag, so it isn't silently absorbed into a live encounter

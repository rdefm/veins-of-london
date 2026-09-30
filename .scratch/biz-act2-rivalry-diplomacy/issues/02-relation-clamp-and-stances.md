# 02 — Relation clamp + stances

**What to build:** Relation is limited to −100..+100 everywhere. The player's relation with each faction, and every faction pair, has a stored **stance**: Partner, Neutral, Business rival or Hostile. Stance follows the relation bands with hysteresis, so relation must stay in a new band for N days before the stance flips. Business rival applies only where the two sides overlap: a shared primary/secondary ore, or crafting the same items. For the player, overlap means holding at least 5% ore or crafting share in one of the faction's ores or items. London starts with the canonical stances, and the Collective's player stance follows its questline. Each faction keeps a bounded activity log. A stance change involving the player sends a key-member message and adds an activity-log entry. The Factions app shows stance and the log.

**Blocked by:** 01 — Key-member contacts.

**Relevant files:** `systems/factions.gd` (`adjust_player_relation`, `adjust_relation`, `get_relation`), new `systems/faction_ai.gd`, `data/factions.json` / `data/constants.json` (bands, hysteresis, starting stances), `systems/shares.gd` (overlap), `systems/collective.gd` (questline state), `systems/time_system.gd` (daily stance update), `SaveManager`, `scenes/phone_apps/factions_app.gd`, `tests/test_factions.gd`, `tests/test_phone_factions.gd`, `tests/test_savemanager.gd`, `CONTEXT.md` (stance, key member), `CODEMAP.md`. Spec: `.scratch/biz-act2-rivalry-diplomacy/spec.md` §Stances stories 1–8, §Stance model, §State. REFERENCE.md §1.8, §3.1, §6.

**Status:** ready-for-agent

- [ ] Both relation adjusters clamp to −100..+100. Existing values out of range are clamped when an old save loads.
- [ ] The stance matrix (faction pairs are symmetric, plus player→faction) and pending-flip counters are stored in state and backfilled on old saves.
- [ ] Starting stances come from data: Collective–Firm Hostile, Guild–Conclave and Network–Conclave Business rival, Collective–Guild Partner, the rest Neutral. Starting pair relations sit inside their band.
- [ ] Band placeholders (Partner ≥ +50, Hostile ≤ −40) and hysteresis (3 days) live in JSON. A test shows relation moved into a new band flips the stance only after the hysteresis days.
- [ ] Business rival vs Neutral follows the overlap rule, including the player's 5% share threshold.
- [ ] A player stance change sends a message from the faction's key member and adds an activity-log entry. Faction-pair changes are logged. The log is bounded.
- [ ] The Factions app shows each faction's stance and activity log (read-only).
- [ ] REFERENCE, CONTEXT.md and CODEMAP updated. `PROSE-REVIEW:` covers the stance-change lines.

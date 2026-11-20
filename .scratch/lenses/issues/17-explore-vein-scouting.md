# 17 — Explore: per-vein scouting and a higher vein-security intel level

**What to build:** Nothing yet. This is a design ticket. Work through the open questions below with the human until both sides agree on the design, then write the implementation tickets (vertical slices, with blocking edges) under `.scratch/lenses/issues/` and mark this ticket complete.

The idea: the raid site sheet's vein info (Alarms, Ward, Guards rows) unlocks only at a much higher faction intel level. Separately, the player can **scout a specific vein** to learn that one vein's guards, alarms and ward.

**Blocked by:** None. Can start immediately. (Builds on 10, which is completed.)

**Relevant files:**
- `systems/intel.gd`: `knows`/`level`, `physics_read`, `vein_security_read`, `vein_security_counts`
- `scenes/screens/map.gd`: `_build_faction_vein_content` (raid site sheet rows, Raid button and block-cost pattern)
- `scenes/phone_apps/factions_app.gd`: `_build_intel` ("Veins:" line gated on vein security)
- `systems/raiding.gd`: `security_profile`, `prepare_raid` (raid entry: block spend, event context)
- `systems/ambush.gd`: `maybe_trigger` (runs after district actions; scouting may or may not count as one)
- `systems/player_moves.gd`: `intelGate` uses of `Intel.knows`
- `data/constants.json`: `intel` (levels, `gain.scout` exists but nothing uses it yet, `securityRead`)
- `data/dial.json`: Physics lens `effects.physics.world` text
- `tests/test_intel.gd`
- REFERENCE.md §1.11 "Intel" (data), §3.1 "Intel", §3.12 "Security profile", §1.4 Lenses, §6 save format (if new state)
- `.scratch/lenses/spec.md`: "Physics — security read"

**Status:** ready-for-human

## Notes

**Current state (after ticket 10):**
- Intel levels unlock in list order: `veinSecurity` 20 → `holdings` 40 → `stockpileLocation` 60 → `stockpileSecurity` 80 → `stash` 100.
- The raid site sheet shows Alarms / Ward / Guards rows. Each row shows the real value, or `?` below vein security.
- A Physics lens at Sense ≥ 2 reads vein security from meter 0 (option B, "+1 level").
- No scouting action exists. `gain.scout` (+8) is in data but unused.

**Rough scope estimate:** moderate. About one ticket for a plain Scout button; 2–3 tickets for an authored scout event.
1. Data: move `veinSecurity` up the ladder. It must be reordered, because levels unlock in list order. Small.
2. Per-vein scouted state, e.g. on the faction vein: save version bump, backfill, tests. Small to medium.
3. Scout action:
   - Plain: a button on the faction vein card costing 1 time block. It marks the vein scouted, applies `gain.scout` to the faction meter, and may run the ambush roll. About one ticket.
   - Authored event: checks, spotted outcomes, prose (writing-guide, storyboard). 2–3 tickets.
4. Sheet read: a row counts as known if the player is at the intel level OR the vein is scouted. Trivial.
5. REFERENCE, CODEMAP and tests.

## Open questions

1. **New threshold:** where does `veinSecurity` sit in the ladder, and at what meter value? Or is it replaced by a per-vein-only read, with no faction-wide unlock?
2. **Staleness:** does scouted info expire (N days), reset when the faction upgrades security / changes guards / reallocates kit, or show a snapshot ("as of day N") that can be wrong?
3. **Snapshot or live:** does a scout record what it saw, or does it unlock live reads of that vein?
4. **Cost and risk:** 1 time block only, or also a chance of being spotted (alert/wary state on the next raid, relation hit, ambush)? Does it count as a district action for ambush?
5. **Plain button or event:** a plain action, or an authored scout event with checks (and prose)?
6. **Intel gain:** does scouting a vein also add `gain.scout` to the faction meter?
7. **Physics lens:** keep "+1 intel level" with vein security now higher up the ladder? Or a new effect, e.g. scouting reveals more, lens scout costs no block, or the lens reads one row (ward) for free?
8. **Factions app:** keep its "Veins: N Warded…" summary on the faction-wide level? Should scouted veins appear there?
9. **Partial reads:** should the rows unlock separately (e.g. guards at one level, ward at another, alarms only by scouting)?
10. **AI symmetry:** do factions "scout" player veins too, or is this player-only?
11. **Where it's shown:** only the raid site sheet, or also combat prep / the raid event context?

## Outcome

- [ ] Each open question answered and recorded under `## Comments`
- [ ] REFERENCE.md / spec changes agreed (no design written as decided before the human approves)
- [ ] Implementation tickets written as vertical slices with blocking edges
- [ ] This ticket renamed `_COMPLETED`

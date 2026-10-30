# 08 — Grilling + proposal: vein raids as stage trees (needs human approval)

**What to build:** Vein raid approaches stop being one roll each. Each approach becomes a branch of stages, and each stage gives the player choices on how to handle it. Items and observation can open alternative choices or raise the odds within a stage. Failure escalates (the guards are alerted and searching) rather than always starting the fight.

First run a grilling session (the `grilling` skill) with the human. Then write a proposal covering the rebuilt `vein_raid` plus two new vein-raid events. Each event is at a different location type from the others.

Human's direction (from the review session):
- **Blast through:** fight, blow open gates and doors.
- **Stealth:** break in unseen through windows, doors and cameras. Example: a high physics observation spots a gap to slide something in and open the latch. Enhancement Powder forces it quickly and quietly. Blast blows the window in, noisily, and the guards are now alert and searching for the rest of the event.
- **Bluff:** conversation options to get past guards and gain access.
- **Luck:** walk past just as the guard looks away; the door was left unlocked; the cameras short out; a car backfires as you bash the lock.
- **Items as options within a stage**, for example guards coming:
  - Prophet's Breath: know exactly when and where they come, and avoid them.
  - Time Pearl: freeze them and rush past, or take out the line guard in a fight before going on.
- **Be A Lady:** raises the odds of every choice (already true for event rolls) and lowers the chance of alerting the guards (cover roll, 17).

The grilling must settle:
- whether the four styles (blast / stealth / bluff / luck) are the top-level approaches, and how they map to the observation ores
- stages per branch and the rule for odds per stage (stacked rolls compound: three stages at 0.6 is about 22% overall)
- alert tiers: what each tier changes (later odds, options gated, guards searching) and when alert starts a fight
- the full item map: Enhancement Powder, Blast, Be A Lady, Prophet's Breath, Time Pearl, Wormhole, Pan's Rapture, Panic, Pandemonium, and which effect kind each uses per stage (`bonus` / `unlock` / `bypass` / `remove` / `fightStart`, item options without a roll, alert raise/lower, cover)
- mid-raid fights (e.g. the line guard): guard counts, what a win leads to; a loss ends the raid (decided)
- switching approach mid-raid (stealth fails, go loud)
- card count per event, to scope the prose work

For each of the three events, the proposal gives:
- premise and location, who guards it, what makes it distinct
- observations: which ores, what each tier reveals
- branch per approach: stages, the choices at each stage, observation gates, item effects, alert changes, fights
- failure paths and how each branch reaches the claim/loot card

Write it to `.scratch/raid-events/raid-variants-proposal.md` and hand it to the human. Do not write event JSON or prose.

After approval, write the per-beat prose tickets in this folder: one per beat per event, each referencing `docs/writing-guide.md` and flagged `PROSE-REVIEW:`. Each is blocked by its event's build ticket (19 for `vein_raid`, 10 / 11 for the new events).

**Blocked by:** None — can start immediately (engine tickets 13–18 can run in parallel).

**Relevant files:** `data/events/vein_raid.json`, `.scratch/COMPLETED/observation_COMPLETED/raid-events-spec.md`, `docs/writing-guide.md`, `docs/CONTENT-GUIDE.md`, `docs/M1-LONDON.md` (districts, sites), `CONTEXT.md` (site vs vein), `data/recipes.json` (item ids), `systems/active_effects.gd` (Be A Lady, Prophet's Breath), REFERENCE.md §3.9a Event choice checks, §3.9d Observation, §3.7b Open/Guarded round combat.

**Status:** ready-for-human

- [x] Grilling session held; decisions recorded at the top of the proposal
- [x] Proposal covers `vein_raid` (rebuilt) and both new events with the fields above
- [ ] Human approval recorded in the doc
- [ ] Per-beat prose tickets written after approval
- [ ] Not marked `_COMPLETED` before approval

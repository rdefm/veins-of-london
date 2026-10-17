# Combat port — Open/Guarded round planning becomes live combat

Status: ready-for-agent

Builds on: `.scratch/COMPLETED/combat-revamp_COMPLETED/spec.md` (the prototype rules) and `.scratch/COMPLETED/combat-prototype-ui_COMPLETED/` (the prototype screen).

Save compatibility: not required for a save taken mid-fight. Saves outside combat must load.

## Problem Statement

Live combat is still "press Attack until someone falls over". The sandboxed Combat Prototype in the Debug app (Open/Guarded guard states, committed enemy round plans shown as intents, fog of war, six moves, per-action decisions, Rewind to last pick) plays the way the game is meant to play, but no real fight uses it.

## Solution

The prototype's rules and screen replace live combat outright. The old speed-queue/Attack engine is deleted, with no toggle. Every combat context (muggings, raids, defences, home raids, ambushes, event fights, debug fights) runs on the new rules, using the player's real HP, loadout, Dial, allies and XP. Live-only features survive, adapted to actions: Dial Complications, reinforcement queues, enemy/guard/raider kits, anger/fury, disarm, the Pan family, Panic, Wormhole, Failsafe and the Rewind consumable.

## Decisions (signed off 2026-10-17)

- **Replace outright.** The prototype system, screen, data, tests and Debug card are deleted once every context has moved over. Migration is expand–contract internally: contexts move one at a time, and a final ticket deletes the old engine and the transitional routing.
- **Values.** The prototype's current draft values (chip ×0.25, actions/crit/fog curves, archetype stats including V2, Leg it 0.65) become production values in REFERENCE.md as they stand. Tuning follows later, through the sim.
- **Level range.** Combat Skill stays 1–5 for the port. `.scratch/skill-level-cap-10/issues/03` is rewritten to also extend the actions-per-round, crit and fog curves to 10.
- **Moves.** All six (Guard, Strike, Feint, Stun, Lure, Leg it) are available from the start. Move learning and move levels are a later spec.
- **Rewind.** Rewind-to-last-pick (snapshot cap 2) costs one `rewind` consumable or a loaded Dial rewind cast. Failsafe stays as the automatic rewind on player KO. The guard-kit rewind stays.
- **Enemies.** Each enemies.json template gains an `archetype` (mugger / bruiser / turtle / V2 variants) plus plan patterns, and keeps its own hp, attack, speed, names and sprites. The agent drafts the mapping and the human approves it (ticket 01).
- **Enemy level** (drives HP/attack/speed/crit/actions/fog) comes from a data table over the existing scaling drivers: vein value tier, faction strength, harder mugger, home raid. Drafted in 01 for approval.
- **Ally level.** A contact uses its own combat skill if it has one, else an authored level in its combat kit. Hired guards and hired muscle use a flat authored level from data.
- **Extra items** (Panic, Pan's Rapture, Panger, Pandemonium, Wormhole, Failsafe, disarm) keep their old effects, adapted to the action model (01 drafts the adaptation).
- **Kept and adapted:** Dial Complications (1 action, guard state unchanged; ally casts too), reinforcement queues, enemy/guard/raider kits shown as intents in the committed plan, anger/fury and disarm statuses.
- **XP.** A fixed lump per fight: win 30 Combat XP, loss 10% of that (3), a successful Leg it 0. Gym Train unchanged. Per-move-type XP (Strike, Feint, …) comes later.
- **Leg it.** Prototype rule: success ends the fight `fled`; failure leaves the actor Open and loses the rest of its actions that round. No parting shot. Blast's one-use flee boost is kept.
- **Screen.** The prototype screen becomes the live combat screen (strip carousel, intents including unread `?`, guard overlay, block-reason `?`, Readouts). It keeps the prep sheet, top bar, exit/debrief, pacing toggle and Bag drawer.
- **Carry-in effects.** An active out-of-combat Prophet's Breath gives sight from round 1 (and still blocks ambushes). An active Be a Lady gives max rolls and a 1/3 crit chance while it lasts.
- **Debug and sim.** The Debug combat setup gains player/enemy/ally level, archetype and loadout pickers. The balance sim is rewritten against live `Combat` (naive vs reader policy, fog on/off). The old itemless sim and the prototype sim are removed.
- **Prose.** One sweep ticket patches old-combat references lightly and adds a first-fight hint for Guard/Strike/Feint, all flagged `PROSE-REVIEW:`.

## Out of Scope

- Balance tuning beyond carrying the prototype values over.
- Combat Skill levels 6–10 (cap-10 ticket 03).
- Move learning, move levels, per-move XP.
- Combat openers (Talk / Bribe / Intimidate).
- New art or animation beyond what the prototype screen already has.

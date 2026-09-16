# PRD — Vein Raiding (Player ↔ Faction)

**Status:** Draft, from a `/grill-me` session (2026-08-07).

## Why

`systems/combat.gd` already has a `generate_raid_enemy()` stub with a comment explaining it's debug-only because "M0 has no NPC-claimed-vein storage." **Chunk 1 (Faction Vein Ownership)** creates that storage. This PRD closes the loop both directions: the player raiding a faction's vein to take it, and factions raiding the player's own veins — including a full escalation loop (raid them → they retaliate → you may have to raid them again).

`data/vein_security.json` already carries an unused `raidResist` field per tier (none/basic/warded/guarded) — further evidence this was always the intended eventual use of vein security, just never wired to a real mechanic.

## Depends on

- **Chunk 1 (Faction Vein Ownership)**: needs real faction-owned veins (with security/value) to raid.
- **M1's district event-card engine** (`systems/district_deck.gd`/`events.gd`): the stealth sequence is authored as event-card content on this engine, not a bespoke new system.

## Direction A — Player raids a faction's vein

### Flow

1. Player travels to the district holding the target vein (existing `Travel`/time-block rules, unchanged — no new travel mechanic).
2. Raid is initiated as an **event card / short event chain** on the existing district event-card engine — reuses the same content/choice/branching system district events already use, not a bespoke raid screen.
3. The event card resolves a **stealth check**, gated by:
   - A new dedicated skill, **stealthSkill** (third skill alongside `craftingSkill`/`cultivatingSkill`, same progression shape).
   - The target vein's security tier (`raidResist` from `vein_security.json`) and value (ore type/level).
   - Consumable items spent during the event (existing items like `enhancementPowder`, plus new stealth-specific consumables to be added) — exact items/effects are determined when the actual event cards are written, not fixed here.
   - Player choices within the event card itself.
4. **Stealth success** → no combat, raid proceeds to the claim/loot choice (below).
5. **Caught** → drops into combat against the vein's guards, via the existing `Combat.generate_raid_enemy(vein_id, level, guards, template)` (already built, previously unreachable outside debug). Winning combat proceeds to the claim/loot choice; losing combat fails the raid (existing combat-loss handling applies — no new raid-specific punishment invented).
6. This default outcome mapping (stealth success / combat win → the vein is available; anything else → raid fails) is the baseline; individual event cards, written per circumstance (location/ore type/security tier/faction), can vary the specifics within that shape.

### Claim vs. loot choice

On a successful raid (clean stealth or won combat), the player chooses:
- **Claim it**: the vein converts to player ownership outright. Always costs a **severe relation hit** with the owning faction — claiming is visible on the map, so they know it was you regardless of how clean the entry was. This relation hit is what drives the escalation loop into Direction B: a badly damaged relation raises that faction's future raid chance against the player's own veins (no separate "vendetta" flag needed — Direction B's trigger is already relation-based, see below).
- **Loot only**: a smaller one-time payoff (ore/cash, or damage to the vein's security/charge) and the vein stays with the faction. Only the moderate "got caught" relation hit applies here (and only if the player was actually caught during the attempt — a fully clean stealth-and-loot leaves relation untouched).

## Direction B — A faction raids the player's own vein

### Trigger

- Resolved on the daily tick, same cadence family as the existing NPC-claim roll — not a player-interrupting encounter by default.
- Trigger chance is driven by: the player's relation with that faction (low relation = more likely — this is what makes Direction A's severe "claim" relation hit consequential), the district's `dangerMod`, and the target vein's own security tier (`raidResist` reduces the chance, same field Direction A reads from the other side).

### Alarm — the one case with player agency

- A **new, separate purchasable upgrade** ("alarm/cameras"), independent of the existing 4-tier security ladder (none/basic/warded/guarded) — not folded into those tiers.
- If the raided vein has the alarm upgrade, the raid doesn't resolve silently: the player gets a notification and can choose to travel to that district (standard travel rules — costs the normal 1 time block for a different district, no separate countdown system) to trigger a **defend encounter** (combat).
  - Player arrives in time → defend combat. Win = raid repelled, vein safe. Lose = vein lost (see below).
  - No alarm, or player doesn't travel there in time → resolves automatically off-screen, same outcome roll as the no-alarm case.

### Outcome

- A successful raid against the player is a **whole-vein loss** — it converts to the attacking faction's ownership. Symmetric with Direction A's "claim" outcome, not a partial smash-and-grab. This makes security/alarm investment and relation management real stakes, and closes the loop: a vein taken this way can later be raided back via Direction A.
- Either way (resolved off-screen, or after a defend-encounter loss), the player is notified afterward (Ticker/notification, consistent with how the game already surfaces background world-state changes like NPC claims/abandonment).

## Explicitly out of scope for this pass

- Faction-vs-faction raiding — covered separately by **Chunk 1c (Faction Territory Rivalry)**.
- Any UI/flavour text in the site/vein sheet hinting at raid difficulty before attempting — Chunk 1 kept that sheet read-only-info-only; a raid entry point (button/action) is new UI this PRD adds but its exact placement is implementation detail.

## Open questions for the later ticket-level spec

- Exact stealth-check formula (how `stealthSkill`, `raidResist`, vein value, and consumable bonuses combine into a success chance).
- Exact relation-hit magnitudes for "caught" vs. "claimed," and the exact relation → Direction-B-trigger-chance curve.
- Exact alarm upgrade cost/purchase flow, and whether it stacks with or is independent of the existing security tier's cost.
- Whether winning a Direction-B defend-encounter has any positive consequence (loot from attackers, relation recovery) beyond just "vein safe" — not decided, currently no.
- Content plan: how many/which raid event cards get written first (which factions/districts/circumstances), left to the content pass alongside Chunk 1's faction flavour.

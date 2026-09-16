# PRD — Faction Vein Ownership & Lifecycle

**Status:** Draft, from a `/grill-me` session (2026-08-07). Product-level decisions locked; implementation schema (exact GameState field names, tick wiring) is deferred to the eventual ticket-level spec.

## Why

Today `state.world.sites` only distinguishes `claimed` (player) and `npcClaimed` (a single anonymous "someone else's problem now" bucket — no identity, no vein object, just a flag). `docs/M1.5-NETWORK-MAP.md` N2 already specifies that the Network map should draw a coloured line per faction, and `MapLayout.faction_first_presence_anchor()` exists as an unused stub for it — but there is nothing upstream that actually attributes a claimed site to a specific faction, or gives it a real vein (oreType/level/charge/security) the way player veins have.

This PRD makes faction ownership real: named factions claim sites, grow real veins on them, and those veins behave like active economy participants (not static scenery) — closing the gap between what N2's rendering grammar already promises and what the data model can currently support. It also retires the anonymous "NPC-claimed" concept entirely: every non-player claim now has a faction identity.

## Depends on / feeds

- Feeds **Chunk 2 (Map rendering)**: multi-faction lines need real faction-owned stops to draw.
- Feeds **Chunk 6 (Raiding)**: player-raids-faction needs a real vein (security, value) to raid; faction-raids-player needs relation data this PRD doesn't touch but sits next to.
- Split out of this PRD into their own chunks (referenced, not designed here):
  - **Chunk 1b — Faction Resource Economy**: what generates/spends a faction's dynamic resource stat, and the longer-term cultivator-staffing model.
  - **Chunk 1c — Faction Territory Rivalry**: faction-vs-faction vein takeover.

## Rules

### Claiming

- Reuses the existing daily-tick claim roll (`systems/sites.gd`, currently flips `npcClaimed = true` on an eligible unclaimed site) — no new tick step.
- Every district has one `factionPresence` faction (`data/districts.json`). When a site in that district is claimed, the presence faction is heavily favoured; there's a small chance a rival faction encroaches instead. No change to the existing roll's frequency/eligibility rules (siteCap, "worst unclaimed" targeting, etc.).
- The anonymous "NPC-claimed, no identity" state is retired. Every non-player claim now names one of the 5 canonical factions (`collective`, `firm`, `guild`, `network`, `conclave`).

### Claim = instant vein

- Claiming is a single event, same cadence as today: the moment a site is claimed by a faction, it immediately gets a real vein (oreType inherited from the site, level 1, security rolled — see below). No separate "claimed land, not yet seeded" intermediate state.

### Growth (placeholder — see Chunk 1b for the real target)

- Placeholder for now: faction veins grow at the **same pace as the player** — reuse `vein_levels.json`'s existing devBar/level thresholds directly, no new balancing table.
- Longer-term vision (design fully in **Chunk 1b**, not here): a cultivator-staffing model. Each faction vein needs a cultivator to grow at normal rate; one cultivator spread across 2 veins costs -25% speed; the number of cultivators a faction can field is gated by its resource stat. This is meant to favour small/agile factions growing fast and to punish large factions with bureaucratic drag/wastage. Flagged as future direction, not built now.

### Security

- Faction veins get a security tier (none/basic/warded/guarded, per N2), rolled from a distribution that depends on three things:
  1. **Faction flavour bias** — e.g. street-level gangs skew away from the more expensive tiers regardless of anything else.
  2. **Vein value** (its ore type/level) — more valuable veins skew toward higher security.
  3. **Faction resource level** — a resource-strapped faction can't afford to secure everything at max tier, even if it wants to. The resource stat itself is designed in **Chunk 1b**; this PRD only establishes that security rolls consult it.

### Abandonment

- Faction veins follow the same abandonment/ageing-out rule already built for generic NPC claims (ticket 05, `sites.gd`) — an unmanaged, low-value faction vein can revert to unclaimed after enough time. No new mechanic; the existing rule now also applies to faction claims.

### Faction vs. faction

- Factions **can** take a vein from another faction (not just from unclaimed land). The contest-resolution logic (trigger frequency, odds from security/resources/inter-faction relations) is designed in **Chunk 1c**, not here.

### Player-facing UI

- Tapping a faction vein reuses M1's existing site/vein sheet (N5 — interaction contract unchanged).
- Shows read-only info only: owning faction (name + colour), ore type, level, security tier. No action buttons yet — no cultivate/charge (it isn't the player's), and no raid button until Chunk 6 lands.
- No relation-flavoured text or raid-difficulty hinting in the sheet (kept plain for now; revisit if Chunk 6 wants it).

## Explicitly deferred (own PRDs)

- **Chunk 1b — Faction Resource Economy**: what generates/spends a faction's resource stat; the cultivator-staffing growth model.
- **Chunk 1c — Faction Territory Rivalry**: faction-vs-faction vein takeover mechanics.
- **Chunk 6 — Raiding**: player raiding a faction vein (stealth/event-card/combat), and factions raiding the player's veins (relation-driven trigger chance).

## Open questions for the later ticket-level spec

- Exact GameState schema for where a faction-owned vein object lives (e.g. embedded on the site record vs. a new unified veins list) — deliberately left to implementation spec, not decided at PRD level.
- Exact security-tier probability table per faction/value/resource band.
- Exact claim-weighting probability (how "heavily favoured" the presence faction is vs. rival encroachment chance).

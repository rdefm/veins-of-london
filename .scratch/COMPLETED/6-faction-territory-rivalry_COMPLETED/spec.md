# PRD — Faction Territory Rivalry

**Status:** Draft, from a `/grill-me` session (2026-08-07).

## Why

**Chunk 1 (Faction Vein Ownership)** established that factions can take veins from each other, not just from unclaimed land, and split the contest-resolution logic out into this PRD. This is what makes the Network map's faction territory feel alive beyond the player's own actions — factions genuinely compete with each other, not just pursue empty land.

## Depends on

- **Chunk 1 (Faction Vein Ownership)**: needs real faction-owned veins to contest.
- **Chunk 1b (Faction Resource Economy)**: resource disparity is one of the contest-odds inputs.

## Rules

### Trigger

- Resolved on the daily tick, same simulation family as Chunk 1's claim roll and Chunk 1b's income/spend.
- A faction's `industries` (`factions.json`) bias how often it **initiates** a rivalry attempt at all — e.g. the Firm ("raiding" industry) picks fights far more often than factions without a raiding-flavoured industry, who mostly get targeted rather than targeting others. Reuses existing `industries` data, no new per-faction aggression stat invented.

### Odds

Whether an initiated attempt succeeds is driven by:
- **Resource/security disparity** — the attacking faction's resource level (Chunk 1b) vs. the defending faction's, and the target vein's security tier (`raidResist`, same field Chunks 1/6 already read).
- **A new faction-to-faction relation matrix** (separate from the existing player-faction relation stat) — **dynamic**, not static: it shifts over time based on rivalry outcomes. Losing territory to a faction worsens relation with them, which feeds back into future rivalry odds — grudges compound rather than resetting.
- This relation matrix is **purely an internal simulation input** — not shown to the player, not player-influenceable. No diplomacy UI/mechanic in this pass; explicitly flagged as a possible future direction if wanted later.

### Outcome & visibility

- A successful rivalry attempt transfers the vein's ownership from the defending faction to the attacking one — same shape as any other ownership change Chunk 1 already defines (vein/security/level carry over or reset per Chunk 1's own rules, not redefined here).
- **Silent** — no Ticker notification. The player discovers the change the same way they'd discover any other map-territory change: by looking at the map, where **Chunk 4 (Map animations)**'s existing replay-queue mechanism already handles showing ownership changes (its queue/animation set should be understood to include "vein changes owner via rivalry," not just player- or claim-tick-driven changes — worth confirming when Chunk 4 moves to implementation).
- A defending faction that loses territory naturally becomes poorer via Chunk 1b's vein-derived income tie — no separate penalty needs inventing; the resource system already produces the decline.

## Explicitly out of scope for this pass

- No player-facing diplomacy or influence over the faction-to-faction relation matrix.
- No Ticker/notification volume for these events.

## Open questions for the later ticket-level spec

- Exact relation-matrix seed values and the exact "losing territory worsens relation by how much" feedback formula.
- Exact resource/security-disparity-to-odds formula.
- Whether Chunk 4's animation queue needs any change to actually pick up rivalry-driven ownership changes (it's designed around daily-tick events broadly, so this should be additive, but confirm at implementation time).

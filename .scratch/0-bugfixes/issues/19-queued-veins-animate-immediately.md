# 19 — Seeded/claimed veins animate and appear immediately, regardless of active tab

**What to build:** A vein queued via `queue_seed_claim` (player Seed action, NPC daily-tick claim roll, faction rivalry takeover) is deliberately excluded from the Map tab's static draw list until its map animation plays back — by design, so the animation has something to reveal. But that playback currently only drains once, in `MapCanvas._ready()`, which only fires when the player navigates *onto* the Map tab. Any vein queued while the player is already on the Map tab (e.g. via Seed/Cultivate/Harvest bubbles, or a daily-tick roll triggered by a time-advancing action taken from the map) has nothing left to trigger its playback — it sits invisible in state, sometimes for several turns, until the player leaves and re-enters the tab. This also explains faction-seed notifications firing with no corresponding vein appearing on the map.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] A vein's queued map animation plays as soon as it's queued (`queue_seed_claim`), whether or not the Map tab is the currently active screen — not gated behind a Map-tab-visit `_ready()` firing.
- [ ] If the Map tab isn't active when a vein is queued, the animation either plays retroactively the moment the tab becomes active, or the vein is at least immediately visible in the static draw list even if its "reveal" animation is skipped/deferred — no scenario should leave a real, state-present vein invisible on the map.
- [ ] Player-seeded veins appear on the Map tab immediately after a successful Seed action, with no multi-turn delay.
- [ ] Faction/NPC-claimed veins that trigger a "faction seeded a new vein" notification are visible on the map at the same time the notification fires.
- [ ] Staying on the Map tab across multiple time-advancing actions (e.g. repeated Harvest/Cultivate calls that roll daily ticks) still shows every queued vein's animation — none get silently dropped because a prior drain already ran.
- [ ] Existing `MapCanvas`/`MapEvents` playback tests updated; add coverage for queuing a vein while the Map tab is already active.

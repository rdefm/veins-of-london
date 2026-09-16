# Follow-up specs — deferred out of calc-effect-wiring

Four pieces of lab-effect scope came up during the grill for this feature (2026-08-14) that got explicitly deferred rather than built now, each because it needs a system that doesn't exist yet and building that system inline would have ballooned one consumable effect into a feature-sized change. None of these are tracked as tickets — each needs its own spec/grill pass before it's ticket-ready. Listed so they aren't lost.

## 1. Prophet's Breath — event chance-preview half

**Deferred from:** ticket 03 (combat evade-buff half shipped there).

The event system has no visible per-choice success % today — choice cards are authored with fixed `effects` arrays, and any RNG lives inside a hidden `"chance"` op (`events.gd:208`) that only fires after the player commits. Prophet's Breath wants to peek-roll a choice's chance node(s) and reveal pass/fail *before* the player picks. Needs: a generic "resolve a choice's chance op without applying its effects" capability in the event runner, plus a UI treatment for surfacing the peeked result on the choice button.

## 2. Be a Lady — full effect (combat half + universal favorable-RNG bias)

**Deferred from:** ticket 02/03 entirely — not shipped in either.

Originally scoped as a one-shot buff (guaranteed player hit/max-damage in combat, boosted odds on a couple of named out-of-combat rolls), but the design that emerged is bigger: apply for one full day to **every** `Rng.chance()` call in the game, nudged in whichever direction favors the player. That requires:
- A polarity taxonomy across all ~23 `Rng.chance()` call sites in `systems/` — several have no clean player-relevant polarity (faction-vs-faction rolls, world/weather triggers) and forcing one onto them means inventing a value judgement the design doesn't currently make.
- Per-event-card authoring: the event runner's `"chance"` op (`events.gd:209`) is generic and reused by every event card — whether its success is good or bad for the player depends on that specific card's authored `on_success`/`on_fail`, so every existing (and future) event JSON needs individual annotation, not an engine-level fix.
- The combat half (guaranteed hit via zeroing the *new* enemy evade-chance stat from ticket 01, guaranteed max damage) is comparatively simple and could ship early once ticket 01 lands, but was kept bundled with the rest so the effect isn't split across two disconnected deliveries.

## 3. Pan's Prank — full effect

**Deferred from:** ticket 02/03 entirely — not shipped in either.

Recipe description frames it as a crowd/event effect ("aimed at a crowd, not a person"), but the event system has no crowd-NPC concept to hang that on. Even scoped down to combat-only, it needs a sub-choice UI at use-time (rage / panic / confidence — no other consumable needs a choice modal) and each emotion's mechanic needs real design, not a placeholder guess:
- **Rage** on an enemy — higher damage (bad for the player, so why choose it?) or a reckless-attack tradeoff (lower accuracy for higher damage)?
- **Panic** on an enemy — a per-turn chance the enemy flees the fight outright?
- **Confidence** — reads backwards if aimed at an enemy ("increases their success"); is this meant to target the *player's own* stats instead?

## 4. Wormhole — raid-alert / instant-HQ-escape clause

**Deferred from:** ticket 03 (combat flee + trigger-free travel shipped there).

Flavor text: "instant transport back to HQ if you get an alert that it's being raided." No alert/warning system exists before a home raid fires — `homeRaidEventPending` is only ever set by debug code (`debug_start.gd:106`) today; a real raid (REFERENCE.md §3.3's daily raid roll) just happens silently, launching on the player's next home visit, with no window where the player is "alerted" and could react. Needs a raid-warning system built first (what triggers it, how much lead time, what the player sees) before wormhole's escape clause means anything.

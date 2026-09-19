# 01 — Canonical contract amendments (spec, not code)

**What to build:** The mechanics/schema decisions the visual work depends on, written into the canonical docs so later tickets execute rather than invent. Agent drafts each item as a proposal in the doc itself, marked clearly as draft; the human signs off (removing the draft marker) before tickets 03, 05, 07 and 10 start. No code changes in this ticket.

Items to define:

1. **Resumable turn progression contract.** A persisted turn cursor inside the combat state (what it points at, how a round boundary ticks, where a Motion extra turn sits as its own decision point). Progression advances from one player decision point to the next; combatants faster than the player act before the first command of a round. A combat snapshot is pushed at every player decision point (today: once per `player_attack()` call). Existing formulas, XP, rewards, flee/item rules unchanged.
2. **Persistent selected-target representation** covering player, ally and enemy (today only an enemy index is persisted). Rules for how it clamps when the target is KO'd, and what enemy-targeted actions do when the selection is not an enemy (they become unavailable — never silently retarget).
3. **Ally-targetable effect table.** Which consumables and loaded Complications may target an ally when one is selected, at what cost/turn consumption, and which stay self-only. Healing Burst on an ally is the confirmed case; do not assume every self-effect transfers.
4. **Bounded queue-projection policy.** How far ahead the visible turn queue projects from the cursor: must include every living combatant's next turn, repeated occurrences and extra turns; refreshes when scheduling conditions change; never pre-rolls outcomes or promises an infinite future.
5. **Fight location key.** A `locationKey` recorded on the combat state at start: district id for raids/defend (via the vein's district), the player's current district for muggings, a fixed key for home raid. Backdrop lookup order: location plate → context plate → palette fallback colour.
6. **Presentation amendments** to the combat-animation vision: tap selection replaces swipe; occurrence cards replace deduplicated roster cards; a subtle arrow replaces the selected-sprite glow; flat command rows replace action cards; upper/lower two-region layout replaces the 220px stage + furniture row.

**Blocked by:** None — can start immediately.

**Relevant files:**
- `docs/REFERENCE.md` — §2 (combat state schema), §3.7 Combat (Use Healing Burst bullet), §3.7a Squad combat (Turn order, Targeting bullets), §3.9 Snapshots & Rewind
- `docs/combat-animation-vision.md` — §2.1 Backdrops, §2.2 Squad roster and stage composition, §2.4 Turn-order strip, §2.5 Command deck
- `CONTEXT.md` — add "turn occurrence" vs "combatant" vs "selection" terminology
- `systems/combat.gd` — read `build_turn_queue`, `player_attack`, `_start_combat`, `push_combat_snapshot`, `_restore_from_snapshot` to ground the contract in current behaviour
- `systems/consumables.gd` — read `use_healing_burst`
- `.scratch/combat-refining/spec.md` — "Known mechanical dependencies" section

**Status:** ready-for-agent

- [ ] REFERENCE §3.7a defines the turn cursor, round-boundary tick, extra-turn decision point and snapshot-per-decision-point rule
- [ ] REFERENCE §2 defines the persisted selection representation and its KO-clamp rule
- [ ] REFERENCE §3.7/§3.7a carries an ally-targetable effect table with cost/turn rules
- [ ] REFERENCE §3.7a defines the bounded projection policy
- [ ] REFERENCE §2 defines `locationKey` and its derivation; §3.7 or the vision doc defines the backdrop lookup order
- [ ] combat-animation-vision §2.4/§2.5 amended with the six presentation changes, superseded text left in place with a dated "superseded" note (existing doc convention)
- [ ] Every new item carries a draft marker until the human removes it; ticket is complete only after sign-off

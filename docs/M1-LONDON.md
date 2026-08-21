# M1 — London Exists

**Goal:** the full economy loop played across a living map: 9 districts, one travel rule, prospecting → sites → hospitability, NPC site-claiming, a district event deck, and a cultivating tutorial event. No ore-roster migration needed (M0 started on the final roster).

Same rules of engagement as M0. New data is canonical HERE (this doc extends REFERENCE.md; on conflict for M1 features, this doc wins).

**Scope note:** the Network Map's full transit-diagram rendering (routing, glyph grammar, filter modes, paper/icon assets) is deferred to `docs/M1.5-NETWORK-MAP.md` — see `docs/adr/0001-defer-network-map-renderer.md` for why. M1 ships the same nav shell, district panel, and site/vein sheet that M1.5 will render against; M1.5's job is narrowly to replace the plain-list Map tab below with the real diagram, reusing the same tap targets. Also see `docs/adr/0002-site-lifecycle-and-npc-claims.md` (siteCap/NPC-claim semantics) and `CONTEXT.md` (site vs. vein, the three site-claim states) — both resolved during the `/grill-with-docs` pass over this document.

---

## D1 — Districts (data)

`data/districts.json`. `oreBias` weights prospected site ore type (see D2). `siteQualityMod` shifts tier weights. `dangerMod` adds to mugging/raid chances for actions in that district. `priceMod` multiplies sale prices when selling there (Archie lane uses the district you sell from). `siteCap` = max concurrent sites in the district, counting ALL states together (unclaimed + player-claimed + NPC-claimed — see D2).

| id | name | oreBias | siteQualityMod | dangerMod | priceMod | siteCap | special | factionPresence |
|---|---|---|---|---|---|---|---|---|
| shoreditch | Shoreditch | {} (uniform) | 0.00 | 0.00 | 0.00 | 7 | home base | collective |
| city | The City | {fate:0.6} | −0.05 | −0.05 | +0.15 | 9 | — | conclave |
| greenwich | Greenwich | {time:0.6} | +0.05 | 0.00 | 0.00 | 10 | — | guild |
| camden | Camden | {physics:0.6} | +0.05 | +0.10 | −0.05 | 6 | — | firm |
| kingscross | King's Cross | {time:0.3, physics:0.3} | 0.00 | +0.05 | 0.00 | 7 | veins here: +1 rightward drift, −1 leftward drift (min 0) | network |
| battersea | Battersea | {physics:0.6} | +0.05 | 0.00 | 0.00 | 5 | — | firm |
| hampstead | Hampstead | {life:0.6} | +0.10 | −0.05 | +0.05 | 2 | — | — |
| whitechapel | Whitechapel | {emotion:0.6} | +0.10 | +0.10 | 0.00 | 7 | vein NPC-raid chance ×1.5 (when vein raids land, M2) | collective |
| soho | Soho | — | — | −0.05 | +0.10 | 0 | marketplace (M4); no veins, no prospecting | network |

`siteCap` above already includes the day-1 faction-vein bump (D2, below) — shoreditch/whitechapel/camden/battersea/greenwich/kingscross/city are each `base + starting-veins-placed-there`; hampstead/soho have no faction presence to seed and keep their original base values.

oreBias semantics: listed weights are the probability of that type; remainder split uniformly among the other types (uniform = 0.2 each).

Flavour: each district gets a one-line `blurb` — DRAFT per CONTENT-GUIDE.md, flag PROSE-REVIEW. District character notes from the vision doc may be paraphrased.

## D2 — Sites & prospecting

Site dict (lives in `state.world.sites` array):
`{ id, district, tier, oreType, bonuses:[String], discoveredDay, claimed:false, factionVein:null, hasNaturalVein:false }`

> **Superseded field:** the anonymous `npcClaimed`/`npcClaimedDay` booleans this section originally described were retired by faction-vein-ownership T01 (`.scratch/faction-vein-ownership/`) — every non-player claim now names one of the 5 canonical factions and carries a real vein object in `factionVein`, not just a flag. The claim-roll frequency/eligibility math below is unchanged; only the claimant's identity and the "claim = instant vein" behaviour are new (see the PRD for the full rationale).

**Site claim states (see `CONTEXT.md`):** a site is exactly one of three states — **unclaimed** (`claimed == false AND factionVein == null`), **player-claimed** (`claimed == true`), or **faction-claimed** (`factionVein != null`, `claimed` stays `false`). Only unclaimed sites are seedable or reroll-eligible. Faction-claimed sites are untouchable by the player in M1 (reclaiming one is M2 combat content) — they leave that state only via NPC abandonment (below).

**Prospect action** (Veins screen and Map screen; costs 1 block, D3): in any district; blocked if district `siteCap` reached, counting sites in ALL three states — instead: re-roll — delete the district's worst **unclaimed** site (faction-claimed and player-claimed sites are never reroll targets) and roll a new one in its place; "worst" = lowest tier index among unclaimed sites, oldest breaks ties.

Tier roll — base weights, then modifiers, then normalise:

| tier | base weight |
|---|---|
| barren | 20 |
| poor | 30 |
| fair | 32 |
| rich | 14 |
| saturated | 4 |

Modifiers: `q = round(siteQualityMod × 100)` → rich += q, poor −= q (floor 0). Cultivating skill: rich += 2×(skill−1), saturated += 1×(skill−1), barren −= 3×(skill−1) (floor 5).

oreType: roll per district oreBias. Bonuses at discovery: rich → ONE of `["vigour","wildCeiling","yield"]` uniformly; saturated → all three, plus `chance(0.05)` → `hasNaturalVein = true` (claiming instantly grants a free second vein of the site's oreType, starting at `growth = seedGrowth` (20) same as any fresh vein, its own freshly-generated `location` distinct from the seeded vein's). Everything about a site (tier, ore, bonuses) is visible before seeding — prospecting is buying information.

Prospecting awards cultivating XP: 10 (barren/poor), 15 (fair), 25 (rich), 40 (saturated).

**Seeding revamp:** `attemptSeed(siteId)` replaces free-floating seeding. Requires: current district == site district, site unclaimed (see claim states above — faction-claimed sites are NOT seedable), tier != barren, 40 ore of the SITE's oreType. Success chance = `cultChance + tierMod` where tierMod: poor −0.15, fair 0, rich +0.20, saturated +0.35 (clamp 0.05–0.95). On success: site.claimed = true; vein created with `district`, `siteId`, `hospitability = {tier, bonuses}`, location generated with district-appropriate street names (extend the generator: per-district street array, 4–6 real street names each — draft, PROSE-REVIEW not needed for street names). On failure: ore lost, site remains (may be faction-claimed later).

**Hospitability application (read by existing systems, per vein-growth-state ticket 05):**
- `"vigour"`: +1 to this vein's rightward drift, −1 to its leftward drift (min 0); stacks with the King's Cross district special, which is the same effect (`Cultivating.vigour_stacks`/`effective_drift`).
- `"wildCeiling"`: raises this vein's growth ceiling from 100 to 120 (`Cultivating.ceiling`).
- `"yield"`: applied to the ROLLED prune result, not the growth table's range bounds — roll the prune yield as normal, then `finalYield = max(rolledYield + 1, round(rolledYield * 1.15))`. This guarantees every prune on a "yield" vein nets at least +1 over what the base roll would have given, even where 1.15× on a small integer would otherwise round away to nothing.

Terroir tier also drives yield directly: `terroirYieldMult` (poor 0.6 / fair 1.0 / rich 1.6 / saturated 2.4) multiplies every prune's rolled yield — see `data/vein_growth.json` and `CONTEXT.md`'s Terroir entry. This is the mid/late-game progression now that growth itself is never permanent.

**NPC site-claiming (daily tick, step ⑤b):** each unclaimed site: `p = 0.03 + 0.02 × tierIndex + 0.01 × ageDays` (tierIndex: poor 0, fair 1, rich 2, saturated 3; barren never claimed; ageDays = day − discoveredDay), cap 0.25. Claimed → one of the 5 canonical factions is picked (`Factions.pick_claimant()`, heavily weighted toward the district's `factionPresence`) and instantly seeded a real Lv1 vein (`site.factionVein`, oreType from the site, security tier rolled from faction flavour/vein value/faction resource level — see faction-vein-ownership T01), notification "<Faction> have moved onto the <tier> site in <district>." Faction-claimed sites remain visible on the map; taking one back is M2 combat content — in M1 they persist until NPC abandonment fires (below).

**NPC abandonment (daily tick, new step ⑤c, runs right after ⑤b):** each faction-claimed site: `p = 0.02 + 0.005 × ageDaysSinceClaim` (`ageDaysSinceClaim = day − site.factionVein.claimedOnDay`), cap 0.08, flat across tiers (richer claims are not stickier). (Retuned in ticket 22 — the original 0.05/0.01/0.15 curve churned faction veins too fast against the day-one roster's scale.) On hit: **delete the site (and its embedded faction vein) outright** (not a reversion — the plot is gone, not dormant; this is deliberate so "wait out the good faction-claimed site" is never a viable strategy). This frees a `siteCap` slot; the district's next prospect rolls a brand-new site from scratch, not the old one reappearing. Notification: *"Word is the outfit running the <tier> site in <district> got sloppy. The plot's gone quiet — worth a fresh prospect."* (draft, tone-bible register, PROSE-REVIEW).

**Day-1 faction vein rosters (`Factions.seed_day_one_veins()`, `.scratch/8-faction-starting-veins/`):** a fresh game doesn't start every faction at zero — new-game init (title screen and the Save/Load app's "New Game", right after `GameState.reset()`; NOT folded into `reset()` itself, and NOT run by `DebugStart`, which builds its own hand-picked site list) pre-places a starting roster of faction-claimed sites+veins via this same `factionVein`/site mechanism, one district-home faction at a time:

| faction | count | district(s) | levels |
|---|---|---|---|
| Collective | 8 | Shoreditch (4) / Whitechapel (4) | 1–3, fixed roll |
| Firm | 4 | Camden (2) / Battersea (2) | 2–3, fixed roll |
| Guild | 7 | Greenwich | 5 @ 2–3 (fixed roll) + 2 @ Lv4 |
| Network | 4 | King's Cross | 3–4, fixed roll |
| Conclave | 7 | City | 4 @ 2–4 (fixed roll) + 3 @ Lv5 |

"Fixed roll" = each vein's level was rolled once, uniformly at random within the stated range, and the resulting values are hardcoded constants (`Factions.DAY_ONE_ROSTER`) — every new game gets the same level distribution, not a fresh roll per playthrough. Everything else about each starting vein (site tier, oreType, discovery bonuses, security tier) is rolled fresh each new game using the exact same procedural logic a normal prospect/NPC-claim would use — only the level is forced. The ongoing daily NPC-claim tick (⑤b above) and its probability curve are completely unchanged by this; it is a new-game-init-only addition. `data/districts.json`'s `siteCap` for every district that receives starting veins is bumped by exactly that count (base + placed, not spent from the base) so normal prospecting capacity is unaffected — see the D1 table's siteCap column and footnote above. `data/map_layout.json`'s per-district `stopSlots` were extended to keep the `siteCap + 2` buffer GameData validates at boot.

## D3 — Travel (the one rule)

`state.world.currentDistrict`. Acting on a district-located action (prospect, seed, cultivate, harvest) sets currentDistrict to that action's district as a free side effect — there is no travel surcharge; every districted action costs the same block count regardless of whether it targets the current district or a different one (show the cost in the button label as just the action's own cost: "Harvest — 1 block"). The standalone Map tab "Travel" button switches currentDistrict for free (0 blocks) and, like prospecting, rolls for a D5 district event on completion. Waking up (daily tick / rest) resets currentDistrict to "shoreditch" (home). Selling uses the district you are in at sale time (priceMod + dangerMod on the mug roll: `getEffectiveMugChance(0.20 + dangerMod)`).

## D4 — Nav shell (Phone/Map/HQ dock), Bag, and the Map tab (M1 scope)

**Nav restructure (supersedes the M0 screen set):** the nav bar is a **3-slot dock — Phone · Map · HQ** — with Phone as the OS shell (a home button opening the app grid) and Map/HQ as full screens also pinned to the dock as apps within that shell, not peer places beside it. A persistent top bar remains on every screen: cash · day/time-blocks · bag button (D4.4). The M0 screens are redistributed, not rebuilt:
- **Map** — district list and drill-down (this section, M1 scope). World/veins/factions screens are deleted; faction panels open from the district panel and from the Phone directory.
- **HQ** — the property AS the interface: workbench (= the crafting screen; visually upgrades when workshop/library/lab rooms are built), gym placeholder (training arrives M2), rooms, security, stored ore, tier upgrade, assigned contacts. Merges the old property + crafting screens.
- **Phone** — the OS shell: an app grid (the game's home screen) launching Messages (contact list, SMS threads reskinned from old sms screens, James job offers), Notes (the to-do list), Factions (directory), **The Ticker** (D4.5) — the barometer as a news app — and Profile (below).
- **Bag** — retired as a nav tab; full inventory management (ore, consumables, equipment equip/unequip, devices start/build/equip) lives in the global bag drawer (D4.4), reachable from any screen.
- **Profile** (a Phone app) — HP, skills & XP, equipment summary. You is retired as a nav tab; this is its redesignated landing spot, including its future content — reputation (M2), affinities (M3), Fieldcraft (M2).

**Interface doctrine (enforce in every later milestone):** Phone is the OS shell — Map and HQ are apps pinned to its dock, not peer places beside it — but that topology framing doesn't change what content lives where: things that happen at *addresses* go on the Map (veins, sites, travel, property pin, meetings, the Soho market); things that happen through *people* go on the Phone (texts, job offers, relations, influence actions); things that happen at *your bench* go in HQ (craft, train, store, fortify). Events with a location are initiated by tapping their map pin (M1.5) or, in M1's plain-list Map, from the district panel; events initiated by a person arrive as a Phone notification first.

**Naming guardrail:** never call this screen/feature "the tube map," "the Underground," or "London Underground" in player-facing text — in-fiction it is always **"the Network"** (full legal rationale for the eventual diagram in `docs/M1.5-NETWORK-MAP.md` D4.1).

### Map tab (M1 — plain list, superseded by the real diagram in M1.5)
- A scrollable list of the 9 districts: name, one-line blurb, derived indicators ("Prices +15%", "Rough"), an ownership summary ("2 of 3 sites yours").
- Tap a district row → **district panel**: blurb, derived indicators, Prospect and Travel buttons, list of its sites (each row: tier, ore, claim state).
- Tap a site/vein row → **site/vein sheet** (bottom sheet): tier, ore, bonuses, level, dev bar, charge state, security; actions Cultivate / Harvest (cautious·full) / Seed / Upgrade security — labels show the action's block cost per D3, flat regardless of district ("Harvest — 1 block").
- This is the exact interaction contract M1.5 renders against — it swaps only the Map tab's top-level presentation (list → diagram); district panel and site/vein sheet are unchanged.

### D4.4 Global bag drawer + inline counts (anti-friction rules)
- The top-bar bag button opens a **bottom-sheet drawer from ANY screen — including mid-event and mid-combat**. Contents: ore counts (all 5, with symbols), consumable counts, equipped weapon/device, device charges remaining. Full management outside combat/events: equip/unequip weapon and device, device start/build-attempt/abandon, on top of the read-only contents above. Read-only plus Use buttons inside them: in combat it shows the legal Use buttons (same logic as the combat item modal — this drawer replaces that modal); in an event card with itemHooks it shows the legal Use buttons for that hook. Opening the drawer never costs a turn, a block, or advances anything.
- **Inline-count rule (global, all screens, all milestones):** any button or choice whose action consumes or requires an item/ore/cash shows the requirement AND the player's holding inline — "Use Time Pearl (3)", "Seed — 40 physics (have 52)", "Bribe — £50 (have £210)". Insufficient → button disabled with the same label. A player should never need the drawer to make a decision; the drawer is for browsing.
- Implementation: one `BagDrawer` component + one shared `format_cost_label(cost, holdings)` helper used by every action button. Test: helper unit-tested; a lint-style checklist item in every UI task review: "all cost buttons use format_cost_label".

### D4.5 The Ticker (barometer as a news app, replaces the barometer screen)
- A Phone app: three headline cards, one per axis (economic/social/political), each showing the active state's label restyled as a headline + one-line description, with a small trend hint if any non-active state is ≥ 70 progress ("rumblings…").
- Tap a card → axis detail: all states with progress bars, the manual push/pull buttons (M0 logic unchanged: £2000, cooldowns), and the M4 influence actions listed greyed with full costs (fate/emotion ore requirements visible — foreshadowing is free).
- Headline strings: 2–3 variants per state, DRAFT per tone bible ("administrated menace" register: dry, plausible, London), PROSE-REVIEW. State changes push a phone notification styled as a breaking-news line.
- The World and barometer screens from M0 are deleted once this lands; save-slot UI moves to the Save/Load app.

## D5 — District event deck

~15 small events, data-driven on the M0 framework, extended with a `choices` card type:
`{ type:"choice", text, choices:[{label, effects:[...], result_text}] }` (runner shows buttons; picking applies effects, shows result_text as a resolution card, continues).
Trigger: on completing a travel OR prospect action, `chance(0.25)` → draw from the deck filtered by `{district (or "any"), excludeIfFlag, barometer state}` weights, no repeat within 5 days (track `state.world.recentEvents` as [{id, day}]).

**Deck filter semantics:** `district` restricts which district's actions can draw the entry. `excludeIfFlag: <flagName>` (new) removes an entry from the pool once that flag is true — used ONLY by `conclave_watch` below, so its one-time lore beat doesn't repeat. `barometer state` gating exists as plumbing reserved for a future batch of events tied to specific barometer states — none of these 15 use it; that's intentional, not an oversight. `requireUnclaimedSiteInDistrict` (optional, default false) removes an entry from the pool unless the current district has at least one unclaimed site — used ONLY by `rival_prospector` below, per its "any district with unclaimed sites" wording.

Author these 15 (ids fixed; prose DRAFTED per tone bible, PROSE-REVIEW all):
1. `busker_greenwich` — Greenwich, flavour + offer: give £20 → +1 time ore tip-off (next Greenwich prospect +10 rich weight, one-shot flag; the event itself is repeatable).
2. `city_suit` — City, a fate-ore insider trade offer: pay £200, `chance(0.5)` → fate ore ×8 or nothing.
3. `camden_shakedown` — Camden, pay £50 or `chance(0.4)` mugging combat.
4. `heath_dogwalker` — Hampstead, free +2 life ore, pure flavour.
5. `whitechapel_grief` — Whitechapel, atmosphere; +1 emotion ore; a line that lands the district's character.
6. `kx_delay` — King's Cross, lose the rest of this block's action (travel disruption) OR pay £30 cab.
7. `soho_tout` — Soho, teaser for the M4 marketplace; no mechanics, one card.
8. `battersea_hum` — Battersea, flavour; +1 physics ore.
9. `shoreditch_archie` — anywhere, Archie cameo; archie relation +2.
10. `conclave_watch` — City, unsettling observation beat; sets flag `conclaveNoticed` (lore hook, no mechanics); `excludeIfFlag: conclaveNoticed` — this is a one-time beat, must not redraw once seen.
11. `pigeon_omen` — any, fate flavour; next sale `chance(0.5)` +10% (one-shot flag `luckyOmen`; event itself is repeatable).
12. `rain` — any, pure one-card atmosphere.
13. `rival_prospector` — any district with unclaimed sites: that district's best unclaimed site NPC-claims unless you pay £100.
14. `foxes` — any, night flavour, one card.
15. `roman_brick` — any, prospecting oddity; lore seed for the Deep Vein ("Roman brick where no Roman brick should be"); sets counter flag `oddities += 1` (repeatable by design).

## D6 — Cultivating tutorial event

New event `archie_cultivation` slots into the tutorial right after the home-raid debrief (trigger: first visit to the Map tab after `archiePartnerSeen`). Archie walks the player through cultivating his transferred Whitechapel time vein: 6–9 cards teaching cultivate → dev bar → level → cautious vs full harvest, ending with effects: force one free successful cultivate on that vein (+barGain devBar, no block cost — special effect op `tutorial_cultivate`), archie relation +2, flag `cultivationTutorialSeen`. Prose: DRAFT, PROSE-REVIEW; Archie voice per tone bible.

## D7 — Tutorial migration cleanup + M0 tutorial gating (light)

- Home-raid vein grant now references the Whitechapel district properly and creates a matching claimed site (tier fair, no bonuses) so the map is consistent.
- Gate M1 features for new games: Map locked (nav tab greyed, "Stick close for now — Archie") until `archiePartnerSeen`; prospecting locked until `cultivationTutorialSeen`. Debug start unlocks everything and seeds 2 discovered sites (one rich in greenwich, one saturated in whitechapel, unclaimed).

---

## Task order

T1 districts data + travel rule (+tests: 2-block costing, wake-at-home, price/danger mods) → T2 sites + prospecting + seeding revamp (+seeded tests: weight table math incl. floors/caps, bonus rolls, natural vein at 5%, NPC-claim curve, NPC-abandonment curve, hospitability effects on recharge/cap/yield — yield tested against the post-roll-scaling formula) → T3 nav restructure (5 tabs + top bar), Map tab as plain district list, district panels, site/vein sheets, HQ merge, Phone reskin, BagDrawer + format_cost_label, The Ticker (human visual QA list per tab) → T4 daily-tick integration (NPC claims, NPC abandonment, King's Cross recharge) → T5 choice cards + district deck engine (+tests: filter/weights/no-repeat window, excludeIfFlag) → T6 the 15 events (PROSE-REVIEW) → T7 cultivating tutorial + gating → T8 playthrough test extension (prospect→seed→cultivate→harvest→sell across ≥3 districts, seeded, 20-seed soak).

(The Network Map renderer's task order — layout data, MapCanvas rendering, filters, pins, assets — lives in `docs/M1.5-NETWORK-MAP.md`, and depends on this milestone being complete.)

## M1 exit criteria

1. New player path: prospect → seed → cultivate → harvest → sell entirely via the Map tab (district list → district panel → site/vein sheet), tutorial-gated.
2. ~~Travel visibly costs blocks and the 2-block labels are correct everywhere.~~ Superseded by faction-resource-economy ticket 05: `Travel.blocks_needed()` returns 0 and travel itself is free — acting in a district you aren't in costs exactly the same as acting in the one you are. See D3.
3. Site quality is always visible pre-seed; at least one playtest session where the human reports a routing trade-off decision unprompted.
4. NPC-claim and NPC-abandonment curves behave correctly under soak: no district ever permanently locks out prospecting, and an abandoned site's slot reliably rerolls fresh on the district's next prospect.
5. Soak test green; all prose flagged PROSE-REVIEW has been reviewed.

(Network-rendering exit criteria — diagram correctness from any save state, all five filter modes on device — now live in `docs/M1.5-NETWORK-MAP.md`.)

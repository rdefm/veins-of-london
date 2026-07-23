# M1 — London Exists

**Goal:** the full economy loop played across a living map: 9 districts, one travel rule, prospecting → sites → hospitability, NPC site-claiming, a district event deck, and a cultivating tutorial event. No ore-roster migration needed (M0 started on the final roster).

Same rules of engagement as M0. New data is canonical HERE (this doc extends REFERENCE.md; on conflict for M1 features, this doc wins).

---

## D1 — Districts (data)

`data/districts.json`. `oreBias` weights prospected site ore type (see D2). `siteQualityMod` shifts tier weights. `dangerMod` adds to mugging/raid chances for actions in that district. `priceMod` multiplies sale prices when selling there (Archie lane uses the district you sell from). `siteCap` = max concurrent unclaimed+claimed sites.

| id | name | oreBias | siteQualityMod | dangerMod | priceMod | siteCap | special | factionPresence |
|---|---|---|---|---|---|---|---|---|
| shoreditch | Shoreditch | {} (uniform) | 0.00 | 0.00 | 0.00 | 3 | home base | collective |
| city | The City | {fate:0.6} | −0.05 | −0.05 | +0.15 | 2 | — | conclave |
| greenwich | Greenwich | {time:0.6} | +0.05 | 0.00 | 0.00 | 3 | — | guild |
| camden | Camden | {physics:0.6} | +0.05 | +0.10 | −0.05 | 4 | — | firm |
| kingscross | King's Cross | {time:0.3, physics:0.3} | 0.00 | +0.05 | 0.00 | 3 | veins here: rechargeBlocks −1 (min 1) | network |
| battersea | Battersea | {physics:0.6} | +0.05 | 0.00 | 0.00 | 3 | — | firm |
| hampstead | Hampstead | {life:0.6} | +0.10 | −0.05 | +0.05 | 2 | — | — |
| whitechapel | Whitechapel | {emotion:0.6} | +0.10 | +0.10 | 0.00 | 3 | vein NPC-raid chance ×1.5 (when vein raids land, M2) | collective |
| soho | Soho | — | — | −0.05 | +0.10 | 0 | marketplace (M4); no veins, no prospecting | network |

oreBias semantics: listed weights are the probability of that type; remainder split uniformly among the other types (uniform = 0.2 each).

Flavour: each district gets a one-line `blurb` — DRAFT per CONTENT-GUIDE.md, flag PROSE-REVIEW. District character notes from the vision doc may be paraphrased.

## D2 — Sites & prospecting

Site dict (lives in `state.world.sites` array):
`{ id, district, tier, oreType, bonuses:[String], discoveredDay, claimed:false, npcClaimed:false, hasNaturalVein:false }`

**Prospect action** (Veins screen and Map screen; costs 1 block + travel rule): only in the current district; blocked if district siteCap reached (instead: re-roll — delete the district's worst unclaimed site and roll a new one; "worst" = lowest tier index, oldest breaks ties).

Tier roll — base weights, then modifiers, then normalise:

| tier | base weight |
|---|---|
| barren | 20 |
| poor | 30 |
| fair | 32 |
| rich | 14 |
| saturated | 4 |

Modifiers: `q = round(siteQualityMod × 100)` → rich += q, poor −= q (floor 0). Cultivating skill: rich += 2×(skill−1), saturated += 1×(skill−1), barren −= 3×(skill−1) (floor 5).

oreType: roll per district oreBias. Bonuses at discovery: rich → ONE of `["recharge","maxLevel","yield"]` uniformly; saturated → all three, plus `chance(0.05)` → `hasNaturalVein = true` (claiming instantly grants a free Lv1 vein of the site's oreType, charged:false, devBar 0). Everything about a site (tier, ore, bonuses) is visible before seeding — prospecting is buying information.

Prospecting awards cultivating XP: 10 (barren/poor), 15 (fair), 25 (rich), 40 (saturated).

**Seeding revamp:** `attemptSeed(siteId)` replaces free-floating seeding. Requires: current district == site district, site unclaimed, tier != barren, 40 ore of the SITE's oreType. Success chance = `cultChance + tierMod` where tierMod: poor −0.15, fair 0, rich +0.20, saturated +0.35 (clamp 0.05–0.95). On success: site.claimed = true; vein created with `district`, `siteId`, `hospitability = {tier, bonuses}`, location generated with district-appropriate street names (extend the generator: per-district street array, 4–6 real street names each — draft, PROSE-REVIEW not needed for street names). On failure: ore lost, site remains (may be NPC-claimed later).

**Hospitability application (read by existing systems):**
- `"recharge"`: vein's effective rechargeBlocks −1 (min 1); stacks with King's Cross special.
- `"maxLevel"`: level cap 6 for this vein (VEIN_LEVELS["6"] already shipped in M0 data).
- `"yield"`: both harvest yields ×1.15, rounded (min +1 over base roll if rounding annuls it).

**NPC site-claiming (daily tick, new step ⑤b):** each unclaimed site: `p = 0.03 + 0.02 × tierIndex + 0.01 × ageDays` (tierIndex: poor 0, fair 1, rich 2, saturated 3; barren never claimed), cap 0.25. Claimed → `npcClaimed = true`, notification "Someone's moved onto the <tier> site in <district>." NPC-claimed sites remain visible; taking one back is M2 combat content — for M1 they are simply lost (greyed on map).

## D3 — Travel (the one rule)

`state.world.currentDistrict`. Every district-located action (prospect, seed, cultivate, harvest, sell) targeting a district ≠ current: first consume 1 time block as travel (sets currentDistrict), THEN the action costs its normal block — both gated on time remaining (need 2 blocks; show the cost in the button label: "Harvest (2 blocks — travel)"). Waking up (daily tick / rest) resets currentDistrict to "shoreditch" (home). Selling uses the district you are in at sale time (priceMod + dangerMod on the mug roll: `getEffectiveMugChance(0.20 + dangerMod)`).

## D4 — The Network Map (transit-diagram map screen)

The map is a **Beck-style transit diagram drawn entirely by the engine** over a paper texture. In-fiction it is the trade's internal network reference — the ancient, administrated. It is the game's primary world interface and the centre nav tab.

**Nav restructure (supersedes the M0 screen set):** **Map · HQ · Phone · Bag · You**, plus a persistent top bar on every screen: cash · day/time-blocks · bag button (D4.7). The M0 screens are redistributed, not rebuilt:
- **Map** — the Network diagram (this section). World/veins/factions screens are deleted; faction panels open from zone taps and from the Phone directory.
- **HQ** — the property AS the interface: workbench (= the crafting screen; visually upgrades when workshop/library/lab rooms are built), gym placeholder (training arrives M2), rooms, security, stored ore, tier upgrade, assigned contacts. Merges the old property + crafting screens.
- **Phone** — a phone UI: contact list, SMS threads (existing sms screens reskinned as threads), James job offers, the to-do list as a notes app, a faction directory, and **The Ticker** (D4.8) — the barometer as a news app.
- **Bag** — full inventory management: ore, consumables, equipment (equip/unequip), devices (start/build/equip).
- **You** — HP, skills & XP, equipment summary, save/load/export/settings (reputation M2, affinities M3, Fieldcraft M2 land here).

**Interface doctrine (enforce in every later milestone):** things that happen at *addresses* go on the Map (veins, sites, travel, property pin, meetings, the Soho market); things that happen through *people* go on the Phone (texts, job offers, relations, influence actions); things that happen at *your bench* go in HQ (craft, train, store, fortify). Events with a location are initiated by tapping their map pin; events initiated by a person arrive as a Phone notification first, and gain a pin if they require attending an address.

### D4.1 Legal + visual guardrails
Beck-style octilinear diagrams are a generic design language — but NEVER: TfL roundels, the actual tube map's layout, real line names, or real line-name/colour pairings, and never "the Underground"/"London Underground" as the name of the map, the network, or any feature (registered TfL marks). Lowercase descriptive use in dialogue is fine ("the underground trade"). Do not describe it as "the tube map" in any player-facing string; in-game it is **"the Network"**.

### D4.2 Semantic channels (fixed grammar — do not vary)
- **LINES = ownership.** An owner's stops in adjacent districts are joined into that owner's line. Colours: player = amber #c8873a; each faction = its `colour` from factions.json; NPC-claimed (unaffiliated) stops = short grey #8a8a8a stubs, unconnected. Unclaimed discovered sites are ticks with no line.
- **STOPS = veins and sites.** Glyph grammar (logical px):
  - Your vein / faction vein: circle r7, stroke 2.5 in owner colour, paper fill; the ore SYMBOL (⧖ ↯ ✦ ⚄ ❋) centred, drawn in the ore's type colour. Symbol carries type (colour-blind safe).
  - Unclaimed site: perpendicular tick (12×3) on a hairline in `--muted`, ore symbol beside it. Rich/Saturated sites: double tick (interchange styling).
  - NPC-claimed site: filled grey dot r5, no symbol ("someone else's problem now").
  - Charged vein: soft amber halo behind the stop, tween pulse (scale 1.0→1.3, alpha 0.5→0, 1.2 s loop).
  - Vein level: small numeral 1–6 in a badge at the stop's 4 o'clock.
  - Security: padlock micro-icon at 8 o'clock, tinted by tier (none = absent, basic `--muted`, warded #7b68ee, guarded `--success`).
- **ZONE FILLS = faction presence.** District `zonePolygon` filled at 8% alpha in the presence faction's colour (static in M1; relation-reactive in M5).
- **PINS = points of interest.** Home/property icon at the home district (tap → Property screen); contact pin when an event awaits at an address (tap → start that event); Soho market pin, padlocked until M4; player-position marker ("You are here" ring) on `currentDistrict`.

### D4.3 Rendering & layout data
- `data/map_layout.json`: `{ mapSize:[1170,1560], districts:{ id:{ anchor:[x,y], labelAnchor:[x,y], zonePolygon:[[x,y],…], stopSlots:[[x,y],…] } }, riverPath:[[x,y],…], homeAnchor:[x,y] }`. Coordinates in logical map px (map canvas is 3× the 390 column, inside a pan-capable `Camera2D`/ScrollContainer; pinch-zoom is a stretch goal, pan is required). Hand-place plausible-London coordinates; geographic exactness irrelevant. Each district has ≥ `siteCap + 2` stopSlots; stops occupy slots in discovery order.
- **Octilinear line routing (deterministic):** for each owner, order their stops nearest-neighbour starting from `homeAnchor` (player) or the faction's first-presence district anchor. Connect consecutive stops with a two-segment elbow: diagonal 45° for `min(|dx|,|dy|)`, then axis-aligned for the remainder (pick the elbow orientation that avoids crossing the river path where trivially possible; otherwise ignore crossings — the real thing crosses lines constantly). `Line2D`: width 6, round caps/joints, corner radius via joint mode. A single-stop owner draws a 24 px terminus stub through the stop at 45°.
- **River:** `riverPath` drawn once, width 14, colour #d4cfc4 at 60% alpha, beneath everything but the paper.
- Draw order: paper → zones → river → lines → stops → badges/halos → pins → labels. District labels in the UI sans, `--slate`, small caps.
- All drawing in one `MapCanvas` Control using `_draw()` + a handful of child nodes for pulsing halos and pins; rebuilt from state on `state_changed`. No per-stop scenes; keep it immediate-mode and dumb.

### D4.4 Filters (view modes)
A chip row above the map: **Ownership · Type · Strength · Charge · Security**. One active at a time; default Ownership. Modes re-style ONLY (never hide stops, never change tap behaviour):
- Ownership: the default grammar above (lines coloured by owner).
- Type: all lines/stubs desaturate to `--muted`; stop rings recolour by ore type; symbols stay.
- Strength: stop ring thickness 1.5 + level×0.8; ring greyscale ramp from `--muted` (L1) to `--ink` (L6); level badges enlarge.
- Charge: charged stops full colour + halo; everything uncharged drops to 35% alpha; per-stop countdown badge "2⏳" = blocks until charged.
- Security: padlock badges enlarge; unsecured YOUR veins get a `--danger` dotted ring (the "you should fix this" view).
Filter is UI-local state (not saved, not in GameState).

### D4.5 Interaction
- Tap stop/tick → **site/vein sheet** (bottom sheet): tier, ore, bonuses, level, dev bar, charge state, security; actions Cultivate / Harvest (cautious·full) / Seed / Upgrade security — labels show true block cost per D3 ("Harvest — 2 blocks (travel)").
- Tap district label or zone → **district panel**: blurb, derived indicators ("Prices +15%", "Rough"), Prospect and Travel buttons, list of its stops.
- Tap pin → its screen/event. Legend button (?) → modal titled "Network Reference", listing the glyph grammar with one dry line of flavour (DRAFT, PROSE-REVIEW).

### D4.6 Asset list (total, final)
1. **Paper texture** — 1536×2048 PNG, aged cream (#f0ece2 family), subtle foxing/grain, NO linework, NO text. AI-generatable; also acceptable: procedural noise over flat colour as placeholder.
2. **Icon glyphs ×8** — home, pin, padlock, market, phone, bag, legend "?", news: 64 px, single-colour (tint in engine). Draw as simple `_draw()` polygons if no pack is available.
3. Fonts already bundled (M0). Ore symbols are text glyphs — verify the bundled font covers ⧖ ↯ ✦ ⚄ ❋ on Android; if not, render them as tiny SVG-derived textures (add to icon set).
Nothing else. There is no commissioned illustration in this design.

### D4.7 Global bag drawer + inline counts (anti-friction rules)
- The top-bar bag button opens a **bottom-sheet drawer from ANY screen — including mid-event and mid-combat**. Contents: ore counts (all 5, with symbols), consumable counts, equipped weapon/device, device charges remaining. Read-only everywhere, EXCEPT: in combat it shows the legal Use buttons (same logic as the combat item modal — this drawer replaces that modal); in an event card with itemHooks it shows the legal Use buttons for that hook. Opening the drawer never costs a turn, a block, or advances anything.
- **Inline-count rule (global, all screens, all milestones):** any button or choice whose action consumes or requires an item/ore/cash shows the requirement AND the player's holding inline — "Use Time Pearl (3)", "Seed — 40 physics (have 52)", "Bribe — £50 (have £210)". Insufficient → button disabled with the same label. A player should never need the drawer to make a decision; the drawer is for browsing.
- Implementation: one `BagDrawer` component + one shared `format_cost_label(cost, holdings)` helper used by every action button. Test: helper unit-tested; a lint-style checklist item in every UI task review: "all cost buttons use format_cost_label".

### D4.8 The Ticker (barometer as a news app, replaces the barometer screen)
- A Phone app: three headline cards, one per axis (economic/social/political), each showing the active state's label restyled as a headline + one-line description, with a small trend hint if any non-active state is ≥ 70 progress ("rumblings…").
- Tap a card → axis detail: all states with progress bars, the manual push/pull buttons (M0 logic unchanged: £2000, cooldowns), and the M4 influence actions listed greyed with full costs (fate/emotion ore requirements visible — foreshadowing is free).
- Headline strings: 2–3 variants per state, DRAFT per tone bible ("administrated menace" register: dry, plausible, London), PROSE-REVIEW. State changes push a phone notification styled as a breaking-news line.
- The World and barometer screens from M0 are deleted once this lands; save-slot UI moves to You.

## D5 — District event deck

~15 small events, data-driven on the M0 framework, extended with a `choices` card type:
`{ type:"choice", text, choices:[{label, effects:[...], result_text}] }` (runner shows buttons; picking applies effects, shows result_text as a resolution card, continues).
Trigger: on completing a travel OR prospect action, `chance(0.25)` → draw from the deck filtered by `{district (or "any"), min flags, barometer state}` weights, no repeat within 5 days (track `state.world.recentEvents` as [{id, day}]).

Author these 15 (ids fixed; prose DRAFTED per tone bible, PROSE-REVIEW all):
1. `busker_greenwich` — Greenwich, flavour + offer: give £20 → +1 time ore tip-off (next Greenwich prospect +10 rich weight, one-shot flag).
2. `city_suit` — City, a fate-ore insider trade offer: pay £200, `chance(0.5)` → fate ore ×8 or nothing.
3. `camden_shakedown` — Camden, pay £50 or `chance(0.4)` mugging combat.
4. `heath_dogwalker` — Hampstead, free +2 life ore, pure flavour.
5. `whitechapel_grief` — Whitechapel, atmosphere; +1 emotion ore; a line that lands the district's character.
6. `kx_delay` — King's Cross, lose the rest of this block's action (travel disruption) OR pay £30 cab.
7. `soho_tout` — Soho, teaser for the M4 marketplace; no mechanics, one card.
8. `battersea_hum` — Battersea, flavour; +1 physics ore.
9. `shoreditch_archie` — anywhere, Archie cameo; archie relation +2.
10. `conclave_watch` — City, unsettling observation beat; sets flag `conclaveNoticed` (lore hook, no mechanics).
11. `pigeon_omen` — any, fate flavour; next sale `chance(0.5)` +10% (one-shot flag `luckyOmen`).
12. `rain` — any, pure one-card atmosphere.
13. `rival_prospector` — any district with unclaimed sites: that district's best unclaimed site NPC-claims unless you pay £100.
14. `foxes` — any, night flavour, one card.
15. `roman_brick` — any, prospecting oddity; lore seed for the Deep Vein ("Roman brick where no Roman brick should be"); sets counter flag `oddities += 1`.

## D6 — Cultivating tutorial event

New event `archie_cultivation` slots into the tutorial right after the home-raid debrief (trigger: first visit to the Map screen after `archiePartnerSeen`). Archie walks the player through cultivating his transferred Whitechapel time vein: 6–9 cards teaching cultivate → dev bar → level → cautious vs full harvest, ending with effects: force one free successful cultivate on that vein (+barGain devBar, no block cost — special effect op `tutorial_cultivate`), archie relation +2, flag `cultivationTutorialSeen`. Prose: DRAFT, PROSE-REVIEW; Archie voice per tone bible.

## D7 — Tutorial migration cleanup + M0 tutorial gating (light)

- Home-raid vein grant now references the Whitechapel district properly and creates a matching claimed site (tier fair, no bonuses) so the map is consistent.
- Gate M1 features for new games: Map locked (nav tab greyed, "Stick close for now — Archie") until `archiePartnerSeen`; prospecting locked until `cultivationTutorialSeen`. Debug start unlocks everything and seeds 2 discovered sites (one rich in greenwich, one saturated in whitechapel, unclaimed).

---

## Task order
T1 districts data + travel rule (+tests: 2-block costing, wake-at-home, price/danger mods) → T2 sites + prospecting + seeding revamp (+seeded tests: weight table math incl. floors/caps, bonus rolls, natural vein at 5%, NPC-claim curve, hospitability effects on recharge/cap/yield) → T3a map layout data + MapCanvas rendering (lines/stops/zones/river; +tests: octilinear elbow geometry pure functions, nearest-neighbour ordering determinism, stop-slot assignment) → T3b nav restructure (5 tabs + top bar), filters, site/vein sheets, district panels, pins, HQ merge, Phone reskin, BagDrawer + format_cost_label, The Ticker (human visual QA list per tab and per filter mode) → T4 daily-tick integration (NPC claims, King's Cross recharge) → T5 choice cards + district deck engine (+tests: filter/weights/no-repeat window) → T6 the 15 events (PROSE-REVIEW) → T7 cultivating tutorial + gating → T8 playthrough test extension (prospect→seed→cultivate→harvest→sell across ≥3 districts, seeded, 20-seed soak).

## M1 exit criteria
1. New player path: prospect → seed → cultivate → harvest → sell entirely via the map, tutorial-gated.
2. Travel visibly costs blocks and the 2-block labels are correct everywhere.
3. Site quality is always visible pre-seed; at least one playtest session where the human reports a routing trade-off decision unprompted.
4. The Network map renders correctly from any save state (including debug start) — every ownership change, discovery, seed, charge and security change appears without restart; a newly seeded vein visibly joins the player's line.
5. All five filter modes correct on device; ore symbols legible at 1× on a real phone.
6. Soak test green; all prose flagged PROSE-REVIEW has been reviewed.

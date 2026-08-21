# PRD — Vein Growth State

**Status:** Draft, from a design session (2026-08-21). Approved in conversation by the human; open items are listed in §12 and must be confirmed before the tickets that depend on them are worked.

**Scope of authority:** this document is canonical for the mechanics it defines. Where it conflicts with `docs/REFERENCE.md` or `docs/M1-LONDON.md`, **this document wins** and those documents must be updated in the same ticket that lands the conflicting code (per the project constitution: code and docs must not diverge).

---

## 1. Why

A vein today has two independent scalars and a boolean:

- `devBar` + `level` — permanent scale. `cultivate` raises `devBar`; crossing `devBarMax` levels the vein up. `harvest_full` costs `devBar`; hitting 0 levels it down, and at Lv1 the vein collapses.
- `charged` + `chargeBlocks` — readiness. `+1` per daily tick until `chargeBlocks >= rechargeBlocks(level)`, at which point `charged` flips true. Harvesting resets both.

`charged` is a timer, not a decision — the player waits, then takes the free thing. `devBar` is a one-way ratchet the player pushes up and only rarely spends down. Neither creates a choice at the moment of interaction.

This PRD replaces all four fields with **one signed axis**: how wild or how barren the vein currently is. The player prunes it left (taking ore) or cultivates it right (spending a block). Left alone, it drifts away from neutral in whichever direction it was last left, accelerating as it goes.

The result is a single recurring decision — *how far past neutral am I willing to cut this?* — which is simultaneously the yield question, the risk question, and the "when do I next have to care about this vein" question.

**Design principles this must preserve.** These are the acceptance bar for balance, not decoration:

1. **Neglect is affordable.** A vein left alone must take roughly a month of in-game days to reach either wall. Veins must never become a daily chore. A player who ignores their whole portfolio for two weeks should find it changed, not destroyed.
2. **Both extremes are meaningful, in opposite ways.** Wild is *productive and exposed*. Barren is *worthless and dying*. Neither is a dead end the player stumbles into without warning.
3. **Terroir carries the progression.** With levels gone, a vein never permanently improves. All long-term growth moves to *which sites you hold* — see §7, which is a hard requirement of this design, not a nice-to-have.

---

## 2. The model

### 2.1 State

`growth: int`, ranging `0 .. ceiling` (default ceiling 100). Neutral is **50**.

**Removed from the vein dict, entirely, with no replacement field:** `devBar`, `charged`, `chargeBlocks`, `level`, `levelLabel`.

New vein dict (`Cultivating.make_vein()`):

```
{ id, oreType, growth:int, security:"none", alarmUpgrades:[],
  location:String, claimedOnDay:int, district:String, siteId,
  hospitability: {tier:String, bonuses:[String]},
  rampantDays:int }
```

`rampantDays` counts consecutive daily ticks spent at the ceiling; it drives self-seeding (§2.6). It is 0 for any vein not at the ceiling.

Faction veins (`site.factionVein`) carry the same fields plus `factionId`, as today.

Everything remains pure data — ints, strings, arrays of strings, nested dicts of the same. No change to the state-purity contract.

### 2.2 Bands

Bands exist so that risk, prose, UI and drift can all key off one shared vocabulary rather than scattered magic numbers. Symmetric around neutral.

| band id | growth range | label | drift/day |
|---|---|---|---|
| `collapsed` | 0 | — (vein is removed) | — |
| `barren` | 1–14 | Barren | 3 (leftward) |
| `sparse` | 15–29 | Sparse | 2 (leftward) |
| `thinning` | 30–44 | Thinning | 1 (leftward) |
| `dormant` | 45–55 | Dormant | 0 |
| `taking` | 56–70 | Taking | 1 (rightward) |
| `lush` | 71–85 | Lush | 2 (rightward) |
| `wild` | 86–99 | Wild | 3 (rightward) |
| `rampant` | 100 (ceiling) | Rampant | 0 (clamped; see §2.6) |

Band labels are player-facing prose and are **PROSE-REVIEW** material — draft, to be signed off.

The `dormant` band is a deliberate affordance: a vein pruned back to neutral does not drift at all. It yields nothing, but it is safe and can be left indefinitely. That is the player's answer to "I have more veins than blocks" and is what stops this system becoming a treadmill. Do not remove it as a "simplification."

### 2.3 Drift (daily tick)

Replaces `Cultivating.recharge_veins()` at `daily_tick` step ④ — same position in the order, same one-pass-over-all-veins shape.

For each player vein and each faction vein:

```
delta = band_drift(growth)                   # 0..3, from the table above
direction = +1 if growth > 50, -1 if growth < 50, 0 if dormant
growth = clamp(growth + delta * direction, 0, ceiling(vein))
```

Then handle the walls (§2.5, §2.6).

**Pacing check** (this is the number the design lives or dies on): from `growth = 56`, untouched, to the ceiling is 14 + 7 + 5 ≈ **26 days**. From `growth = 44` to collapse is likewise ≈ **26 days**. Both satisfy principle 1. Any retuning of the band table must be re-checked against this figure and against §11.

### 2.4 Actions

All three cost **1 block** and route through `Travel.ensure_district(district)` exactly as today (travel itself is free — see §9).

**Cultivate** — pushes right. Unchanged success roll: `cultChance = min(0.90, 0.30 + (skill − 1) × 0.12)`. On success `growth += cultivate_gain`, award 20 XP; on failure no change, award 8 XP. Result modal either way, as today.

```
cultivate_gain(skill, growth, ceiling) = max(2, round((4 + 2 * skill) * (1 - growth / ceiling)))
```

Diminishing toward the right on purpose: cultivating is at its most efficient as **rescue** on the barren side and at its least efficient as a shortcut to the ceiling. This is what stops a high-skill player block-spamming a vein straight to Rampant.

**Prune (light)** — `growth -= 15`. **Prune (hard)** — `growth -= 40`. Both clamp at 0. Together they replace `harvest_cautious` and `harvest_full`, which are deleted.

Yield counts **only the growth points removed from above neutral**:

```
points = max(0, growth_before - 50) - max(0, growth_after - 50)
yield  = round(points * YIELD_PER_POINT * terroir_yield_mult(vein) * hard_bonus)
yield  = apply_yield_bonus(vein, yield)          # the "yield" terroir bonus, unchanged formula
```

with `YIELD_PER_POINT = 0.35`, `hard_bonus = 1.25` for a hard prune and `1.0` for a light one.

Consequences, all intended:

- Pruning a vein already at or below neutral yields nothing. It is never worth a block. The UI must show the projected yield so the player never spends a block discovering this.
- A hard prune is more ore *per block* than two light prunes, but only when the vein is deep enough in the wild bands that the whole 40-point cut lands above neutral. Cutting past neutral is pure cost.
- Therefore: **prune depth is the decision.** Cut lightly and stay wild (more ore later, more risk now); cut hard and bank it (efficient, but the vein is now drifting toward death and needs cultivating back).

Pruning awards cultivating XP on the same schedule harvesting does today.

### 2.5 The left wall — collapse

`growth` reaching **0** removes the vein. There is no level ladder to step down; collapse is the only left-wall outcome.

- Remove the vein from `player.veins` (or clear `site.factionVein` for a faction vein).
- **Its site reverts to unclaimed** — `site.claimed = false`, `factionVein` stays null. The site survives and is seedable again.
- Notification, reusing the existing collapse line: *"Your <ore> vein on <street> collapsed and disappeared."*

Note this deliberately differs from **NPC abandonment** (`M1-LONDON.md` D2 ⑤c), which deletes the site outright. That asymmetry is intentional and must be preserved: an abandoned faction plot is gone; a vein you starved leaves the land behind.

### 2.6 The right wall — Rampant, and self-seeding

`growth` clamps at the vein's ceiling (`100`, or higher with the terroir bonus in §7). A vein at the ceiling does not drift and does not decay; it is stable, maximally productive, and the most attractive raid target on the board.

While at the ceiling, `rampantDays += 1` each daily tick. At `RAMPANT_SEED_DAYS = 5`:

1. Pick an **unclaimed** site in the same district, uniformly at random among unclaimed sites there.
2. If one exists: claim it for the player (`site.claimed = true`) and create a new player vein on it at `growth = 60`, ore type from the site, hospitability from the site, its own generated `location`. Reset the parent's `rampantDays = 0`. Notification (PROSE-REVIEW).
3. If none exists: nothing happens; `rampantDays` holds at the threshold and retries on each subsequent tick.

Self-seeding claims an existing site, so `siteCap` is unaffected and needs no new plumbing. It does consume unclaimed sites in the district, competing with the player's own prospecting — an intended tension, not a bug.

`rampantDays` resets to 0 the moment `growth` drops below the ceiling by any means.

**Faction veins do not self-seed.** Faction expansion is already handled by the daily NPC-claim roll; letting faction veins self-seed as well would flood the map. See §5.

---

## 3. Value tier — the single seam replacing `level`

`level` is currently used as a 1–5 magnitude in eight places outside the cultivating system: raid stealth odds, faction raid target selection, faction vein income, rivalry target weighting, raid-enemy combat scaling, defend-vein combat scaling, the map's Strength filter, and the level badge.

Rather than patch each call site with its own growth expression, add **one** helper and re-point every one of them at it:

```
Cultivating.value_tier(vein) -> int      # 1..6
    return 1 + floor(growth / 20)
```

`growth 0–19 → 1`, `20–39 → 2`, `40–59 → 3`, `60–79 → 4`, `80–99 → 5`, `100+ → 6`. Same 1-to-5-ish magnitude the old `level` had, so every existing formula keeps its shape and its tuning constants — `basePrice × level` becomes `basePrice × value_tier(vein)` and needs no re-balancing pass.

This is the design's most valuable property and the reason "wild attracts raids" costs almost nothing to implement: a wild vein is automatically the highest-value target in `Raiding.stealth_success_chance`, `Raiding._pick_target_vein`, `Factions._pick_target_vein` and the rivalry weighting, through formulas that already exist and are already tuned.

**In addition**, add an explicit growth tilt to `Raiding`'s Direction-B daily raid chance, so exposure scales continuously and not just in 20-point steps:

```
RAID_GROWTH_WEIGHT = 0.15
growth_tilt = RAID_GROWTH_WEIGHT * (growth / ceiling)
```

added to the existing `RAID_BASE_CHANCE + relation + danger + raidResist` stack. Magnitude is deliberately in line with the existing `RAID_RELATION_WEIGHT` (0.20) and `RAID_RAID_RESIST_WEIGHT` (0.20) — significant but not dominant.

---

## 4. Data files

**Delete** `data/vein_levels.json` and its `GameData` loader, validation and constant.

**Add** `data/vein_growth.json` — all numbers in §2 live here, none in code:

```json
{
  "neutral": 50,
  "ceiling": 100,
  "wildCeilingBonus": 20,
  "bands": [
    { "id": "barren",   "min": 1,   "max": 14,  "label": "Barren",   "drift": 3 },
    { "id": "sparse",   "min": 15,  "max": 29,  "label": "Sparse",   "drift": 2 },
    { "id": "thinning", "min": 30,  "max": 44,  "label": "Thinning", "drift": 1 },
    { "id": "dormant",  "min": 45,  "max": 55,  "label": "Dormant",  "drift": 0 },
    { "id": "taking",   "min": 56,  "max": 70,  "label": "Taking",   "drift": 1 },
    { "id": "lush",     "min": 71,  "max": 85,  "label": "Lush",     "drift": 2 },
    { "id": "wild",     "min": 86,  "max": 99,  "label": "Wild",     "drift": 3 },
    { "id": "rampant",  "min": 100, "max": 9999,"label": "Rampant",  "drift": 0 }
  ],
  "yieldPerPoint": 0.35,
  "hardPruneBonus": 1.25,
  "pruneLightDepth": 15,
  "pruneHardDepth": 40,
  "cultivateBase": 4,
  "cultivatePerSkill": 2,
  "cultivateMinGain": 2,
  "rampantSeedDays": 5,
  "selfSeedGrowth": 60,
  "terroirYieldMult": { "poor": 0.6, "fair": 1.0, "rich": 1.6, "saturated": 2.4 }
}
```

Band lookup must tolerate a growth value above 100 (a `wildCeiling` vein) — hence `rampant`'s open-ended max. `GameData` validation should assert the bands are contiguous, cover 1..100, and that exactly one band has `drift: 0` on each side of neutral.

**Edit** `data/sites.json` — `discoveryBonusPool` becomes `["vigour", "wildCeiling", "yield"]` (see §7).

**Edit** `data/districts.json` — King's Cross's `special` text changes from `"veins here: rechargeBlocks −1 (min 1)"` to the drift equivalent (§7).

---

## 5. Faction veins

Faction veins get `growth` and drift on the same daily pass. Two changes beyond that:

- `Sites.roll_faction_vein_growth()` currently rolls a daily cultivate attempt. Replace with: the vein drifts like any other, **and** if `growth >= 85`, `chance(0.40)` that the faction prunes it back to ~55 (no ore is granted to anyone — it is off-screen world simulation). Without this, every faction vein on the map ends up parked at the ceiling within a month.
- `Factions.DAY_ONE_ROSTER` hardcodes a starting **level** (1–5) per faction vein. Re-express each as a starting `growth` using the `value_tier` mapping in reverse — level *n* becomes `growth = 20n - 10` (so Lv1 → 10, Lv3 → 50, Lv5 → 90), preserving the intended relative strength of the day-one rosters. Keep the "fixed roll" property: these stay hardcoded constants, not fresh rolls.

Faction veins never self-seed (§2.6) and never collapse-and-revert to unclaimed through drift — a faction vein reaching 0 is deleted along with its site, matching existing NPC abandonment semantics rather than the player's collapse semantics. *(Flagged in §12 — confirm.)*

---

## 6. Vein Station delegation, and the vein list

### 6.1 Vein Station — target-based delegation

`systems/rooms.gd`'s assigned-contact behaviour ("harvest if charged, else cultivate") has no meaning under this model and is replaced by **hold-at-target**:

- State: `state.veinStationVeins` (array of ids) gains a companion `state.veinStationTargets: { veinId: int }` — a plain dict of primitives, purity-safe. Default target on assignment: 70 (`lush`).
- Daily, per assigned vein: if `growth > target + 5`, the contact prunes down toward the target — ore goes into the player's `orichalchum` using the same §2.4 yield formula; if `growth < target - 5`, the contact rolls a cultivate attempt at their own `cultivatingSkill`; otherwise nothing happens.
- Contact XP awards keep their current magnitudes (15 on a harvest, 20 on a cultivate success, 8 on a failure).
- Summary notification, as today.

This is what makes the Vein Station room genuinely load-bearing: it is the player's answer to holding more veins than they have blocks, and it lets them set an explicit risk posture per vein (park a vein at 50 and it is safe forever; park it at 95 and the contact keeps it maximally productive and maximally exposed).

### 6.2 The vein list

A list view of every player vein, with inline management.

- **Placement:** recommended under the **HQ** tab, alongside the Vein Station room — it is an operations-management view and the five nav tabs are fixed. Implementer's call if a better home is obvious in the code; document the reasoning either way.
- **Per row:** district, ore type, terroir tier, the growth bar with its band label, days-until-wall, security tier, and Vein Station assignment/target if any.
- **Sort/filter** at minimum by band, so "what needs me this week" is one tap.
- **Inline actions:** Cultivate / Prune (light) / Prune (hard) / Manage, each routing through the **same** `Cultivating` functions and therefore the same `Travel.ensure_district` call as the Map-tab sheet. The list is a convenience layer over the existing rules, never a bypass — screens do not mutate state, and there is no second code path for acting on a vein.
- Projected prune yield must be shown on the button before it is pressed.

---

## 7. Terroir amplification (hard requirement)

With levels gone, a vein never permanently improves. If terroir stays the modest modifier it is today, a day-80 vein plays identically to a day-5 vein and the mid-game goes flat. **Widening the terroir spread is therefore load-bearing, not polish.** Prospecting becomes the progression.

Three changes:

**a) Tier drives yield directly.** `terroirYieldMult` in §4: poor 0.6 / fair 1.0 / rich 1.6 / saturated 2.4. A 4× spread between the worst and best seedable land, where today the tier only nudges the seed success chance. Barren tiers remain unseedable.

**b) The three discovery bonuses are re-pointed** (they currently reference mechanics this PRD deletes):

| old key | new key | effect |
|---|---|---|
| `recharge` | `vigour` | `+1` to rightward drift, `−1` to leftward drift (min 0). Fertile land grows back fast and resists dying. Stacks with the King's Cross district special, which becomes the same effect. |
| `maxLevel` | `wildCeiling` | Raises this vein's growth ceiling from 100 to **120**. |
| `yield` | `yield` | Unchanged, including the `max(rolled + 1, round(rolled × 1.15))` formula. |

The renames are proposed because `recharge` and `maxLevel` name mechanics that will no longer exist; leaving them would be actively misleading. Flagged in §12 for confirmation before the data ticket lands.

**c) `wildCeiling` compounds with tier.** A saturated site carries all three bonuses (per `M1-LONDON.md` D2). A saturated + `wildCeiling` vein holds 70 points above neutral and yields `70 × 0.35 × 2.4 ≈ 59` ore in a single hard prune, against `~8` for the same cut on poor land. That gap is the point — it is what makes prospecting worth blocks and a saturated site worth fighting a faction over.

---

## 8. Map and UI

### 8.1 Stop glyph grammar

Current vein stop: white circle (r=10) → amber `#c8873a` ring (3px) → ore glyph centred → level badge at 4 o'clock (number + `devBar` progress arc) → security padlock at 8 o'clock.

Changes:

- **The ring becomes the growth gauge.** The existing uniform ring stays as a faint track; growth is overdrawn on it as an arc starting at **12 o'clock** — **clockwise** for `growth > 50`, **anticlockwise** for `growth < 50` — with arc length proportional to distance from neutral, reaching at most 6 o'clock at either wall. A dormant vein shows only the track. One glyph answers both "which side" and "how far."
- **Risk-band cue.** In the outer bands the stop also gets an outer ring: `wild`/`rampant` → a ragged, unevenly-spaced dashed amber ring a few px clear of the stop (shaggy, untended); `barren`/`sparse` → the growth arc itself renders thin, faded and broken by gaps. This is what makes "which veins need me" readable across the whole diagram without zooming. `_draw_dotted_ring()` already exists and is the starting point.
- **The 4 o'clock badge becomes the terroir mark** — the site's tier, since the level number it used to hold no longer exists. The stop then reads *terroir (permanent) · growth (the arc) · security (the padlock)*: three facts, three slots, no overlap.
- `Cultivating.dev_fraction()` is deleted along with the arc it fed.

### 8.2 Filters

`MapStyle.FILTER_MODES` currently lists `ownership · type · strength · charge · security · faction`. **`strength` and `charge` merge into one `growth` chip** — under this model they are the same quantity. The merged chip:

- fades everything outside the risk bands (reuse `CHARGE_FADE_ALPHA`),
- ramps ring colour/width by `value_tier` (the old Strength behaviour, re-keyed),
- replaces `countdown_label()`'s `2⏳` with **days-to-wall** — `6↑` for a vein drifting wild, `4↓` for one drifting barren.

### 8.3 Animations

`MapEvents.queue_charge` / `queue_drain` and their `map_canvas.gd` counterparts are re-triggered rather than rewritten:

- **burst** (was: charge complete) fires when a vein crosses **into** the `wild` band or reaches the ceiling.
- **drain** (was: harvested) fires when a vein crosses **below neutral** in either direction of travel.

Both must fire on the transition only, never on every tick a vein sits in a band — the existing `was_charged`-style guard pattern in `recharge_veins()` is the model to follow.

### 8.4 Sheets and bubbles

`scenes/screens/map.gd`'s site/vein sheet, `systems/station_bubble.gd`'s option list, and `scenes/components/ui.gd`'s action row all currently branch on `charged`. They become: growth bar + band label + days-to-wall + projected prune yield; actions Cultivate / Prune (light) / Prune (hard) / Upgrade security / Alarm. Prune buttons are shown always but disabled with the reason surfaced when the projected yield is 0 (i.e. at or below neutral) — the player should be able to see *why* an action isn't worth taking, not just find it missing.

---

## 9. Travel

**No work required — this is already done.** `faction-resource-economy` ticket 05 removed the cross-district travel surcharge: `Travel.blocks_needed()` returns 0, `ensure_district()` is free bookkeeping, and `M1-LONDON.md` D3 was updated. Acting in a district you are not in already costs exactly the same as acting in the one you are.

Two stale doc references remain and should be swept in this feature's documentation ticket:

- `docs/M1-LONDON.md` **exit criterion 2** still reads *"Travel visibly costs blocks and the 2-block labels are correct everywhere"* — false since ticket 05.
- `docs/M1-LONDON.md` **D4** line describing the site/vein sheet still lists *"level, dev bar, charge state"* — all three deleted by this PRD.

---

## 10. Change inventory

Everything a ticket-writer needs to enumerate the work. Nothing here is optional.

**Systems**

| file | change |
|---|---|
| `systems/cultivating.gd` | Core rewrite. Delete `harvest_cautious`, `harvest_full`, `recharge_veins`, `level_up_vein`, `_level_down_vein`, `dev_fraction`, `get_level_cap`, `is_at_max_level`, `get_effective_recharge_blocks`, `LEVEL_CAP`. Add `growth_band`, `band_drift`, `drift_veins`, `prune(vein_id, depth)`, `prune_yield`, `cultivate_gain`, `value_tier`, `ceiling`, `days_to_wall`, `collapse_vein`, `self_seed`. Rewrite `make_vein`, `cultivate`. Keep `generate_location_name`, `get_cult_chance`, `apply_yield_bonus`, `award_xp`, `find_vein`, `make_vein_id`, and both security/alarm sections untouched. |
| `systems/time_system.gd` | `daily_tick` step ④ calls `Cultivating.drift_veins()` instead of `recharge_veins()`. Faction-vein drift and the self-seed pass run in the same step. |
| `systems/rooms.gd` | Vein Station rewritten to hold-at-target (§6.1). |
| `systems/sites.gd` | `attempt_seed` creates a vein at a starting growth (recommend 60, so a fresh vein is already productive and drifting right — confirm in §12). `roll_faction_vein_growth` per §5. Natural-vein grant (`hasNaturalVein`) gets a starting growth. Collapse must revert the site to unclaimed (§2.5). |
| `systems/factions.gd` | `create_faction_vein` growth instead of level; `DAY_ONE_ROSTER` re-expressed (§5); income, `_pick_target_vein` and rivalry weighting re-pointed at `value_tier`. |
| `systems/raiding.gd` | `stealth_success_chance` value term → `value_tier`; Direction-B chance gains `RAID_GROWTH_WEIGHT` (§3); `Combat.start_defend_vein` scaling arg → `value_tier`. |
| `systems/events.gd` | `grant_vein` / `grant_vein_with_site` ops take `growth`; `tutorial_cultivate` op re-pointed; `start_raid` scaling arg → `value_tier`. |
| `systems/combat.gd` | `generate_raid_enemy`'s `veinLevel` parameter is now a value tier — same 1–6 range, no formula change, but rename the parameter so it doesn't lie. |
| `systems/debug_start.gd` | Debug save's three veins get growth values instead of levels/charge (recommend one per side plus one at the ceiling, so all three visual states are inspectable immediately). |
| `systems/map_style.gd` | Merge `strength`+`charge` into `growth` (§8.2); `countdown_label` → days-to-wall. |
| `systems/map_events.gd` | Re-trigger burst/drain on band transitions (§8.3). |
| `systems/station_bubble.gd` | Option list branches on projected yield, not `charged`. |

**Screens / components**

`scenes/screens/map.gd` (vein sheet), `scenes/components/map_canvas.gd` (stop glyph, badges, filter plumbing, animations), `scenes/components/ui.gd` (action row), plus the **new vein list** (§6.2) and its Vein Station target UI.

**Autoloads**

`autoload/GameData.gd` — drop `VEIN_LEVELS` and its validation, add `VEIN_GROWTH` with the validation in §4. `autoload/SaveManager.gd` — see §11.

**Data**

Per §4.

**Docs** — all must land with the code, not after:

- `docs/REFERENCE.md`: §1.2 (vein levels table → growth table), §2.1 (vein dict), §3.1 ④ (daily tick), §3.4 (cultivating & harvest → cultivating & pruning), §7 debug-start description.
- `docs/M1-LONDON.md`: D1 King's Cross special, D2 hospitability application + bonus pool + natural vein, D3 (no change needed, already correct), D4 site/vein sheet line, exit criterion 2 (§9).
- `docs/M1.5-NETWORK-MAP.md`: filter roster and glyph grammar (§8).
- `CONTEXT.md`: add **Growth**, **Band**, **Prune**, **Rampant**, **Terroir** to the Language section; update the **Vein** entry, which currently references levels. Retire "charge", "dev bar" and "vein level" as terms.

---

## 11. Saves and tests

**Saves.** Save-breaking is accepted — no migrator. Bump `SaveManager.SAVE_VERSION` from 1 to 2 and have the loader reject a v1 save with a clear message rather than half-loading it. `SaveManager`'s per-vein key sanitising lists (`["level", "devBar", "chargeBlocks", "claimedOnDay"]`, two sites) become `["growth", "rampantDays", "claimedOnDay"]`.

**Tests.** Every touched file needs `godot --headless -s scripts/check_runner.gd -- <file>` clean and `scripts/run_tests.sh` green. Rewrites needed in: `test_cultivating.gd` (largest — every case is charge/devBar-shaped), `test_rooms.gd`, `test_sites.gd`, `test_factions.gd`, `test_raiding.gd`, `test_map_style.gd`, `test_map_canvas.gd`, `test_map_screen.gd`, `test_station_bubble.gd`, `test_events.gd`, `test_time_system.gd`, `test_savemanager.gd`, `test_debug_start.gd`, `test_gamedata.gd`, `test_combat.gd`, `test_travel.gd`, `test_playthrough.gd`.

New coverage that must exist, beyond porting what is there:

1. **Drift is symmetric and sided** — a vein at 56 drifts right, at 44 drifts left, at 50 does not move.
2. **The 26-day pacing figure** — a seeded soak from 56, untouched, reaches the ceiling in 24–28 ticks; likewise 44 → collapse. This is the design's core promise and must be asserted, not assumed.
3. **Prune yields nothing at or below neutral**, and a hard prune from just above neutral yields only the above-neutral points.
4. **Collapse reverts its site to unclaimed and the site is re-seedable** — distinct from NPC abandonment's delete.
5. **Self-seeding** fires at exactly 5 rampant days, claims an unclaimed site in the same district, does not breach `siteCap`, and no-ops (without losing its counter) when no unclaimed site exists.
6. **`value_tier` boundaries** at 19/20, 99/100, and above 100 for a `wildCeiling` vein.
7. **Terroir spread** — a saturated+`wildCeiling` vein's maximum single-prune yield is at least 5× a poor vein's, asserting §7 actually landed.
8. **Vein Station hold-at-target** converges: a vein at 95 with target 70 is pruned down; one at 40 with target 70 is cultivated up; one at 70 is left alone.
9. **`test_playthrough.gd`** extended: prospect → seed → cultivate → prune across ≥3 districts, plus a neglect arm that verifies a vein left alone for 30 days has collapsed and its site is seedable again.

---

## 12. Decisions taken, and the ones still open

**Taken in session, do not relitigate:** one axis, not two; drift keyed on which side of neutral the vein sits; collapse at the left wall with the site reverting to unclaimed; growth replaces levels entirely; self-seeding at the right wall; terroir amplified to carry progression; daily drift cadence; the discovery bonuses re-pointed to drift and ceiling; save-breaking accepted; the map glyph grammar in §8.1.

**Open — confirm before the dependent ticket lands:**

1. **Bonus key renames** (`recharge` → `vigour`, `maxLevel` → `wildCeiling`). Recommended, since both keys name deleted mechanics, but renaming data keys is the human's call per the constitution.
2. **Starting growth for a newly seeded vein.** Recommend **60** — immediately productive and drifting right, so a new vein feels alive rather than inert. Alternative is 50 (dormant, fully player-driven).
3. **Faction vein collapse semantics** (§5) — delete the site outright, matching NPC abandonment, or revert to unclaimed, matching the player? Recommend delete-outright for consistency with the existing abandonment rule.
4. **Vein list placement** (§6.2) — HQ tab recommended.
5. **Band labels** (§2.2) and all new notification prose — PROSE-REVIEW, needs a tone-bible pass and human sign-off.

**Watch items for the balance pass** (not blockers, but the first things to check on device):

- **Self-seeding may be too generous.** It is free veins for doing nothing, counterweighted only by raid exposure and by consuming the district's unclaimed sites. If a player can chain-seed a district from one Rampant vein, raise `RAMPANT_SEED_DAYS` or gate it behind a roll.
- **The dormant band may be too safe.** If parking everything at 50 becomes the dominant strategy, the fix is to make holding land cost something (upkeep, faction attention), not to remove the band.
- **Cultivate may be too weak on the right.** If pushing a Lush vein to Rampant by hand is never worth a block, the ceiling is decorative for anyone not willing to wait 26 days.

---

## 13. Out of scope

- Any change to the security ladder, alarms, or the raid event cards themselves — this PRD only re-points the *inputs* those systems read.
- Faction-vein self-seeding (§5).
- A cap on how many veins the Vein Station can hold (currently uncapped; unchanged here).
- Ore-type-specific growth behaviour — all five types drift and yield identically.
- Any new consumable or device interacting with growth.

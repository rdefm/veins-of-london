# 29 — Grilling: muscle (hired guards and soldiers)

**What to build:** A grilling session (the `grilling` skill) with the human, then a spec, for a "muscle" system: the player (and factions) hire and manage people who act as guards and soldiers. Muscle can be allocated as guards on veins, as guards on HQ, or held in reserve to answer alarm calls. Muscle can be trained and equipped. Raid reinforcements (23) then draw from the owning faction's muscle pool instead of the flat placeholder +2. No code in this ticket.

The grilling must settle at least:
- how muscle relates to today's guards (vein guard slots, `extraGuards`, HQ `guardCount`, guard wages, guard kit): replace, wrap, or sit beside
- hiring, wages and upkeep; where muscle comes from (contacts, factions, districts)
- allocation: veins, HQ, reserve; how a reserve answers an alarm (response time in raid cards, how many come)
- training (stats, levels) and equipment (guard kit, weapons), and how both show up in fights
- faction muscle pools and how factions spend and lose them
- what changes in raid reinforcements (23) and the stockpile raid's guards

Output: `.scratch/muscle/spec.md` with the decisions at the top, handed to the human for approval. Ticket breakdown only after approval.

**Blocked by:** 10 — The Arches; 11 — The Shop; 19 — Rebuild `vein_raid`; 26–28 — Prose (the raid work built and tested first).

**Relevant files:** `systems/guard_upkeep.gd`, `systems/guard_kit.gd`, `systems/cultivating.gd` (`vein_guard_count`, `drop_vein_guard`), `systems/home.gd` (`guardCount`), `systems/factions.gd` (`apply_security_upgrades()`), reinforcement clock from 23, `CONTEXT.md`, `docs/adr/`, REFERENCE.md §1.6 (guards, guard kit), §1.8 (faction guard hiring and wages), §3.12 Vein raiding.

**Status:** ready-for-human

## Grilling progress (session 1, 2026-11-09)

Decided:
1. **Wrap, not replace/beside.** Muscle is the single source of truth for guard bodies. `Cultivating.vein_guard_count`, `Home.get_guard_count`, faction `stockpile.guards` become derived from muscle posted at that place, so every current consumer (raid resist, repel, kit capacity, raid enemy count, wages) keeps reading the same functions. No parallel guard + muscle count.
2. **Hybrid granularity.** Player muscle = individual records (`{id, name, level, xp, gear, post}`-ish). Faction muscle = counts by level (see 35), sim-only, enough to spawn raid enemies at the right strength.
3. **Own lightweight entity, not Contacts.** Player roster under `state.muscle`, generated names from a data name pool, no portraits/dialogue/room seats. Contacts stay the named-people layer; a contact can supply muscle but isn't one. LodedInnit stays skilled staff.
4. **Hiring channel: a version of "fixer contact runs a hiring board"** (shape settled in 15–17; no quick-hire shortcut). Rejected for now: generic button only, per-district pools. Faction-rented muscle (relation-gated, recallable in war) parked as a possible later extension.

(Q4 leftovers settled: Arnie runs it, decision 9/13; board shape 15–17.)

## Grilling progress (session 2, 2026-11-09) — UI spine

Human goal: concise, clear, intuitive UI for hiring, managing and (maybe) training/equipping guards; equipping likely stays with site-based guard kits; allocation must cover HQ.

Decided:
5. **Security management screen reached from the HQ security room, once bought/unlocked** (revised session 3, 2026-11-10: was a phone app). Mix of "HQ screen" + "fixer contact" ideas. No fixer personality on the screen (see 39); the roster isn't managed inside a chat thread. "App" below = this screen.
6. **App scope (consolidate people-security):** tabs
   - **Posts**: place-centric. Groups HQ / each vein / Reserve, each with count, weekly cost, "Kit n/cap ›" link to the existing kit stocking sheet.
   - **Guards**: person-centric. A list of all hired guards. Tapping a guard opens a detail sheet (stats, wage, training options, post, dismiss). A **Hire** button on this tab opens the fixer's board (candidate cards: name, level, wage, trait).
   - **Costs**: Guard Costs moves here from BizBrief; Short Pay deep-links here.
   - Locks/cameras/wards/alarm hardware stays in the HQ Security zone (app = people, not hardware).
   - Everything else becomes readouts plus deep links into the app: HQ door guard tile → Posts@HQ, vein detail panel → Posts@vein, `hq_guard_kit` list, BizBrief expense totals/Brief rows.
7. **Posting from three entry points, one system function:**
   - Posts tab: "+ Assign" per place picks from Reserve; guard row "→ Reserve".
   - Guard detail: "Post: [▾]" picker (HQ / any vein / Reserve), so post-to-post moves happen here.
   - Vein detail panel guard row: **+ Assign** (Reserve picker) and **Manage ›** (Posts scrolled to that vein).
8. **Security score per vein (and HQ), a readout only.** *Display superseded by 19–20 (one combined score); the Deter/Defend split below is now just its two inputs.*
   - **Deter** = locks, wards, cameras, alarm → raid resist.
   - **Defend** = guard count × level/training/skills + guard kit → repel chance and defend-fight strength.
   - Formulas stay separate (`vein_raid_resist`, `Raiding.guards_repel`, faction `_rivalry_chance`). Muscle plugs in by adding guard quality to raid resist/repel; no single mechanical score.
   - Shown on the vein detail panel and Posts group headers (map vein bubble maybe).

9. **Arnie runs it, via an event.** Arnie introduces his security company; from then on everything is handled in the security screen (no ongoing chat-thread management). Trigger and prose settled in 13; `securityContactUnlocked` stays separate (14). No existing event covers it, so it's a new prose ticket.

## Grilling progress (session 3, 2026-11-10)

10. **Security room = new buyable room** (`securityRoom` in `home.json` `rooms`, uses a room slot like Ops). Buying it opens the management screen (Posts/Guards/Costs). Hardware (lock/cameras/door/alarm/ward) stays in the diorama Security zone.
11. **No vein guards before the room.** Until it's bought the player can't post guards on veins (the vein `guarded` tier / "+1 guard" is unavailable).
12. **Room minTier `townhouse`, £2,500** (placeholder for the economy pass). HQ guard posts open with the room at townhouse; the HQ "Hired Guard" compound gate goes away.
13. **Buying the room fires the intro event** (on the next HQ visit). Prose: Archie says they need help with security and has called Arnie; Arnie then gives the player an overview/tutorial on managing guards (hiring board, posts, reserve, costs). The screen works from then on. The event is one prose ticket under writing-guide.md.
14. **`flags.securityContactUnlocked` unchanged**: stays the prologue's ×0.7 HQ hardware discount, unrelated to Arnie.
15. **Hiring board: 4 candidates, refreshed every Monday.** A hired card stays empty until the next refresh. No paid re-roll. Candidate quality does NOT depend on HQ tier.
16. **Candidate level = a fixed random mix.** Each card rolls its level on its own (odds in 23). Wage is set by level. Training is how you get better guards over time.
17. **No quick-hire shortcut.** All hiring goes through the board. With an empty Reserve, a vein panel's "+ Assign" shows "No one in reserve — Hire ›", which deep-links to the board. The vein-panel "+1 guard" / `guarded`-tier purchase is removed.
18. **Level weights on the existing constants** (weights in 23). Vein resist = lock/ward tier (0/15/35) + 20 × sum of guard weights; repel = 15% × sum of weights, capped at 75%. An all-L1 roster gives today's numbers. The `guarded` tier goes; a vein's tier tops out at warded.
19. **One Security score shown to the player** (overrides the two-bar display in decision 8). The resist and repel formulas stay separate underneath; the score is a readout that combines them.
20. **Score = 40 × (hardware ÷ place's max hardware) + 60 × (repel ÷ 75% cap)**, rounded, 0–100. Vein hardware = lock/ward resist (max 35). HQ hardware = sum of installed `raidReduction` (max 0.18 excl. guard). Word band beside it: 0–24 Exposed / 25–49 Light / 50–74 Solid / 75+ Fortified. Shown on the vein detail panel and Posts group headers.
21. **Old saves not supported.** Save version bump; no migration or backfill of existing anonymous player guards (`guarded` tier, player `extraGuards`, `home.guardCount`).
22. **Grade = level, 1–5 max.** Guards gain XP passively from being on a post (guarding) and from player-run training; at each XP threshold they level up. Wage is set by level only (no per-card variance), so it rises as a guard levels. Advance, Monday bill and grace day work as before, summed per person; Reserve guards are paid too.
23. **Level table (placeholder):** L1 weight 1.0 / £500/wk / board 50%; L2 1.25 / £600 / 30%; L3 1.5 / £750 / 15%; L4 1.75 / £900 / 5%; L5 2.0 / £1,100 / 0% (training only). Weights feed the formulas in 18.
24. **XP (placeholder):** +1/day on a post (vein or HQ); Reserve earns 0; +5 for a successful repel; +3 for each guard who fights in a defend fight (win or lose). Cumulative thresholds double: L2 50 / L3 100 / L4 200 / L5 400. A level-up sends a notification, and the new wage applies from the next Monday bill.
25. **Training:** "Train ›" on the Guard detail sheet (off-screen, no named venue; see 39). Costs £200 × the guard's current level. The guard is away 1 day training and recovering (off post, so the post is unguarded unless covered from Reserve). +10 XP per session. No player time block spent. **No session cap**: cost and the empty post limit it; training from Reserve costs no security.
26. **Equipment = existing place kits only.** No per-guard gear or weapons. Kit capacity still counts bodies (guards × slotsPerGuard), not level weights. Level shows up in fight stats.
27. **Guard ally fight stats = the `guardAlly` block × level weight** (L1 ×1.0 … L5 ×2.0, rounded) on HP, attack min/max and speed. The ally shows the guard's name and level. L1 = today's block.
28. **Guards never transfer with a vein.** A vein taken from the player by force: its guards fall back to Reserve, unhurt (one notification). Selling/buying a vein doesn't move guards (seller's guards go to their Reserve/pool). A vein the player takes from a faction arrives with no guards. Guards injured in a fight are out of commission for 3 days (see 29).
29. **Injury:** a guard ally knocked to 0 HP in a fight (win or lose) is Injured for 3 days: dropped to Reserve, can't be posted or trained, still paid, no passive XP; tag "Injured · Nd" on the Guards list. A repel never injures. No deaths.
30. **Short Pay with people:** the Short Pay sheet becomes a per-person keep checklist (grouped by post, wage shown, total checked against reserve/cash). Auto-resolve drop order: Reserve first (injured included), then posted guards on the least valuable vein first, then HQ. Within a place the lowest level walks first. Walked guards are gone for good.
31. **Posting:** cap 4 per vein and 4 at HQ (placeholder); Reserve uncapped. Moves are instant, free, no cooldown; a guard can be moved every time block.
32. **Reserve answers alarms in fights.** In a defend fight at an alarmed place (HQ `pendingRaid`, vein `pendingDefendRaids`), posted guards start at round 1. Up to 2 Reserve guards (placeholder `reserveResponders`; highest level, not injured) join at round 3 through the existing reinforcement queue, then return to Reserve.
33. **Undefended/expired alarms:** up to 2 Reserve guards add their weights to that place's repel roll (cap 75% / 90% with kit). **Each Reserve guard answers at most one alarm per time block** (fight or repel). E.g. 3 alarms in one block with 4 in Reserve: two alarms get 2 each, the third gets 0.
34. **Responder priority (automatic, no picker):** the fight the player Defends first, then HQ, then veins by `Cultivating.value_order` (most valuable first). Each alarm takes the 2 highest-level free guards. Alarms rows show "Reserve: 2 responding" / "Reserve: none free".
35. **Faction muscle:** counts by level, `guards: [n1..n5]` on each faction vein and stockpile, plus a faction Reserve `muscle.reserve: [n1..n5]`. Hire level rolls a per-faction `muscleOdds` profile in `factions.json`. No faction XP/training. Wages use the same level table; walk-off goes lowest level first. Daily buy order: lock → ward → fill vein posts (cap 4, highest-value first) → stockpile target → Reserve target (`reserveGuards` per faction). Factions lose the `guarded` tier too.
36. **Raid reinforcements (23):** when the clock fires, up to 2 (`reserveResponders`) come from the owner faction's Reserve, highest level first, with stats = block × weight. An empty Reserve means none come: the arrival card plays a "No one came." variant if the event has one, otherwise it's skipped. Faction Reserve follows the same one-alarm-per-block rule. The raid's starting guards = that vein's posted guards (count + levels); the stockpile raid uses `stockpile.guards`. Sites with no owner faction (Arches/Shop) keep the event's flat +2.
37. **Faction muscle loss:** a faction guard defeated in a player raid fight is out 3 days (`muscle.injured: [{level, returnsDay}]`) and then returns to the faction Reserve; no deaths. A faction vein taken by anyone: its posted guards fall back to that faction's Reserve, unhurt. Faction-vs-faction rivalry: the loser of the attempt loses 1 guard to injury (the defender's raided vein on success, the attacker's Reserve on failure). Walk-off unchanged (lowest level first).
38. **Losing the room** (arrears downgrade below townhouse, a tier with no free slot, or replaced via `set_room_use`): guards stay employed; posts, wages and fights keep running. The screen is locked (no hiring, posting or training); vein posts freeze as they are; HQ guards drop to Reserve if the new tier is below townhouse. Short Pay still works. One notification: "No security room. Your guards hold their posts but can't take new orders." Re-buying restores management; the intro event doesn't replay.
39. **Arnie appears only in the intro event.** After it he plays no part: no avatar or line on the hiring board (candidate cards only), training is "Train ›" with no named venue, and system text never names him.
40. **Traits (placeholder, data file):** every guard has at least one trait, drawn from the list below, fixed for life. Shown as a tag on the card and the detail sheet, with a one-line effect on tap. Positive: Quick study (+50% XP from every source), Brawler (fight attack ×1.25), Solid (fight HP ×1.25), Watchful (+0.25 weight for repel only), Hard to keep down (injury 1 day, not 3), Cheap (wage −20%). Mixed: Mouthy (wage +10%, +0.25 repel weight; "people steer clear"), Hothead (fight attack ×1.25, HP ×0.8). Negative (no wage discount): Flaky (−0.25 repel weight), Glass jaw (fight HP ×0.75), Slow learner (−50% XP), Lazy (no passive XP on post), Light-fingered (10% chance each Monday that 1 kit unit at their post goes missing). Some guards have 2 traits, so a positive + negative pair is possible (chance: see 41).
41. **Second trait:** 25% of cards (placeholder) roll a second, distinct trait, drawn evenly. Blocked pairs: Solid+Glass jaw, Quick study+Slow learner, Watchful+Flaky, Quick study+Lazy. Other effects stack multiplicatively (e.g. Brawler+Hothead attack ×1.56).
42. **Dismiss:** "Dismiss" on the detail sheet, with a confirm. The guard leaves at once, with no severance and no refund of the week's advance. Injured guards can be dismissed. Dismissed guards can come back on later weekly boards and be rehired (details: see 43).
43. **Former guards:** dismissed and walked-off guards go to `muscle.former` (capped at 20, oldest dropped). Each board card has a 10% chance (placeholder) to be a former guard instead of a fresh roll. They return as they left: name, level, XP and traits; wage by level; injuries cleared. Card tag: "Worked for you before".
44. **Costs tab:** a header with the next Monday bill (£ + date) and this week's total, split into wages and training. Rows by place (HQ / veins / Reserve) show weekly cost + the existing 28-day history chart; tap to expand per-guard wages (name, level, wage). A separate training line (this week / 28 days). History stays per place (`guardUpkeep.history`). The Short Pay deep link opens the checklist over this tab.
45. **Names:** `data/muscle_names.json`, ~60 first names + ~60 surnames, London mix, plus a nickname list (generic and funny). 15% of guards (placeholder) get a nickname, shown as Dee "Spanner" O. List rows show first name + surname initial; the detail sheet shows the full name. No repeats among current and former guards. PROSE-REVIEW flag in the build ticket.
46. **No company name needed.** The screen is "Security". The intro prose may name a firm, but nothing depends on it.
47. **Enemy strength visibility:** observing a site shows guard count + a strength word from average weight per guard: green (<1.25) / hardened (<1.75) / seasoned (≥1.75), with no exact levels. The observation security signature includes levels. In raid fights, enemy guards show their level on combat cards. Faction Reserve size stays hidden (a possible future Network intel product, out of scope).

Still to grill: nothing open (session 3 end).

- [x] Grilling session held; decisions recorded at the top of the spec
- [x] Spec covers the points above (`.scratch/muscle/spec.md`, merged with `.scratch/security-officer/spec.md`)
- [ ] Human approval recorded in the spec
- [ ] Not marked `_COMPLETED` before approval

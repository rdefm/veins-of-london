# 19 — Scout a faction vein

**What to build:** Tapping a faction vein on the map shows a **Scout** action next to Raid. Scouting costs 1 time block and has no other risk: no ambush roll, no spotted outcome. Each scout makes five independent rolls, one per security fact:

| Fact | Chance |
|---|---|
| alarms/cameras | 80% |
| guard count | 50% |
| guard strength | 40% |
| guard kit | 30% |
| ward | 25% |

- **On a hit:** the player learns that fact as it stands right now. This is a snapshot: if the faction later changes guards or kit, the snapshot stays as it was and can be wrong.
- **Freshness:** a fact stays fresh for 7 days from the day it was found. After that it reads `?` again.
- **Re-scouting:** rolls all five again. New hits add to what's known; a hit on a fact already known refreshes its value and its 7-day clock.
- **Intel:** each scout raises the player's intel on that faction by 2. The existing `gain.scout` value changes 8 → 2.
- **Result:** one short notification lists what was found, or says nothing new turned up.

The sheet rows show fresh scouted facts. Until 20 lands, the vein-security intel level still shows all facts live.

Chances, staleness days and the gain go in data. Rolls draw from the game RNG stream, so Rewind replays them identically. The scout state is pure data, needs a save version bump with backfill, and is player only. Add a **Scouted security** entry to CONTEXT.md (distinct from the Network's *site intel*).

**Blocked by:** 18

**Relevant files:**
- `systems/intel.gd`: new scout roll, shared with 21 and 22
- `systems/raiding.gd`: `security_profile`
- `scenes/screens/map.gd`: `_build_faction_vein_content` (Raid button block-cost pattern, `Travel.can_afford`)
- `systems/notify.gd`
- `autoload/Rng.gd`
- `autoload/GameState.gd`: new top-level state; keep it out of `state.intel`, whose keys are actor ids
- `autoload/SaveManager.gd`: `SAVE_VERSION` 17 → 18
- `data/constants.json`: `intel.gain.scout`, new `intel.scout` block, `intel.securityRead` strings
- `tests/test_intel.gd`
- `CONTEXT.md`, `CODEMAP.md`
- REFERENCE.md §1.11 "Intel", §3.1 "Intel", §3.12 "Security profile", §6 save format

**Status:** ready-for-agent

- [ ] Scout spends 1 block; it is disabled or refused when the block can't be afforded.
- [ ] Five independent rolls at the listed chances; each hit stores the fact and the day.
- [ ] A re-hit refreshes value and day; misses never erase a fresh fact.
- [ ] A snapshot keeps its old value after the faction changes guards/kit, and reads `?` from day found + 7.
- [ ] Intel +2 per scout; no ambush roll.
- [ ] Rewind before a scout restores the prior state; an older save loads with no scouted facts.
- [ ] Human QA: Scout action on the faction vein sheet, mixed rows (e.g. "? guards · tough · kit: ?"), notification text. PROSE-REVIEW: action label and notification strings.
- [ ] Syntax check clean, tests pass, REFERENCE/CONTEXT/CODEMAP updated.

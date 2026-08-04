# 10 — Cultivating tutorial event + M1 gating

**What to build:** the `archie_cultivation` event per D6 (6–9 cards, trigger on first Map-tab visit after `archiePartnerSeen`, ends with `tutorial_cultivate` free-cultivate effect + archie relation +2 + `cultivationTutorialSeen`), plus D7's gating (Map tab locked until `archiePartnerSeen`, prospecting locked until `cultivationTutorialSeen`, debug start seeds 2 discovered sites, home-raid vein grant fixed to reference Whitechapel properly with a matching claimed site).

**Blocked by:** 02, 04.

**Status:** done

- [x] `archie_cultivation` triggers correctly on first qualifying Map-tab visit; ends with the specified effects
- [x] Map tab nav entry greyed with "Stick close for now — Archie" until `archiePartnerSeen`
- [x] Prospecting locked until `cultivationTutorialSeen`
- [x] Debug start seeds exactly 2 discovered sites (rich/greenwich, saturated/whitechapel, both unclaimed) and unlocks everything
- [x] Home-raid vein grant creates a matching claimed site (tier fair, no bonuses) in Whitechapel, consistent with the map
- [x] Prose drafted per tone bible, flagged `PROSE-REVIEW`
- [x] `godot --headless --check-only --script` clean on all touched files

## Comments

Implementation notes (M1-LONDON-T07):

- New `archie_cultivation` event (8 cards) added to `GameData.EVENT_IDS` (not the district deck — it's a one-shot tutorial beat, same category as `home_raid_intro`/`archie_craft_chat`). Triggered from `scenes/screens/map.gd`'s `_ready()`, mirroring `home.gd`'s existing `home_raid_intro` idiom exactly: check `archiePartnerSeen && !cultivationTutorialSeen` before building any UI, `start_event()` and return early if it fires.
- Two new `Events` effect ops (`systems/events.gd`, registered in `GameData.VALID_EFFECT_OPS`):
  - `grant_vein_with_site` — like `grant_vein` but also creates a matching `state.world.sites` entry (tier/oreType/bonuses derived from the vein template's own `hospitability`/`oreType` fields, so the two can't drift out of sync) and links it via the new vein's `siteId`. Replaces `grant_vein` in both `home_raid_debrief_win.json` and `home_raid_debrief_loss.json` — previously the debrief granted a vein with `district: "whitechapel"` but no backing site, so the Map tab showed a Whitechapel vein sitting on land that didn't exist.
  - `tutorial_cultivate` — forces one always-successful cultivate (`devBar += barGain`, level-up check if it crosses `devBarMax`, no block cost, no XP — exactly what D6's parenthetical spells out and nothing more). Looks up "the" tutorial vein by `district == "whitechapel" && oreType == "time"` rather than a threaded id, since no id exists to pass through static JSON and a fresh playthrough has exactly one such vein at this point (comment in code explains the assumption and why it's safe).
- Map-tab lock (`scenes/components/nav_bar.gd`): the bar is built once by `Main.gd` and never rebuilt, so it now subscribes to `EventBus.state_changed` itself and disables/relabels the Map button live, same pattern every screen's `_refresh()` uses.
- Prospecting lock (`scenes/screens/map.gd`'s `_build_district_actions`): implemented as a UI-level swap (locked label instead of the Prospect button) rather than a check inside `Sites.prospect()` itself. This matches the codebase's existing precedent for tutorial-unlock flags — `craftingUnlocked` gates the crafting screen the same way, with no matching check inside `Crafting.attempt_craft()`. It's also structurally unreachable as a bypass in practice: the Map tab is locked until `archiePartnerSeen`, and the very first Map visit after that always redirects into `archie_cultivation` before any district panel renders, so there's no window where a player can see an enabled Prospect button before `cultivationTutorialSeen` flips true.
- `systems/debug_start.gd` now seeds `state.world.sites` with 2 fixed (non-rolled, deterministic) unclaimed sites — rich/greenwich, saturated/whitechapel — matching the rest of debug start's fixed-not-rolled style. The existing all-bool-flags-true loop already covers `archiePartnerSeen`/`cultivationTutorialSeen` without any extra code.
- Code review (standards + spec sub-agents): confirmed Godot-4/one-way-data-flow compliance and D6/D7 mechanics match; flagged (and fixed) that Archie's "calc" tic — used by every other Archie tutorial event — was missing from the harvest-explanation card, added to card 5. Also flagged the `Sites.prospect()` UI-vs-system gating question addressed above, and noted `Cultivating.cultivate()`'s success-branch math is now duplicated inline in `Events._tutorial_cultivate()` rather than delegated — left as-is since `tutorial_cultivate` deliberately skips the block cost, RNG roll, and XP that `Cultivating.cultivate()` always applies, so there's no shared code path to call into without carving one out of `cultivate()` for a single one-shot caller.

**PROSE-REVIEW** (new — draft per CONTENT-GUIDE.md tone bible, needs human audit):
`data/events/archie_cultivation.json` (all 8 cards, new content) and the UI copy string "Prospecting — see Archie first" (`scenes/screens/map.gd`'s locked-Prospect label).

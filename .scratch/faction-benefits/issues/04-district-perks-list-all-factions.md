# 04 — District perks panel lists every faction

**What to build:** Fix the district panel's "Perks" section so it always renders. It currently loops over `TurfPanel.build(...)["sections"]["contenders"]`, which is built from claimed vein counts (`Turf.counts`), so a district with no faction veins (every district on a new game, and until the first daily `Turf.recompute`) shows nothing — no active perks and no "Locked — needs X" lines. Build the section from all five factions instead, regardless of presence.

**Blocked by:** 03 — District view perk preview rework (this reworks its section).

**Visual reference:** `mockups/district-all-factions.html` (Whitechapel scenario; open in a browser). Layout, grouping and content only — colours are illustrative. Keep the Map tab's existing theme (`map_palette.json` light/dark tokens via MapCardStyle, incl. Dark map).

**Behaviour:**
- **Perks here** group: one card per faction that has at least one turf-scope perk (collective, firm, guild, conclave; not network). Card header shows the faction's presence badge: "Holds district · full", "Foothold · half", or "No ground here". Under it, every turf perk of that faction (all tiers) with a status pill and a one-line description / requirement.
- Ordering: factions with ground first (Control, then Foothold, by share), then the rest in `GameData.FACTIONS` order. Factions with no ground are visually dimmed but still listed.
- Perk status pill: Active (unlocked + full), Active half strength (unlocked + foothold), Idle here (unlocked, no ground), Locked (tier not reached). Locked/idle lines state the unlock requirement ("Needs Partner stance (you are Friendly)", "Needs Relation ≥25 (you: 8)", "Needs Joined"); idle lines say "No ground held here yet".
- **Everywhere** group: one compact row per global perk across all factions ("Faction · Perk name", description or requirement, status pill). Unlocked first. Collapse the long tail of locked rows behind a "+ N more locked" line (tap to expand) so the panel stays short.
- Footer line pointing at Phone › Factions for the full ladder.
- The player's own turf share is not a faction card (skip `Turf.PLAYER`). Data comes from `Perks.district_benefit_rows(faction_id, district_id)` per faction; extend it only if the player's current tier/relation is needed for the "(you are Friendly)" text — prefer `Perks.player_tier` / `GameState.state["factions"][id]["relation"]` read in the system layer, not the screen.
- Presence badge and ordering helpers (share, tier) live in a system function (e.g. `TurfPanel` or `Perks`) returning plain rows; `map.gd` only renders them. No state mutation in the screen.
- Do not change the Turf section above it or the benefit-row data shape used by the Factions app (02).

**Relevant files:** `scenes/screens/map.gd` (`_add_perks_section`, `_perk_line`), `scenes/screens/map_card_style.gd`, `systems/perks.gd` (`district_benefit_rows`, `benefit_rows`, `player_tier`, `requirement_text`), `systems/turf_panel.gd`, `systems/turf.gd` (`tier`, `shares`), `data/faction_perks.json`, `tests/test_perks.gd`, `tests/test_turf_panel.gd`, `CODEMAP.md`. REFERENCE.md §3.10 "Perks".

**Status:** ready-for-agent

- [ ] Fresh new-game district (no faction veins) shows the Perks here and Everywhere groups
- [ ] All four turf-perk factions listed under Perks here with correct presence badge, even with no ground
- [ ] Global perks listed for all five factions under Everywhere; locked tail collapsed, expandable
- [ ] Each non-active perk states what unlocks it, using the player's current tier/relation
- [ ] Row-building logic in a system with a test covering: no veins, one controller, foothold, sworn-with-no-ground (Idle)
- [ ] Wording plain; new strings flagged `PROSE-REVIEW:`
- [ ] check_all + tests pass; human on-device check: panel readable, active vs locked obvious at a glance, length acceptable

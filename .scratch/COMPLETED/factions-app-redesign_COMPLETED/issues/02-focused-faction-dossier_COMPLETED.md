# 02 — Focused faction dossier

**What to build:** A tapped faction opens the approved dossier: relationship and pressure first, existing available actions and requests next, then identity, a compact market footprint, intel and activity. The player can still reach every action and every piece of intel-gated information that was on the old long card.

**Blocked by:** 01 — Branded directory and dossier route.

**Status:** ready-for-agent

**Relevant files:** `scenes/phone_apps/factions_app.gd`, `scenes/components/contact_cards.gd`, `scenes/modals/gift_modal.gd`, `systems/factions.gd`, `systems/faction_ai.gd`, `systems/diplomacy.gd`, `systems/partners.gd`, `systems/intel.gd`, `systems/shares.gd`, `data/ore_types.json`, `tests/test_contact_cards.gd`, `docs/REFERENCE.md` §3.1 “Intel”/“War and weariness” and §3.10 “Favours”/“Gifts”/“Partners”, `CODEMAP.md`.

- [ ] Dossier top shows full name, tagline, stored stance, signed relation and neutral centred meter, pressure and current war/truce. Existing Gift, Join, Guild Marketplace, partner price-favour, peace-talk and pending favour/trouble routes retain their exact gates, costs, effects and disabled reasons. No new relationship action is added.
- [ ] Pending/owed requests and available actions precede description, archetype, primary/secondary ore and crafts. Structured ore labels show the canonical glyph and name; authored prose remains unchanged. The old standalone Factions screen still works if shared card code changes.
- [ ] Market footprint is a two-column grid headed by the primary and secondary ore glyph/name. Its only rows are Ore and Crafting; each of the four cells shows the existing exact percentage with oxide-orange fill proportional to that share.
- [ ] Intel and Activity may start collapsed but open in one tap. All existing intel thresholds, known holdings/security/stockpile reads and full newest-first activity log remain available; nothing past the player's intel level leaks.
- [ ] Headless checks cover contextual actions, blocked states, glyph-bearing ore labels, the four live share values, intel gates and activity order. Syntax checks and full Godot 4.7 suite pass. Report narrow-phone visual checks and new copy as `PROSE-REVIEW:`.

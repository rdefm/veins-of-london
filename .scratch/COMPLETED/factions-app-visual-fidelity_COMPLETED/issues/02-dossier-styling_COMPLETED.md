# 02 — Dossier styling

**What to build:** Opening any faction presents the mockup's dark dossier, with clear standing, prominent actions, a compact market footprint, and readable disclosures, while keeping every existing action and intel gate.

**Blocked by:** 01 — Register shell and home.

**Status:** ready-for-agent

**Relevant files:** `scenes/phone_apps/factions_app.gd`, `scenes/components/contact_cards.gd`, `scenes/components/ui.gd`, `data/ore_types.json`, `tests/test_phone_apps.gd`, `tests/test_contact_cards.gd`, `CODEMAP.md`; visual reference: `.scratch/factions-app-redesign/mockup.html`.

- [ ] Dossier sits on the Register canvas without a large generic cream card. An orange text back link leads to home; the **FACTION DOSSIER** kicker, full name, tagline, section rules, spacing and type hierarchy follow the mockup. Standing shows stance, signed relation, neutral centred meter with endpoint and −100 / 0 / +100 labels, pressure, and war/truce detail.
- [ ] **AVAILABLE NOW** gives existing actions the mockup's treatment: a filled oxide-orange primary Gift button with dark text, outlined or dark secondary actions, readable disabled reasons, and distinct pending/owed request panels with compact response buttons. The shared phone red action style must not override these Register controls. Preserve all existing gates, costs, effects and route targets.
- [ ] **DOSSIER** uses compact aligned identity rows, with canonical ore glyphs beside structured ore names. Market footprint matches the two-row Ore/Crafting grid: primary and secondary glyph/name column heads, exact percentages centred in dark cells, and strong oxide fill proportional to each share. Intel and Activity use the mockup's divided disclosure rows and remain fully readable when expanded.
- [ ] Automated checks retain action, intel and share coverage; on-device comparison includes a dossier with actions/request visible and its market footprint, plus a narrow-width scroll check. Godot 4.7 syntax and full tests pass. Flag any new prose with `PROSE-REVIEW:`.

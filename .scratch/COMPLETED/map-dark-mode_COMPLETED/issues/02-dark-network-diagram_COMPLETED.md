# 02 — Dark Network diagram

**What to build:** The player can switch the Network diagram to dark mode from a toggle in the Map controls drawer. It is off by default and saved per save file alongside the other presentation preferences (reduced motion, vibration). It survives save/load, and no Rewind or snapshot restore ever flips it. Toggling sets the preference through the preferences system and redraws the diagram immediately.

In dark mode:
- The paper, river, neutral fullness track, district labels and halo animations use dark-set values.
- Stop centres and pin-head knockouts stay white, and ore glyphs stay charcoal.
- The Growth filter's fullness-arc ramp runs muted → light foreground instead of muted → ink.
- Every owner line, stub, progress arc, padlock tint and danger ring keeps at least 3:1 contrast against the dark paper. Colours that fall short get lighter dark-only variants. The estimate flagged the crimson faction / danger red, emotion ore and guild/guarded green; the action red matters in ticket 03.

Light mode is unchanged. Popup cards, legend, zoom buttons, drawer, top-row icons and the nav dock may stay light until tickets 03/04.

Amend `docs/M1.5-NETWORK-MAP.md` §N4 so the Growth ramp is described as muted → foreground, and note there that the diagram has a player-toggled dark variant. Add the same note to `docs/ui-vision.md` §4 (Family 3). The toggle label is new UI copy: keep it in data and flag it `PROSE-REVIEW:`.

**Blocked by:** 01

**Relevant files:** `systems/preferences.gd`, `scenes/phone_apps/settings_app.gd` (existing preference-toggle pattern), `scenes/components/map_controls.gd`, `scenes/components/map_canvas.gd`, `scenes/components/map_halos.gd`, `systems/map_style.gd`, `autoload/SaveManager.gd` (meta handling), `autoload/Snapshots.gd`, every system `rewind()` (`systems/events.gd`, `systems/combat_prototype.gd`, others via grep), `data/factions.json`, `data/ore_types.json`, `docs/M1.5-NETWORK-MAP.md` §N4, `docs/ui-vision.md` §4, `CODEMAP.md`.

**Status:** ready-for-agent

- [ ] Toggle in the Map controls drawer shows the current value and switches the diagram live
- [ ] Tests: preference defaults off; survives save → load; unchanged after a Rewind
- [ ] Test: every dark line/arc/danger colour has ≥3:1 contrast against the dark paper
- [ ] Growth ramp test covers both modes
- [ ] M1.5 and ui-vision amended; `PROSE-REVIEW:` flag for the toggle label; report lists every dark hex
- [ ] Human check: each filter mode in dark is readable; stops read white with charcoal glyphs; pins readable; halos fit the dark paper; palette sign-off on the listed hexes

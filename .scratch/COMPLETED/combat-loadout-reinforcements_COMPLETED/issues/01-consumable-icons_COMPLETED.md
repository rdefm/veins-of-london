# 01 — Consumable icons everywhere

**What to build:** Every one of the 14 crafted consumables shows its own pixel-art icon wherever the item appears — Profile, Bag, Dial Complications (load sheet and readout), events and trade — replacing the current text glyphs. Dial Movement symbols are not redesigned. Icons follow the physical-art vs vector-chrome distinction and the mobile contrast/tap-size rules. Provide one shared item→icon lookup so later tickets (combat item rows) reuse it.

**Blocked by:** None — can start immediately.

**Relevant files:** `assets/combat/icons/*.png` (already saved; `attack.png`/`leg_it.png` are command icons, not consumables), `data/items.json`, `data/recipes.json`, `scenes/components/bag_drawer.gd`, `scenes/phone_apps/profile_app.gd`, `scenes/screens/hq_dial.gd`, `scenes/modals/dial_load_complication_modal.gd`, `scenes/components/dial_widget.gd`, sell/trade menu screen, event item button (consumers of `systems/event_items.gd`), `docs/ui-vision.md`, `CODEMAP.md`. REFERENCE §1 items table if an icon field is added — update it with the change.

**Status:** ready-for-agent

- [ ] Each of the 14 crafted consumables maps to a distinct icon via one data-driven lookup
- [ ] Profile, Bag, Dial Complication views, event item buttons and trade rows render the icon instead of a text glyph
- [ ] Dial Movement symbols unchanged
- [ ] Headless scene tests assert icon binding on at least Bag and Profile
- [ ] Report lists on-device QA: icon legibility at 390×844, contrast, tap targets

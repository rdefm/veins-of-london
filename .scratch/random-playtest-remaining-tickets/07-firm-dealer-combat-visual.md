# 07 — Firm dealer combat visual

**What to build:** Wire the `firm_dealer1` sprites into combat as a `firmDealer` visual template that replaces the Orichalchum Dealer only when the enemy belongs to The Firm — in real combat (Firm faction squads) and in the combat prototype (when the enemy faction is the Firm). Non-Firm fights keep the Orichalchum Dealer. Assets have idle / attack1 / hurt only: KO reuses hurt, held on its last frame, then fades.

**Blocked by:** None — can start immediately.

**Relevant files:** `assets/combat/firm_dealer1/`, `data/combat_visuals.json`, `data/enemies.json` (`factionSquads.firm`), `scenes/components/combat_stage.gd` (`enemy_template_key`), `systems/combat.gd`, `systems/combat_prototype.gd`, `data/combat_prototype.json`, `tests/test_combat_screen.gd`

**Status:** ready-for-agent

- [ ] Firm-squad dealers resolve to `firmDealer`; other dealers stay `orichalchumDealer`
- [ ] Idle/attack/hit animate from the firm_dealer1 sheets (frame counts verified from the PNGs)
- [ ] KO = hurt held on last frame + fade
- [ ] Prototype shows firmDealer when the fight's enemy faction is the Firm
- [ ] Tests cover template resolution for both cases

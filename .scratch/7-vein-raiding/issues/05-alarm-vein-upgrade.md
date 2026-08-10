# 05 — Alarm/cameras vein upgrade

**What to build:** A new purchasable upgrade for player-owned veins, "alarm/cameras," independent of the existing 4-tier security ladder (`none`/`basic`/`warded`/`guarded`, `data/vein_security.json`) — not folded into those tiers, per the PRD. Model it on `home.security`'s existing pattern: an array field on the vein dict holding purchased upgrade ids (mirroring `state.home["security"]` and `Home.add_security`/`GameData.HOME_SECURITY`, which already has a "cameras" upgrade for home-raid mitigation), rather than extending the security-tier ladder. Add a new `data/*.json` table for the upgrade's cost/effect (or extend an existing table if that reads more naturally — implementer's call, document it), and a purchase action on the player's own claimed-vein site sheet content (`_build_claimed_site_content` in `scenes/screens/map.gd`), alongside the existing "Upgrade security" action. This ticket only adds the upgrade and its purchase flow — the defend-encounter behaviour it unlocks is ticket 07.

**Blocked by:** None — can start immediately

**Status:** ready-for-agent

- [ ] New vein-level upgrade field (array of purchased upgrade ids, or equivalent) added to the vein dict shape (`Cultivating.make_vein`), independent of the existing `security` tier field
- [ ] New data table defines the alarm upgrade's cost and any tiering (PRD leaves cost/whether-it-stacks-with-security-cost open — implementer's call, documented)
- [ ] Purchase action added to the claimed-vein site sheet content, cash-only (no time-block cost, same reasoning as `Cultivating.upgrade_vein_security`/`Home.add_security`)
- [ ] Purchasing is idempotent/guarded the same way `Home.add_security` guards against re-buying an already-owned upgrade
- [ ] Tests cover: purchase deducts cash and adds the upgrade id to the vein; re-purchasing an already-owned upgrade is a no-op or blocked; a fresh vein has no alarm upgrade by default
- [ ] `godot --headless -s scripts/check_runner.gd -- path/to/file.gd` clean on every touched file; `scripts/run_tests.sh` passes

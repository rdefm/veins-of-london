# 11 — Guard kits: two units per guard, refill after defence

**What to build:** Vein and HQ guard kits stay shared and tier-bucketed, but capacity is two units × the full guard count (including guards who will wait as reinforcements). HQ drops from three to two per guard; on migration, units above HQ capacity return to player inventory, keeping the highest tiers in the kit (equal tiers by the existing deterministic kit order). After a fought defence or an unattended kit repel, refill only the recipes actually spent, from the highest available tiers in player inventory, up to capacity; unassigned spare capacity is never auto-filled. When a defence spends both personal and kit units, personal refill settles first. Defences use their place's kit, not recruits' slots.

**Blocked by:** 02

**Relevant files:** `systems/guard_kit.gd`, `systems/home.gd`, `systems/cultivating.gd` (vein guard count), `systems/raiding.gd` / `systems/combat.gd` (defence settlement), `scenes/screens/hq_guard_kit.gd`, `scenes/components/guard_kit_view.gd`, `autoload/SaveManager.gd`, `data/vein_security.json`, `data/home.json`, `tests/test_guard_kit.gd`, `tests/test_hq_guard_kit.gd`. Update REFERENCE §1.6, §2, §3.7 with the change.

**Status:** ready-for-agent

- [ ] Capacity = 2 × guards for veins and HQ
- [ ] HQ migration returns overflow to inventory, keeps highest tiers, conserves units
- [ ] Refill after fought defence and after unattended repel: spent recipes only, highest tier first, capped
- [ ] Personal refill before kit refill when both apply (if 06 has landed; otherwise test kit-only and note it)

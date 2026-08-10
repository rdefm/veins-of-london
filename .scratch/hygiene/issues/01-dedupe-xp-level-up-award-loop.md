# 01 — Dedupe the XP/level-up award loop

**What to build:** A single shared "award XP against a levels table" helper, used by
every skill/progression system that currently reimplements the same loop by hand:

- `Crafting.award_crafting_xp` (`systems/crafting.gd`) — against
  `player.craftingSkill`/`player.craftingXP` and `GameData.CRAFTING_XP_LEVELS`. Does
  **not** push a level-up `Notify` — deliberate, matches the original HTML prototype.
- `Cultivating.award_xp` (`systems/cultivating.gd`) — against
  `player.cultivatingSkill`/`player.cultivatingXP` and `GameData.CULTIVATING_XP_LEVELS`.
  Pushes a level-up `Notify`.
- `Devices.activate` (`systems/devices.gd`) — against a specific device's
  `device.level`/`device.xp` (not a player-level field) and `GameData.DEVICE_XP_LEVELS`.
  Pushes a level-up `Notify` with device-specific wording (`chargesPerDay` increment).
- `Raiding.award_stealth_xp` (`systems/raiding.gd`) — against
  `player.stealthSkill`/`player.stealthXP` and `GameData.STEALTH_XP_LEVELS`. Pushes a
  level-up `Notify`.

All four repeat the identical shape: `while <skill/level> < max_level and <xp> >=
LEVELS[<skill/level> + 1]: <skill/level> += 1 [+ side effect]`. This is a pure
mechanical extraction, not a behavior change — every call site's observable behavior
(including Crafting's no-notify exception and Devices' extra `chargesPerDay` bump) must
be identical before and after.

**Blocked by:** None — can start immediately

**Status:** ready-for-agent

- [ ] A single shared helper (exact home is the implementer's call — e.g. a small new
      system, or a static func on `GameData` alongside the levels tables it already
      owns) implements the "given a levels array, current xp, current skill/level, and
      an award amount, return the new xp/skill/level" logic once
- [ ] The helper supports an optional level-up side effect (at minimum: whether to
      `Notify.push`, and the exact message) so Crafting's silence and Devices'
      `chargesPerDay`-aware message are both preserved, not merged into one generic
      string
- [ ] `Crafting.award_crafting_xp`, `Cultivating.award_xp`, `Devices.activate`, and
      `Raiding.award_stealth_xp` all call the shared helper instead of each
      reimplementing the loop
- [ ] No change to any of the four call sites' external signature or observable
      behavior — same XP thresholds, same level caps, same notify/no-notify split,
      same device `chargesPerDay` increment
- [ ] Existing tests for all four systems (`tests/test_crafting.gd`,
      `tests/test_cultivating.gd`, `tests/test_devices.gd`, `tests/test_raiding.gd`)
      continue to pass unmodified, proving behavior parity
- [ ] `godot --headless -s scripts/check_runner.gd -- path/to/file.gd` clean on every
      touched file; `scripts/run_tests.sh` passes

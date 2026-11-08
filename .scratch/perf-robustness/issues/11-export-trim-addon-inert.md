# 11 — Export trim + debug addon inert in release

**Parent:** `.scratch/perf-robustness/spec.md`

**What to build:** Both export presets exclude reference art, tests, tools, scripts, docs, reference, plans, `.scratch` and the debug addon; reference art folders are do-not-import; the MCP helper autoload is inert outside debug builds without leaving a missing autoload path at boot.

**Blocked by:** None — can start immediately

**Relevant files:** `export_presets.cfg` (Android and Web presets), `project.godot` (autoload list), `addons/godot_ai/runtime/game_helper.gd`, `assets/reference-plates`, `assets/character-references`; review §3.1, §4.8

**Status:** ready-for-agent

- [ ] Both presets' `exclude_filter` cover: `assets/reference-plates/*`, `assets/character-references/*`, `tests/*`, `tools/*`, `scripts/*`, `docs/*`, `reference/*`, `plans/*`, `.scratch/*`, `addons/godot_ai/*`
- [ ] Game boots headless with no autoload errors
- [ ] Human check: release build starts and plays on device; APK size compared to 301 MB

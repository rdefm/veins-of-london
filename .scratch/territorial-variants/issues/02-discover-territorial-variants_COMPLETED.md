# 02 — Build territorial variant sprite sets from the folders

**What to build:** The game finds every `assets/combat/territorialN/` folder by itself and builds a combat sprite set for each one from filenames alone. Adding a `territorial4/` folder with correctly named files is enough to make a fourth variant exist, with no JSON edits. The discovered variants are exposed as an ordered list (by N) that later tickets use for the enemy pool and the new-game picker. The player (`territorial3`) keeps rendering correctly, now through the discovered set instead of the hand-written template.

Decisions (agreed with the human):
- **Folder rule:** a folder name matching `territorial<integer>` is a variant; its key is the folder name (e.g. `territorial2`). Anything else in `assets/combat/` is ignored.
- **File convention** inside a variant folder: `territorialN_idle.png`, `territorialN_attack_1.png`, `territorialN_attack_2a.png` + `territorialN_attack_2b.png` (second attack pair), `territorialN_hurt.png`, `territorialN_throw_windup.png` + `territorialN_throw_release.png`. These map onto the same pose slots and fps values the hand-written `territorial3` template uses today (one image per file, the `images` form).
- **KO:** there is no ko art. KO uses the variant's own `hurt` pose, played with the existing ko fall+fade transform. Do not fall back to the generic default ko.
- **Missing poses** follow the existing rules in combat_visuals' `templateRule` / `actionRule` (for example, no throw art means no throw animation). The human will add the missing throw files for territorial1 and territorial2.
- **Export safety:** the scan must work in the Android export, where `res://` holds `.import` / `.remap` entries rather than raw PNGs. Use an export-safe listing (e.g. `ResourceLoader.list_directory`, Godot 4.4+) or strip `.import` / `.remap` suffixes. It must not rely on the raw `.png` being present in the exported pack.
- **Data-driven:** pose→filename mapping and per-pose fps belong in `data/combat_visuals.json` (a single shared "territorial variant" pose spec), not hard-coded in GDScript. Only the folder scan itself lives in code.

**Blocked by:** 01 — Rename protagonist2 to territorial3.

**Relevant files:**
- `autoload/GameData.gd` — loading and validating `combat_visuals` (`_validate_combat_visuals`); a natural home for the scan result and the ordered variant list
- `scenes/components/combat_stage.gd` — `_load_template_idle_animations`, `_load_template_action_animations`, `_load_animation_frames`, `_resolve_action_keyposes` (these currently iterate `COMBAT_VISUALS.templates`; discovered variants must be included)
- `data/combat_visuals.json` — remove the hand-written `templates.territorial3` entry; add the shared variant pose spec; update the `templateRule` note
- `assets/combat/territorial1/`, `territorial2/`, `territorial3/`
- `docs/combat-animation-vision.md` §3 (cast and frame budget), §4 (animation doctrine: ko transform)
- `tests/test_combat_screen.gd`, and a GameData test for discovery
- `CODEMAP.md`

**Status:** ready-for-agent

- [ ] In this repo, discovery returns `territorial1`, `territorial2`, `territorial3` in that order. A test proves that a gap (e.g. only 1 and 3) and a non-matching folder name are handled.
- [ ] Each discovered variant has idle/attack/hit/ko sprite sets (and throw when both throw files exist). Its ko keyposes come from its own `hurt` image.
- [ ] The player with `player.model = "territorial3"` renders and animates as before; `templates` no longer holds a hand-written territorial3 entry.
- [ ] Missing pose files cause no load errors and follow the existing fallback rules.
- [ ] Discovery does not depend on raw `.png` files being listable (verified by code review plus a unit test of the name-normalising helper against `.import` / `.remap` entries).
- [ ] The syntax check is clean, all tests pass, and CODEMAP is updated.

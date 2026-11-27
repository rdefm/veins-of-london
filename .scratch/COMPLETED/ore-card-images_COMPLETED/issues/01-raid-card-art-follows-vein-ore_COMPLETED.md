# 01 — Raid card art follows the raided vein's ore

**What to build:** During a vein raid, a card's art can differ by the raided vein's ore type. When a raid starts, the raided vein's ore (its site's ore type) is recorded with the raid's event progress as plain data, so Rewind and save restore it. When the event screen resolves a card's image by naming convention, it first tries the ore-suffixed file for that card (`<event_id>_card<n>_<ore>`, e.g. `raid_shop_card47_time.png`) and falls back to the plain `<event_id>_card<n>` file. Cards with an explicit `image` key (including explicit null) are unchanged, and events that aren't raids ignore ore-suffixed files. First user: `raid_shop`'s cellar cards (s_room, s_room_empty, s_room_guarded, s_claim_route and the cards after it), storyboarded in `.scratch/event-art/raid_shop/board.json` (S6, S13, S14, S19) with one lit vein colour per ore.

Update the event image asset contract (ADR 0005) and the "Asset path convention" in ui-vision §11 to name the ore-suffixed form, and add one line to the event-storyboard skill's Phase 5 so per-ore cards are placed under the suffixed names.

Out of scope: per-ore variants for choice-result images (explicit `image` on a choice). The harvested-vein result art is the same for every ore.

**Blocked by:** None — can start immediately.

**Relevant files:**
- `systems/raiding.gd` — `begin_raid()` builds the raid's event context (`site_id`, `securityProfile`, …)
- `systems/events.gd` — `current_image_path()`, `_convention_image_path()`, `_live_event_context()`
- `systems/sites.gd` — site `oreType`
- `docs/adr/0005-event-image-asset-contract.md`
- `docs/ui-vision.md` §11 "Asset path convention"
- `docs/REFERENCE.md` §3.12 (vein raids: "Raid event by location", "Security profile")
- `.claude/skills/event-storyboard/SKILL.md` Phase 5
- `tests/test_raid_shop.gd` (or a new `tests/test_event_images.gd`)
- `CODEMAP.md` if a file's responsibility changes

**Status:** ready-for-agent

- [ ] Starting a raid records the raided vein's ore in the event's state (pure data, no object references); Rewind restores it
- [ ] An ore-suffixed convention file is shown during a raid on a vein of that ore
- [ ] With no ore-suffixed file, the plain convention file is shown
- [ ] An explicit `image` key (including null) still wins over both
- [ ] A non-raid event never picks an ore-suffixed file
- [ ] ADR 0005, ui-vision §11 and event-storyboard Phase 5 describe the suffixed form
- [ ] Syntax check clean; `scripts/run_tests.sh` passes

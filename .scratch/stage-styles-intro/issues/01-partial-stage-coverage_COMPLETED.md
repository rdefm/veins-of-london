# 01 — Partial stage coverage

**What to build:** An event's stage can direct only its first N cards. While the player is on a staged card the live stage plays in the VN image slot exactly as today; on any card past the stage's last entry, the slot shows that card's normal image (or nothing, if the card has none) and the stage stops rendering. Going back (Rewind, resume from save, re-entering the event) onto a staged card brings the stage back in the correct derived state. Context: intro2/3/4 (tickets 05–07) stage only cards 1–6 of the intro and fall back to the existing card art for the Wetherspoons cards.

**Blocked by:** None — can start immediately.

**Relevant files:** `scenes/screens/event.gd` (VN frame, `_refresh_vn_card`), `scenes/stage/stage_player.gd` (`show_card`), `scenes/stage/stage_direction.gd`, `systems/events.gd` (`has_stage`, `is_vn_mode`, card image convention), `data/stages/archie_craft_chat.json`, `tests/test_stage.gd` (currently asserts one direction entry per card), `.scratch/stage-engine/ENGINE.md`, `CODEMAP.md`

**Status:** ready-for-agent

- [ ] A stage with fewer card entries than its event loads and passes the stage data tests; a stage with *more* entries than cards still fails them
- [ ] Staged cards render the stage; unstaged cards render their card image; moving back and forth between the two is clean (no leftover stage nodes, no stale image)
- [ ] An event whose stage is shorter than its cards stays in VN mode for the unstaged cards (same frame layout as a normally illustrated VN event)
- [ ] `archie_craft_chat` and `archie_craft_chat2/3/4` behave exactly as before
- [ ] ENGINE.md documents the partial-coverage rule

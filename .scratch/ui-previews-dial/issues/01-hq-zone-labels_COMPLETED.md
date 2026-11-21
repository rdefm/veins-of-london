# 01 — HQ ? zone labels

**What to build:** A small `?` chip on the HQ tab's room plate. Tapping it toggles a caption over every tappable zone on the current plate (Rest, Lab, Dial, door/security, noticeboard, etc.), so the player can see what each part of the image does. Zones that exist but are locked/unbuilt still get a caption, drawn dimmed. Tapping `?` again hides them. The toggle stays on across HQ visits for the session and resets on app restart — UI-local, never written to `GameState.state` or the save.

**Blocked by:** None — can start immediately.

**Relevant files:**
- `scenes/screens/hq.gd` (already has a "Debug regions" chip and sets the `rest` caption — place the `?` chip alongside; keep the debug toggle)
- `scenes/components/hq_diorama.gd` (region captions, polygon-centred caption placement, `zone_at`/`regions_at`)
- HQ plate/region data under `data/` (region ids, captions)
- `docs/ui-vision.md` (chip styling, typography)
- tests: `tests/test_hq*.gd`

**Status:** ready-for-agent

- [ ] `?` chip visible on the HQ plate, clear of the top bar and the debug chip
- [ ] Toggle on: every tappable region on the current tier's plate shows its caption; locked/unbuilt regions dimmed
- [ ] Toggle off hides all captions; zone taps behave identically in both states
- [ ] Toggle survives leaving/re-entering HQ within a session; not in game state/save
- [ ] Works on every home tier plate incl. bedsit fallback
- [ ] Test: captioned region set == tappable region set for a plate
- [ ] Any new caption strings flagged PROSE-REVIEW

# 01 — Branded directory and dossier route

**What to build:** Opening the phone app shows The Register's branded five-faction directory. Each compact row makes the player's relationship legible and opens that faction's existing full card on a separate dossier page. This first slice preserves all existing detail and actions while establishing the new navigation.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

**Relevant files:** `scenes/phone_apps/factions_app.gd`, `scenes/components/contact_cards.gd`, `systems/phone_apps.gd`, `systems/phone_nav.gd`, `scenes/components/app_tile.gd`, `assets/phone/icons/factions.png`, `data/palette.json`, `docs/ui-vision.md`, `tests/test_phone_apps.gd`, `tests/test_phone_nav.gd`, `docs/REFERENCE.md` §2 and §3.1 “Stances”, `CODEMAP.md`.

- [ ] Phone launcher label and in-app wordmark read “The Register”; launcher icon uses the five-node mark and keeps the 128×128 transparent PNG contract. Warm graphite and named oxide-orange brand colour match the approved spec; document the app-specific palette exception. Internal app id stays `factions`.
- [ ] Home has exactly five tappable rows in canonical order, showing faction identity, stored player stance, signed relation, a centred neutral −100..100 meter, and a concise live war/truce or pending-request alert where applicable. Stance is read independently of relation.
- [ ] Tapping any row opens its existing faction card with all current content and actions intact; Back returns to the five-row directory, and app Back returns to the phone grid. No unfinished secondary route appears yet. Refreshes keep the selected dossier and do not duplicate controls.
- [ ] Focused headless UI/navigation checks demonstrate the five rows, stance-versus-relation distinction, drill-in and Back behaviour, and preserved existing faction-card actions. Syntax checks and full Godot 4.7 suite pass. Report phone-width visual checks and any new UI copy as `PROSE-REVIEW:`.

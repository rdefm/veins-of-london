# 05 — Contact photos in Contacts and LodedInnit

**What to build:** Contacts show a rounded "photo" (pixel-art character headshot) in the Contacts app and in LodedInnit (feed authors, People rows, profile). The image comes from `assets/contacts/<contactId>.png` (the human supplies files later). If no file exists, show the current initial avatar.

**Blocked by:** None — can start immediately.

**Relevant files:** `scenes/screens/contacts.gd`, `scenes/components/contact_cards.gd`, `scenes/phone_apps/lodedinnit_app.gd`, `systems/contacts.gd`, `CODEMAP.md`

**Status:** ready-for-agent

- [ ] Shared avatar builder: circular crop, nearest filter (pixel art stays crisp)
- [ ] Used in the Contacts app and every LodedInnit avatar spot
- [ ] Missing image → initial fallback, no errors logged
- [ ] Test covers path lookup + fallback
- [ ] On-device check listed in report (drop one test PNG in)

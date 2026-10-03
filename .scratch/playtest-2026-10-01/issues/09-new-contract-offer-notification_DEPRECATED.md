# 09 — Notification when a new contract offer arrives

**What to build:** When a new BizBrief contract offer is issued (random or scripted), push a ticker notification (top-board row) and badge BizBrief, same mechanism as Owen's contact-tagged texts. Tapping through lands on BizBrief Manage.

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/offers.gd`, `systems/owen_texts.gd` (notification push pattern), `scenes/components/notification_ticker.gd`, `scenes/components/top_bar.gd`, `systems/phone_apps.gd` (badges), `systems/phone_nav.gd`.

**Status:** ready-for-agent

- [ ] Each new offer pushes one notification; test covers it
- [ ] BizBrief badge reflects unseen offers
- [ ] PROSE-REVIEW: notification string

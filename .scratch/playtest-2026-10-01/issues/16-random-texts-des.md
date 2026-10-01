# 16 — Random texts: Des

**What to build:** Des sends occasional random texts via the general contact-texts system: humorous, character-revealing, endearing — the same feel as Owen's. ~8–12 texts, each with reply choices; some replies grant a small reward suited to them (relation, small cash/item). Availability gate: only once Des is met; pause while unavailable. Interval chosen so contacts don't crowd each other.

**Blocked by:** 11 — Generalise Owen's random texts.

**Relevant files:** generalised texts system + data from 11, `data/owen_texts.json` (tone reference), `docs/CONTENT-GUIDE.md`, `reference/london-orichalchum.html` (Des's voice, if present), existing Des lines (grep `queue_pending("des"`), `systems/contacts.gd`, CONTEXT.md.

**Status:** ready-for-agent

- [ ] Text pool + config for Des; tests for gate and reward grants
- [ ] Tone per CONTENT-GUIDE: one dry line, no camera winks
- [ ] PROSE-REVIEW: all new Des text

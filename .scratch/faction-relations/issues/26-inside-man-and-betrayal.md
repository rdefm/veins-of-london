# 26 — Inside man and betrayal

**What to build:** Personal relationships cut across faction lines. Inside man: when the player's personal relation with a member is ≥ `insideManAt` (TBD) while the faction relation is in or below the Annoyed band, that member warns of their own faction's planned moves (reusing the partner warning plumbing), offers a back-channel truce negotiation, and gives a shop discount. Betrayal: a member at personal relation ≤ `betrayAt` may leak the player's stockpile location or raid timing to a rival, raising that rival's intel on the player.

**Blocked by:** 24 — Key member model; 11 — Network perks (shared warning path)

**Relevant files:** `systems/key_members.gd`, `systems/partners.gd` (warning plumbing), `systems/faction_ai.gd` (planned moves, truce), `systems/diplomacy.gd`, `systems/economy.gd` / `data/faction_trade.json` (discount), `systems/intel.gd`, tests: `test_key_members`, `test_partners`, `test_intel`. REFERENCE.md key members §.

**Status:** ready-for-agent

- [ ] Inside-man warnings fire for the member's faction's planned moves when the gates hold
- [ ] Back-channel truce offer is available through the member
- [ ] Shop discount applies on that faction's shop while gated
- [ ] Betrayal raises a rival's intel on the player (seeded chance), with a notice/headline where the spec implies one
- [ ] Strings `PROSE-REVIEW`

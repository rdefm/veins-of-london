# 75 — Vein raid: explicit "Defend" button

**What to build:** When an alarmed vein is raided, the player gets a warning notification telling them to go defend it — but there's no button anywhere to actually do that. Today the defend fight only auto-triggers if the player happens to arrive in that district (via travel or prospecting) before the next daily tick; otherwise it's an automatic loss. Add an explicit "Defend" button in two places — on the raided vein itself, and on the corresponding notification in the Phone's Notifications app — that jumps straight into the fight immediately, no travel required.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] A vein with a pending defend-raid shows a "Defend" button on its site sheet.
- [ ] The warning notification for a pending defend-raid has its own "Defend" button.
- [ ] Tapping either button starts the defend combat encounter immediately, regardless of the player's current location — no travel time or cost.
- [ ] The existing arrival-triggered path (travelling or prospecting into the district) still works as an alternative way to trigger the same fight.
- [ ] The existing expiry behaviour (auto-loss if the defend window passes without the player acting) is unchanged.
- [ ] Manual check noted for the human: get an alarmed vein raided, use the vein's Defend button once, and separately the notification's Defend button once (different playthroughs/veins), confirm both jump straight into the fight.

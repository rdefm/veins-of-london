# 16 — Allies fight on after player KO

**What to build:** Player KO happens only after the existing automatic Failsafe/Rewind checks. If it stands, the player leaves combat, the next friendly reinforcement enters, and allies resolve their turns automatically with no player commands. Healing Burst cannot bring the player back that fight. If allies defeat every enemy, the normal victory, rewards and raid outcome apply. If no friendly active or queued fighter can continue, the fight is a loss. After settlement following an ally-won victory or a loss, the player's HP is 10% of hpMax. Existing recruited-ally KO cooldowns are unchanged.

**Blocked by:** 14

**Relevant files:** `systems/combat.gd`, `systems/consumables.gd` (Healing Burst targeting), `scenes/screens/combat.gd`, `scenes/components/combat_command_dock.gd` (commands disabled), `systems/raiding.gd` (outcomes), `tests/test_combat.gd`, `tests/test_combat_screen.gd`. Update REFERENCE §3.7, §3.7a with the change.

**Status:** ready-for-agent

- [ ] Failsafe/Rewind still prevent KO first
- [ ] After KO, fight auto-resolves; dock accepts no commands
- [ ] Ally victory yields normal rewards/raid outcome; player at 10% HP
- [ ] No friendlies left → loss, player at 10% HP
- [ ] Healing Burst cannot target the KO'd player

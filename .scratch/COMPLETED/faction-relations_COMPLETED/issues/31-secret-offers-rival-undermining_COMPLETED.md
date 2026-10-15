# 31 — Secret offers: rework defection into a rival-undermining handover

**What to build:** Replaces the shipped ticket-27 defection. A faction contender who is close to the player and trailing their faction's leader secretly sends an offer: hand the player a faction vein on the sly. The member stays in their faction (not recruited). Accepting costs the player a little relation with the faction, raises the player's personal relation with the instigator a lot, raises the instigator's standing and lowers the current leader's. The existing succession challenge then does the rest. Repeatable on a per-member cooldown.

Undo from the 27 commit: recruit-on-accept, `factions[id].defected`, `craftSkillLoss` / `FactionSim.craft_skill`, the "weak or losing war" gate, the speciality and skill prizes, non-contender members (Hakim, Courier) having prizes.

Gates (all): contender seat (speaker/lieutenant), not the current leader, unlocked, personal relation ≥ threshold (`defectAt`, rename to fit), standing below the leader's. Values (relation hit, personal relation gain, standing +X / leader −Y, cooldown) in data, marked TBD.

**Blocked by:** None — can start immediately (builds on the ticket 27 commit).

**Relevant files:** `systems/key_members.gd` (`can_defect`/`defect`, `adjust_standing`), `systems/faction_incidents.gd` (`defection` trigger, `from` member notice), `systems/faction_sim.gd`, `systems/vein_trade.gd` (`transfer_from_faction`), `systems/events.gd` (`accept_defection` op), `autoload/GameData.gd` (allowed ops), `data/faction_incidents.json` (`personal`), `data/factions.json` (member `defection` prizes), `data/events/inc_defection.json`, `tests/test_key_members.gd`, `tests/fixtures/gamedata_pre_manifest_snapshot.gdvar`, `CODEMAP.md`. REFERENCE.md key members § "Defection" and "Standing and succession".

**Status:** ready-for-agent

- [x] Defection recruit/`defected`/craftSkill-loss/war-or-weak gate/speciality+skill prizes removed
- [x] Offer fires only for unlocked non-leader contenders at relation ≥ threshold and standing below the leader; per-member cooldown, repeatable
- [x] Accept hands over a faction vein; member is not recruited
- [x] Accept: faction relation falls a little, instigator personal relation rises a lot, instigator standing up, leader standing down
- [x] Decline changes nothing
- [x] Tests, REFERENCE and CODEMAP updated; placeholder card `PROSE-REVIEW`

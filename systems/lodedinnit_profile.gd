# LodedInnit candidate profile projection: the live facts the profile and its
# hire area show (role, level/cap, role-skill experience, wage, role-room seat
# context, hire block reason). Pure reads of Hiring/Home/Contacts.
class_name LodedInnitProfile
extends RefCounted


# Experience toward the next level as { xp, next }; next is -1 at the cap.
static func experience(candidate_id: String) -> Dictionary:
	var skill := Hiring.skill(candidate_id)
	var c: Dictionary = GameState.state["contacts"][candidate_id]
	var levels := Contacts.xp_levels(skill)
	var level := Hiring.level(candidate_id)
	var next := -1
	if level < Hiring.level_cap(candidate_id) and level + 1 < levels.size():
		next = int(levels[level + 1])
	return { "xp": int(c["%sXP" % skill]), "next": next }


# Role-room seat line: "Build the X first." when unbuilt, else "Y: used/total seats".
static func seat_text(candidate_id: String) -> String:
	var room_id: String = Hiring.role(candidate_id)["room"]
	var room_name: String = GameData.HOME_ROOMS[room_id]["name"]
	if not Home.has_room(room_id):
		return "%s not built" % room_name
	var total := Home.room_seats(room_id)
	var free := total - Contacts.room_seats_used(room_id)
	return "%s · %d of %d seats free" % [room_name, maxi(free, 0), total]


# Cultivator speciality bonus line; "" for roles whose specialities drive something else.
static func speciality_bonus_text(candidate_id: String) -> String:
	var data := Hiring.candidate(candidate_id)
	if data.get("role", "") != "cultivation" or (data.get("specialities", []) as Array).is_empty():
		return ""
	return "Prunes speciality ore at +%d%% yield." % roundi((GameData.CULTIVATOR_SPECIALITY_YIELD_MULT - 1.0) * 100.0)


static func experience_text(candidate_id: String) -> String:
	var e := experience(candidate_id)
	if e["next"] < 0:
		return "%d XP · max level" % e["xp"]
	return "%d / %d XP" % [e["xp"], e["next"]]

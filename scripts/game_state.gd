extends Node


var all_missions: Dictionary = {}
var active_missions: Dictionary = {}
var completed_missions: Array[String] = []
var campaign_flags: Dictionary = {}

func _ready() -> void:
	load_all_missions()

	EventBus.connect("object_interacted", _on_object_interacted)
	EventBus.connect("enemy_killed", _on_enemy_killed)
	EventBus.connect("location_reached", _on_location_reached)

func load_all_missions():
	var dir = DirAccess.open("res://missions/")

	if !dir:
		push_error("could not open missions folder. tf man!")
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		if file_name.ends_with(".tres"):
			var mission = load("res://missions/" + file_name) as Mission
			if mission && mission.id != "":
				all_missions[mission.id] = mission
				print("LOADED MISSION: ", mission.title)

				if mission.auto_start && mission.is_available():
					start_mission(mission.id)
		
		file_name = dir.get_next()

	dir.list_dir_end()

func start_mission(mission_id: String) -> bool:
	if !all_missions.has(mission_id):
		push_error("mission doesnt exist: " + mission_id)
		return false
	
	if active_missions.has(mission_id):
		print("MISSION ALREADY ACTIVE: " + mission_id)
		return false
	
	var mission: Mission = all_missions[mission_id]

	if !mission.is_available():
		print("MISSION NOT YET AVAILABLE: " + mission_id)
		return false
	
	active_missions[mission_id] = mission
	print("STARTED MISSION: " + mission.title)

	return true

func update_all_objectives(action_type: String, target: String):
	for mission_id in active_missions.keys():
		var mission: Mission = active_missions[mission_id]

		for objective in mission.objectives:
			if objective.is_complete() || objective.hidden:
				continue
			
			var matches = false

			match action_type:
				"interact":
					if objective.type == MissionObjective.ObjectiveType.INTERACT_WITH_OBJECT:
						matches = (objective.target == target)
				"kill":
					if objective.type == MissionObjective.ObjectiveType.KILL_ENEMIES:
						matches = (objective.target == target)
				"location":
					if objective.type == MissionObjective.ObjectiveType.REACH_LOCATION:
						matches = (objective.target == target)
			
			if matches:
				objective.progress(1)

				if objective.is_complete():
					EventBus.emit_signal("objective_complete", mission, objective)
					check_mission_complete(mission)

func check_mission_complete(mission: Mission):
	for objective in mission.objectives:
		if !objective.optional && !objective.is_complete():
			return
	
	complete_mission(mission)

func complete_mission(mission: Mission):
	active_missions.erase(mission.id)
	completed_missions.append(mission.id)

	for flag in mission.sets_flags_on_complete:
		set_flag(flag, true)
	
	EventBus.emit_signal("mission_complete", mission)

	check_for_new_missions()

func set_flag(flag: String, value: bool):
	campaign_flags[flag] = value

func has_flag(flag: String) -> bool:
	return campaign_flags.get(flag, false)

func check_for_new_missions():
	for mission_id in all_missions.keys():
		if completed_missions.has(mission_id) || active_missions.has(mission_id):
			continue
		
		var mission: Mission = all_missions[mission_id]

		if mission.is_available():
			if mission.auto_start:
				start_mission(mission_id)
			else:
				EventBus.emit_signal("mission_available", mission)

# When player interacts with an object
func _on_object_interacted(object_id: String):
	print("Object interacted: ", object_id)
	update_all_objectives("interact", object_id)

# When player kills an enemy
func _on_enemy_killed(enemy_type: String):
	print("Enemy killed: ", enemy_type)
	update_all_objectives("kill", enemy_type)

# When player reaches a location
func _on_location_reached(location_id: String):
	print("Location reached: ", location_id)
	update_all_objectives("location", location_id)

# When player talks to NPC
func _on_npc_talked(npc_id: String):
	print("NPC talked: ", npc_id)
	update_all_objectives("talk", npc_id)
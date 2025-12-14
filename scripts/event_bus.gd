extends Node

signal mission_started(mission: Mission)
signal mission_complete(mission: Mission)
signal mission_available(mission: Mission)
signal objective_complete(mission: Mission, objective: MissionObjective)

signal object_interacted(object_id: String)
signal enemy_killed(enemy_type: String)
signal location_reached(location_id: String)

signal show_message(message: String)
class_name Mission
extends Resource

@export var id: String = ""
@export var title: String = ""
@export_multiline var description: String = ""

@export var required_missions: Array[String] = []
@export var required_flags: Array[String] = []

@export var objectives: Array[MissionObjective] = []
@export var sets_flags_on_complete: Array[String] = []

@export var start_scene: PackedScene
@export var start_location: Vector2 = Vector2.ZERO

func is_available() -> bool:
    for mission_id in required_missions:
        if !GameState.completed_missions.has(mission_id):
            return false

    for flag in required_flags:
        if !GameState.campaign_flags.has(flag):
            return false
    
    return true
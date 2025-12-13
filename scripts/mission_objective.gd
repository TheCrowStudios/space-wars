class_name MissionObjective
extends Resource

enum ObjectiveType {
    KILL_ENEMIES,
    REACH_LOCATION,
    REACH_NODE,
    COLLECT_ITEMS,
    TRIGGER_EVENT,
    INTERACT_WITH_OBJECT,
    CUSTOM
}

@export var type: ObjectiveType
@export var description: String = ""
@export var target: String = ""
@export var required_count: int = 1
@export var optional: bool = false
@export var hidden: bool = false

var current_count: int = 0

func is_complete() -> bool:
    return current_count >= required_count

func progress(amount: int = 1):
    current_count = min(current_count + amount, required_count)
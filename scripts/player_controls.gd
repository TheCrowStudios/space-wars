extends Node

@onready var pawn: Character = get_parent()
var weapons_controller: WeaponsController

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pawn.move_direction_normalized = Vector2(Input.get_axis("move_left", "move_right"), Input.get_axis("move_up", "move_down")).normalized()
	pawn.aim_at = pawn.get_global_mouse_position()
	get_input()

func get_input():
	if weapons_controller:
		weapons_controller.aim(pawn.get_global_mouse_position())
		if Input.is_action_pressed("left_click"):
			weapons_controller.fire()
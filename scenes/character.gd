class_name Character
extends RigidBody2D

@export var movement_speed: int = 100
@export var is_player: bool = false

var move: Vector2

func _physics_process(delta: float) -> void:
    move_and_collide(move.normalized() * movement_speed * delta);
    look_at(get_global_mouse_position())

func _input(event: InputEvent) -> void:
    move = Vector2(Input.get_axis("move_left", "move_right"), Input.get_axis("move_up", "move_down"))
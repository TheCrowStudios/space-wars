class_name Character
extends CharacterBody2D

@export var movement_speed: int = 100
@export var is_player: bool = false

@onready var animations: AnimatedSprite2D = $AnimatedSprite2D

var move_direction_normalized: Vector2 = Vector2.ZERO
var aim_at: Vector2 = Vector2.ZERO

func _ready() -> void:
    animations.play("idle")

func _physics_process(delta: float) -> void:
    velocity = move_direction_normalized * movement_speed
    move_and_slide();
    look_at(get_global_mouse_position())
    if move_direction_normalized == Vector2.ZERO:
        animations.play("idle")
    else:
        animations.play("walk")


func _on_destructible_object_destroyed(node: DestructibleObject) -> void:
    pass # Replace with function body.
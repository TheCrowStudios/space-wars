extends RigidBody2D


@export var turn_strength: float = 10.0
@export var turn_damp: float = 2.0
@export var thrust: float = 300.0
@export var launch_speed: float = 100.0

var target: Node2D
var target_position: Vector2
var inherited_velocity: Vector2 = Vector2.ZERO

var parent_ref: Node

func set_parent_ref(parent: Node):
    parent_ref = parent

func get_parent_ref():
    return parent_ref

func _ready() -> void:
    linear_velocity = inherited_velocity + Vector2.RIGHT.rotated(rotation) * launch_speed
    print(linear_velocity)

func _physics_process(delta: float) -> void:
    if !target:
        target_position = global_position + linear_velocity * 100

    if target:
        target_position = target.global_position
        var angle_to_target = global_position.angle_to(target_position)
        var angle_diff = wrapf(angle_to_target - rotation, -PI, PI)

        var torque = angle_diff * turn_strength
        torque -= angular_velocity * turn_damp

        apply_torque(torque)
    apply_force(Vector2.RIGHT.rotated(rotation) * thrust)
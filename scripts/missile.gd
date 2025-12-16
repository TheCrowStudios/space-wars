extends RigidBody2D


@export var turn_strength: float = 10.0
@export var turn_damp: float = 2.0
@export var thrust: float = 300.0
@export var launch_speed: float = 100.0
@export var detonation_distance: float = 200.0
@export var blast: PackedScene
@export var explosion_particles: PackedScene
@export var radius: float = 300
@export var blast_force: float = 400
@export var blast_damage: float = 400

var target: Node2D
var target_position: Vector2
var inherited_velocity: Vector2 = Vector2.ZERO
var detonated = false

var parent_ref: Node

func set_parent_ref(parent: Node):
	parent_ref = parent

func get_parent_ref():
	return parent_ref

func _ready() -> void:
	linear_velocity = inherited_velocity + Vector2.RIGHT.rotated(rotation) * launch_speed
	# print(linear_velocity)

func _physics_process(delta: float) -> void:
	if detonated: return

	if !target:
		target_position = global_position + linear_velocity * 100

	if target:
		target_position = target.global_position
		# var angle_to_target = global_position.angle_to(target_position)
		var nav_constant = 5.0
		var to_target = target_position - global_position
		var los_rate = linear_velocity.cross(to_target) / max(to_target.length_squared(), 1.0)
		los_rate = clamp(los_rate, -10.0, 10.0)
		var desired_angular_velocity = nav_constant * los_rate
		desired_angular_velocity = clamp(desired_angular_velocity, -20.0, 20.0)
		var ang_vel_error = desired_angular_velocity - angular_velocity

		var angle_to_target = global_position.direction_to(target_position).angle()
		var angle_diff = wrapf(angle_to_target - rotation, -PI, PI)

		# var torque = angle_diff * turn_strength
		# torque -= angular_velocity * turn_damp

		var torque = ang_vel_error * turn_strength - angular_velocity * turn_damp

		# print("DISTANCE: ", global_position.distance_to(target_position))
		# print(global_position)
		# print(target_position)
		print(torque)
		apply_torque(torque)
		if global_position.distance_to(target_position) <= detonation_distance && !detonated:
			detonate()

	# print(rotation_degrees)
	# print(Vector2.RIGHT.rotated(rotation))
	apply_force(Vector2.RIGHT.rotated(rotation) * thrust)


func detonate():
	var explosion: ExplosionRadius = blast.instantiate()
	var particles: GPUParticles2D = explosion_particles.instantiate()

	explosion.radius = radius
	explosion.blast_force = blast_force
	explosion.blast_damage = blast_damage
	add_child(explosion)
	add_child(particles)
	particles.emitting = true

	detonated = true
	%ProjectileLifetimeController.reset_counter()
	%TrailParticles.emitting = false
	linear_damp = 20.0

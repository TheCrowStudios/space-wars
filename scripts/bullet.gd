class_name Bullet
extends CharacterBody2D

const VELOCITY_THRESHOLD = 50

var speed: int = 1600
var lifetime: int = 5000
var max_bounces: int = 3
var bounces_left: int = max_bounces
var push_force: float = 200.0
var bullet_type: Globals.BulletType = Globals.BulletType.MEDIUM
var penetration_left = Globals.bulletMaxPenetration[bullet_type]
var created_by: int = 0

var insantiation_time: int

var pre_collision_velocity: Vector2 = Vector2.ZERO

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	insantiation_time = Time.get_ticks_msec()
	$Sprite2D.look_at(global_position + velocity)
	# velocity = transform.x * speed
	# print(transform.x)
	# print(speed)
	# print(velocity)

func _process(delta: float) -> void:
	$Sprite2D.look_at(global_position + velocity)

func _physics_process(delta: float) -> void:
	pre_collision_velocity = velocity
	var collision = move_and_slide()

	if get_slide_collision_count() > 0:
		handle_collision()

	# position += transform.x * speed * delta
	if (Time.get_ticks_msec() - insantiation_time >= lifetime):
		$PointLight2D.energy = lerp($PointLight2D.energy, 0.0, 0.05)
		# $Sprite2D.modulate.a = lerp($PointLight2D.modulate.a, 0.0, 0.1)
		if ($PointLight2D.energy <= 0.1): queue_free() # TODO - fade

func handle_collision():
	if (pre_collision_velocity.length() <= VELOCITY_THRESHOLD): queue_free()
	var collision_info = get_last_slide_collision()

	if not collision_info: return

	var impact_normal: Vector2 = collision_info.get_normal()
	var incoming_velocity: Vector2 = pre_collision_velocity

	# var perpendicular_speed: float = abs(incoming_velocity.dot(impact_normal))
	var angle_cos: float = abs(impact_normal.dot(-incoming_velocity.normalized()))
	# print(perpendicular_speed)
	# print(pre_collision_velocity)
	# print(0.2 * incoming_velocity.length())


	var max_angle_rad: float = deg_to_rad(90.0 - 45.0)
	var max_cos: float = cos(max_angle_rad)

	# print(angle_cos)
	# print(max_cos)

	var collider = collision_info.get_collider()
	var is_destroyed = false
	if collider is DestructibleObject:
		is_destroyed = collider.is_destroyed

	if angle_cos < max_cos && !is_destroyed:
	# if perpendicular_speed < 0.8 * incoming_velocity.length():
		if bounces_left > 0:
			velocity = incoming_velocity.bounce(impact_normal)

			velocity *= 0.85
			bounces_left -= 1

			# var remainder = collision_info.get_remainder()
			# global_position += remainder

			# print("BOUNCE")
			# if collider.has_method("take_ricochet"):
			# if collider.destructibleObject:
			if collider is DestructibleObject:
				collider.take_ricochet(global_position, angle_cos, self)
			# if collider is RigidBody2D:
			# 	var body: RigidBody2D = collider

			# 	var point_of_impact: Vector2 = collision_info.get_position()
			# 	var offset: Vector2 = point_of_impact - body.global_position

				# body.apply_impulse(-impact_normal * push_force, offset)
			# else:
			# 	queue_free()
		else:
			queue_free()
	else:

		# if collider.destructibleObject:
		# if collider.has_method("take_hit"):
		if collider is DestructibleObject:
			var damage: float = max(penetration_left / Globals.bulletMaxPenetration[bullet_type] * Globals.bulletDamages[bullet_type], Globals.bulletDamages[bullet_type] / 4)
			print(damage)

			# if (collider.penetration_resistance > Globals.bulletPenetrations[bullet_type]):
			# 	damage /= 4

			collider.take_hit(bullet_type, collision_info.get_position(), self, damage)
			# print(collision_info.get_position())
			# print(pre_collision_velocity)
			print(global_position)
			if (collider.penetration_resistance <= Globals.bulletPenetrations[bullet_type] && penetration_left >= collider.penetration_cost):
				# global_position += pre_collision_velocity * 2.0
				add_collision_exception_with(collider)
				velocity = pre_collision_velocity
				penetration_left -= collider.penetration_cost
			else: queue_free()

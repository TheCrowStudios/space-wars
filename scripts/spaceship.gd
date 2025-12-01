extends RigidBody2D
# @onready var destructibleObject = preload("res://scripts/destructible_object.gd").new()

@export var steering_angle = 20
@export var engine_power = 2000
@export var friction = -10
@export var drag = -0.06
@export var max_speed_reverse = 800
@export var slip_speed = 400
@export var traction_fast = 2.5 # Traction factor when the car is moving fast (affects control)
@export var traction_slow = 10 # Traction factor when the car is moving slow (affects control)
@export var is_player = false
@export var enable_ai = true
@export var is_alive = true
@export var flyby_audio_streams: Array[AudioStream]

var boosters = []
var guns = []
var hp = 1000
const REGULAR_LINEAR_DAMP = 0.2
const REGULAR_ANGULAR_DAMP = 0.05
const COLLISION_DAMP = 100.0

var acceleration = Vector2.ZERO # Current acceleration vector
var steer_direction # Current direction of steering

var turn = 0
var acc = 0
var aim_at

var target: Node2D = null
var input_per_sec: int = 24
var input_cooldown: float = 0

# @onready var passBy: AudioStreamPlayer2D = $PassBy
const WALL_DEBRIS = preload("res://scenes/debris.tscn")

@export var is_active = true

func _ready() -> void:
	boosters = get_node(".").find_children("Booster" + "*")
	guns = get_node(".").find_children("Gun" + "*")
	aim_at = get_global_mouse_position()

	if (Globals.DEBUG):
		var crosshair = $Crosshair
		var crosshair_velocity = $CrosshairVelocity

		if crosshair:
			crosshair.visible = true

		if crosshair_velocity:
			crosshair.visible = true

	if (is_player):
		add_to_group("player")
		add_to_group("team1") # TODO - come up with teams names

func _process(delta: float) -> void:
	if is_alive:
		if is_player:
			if is_active:
				# $Camera2D.enabled = true
				get_input()
				interpret_input()
			else:
				# $Camera2D.enabled = false
				pass
		elif enable_ai:
			var players = get_tree().get_nodes_in_group("player")
			players = players.filter(func(player): return player.is_alive)

			if players.size() > 0:
				target = players[0]
			else: target = null

			if input_cooldown <= 0: generate_input()
			interpret_input()
			input_cooldown -= delta * input_per_sec
	else:
		for booster in boosters:
			booster.set_thrust(false)

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if state.get_contact_count() > 0:
		linear_damp = COLLISION_DAMP
		angular_damp = COLLISION_DAMP
	else:
		linear_damp = REGULAR_LINEAR_DAMP
		angular_damp = REGULAR_ANGULAR_DAMP

func get_input():
	turn = Input.get_axis("move_left", "move_right")
	acc = Input.get_axis("move_down", "move_up")

	aim_at = get_global_mouse_position()
	
	if (Input.is_action_pressed("left_click")):
		fire_guns()
		

func generate_input():
	if target != null:
		var error_position = target.global_position - global_position

		# TODO - we don't yet account for the offset of the guns duhhh
		# TODO - oh yeah, we need to account for distance travelled before hitting target as current velocity changes where the bullets will go as they travel
		aim_at = target.global_position + target.linear_velocity # account for target speed
		if (Globals.DEBUG):
			var crosshair = $CrosshairVelocity

			if crosshair:
				crosshair.global_position = aim_at
				crosshair.global_rotation = 0
		aim_at -= linear_velocity / 2 # account for velocity

		if (Globals.DEBUG):
			var crosshair = $Crosshair

			if crosshair:
				crosshair.global_position = aim_at
				crosshair.global_rotation = 0

		var distance_to_target_vec: Vector2 = target.global_position - global_position
		var distance_to_target = distance_to_target_vec.length()
		# print(distance_to_target)
		# print(distance_to_target.normalized())

		if (distance_to_target < 3000): fire_guns()

		var target_dir = distance_to_target_vec.normalized()
		var target_rotation = target_dir.angle()
		# print(rad_to_deg(target_rotation))

		var error_angle = wrapf(target_rotation - rotation, -PI, PI)

		var p_torque = error_angle * 1.0

		var d_damp = - angular_velocity * 0.2
		var final_torque = p_torque + d_damp

		turn = 1.0 * sign(final_torque)
		# print(turn)

		acc = 1
		input_cooldown = 1
	else:
		for booster in boosters:
			booster.set_thrust(false)

func interpret_input():
	steer_direction = turn * deg_to_rad(steering_angle)
	for booster: Node2D in boosters:
		booster.rotation = steer_direction

	if acc != 0:
		for booster in boosters:
			booster.set_thrust(true);
			if (acc == -1): booster.rotation += deg_to_rad(180);
	else:
		for booster in boosters:
			booster.set_thrust(false);

	for gun in guns:
		gun.look(aim_at)

func fire_guns():
	for gun in guns:
		gun.fire()

# func take_hit(bullet_type: Globals.BulletType, hit_point: Vector2):
# 	if bullet_type == Globals.BulletType.MEDIUM:
# 		hp -= 20
	
# 	impact.pitch_scale = randf_range(0.8, 1.0)
# 	impact.play()
# 	var wall_debris: GPUParticles2D = WALL_DEBRIS.instantiate()
# 	# wall_debris.global_position = global_position
# 	# wall_debris.position = position
# 	add_child(wall_debris)
# 	wall_debris.emitting = true

# func take_ricochet():
# 	ricochet.pitch_scale = randf_range(0.8, 1.0)
# 	ricochet.play()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Bullet && is_player && body.created_by != get_instance_id() && !flyby_audio_streams.is_empty():
		# print("PASS BY")
		var audio_stream = flyby_audio_streams.pick_random()
		var audio_player = AudioStreamPlayer2D.new()
		audio_player.stream = audio_stream
		add_child(audio_player)
		audio_player.volume_linear = abs((body.velocity - linear_velocity).length()) / 1600.0
		# print(audio_player.volume_linear)
		audio_player.play()
		await audio_player.finished
		audio_player.queue_free()


func _on_node_destroyed(node: DestructibleObject) -> void:
	if (node.get_parent() != self): return
	var random_dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	apply_impulse(random_dir * node.destruction_force)
	angular_velocity = random_dir.length()
	is_alive = false
	# if (node.name == "OxygenTank")

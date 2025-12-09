class_name Spaceship
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
@export var aim_error = 10.0

signal character_died(node: Spaceship)

var boosters = []
var guns = []
var hp = 1000

const MAX_REPAIR_DELAY: float = 1.0
const REGULAR_LINEAR_DAMP = 0.2
const REGULAR_ANGULAR_DAMP = 0.05
const COLLISION_DAMP = 100.0

var acceleration = Vector2.ZERO # Current acceleration vector
var steer_direction # Current direction of steering

var turn = 0
var acc = 0
var aim_at

# repairs
var repair_delay: float = MAX_REPAIR_DELAY
var time_to_repair_nodes: float = 0
var remaining_time_to_repair_nodes: float = 0
var destroyed_nodes_repairable: Array[DestructibleObject] = []
var nodes_to_repair: Array[DestructibleObject] = []
var all_boosters_destroyed: bool = false
var has_destroyed_gun: bool = false

var target: Spaceship = null
var target_position: Vector2 = Vector2.ZERO
var target_in_inner_radius: bool = false
var target_in_outer_radius: bool = false
var max_shot_at_cooldown: float = 5.0
var shot_at_cooldown: float = 0.0
var targetting_radius: int = 3000
var patrol_range: int = 1500
var input_per_sec: int = 24
var input_cooldown: float = 0

enum State {IDLE, PATROL, CHASE, ATTACK, RETREAT, REPAIRING}
var state: State = State.IDLE

# @onready var passBy: AudioStreamPlayer2D = $PassBy
const WALL_DEBRIS = preload("res://scenes/debris.tscn")

@export var is_active = true

func _ready() -> void:
	boosters = get_node(".").find_children("Booster" + "*")
	guns = get_node(".").find_children("Gun" + "*")
	aim_at = get_global_mouse_position()

	if (Globals.DEBUG && Globals.DEBUG_AIM):
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
				if state == State.REPAIRING:
					acc = 0
					turn = 0
					repair(delta)
				else:
					get_input(delta)
					interpret_input()
			else:
				# $Camera2D.enabled = false
				pass
		elif enable_ai:
			# var players = get_tree().get_nodes_in_group("player")
			# players = players.filter(func(player): return player.is_alive)

			# if players.size() > 0:
			# 	target = players[0]
			# else: target = null

			if input_cooldown <= 0:
				state_machine()

			if state == State.REPAIRING:
				if Globals.DEBUG && Globals.DEBUG_AI_STATE:
					print("REPAIRING")
				repair(delta)
			
			interpret_input()
			if (input_cooldown > 0): input_cooldown -= delta * input_per_sec
			if (shot_at_cooldown > 0): shot_at_cooldown -= delta
	else:
		for booster in boosters:
			booster.set_thrust(false)

func _physics_process(delta: float) -> void:
	# linear_velocity = clamp(linear_velocity, Vector2(-2000, -2000), Vector2(2000, 2000))
	pass

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if state.get_contact_count() > 0:
		linear_damp = COLLISION_DAMP
		angular_damp = COLLISION_DAMP
		print("COLLISION")
	else:
		linear_damp = REGULAR_LINEAR_DAMP
		angular_damp = REGULAR_ANGULAR_DAMP

func get_input(delta: float):
	turn = Input.get_axis("move_left", "move_right")
	acc = Input.get_axis("move_down", "move_up")

	aim_at = get_global_mouse_position()

	if (Input.is_action_pressed("repair")):
		if Globals.DEBUG && Globals.DEBUG_INPUTS:
			print("REPAIR BUTTON HELD")

		if destroyed_nodes_repairable.size() == 0: return
		repair_delay -= delta
		if repair_delay <= 0:
			start_repair()
	
	if (Input.is_action_just_released("repair")):
		repair_delay = MAX_REPAIR_DELAY
	
	if (Input.is_action_pressed("left_click")):
		fire_guns()
	
func start_repair():
	if (is_player): Popups.hide_message_popup()
	state = State.REPAIRING
	nodes_to_repair = destroyed_nodes_repairable

	time_to_repair_nodes = 0
	for node: DestructibleObject in nodes_to_repair:
		time_to_repair_nodes += node.repair_time
	
	remaining_time_to_repair_nodes = time_to_repair_nodes

func repair(delta: float):
	if (is_player):
		Popups.show_repair_progress()
		Popups.set_repair_progress(100.0 - (remaining_time_to_repair_nodes / time_to_repair_nodes * 100))
		Popups.set_repair_progress_seconds(remaining_time_to_repair_nodes)
	
	remaining_time_to_repair_nodes -= delta

	if (remaining_time_to_repair_nodes <= 0):
		for node: DestructibleObject in nodes_to_repair:
			node.repair()
		
		nodes_to_repair.clear()

		destroyed_nodes_repairable = destroyed_nodes_repairable.filter(func (node: DestructibleObject): return node.destroyed)
		state = State.IDLE

		Popups.hide_repair_progress()
		
func generate_input(move: bool, fire: bool):
	# var error_position = target.global_position - global_position
	var distance_to_target_vec: Vector2 = target_position - global_position
	var distance_to_target = distance_to_target_vec.length()
	# print(distance_to_target)
	# print(distance_to_target.normalized())

	if (distance_to_target < targetting_radius && target != null && target.is_alive && fire): fire_guns()

	var target_dir = distance_to_target_vec.normalized()
	var target_rotation = target_dir.angle()
	# print(rad_to_deg(target_rotation))

	var error_angle = wrapf(target_rotation - rotation, -PI, PI)

	var p_torque = error_angle * 1.0

	var d_damp = - angular_velocity * 0.1
	var final_torque = p_torque + d_damp

	# print(turn)

	if move:
		turn = 1.0 * sign(final_torque)
		acc = 1
	else:
		turn = 0
		acc = 0

	input_cooldown = 1

	if (Globals.DEBUG && Globals.DEBUG_AI):
		var crosshair = $CrosshairVelocity

		if crosshair:
			crosshair.global_position = target_position
			crosshair.global_rotation = 0

func state_machine():
	# if Globals.DEBUG && Globals.DEBUG_AI_STATE:
	# 	print(state)

	match state:
		State.IDLE:
			idle()
		State.PATROL:
			patrol()
		State.CHASE:
			chase()
		State.ATTACK:
			attack()
		State.RETREAT:
			retreat()
		State.REPAIRING:
			pass

func idle():
	acc = 0
	turn = 0

	if destroyed_nodes_repairable.size() > 0:
		if !target_in_inner_radius:# check if its safe
			start_repair()
			state = State.REPAIRING
			return

	if randf() < 0.1 / float(input_per_sec) && !all_boosters_destroyed:
		target_position.x = global_position.x + randi_range(-patrol_range, patrol_range)
		target_position.y = global_position.y + randi_range(-patrol_range, patrol_range)
		state = State.PATROL

func patrol():
	if (global_position - target_position).length() < 200:
		state = State.IDLE
	else:
		generate_input(true, false)

func chase():
	if Globals.DEBUG && Globals.DEBUG_AI_STATE:
		print("CHASING TARGET")

	if target != null && target.is_alive: # TODO - use main boosters
		target_position = target.global_position
		aim()
		generate_input(true, false)
		if target_in_inner_radius: state = State.ATTACK
	else:
		state = State.IDLE

# TODO - avoid shooting allies
# TODO - avoid collisions
# TODO - add personalities
func attack():
	if Globals.DEBUG && Globals.DEBUG_AI_STATE:
		print("ATTACKING TARGET")

	if target != null && target.is_alive:
		target_position = target.global_position
		aim()
		# TODO - some enemies stand still while firing unless shot at
		generate_input(true, true)
		if !target_in_inner_radius && target_in_outer_radius: state = State.CHASE
	else:
		state = State.IDLE

func retreat():
	# TODO - retreat if damaged
	pass

func aim():
	# TODO - we don't yet account for the offset of the guns duhhh
	# TODO - oh yeah, we need to account for distance travelled before hitting target as current velocity changes where the bullets will go as they travel
	aim_at = target.global_position + target.linear_velocity # account for target speed
	if (Globals.DEBUG && Globals.DEBUG_AIM):
		var crosshair = $CrosshairVelocity

		if crosshair:
			crosshair.global_position = aim_at
			crosshair.global_rotation = 0

	aim_at -= linear_velocity / 2 # account for spaceship velocity

	aim_at.x += randf_range(-aim_error, aim_error)
	aim_at.y += randf_range(-aim_error, aim_error)

	if (Globals.DEBUG && Globals.DEBUG_AIM):
		var crosshair = $Crosshair

		if crosshair:
			crosshair.global_position = aim_at
			crosshair.global_rotation = 0

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
	angular_velocity = random_dir.length()


func _on_character_static_character_died() -> void:
	is_alive = false
	emit_signal("character_died", self)


func _on_target_area_body_entered(body: Node2D) -> void:
	if body is Spaceship:
		if body.is_player && body.is_alive:
			if Globals.DEBUG && Globals.DEBUG_AI:
				print("PLAYER DETECTED. ATTACKING")
			if state == State.IDLE || state == State.PATROL || state == State.CHASE:
				target = body
				state = State.ATTACK
				target_in_inner_radius = true
				target_in_outer_radius = true
	elif body is Bullet:
		shot_at_cooldown = max_shot_at_cooldown
		if state != State.ATTACK && state != State.REPAIRING:
			state = State.CHASE

func _on_target_detection_area_body_exited(body: Node2D) -> void:
	if target == body:
		state = State.CHASE # chase target if its in outer circle
		target_in_inner_radius = false

func _on_wide_target_detection_area_body_entered(body: Node2D) -> void:
	if body is Spaceship:
		if body.is_player && body.is_alive:
			target = body
			target_in_outer_radius = true

func _on_wide_target_detection_area_body_exited(body: Node2D) -> void:
	if target == body:
		target = null
		target_in_inner_radius = false
		target_in_outer_radius = false
		if state != State.REPAIRING: state = State.IDLE

func _on_booster_destroyed(node: DestructibleObject) -> void:
	destroyed_nodes_repairable.push_back(node)
	if is_player: Popups.message_popup()
	var destroyed_boosters_count: int = 0
	var destroyed_boosters = boosters.filter(func(booster): return booster.destroyed)

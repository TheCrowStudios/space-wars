class_name SpaceshipAIBrains
extends Node


@onready var pawn: Spaceship = get_parent()

var input_per_sec: int = 24
var input_cooldown: float = 0

var target: Spaceship = null
var target_position: Vector2 = Vector2.ZERO
var target_in_inner_radius: bool = false
var target_in_outer_radius: bool = false
var max_shot_at_cooldown: float = 5.0
var shot_at_cooldown: float = 0.0
var targetting_radius: int = 3000
var patrol_range: int = 1500
var aim_error = 10.0

enum State {IDLE, PATROL, CHASE, ATTACK, RETREAT, REPAIRING}
var state: State = State.IDLE

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if input_cooldown <= 0:
		state_machine()

	if state == State.REPAIRING:
		if Globals.DEBUG && Globals.DEBUG_AI_STATE:
			print("REPAIRING")
	
	if (input_cooldown > 0): input_cooldown -= delta * input_per_sec
	if (shot_at_cooldown > 0): shot_at_cooldown -= delta

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
	pawn.acc = 0
	pawn.turn = 0

	# TODO - enemy wont repair if its not being shot at but player is still in wide detection area as it still tries to chase it
	# repair whenever not in immediate danger
	if pawn.destroyed_nodes_repairable.size() > 0:
		if !target_in_inner_radius:# check if its safe
			pawn.start_repair()
			state = State.REPAIRING
			return

	if randf() < 0.1 / float(input_per_sec) && !pawn.all_boosters_destroyed:
		target_position.x = pawn.global_position.x + randi_range(-patrol_range, patrol_range)
		target_position.y = pawn.global_position.y + randi_range(-patrol_range, patrol_range)
		state = State.PATROL

func patrol():
	if (pawn.global_position - target_position).length() < 200:
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
	pawn.aim_at = target.global_position + target.linear_velocity # account for target speed
	if (Globals.DEBUG && Globals.DEBUG_AIM):
		var crosshair = $CrosshairVelocity

		if crosshair:
			crosshair.global_position = pawn.aim_at
			crosshair.global_rotation = 0

	pawn.aim_at -= pawn.linear_velocity / 2 # account for spaceship velocity

	pawn.aim_at.x += randf_range(-aim_error, aim_error)
	pawn.aim_at.y += randf_range(-aim_error, aim_error)

	if (Globals.DEBUG && Globals.DEBUG_AIM):
		var crosshair = $Crosshair

		if crosshair:
			crosshair.global_position = pawn.aim_at
			crosshair.global_rotation = 0

func generate_input(move: bool, fire: bool):
	# var error_position = target.global_position - global_position
	var distance_to_target_vec: Vector2 = target_position - pawn.global_position
	var distance_to_target = distance_to_target_vec.length()
	# print(distance_to_target)
	# print(distance_to_target.normalized())

	if (distance_to_target < targetting_radius && target != null && target.is_alive && fire): pawn.fire_guns()

	var target_dir = distance_to_target_vec.normalized()
	var target_rotation = target_dir.angle()
	# print(rad_to_deg(target_rotation))

	var error_angle = wrapf(target_rotation - pawn.rotation, -PI, PI)

	var p_torque = error_angle * 1.0

	var d_damp = - pawn.angular_velocity * 0.1
	var final_torque = p_torque + d_damp

	# print(turn)

	if move:
		pawn.turn = 1.0 * sign(final_torque)
		pawn.acc = 1
	else:
		pawn.turn = 0
		pawn.acc = 0

	input_cooldown = 1

	if (Globals.DEBUG && Globals.DEBUG_AI):
		var crosshair = $CrosshairVelocity

		if crosshair:
			crosshair.global_position = target_position
			crosshair.global_rotation = 0

func _on_target_detection_area_body_entered(body: Node2D) -> void:
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

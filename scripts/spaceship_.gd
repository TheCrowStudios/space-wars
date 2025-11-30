extends CharacterBody2D

@export var steering_angle = 15
@export var engine_power = 2000
@export var friction = -10
@export var drag = -0.06
@export var braking = -450
@export var max_speed_reverse = 800
@export var slip_speed = 400
@export var traction_fast = 2.5 # Traction factor when the car is moving fast (affects control)
@export var traction_slow = 10 # Traction factor when the car is moving slow (affects control)

var boosters = []

var wheel_base = 65 # Distance between the front and back axle of the car
var acceleration = Vector2.ZERO # Current acceleration vector
var steer_direction # Current direction of steering

@export var is_active = true

func _ready() -> void:
	print_tree()
	boosters = get_node(".").find_children("Booster" + "*")

func _physics_process(delta: float) -> void:
	if is_active:
		$Camera2D.enabled = true
		acceleration = Vector2.ZERO
		get_input()
		calculate_steering(delta)
	else:
		$Camera2D.enabled = false

	apply_friction(delta)
	velocity += acceleration * delta;
	move_and_slide()

	# var inputVector = Vector2.ZERO
	# inputVector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	# inputVector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	# inputVector = inputVector.normalized()

	# velocity = velocity.lerp(inputVector * SPEED, acceleration)
	# move_and_slide()
	# look_at(get_global_mouse_position())

func get_input():
	var turn = Input.get_axis("move_left", "move_right")
	steer_direction = turn * deg_to_rad(steering_angle)

	if Input.is_action_pressed("move_up"):
		acceleration = transform.x * engine_power;
		for booster in boosters:
			booster.set_thrust(true);
	else:
		for booster in boosters:
			booster.set_thrust(false);
	
	if Input.is_action_pressed("move_down"):
		acceleration = transform.x * braking;

func apply_friction(delta):
	if acceleration == Vector2.ZERO and velocity.length() < 50:
		velocity = Vector2.ZERO
	
	var friction_force = velocity * friction * delta
	var drag_force = velocity * velocity.length() * drag * delta
	acceleration += drag_force + friction_force
	print(str(friction_force) + " " + str(drag_force) + " " + str(acceleration))

func calculate_steering(delta):
	var rear_wheel = position - transform.x * wheel_base / 2.0
	var front_wheel = position + transform.x * wheel_base / 2.0
	# print("" + str(rear_wheel) + " " + str(front_wheel))
	rear_wheel += velocity * delta
	front_wheel += velocity.rotated(steer_direction) * delta
	var new_heading: Vector2 = rear_wheel.direction_to(front_wheel)

	var traction = traction_slow
	if velocity.length() > slip_speed:
		traction = traction_fast
	
	var d = new_heading.dot(velocity.normalized())

	if d > 0:
		velocity = lerp(velocity, new_heading * velocity.length(), traction * delta)

	if d < 0:
		velocity = - new_heading * min(velocity.length(), max_speed_reverse)
	
	rotation = new_heading.angle()

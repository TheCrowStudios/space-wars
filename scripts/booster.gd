extends Node2D


enum State {OFF, STARTING, RUNNING, STOPPING, OVERHEATING, DESTROYED}
var state = State.OFF

@export var power = 300

signal destroyed(node: DestructibleObject)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$AnimatedSprite2D.play('default')

func _process(delta: float) -> void:
	if Globals.DEBUG:
		if Input.is_action_just_pressed("ui_end"):
			$DestructibleBody.take_damage(1000)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	# print(global_transform.x)
	if state == State.STARTING || state == State.RUNNING:
		var factor = 1.0 if state == State.RUNNING else 0.25 # force multiplicator
		# var forward_vector = Vector2.UP.rotated(global_rotation)
		var ship: RigidBody2D = get_parent()
		ship.apply_central_force(global_transform.x * power * factor)
		if (rotation_degrees <= 90): ship.apply_torque(deg_to_rad(rotation_degrees) * 10 * factor)
		else: ship.apply_torque(deg_to_rad(rotation_degrees - 180) * 10 * factor)
	
func set_animation():
	match state:
		State.OFF:
			$AnimatedSprite2D.play('default')
		
		State.STARTING:
			if $AnimatedSprite2D.animation != 'startup': $AnimatedSprite2D.play('startup')
		
		State.RUNNING:
			if $AnimatedSprite2D.animation != 'running': $AnimatedSprite2D.play('running')

		State.STOPPING:
			if $AnimatedSprite2D.animation != 'stopping': $AnimatedSprite2D.play('stopping')

		State.DESTROYED:
			$AnimatedSprite2D.play('default')

func set_thrust(active: bool):
	match state:
		State.OFF:
			if active:
				state = State.STARTING
		
		State.STARTING:
			if !active:
				state = State.OFF
		
		State.RUNNING:
			if !active:
				state = State.STOPPING

		State.STOPPING:
			if active:
				state = State.STARTING
		
		State.DESTROYED:
			pass

	set_animation()
	
func _on_animated_sprite_2d_animation_finished() -> void:
	if $AnimatedSprite2D.animation == 'startup':
		state = State.RUNNING
		set_animation()


func _on_destructible_body_destroyed(node: DestructibleObject) -> void:
	state = State.DESTROYED
	set_thrust(0)
	emit_signal("destroyed", node)


func _on_destructible_body_repaired(node: DestructibleObject) -> void:
	state = State.OFF

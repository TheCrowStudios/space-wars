extends Node2D

@export var max_rotation_deg := Vector2(-160, 15)
@export var rpm = 600
var cooldown: float = 0.0

const BULLET = preload("res://scenes/bullet.tscn")

@onready var sound_node: AudioStreamPlayer2D = $Shoot
@onready var muzzle: Marker2D = $Marker2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func init(max_rot: Vector2):
	max_rotation_deg = max_rot

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if (cooldown > 0): cooldown -= delta; # reduce cooldown by 1 every second

func look(pos: Vector2):
	look_at(pos)
	if (rotation_degrees < max_rotation_deg.x): rotation_degrees = max_rotation_deg.x
	if (rotation_degrees > max_rotation_deg.y): rotation_degrees = max_rotation_deg.y
	# rotation_degrees = wrap(rotation_degrees, max_rotation_deg.x, max_rotation_deg.y)
	# var angle_to_mouse = rad_to_deg(global_position.angle_to(get_global_mouse_position()))
	# print(global_position)
	# print(get_global_mouse_position())
	# print(angle_to_mouse)


func fire() -> void:
	# var angle_to_mouse = rad_to_deg(global_position.angle_to(get_global_mouse_position()))
	# var diff = wrapf(angle_to_mouse - rotation_degrees, -180.0, 180.0)
	# print(diff)
	# if (diff < max_rotation_deg.x || diff > max_rotation_deg.y): return
	if (cooldown <= 0 && rotation_degrees >= max_rotation_deg.x + 1 && rotation_degrees <= max_rotation_deg.y - 1):
		var bullet_instance: Node2D = BULLET.instantiate()
		# bullet_instance.rotation = rotation
		# bullet_instance.global_rotation = global_rotation
		# bullet_instance.speed += int(get_parent().linear_velocity.dot(Vector2.RIGHT.rotated(rotation)) + (get_parent().linear_velocity.abs().x + get_parent().linear_velocity.abs().y))
		# bullet_instance.speed += int(get_parent().linear_velocity.dot(Vector2.RIGHT.rotated(rotation)) + (get_parent().linear_velocity.abs().x + get_parent().linear_velocity.abs().y))
		# bullet_instance.velocity = Vector2(bullet_instance.speed, bullet_instance.speed) * bullet_instance.transform.x + get_parent().linear_velocity
		bullet_instance.created_by = get_parent().get_instance_id()
		bullet_instance.velocity = Vector2(bullet_instance.speed, bullet_instance.speed) * global_transform.x + get_parent().linear_velocity
		bullet_instance.global_position = muzzle.global_position
		get_tree().root.add_child(bullet_instance)
		# bullet_instance.speed += get_parent().linear_velocity.abs().x + get_parent().linear_velocity.abs().y
# 
		sound_node.pitch_scale = randf_range(0.8, 1.0)
		sound_node.play();
		cooldown = 60.0 / rpm # set cooldown in secs based on rpm

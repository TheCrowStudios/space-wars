class_name Weapon
extends Node2D

@export var weapon_group: int = 1
@export var max_rotation_deg := Vector2(-180, 0)
@export var rpm = 600
@export var bullet: PackedScene
@export var locking: bool = false
@export var limit_rotation: bool = true
# @export var limit_rotation_based_on_set_values: bool = true
@export var limit_rotation_based_on_collision: bool = true # ignores max_rotation_deg if true
@export var flip: bool = false
@export var energy_points: int = 2

var target: Node2D

var cooldown: float = 0.0

@onready var sound_node: AudioStreamPlayer2D = $Shoot
@onready var muzzle: Marker2D = %Muzzle

var parent_ref: Node

func set_parent_ref(parent: Node):
	parent_ref = parent

func get_parent_ref():
	return parent_ref

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func init(max_rot: Vector2):
	max_rotation_deg = max_rot

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if (cooldown > 0): cooldown -= delta; # reduce cooldown by 1 every second

func look(pos: Vector2):
	if limit_rotation:
		if !limit_rotation_based_on_collision:
			look_at(pos)
			if (rotation_degrees < max_rotation_deg.x): rotation_degrees = max_rotation_deg.x
			if (rotation_degrees > max_rotation_deg.y): rotation_degrees = max_rotation_deg.y
		else:
			if !%ProjectileCollisionChecker.would_collide((pos - global_position).angle() - rotation): look_at(pos) # TODO - verify
	else:
		rotation_degrees = wrapf(rotation_degrees, -180, 180)
		$Sprite2D.flip_v = rotation_degrees > 90 || rotation_degrees < -90
	# rotation_degrees = wrap(rotation_degrees, max_rotation_deg.x, max_rotation_deg.y)
	# var angle_to_mouse = rad_to_deg(global_position.angle_to(get_global_mouse_position()))
	# print(global_position)
	# print(get_global_mouse_position())
	# print(angle_to_mouse)


func fire() -> void:
	if %ProjectileCollisionChecker.is_blocked(): return

	if (limit_rotation && !(rotation_degrees >= max_rotation_deg.x + 1 && rotation_degrees <= max_rotation_deg.y - 1)): return

	if (cooldown <= 0):
		var bullet_instance: Node2D = bullet.instantiate()
		if parent_ref:
			bullet_instance.set_parent_ref(parent_ref)
			bullet_instance.inherited_velocity = parent_ref.linear_velocity
		bullet_instance.global_rotation = global_rotation
		bullet_instance.global_position = muzzle.global_position
		if locking:
			bullet_instance.target = target
		# bullet_instance.bullet_type = Globals.BulletType.MEDIUM
		get_tree().root.add_child(bullet_instance)

		sound_node.pitch_scale = randf_range(0.8, 1.0)
		sound_node.play();
		cooldown = 60.0 / rpm # set cooldown in secs based on rpm

extends Node2D


@export var max_zoom: float = 2.0
@export var min_zoom: float = 0.5
@export var max_shift: int = 400

var target_zoom: float = 1.0
var target_shift: Vector2 = Vector2.ZERO
var move_camera_to_mouse: bool = false
var camera: Camera2D

func _ready():
	camera = get_viewport().get_camera_2d()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	camera.zoom.x = lerp(camera.zoom.x, target_zoom, 0.1)
	camera.zoom.y = camera.zoom.x
	camera.global_rotation_degrees = 0
	camera.rotation_degrees = 0

	if move_camera_to_mouse:
		target_shift = get_global_mouse_position() - camera.global_position
		target_shift = target_shift.clamp(Vector2(-max_shift, -max_shift), Vector2(max_shift, max_shift))
	else:
		target_shift = Vector2.ZERO

	camera.position = lerp(camera.position, target_shift, 0.1)

	var zoom_factor = camera.zoom
	var inverse_zoom = Vector2(1.0 / zoom_factor.x, 1.0 / zoom_factor.y)
	# print(camera.zoom)

	# for child in get_children():
	# 	# print(typeof(child))
	# 	if child is ParallaxLayer:
	# 		child.get_child(0).scale = inverse_zoom
	# 		print(child.scale)

	$ParallaxBackground.scale = inverse_zoom

	var volume = linear_to_db(camera.zoom.x) * 1.5

	# volume = min(volume, 0.0)
	volume = clamp(volume, -24.0, 0.0)
	# print(volume)

	AudioServer.set_bus_volume_db(0, volume)

func _input(event: InputEvent) -> void:
	var zoom = false

	if event.is_action_pressed("mouse_wheel_up"):
		zoom = true
		if target_zoom < max_zoom:
			target_zoom += 0.1
	
	if event.is_action_pressed("mouse_wheel_down"):
		zoom = true
		if target_zoom > min_zoom:
			target_zoom -= 0.1
	
	if event.is_action_pressed("shift"):
		move_camera_to_mouse = true

	if event.is_action_released("shift"):
		move_camera_to_mouse = false
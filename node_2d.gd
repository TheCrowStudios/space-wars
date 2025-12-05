extends Node2D


@export var max_zoom: float = 2.0
@export var min_zoom: float = 0.5
@export var max_shift: int = 400

@onready var map_canvas: CanvasLayer = get_node("MapCanvas")
@onready var map_icons: Node2D = map_canvas.get_node("MapIcons")

var target_zoom: float = 1.0
var target_shift: Vector2 = Vector2.ZERO
var move_camera_to_mouse: bool = false
var camera: Camera2D
var on_map: Array
var map_update = false

func _ready():
	camera = get_viewport().get_camera_2d()
	print(camera.global_position)
	print(camera.position)
	camera.position.x += 10
	print(camera.global_position)
	print(camera.position)
	# for child in get_children():
	# 	if child.is_in_group("OnMap"):
	# 		on_map.append(child)
			

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	camera.zoom.x = lerp(camera.zoom.x, target_zoom, 0.1)
	camera.zoom.y = camera.zoom.x
	camera.global_rotation_degrees = 0
	camera.rotation_degrees = 0

	if camera.zoom.x <= 0.2:
		map_canvas.show()
		get_viewport().set_canvas_cull_mask_bit(0, false)
		get_viewport().set_canvas_cull_mask_bit(1, true)
		map_update = false

		for node: Node2D in on_map:
			if is_instance_valid(node):
				# var map_icon = node.map_icon_instance
				print("SHOW ICON")
				node.show()

				# var viewport_size = get_viewport_rect().size
				# var world_pos = node.global_position
				# var world_width = 10000.0
				# var world_height = 10000.0
				# var world_origin = $Spaceship.global_position
				# var normalized_x = (world_pos.x - (world_origin.x - world_width / 2.0)) / world_width
				# var normalized_y = (world_pos.y - (world_origin.y - world_height / 2.0)) / world_height

				# node.position = Vector2(normalized_x * viewport_size.x, normalized_y * viewport_size.y)
				print(node.global_position)
				print(node.position)
	else:
		# map_canvas.hide()
		get_viewport().set_canvas_cull_mask_bit(0, true)
		get_viewport().set_canvas_cull_mask_bit(1, false)
		
		for node: Node2D in on_map:
			if is_instance_valid(node):
				# print(node.global_position)
				# node.map_icon_instance.hide()
				pass

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

func register_map_icon(node):
	on_map.append(node)

func _input(event: InputEvent) -> void:
	var zoom = false

	if event.is_action_pressed("mouse_wheel_up"):
		zoom = true
		if target_zoom < max_zoom:
			target_zoom += 0.1
			target_zoom = min(target_zoom, max_zoom)
	
	if event.is_action_pressed("mouse_wheel_down"):
		zoom = true
		if target_zoom > min_zoom:
			target_zoom -= 0.1
			target_zoom = max(target_zoom, min_zoom)
			map_update = true
	
	if event.is_action_pressed("shift"):
		move_camera_to_mouse = true

	if event.is_action_released("shift"):
		move_camera_to_mouse = false

func _on_spaceship_character_died() -> void:
	target_zoom = 2.0
	target_shift = Vector2.ZERO

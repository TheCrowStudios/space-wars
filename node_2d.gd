extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

@export var max_zoom: Vector2 = Vector2(2.0, 2.0)
@export var min_zoom: Vector2 = Vector2(0.5, 0.5)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _input(event: InputEvent) -> void:
	var zoom = false

	if event.is_action_pressed("mouse_wheel_up"):
		zoom = true
		var camera: Camera2D = get_viewport().get_camera_2d()
		if camera.zoom < max_zoom:
			camera.zoom += Vector2(0.1, 0.1)
	
	if event.is_action_pressed("mouse_wheel_down"):
		zoom = true
		var camera: Camera2D = get_viewport().get_camera_2d()
		if camera.zoom > min_zoom:
			camera.zoom -= Vector2(0.1, 0.1)

	if (zoom):
		var camera: Camera2D = get_viewport().get_camera_2d()
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
		print(volume)

		AudioServer.set_bus_volume_db(0, volume)

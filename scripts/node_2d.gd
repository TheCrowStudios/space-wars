extends Node2D


@onready var map_canvas: CanvasLayer = get_node("MapCanvas")
@onready var map_icons: Node2D = map_canvas.get_node("MapIcons")

const SPACESHIP: PackedScene = preload("res://scenes/spaceship.tscn")
const MAP_ENEMY_DOT: PackedScene = preload("res://scenes/map_enemy_dot.tscn")

var on_map: Array

var spaceships_minimap: Dictionary = {}

func _ready():
	# for child in get_children():
	# 	if child.is_in_group("OnMap"):
	# 		on_map.append(child)
	generate_minimap()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if %CameraController.get_zoom().x <= 0.2:
		map_canvas.show()
		get_viewport().set_canvas_cull_mask_bit(0, false)
		get_viewport().set_canvas_cull_mask_bit(1, true)

		for node: Node2D in on_map:
			if is_instance_valid(node):
				# var map_icon = node.map_icon_instance
				# print("SHOW ICON")
				node.show()

				# var viewport_size = get_viewport_rect().size
				# var world_pos = node.global_position
				# var world_width = 10000.0
				# var world_height = 10000.0
				# var world_origin = $Spaceship.global_position
				# var normalized_x = (world_pos.x - (world_origin.x - world_width / 2.0)) / world_width
				# var normalized_y = (world_pos.y - (world_origin.y - world_height / 2.0)) / world_height

				# node.position = Vector2(normalized_x * viewport_size.x, normalized_y * viewport_size.y)
				# print(node.global_position)
				# print(node.position)
	else:
		# map_canvas.hide()
		get_viewport().set_canvas_cull_mask_bit(0, true)
		get_viewport().set_canvas_cull_mask_bit(1, false)
		
		for node: Node2D in on_map:
			if is_instance_valid(node):
				# print(node.global_position)
				# node.map_icon_instance.hide()
				pass

	# print(camera.zoom)

	# for child in get_children():
	# 	# print(typeof(child))
	# 	if child is ParallaxLayer:
	# 		child.get_child(0).scale = inverse_zoom
	# 		print(child.scale)

	# $ParallaxBackground.scale = inverse_zoom

	update_minimap()

func register_map_icon(node):
	on_map.append(node)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_home"):
		spawn_enemy()
	
func spawn_enemy():
	var pos: Vector2

	pos.x = %PlayerShip.global_position.x + randi_range(200, 3000)
	pos.y = %PlayerShip.global_position.y + randi_range(200, 3000)

	var spaceship: Spaceship = SPACESHIP.instantiate()
	spaceship.global_position = pos
	spaceship.character_died.connect(_on_ai_spaceship_character_died)
	%SpaceshipContainer.add_child(spaceship)

	var map_dot = MAP_ENEMY_DOT.instantiate()
	map_dot.global_position = pos
	%Minimap.add_child(map_dot)
	spaceships_minimap[spaceship] = map_dot
	print(map_dot.global_position)

func generate_minimap():
	# var map: Image = Image.create(10000, 10000, false, Image.FORMAT_RGB8)
	# map.fill(Color.WHITE)
	# %Minimap.texture = ImageTexture.create_from_image(map)
	pass

func update_minimap():
	%MapPlayer.global_position = %PlayerShip.global_position
	%MinimapCamera.global_position = %PlayerShip.global_position
	%MinimapCamera.zoom = Vector2(0.01, 0.01)
	%Minimap.global_position = %PlayerShip.global_position

	for ship in spaceships_minimap.keys():
		spaceships_minimap[ship].global_position = ship.global_position
		# print("UPDATING SPACESHIP")

func _on_player_ship_character_died(node: Spaceship) -> void:
	%CameraController.set_target_zoom(2.0)
	%CameraController.set_target_shift(Vector2.ZERO)

func _on_ai_spaceship_character_died(node: Spaceship) -> void:
	spaceships_minimap[node].queue_free()
	spaceships_minimap.erase(node)

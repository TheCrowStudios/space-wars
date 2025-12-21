extends Node2D

@export var weapons: Array[PackedScene]
@export var fuel_tanks: Array[PackedScene]
@export var oxygen_tanks: Array[PackedScene]

@onready var spaceship = $SpaceshipHull

var weapon_instances: Array[Weapon]
var fuel_instances: Array[Weapon]
var oxygen_instances: Array[Weapon]
var mounting_markers: Array[Area2D]
var placed_parts: Array[Node2D]
var hovered_instance: Node2D

var weapon_buttons: Array[TextureButton]
var fuel_buttons: Array[TextureButton]
var oxygen_buttons: Array[TextureButton]
var other_buttons: Array[TextureButton]

# placement flags
var lock_ghost: bool = false
# var can_place: bool = false
var is_inside: bool = false
var is_in_wall: bool = false
var is_blocked: bool = false
var is_on_mounting_point: bool = false

enum SelectedType {WEAPON, FUEL, OXYGEN, OTHER, NONE}
var selected_type: SelectedType = SelectedType.NONE
var selected_instance: Node2D
var selected_scene: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var markers = %MountingMarkers.get_children()
	
	for child in markers:
		if child is Area2D:
			print("ADDING MARKER")
			mounting_markers.append(child)
	
	%PartGhost.area_entered.connect(_on_marker_intersect)
	%PartGhost.area_exited.connect(_on_marker_leave)

	for scene: PackedScene in weapons:
		var weapon: Weapon = scene.instantiate()
		var btn = create_button(weapon.find_child("Sprite2D").texture)
		btn.pressed.connect(_on_weapon_selected.bind(weapon, scene))
		weapon_buttons.append(btn)

		%List.add_child(btn)
		# weapon.queue_free()

	for scene: PackedScene in fuel_tanks:
		var fuel = scene.instantiate()
		var btn = create_button(fuel.find_child("Sprite2D").texture)
		btn.pressed.connect(_on_fuel_selected.bind(fuel, scene))
		fuel_buttons.append(btn)

		%List.add_child(btn)
		btn.visible = false
		# weapon.queue_free()

	for scene: PackedScene in oxygen_tanks:
		var oxygen = scene.instantiate()
		var btn = create_button(oxygen.find_child("Sprite2D").texture)
		btn.pressed.connect(_on_oxygen_selected.bind(oxygen, scene))
		oxygen_buttons.append(btn)

		%List.add_child(btn)
		btn.visible = false
		# weapon.queue_free()

func create_button(texture: Texture2D) -> TextureButton:
	var btn: TextureButton = TextureButton.new()
	btn.texture_normal = texture
	btn.size_flags_horizontal = Control.SIZE_FILL
	btn.size_flags_vertical = Control.SIZE_FILL
	btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT
	btn.custom_minimum_size = Vector2(100, 100)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return btn

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if !lock_ghost: %PartGhost.global_position = get_global_mouse_position()
	elif %PartGhost.global_position.distance_to(get_global_mouse_position()) > 20: lock_ghost = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("left_click"):
		place()
	if event.is_action_pressed("right_click"):
		remove()

func place():
	if selected_type == SelectedType.NONE || !can_place(): return

	match selected_type:
		SelectedType.WEAPON:
			var weapon: Weapon = selected_scene.instantiate()
			# TODO - dont use partghost position, use marker position
			weapon.position = spaceship.to_local(%PartGhost.global_position)
			spaceship.add_weapon(weapon)
			placed_parts.push_back(weapon)
			var shape: Area2D = get_node_editor_area(weapon)
			if shape:
				shape.mouse_entered.connect(_placed_object_mouse_entered.bind(weapon))
				shape.mouse_exited.connect(_placed_object_mouse_exited)
			print("WEAPON ADDED AT: ", weapon.global_position)
		SelectedType.FUEL:
			var instance = selected_scene.instantiate()
			instance.position = spaceship.to_local(%PartGhost.global_position)
			spaceship.add_child(instance)
			placed_parts.push_back(instance)
			var shape: Area2D = get_node_editor_area(instance)
			if shape:
				shape.mouse_entered.connect(_placed_object_mouse_entered.bind(instance))
				shape.mouse_exited.connect(_placed_object_mouse_exited)
		SelectedType.OXYGEN:
			var instance = selected_scene.instantiate()
			instance.position = spaceship.to_local(%PartGhost.global_position)
			spaceship.add_child(instance)
			placed_parts.push_back(instance)
			var shape: Area2D = get_node_editor_area(instance)
			if shape:
				shape.mouse_entered.connect(_placed_object_mouse_entered.bind(instance))
				shape.mouse_exited.connect(_placed_object_mouse_exited)
		SelectedType.NONE:
			return false

func remove():
	if !hovered_instance: return
	print("REMOVING PART")

	var pos = placed_parts.find(hovered_instance)
	if pos == -1: return
	
	placed_parts[pos].queue_free()
	placed_parts.remove_at(pos)

func can_place() -> bool:
	match selected_type:
		SelectedType.WEAPON:
			if !is_on_mounting_point || is_blocked: return false
		SelectedType.FUEL:
			if !is_inside || is_in_wall || is_blocked: return false
		SelectedType.OXYGEN:
			if !is_inside || is_in_wall || is_blocked: return false
		SelectedType.NONE:
			return false
	
	return true

func _on_weapon_selected(weapon: Weapon, scene: PackedScene):
	var sprite: Sprite2D = weapon.find_child("Sprite2D")
	var shape = get_node_editor_collision_shape(weapon)
	update_part_ghost(sprite.texture, shape)
	selected_type = SelectedType.WEAPON
	selected_instance = weapon
	selected_scene = scene
	# mounting_markers[0].

func _on_fuel_selected(fuel, scene: PackedScene):
	var sprite: Sprite2D = fuel.find_child("Sprite2D")
	var shape = get_node_editor_collision_shape(fuel)
	update_part_ghost(sprite.texture, shape)
	selected_type = SelectedType.FUEL
	selected_instance = fuel
	selected_scene = scene

func _on_oxygen_selected(oxygen, scene: PackedScene):
	var sprite: Sprite2D = oxygen.find_child("Sprite2D")
	var shape = get_node_editor_collision_shape(oxygen)
	update_part_ghost(sprite.texture, shape)
	selected_type = SelectedType.OXYGEN
	selected_instance = oxygen
	selected_scene = scene

func update_part_ghost(texture, shape):
	%PartGhostSprite.texture = texture
	if shape: %PartGhostCollisionShape.shape = shape.shape

func get_node_editor_area(node: Node2D) -> Area2D:
	var shape = node.get_node("EditorCollisionArea")
	print("EDITOR AREA: ", shape)
	return shape

func get_node_editor_collision_shape(node: Node2D) -> CollisionShape2D:
	var shape = node.get_node("EditorCollisionArea/CollisionShape2D")
	print("EDITOR COLLISION SHAPE: ", shape)
	return shape

func _on_marker_intersect(marker: Area2D):
	if marker.is_in_group("MountingMarker"):
		if lock_ghost: return
		lock_ghost = true
		print("INTERSECT")

		var offset: Vector2 = Vector2.ZERO

		if selected_type == SelectedType.WEAPON:
			offset = selected_instance.find_child("MountingMarker").position
		
		%PartGhost.global_position = marker.find_child("Marker2D").global_position - offset
		%PartGhostSprite.modulate = Color.GREEN
		is_on_mounting_point = true
	elif marker.is_in_group("InsideArea"):
		is_inside = true
	elif marker.is_in_group("Walls"):
		is_in_wall = true
	elif marker.is_in_group("EditorCollisionArea"):
		is_blocked = true

func _on_marker_leave(marker: Area2D):
	if marker.is_in_group("MountingMarker"):
		if lock_ghost: return
		is_on_mounting_point = false
		print("LEAVE")
		%PartGhostSprite.modulate = Color.GRAY
	elif marker.is_in_group("InsideArea"):
		is_inside = false
	elif marker.is_in_group("Walls"):
		is_in_wall = false
	elif marker.is_in_group("EditorCollisionArea"):
		is_blocked = false

func _on_tab_bar_tab_changed(tab: int) -> void:
	print("TAB CHANGED")
	match tab:
		0:
			set_button_visibility(weapon_buttons, true)
			set_button_visibility(fuel_buttons, false)
			set_button_visibility(oxygen_buttons, false)
			set_button_visibility(other_buttons, false)
		1:
			set_button_visibility(weapon_buttons, false)
			set_button_visibility(fuel_buttons, true)
			set_button_visibility(oxygen_buttons, false)
			set_button_visibility(other_buttons, false)
		2:
			set_button_visibility(weapon_buttons, false)
			set_button_visibility(fuel_buttons, false)
			set_button_visibility(oxygen_buttons, true)
			set_button_visibility(other_buttons, false)
		3:
			set_button_visibility(weapon_buttons, false)
			set_button_visibility(fuel_buttons, false)
			set_button_visibility(oxygen_buttons, false)
			set_button_visibility(other_buttons, true)

func set_button_visibility(array: Array[TextureButton], visible: bool):
	for button in array:
		button.visible = visible

func _placed_object_mouse_entered(instance: Node2D):
	print("MOUSE ENTERED PLACED NODE")
	for node in placed_parts:
		if node == instance:
			hovered_instance = instance
			return

func _placed_object_mouse_exited():
	hovered_instance = null

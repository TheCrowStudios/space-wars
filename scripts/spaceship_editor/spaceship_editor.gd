extends Node2D

@export var weapons: Array[PackedScene]
@export var fuel: Array[PackedScene]
@export var oxygen: Array[PackedScene]

@onready var spaceship = $SpaceshipHull

var weapon_instances: Array[Weapon]
var mounting_markers: Array[Area2D]

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
		var btn: TextureButton = TextureButton.new()
		var weapon: Weapon = scene.instantiate()
		btn.texture_normal = weapon.find_child("Sprite2D").texture
		btn.size_flags_horizontal = Control.SIZE_FILL
		btn.size_flags_vertical = Control.SIZE_FILL
		btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT
		btn.custom_minimum_size = Vector2(100, 100)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn.pressed.connect(_on_weapon_selected.bind(weapon, scene))

		%List.add_child(btn)
		# weapon.queue_free()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if !lock_ghost: %PartGhost.global_position = get_global_mouse_position()
	elif %PartGhost.global_position.distance_to(get_global_mouse_position()) > 20: lock_ghost = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("left_click"):
		place()

func place():
	if selected_type == SelectedType.NONE || !can_place(): return

	match selected_type:
		SelectedType.WEAPON:
			var weapon: Weapon = selected_scene.instantiate()
			weapon.position = spaceship.to_local(%PartGhost.global_position)
			spaceship.add_weapon(weapon)
			print("WEAPON ADDED AT: ", weapon.global_position)
		SelectedType.FUEL:
			if !is_inside || is_in_wall || is_blocked: return false
		SelectedType.OXYGEN:
			if !is_inside || is_in_wall || is_blocked: return false
		SelectedType.NONE:
			return false

func can_place() -> bool:
	match selected_type:
		SelectedType.WEAPON:
			if !is_on_mounting_point: return false
		SelectedType.FUEL:
			if !is_inside || is_in_wall || is_blocked: return false
		SelectedType.OXYGEN:
			if !is_inside || is_in_wall || is_blocked: return false
		SelectedType.NONE:
			return false
	
	return true

func _on_weapon_selected(weapon: Weapon, scene: PackedScene):
	var sprite: Sprite2D = weapon.find_child("Sprite2D")
	%PartGhostSprite.texture = sprite.texture
	selected_type = SelectedType.WEAPON
	selected_instance = weapon
	selected_scene = scene
	# mounting_markers[0].

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

func _on_marker_leave(marker: Area2D):
	if marker.is_in_group("MountingMarker"):
		if lock_ghost: return
		is_on_mounting_point = false
		print("LEAVE")
		%PartGhostSprite.modulate = Color.GRAY

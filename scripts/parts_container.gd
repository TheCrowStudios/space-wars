extends Node2D

@export var weapons: Array[PackedScene]

var weapon_instances: Array[Weapon]
var mounting_markers: Array[Area2D]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var markers = %MountingMarkers.get_children()
	
	for child in markers:
		if child is Area2D:
			mounting_markers.append(child)

	for scene: PackedScene in weapons:
		var btn: TextureButton = TextureButton.new()
		var weapon: Weapon = scene.instantiate()
		btn.texture_normal = weapon.find_child("Sprite2D").texture
		btn.size_flags_horizontal = Control.SIZE_FILL
		btn.size_flags_vertical = Control.SIZE_FILL
		btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT
		btn.custom_minimum_size = Vector2(100, 100)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn.pressed.connect(_on_weapon_selected.bind(weapon))

		%List.add_child(btn)
		weapon_instances.append(weapon)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	%PartGhost.global_position = get_global_mouse_position()

func _on_weapon_selected(weapon: Weapon):
	var sprite: Sprite2D = weapon.find_child("Sprite2D")
	%PartGhost.texture = sprite.texture
	# mounting_markers[0].
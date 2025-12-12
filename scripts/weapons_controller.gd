extends Node2D


var weapon_group_1: Array[Weapon]
var weapon_group_2: Array[Weapon]
var weapon_group_3: Array[Weapon]

var selected_group: int = 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var children = get_children()

	for child: Weapon in children:
		match child.weapon_group:
			1:
				weapon_group_1.append(child)
			2:
				weapon_group_2.append(child)
			3:
				weapon_group_3.append(child)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func select_weapon_group(group: int):
	selected_group = group
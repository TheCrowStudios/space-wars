extends Node2D


var weapon_group_1: Array[Weapon] # machine guns
var weapon_group_2: Array[Weapon] # locking missiles
var weapon_group_3: Array[Weapon]
var selected_weapons: Array[Weapon]

var selected_group: int = 1
var lock_on: bool = false

var parent_ref: Node

func set_parent_ref(parent: Node):
	parent_ref = parent

func get_parent_ref():
	return parent_ref

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
	
	selected_weapons = weapon_group_1

func _process(delta: float) -> void:
	queue_redraw()
# 	get_mouse_lock_target()
	
func get_mouse_lock_target(max_range: int = 3000) -> Node2D:
	var mouse_pos = get_global_mouse_position()
	var closest_target: Node2D = null
	var lock_on_dist_to_mouse = 300
	var closest_dist = INF

	var lockable = get_tree().get_nodes_in_group("lockable")

	for enemy: Node2D in lockable:
		if parent_ref.get_instance_id() == enemy.get_instance_id():
			continue

		var dist_to_mouse = enemy.global_position.distance_to(mouse_pos)
		var dist_to_controller = enemy.global_position.distance_to(global_position)

		if dist_to_mouse < closest_dist && dist_to_mouse < lock_on_dist_to_mouse && dist_to_controller <= max_range:
			closest_dist = dist_to_mouse
			closest_target = enemy

	return closest_target

func fire():
	for weapon in selected_weapons:
		if lock_on && weapon.locking:
			weapon.target = get_mouse_lock_target()

		weapon.fire()

func aim(at: Vector2):
	for weapon in selected_weapons:
		weapon.look(at)

func select_weapon_group(group: int):
	lock_on = false
	selected_group = group

	match selected_group:
		1:
			selected_weapons = weapon_group_1
		2:
			selected_weapons = weapon_group_2
		3:
			selected_weapons = weapon_group_3
	
	for weapon: Weapon in selected_weapons:
		if weapon.locking:
			lock_on = true
		
func _draw() -> void:
	if lock_on:
		var target = get_mouse_lock_target()
		if target:
			print(target.global_position)
			draw_circle(to_local(target.global_position), 64, Color.RED, false, 5)
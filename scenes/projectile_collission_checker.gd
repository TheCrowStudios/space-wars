extends Area2D


var parent_ref: Node

func set_parent_ref(parent: Node):
	parent_ref = parent

func get_parent_ref():
	return parent_ref

func is_blocked() -> bool:
	var overlaps = get_overlapping_bodies()

	for node in overlaps:
		if node.has_method("get_parent_ref"):
			if node.get_parent_ref().get_instance_id() == parent_ref.get_instance_id():
				return true

	# if is_colliding():
	# 	var node = get_collider()
	# 	if node.get_parent_ref().get_instance_id() == parent_ref.get_instance_id():
	# 		return true

	return false

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

func would_collide(rotation_radians: float) -> bool:
	var space_state = get_world_2d().direct_space_state

	var shape = $CollisionShape2D.shape

	var transform := Transform2D(rotation_radians, global_position)

	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = shape
	params.transform = transform
	params.collision_mask = collision_mask
	params.exclude = [self]
	var result = space_state.intersect_shape(params)

	for node in result:
		if node is Node2D:
			if node.has_method("get_parent_ref"):
				if node.get_parent_ref().get_instance_id() == parent_ref.get_instance_id():
					return true
		
	return false

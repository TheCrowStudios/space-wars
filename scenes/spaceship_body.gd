extends MeshInstance2D


var deform_radius: float = 5.0
var max_deform: float = 5.0
# var deform_strength: float = .5

var original_vertices: PackedVector2Array
var working_vertices: PackedVector2Array

func _ready() -> void:
	var arrays = mesh.surface_get_arrays(0)
	original_vertices = arrays[Mesh.ARRAY_VERTEX].duplicate()
	working_vertices = original_vertices.duplicate()

func dent(hit_position: Vector2, normal: float, strength: float = 1.0):
	var hit_local = to_local(hit_position)

	for i in working_vertices.size():
		var v = working_vertices[i]
		var dist = v.distance_to(hit_local)

		if dist < deform_radius:
			var falloff = 1.0 - (dist / deform_radius)
			var deform: Vector2 = Vector2.RIGHT.rotated(normal) * falloff * strength * max_deform
			# var force = Vector2.RIGHT.rotated(normal) * (1.0 - dist / deform_radius) * deform_strength
			print("FORCE: ", Vector2.RIGHT.rotated(normal))
			# verts[i] += to_local(force)
			working_vertices[i] += deform.clampf(-max_deform, max_deform)
	
	# arrays[Mesh.ARRAY_VERTEX] = verts
	var arrays = mesh.surface_get_arrays(0)
	arrays[Mesh.ARRAY_VERTEX] = working_vertices
	var new_mesh: ArrayMesh = ArrayMesh.new()
	new_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh = new_mesh
	# mesh.surface_update_region(0, Mesh.ARRAY_VERTEX, 0, verts.size())

func dent_local(hit_position_local: Vector2, normal: Vector2, strength: float = 1.0):
	dent(to_global(hit_position_local), normal.angle(), strength)
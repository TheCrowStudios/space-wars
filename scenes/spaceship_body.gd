extends MeshInstance2D


var deform_radius: float = 40.0
var deform_strength: float = 20.0

func dent(hit_position: Vector2, normal: Vector2):
	var arrays = mesh.surface_get_arrays(0)
	var verts  = arrays[Mesh.ARRAY_VERTEX]
extends Node2D

@onready var mat: ShaderMaterial = %TextureRect.material

func _process(delta):
	var screen_size = get_viewport().size
	var uv = global_position / screen_size
	mat.set_shader_parameter("center", uv)

extends Node2D

@export var map_icon_sprite: CompressedTexture2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Sprite2D.texture = map_icon_sprite
	print("ROOT NODE NAME: " + get_node("/root/Game").name)
	var root = get_node("/root/Game")
	root.register_map_icon(self)
	# root.get_node("MapCanvas/MapIcons").add_child(self)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

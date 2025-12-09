extends SubViewportContainer


@export var player: Node2D
@export var zoom_level: float = 0.2
@export var minimap_size: Vector2 = Vector2(200, 200)

@onready var viewport: SubViewport = $SubViewport
@onready var camera: Camera2D = %MinimapCamera

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	size = minimap_size

	if camera:
		camera.enabled = true
		camera.zoom = Vector2(zoom_level, zoom_level)

	add_theme_stylebox_override("panel", create_border_style())


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if player && camera:
		camera.global_position = player.global_position

func create_border_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(1, 0, 0, 0.5)
	style.border_color = Color(1, 1, 1, 0.8)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	return style

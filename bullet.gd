extends Node2D

var speed: int = 800
var lifetime: int = 5000

var insantiation_time: int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	insantiation_time = Time.get_ticks_msec()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position += transform.x * speed * delta
	if (Time.get_ticks_msec() - insantiation_time >= lifetime):
		$PointLight2D.energy = lerp($PointLight2D.energy, 0.0, 0.05)
		# $Sprite2D.modulate.a = lerp($PointLight2D.modulate.a, 0.0, 0.1)
		print($PointLight2D.energy)
		if ($PointLight2D.energy <= 0.1): queue_free() # TODO - fade

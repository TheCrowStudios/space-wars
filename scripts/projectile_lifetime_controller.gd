extends Node


@export var light: PointLight2D
@export var particles: GPUParticles2D
@export var sprite: Sprite2D

var parent = get_parent()
var lifetime: int = 5000
var insantiation_time

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	insantiation_time = Time.get_ticks_msec()

func _process(delta: float) -> void:
	if (Time.get_ticks_msec() - insantiation_time >= lifetime):
		if light:
			light.energy = lerp(light.energy, 0.0, 0.05)
			# $Sprite2D.modulate.a = lerp($PointLight2D.modulate.a, 0.0, 0.1)
			# if (light.energy <= 0.1): queue_free()
		
		if sprite:
			sprite.modulate.a = lerp(sprite.modulate.a, 0.0, 0.05)
			if (light.energy <= 0.05): queue_free()
		
		if particles:
			particles.emitting = false

		if !sprite:
			queue_free() # delet if no sprite to fade

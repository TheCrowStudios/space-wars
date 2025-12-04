class_name ExplosionRadius
extends Node2D

@export var radius: float = 800.0
@export var blast_force: float = 800.0
@export var blast_damage: float = 100.0
@export_range(0.01, 1.0) var blast_speed: float = 0.1


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Area2D/CollisionShape2D.shape.radius = 0


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$Area2D/CollisionShape2D.shape.radius = lerp($Area2D/CollisionShape2D.shape.radius, radius, 0.1)
	# print($Area2D/CollisionShape2D.shape.radius)
	if $Area2D/CollisionShape2D.shape.radius >= radius - 10:
		queue_free()


func _on_area_2d_body_entered(body: Node2D) -> void:
	var distance_to_body
	if body is RigidBody2D:
		distance_to_body = global_position - body.global_position
		body.apply_central_impulse((blast_force * (distance_to_body.length() / radius)) * -distance_to_body.normalized())
		# var area: Area2D = $Area2D
	elif body is DestructibleObject:
		print("BODY ENTERED BLAST AREA: " + body.name)
		distance_to_body = global_position - body.global_position
		print("DAMAGE CAUSED: " + str((blast_damage * (radius - distance_to_body.length())) / blast_damage))
		body.take_damage((blast_damage * (distance_to_body.length() / radius)))

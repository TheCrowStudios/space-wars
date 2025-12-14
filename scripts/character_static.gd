extends Node2D

signal character_died()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_destructible_object_destroyed(node: DestructibleObject) -> void:
	$AnimatedSprite2D.play("die")
	emit_signal("character_died")
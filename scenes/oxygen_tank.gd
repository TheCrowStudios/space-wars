extends StaticBody2D
@onready var destructibleObject = preload("res://scripts/destructible_object.gd")

func _on_destroyed() -> void:

	print("DESTROYED")

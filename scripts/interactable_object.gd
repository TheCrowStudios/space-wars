class_name InteractableObject
extends Area2D


@export var object_id: String = ""
@export var display_name: String = "Object"
@export var interaction_prompt: String = "Press E to interact"
@export var requires_item: String = ""
@export var is_locked: bool = false
@export var locked_message: String = "This is locked."

@onready var prompt_label = %PromptLabel
var player_nearby: bool = false

func _ready() -> void:
	prompt_label.hide()

func _input(event: InputEvent) -> void:
	if !player_nearby:
		return
	
	if event.is_action_pressed("interact"):
		interact()

func interact():
	if is_locked:
		show_message(locked_message)
		return
	
	on_interact()

func on_interact():
	if Globals.DEBUG:
		print("INTERACTED WITH: " + display_name)
	# TODO - interact

func show_message(message: String):
	# TODO - show message
	pass

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_nearby = true
		if !is_locked:
			prompt_label.text = interaction_prompt
			prompt_label.show()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_nearby = true
		prompt_label.hide()

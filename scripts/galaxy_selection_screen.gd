extends Control


var selected_galaxy: int = 0

var galaxy_names = ["", "Galaxy 1"]
var galaxy_descriptions = ["", "Galaxy 1 description goes here bla bla bla"]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func set_galaxy_name(galaxy_name: String):
	%GalaxyName.text = galaxy_name

func set_galaxy_description(description: String):
	%GalaxyDescription.text = description 

func _on_galaxy_1_mouse_entered() -> void:
	%Galaxy1.modulate = Color(1.2, 1.2, 1.2)
	set_galaxy_name("Galaxy 1")
	set_galaxy_description("Galaxy 1 description goes here bla bla bla")

func _on_galaxy_1_mouse_exited() -> void:
	%Galaxy1.modulate = Color.WHITE
	set_galaxy_name("")
	set_galaxy_description("")
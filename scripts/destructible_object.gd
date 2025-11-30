class_name DestructibleObject
extends RigidBody2D

@export_group("Destruction Settings")
@export var max_health: int = 100
@export var debris_scene: PackedScene
@export var destruction_force: float = 300.0
@export var hit_audio_streams: Array[AudioStream]
@export var ricochet_audio_streams: Array[AudioStream]

var health: int = max_health

signal health_changed(new_health, max_health)
signal destroyed()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func take_hit(bullet_type: Globals.BulletType, hit_point: Vector2):
	if bullet_type == Globals.BulletType.MEDIUM:
		health -= 20
	
	if !hit_audio_streams.is_empty():
		var stream_to_play = hit_audio_streams.pick_random()
		var audio_player = AudioStreamPlayer2D.new()
		audio_player.stream = stream_to_play
		audio_player.pitch_scale = randf_range(0.8, 1.0)
		audio_player.global_position = global_position
		add_child(audio_player)
		audio_player.max_distance = 3000
		audio_player.play()
		await audio_player.finished
		audio_player.queue_free()

	if debris_scene:
		var debris = debris_scene.instantiate()
		add_child(debris)
		debris.emitting = true

func take_ricochet():
	if !ricochet_audio_streams.is_empty():
		var stream_to_play = ricochet_audio_streams.pick_random()
		var audio_player = AudioStreamPlayer2D.new()
		audio_player.stream = stream_to_play
		audio_player.pitch_scale = randf_range(0.8, 1.0)
		audio_player.global_position = global_position
		add_child(audio_player)
		audio_player.max_distance = 3000
		audio_player.play()
		await audio_player.finished
		audio_player.queue_free()

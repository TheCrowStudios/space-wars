class_name DestructibleObject
extends StaticBody2D

@export_group("Destruction Settings")
@export var max_health: int = 100
@export var debris_particles: PackedScene
@export var hit_particles: PackedScene
@export var destruction_particles: PackedScene
@export var destruction_force: float = 300.0
@export var hit_audio_streams: Array[AudioStream]
@export var ricochet_audio_streams: Array[AudioStream]
@export var destruction_audio_streams: Array[AudioStream]
@export var penetration_resistance: int = 10
@export var penetration_cost: int = 10

var health: float

signal health_changed(new_health, max_health)
signal destroyed(node: DestructibleObject)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	health = max_health

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func take_hit(bullet_type: Globals.BulletType, hit_point: Vector2, bullet: Bullet, damage: float):
	if bullet_just_fired_by_parent(bullet): return

	# print(health)


	if hit_particles:
		var particles = hit_particles.instantiate()
		add_child(particles)
		particles.emitting = true
	
	if !hit_audio_streams.is_empty():
		var stream_to_play = hit_audio_streams.pick_random()
		var audio_player = AudioStreamPlayer2D.new()
		audio_player.stream = stream_to_play
		audio_player.pitch_scale = randf_range(0.8, 1.0)
		add_child(audio_player)
		audio_player.max_distance = 3000
		audio_player.play()
		await audio_player.finished
		audio_player.queue_free()

	if health <= 0: return

	health -= damage

	if health <= 0:
		print("DESTROYED")
		emit_signal("destroyed", self)
		penetration_resistance /= 10
		penetration_cost /= 10
		if destruction_particles:
			var particles = destruction_particles.instantiate()
			add_child(particles)
			particles.emitting = true

		if debris_particles:
			var debris = debris_particles.instantiate()
			add_child(debris)
			debris.emitting = true


		if !destruction_audio_streams.is_empty():
			var stream_to_play = destruction_audio_streams.pick_random()
			var audio_player = AudioStreamPlayer2D.new()
			audio_player.stream = stream_to_play
			audio_player.pitch_scale = randf_range(0.8, 1.0)
			add_child(audio_player)
			audio_player.max_distance = 5000
			audio_player.play()
			await audio_player.finished
			audio_player.queue_free()
	
	print(health)

func take_ricochet(hit_position: Vector2, angle_to_normal: float, bullet: Bullet):
	if bullet_just_fired_by_parent(bullet): return

	if hit_particles:
		var particles: GPUParticles2D = hit_particles.instantiate()
		particles.rotation = angle_to_normal
		particles.position = hit_position - global_position
		add_child(particles)
		particles.emitting = true

	if !ricochet_audio_streams.is_empty():
		var stream_to_play = ricochet_audio_streams.pick_random()
		var audio_player = AudioStreamPlayer2D.new()
		audio_player.stream = stream_to_play
		audio_player.pitch_scale = randf_range(0.8, 1.0)
		add_child(audio_player)
		audio_player.max_distance = 3000
		audio_player.play()
		await audio_player.finished
		audio_player.queue_free()

func bullet_just_fired_by_parent(bullet: Bullet) -> bool:
	if bullet.created_by == get_parent().get_instance_id() && bullet.insantiation_time + 500 < Time.get_ticks_msec(): return true # avoid collision with bullets just fired by parent
	return false

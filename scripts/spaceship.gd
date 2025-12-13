class_name Spaceship
extends RigidBody2D
# @onready var destructibleObject = preload("res://scripts/destructible_object.gd").new()

@export var steering_angle = 20
@export var engine_power = 2000
@export var friction = -10
@export var drag = -0.06
@export var max_speed_reverse = 800
@export var slip_speed = 400
@export var traction_fast = 2.5 # Traction factor when the car is moving fast (affects control)
@export var traction_slow = 10 # Traction factor when the car is moving slow (affects control)
@export var is_player = false
@export var enable_ai = true
@export var is_alive = true
@export var flyby_audio_streams: Array[AudioStream]

signal character_died(node: Spaceship)

const PLAYER_BRAINS: PackedScene = preload("res://scenes/spaceship_player_brains.tscn")
const AI_BRAINS: PackedScene = preload("res://scenes/spaceship_ai_brains.tscn")

const REGULAR_LINEAR_DAMP = 0.2
const REGULAR_ANGULAR_DAMP = 0.05
const COLLISION_DAMP = 100.0

var boosters = []
var main_boosters = []
var use_main_boosters: bool = false
var hp = 1000

var acceleration = Vector2.ZERO # Current acceleration vector
var steer_direction # Current direction of steering

var turn = 0
var acc = 0
var aim_at: Vector2

# repairs
var time_to_repair_nodes: float = 0
var remaining_time_to_repair_nodes: float = 0
var destroyed_nodes_repairable: Array[DestructibleObject] = []
var nodes_to_repair: Array[DestructibleObject] = []
var all_boosters_destroyed: bool = false
var has_destroyed_gun: bool = false
var repairing: bool = false

@export var is_active = true

func _ready() -> void:
	assign_parent_ref_recursive(self)

	if is_player:
		var player_brains = PLAYER_BRAINS.instantiate()
		add_child(player_brains)

	if enable_ai:
		var ai_brains: SpaceshipAIBrains = AI_BRAINS.instantiate()
		add_child(ai_brains)
		$TargetDetectionArea.connect("body_entered", ai_brains._on_target_detection_area_body_entered)
		$TargetDetectionArea.connect("body_exited", ai_brains._on_target_detection_area_body_exited)
		$WideTargetDetectionArea.connect("body_entered", ai_brains._on_wide_target_detection_area_body_entered)
		$WideTargetDetectionArea.connect("body_exited", ai_brains._on_wide_target_detection_area_body_exited)

	boosters = get_node(".").find_children("Booster" + "*")
	main_boosters = get_node(".").find_children("MainBooster" + "*")
	# guns = get_node(".").find_children("Gun" + "*")
	aim_at = get_global_mouse_position()

	if (Globals.DEBUG && Globals.DEBUG_AIM):
		var crosshair = $Crosshair
		var crosshair_velocity = $CrosshairVelocity

		if crosshair:
			crosshair.visible = true

		if crosshair_velocity:
			crosshair.visible = true

	if (is_player):
		add_to_group("player")
		add_to_group("team1") # TODO - come up with teams names
	
func assign_parent_ref_recursive(node: Node):
	for child in node.get_children():
		if child.has_method("set_parent_ref"):
			child.set_parent_ref(self)
			print(child.name)
		
		assign_parent_ref_recursive(child)

func _process(delta: float) -> void:
	if is_alive:
		if is_active:
			if !repairing:
				interpret_input()
			else:
				repair(delta)
	else:
		set_booster_thrust(false)

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if state.get_contact_count() > 0:
		linear_damp = COLLISION_DAMP
		angular_damp = COLLISION_DAMP
		print("COLLISION")
	else:
		linear_damp = REGULAR_LINEAR_DAMP
		angular_damp = REGULAR_ANGULAR_DAMP

func start_repair():
	if (is_player): Popups.hide_message_popup()
	# state = State.REPAIRING
	nodes_to_repair = destroyed_nodes_repairable

	time_to_repair_nodes = 0
	for node: DestructibleObject in nodes_to_repair:
		time_to_repair_nodes += node.repair_time
	
	remaining_time_to_repair_nodes = time_to_repair_nodes
	repairing = true

func repair(delta: float):
	if (is_player):
		Popups.show_repair_progress()
		Popups.set_repair_progress(100.0 - (remaining_time_to_repair_nodes / time_to_repair_nodes * 100))
		Popups.set_repair_progress_seconds(remaining_time_to_repair_nodes)
	
	remaining_time_to_repair_nodes -= delta

	if (remaining_time_to_repair_nodes <= 0):
		for node: DestructibleObject in nodes_to_repair:
			node.repair()
		
		nodes_to_repair.clear()

		destroyed_nodes_repairable = destroyed_nodes_repairable.filter(func(node: DestructibleObject): return node.destroyed)
		# state = State.IDLE

		Popups.hide_repair_progress()
		repairing = false
		
func interpret_input():
	steer_direction = turn * deg_to_rad(steering_angle)
	set_booster_direction(steer_direction)

	if acc != 0:
		set_booster_thrust(true)
		for booster in boosters:
			if (acc == -1): booster.rotation += deg_to_rad(180);
	else:
		set_booster_thrust(false)

	%WeaponsController.aim(aim_at)

func fire_guns():
	%WeaponsController.fire()

func select_weapon_group(group: int):
	%WeaponsController.select_weapon_group(group)

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Bullet && is_player && body.get_parent_ref().get_instance_id() != get_instance_id() && !flyby_audio_streams.is_empty():
		# print("PASS BY")
		var audio_stream = flyby_audio_streams.pick_random()
		var audio_player = AudioStreamPlayer2D.new()
		audio_player.stream = audio_stream
		add_child(audio_player)
		audio_player.volume_linear = abs((body.velocity - linear_velocity).length()) / 1600.0
		# print(audio_player.volume_linear)
		audio_player.play()
		await audio_player.finished
		audio_player.queue_free()

func _on_node_destroyed(node: DestructibleObject) -> void:
	if (node.get_parent() != self): return
	var random_dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	angular_velocity = random_dir.length()


func _on_character_static_character_died() -> void:
	is_alive = false
	emit_signal("character_died", self)


func _on_booster_destroyed(node: DestructibleObject) -> void:
	destroyed_nodes_repairable.push_back(node)
	if is_player: Popups.message_popup()
	var destroyed_boosters_count: int = 0
	var destroyed_boosters = boosters.filter(func(booster): return booster.destroyed)

func set_booster_thrust(on: bool):
	for booster in boosters:
		booster.set_thrust(on)

	if use_main_boosters && on:
		for booster in main_boosters:
			booster.set_thrust(true)
	else:
		for booster in main_boosters:
			booster.set_thrust(false)

func set_booster_direction(direction_rad):
	for booster: Node2D in boosters:
		booster.rotation = direction_rad
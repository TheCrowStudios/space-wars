extends Node


@onready var pawn: Spaceship = get_parent()

const MAX_REPAIR_DELAY: float = 1.0
var repair_delay: float = MAX_REPAIR_DELAY

enum State {NORMAL, DEAD}
var state: State = State.NORMAL

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	get_input(delta)

func get_input(delta: float):
	if state == State.DEAD: return

	pawn.turn = Input.get_axis("move_left", "move_right")
	pawn.acc = Input.get_axis("move_down", "move_up")

	pawn.aim_at = pawn.get_global_mouse_position()

	if (Input.is_action_pressed("repair")):
		if Globals.DEBUG && Globals.DEBUG_INPUTS:
			print("REPAIR BUTTON HELD")

		if pawn.destroyed_nodes_repairable.size() == 0: return
		repair_delay -= delta
		if repair_delay <= 0:
			pawn.start_repair()
	
	if (Input.is_action_just_released("repair")):
		repair_delay = MAX_REPAIR_DELAY
	
	if (Input.is_action_pressed("left_click")):
		pawn.fire_guns()
	
	if (Input.is_action_pressed("select_weapon_group_1")):
		pawn.select_weapon_group(1)

	if (Input.is_action_pressed("select_weapon_group_2")):
		pawn.select_weapon_group(2)

	if (Input.is_action_pressed("select_weapon_group_3")):
		pawn.select_weapon_group(3)
	
	if (Input.is_action_pressed("shift")):
		pawn.use_main_boosters = true
	else:
		pawn.use_main_boosters = false

func _on_character_died(node):
	state = State.DEAD 
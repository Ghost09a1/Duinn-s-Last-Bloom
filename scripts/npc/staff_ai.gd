extends CharacterBody3D

enum State { IDLE, MOVE_TO_TARGET, WAIT, ACTION }
var current_state : State = State.IDLE

@export var role : String = "waiter" # "waiter" oder "cleaner"
@export var move_speed : float = 4.0

@onready var nav_agent : NavigationAgent3D = $NavigationAgent3D
@onready var animation : AnimationPlayer = $AnimationPlayer # Optional für später

var target_position : Vector3
var action_timer : float = 0.0

func _ready() -> void:
	if nav_agent == null:
		push_warning("[%s] Kein NavigationAgent3D gefunden." % name)

func _physics_process(delta: float) -> void:
	match current_state:
		State.IDLE:
			_process_idle()
		State.MOVE_TO_TARGET:
			_process_move(delta)
		State.WAIT:
			_process_wait(delta)
		State.ACTION:
			_process_action(delta)

func _process_idle() -> void:
	# Suche Wegpunkte im Tree
	var waypoints = get_tree().get_nodes_in_group("staff_waypoints")
	if waypoints.size() > 0:
		# Wähle einen zufälligen Wegpunkt
		var target = waypoints[randi() % waypoints.size()]
		assign_task(target.global_position)
	else:
		# Keine Wegpunkte gefunden, trödle am Ort
		_change_state(State.WAIT)

func _process_move(_delta: float) -> void:
	if nav_agent == null: return
	
	if nav_agent.is_navigation_finished():
		_change_state(State.WAIT)
		return
		
	var next_pos = nav_agent.get_next_path_position()
	var dir = global_position.direction_to(next_pos)
	dir.y = 0
	
	if dir != Vector3.ZERO:
		velocity = dir * move_speed
		
		# Drehen (Sofort für Prototyp, Interpolation besser für Finish)
		look_at(global_position + dir, Vector3.UP)
		
		move_and_slide()

func _process_wait(delta: float) -> void:
	action_timer -= delta
	if action_timer <= 0.0:
		_change_state(State.IDLE)

func _process_action(delta: float) -> void:
	action_timer -= delta
	if action_timer <= 0:
		_change_state(State.IDLE)

func _change_state(new_state: State) -> void:
	current_state = new_state
	if new_state == State.WAIT:
		action_timer = randf_range(2.0, 5.0) # Verweilen zwischen 2 und 5 Sekunden
	elif new_state == State.ACTION:
		action_timer = 2.0 # Standarddauer für Aktionen (wie servieren)

func assign_task(pos: Vector3) -> void:
	target_position = pos
	if nav_agent:
		nav_agent.set_target_position(pos)
	_change_state(State.MOVE_TO_TARGET)

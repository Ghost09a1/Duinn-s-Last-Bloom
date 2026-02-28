extends CharacterBody3D

const SPEED = 6.0
const GRAVITY = 9.8

@onready var nav_agent : NavigationAgent3D = $NavigationAgent3D
@onready var interact_prompt: Label = $HUD/InteractPrompt

var _locked : bool = false
var _target_interactable : Node3D = null
var _has_target : bool = false

func _ready() -> void:
	print("[Player] _ready() - Iso-Controller aktiv")
	if nav_agent:
		nav_agent.path_desired_distance = 0.5
		nav_agent.target_desired_distance = 0.5
		# DEAKTIVIERE AVOIDANCE: Godots RVO-Avoidance blockiert direkte Velocity-Zuweisung,
		# wenn nicht das `velocity_computed` Signal abgefangen wird! Das war der Fehler.
		nav_agent.avoidance_enabled = false
	if interact_prompt:
		interact_prompt.hide()

func move_to(target_pos: Vector3, interactable: Node3D = null) -> void:
	if _locked: return
	
	_target_interactable = interactable
	print("[Player] move_to() -> Ziel: ", target_pos)
	if nav_agent:
		nav_agent.avoidance_enabled = false
		nav_agent.target_position = target_pos
		_has_target = true
		print("[Player] New Target Set:", target_pos)

func _physics_process(delta: float) -> void:
	if _locked:
		return

	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	if _has_target and nav_agent:
		var dist_to_target = global_position.distance_to(nav_agent.target_position)
		
		# Sobald wir sehr nah am Ziel sind, anhalten
		if dist_to_target < 0.6 or nav_agent.is_navigation_finished():
			_has_target = false
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)
			
			if _target_interactable != null:
				var dist = global_position.distance_to(_target_interactable.global_position)
				if dist < 2.5:
					_try_interact(_target_interactable)
				_target_interactable = null
		else:
			var next_path_pos = nav_agent.get_next_path_position()
			var dir = global_position.direction_to(next_path_pos)
			dir.y = 0
			
			# Fallback: Wenn NavMesh kaputt ist, gehe blind in Richtung des Ziels
			if dir.length_squared() < 0.001:
				dir = global_position.direction_to(nav_agent.target_position)
				dir.y = 0
				
			dir = dir.normalized()
			
			velocity.x = dir.x * SPEED
			velocity.z = dir.z * SPEED
			
			if dir.length_squared() > 0.01:
				var target_rotation = atan2(dir.x, dir.z)
				rotation.y = lerp_angle(rotation.y, target_rotation, 10.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

func _try_interact(target: Node3D) -> void:
	if target and target.has_method("interact"):
		print("[Player] Interagieren mit: ", target.name)
		target.interact(self)

func set_locked(val: bool) -> void:
	_locked = val
	if val and nav_agent:
		nav_agent.target_position = global_position # Stoppe aktuelle Bewegung


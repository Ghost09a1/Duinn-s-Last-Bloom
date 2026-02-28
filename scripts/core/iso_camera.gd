extends Node3D

@export var move_speed : float = 15.0
@export var zoom_speed : float = 2.0
@export var min_zoom : float = 5.0
@export var max_zoom : float = 30.0
@export var rotation_speed : float = 5.0

@onready var cam : Camera3D = $Camera3D

var player : CharacterBody3D
var _target_y_rot : float = 0.0


func _ready() -> void:
	_target_y_rot = rotation.y
	if cam == null:
		push_error("[IsoCamera] Camera3D wurde nicht als Child gefunden!")
		return
	cam.current = true
	
	# Hole den Player
	player = get_node_or_null("../Player")
	if player == null:
		player = get_node_or_null("/root/TavernPrototype/Player")

func _process(delta: float) -> void:
	var move_dir = Vector3.ZERO
	# Rotation Input
	if Input.is_action_just_pressed("ui_page_down") or Input.is_physical_key_pressed(KEY_E):
		_target_y_rot -= PI / 2.0
	elif Input.is_action_just_pressed("ui_page_up") or Input.is_physical_key_pressed(KEY_Q):
		_target_y_rot += PI / 2.0
		
	# Interpolate Rotation
	rotation.y = lerp_angle(rotation.y, _target_y_rot, rotation_speed * delta)
	
	# Hole Basis für relative Bewegung
	var cam_basis = global_transform.basis
	
	# WASD Movement -> Map to Local Camera Coordinates
	var input_dir = Vector2.ZERO
	if Input.is_action_pressed("ui_up") or Input.is_physical_key_pressed(KEY_W):
		input_dir.y -= 1
	if Input.is_action_pressed("ui_down") or Input.is_physical_key_pressed(KEY_S):
		input_dir.y += 1
	if Input.is_action_pressed("ui_left") or Input.is_physical_key_pressed(KEY_A):
		input_dir.x -= 1
	if Input.is_action_pressed("ui_right") or Input.is_physical_key_pressed(KEY_D):
		input_dir.x += 1

	if input_dir != Vector2.ZERO:
		input_dir = input_dir.normalized()
		# Translatiere Input entsprechend der Kamera-Rotation (X = Right, Z = Backwards)
		# Wir wollen dass W "nach oben" (auf dem Bildschirm) geht, also in Richtung -Z lokal
		move_dir = (cam_basis.x * input_dir.x) + (cam_basis.z * input_dir.y)
		global_position += move_dir * move_speed * delta

	_update_xray()

func _update_xray() -> void:
	if player == null or cam == null: return
	var xray_mgr = get_node_or_null("/root/TavernPrototype")
	if not xray_mgr or not xray_mgr.has_method("set_target_alphas"): return
	
	var space_state = get_world_3d().direct_space_state
	var from = cam.global_position
	# Ray to player slightly above ground
	var to = player.global_position + Vector3(0, 1.0, 0) 
	
	var query = PhysicsRayQueryParameters3D.create(from, to)
	var exceptions = []
	var hits = []
	
	for i in range(10):
		query.exclude = exceptions
		var result = space_state.intersect_ray(query)
		if result:
			if result.collider == player:
				break
			hits.append(result.collider)
			exceptions.append(result.rid)
		else:
			break
			
	xray_mgr.set_target_alphas(hits)

func _unhandled_input(event: InputEvent) -> void:
	if cam == null: return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			if cam.projection == Camera3D.PROJECTION_ORTHOGONAL:
				cam.size = clamp(cam.size - zoom_speed, min_zoom, max_zoom)
			else:
				cam.fov = clamp(cam.fov - zoom_speed, min_zoom, max_zoom)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if cam.projection == Camera3D.PROJECTION_ORTHOGONAL:
				cam.size = clamp(cam.size + zoom_speed, min_zoom, max_zoom)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_handle_click(event.position)

func _handle_click(mouse_pos: Vector2) -> void:
	if player == null or player._locked: return
	
	var from = cam.project_ray_origin(mouse_pos)
	var to = from + cam.project_ray_normal(mouse_pos) * 1000.0
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1 # Nur Layer 1 abfragen (Wände auf Layer 2 werden ignoriert)
	
	var exceptions = []
	var move_target_found = false
	
	for i in range(10): # Raycast durch max 10 Wände/Decken etc. iterativ ignorieren
		query.exclude = exceptions
		var result = space_state.intersect_ray(query)
		
		if result:
			var collider = result.collider
			
			if collider.has_method("interact"):
				print("[IsoCamera] Clicked Interactable: ", collider.name)
				player.move_to(result.position, collider)
				move_target_found = true
				break
			elif collider.name.begins_with("Floor") or "Boden" in collider.name or (collider.get_parent() and collider.get_parent().name.begins_with("Floor")):
				print("[IsoCamera] Clicked Floor: ", collider.name)
				player.move_to(result.position)
				move_target_found = true
				break
			elif collider.get_parent() and "NavigationRegion" in collider.get_parent().name:
				print("[IsoCamera] Fallback: Clicked NavRegion Obj: ", collider.name)
				player.move_to(result.position)
				move_target_found = true
				break
			else:
				# Kein Floor und kein Interactable (vermutlich Wand/Dach). Ignorieren!
				exceptions.append(result.rid)
		else:
			break
			
	if not move_target_found:
		print("[IsoCamera] Click hit nothing walkable.")
